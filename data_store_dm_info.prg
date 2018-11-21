/*******************************************************************************************************************************
 
    Source File Name:   data_store_dm_info.prg
    Object Name:        data_store_dm_info
 
    Author:             Nick Klockenga
 
    Program Purpose:    Library for storing long text data in dm_info by key

    Executing From:     Other CCL Objects

    Special Notes:      All subroutines are copy type
                        
********************************************************************************************************************************
*       MODIFICATION CONTROL LOG
********************************************************************************************************************************
 
  Mod  Date            Engineer       Comment
  ---  ----------      -------------  -------------------------------------------------------------------------------------
  001  07/02/2018      Nick Klockenga  
 
*******************************************************************************************************************************/
set trace translatelock go
drop program data_store_dm_info:dba go
create program data_store_dm_info:dba

;preventing data_store_dm_info from being defined more than once
if(validate(DATA_STORE::DSDI_IS_DEFINED) = 0)
declare DATA_STORE::DSDI_IS_DEFINED = i1 with constant(1), persistscript
declare DATA_STORE::DSDI_DEBUG_LOG = i1 with noconstant(0), persistscript
declare DATA_STORE::DSDI_MAXVARLENGTH = i4 with noconstant(268435456), persistscript ;256 MB MAX

set modify maxvarlen value(DATA_STORE::DSDI_MAXVARLENGTH)

;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA STORE GLOBALS ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;do not change unless you know exactly what your doing
declare DATA_STORE::INFO_DOMAIN = vc with noconstant("DATA_STORE_DM_INFO"), persistscript

;;;;;;;;;;;;;;;;;;;;;;;;
;;      MAIN API      ;;
;;;;;;;;;;;;;;;;;;;;;;;;

