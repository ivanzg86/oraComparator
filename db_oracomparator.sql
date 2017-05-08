prompt DB install of oraComparator starting

whenever sqlerror exit

create user oracomparator identified by oracomparator1;

grant select on dba_users to oracomparator;
grant execute on dbms_random to oracomparator;
alter user oracomparator quota unlimited on users;

create table oracomparator.object_hash_table 
   (owner varchar2(100), 
    object_name varchar2(100), 
    object_type varchar2(100), 
    hash varchar2(100), 
    modified varchar2(1),
    datetime timestamp
   );

create or replace package oracomparator.pkg_oracomparator_utl
as
    function set_hash (row_id rowid, hash_value varchar2)
       return varchar2;
end pkg_oracomparator_utl;
/

create or replace package body oracomparator.pkg_oracomparator_utl
as
    function set_hash (row_id rowid, hash_value varchar2)
    return varchar2
    as
      pragma autonomous_transaction;
    begin
         update oracomparator.object_hash_table set hash = hash_value,
             modified = 'N'
                where rowid = row_id;
          commit;
          
          return hash_value;
        
    end;
end pkg_oracomparator_utl;
/

create or replace trigger oracomparator.async_update_ddl_hash
after create or alter or drop
on database
declare
     v_object_owner oracomparator.object_hash_table.owner%type;
     
     v_object_name oracomparator.object_hash_table.object_name%type;
     
     v_object_type oracomparator.object_hash_table.object_type%type;
     
     v_hash oracomparator.object_hash_table.hash%type;
     
     v_ddl varchar2(2000);

     v_check_owner varchar2(1);

     v_exist number;
     
begin
    v_object_owner := ora_dict_obj_owner;
    
    v_object_name := ora_dict_obj_name;
    
    v_object_type := ora_dict_obj_type;
    
    v_ddl := ora_sysevent;

    if v_object_type = 'PACKAGE BODY'
       then v_object_type := 'PACKAGE';
            v_ddl := 'ALTER';
    elsif v_object_type = 'TYPE BODY'
       then v_object_type := 'TYPE';
            v_ddl := 'ALTER';
    end if;

    select nvl(max(1),0)
    into v_exist
    from oracomparator.object_hash_table
    where owner = v_object_owner
    and object_name = v_object_name
    and object_type = v_object_type;

    select max(oracle_maintained)
    into v_check_owner
    from dba_users
    where username = v_object_owner;

    if v_check_owner = 'N' then

    	if (v_ddl = 'CREATE' and v_object_type in ('PACKAGE','PROCEDURE','FUNCTION','VIEW','TRIGGER','TYPE')) then
   
             if v_exist = 0 then
        	insert into oracomparator.object_hash_table
        	(owner,
         	object_name,
         	object_type,
         	hash,
         	modified,
         	datetime
         	)
         	values 
        	(v_object_owner,
         	v_object_name,
         	v_object_type,
         	'TO_BE_COMPUTED',
         	'Y',
         	systimestamp
        	);

            else

                update oracomparator.object_hash_table
          	set modified = 'Y',
                    hash = to_char(dbms_random.random),
              	datetime = systimestamp
       		where owner = v_object_owner
          	and object_name = v_object_name
          	and object_type = v_object_type;

            end if;

    	elsif (v_ddl = 'ALTER' and v_object_type in ('PACKAGE','PROCEDURE','FUNCTION','VIEW','TRIGGER','TYPE')) then

       		update oracomparator.object_hash_table
          	set modified = 'Y',
                    hash = to_char(dbms_random.random),
              	datetime = systimestamp
       		where owner = v_object_owner
          	and object_name = v_object_name
          	and object_type = v_object_type;

    	elsif (v_ddl = 'DROP' and v_object_type in ('PACKAGE','PROCEDURE','FUNCTION','VIEW','TRIGGER','TYPE')) then

         	delete oracomparator.object_hash_table
         	where owner = v_object_owner
           	and object_name = v_object_name
           	and object_type = v_object_type;
           
    	end if;
   end if;
    
end;
/

prompt Initial hash population started

insert into oracomparator.object_hash_table
select owner,
       object_name,
       object_type,
       rawtohex(dbms_crypto.hash(dbms_metadata.get_ddl(object_type, object_name, owner), 2)) hash,
        'N',
        systimestamp
        from dba_objects
        where object_type in ('PROCEDURE','FUNCTION',
                              'PACKAGE','TYPE','TRIGGER',
                              'VIEW')
        and owner in (select username from dba_users where oracle_maintained = 'N');

commit;

prompt DB install of oraComparator ended
