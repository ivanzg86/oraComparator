# oraComparator
Python comparator script for source objects in Oracle Database

Source objects are : procedure, function, package (body included), type (body included), view and trigger

Purpose of the script is to compare hashes of source object DDL in two Oracle databases and report if any discrepancy in DDL between them exist

Hashes are calculated during initial hash loading, updated in case of any DDL change on them by
a DDL trigger and stored in a dedicated table from which Python script selects them for comparison

Script was made using Python 2.7.5 and tested in Oracle Database 12.1.0.2.0 Enterprise Edition

Script uses multiprocessing module to get hashes in parallel

It uses cx_Oracle module to connect Python to Oracle Database

Script depends on several Oracle db objects for its correct functioning, those objects were developed in Oracle Database 12.1.0.2.0 Enterprise Edition

Repository includes following elements

--> Python comparator script --> oraComparator.py

--> sql script that does the initial hash loading and creation of Oracle db objects --> db_oracomparator.sql

   --> Oracle db objects include : package, table and a ddl trigger created under a dedicated schema
