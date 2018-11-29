/*******************************************************************************************************************************
 
    Source File Name:   msj_csv_lib_py.prg
    Object Name:        msj_csv_lib_py
 
    Author:             Nick Klockenga
    Product Team:       MSJH_NC IT Application Developement
 
    Program Purpose:    

    Executing From:     Other CCL Objects

    Special Notes:      
                        
********************************************************************************************************************************
*       MODIFICATION CONTROL LOG
********************************************************************************************************************************
 
  Mod  Date            Engineer       Comment
  ---  ----------      -------------  -------------------------------------------------------------------------------------
  001  11/30/2018      Nick Klockenga  Created Library, uses Python script to parse csv to json
 
*******************************************************************************************************************************/
set trace translatelock go
drop program msj_csv_lib_py:dba go
create program msj_csv_lib_py:dba

;preventing msj_ccl_lib from being defined more than once
if(validate(CSV::IS_DEFINED) = 0)
declare CSV::IS_DEFINED = i1 with constant(1), persistscript

;;; PUBLIC API subroutines ;;;
declare read_csv_to_rec(lib_csvfullfilename = vc, lib_rec_output_flag = i2(value, 1)) = vc with copy

;;; INTERNAL subroutines ;;;
;;; not designed for use ;;;

declare csv_write_to_file(lib_fullfilename = vc, lib_out = vc, lib_open_mode = vc(value, "a+"))                 = i4 with copy

declare csv_rec_create(lib_rec_output_flag = i2) = null with copy

;;;;;;;;;;;;;;;;;;;
;;; DEFINITIONS ;;;
;;;;;;;;;;;;;;;;;;;

subroutine csv_rec_create(lib_rec_output_flag)

    free record CSV::headers
    free record CSV::flat
    free record CSV::data

    /*

    record CSV::headers (
        1 xcnt = i4
        1 x[*]
            2 value = vc
            2 name = vc
    ) with persistscript
    
    if(lib_rec_output_flag = 3)
    
        record CSV::data (
            1 cnt = i4
            1 column[*]
                2 value = vc
                2 row[*]
                    3 value = vc
        ) with persistscript
        
    endif
    
    */

end

subroutine csv_write_to_file(lib_fullfilename, lib_out, lib_open_mode)

    declare CSV::stat = i4 with noconstant(0)  , protect
    
    record CSV::frec
    (
        1 file_desc     = i4
        1 file_offset   = i4
        1 file_dir      = i4
        1 file_name     = vc
        1 file_buf      = vc
    ) with protect
    
    ;Open the file with write access
    set CSV::frec->file_name = lib_fullfilename
    set CSV::frec->file_buf = lib_open_mode
    set CSV::stat = cclio("OPEN",CSV::frec)
    
    if(CSV::stat = 0) ;return 0 if file can not be open
        return(CSV::stat)
    endif
    
    set CSV::frec->file_buf = lib_out
    set CSV::stat = cclio("WRITE",CSV::frec)
    
    if(CSV::stat = 0) ;if nubmer of bytes written is 0, return 0
        return(CSV::stat)
    endif
    
    set CSV::stat = cclio("CLOSE",CSV::frec)
    
    return(CSV::stat)
end

