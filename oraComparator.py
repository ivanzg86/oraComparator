import cx_Oracle
import getopt
import sys
from multiprocessing import Manager, Process

#function definition
def parallelExecution(username, password, address, schema, numproc, queue):
	def connectToDb(username, password, address):
	   try:
	      connection = cx_Oracle.connect (username, password, address)
	   except cx_Oracle.DatabaseError as exception:
	      print ('\n'+numproc+': Failed to connect to DB at --> '+address+' because of this : '+str(exception))
	      exit(1)
	   print ('\n'+numproc+': Connected to DB at --> '+address)
	   return connection
        def checkDB(connection, address):
           cursor = connection.cursor()
           cursor.execute(sql_stmt2)
           result = cursor.fetchall()
           result2 = result[0] 
           if result2[0] != 4:
             print('DB doesnt contain all needed components at --> '+address+', exiting')
             exit(1)
           cursor.close()
	def fetchPutToArray(connection):
	   cursor = connection.cursor()
	   cursor.arraysize = 1000
	   cursor.execute(sql_stmt+""" and owner ='"""+schema+"""'""")
	   result = cursor.fetchall()
	   connection.close()
	   return result
	connection = connectToDb(username, password, address)
        checkDB(connection, address)
        queue.put(fetchPutToArray(connection))

def comparisonResult(result1, result2):
        only_1=set(result1) - set(result2)
        only_2=set(result2) - set(result1)
	if (len(only_1) != 0 or len(only_2) != 0):
    	   print('\nResult of DB comparison is below :')
    	   print('-----------------------------------')
    	   print('Format ---> SCHEMA|OBJECT_NAME|OBJECT_TYPE|OBJECT_HASH')
           print('Difference in '+address)
           print('----------')
           for i,j,k,l in only_1:
             print(i+'|'+j+'|'+k+'|'+l)
           print('----------')
           print('Difference in '+address2)
           print('----------')
           for i,j,k,l in only_2:
             print(i+'|'+j+'|'+k+'|'+l)
           print('----------')
    	   print('DB comparison is finished :')
    	   print('-----------------------------------\n')
    	   return
    	else:
	   print('No difference between schemas')

def processInParallel ():
	process1 = Process(target=parallelExecution,args=(username, password, address, schema,'Process1', queue1,))
	process2 = Process(target=parallelExecution,args=(username2, password2, address2, schema2, 'Process2', queue2,))
        process1.daemon = True
        process2.daemon = True
	process1.start()
        process2.start()
        while process1.exitcode is None and process2.exitcode is None:
           process1.join()
           process2.join()
        if process1.exitcode is not None and process1.exitcode != 0:
              print('Exiting...child process #1 did not execute correctly...')
              process2.terminate()
              exit(1)
        elif process2.exitcode is not None and process2.exitcode != 0:
              print('Exiting...child process #2 did not execute correctly...')
              process1.terminate()
              exit(1)
        elif process1.exitcode is not None and process1.exitcode == 0 and process2.exitcode is None:
              while process2.exitcode is None:
                 process2.join()
                 if process2.exitcode is not None and process2.exitcode != 0:
                    print('Exiting...child process #2 did not execute correctly...')
                    exit(1)
        elif process2.exitcode is not None and process2.exitcode == 0 and process1.exitcode is None:
              while process1.exitcode is None:
                 process1.join()
                 if process1.exitcode is not None and process1.exitcode != 0:
                    print('Exiting...child process #1 did not execute correctly...')
                    exit(1)
        global result1
        global result2
        result1 = queue1.get()
        result2 = queue2.get()
	comparisonResult(result1, result2)

def checkPassOptions(argv):
        try:
          opts, args = getopt.getopt(argv,"",["u1=","p1=","a1=","s1=","u2=","p2=","a2=","s2="])
        except getopt.GetoptError: 
          print('Script is not correctly invoked')
          print ('usage: oraComparator.py --u1 <user> --p1 <pass> --a1 <address> --s1 <schema> --u2 <user> --p2 <pass> --a2 <address> --s2 <schema>')
          exit(1)
        global username
	global password
	global address
        global username2
        global password2
        global address2
        global schema
        global schema2
        for opt, arg in opts:
           if opt in ("--u1"):
             username = arg
           elif opt in ("--p1"):
             password = arg
           elif opt in ("--a1"):
             address = arg
           elif opt in ("--s1"):
             schema = arg
           elif opt in ("--u2"):
             username2 = arg
           elif opt in ("--p2"):
             password2 = arg
           elif opt in ("--a2"):
             address2 = arg
           elif opt in ("--s2"):
             schema2 = arg

def notification(part):
    if part == 'TYPE_OF_OBJECTS':
       print('Comparison is done for these objects : FUNCTION, PROCEDURE, PACKAGE (body included), TYPE (body included), TRIGGER, VIEW')
       print('Note : Schemas that are not Oracle maintained are only compared')

#variable definition         
username = ''
username2 = ''
password = ''
password2 = ''
address = ''
address2 = ''
result1 = ''
result2 = ''
schema = ''
schema2 = ''
manager = Manager()
queue1 = manager.Queue(1)
queue2 = manager.Queue(1)

sql_stmt="""select owner,
                   object_name,
                   object_type,
                   case when modified = 'N' then  hash
                        else oracomparator.pkg_oracomparator_utl.set_hash(rowid,rawtohex(dbms_crypto.hash(dbms_metadata.get_ddl( 
                                                                                          object_type, object_name, owner), 2)))
                   end hash
            from oracomparator.object_hash_table 
            where object_type in ('PROCEDURE','FUNCTION',
                                  'PACKAGE','TYPE','TRIGGER',
                                  'VIEW')"""

sql_stmt2="""select sum(value)
            from (select 1 value
                  from dba_users
                  where username = 'ORACOMPARATOR'
                  union all
                  select 1 value
      		  from dba_objects
                  where object_name = 'OBJECT_HASH_TABLE'
                  and object_type = 'TABLE'
                  and owner = 'ORACOMPARATOR'
                  union all
                  select 1 value
                  from dba_objects
                  where object_name = 'ASYNC_UPDATE_DDL_HASH'
                  and object_type = 'TRIGGER'
                  and owner = 'ORACOMPARATOR'
                  union all
                  select 1 value
                  from dba_objects
                  where object_name = 'PKG_ORACOMPARATOR_UTL'
                  and object_type = 'PACKAGE'
                  and owner = 'ORACOMPARATOR'
                 )"""

#main program
notification('TYPE_OF_OBJECTS')

checkPassOptions(sys.argv[1:])

processInParallel()

