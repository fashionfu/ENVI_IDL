;+
;  ��IDL������ơ�
;   -���ݿ��ӻ���ENVI���ο���
;        
; ʾ������
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;-
;+
;ENVI���ο������ܴ���
;
;Author: DYQ
;�������ۣ�
; http://hi.baidu.com/dyqwrp
; http://bbs.esrichina-bj.cn/ESRI/?fromuid=9806
;������
;ͼ���ں�
;
;���÷�����
;CAL_SHARPEN,inputfileMulti,inputfilePan,outputfile,method
;inputfileMulti�ǵͷֱ��ʵĶ����Ӱ��
;inputfilePan�Ǹ߷�ȫɫӰ��
;
;Method : 0-HSV�ں�
;         1-color-normalized�ں�
;         2-Gram-Schmidt�ں�
;         3-���ɷݷ����ں�
;-
PRO CAL_SHARPEN,inputfileMulti,inputfilePan,outputfile,method
  COMPILE_OPT idl2
  CATCH, Error_status
  errorshow = 'Sorry to see the error,'+ $
    ' please send the error Information to "dongyq@esrichina-bj.cn"'
  IF Error_status NE 0 THEN BEGIN
    tmp = DIALOG_MESSAGE(errorshow+STRING(13b)+$
      !ERROR_STATE.MSG,/error,title = '������ʾ!')
    RETURN
  ENDIF
  ;��ȫɫӰ��
  ENVI_OPEN_FILE, inputfilePan, r_fid=h_fid
  IF (h_fid EQ -1) THEN BEGIN
    ENVI_BATCH_EXIT
    RETURN
  ENDIF
  ;��ȡӰ�����    ;
  ENVI_FILE_QUERY, h_fid, ns=h_ns, nl=h_nl,$
    dims = h_dims,nb = h_nb
    
  ; �򿪶����Ӱ��
  ENVI_OPEN_FILE, inputfileMulti, r_fid=m_fid
  IF (m_fid EQ -1) THEN BEGIN
    ENVI_BATCH_EXIT
    RETURN
  ENDIF
  ;��ȡӰ�����
  ENVI_FILE_QUERY, m_fid, dims=m_dims, $
    bnames=m_bnames,nb = m_nb
    
  IF method LT 2 THEN BEGIN
    ; Set the keywords
    f_dims = [-1l, 0, h_ns-1, 0, h_nl-1]
    f_pos  = [0]
    ;
    rgb_fid = [m_fid,m_fid,m_fid]
    out_bname = ['3','2','1']
    ;ENVI���ںϹ���
    ENVI_DOIT, 'sharpen_doit', $
      fid=rgb_fid, pos=LINDGEN(m_nb), f_fid=h_fid, $
      f_dims=f_dims, f_pos=f_pos, $
      out_name=outputfile, method=1, $
      interp=0, out_bname=out_bname
    RETURN
  ENDIF
  
  CASE  method OF
    ;
    2: BEGIN
      out_bname = 'GS_Sharpen_band_'+STRTRIM(LINDGEN(m_nb),2)
      ENVI_DOIT, 'ENVI_GS_SHARPEN_DOIT', $
        DIMS= m_dims, $
        fID = m_fid, $
        HIRES_DIMS = h_dims, $
        HIRES_FID = h_fid,$
        HIRES_POS = LINDGEN(h_nb),$
        INTERP = 2,$
        METHOD = 0 ,$
        OUT_BNAME = out_bname , $
        OUT_NAME = outputfile,$
        POS =LINDGEN(m_nb)
    END
    3: BEGIN
      out_bname = 'PC_Sharpen_band_'+STRTRIM(LINDGEN(m_nb),2)
      ENVI_DOIT, 'ENVI_PC_SHARPEN_DOIT', $
        DIMS= m_dims, $
        fID = m_fid, $
        HIRES_DIMS = h_dims, $
        HIRES_FID = h_fid,$
        HIRES_POS = LINDGEN(h_nb),$
        INTERP = 2,$
        OUT_BNAME = out_bname , $
        OUT_NAME = outputfile,$
        POS =LINDGEN(m_nb)
    END
    ELSE:
  ENDCASE
END