subroutine read_csv_to_rec(lib_csvfullfilename, lib_rec_output_flag)

    declare CSV::stat = i4 with noconstant(0)  , protect
    declare CSV::length = i4 with noconstant(0)  , protect
    declare CSV::buffer = vc with noconstant(" "), protect
    declare CSV::contents = vc with noconstant(" "), protect
    declare CSV::command = vc with noconstant(" "), protect
    declare CSV::logical_path = vc with noconstant(" "), protect
    declare CSV::csvfullfilename = vc with noconstant(" "), protect
    declare CSV::python_script = vc with noconstant(" "), protect
    declare CSV::python_script_file = vc with noconstant(" "), protect
    declare CSV::json_output_file = vc with noconstant(" "), protect
    
    set CSV::csvfullfilename = lib_csvfullfilename
    
    declare CSV::new_maxvarlength = i4 with noconstant(268435456), protect ;256 MB MAX
    declare CSV::old_maxvarlength = i4 with noconstant(0), protect
    
    record CSV::frec
    (
        1 file_desc     = i4
        1 file_offset   = i4
        1 file_dir      = i4
        1 file_name     = vc
        1 file_buf      = vc
    ) with protect

    call csv_rec_create(lib_rec_output_flag)

    set CSV::old_max_varlength = CURMAXVARLEN
    set modify maxvarlen value(CSV::new_maxvarlength)

    declare CSV::python_binary = vc with noconstant(" "), protect

    ;check which python version exists
    if(findfile("/usr/bin/python2.6"))
        set CSV::python_binary = "/usr/bin/python2.6"
    elseif(findfile("/usr/bin/python2.7"))
        set CSV::python_binary = "/usr/bin/python2.7"
    elseif(findfile("/usr/bin/python"))
        set CSV::python_binary = "/usr/bin/python"
    else
        call cclexception(999, 'E', "could not find python binary, this is required for csv parsing")
        return(-1)
    endif

    ;check for and replace logical
    set pos = findstring(":",trim(trim(CSV::csvfullfilename,3),3),1,1)
    if(pos > 0)
        ;a ":" was found in the file path
        set CSV::logical_pat = trim(logical(substring(1,pos - 1,trim(CSV::csvfullfilename,3))),3)
        if(textlen(trim(CSV::logical_pat,3)) > 0)
            set CSV::csvfullfilename = concat(trim(CSV::logical_pat,3), "/", substring(pos + 1,
                                                       textlen(trim(CSV::csvfullfilename,3)), trim(CSV::csvfullfilename,3)))
        endif
    endif

    ;check if the input file exists
    if(findfile(CSV::csvfullfilename))
        call echo(notrim(concat("file found: ", CSV::csvfullfilename)))
    else
        call cclexception(999, 'E', "could not find file passed into read_csv_to_rec")
        return(0)
    endif

    ;identify temp space for creating files
    declare CSV::temp = vc with noconstant(" "), protect
    set CSV::temp = trim(logical("CER_TEMP", 255),3)
    if(textlen(trim(CSV::temp,3)) = 0)
        ;could not find cer_temp, use ccluserdir instead
        set CSV::temp = trim(logical("CCLUSERDIR", 255),3)
    endif

    if(textlen(trim(CSV::temp,3)) = 0)
        call cclexception(999, 'E', "temp space not found, this is required for csv parsing")
        return(0)
    endif
    
    ;temp json output location
    set CSV::json_output_file = concat("json_out_", format(systimestamp,"yymmddhhmmsscc;;d"),trim(cnvtlower(CURPRCNAME),3),".json")
    set CSV::json_output_file = notrim(concat(CSV::temp, "/", CSV::json_output_file))

    call echo(concat("CSV::json_output_file: ", CSV::json_output_file))

    ;write out python script to temp location
    set CSV::python_script = concat("import csv",                                   								CHAR(10),
                                    "import json",         															CHAR(10),
                                    "import re",         															CHAR(10),
                                    "a = []",         																CHAR(10),
                                    "with open('",
                                    CSV::csvfullfilename,
                                    "', mode='r') as i:",         								                    CHAR(10),
                                    " x = csv.DictReader(i)",         												CHAR(10),
                                    " for r in x:",         														CHAR(10),
                                    "  b = { re.sub(r'\W+', '', re.sub('\s+', '_', k)): v for k, v in r.items() }", CHAR(10),
                                    "  a.append(b)",         														CHAR(10),
                                    "with open('",
                                    CSV::json_output_file,
                                    "', 'w') as o:",         				CHAR(10),
                                    " json.dump(a, o)")

    set CSV::python_script_file = concat("csv_script_",format(systimestamp,"yymmddhhmmsscc;;d"),trim(cnvtlower(CURPRCNAME),3),".py")
    set CSV::python_script_file = notrim(concat(CSV::temp, "/", CSV::python_script_file))

    set CSV::stat = csv_write_to_file(CSV::python_script_file,CSV::python_script,"w+")

    ;execute python script to create json file
    set status = -1
    set dclstat = -1

    set CSV::command = concat(CSV::python_binary , " ", CSV::python_script_file)
    set CSV::length = textlen(CSV::command)

    call echo(concat("CSV::command: ", CSV::command))

    set dclstat = dcl(CSV::command,CSV::length,status) ;For linux, 1 = successful
 
    call echo(build2("Command DCLStatus:", dclstat))
    call echo(build2("Command Status:", status))

    ;remove python script
    set stat = remove(CSV::python_script_file)

    ;read in json file to string variable
    set CSV::frec->file_name = CSV::json_output_file
    set CSV::frec->file_buf = "r"
    set CSV::stat = cclio("OPEN",CSV::frec)
    
    if(CSV::stat > 0 and CSV::frec->file_desc != 0)
        ;Jump to the end of the file
        set CSV::frec->file_dir = 2
        set CSV::stat = cclio("SEEK",CSV::frec)
        if(CSV::stat = 0)
            ;Determine file size
            set CSV::length = cclio("TELL",CSV::frec)
            set CSV::stat = memrealloc(CSV::buffer,1,build("C",CSV::length))
            if(CSV::stat > 0)
                ;Jump to the beginning of the file
                set CSV::frec->file_dir = 0
                set CSV::stat = cclio("SEEK",CSV::frec)                
                set CSV::frec->file_buf=notrim(CSV::buffer)
                set CSV::buffer = " "
                if(CSV::stat = 0)
                    ;Read in file
                    set CSV::stat = cclio("READ",CSV::frec)
                    set CSV::contents=notrim(CSV::frec->file_buf)
                endif
            endif
         endif
    endif
    
    set CSV::stat = cclio("CLOSE",CSV::frec)
    ;remove json file
    set stat = remove(CSV::json_output_file)

    ;convert json string to record structure
    set CSV::contents = concat(^{"CSV_DATA":{"LIST":^, CSV::contents, ^}}^)
    set stat = cnvtjsontorec(CSV::contents,10,0,0)
    set stat = renamerec(CSV_DATA, CSV::data)

    ;build record structure to match output flag
    ;to do, need to transverse record structure list to get header names

    ;restore maxvarlen to previous value
    set modify maxvarlen value(CSV::old_maxvarlength)

end

set last_csv_lib_version = "001 11/30/2018 By Nick Klockenga"

endif ;CSV::IS_DEFINED

end
go
