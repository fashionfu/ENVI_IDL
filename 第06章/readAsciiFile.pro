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
PRO READASCIIFILE
  ;�Ի���ѡ���ļ�
  asciifile= DIALOG_PICKFILE(title='����ascii.txt',$
    filter = '*.txt',$
    path = FILE_DIRNAME(ROUTINE_FILEPATH('READASCIIFILE')))
  ;���ļ�
  OPENR,lun,asciifile,/get_lun
  
  IF lun EQ -1 THEN BEGIN
    void = DIALOG_MESSAGE('�ļ�����',/error)
    RETURN
  ENDIF
  ;��һ�ֶ���
  ;ȫ�������ַ�����ʽ��ȡ�����ڿ���̨����ַ���
  tmp = ''
  WHILE(~EOF(lun)) DO BEGIN
    READF,lun,tmp
    PRINT,tmp
  ENDWHILE
  ;�ر��ļ�
  FREE_LUN,lun
  ;�ڶ��ֶ���
  ;�����������Ͷ�ȡ
  tmp = INTARR(3)
  str = STRARR(2)
  data = FLTARR(2,4)
  
  OPENR,lun,asciifile,/get_lun
  READF,lun,tmp
  READF,lun,str
  READF,lun,data
  ;�ر��ļ�
  FREE_LUN,lun
END