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

PRO ENVI_BATCH_MODE

  COMPILE_OPT IDL2
  ;�ָ�ENVI��sav�ļ�
  ENVI, /RESTORE_BASE_SAVE_FILES
  ;��ʼ��ENVI����������־�ļ�
  ENVI_BATCH_INIT, log_file='batch.LOG'
  ;ENVI�������ļ�
  ENVI_OPEN_FILE, fname, r_fid=fid
  ;���δѡ���ļ����ļ��޷���
  IF (fid EQ -1) THEN BEGIN
    ;ENVI���ο���ģʽ�ر�
    ENVI_BATCH_EXIT
    RETURN
  ENDIF
  ;��ѯ�ļ���Ϣ
  ENVI_FILE_QUERY, fid,fName = fileName
  ;�Ի�����ʾ�ļ�����
  tmp = DIALOG_MESSAGE(fileName,/infor)
  ;ENVI���ο���ģʽ�ر�
  ENVI_BATCH_EXIT

END