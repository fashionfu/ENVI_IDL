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
; :Description:
;   Runs FX in batch with input and output filenames specificed by command line arguments.
; :Author:
;   Benjamin D. Kamphaus
; :Requires:
;   ENVI license
; :Copyright:
;   ITT Visual Information Solutions
;  Modified By DYQ
;   2011��5��5��
;-
PRO ENVI_FX, folder, ruleSetFilename, outFolder
  COMPILE_OPT idl2, hidden
  ;��ʼ��ENVI���ο���ģʽ
  ENVI,/RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT;�粻ϣ������ENVI�����������"/No_Status_Window"
  ;�����������ݵ�������չ��
  fileExtension='tif'
  ;�������Ϊ���򷵻�
  IF (folder EQ '') THEN RETURN
  ;���������ļ�
  imgFiles=FILE_SEARCH(folder,'*.'+fileExtension,/FOLD_CASE,COUNT=count)
  ;�����Ƿ���������Ҫ��
  ruleFileExist = FILE_TEST(ruleSetFilename)
  outFolderExist = FILE_TEST(outFolder,/directory)
  IF (count EQ 0)OR ~ruleFileExist OR ~outFolderExist THEN BEGIN
    void=DIALOG_MESSAGE(['������Ҫ������ļ�:',$
      '',folder])
    RETURN
  ENDIF
  
  ;�����ļ���������ѭ������
  FOR i = 0 ,(count-1) DO BEGIN
    ;�ļ����������Ϣ��ѯ
    ENVI_OPEN_FILE, imgFiles[i], R_FID=fid
    IF (fid EQ -1) THEN BEGIN
      CONTINUE
    ENDIF
    ENVI_FILE_QUERY, fid, DIMS=dims, NS=ns, NL=nl, NB=nb
    pos = LINDGEN(nb)
    ;��������ļ���
    shpFile=outFolder+path_sep()+FILE_BASENAME(imgFiles[i],fileExtension)+'shp'
    ;ִ��ENVI��Feature Extraction����
    ENVI_DOIT, 'ENVI_FX_DOIT', fid=fid, dims=dims, pos=pos, scale_level=40.0, merge_level=95.0, $
      ruleset_filename=ruleSetFilename, vector_filename=shpFile, smoothing_threshold=0.0, $
      r_fid=r_fid
      
  ENDFOR
  
END