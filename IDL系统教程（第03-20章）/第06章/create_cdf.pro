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
PRO CREATE_CDF
  ;��ȡ��ǰ�ļ�����Ŀ¼
  curDir = FILE_DIRNAME(ROUTINE_FILEPATH('create_cdf'),/mark_directory)
  ;����Ҫ��ȡ��jpeg�ļ�
  jpegfile =curDir+'data\idl.jpg'
  ;�ж��ļ��Ƿ���ڣ�����������ʾ��ϢȻ���˳�
  IF ~FILE_TEST(jpegFile) THEN BEGIN
    void = DIALOG_MESSAGE('jpeg�ļ������ڣ�',/Error)
    RETURN
  ENDIF
  ;��ȡjpeg�ļ�
  READ_JPEG, jpegFile,data
  ;��ȡ������Ϣ
  dimensions = SIZE(data,/dimensions)
  ;���������cdf�ļ�
  cdfFile = curDir+'data\example.cdf'
  ;�ļ����Ѿ�������ɾ��
  IF FILE_TEST(cdfFile) THEN FILE_DELETE, cdfFile
  ;����CDF�ļ����������ݴ�С������CDF�ļ�ID
  Id  = CDF_CREATE(cdfFile,dimensions)
  ;��������title
  dummy = CDF_ATTCREATE(Id, "TITLE", /GLOBAL)
  ;д������title����
  CDF_ATTPUT, Id, "TITLE", 0, "idl.jpg"
  ;������������
  VarId = CDF_VARCREATE(Id,'jpgfile', ['VARY', 'VARY', 'VARY'])
  ;д������
  CDF_VARPUT, Id, VarId, Data
  
  ;�ر�CDF�ļ�ID
  CDF_CLOSE, Id
  
END