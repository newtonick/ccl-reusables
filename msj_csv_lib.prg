/*******************************************************************************************************************************
 
    Source File Name:   msj_csv_lib.prg
    Object Name:        msj_csv_lib
 
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
  001  11/16/2018      Nick Klockenga  Created Library
 
*******************************************************************************************************************************/
set trace translatelock go
drop program msj_csv_lib:dba go
create program msj_csv_lib:dba

;preventing msj_ccl_lib from being defined more than once
if(validate(CSV::IS_DEFINED) = 0)
declare CSV::IS_DEFINED = i1 with constant(1), persistscript

declare read_csv_to_rec(lib_csvfullfilename = vc, lib_rec_output_flag = i2(value, 2)) = vc with copy

;flag meaning:
; 0) flat unamed without header
; 1) flat unnamed with header
; 2) flat named list (default) - requires a header row
; 3) group structure columns and rows

declare csv_rec_create(lib_rec_output_flag = i2) = null with copy

subroutine csv_rec_create(lib_rec_output_flag)

    free record CSV::headers
    free record CSV::flat
    free record CSV::data

    if(lib_rec_output_flag > 0)

        record CSV::headers (
            1 xcnt = i4
            1 x[*]
                2 value = vc
                2 name = vc
        ) with persistscript
        
    endif
    
    record CSV::flat (
        1 cnt = i4
        1 list[*]
            2 col_a  = vc
            2 col_b  = vc
            2 col_c  = vc
            2 col_d  = vc
            2 col_e  = vc
            2 col_f  = vc
            2 col_g  = vc
            2 col_h  = vc
            2 col_i  = vc
            2 col_j  = vc
            2 col_k  = vc
            2 col_l  = vc
            2 col_m  = vc
            2 col_n  = vc
            2 col_o  = vc
            2 col_p  = vc
            2 col_q  = vc
            2 col_r  = vc
            2 col_s  = vc
            2 col_t  = vc
            2 col_u  = vc
            2 col_v  = vc
            2 col_w  = vc
            2 col_x  = vc
            2 col_y  = vc
            2 col_z  = vc
            2 col_aa = vc
            2 col_ab = vc
            2 col_ac = vc
            2 col_ad = vc
            2 col_ae = vc
            2 col_af = vc
            2 col_ag = vc
            2 col_ah = vc
            2 col_ai = vc
            2 col_aj = vc
            2 col_ak = vc
            2 col_al = vc
            2 col_am = vc
            2 col_an = vc
            2 col_ao = vc
            2 col_ap = vc
            2 col_aq = vc
            2 col_ar = vc
            2 col_as = vc
            2 col_at = vc
            2 col_au = vc
            2 col_av = vc
            2 col_aw = vc
            2 col_ax = vc
            2 col_ay = vc
            2 col_az = vc
            2 col_ba = vc
            2 col_bb = vc
            2 col_bc = vc
            2 col_bd = vc
            2 col_be = vc
            2 col_bf = vc
            2 col_bg = vc
            2 col_bh = vc
            2 col_bi = vc
            2 col_bj = vc
            2 col_bk = vc
            2 col_bl = vc
            2 col_bm = vc
            2 col_bn = vc
            2 col_bo = vc
            2 col_bp = vc
            2 col_bq = vc
            2 col_br = vc
            2 col_bs = vc
            2 col_bt = vc
            2 col_bu = vc
            2 col_bv = vc
            2 col_bw = vc
            2 col_bx = vc
            2 col_by = vc
            2 col_bz = vc
            2 col_ca = vc
            2 col_cb = vc
            2 col_cc = vc
            2 col_cd = vc
            2 col_ce = vc
            2 col_cf = vc
            2 col_cg = vc
            2 col_ch = vc
            2 col_ci = vc
            2 col_cj = vc
            2 col_ck = vc
            2 col_cl = vc
            2 col_cm = vc
            2 col_cn = vc
            2 col_co = vc
            2 col_cp = vc
            2 col_cq = vc
            2 col_cr = vc
            2 col_cs = vc
            2 col_ct = vc
            2 col_cu = vc
            2 col_cv = vc
            2 col_cw = vc
            2 col_cx = vc
            2 col_cy = vc
            2 col_cz = vc
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

end

subroutine read_csv_to_rec(lib_csvfullfilename, lib_rec_output_flag)

    call csv_rec_create(lib_rec_output_flag)

    declare CSV::new_maxvarlength = i4 with noconstant(268435456), protect ;256 MB MAX
    declare CSV::old_maxvarlength = i4 with noconstant(0), protect

    set CSV::old_max_varlength = CURMAXVARLEN
    set modify maxvarlen value(CSV::new_maxvarlength)

    declare CSV::stat = i4 with noconstant(0)  , protect
    declare CSV::length = i4 with noconstant(0)  , protect
    declare CSV::buffer = vc with noconstant(" "), protect
    declare CSV::contents = vc with noconstant(" "), protect
    declare CSV::pos = i4 with noconstant(0), protect
    declare CSV::coln = i4 with noconstant(0), protect
    declare CSV::line = i4 with noconstant(0),protect
    declare CSV::linh = i4 with noconstant(0),protect
    declare CSV::curr = c1 with noconstant(CHAR(0)), protect
    declare CSV::prev = c1 with noconstant(CHAR(0)), protect 
    declare CSV::eol = i2 with noconstant(0), protect

    declare CSV::open_quote = i2 with noconstant(0), protect
    declare CSV::quote_escaped = i2 with noconstant(0), protect
    declare CSV::skip_value = i2 with noconstant(0), protect
    
    record CSV::frec
    (
        1 file_desc     = i4
        1 file_offset   = i4
        1 file_dir      = i4
        1 file_name     = vc
        1 file_buf      = vc
    ) with protect
    
    ;Open the file with read access
    set CSV::frec->file_name = lib_csvfullfilename
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
    
    ;check for and remove utf-8 BOM
    if(substring(1,3,CSV::contents) = concat(CHAR(239), CHAR(187), CHAR(191)))
        set CSV::contents = substring(4,CSV::length - 3,CSV::contents)
        set CSV::length = CSV::length - 3
    endif
    
    ;set starting line and column numbers to 1
    set CSV::line = 1
    set CSV::linh = 1
    set CSV::coln = 1
    
    for(CSV::pos = 1 to CSV::length by 1)
        
        ;reset end of line to no (0)
        set CSV::eol = 0
        
        ;reset skip value to no (0)
        set CSV::skip_value = 0
        
        ;set CSV::prev = CSV::curr
        set CSV::curr = substring(CSV::pos, 1, CSV::contents)
        
        ;handling special characters
        if(CSV::curr = CHAR(13) or CSV::curr = CHAR(10)) ;end of line
            if(CSV::pos != CSV::length)
                set CSV::next = substring(CSV::pos + 1, 1, CSV::contents)
            else
                set CSV::next = CHAR(0) ;set to null if no next char
            endif
            if(CSV::next = CHAR(13) or CSV::next = CHAR(10)) ;considering CRLF and LFCR case, skipping POS
                set CSV::pos += 1
            endif
            set CSV::coln = 1
            set CSV::eol = 1
            set CSV::skip_value = 1
        elseif(CSV::curr = ^,^ and CSV::open_quote = 0) ;end of column
            set CSV::coln += 1
            set CSV::skip_value = 1
        elseif(CSV::curr = ^"^ and CSV::open_quote = 0) ;opening double quote
            set CSV::open_quote = 1
            set CSV::skip_value = 1
        elseif(CSV::curr = ^"^ and CSV::open_quote = 1) ;handling 2 cases... 1) closing double quote OR 2) escaping double quote
            if(CSV::pos != CSV::length)
                set CSV::next = substring(CSV::pos + 1, 1, CSV::contents)
            else
                set CSV::next = CHAR(0) ;set to null if no next char
            endif
            if(CSV::next = ^"^)
                ;when next char is double quote, then not closing quote. skip next POS, value is double quote
                set CSV::pos += 1
            else
                ;next char is not double quote, closing double quotes
                set CSV::open_quote = 0
                set CSV::skip_value = 1
            endif 
        endif

        ;catching common errors
        if(CSV::eol = 1 and CSV::open_quote = 1) ;end of line before closing quote
            call cclexception(999, 'E', "End of Line Found before Closing Quote")
        endif

        ;;;;;;;;;;;;;;;;;;;;;;;
        ;; X Axis HEADER ROW ;;
        ;;;;;;;;;;;;;;;;;;;;;;;
        if(CSV::line = 1 and lib_rec_output_flag > 0)
            if(CSV::coln > CSV::headers->xcnt and CSV::skip_value = 0)
                ;create new column (attribute)
                set CSV::headers->xcnt += 1
                call alterlist(CSV::headers->x, CSV::headers->xcnt)
            endif

            if(CSV::skip_value = 0)
                set CSV::headers->x[CSV::coln].value = notrim(concat(CSV::headers->x[CSV::coln].value, CSV::curr))
            
                set CSV::headers->x[CSV::coln].name = replace(trim(CSV::headers->x[CSV::coln].value,3),
                                                          "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_ ",
                                                          "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789__", 3)
            endif

        ;;;;;;;;;;;;;;;
        ;; DATA ROWS ;;
        ;;;;;;;;;;;;;;;
        else
        
            if(lib_rec_output_flag > 0)
                set CSV::linh = CSV::line - 1
            else
                set CSV::linh = CSV::line
            endif
            
            if(CSV::linh > CSV::flat->cnt and CSV::skip_value = 0)
                ;create new line
                set CSV::flat->cnt += 1
                call alterlist(CSV::flat->list, CSV::flat->cnt)
            endif
            
            if(CSV::skip_value = 0)
                if(CSV::coln = 1)
                  set CSV::flat->list[CSV::flat->cnt].col_a = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_a, CSV::curr))
                elseif(CSV::coln = 2)
                  set CSV::flat->list[CSV::flat->cnt].col_b = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_b, CSV::curr))
                elseif(CSV::coln = 3)
                  set CSV::flat->list[CSV::flat->cnt].col_c = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_c, CSV::curr))
                elseif(CSV::coln = 4)
                  set CSV::flat->list[CSV::flat->cnt].col_d = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_d, CSV::curr))
                elseif(CSV::coln = 5)
                  set CSV::flat->list[CSV::flat->cnt].col_e = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_e, CSV::curr))
                elseif(CSV::coln = 6)
                  set CSV::flat->list[CSV::flat->cnt].col_f = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_f, CSV::curr))
                elseif(CSV::coln = 7)
                  set CSV::flat->list[CSV::flat->cnt].col_g = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_g, CSV::curr))
                elseif(CSV::coln = 8)
                  set CSV::flat->list[CSV::flat->cnt].col_h = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_h, CSV::curr))
                elseif(CSV::coln = 9)
                  set CSV::flat->list[CSV::flat->cnt].col_i = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_i, CSV::curr))
                elseif(CSV::coln = 10)
                  set CSV::flat->list[CSV::flat->cnt].col_j = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_j, CSV::curr))
                elseif(CSV::coln = 11)
                  set CSV::flat->list[CSV::flat->cnt].col_k = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_k, CSV::curr))
                elseif(CSV::coln = 12)
                  set CSV::flat->list[CSV::flat->cnt].col_l = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_l, CSV::curr))
                elseif(CSV::coln = 13)
                  set CSV::flat->list[CSV::flat->cnt].col_m = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_m, CSV::curr))
                elseif(CSV::coln = 14)
                  set CSV::flat->list[CSV::flat->cnt].col_n = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_n, CSV::curr))
                elseif(CSV::coln = 15)
                  set CSV::flat->list[CSV::flat->cnt].col_o = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_o, CSV::curr))
                elseif(CSV::coln = 16)
                  set CSV::flat->list[CSV::flat->cnt].col_p = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_p, CSV::curr))
                elseif(CSV::coln = 17)
                  set CSV::flat->list[CSV::flat->cnt].col_q = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_q, CSV::curr))
                elseif(CSV::coln = 18)
                  set CSV::flat->list[CSV::flat->cnt].col_r = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_r, CSV::curr))
                elseif(CSV::coln = 19)
                  set CSV::flat->list[CSV::flat->cnt].col_s = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_s, CSV::curr))
                elseif(CSV::coln = 20)
                  set CSV::flat->list[CSV::flat->cnt].col_t = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_t, CSV::curr))
                elseif(CSV::coln = 21)
                  set CSV::flat->list[CSV::flat->cnt].col_u = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_u, CSV::curr))
                elseif(CSV::coln = 22)
                  set CSV::flat->list[CSV::flat->cnt].col_v = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_v, CSV::curr))
                elseif(CSV::coln = 23)
                  set CSV::flat->list[CSV::flat->cnt].col_w = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_w, CSV::curr))
                elseif(CSV::coln = 24)
                  set CSV::flat->list[CSV::flat->cnt].col_x = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_x, CSV::curr))
                elseif(CSV::coln = 25)
                  set CSV::flat->list[CSV::flat->cnt].col_y = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_y, CSV::curr))
                elseif(CSV::coln = 26)
                  set CSV::flat->list[CSV::flat->cnt].col_z = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_z, CSV::curr))
                elseif(CSV::coln = 27)
                  set CSV::flat->list[CSV::flat->cnt].col_aa = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_aa, CSV::curr))
                elseif(CSV::coln = 28)
                  set CSV::flat->list[CSV::flat->cnt].col_ab = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ab, CSV::curr))
                elseif(CSV::coln = 29)
                  set CSV::flat->list[CSV::flat->cnt].col_ac = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ac, CSV::curr))
                elseif(CSV::coln = 30)
                  set CSV::flat->list[CSV::flat->cnt].col_ad = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ad, CSV::curr))
                elseif(CSV::coln = 31)
                  set CSV::flat->list[CSV::flat->cnt].col_ae = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ae, CSV::curr))
                elseif(CSV::coln = 32)
                  set CSV::flat->list[CSV::flat->cnt].col_af = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_af, CSV::curr))
                elseif(CSV::coln = 33)
                  set CSV::flat->list[CSV::flat->cnt].col_ag = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ag, CSV::curr))
                elseif(CSV::coln = 34)
                  set CSV::flat->list[CSV::flat->cnt].col_ah = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ah, CSV::curr))
                elseif(CSV::coln = 35)
                  set CSV::flat->list[CSV::flat->cnt].col_ai = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ai, CSV::curr))
                elseif(CSV::coln = 36)
                  set CSV::flat->list[CSV::flat->cnt].col_aj = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_aj, CSV::curr))
                elseif(CSV::coln = 37)
                  set CSV::flat->list[CSV::flat->cnt].col_ak = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ak, CSV::curr))
                elseif(CSV::coln = 38)
                  set CSV::flat->list[CSV::flat->cnt].col_al = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_al, CSV::curr))
                elseif(CSV::coln = 39)
                  set CSV::flat->list[CSV::flat->cnt].col_am = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_am, CSV::curr))
                elseif(CSV::coln = 40)
                  set CSV::flat->list[CSV::flat->cnt].col_an = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_an, CSV::curr))
                elseif(CSV::coln = 41)
                  set CSV::flat->list[CSV::flat->cnt].col_ao = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ao, CSV::curr))
                elseif(CSV::coln = 42)
                  set CSV::flat->list[CSV::flat->cnt].col_ap = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ap, CSV::curr))
                elseif(CSV::coln = 43)
                  set CSV::flat->list[CSV::flat->cnt].col_aq = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_aq, CSV::curr))
                elseif(CSV::coln = 44)
                  set CSV::flat->list[CSV::flat->cnt].col_ar = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ar, CSV::curr))
                elseif(CSV::coln = 45)
                  set CSV::flat->list[CSV::flat->cnt].col_as = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_as, CSV::curr))
                elseif(CSV::coln = 46)
                  set CSV::flat->list[CSV::flat->cnt].col_at = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_at, CSV::curr))
                elseif(CSV::coln = 47)
                  set CSV::flat->list[CSV::flat->cnt].col_au = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_au, CSV::curr))
                elseif(CSV::coln = 48)
                  set CSV::flat->list[CSV::flat->cnt].col_av = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_av, CSV::curr))
                elseif(CSV::coln = 49)
                  set CSV::flat->list[CSV::flat->cnt].col_aw = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_aw, CSV::curr))
                elseif(CSV::coln = 50)
                  set CSV::flat->list[CSV::flat->cnt].col_ax = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ax, CSV::curr))
                elseif(CSV::coln = 51)
                  set CSV::flat->list[CSV::flat->cnt].col_ay = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ay, CSV::curr))
                elseif(CSV::coln = 52)
                  set CSV::flat->list[CSV::flat->cnt].col_az = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_az, CSV::curr))
                elseif(CSV::coln = 53)
                  set CSV::flat->list[CSV::flat->cnt].col_ba = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ba, CSV::curr))
                elseif(CSV::coln = 54)
                  set CSV::flat->list[CSV::flat->cnt].col_bb = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bb, CSV::curr))
                elseif(CSV::coln = 55)
                  set CSV::flat->list[CSV::flat->cnt].col_bc = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bc, CSV::curr))
                elseif(CSV::coln = 56)
                  set CSV::flat->list[CSV::flat->cnt].col_bd = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bd, CSV::curr))
                elseif(CSV::coln = 57)
                  set CSV::flat->list[CSV::flat->cnt].col_be = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_be, CSV::curr))
                elseif(CSV::coln = 58)
                  set CSV::flat->list[CSV::flat->cnt].col_bf = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bf, CSV::curr))
                elseif(CSV::coln = 59)
                  set CSV::flat->list[CSV::flat->cnt].col_bg = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bg, CSV::curr))
                elseif(CSV::coln = 60)
                  set CSV::flat->list[CSV::flat->cnt].col_bh = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bh, CSV::curr))
                elseif(CSV::coln = 61)
                  set CSV::flat->list[CSV::flat->cnt].col_bi = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bi, CSV::curr))
                elseif(CSV::coln = 62)
                  set CSV::flat->list[CSV::flat->cnt].col_bj = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bj, CSV::curr))
                elseif(CSV::coln = 63)
                  set CSV::flat->list[CSV::flat->cnt].col_bk = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bk, CSV::curr))
                elseif(CSV::coln = 64)
                  set CSV::flat->list[CSV::flat->cnt].col_bl = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bl, CSV::curr))
                elseif(CSV::coln = 65)
                  set CSV::flat->list[CSV::flat->cnt].col_bm = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bm, CSV::curr))
                elseif(CSV::coln = 66)
                  set CSV::flat->list[CSV::flat->cnt].col_bn = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bn, CSV::curr))
                elseif(CSV::coln = 67)
                  set CSV::flat->list[CSV::flat->cnt].col_bo = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bo, CSV::curr))
                elseif(CSV::coln = 68)
                  set CSV::flat->list[CSV::flat->cnt].col_bp = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bp, CSV::curr))
                elseif(CSV::coln = 69)
                  set CSV::flat->list[CSV::flat->cnt].col_bq = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bq, CSV::curr))
                elseif(CSV::coln = 70)
                  set CSV::flat->list[CSV::flat->cnt].col_br = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_br, CSV::curr))
                elseif(CSV::coln = 71)
                  set CSV::flat->list[CSV::flat->cnt].col_bs = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bs, CSV::curr))
                elseif(CSV::coln = 72)
                  set CSV::flat->list[CSV::flat->cnt].col_bt = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bt, CSV::curr))
                elseif(CSV::coln = 73)
                  set CSV::flat->list[CSV::flat->cnt].col_bu = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bu, CSV::curr))
                elseif(CSV::coln = 74)
                  set CSV::flat->list[CSV::flat->cnt].col_bv = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bv, CSV::curr))
                elseif(CSV::coln = 75)
                  set CSV::flat->list[CSV::flat->cnt].col_bw = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bw, CSV::curr))
                elseif(CSV::coln = 76)
                  set CSV::flat->list[CSV::flat->cnt].col_bx = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bx, CSV::curr))
                elseif(CSV::coln = 77)
                  set CSV::flat->list[CSV::flat->cnt].col_by = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_by, CSV::curr))
                elseif(CSV::coln = 78)
                  set CSV::flat->list[CSV::flat->cnt].col_bz = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_bz, CSV::curr))
                elseif(CSV::coln = 79)
                  set CSV::flat->list[CSV::flat->cnt].col_ca = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ca, CSV::curr))
                elseif(CSV::coln = 80)
                  set CSV::flat->list[CSV::flat->cnt].col_cb = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cb, CSV::curr))
                elseif(CSV::coln = 81)
                  set CSV::flat->list[CSV::flat->cnt].col_cc = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cc, CSV::curr))
                elseif(CSV::coln = 82)
                  set CSV::flat->list[CSV::flat->cnt].col_cd = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cd, CSV::curr))
                elseif(CSV::coln = 83)
                  set CSV::flat->list[CSV::flat->cnt].col_ce = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ce, CSV::curr))
                elseif(CSV::coln = 84)
                  set CSV::flat->list[CSV::flat->cnt].col_cf = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cf, CSV::curr))
                elseif(CSV::coln = 85)
                  set CSV::flat->list[CSV::flat->cnt].col_cg = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cg, CSV::curr))
                elseif(CSV::coln = 86)
                  set CSV::flat->list[CSV::flat->cnt].col_ch = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ch, CSV::curr))
                elseif(CSV::coln = 87)
                  set CSV::flat->list[CSV::flat->cnt].col_ci = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ci, CSV::curr))
                elseif(CSV::coln = 88)
                  set CSV::flat->list[CSV::flat->cnt].col_cj = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cj, CSV::curr))
                elseif(CSV::coln = 89)
                  set CSV::flat->list[CSV::flat->cnt].col_ck = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ck, CSV::curr))
                elseif(CSV::coln = 90)
                  set CSV::flat->list[CSV::flat->cnt].col_cl = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cl, CSV::curr))
                elseif(CSV::coln = 91)
                  set CSV::flat->list[CSV::flat->cnt].col_cm = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cm, CSV::curr))
                elseif(CSV::coln = 92)
                  set CSV::flat->list[CSV::flat->cnt].col_cn = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cn, CSV::curr))
                elseif(CSV::coln = 93)
                  set CSV::flat->list[CSV::flat->cnt].col_co = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_co, CSV::curr))
                elseif(CSV::coln = 94)
                  set CSV::flat->list[CSV::flat->cnt].col_cp = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cp, CSV::curr))
                elseif(CSV::coln = 95)
                  set CSV::flat->list[CSV::flat->cnt].col_cq = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cq, CSV::curr))
                elseif(CSV::coln = 96)
                  set CSV::flat->list[CSV::flat->cnt].col_cr = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cr, CSV::curr))
                elseif(CSV::coln = 97)
                  set CSV::flat->list[CSV::flat->cnt].col_cs = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cs, CSV::curr))
                elseif(CSV::coln = 98)
                  set CSV::flat->list[CSV::flat->cnt].col_ct = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_ct, CSV::curr))
                elseif(CSV::coln = 99)
                  set CSV::flat->list[CSV::flat->cnt].col_cu = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cu, CSV::curr))
                elseif(CSV::coln = 100)
                  set CSV::flat->list[CSV::flat->cnt].col_cv = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cv, CSV::curr))
                elseif(CSV::coln = 101)
                  set CSV::flat->list[CSV::flat->cnt].col_cw = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cw, CSV::curr))
                elseif(CSV::coln = 102)
                  set CSV::flat->list[CSV::flat->cnt].col_cx = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cx, CSV::curr))
                elseif(CSV::coln = 103)
                  set CSV::flat->list[CSV::flat->cnt].col_cy = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cy, CSV::curr))
                elseif(CSV::coln = 104)
                  set CSV::flat->list[CSV::flat->cnt].col_cz = notrim(concat(CSV::flat->list[CSV::flat->cnt].col_cz, CSV::curr))
                else
                  call cclexception(999, 'E', "Only 104 Columns Supported")
                endif
            endif
        endif
        
        if(CSV::eol = 1)
            set CSV::line += 1
        endif
        
    endfor

    declare CSV::i = i4 with noconstant(0), protect
    declare CSV::j = i4 with noconstant(0), protect

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Additional Data Processing for flag values >= 2 ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;create data record structure using x axis header names
    if(lib_rec_output_flag = 2)
        declare parse_rec_str = vc with noconstant(" "), protect
        
        set parse_rec_str = notrim("record CSV::data ( 1 cnt = i4 1 list[*] ")
        
        for(CSV::i = 1 to CSV::headers->xcnt by 1)
            set parse_rec_str = notrim(concat(parse_rec_str, " 2 ", CSV::headers->x[CSV::i].name," = vc "))
        endfor
        
        set parse_rec_str = notrim(concat(notrim(parse_rec_str), " ) with persistscript go "))
        ;create record structure
        call parser(parse_rec_str)
        
        if(validate(CSV::data))
            ;if valid record structure, then populate from flat
            set CSV::data->cnt = CSV::flat->cnt
            call alterlist(CSV::data->list, CSV::data->cnt)
            for(CSV::i = 1 to CSV::flat->cnt by 1)
                if(CSV::headers->xcnt >= 1)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[1].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_a go"))
                endif
                if(CSV::headers->xcnt >= 2)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[2].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_b go"))
                endif
                if(CSV::headers->xcnt >= 3)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[3].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_c go"))
                endif
                if(CSV::headers->xcnt >= 4)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[4].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_d go"))
                endif
                if(CSV::headers->xcnt >= 5)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[5].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_e go"))
                endif
                if(CSV::headers->xcnt >= 6)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[6].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_f go"))
                endif
                if(CSV::headers->xcnt >= 7)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[7].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_g go"))
                endif
                if(CSV::headers->xcnt >= 8)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[8].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_h go"))
                endif
                if(CSV::headers->xcnt >= 9)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[9].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_i go"))
                endif
                if(CSV::headers->xcnt >= 10)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[10].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_j go"))
                endif
                if(CSV::headers->xcnt >= 11)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[11].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_k go"))
                endif
                if(CSV::headers->xcnt >= 12)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[12].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_l go"))
                endif
                if(CSV::headers->xcnt >= 13)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[13].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_m go"))
                endif
                if(CSV::headers->xcnt >= 14)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[14].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_n go"))
                endif
                if(CSV::headers->xcnt >= 15)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[15].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_o go"))
                endif
                if(CSV::headers->xcnt >= 16)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[16].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_p go"))
                endif
                if(CSV::headers->xcnt >= 17)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[17].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_q go"))
                endif
                if(CSV::headers->xcnt >= 18)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[18].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_r go"))
                endif
                if(CSV::headers->xcnt >= 19)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[19].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_s go"))
                endif
                if(CSV::headers->xcnt >= 20)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[20].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_t go"))
                endif
                if(CSV::headers->xcnt >= 21)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[21].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_u go"))
                endif
                if(CSV::headers->xcnt >= 22)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[22].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_v go"))
                endif
                if(CSV::headers->xcnt >= 23)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[23].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_w go"))
                endif
                if(CSV::headers->xcnt >= 24)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[24].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_x go"))
                endif
                if(CSV::headers->xcnt >= 25)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[25].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_y go"))
                endif
                if(CSV::headers->xcnt >= 26)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[26].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_z go"))
                endif
                if(CSV::headers->xcnt >= 27)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[27].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_aa go"))
                endif
                if(CSV::headers->xcnt >= 28)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[28].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ab go"))
                endif
                if(CSV::headers->xcnt >= 29)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[29].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ac go"))
                endif
                if(CSV::headers->xcnt >= 30)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[30].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ad go"))
                endif
                if(CSV::headers->xcnt >= 31)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[31].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ae go"))
                endif
                if(CSV::headers->xcnt >= 32)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[32].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_af go"))
                endif
                if(CSV::headers->xcnt >= 33)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[33].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ag go"))
                endif
                if(CSV::headers->xcnt >= 34)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[34].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ah go"))
                endif
                if(CSV::headers->xcnt >= 35)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[35].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ai go"))
                endif
                if(CSV::headers->xcnt >= 36)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[36].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_aj go"))
                endif
                if(CSV::headers->xcnt >= 37)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[37].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ak go"))
                endif
                if(CSV::headers->xcnt >= 38)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[38].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_al go"))
                endif
                if(CSV::headers->xcnt >= 39)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[39].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_am go"))
                endif
                if(CSV::headers->xcnt >= 40)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[40].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_an go"))
                endif
                if(CSV::headers->xcnt >= 41)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[41].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ao go"))
                endif
                if(CSV::headers->xcnt >= 42)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[42].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ap go"))
                endif
                if(CSV::headers->xcnt >= 43)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[43].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_aq go"))
                endif
                if(CSV::headers->xcnt >= 44)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[44].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ar go"))
                endif
                if(CSV::headers->xcnt >= 45)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[45].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_as go"))
                endif
                if(CSV::headers->xcnt >= 46)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[46].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_at go"))
                endif
                if(CSV::headers->xcnt >= 47)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[47].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_au go"))
                endif
                if(CSV::headers->xcnt >= 48)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[48].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_av go"))
                endif
                if(CSV::headers->xcnt >= 49)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[49].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_aw go"))
                endif
                if(CSV::headers->xcnt >= 50)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[50].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ax go"))
                endif
                if(CSV::headers->xcnt >= 51)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[51].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ay go"))
                endif
                if(CSV::headers->xcnt >= 52)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[52].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_az go"))
                endif
                if(CSV::headers->xcnt >= 53)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[53].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ba go"))
                endif
                if(CSV::headers->xcnt >= 54)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[54].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bb go"))
                endif
                if(CSV::headers->xcnt >= 55)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[55].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bc go"))
                endif
                if(CSV::headers->xcnt >= 56)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[56].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bd go"))
                endif
                if(CSV::headers->xcnt >= 57)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[57].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_be go"))
                endif
                if(CSV::headers->xcnt >= 58)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[58].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bf go"))
                endif
                if(CSV::headers->xcnt >= 59)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[59].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bg go"))
                endif
                if(CSV::headers->xcnt >= 60)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[60].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bh go"))
                endif
                if(CSV::headers->xcnt >= 61)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[61].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bi go"))
                endif
                if(CSV::headers->xcnt >= 62)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[62].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bj go"))
                endif
                if(CSV::headers->xcnt >= 63)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[63].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bk go"))
                endif
                if(CSV::headers->xcnt >= 64)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[64].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bl go"))
                endif
                if(CSV::headers->xcnt >= 65)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[65].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bm go"))
                endif
                if(CSV::headers->xcnt >= 66)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[66].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bn go"))
                endif
                if(CSV::headers->xcnt >= 67)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[67].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bo go"))
                endif
                if(CSV::headers->xcnt >= 68)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[68].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bp go"))
                endif
                if(CSV::headers->xcnt >= 69)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[69].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bq go"))
                endif
                if(CSV::headers->xcnt >= 70)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[70].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_br go"))
                endif
                if(CSV::headers->xcnt >= 71)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[71].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bs go"))
                endif
                if(CSV::headers->xcnt >= 72)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[72].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bt go"))
                endif
                if(CSV::headers->xcnt >= 73)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[73].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bu go"))
                endif
                if(CSV::headers->xcnt >= 74)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[74].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bv go"))
                endif
                if(CSV::headers->xcnt >= 75)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[75].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bw go"))
                endif
                if(CSV::headers->xcnt >= 76)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[76].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bx go"))
                endif
                if(CSV::headers->xcnt >= 77)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[77].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_by go"))
                endif
                if(CSV::headers->xcnt >= 78)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[78].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_bz go"))
                endif
                if(CSV::headers->xcnt >= 79)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[79].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ca go"))
                endif
                if(CSV::headers->xcnt >= 80)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[80].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cb go"))
                endif
                if(CSV::headers->xcnt >= 81)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[81].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cc go"))
                endif
                if(CSV::headers->xcnt >= 82)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[82].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cd go"))
                endif
                if(CSV::headers->xcnt >= 83)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[83].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ce go"))
                endif
                if(CSV::headers->xcnt >= 84)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[84].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cf go"))
                endif
                if(CSV::headers->xcnt >= 85)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[85].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cg go"))
                endif
                if(CSV::headers->xcnt >= 86)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[86].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ch go"))
                endif
                if(CSV::headers->xcnt >= 87)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[87].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ci go"))
                endif
                if(CSV::headers->xcnt >= 88)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[88].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cj go"))
                endif
                if(CSV::headers->xcnt >= 89)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[89].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ck go"))
                endif
                if(CSV::headers->xcnt >= 90)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[90].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cl go"))
                endif
                if(CSV::headers->xcnt >= 91)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[91].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cm go"))
                endif
                if(CSV::headers->xcnt >= 92)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[92].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cn go"))
                endif
                if(CSV::headers->xcnt >= 93)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[93].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_co go"))
                endif
                if(CSV::headers->xcnt >= 94)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[94].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cp go"))
                endif
                if(CSV::headers->xcnt >= 95)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[95].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cq go"))
                endif
                if(CSV::headers->xcnt >= 96)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[96].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cr go"))
                endif
                if(CSV::headers->xcnt >= 97)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[97].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cs go"))
                endif
                if(CSV::headers->xcnt >= 98)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[98].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_ct go"))
                endif
                if(CSV::headers->xcnt >= 99)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[99].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cu go"))
                endif
                if(CSV::headers->xcnt >= 100)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[100].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cv go"))
                endif
                if(CSV::headers->xcnt >= 101)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[101].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cw go"))
                endif
                if(CSV::headers->xcnt >= 102)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[102].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cx go"))
                endif
                if(CSV::headers->xcnt >= 103)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[103].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cy go"))
                endif
                if(CSV::headers->xcnt >= 104)
                    call parser(concat("set CSV::data->list[",trim(cnvtstring(CSV::i),3),"].",CSV::headers->x[104].name,
                                       "=CSV::flat->list[",trim(cnvtstring(CSV::i),3),"].col_cz go"))
                endif
            endfor
        endif
        
    endif

    ;create data record structure for columns and rows
    if(lib_rec_output_flag = 3)
        set CSV::data->cnt = CSV::headers->xcnt
        call alterlist(CSV::data->column, CSV::data->cnt)
        for(CSV::i = 1 to CSV::data->cnt by 1)
        
            set CSV::data->column[CSV::i].value = CSV::headers->x[CSV::i].value
            call alterlist(CSV::data->column[CSV::i].row, CSV::flat->cnt)
            for(CSV::j = 1 to CSV::flat->cnt by 1)
                if(CSV::i = 1)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_a
                elseif(CSV::i = 2)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_b
                elseif(CSV::i = 3)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_c
                elseif(CSV::i = 4)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_d
                elseif(CSV::i = 5)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_e
                elseif(CSV::i = 6)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_f
                elseif(CSV::i = 7)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_g
                elseif(CSV::i = 8)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_h
                elseif(CSV::i = 9)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_i
                elseif(CSV::i = 10)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_j
                elseif(CSV::i = 11)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_k
                elseif(CSV::i = 12)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_l
                elseif(CSV::i = 13)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_m
                elseif(CSV::i = 14)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_n
                elseif(CSV::i = 15)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_o
                elseif(CSV::i = 16)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_p
                elseif(CSV::i = 17)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_q
                elseif(CSV::i = 18)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_r
                elseif(CSV::i = 19)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_s
                elseif(CSV::i = 20)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_t
                elseif(CSV::i = 21)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_u
                elseif(CSV::i = 22)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_v
                elseif(CSV::i = 23)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_w
                elseif(CSV::i = 24)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_x
                elseif(CSV::i = 25)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_y
                elseif(CSV::i = 26)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_z
                elseif(CSV::i = 27)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_aa
                elseif(CSV::i = 28)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ab
                elseif(CSV::i = 29)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ac
                elseif(CSV::i = 30)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ad
                elseif(CSV::i = 31)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ae
                elseif(CSV::i = 32)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_af
                elseif(CSV::i = 33)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ag
                elseif(CSV::i = 34)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ah
                elseif(CSV::i = 35)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ai
                elseif(CSV::i = 36)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_aj
                elseif(CSV::i = 37)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ak
                elseif(CSV::i = 38)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_al
                elseif(CSV::i = 39)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_am
                elseif(CSV::i = 40)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_an
                elseif(CSV::i = 41)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ao
                elseif(CSV::i = 42)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ap
                elseif(CSV::i = 43)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_aq
                elseif(CSV::i = 44)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ar
                elseif(CSV::i = 45)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_as
                elseif(CSV::i = 46)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_at
                elseif(CSV::i = 47)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_au
                elseif(CSV::i = 48)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_av
                elseif(CSV::i = 49)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_aw
                elseif(CSV::i = 50)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ax
                elseif(CSV::i = 51)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ay
                elseif(CSV::i = 52)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_az
                elseif(CSV::i = 53)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ba
                elseif(CSV::i = 54)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bb
                elseif(CSV::i = 55)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bc
                elseif(CSV::i = 56)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bd
                elseif(CSV::i = 57)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_be
                elseif(CSV::i = 58)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bf
                elseif(CSV::i = 59)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bg
                elseif(CSV::i = 60)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bh
                elseif(CSV::i = 61)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bi
                elseif(CSV::i = 62)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bj
                elseif(CSV::i = 63)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bk
                elseif(CSV::i = 64)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bl
                elseif(CSV::i = 65)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bm
                elseif(CSV::i = 66)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bn
                elseif(CSV::i = 67)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bo
                elseif(CSV::i = 68)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bp
                elseif(CSV::i = 69)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bq
                elseif(CSV::i = 70)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_br
                elseif(CSV::i = 71)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bs
                elseif(CSV::i = 72)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bt
                elseif(CSV::i = 73)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bu
                elseif(CSV::i = 74)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bv
                elseif(CSV::i = 75)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bw
                elseif(CSV::i = 76)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bx
                elseif(CSV::i = 77)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_by
                elseif(CSV::i = 78)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_bz
                elseif(CSV::i = 79)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ca
                elseif(CSV::i = 80)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cb
                elseif(CSV::i = 81)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cc
                elseif(CSV::i = 82)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cd
                elseif(CSV::i = 83)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ce
                elseif(CSV::i = 84)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cf
                elseif(CSV::i = 85)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cg
                elseif(CSV::i = 86)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ch
                elseif(CSV::i = 87)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ci
                elseif(CSV::i = 88)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cj
                elseif(CSV::i = 89)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ck
                elseif(CSV::i = 90)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cl
                elseif(CSV::i = 91)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cm
                elseif(CSV::i = 92)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cn
                elseif(CSV::i = 93)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_co
                elseif(CSV::i = 94)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cp
                elseif(CSV::i = 95)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cq
                elseif(CSV::i = 96)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cr
                elseif(CSV::i = 97)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cs
                elseif(CSV::i = 98)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_ct
                elseif(CSV::i = 99)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cu
                elseif(CSV::i = 100)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cv
                elseif(CSV::i = 101)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cw
                elseif(CSV::i = 102)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cx
                elseif(CSV::i = 103)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cy
                elseif(CSV::i = 104)
                  set CSV::data->column[CSV::i].row[CSV::j].value = CSV::flat->list[CSV::j].col_cz
                endif
            endfor
        
        endfor
    endif
    
    if(not validate(CSV::data))
        ;if data record strucutre does not exist, rename flat to data
        set stat = renamerec(CSV::flat, CSV::data)
    endif

    set modify maxvarlen value(CSV::old_maxvarlength)

end

set last_csv_lib_version = "001 11/19/2018 By Nick Klockenga"

endif ;CSV::IS_DEFINED

end
go