declare dsdi_write_using_key_ocf(lib_key = vc, lib_data = vc(ref, " "))                                   = i4 with copy
declare dsdi_write_using_key(lib_key = vc, lib_data = vc(ref, " "))                                       = i4 with copy
declare dsdi_fetch_using_key(lib_key = vc, lib_data = vc(ref, " "))                                       = i4 with copy
declare dsdi_remove_using_key(lib_key = vc)                                                               = i4 with copy
declare dsdi_last_updt_using_key(lib_key = vc)                                                            = f8 with copy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; INTERNAL/PRIVATE API (NOT DESIGNED FOR USE OUTSIDE OF THIS EXE ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

declare lib_dsdi_remove_using_key(lib_key = vc, commit_ind = i4(val, 0))                                  = i4 with copy
declare lib_log_dsdi(output = vc)                                                                         = null with copy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; INTERNAL INCLUDE FILE VARIABLE DEFINITIONS ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

subroutine dsdi_write_using_key_ocf(lib_key, lib_data)

    declare DATA_STORE::IS_OCF_COMPRESSED = i4 with constant(1), protect
    record DATA_STORE::data ( 1 compressed = vc ) with protect

    set DATA_STORE::outBuf          = fillstring(value(DATA_STORE::DSDI_MAXVARLENGTH), " ")
    declare DATA_STORE::bufsize     = i4 with noconstant(0) , protect
    declare DATA_STORE::newsize     = i4 with noconstant(0) , protect
    declare DATA_STORE::datasize    = i4 with noconstant(0) , protect

    set DATA_STORE::datasize = size(lib_data)
    set DATA_STORE::bufsize = size(DATA_STORE::outBuf)
    set DATA_STORE::stat = uar_ocf_compress(lib_data, DATA_STORE::datasize,
                                            DATA_STORE::outBuf, DATA_STORE::bufsize, DATA_STORE::newsize)

    call lib_log_dsdi(concat("==============================================================================================="))
    call lib_log_dsdi(concat("dsdi_write_using_key_ocf subroutine in the data_store_dm_info executable"))
    call lib_log_dsdi(concat("==============================================================================================="))
    call lib_log_dsdi(concat("Key Name       : ", trim(lib_key,3)))
    call lib_log_dsdi(concat("Info Domain    : ", trim(DATA_STORE::INFO_DOMAIN,3)))
    call lib_log_dsdi(concat("Data Size      : ", trim(cnvtstring(DATA_STORE::datasize,18,0),3), " Bytes"))
    call lib_log_dsdi(concat("Compressed Size: ", trim(cnvtstring(DATA_STORE::newsize,18,0),3) , " Bytes"))

    if(DATA_STORE::stat = 1)
        set DATA_STORE::data->compressed = substring(1,DATA_STORE::newsize,DATA_STORE::outBuf)
        return(dsdi_write_using_key(lib_key, DATA_STORE::data->compressed))
    else
        call lib_log_dsdi("dsdi_write_using_key_ocf, failed to compress and save data")
        call cclexception(950, "E", "dsdi_write_using_key_ocf, failed to compress and save data")
        return(0)
    endif

end

subroutine dsdi_write_using_key(lib_key, lib_data)

    declare DATA_STORE::idx                             = i4 with noconstant(0), protect
    declare DATA_STORE::pos                             = i4 with noconstant(0), protect
    declare DATA_STORE::len                             = i4 with noconstant(0), protect
    declare DATA_STORE::errmsg                          = c132 with noconstant(" "), protect
    declare DATA_STORE::errcode                         = i4 with noconstant(1), protect
    declare DATA_STORE::stat                            = i4 with noconstant(0), protect
    declare DATA_STORE::cur_dt_tm                       = dq8 with constant(cnvtdatetime(curdate, curtime3)), protect
    declare DATA_STORE::user_id                         = f8 with noconstant(0.0),protect
    declare DATA_STORE::updt_task                       = i4 with noconstant(0), protect
    declare DATA_STORE::updt_applctx                    = i4 with noconstant(0), protect
    declare DATA_STORE::info_char                       = vc with noconstant(" "), protect
    
    ;lib_key must be >= 5 charts and <= 200 and does not contain a pipe char
    if(textlen(trim(lib_key,3)) < 5 or textlen(trim(lib_key,3)) > 200 or findstring("|",lib_key,1,1) > 0)
        call lib_log_dsdi("dsdi_write_using_key, lib_key must be 5 to 200 chars long and not contain a pipe char")
        call cclexception(950, "E", "dsdi_write_using_key, lib_key must be 5 to 200 chars long and not contain a pipe char")
        return(0)
    endif
    
    if(validate(reqinfo))
        if(validate(reqinfo->user_id))
            set DATA_STORE::user_id = reqinfo->user_id
        endif
        if(validate(reqinfo->updt_task))
            set DATA_STORE::updt_task = reqinfo->updt_task
        endif
        if(validate(reqinfo->updt_applctx))
            set DATA_STORE::updt_applctx = reqinfo->updt_applctx
        endif
    endif
    
    if(DATA_STORE::user_id = 0.0)
        set DATA_STORE::user_id = 1.0 ;Default to System Id
    endif
    
    if(validate(DATA_STORE::IS_OCF_COMPRESSED))
        if(DATA_STORE::IS_OCF_COMPRESSED = 1)
            set DATA_STORE::info_char = "OCF COMPRESSION"
        endif
    else
        set DATA_STORE::info_char = "PLAIN TEXT"
        ;display log messages if not displayed by ocf compress subroutine
        call lib_log_dsdi(concat("==============================================================================================="))
        call lib_log_dsdi(concat("dsdi_write_using_key subroutine in the data_store_dm_info executable"))
        call lib_log_dsdi(concat("==============================================================================================="))
        call lib_log_dsdi(concat("Key Name       : ", trim(lib_key,3)))
        call lib_log_dsdi(concat("Info Domain    : ", trim(DATA_STORE::INFO_DOMAIN,3)))
        call lib_log_dsdi(concat("Data Size      : ", trim(cnvtstring(size(lib_data),18,0),3), " Bytes"))
    endif

    record DATA_STORE::data (
        1 cnt = i4
        1 size = i4
        1 list[*]
            2 info_name = vc
            2 info_domain = vc
            2 text = vc
            2 info_long_id = f8
    ) with protect
    
    ;break data into data record structure
    call lib_log_dsdi(concat("Data Parts"))
    set DATA_STORE::data->cnt = floor((size(lib_data)/32000)) + 1
    set DATA_STORE::data->size = size(lib_data)
    call alterlist(DATA_STORE::data->list, DATA_STORE::data->cnt)
    for(DATA_STORE::idx = 1 to DATA_STORE::data->cnt by 1)
        set DATA_STORE::data->list[DATA_STORE::idx].info_name = concat(lib_key, "|", trim(cnvtstring(DATA_STORE::idx,10,0),3))
        set DATA_STORE::data->list[DATA_STORE::idx].info_domain = DATA_STORE::INFO_DOMAIN
        
        if(DATA_STORE::idx = 1)
            ;if first data piece, set position to 1
            set DATA_STORE::pos = 1
        else
            ;if not first data piece, set position to (index - 1) * 32000 + 1 size
            set DATA_STORE::pos = (32000 * (DATA_STORE::idx - 1)) + 1
        endif
        
        if(DATA_STORE::data->size <= 32000)
            set DATA_STORE::len = DATA_STORE::data->size
        else
            set DATA_STORE::len = DATA_STORE::data->size - (32000 * (DATA_STORE::idx - 1))
            if(DATA_STORE::len > 32000)
                set DATA_STORE::len = 32000
            endif
        endif
        
        set DATA_STORE::data->list[DATA_STORE::idx].text = notrim(substring(DATA_STORE::pos, DATA_STORE::len , lib_data))

        call lib_log_dsdi(concat("  Part ", trim(cnvtstring(DATA_STORE::idx,10,0),3), " with info domain ^",
                                DATA_STORE::data->list[DATA_STORE::idx].info_domain, "^ and name ^",
                                DATA_STORE::data->list[DATA_STORE::idx].info_name, "^ is ", 
                                trim(cnvtstring(textlen(DATA_STORE::data->list[DATA_STORE::idx].text),18,0),3), " Bytes"))
        call lib_log_dsdi(concat("     using pos ", trim(cnvtstring(DATA_STORE::pos,18,0),3), " and length ",
                                 trim(cnvtstring(DATA_STORE::len,18,0),3)))
    endfor
    
    call lib_log_dsdi(" ")
    call lib_log_dsdi(concat("Removing existing data with the info_domain and info_name"))
    
    ;delete dm_info if it does exists based on lib_key
    set DATA_STORE::stat = lib_dsdi_remove_using_key(lib_key, 0)
    
    if(DATA_STORE::stat < 0)
        call lib_log_dsdi("lib_dsdi_remove_using_key, delete before write of data to key failed, no commit")
        call cclexception(952, "E", "lib_dsdi_remove_using_key, delete before write of data to key failed, no commit")
        return(0)
    endif
    
    call lib_log_dsdi(concat("Number of Rows to Insert: ", trim(cnvtstring(DATA_STORE::data->cnt,18,0),3)))
    
    ;insert data into long_text
    for(DATA_STORE::idx = 1 to DATA_STORE::data->cnt by 1)
        ;get seq for long_text table
        select into "nl:"
            next_seq = seq(long_data_seq, nextval)
        from
            dual d
        detail
            DATA_STORE::data->list[DATA_STORE::idx].info_long_id = cnvtreal(next_seq)
        with nocounter
        
        call lib_log_dsdi(concat("  insert into long_text with id ",
                         trim(cnvtstring(DATA_STORE::data->list[DATA_STORE::idx].info_long_id,18,2),3)))
        
        ;insert long text data
        insert into long_text lt
        set lt.long_text_id = DATA_STORE::data->list[DATA_STORE::idx].info_long_id
        ,   lt.active_ind = 1
        ,   lt.active_status_cd = 188.00 ;Active
        ,   lt.active_status_dt_tm = cnvtdatetime(DATA_STORE::cur_dt_tm)
        ,   lt.active_status_prsnl_id = DATA_STORE::user_id
        ,   lt.last_utc_ts = cnvtdatetime(DATA_STORE::cur_dt_tm)
        ,   lt.long_text = notrim(DATA_STORE::data->list[DATA_STORE::idx].text)
        ,   lt.parent_entity_id = 0.0
        ,   lt.parent_entity_name = "DM_INFO"
        ,   lt.updt_applctx = DATA_STORE::updt_applctx
        ,   lt.updt_cnt = 1
        ,   lt.updt_dt_tm = cnvtdatetime(DATA_STORE::cur_dt_tm)
        ,   lt.updt_id = DATA_STORE::user_id
        ,   lt.updt_task = DATA_STORE::updt_task
        with nocounter, notrim
    
        call lib_log_dsdi(concat("  insert into dm_info with info_name ",
                         trim(DATA_STORE::data->list[DATA_STORE::idx].info_name,3)))
    
        insert into dm_info di
        set di.info_char = DATA_STORE::info_char
        ,   di.info_date = cnvtdatetime(DATA_STORE::cur_dt_tm)
        ,   di.info_domain = DATA_STORE::data->list[DATA_STORE::idx].info_domain
        ,   di.info_domain_id = 0.0
        ,   di.info_long_id = DATA_STORE::data->list[DATA_STORE::idx].info_long_id
        ,   di.info_name = DATA_STORE::data->list[DATA_STORE::idx].info_name
        ,   di.info_number = 0.0
        ,   di.last_utc_ts = cnvtdatetime(DATA_STORE::cur_dt_tm)
        ,   di.updt_applctx = DATA_STORE::updt_applctx
        ,   di.updt_cnt = 1
        ,   di.updt_dt_tm = cnvtdatetime(DATA_STORE::cur_dt_tm)
        ,   di.updt_id = DATA_STORE::user_id
        ,   di.updt_task = DATA_STORE::updt_task
        with nocounter, notrim
        
    endfor
    
    ;if everything checks out, no errors then commit, else rollback
    set DATA_STORE::errcode = error(DATA_STORE::errmsg, 0)
    if(DATA_STORE::errcode = 0)
        call lib_log_dsdi("-->commit!")
        commit
        return(1)
    else
        rollback
        call lib_log_dsdi(concat("Last Error Message: ", DATA_STORE::errmsg))
        call cclexception(DATA_STORE::errcode, "E", DATA_STORE::errmsg)
        return(0)
    endif

end

subroutine lib_dsdi_remove_using_key(lib_key, commit_ind)

    declare DATA_STORE::idx                             = i4 with noconstant(0), protect
    declare DATA_STORE::pos                             = i4 with noconstant(0), protect
    declare DATA_STORE::errmsg                          = c132 with noconstant(" "), protect
    declare DATA_STORE::errcode                         = i4 with noconstant(1), protect
    
    declare DATA_STORE::part                            = vc with noconstant(" "), protect
    declare DATA_STORE::key_name                        = vc with noconstant(" "), protect
    declare DATA_STORE::pipe_pos                        = i4 with noconstant(0), protect
    declare DATA_STORE::part_cnt                        = i4 with noconstant(0), protect
    declare DATA_STORE::valid_cnt                       = i4 with noconstant(0), protect
    declare DATA_STORE::cur_dt_tm                       = dq8 with constant(cnvtdatetime(curdate, curtime3)), protect
    declare DATA_STORE::user_id                         = f8 with noconstant(0.0),protect
    declare DATA_STORE::updt_task                       = i4 with noconstant(0), protect
    declare DATA_STORE::updt_applctx                    = i4 with noconstant(0), protect

    record DATA_STORE::data (
        1 cnt = i4
        1 list[*]
            2 info_name = vc
            2 info_domain = vc
            2 info_long_id = f8
    ) with protect
    
    ;find data using lib_key
    select into "nl:"
    from
        dm_info di
    plan di
        where di.info_domain = DATA_STORE::INFO_DOMAIN
        and di.info_name = patstring(concat(lib_key,"*"))
        and di.info_name != " "
        and di.info_domain != " "
        and di.info_domain_id = 0.0
        and di.info_long_id != 0.0
    detail
        
        DATA_STORE::pipe_pos = findstring("|", trim(di.info_name,3), 1, 1)
        DATA_STORE::key_name = substring(1,DATA_STORE::pipe_pos - 1, trim(di.info_name,3))
        DATA_STORE::part = substring(DATA_STORE::pipe_pos + 1, textlen(trim(di.info_name,3)) - DATA_STORE::pipe_pos,
                                     trim(di.info_name,3))
        DATA_STORE::valid_cnt = textlen(trim(replace(DATA_STORE::part, "1234567890", "1234567890", 3),3))
        DATA_STORE::part_cnt = textlen(trim(DATA_STORE::part,3))
        
        ;make sure the lib_key is not a partial match and only has the seq as an additional part
        if(DATA_STORE::part_cnt = DATA_STORE::valid_cnt and DATA_STORE::part_cnt > 0 and DATA_STORE::key_name = lib_key)
            DATA_STORE::pos = cnvtint(DATA_STORE::part)
            
            ;set data list size based on max pos
            if(DATA_STORE::data->cnt < DATA_STORE::pos)
                call alterlist(DATA_STORE::data->list, DATA_STORE::pos)
                DATA_STORE::data->cnt = DATA_STORE::pos
            endif
            
            DATA_STORE::data->list[DATA_STORE::pos].info_long_id = di.info_long_id
            DATA_STORE::data->list[DATA_STORE::pos].info_name = di.info_name
            DATA_STORE::data->list[DATA_STORE::pos].info_domain = di.info_domain
        endif
    with nocounter

    call lib_log_dsdi(concat("Number of Rows to Delete: ", trim(cnvtstring(DATA_STORE::data->cnt,18,0),3)))
    
    if(DATA_STORE::data->cnt = 0)
        return(0)
    endif
    
    ;delete dm_info rows
    for(DATA_STORE::idx = 1 to DATA_STORE::data->cnt by 1)
    
        call lib_log_dsdi(concat("  removing dm_info row with info_name ",
                         trim(DATA_STORE::data->list[DATA_STORE::idx].info_name,3)))
    
        delete from dm_info di
        where di.info_domain = DATA_STORE::data->list[DATA_STORE::idx].info_domain
        and di.info_domain != " "
        and di.info_name = DATA_STORE::data->list[DATA_STORE::idx].info_name
        and di.info_name != " "
        and di.info_long_id > 0.0
        with nocounter
        
        call lib_log_dsdi(concat("  removing long_text row with long_text_id ",
                         trim(cnvtstring(DATA_STORE::data->list[DATA_STORE::idx].info_long_id,18,2),3)))
        
        delete from long_text lt
        where lt.long_text_id = DATA_STORE::data->list[DATA_STORE::idx].info_long_id
        and lt.long_text_id != 0
        and lt.parent_entity_name = "DM_INFO"
        with nocounter
       
    endfor
    
    if(commit_ind = 1)
        ;if everything checks out, no errors then commit, else rollback
        set DATA_STORE::errcode = error(DATA_STORE::errmsg, 0)
        if(DATA_STORE::errcode = 0)
            call lib_log_dsdi("-->commit!")
            commit
            return(DATA_STORE::data->cnt)
        else
            rollback
            call lib_log_dsdi(concat("Last Error Message: ", DATA_STORE::errmsg))
            call cclexception(DATA_STORE::errcode, "E", DATA_STORE::errmsg)
            return(-1)
        endif
    else
        ;if successful without commit it will return the number of rows deleted (without commit).
        return(DATA_STORE::data->cnt)
    endif
    
end

subroutine dsdi_remove_using_key(lib_key)
    
    declare DATA_STORE::errmsg      = c132 with noconstant(" "), protect
    declare DATA_STORE::errcode     = i4 with noconstant(1), protect
    declare DATA_STORE::stat        = i4 with noconstant(0), protect
    
    call lib_log_dsdi(concat("==============================================================================================="))
    call lib_log_dsdi(concat("dsdi_remove_using_key subroutine in the data_store_dm_info executable"))
    call lib_log_dsdi(concat("==============================================================================================="))
    call lib_log_dsdi(concat("Info Domain    : ", trim(DATA_STORE::INFO_DOMAIN,3)))
    call lib_log_dsdi(concat("Info Name      : ", trim(lib_key,3)))
    
    set DATA_STORE::stat            = lib_dsdi_remove_using_key(lib_key, 0)
    
    ;if return value from lib_dsdi_remove_using_key is greater than 0 (successful delete)
    if(DATA_STORE::stat > 0)
    
        ;and if everything checks out, no errors ...
        set DATA_STORE::errcode = error(DATA_STORE::errmsg, 0)
        if(DATA_STORE::errcode = 0)
            call lib_log_dsdi("-->commit!")
            commit
            return(DATA_STORE::stat)
        else
            rollback
            call lib_log_dsdi(concat("Last Error Message: ", DATA_STORE::errmsg))
            call cclexception(DATA_STORE::errcode, "E", DATA_STORE::errmsg)
            return(-1)
        endif
        
    endif

end

subroutine dsdi_fetch_using_key(lib_key, lib_data)

    declare DATA_STORE::idx                         = i4 with noconstant(0), protect
    declare DATA_STORE::pos                         = i4 with noconstant(0), protect
    declare DATA_STORE::errmsg                      = c132 with noconstant(" "), protect
    declare DATA_STORE::errcode                     = i4 with noconstant(1), protect
    declare DATA_STORE::part                        = vc with noconstant(" "), protect
    declare DATA_STORE::key_name                    = vc with noconstant(" "), protect
    declare DATA_STORE::pipe_pos                    = i4 with noconstant(0), protect
    declare DATA_STORE::part_cnt                    = i4 with noconstant(0), protect
    declare DATA_STORE::valid_cnt                   = i4 with noconstant(0), protect
    
    record DATA_STORE::data (
        1 cnt = i4
        1 list[*]
            2 info_name = vc
            2 info_domain = vc
            2 info_char = vc
            2 info_long_id = f8
            2 text = vc
        1 text = vc
    ) with protect

    call lib_log_dsdi(concat("==============================================================================================="))
    call lib_log_dsdi(concat("dsdi_fetch_using_key subroutine in the data_store_dm_info executable"))
    call lib_log_dsdi(concat("==============================================================================================="))
    call lib_log_dsdi(concat("Key Name       : ", trim(lib_key,3)))
    call lib_log_dsdi(concat("Info Domain    : ", trim(DATA_STORE::INFO_DOMAIN,3)))

    ;lib_key must be >= 5 charts and <= 200 and does not contain a pipe char
    if(textlen(trim(lib_key,3)) < 5 or textlen(trim(lib_key,3)) > 200 or findstring("|",lib_key,1,1) > 0)
        call lib_log_dsdi("dsdi_fetch_using_key, lib_key must be 5 to 200 chars long and not contain a pipe char")
        call cclexception(950, "E", "dsdi_fetch_using_key, lib_key must be 5 to 200 chars long and not contain a pipe char")
        return(0)
    endif

    ;get long text data
    select into "nl:"
    from
        dm_info di
    ,   long_text lt
    plan di
        where di.info_domain = DATA_STORE::INFO_DOMAIN
        and di.info_name = patstring(concat(lib_key,"*"))
        and di.info_name != " "
        and di.info_domain != " "
        and di.info_domain_id = 0.0
        and di.info_long_id != 0.0
    join lt
        where lt.parent_entity_name = "DM_INFO"
        and lt.long_text_id = di.info_long_id
    detail
        DATA_STORE::pipe_pos = findstring("|", trim(di.info_name,3), 1, 1)
        DATA_STORE::key_name = substring(1,DATA_STORE::pipe_pos - 1, trim(di.info_name,3))
        DATA_STORE::part = substring(DATA_STORE::pipe_pos + 1, textlen(trim(di.info_name,3)) - DATA_STORE::pipe_pos,
                                     trim(di.info_name,3))
        DATA_STORE::valid_cnt = textlen(trim(replace(DATA_STORE::part, "1234567890", "1234567890", 3),3))
        DATA_STORE::part_cnt = textlen(trim(DATA_STORE::part,3))
        
        ;make sure the lib_key is not a partial match and only has the seq as an additional part
        if(DATA_STORE::part_cnt = DATA_STORE::valid_cnt and DATA_STORE::part_cnt > 0 and DATA_STORE::key_name = lib_key)
            DATA_STORE::pos = cnvtint(DATA_STORE::part)
            
            ;set data list size based on max pos
            if(DATA_STORE::data->cnt < DATA_STORE::pos)
                call alterlist(DATA_STORE::data->list, DATA_STORE::pos)
                DATA_STORE::data->cnt = DATA_STORE::pos
            endif
            
            DATA_STORE::data->list[DATA_STORE::pos].info_long_id = di.info_long_id
            DATA_STORE::data->list[DATA_STORE::pos].info_name = di.info_name
            DATA_STORE::data->list[DATA_STORE::pos].info_domain = di.info_domain
            DATA_STORE::data->list[DATA_STORE::pos].text = lt.long_text
            DATA_STORE::data->list[DATA_STORE::pos].info_char = di.info_char
        endif
    with nocounter

    call lib_log_dsdi(concat("Part Count     : ", trim(cnvtstring(DATA_STORE::data->cnt,10,0),3)))
    
    if(DATA_STORE::data->cnt = 0)
        return(0)
    endif

    ;combine data record into single text output
    for(DATA_STORE::idx = 1 to DATA_STORE::data->cnt by 1)
        set DATA_STORE::data->text = notrim(concat(notrim(DATA_STORE::data->text),
                                                   notrim(DATA_STORE::data->list[DATA_STORE::idx].text)))
    endfor

    if(DATA_STORE::data->list[1].info_char = "OCF COMPRESSION")
    
        ;uncompress data
        set DATA_STORE::outBuf          = fillstring(value(DATA_STORE::DSDI_MAXVARLENGTH), " ")
        declare DATA_STORE::bufsize     = i4 with noconstant(0) , protect
        declare DATA_STORE::newsize     = i4 with noconstant(0) , protect
        declare DATA_STORE::datasize    = i4 with noconstant(0) , protect
    
        set DATA_STORE::datasize = size(DATA_STORE::data->text)
        set DATA_STORE::bufsize = size(DATA_STORE::outBuf)
        set stat = uar_ocf_uncompress(DATA_STORE::data->text, DATA_STORE::datasize,
                                                  DATA_STORE::outBuf, DATA_STORE::bufsize, DATA_STORE::newsize)
    
        call lib_log_dsdi(concat("Compressed Size: ", trim(cnvtstring(DATA_STORE::datasize,18,0),3)))
        set DATA_STORE::data->text = substring(1,DATA_STORE::newsize,DATA_STORE::outBuf)
    endif

    call lib_log_dsdi(concat("Data Size      : ", trim(cnvtstring(size(DATA_STORE::data->text),18,0),3)))

    set lib_data = DATA_STORE::data->text

    return(1)

end

subroutine dsdi_last_updt_using_key(lib_key)

    declare DATA_STORE::idx                         = i4 with noconstant(0), protect
    declare DATA_STORE::pos                         = i4 with noconstant(0), protect
    declare DATA_STORE::part                        = vc with noconstant(" "), protect
    declare DATA_STORE::key_name                    = vc with noconstant(" "), protect
    declare DATA_STORE::pipe_pos                    = i4 with noconstant(0), protect
    declare DATA_STORE::part_cnt                    = i4 with noconstant(0), protect
    declare DATA_STORE::valid_cnt                   = i4 with noconstant(0), protect
    
    record DATA_STORE::data (
        1 cnt = i4
        1 list[*]
            2 info_name = vc
            2 info_domain = vc
            2 info_char = vc
            2 info_long_id = f8
            2 last_updt = dq8
        1 last_updt = dq8
    ) with protect

    call lib_log_dsdi(concat("==============================================================================================="))
    call lib_log_dsdi(concat("dsdi_last_updt_using_key subroutine in the data_store_dm_info executable"))
    call lib_log_dsdi(concat("==============================================================================================="))
    call lib_log_dsdi(concat("Key Name       : ", trim(lib_key,3)))
    call lib_log_dsdi(concat("Info Domain    : ", trim(DATA_STORE::INFO_DOMAIN,3)))

    ;lib_key must be >= 5 charts and <= 200 and does not contain a pipe char
    if(textlen(trim(lib_key,3)) < 5 or textlen(trim(lib_key,3)) > 200 or findstring("|",lib_key,1,1) > 0)
        call lib_log_dsdi("dsdi_last_updt_using_key, lib_key must be 5 to 200 chars long and not contain a pipe char")
        call cclexception(950, "E", "dsdi_last_updt_using_key, lib_key must be 5 to 200 chars long and not contain a pipe char")
        return(0)
    endif

    ;get long text data
    select into "nl:"
    from
        dm_info di
    ,   long_text lt
    plan di
        where di.info_domain = DATA_STORE::INFO_DOMAIN
        and di.info_name = patstring(concat(lib_key,"*"))
        and di.info_name != " "
        and di.info_domain != " "
        and di.info_domain_id = 0.0
        and di.info_long_id != 0.0
    join lt
        where lt.parent_entity_name = "DM_INFO"
        and lt.long_text_id = di.info_long_id
    detail
        DATA_STORE::pipe_pos = findstring("|", trim(di.info_name,3), 1, 1)
        DATA_STORE::key_name = substring(1,DATA_STORE::pipe_pos - 1, trim(di.info_name,3))
        DATA_STORE::part = substring(DATA_STORE::pipe_pos + 1, textlen(trim(di.info_name,3)) - DATA_STORE::pipe_pos,
                                     trim(di.info_name,3))
        DATA_STORE::valid_cnt = textlen(trim(replace(DATA_STORE::part, "1234567890", "1234567890", 3),3))
        DATA_STORE::part_cnt = textlen(trim(DATA_STORE::part,3))
        
        ;make sure the lib_key is not a partial match and only has the seq as an additional part
        if(DATA_STORE::part_cnt = DATA_STORE::valid_cnt and DATA_STORE::part_cnt > 0 and DATA_STORE::key_name = lib_key)
            DATA_STORE::pos = cnvtint(DATA_STORE::part)
            
            ;set data list size based on max pos
            if(DATA_STORE::data->cnt < DATA_STORE::pos)
                call alterlist(DATA_STORE::data->list, DATA_STORE::pos)
                DATA_STORE::data->cnt = DATA_STORE::pos
            endif
            
            DATA_STORE::data->list[DATA_STORE::pos].last_updt = di.info_date
            DATA_STORE::data->list[DATA_STORE::pos].info_long_id = di.info_long_id
            DATA_STORE::data->list[DATA_STORE::pos].info_name = di.info_name
            DATA_STORE::data->list[DATA_STORE::pos].info_domain = di.info_domain
            DATA_STORE::data->list[DATA_STORE::pos].info_char = di.info_char
        endif
    with nocounter
    
    call lib_log_dsdi(concat("Part Count     : ", trim(cnvtstring(DATA_STORE::data->cnt,10,0),3)))
    
    if(DATA_STORE::data->cnt = 0)
        return(0)
    endif
    
    set DATA_STORE::data->last_updt = DATA_STORE::data->list[1].last_updt

    return(DATA_STORE::data->last_updt)
    
end

subroutine lib_log_dsdi(output)
    if(DATA_STORE::DSDI_DEBUG_LOG = 1)
        call echo(output)
    endif
end

set last_data_store_dm_info_version = "001 07/02/2018 By Nick Klockenga"

endif ;DATA_STORE::DSDI_IS_DEFINED

end
go
