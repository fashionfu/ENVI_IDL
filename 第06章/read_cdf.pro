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
PRO READ_CDF
  ;��ȡ��ǰ�ļ�����Ŀ¼
  curDir = FILE_DIRNAME(ROUTINE_FILEPATH('READ_CDF'),/mark_directory)
  ;����Ҫ��ȡ��cdf�ļ�
  cdfFile = curDir+'data\example.cdf'
  ;�ж��ļ��Ƿ���ڣ�����������ʾ��ϢȻ���˳�
  IF ~FILE_TEST(cdfFile) THEN BEGIN
    void = DIALOG_MESSAGE('cdf�ļ������ڣ�',/Error)
    RETURN
  ENDIF
  ;��cdf�ļ�����ȡ�ļ�ID
  Id  = CDF_OPEN(cdfFile)
  ;��ȡ����TITLE�����ݣ��洢��title������
  CDF_ATTGET, Id, "TITLE", 0, Title
  ;��ȡjpgfile����������
  CDF_VARGET, Id, 'jpgfile', Data
  ;���ɫ��ʽ��ʾ
  TVSCL, Data,/true
 
  ;��ʾ�����м����title
  XYOUTS, !d.X_SIZE/2, !d.Y_SIZE - 20, ALIGNMENT=0.5, /DEVICE, $
    STRING(title)
  ;�ر��ļ�ID
  CDF_CLOSE, Id
END