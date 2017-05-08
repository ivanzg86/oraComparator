prompt DB install of oraComparator starting

create user oracomparator identified by &pass;

grant unlimited tablespace to oracomparator;

create table oracomparator.object_hash_table 
   (owner varchar2(100), 
    object_name varchar2(100), 
    object_type varchar2(100), 
    hash varchar2(100), 
    modified varchar2(1)
   );

create or replace trigger oracomparator.async_update_ddl_hash
after create or alter or drop
on database
declare
     v_object_owner oracomparator.object_hash_table.owner%type;
     
     v_object_name oracomparator.object_hash_table.object_name%type;
     
     v_object_type oracomparator.object_hash_table.object_type%type;
     
     v_hash oracomparator.object_hash_table.hash%type;
     
     v_ddl varchar2(2000);
     
begin
    v_object_owner := ora_dict_obj_owner;
    
    v_object_name := ora_dict_obj_name;
    
    v_object_type := ora_dict_obj_type;
    
    if ora_sysevent like '%RENAME%BIN%' 
      then v_ddl := 'DROP';
    else v_ddl := ora_sysevent;
    end if;

    if (v_ddl = 'CREATE' and ora_dict_obj_type in ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION','VIEW')) then
    
        insert into oracomparator.object_hash_table
        (owner,
         object_name,
         object_type,
         hash,
         modified
         )
         values 
        (v_object_owner,
         v_object_name,
         v_object_type,
         'TO_BE_COMPUTED',
         'N'
        );

    elsif (v_ddl = 'ALTER' and ora_dict_obj_type in ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION','VIEW')) then

       update oracomparator.object_hash_table
          set modified = 'Y'
       where owner = v_object_owner
          and object_name = v_object_name
          and object_type = v_object_type;

    elsif (v_ddl = 'DROP' and ora_dict_obj_type in ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION','VIEW')) then
         delete oracomparator.object_hash_table
         where owner = v_object_owner
           and object_name = v_object_name
           and object_type = v_object_type;
           
    end if;
    
end;
/

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

prompt DB install of oraComparator ended
