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
PRO HELLOWORLD
  ;����IDL�Դ�����������
  jpgfile = FILEPATH('people.jpg', SUBDIRECTORY=['examples','data'])
  ;��ȡJPEG�ļ�
  READ_JPEG,jpgfile,data,/true
  ;������ʾ����
  WINDOW,1,title ='��ɫͷ����ʾ', $
    xsize = (SIZE(data,/dimension))[2], $
    ysize = (SIZE(data,/dimension))[2]
  ;��ɫ����ͼ��
  TV,data,/true
  ;ѡ��Ի���
  tmp = DIALOG_MESSAGE('�ر���ʾ���ڲ���',/default_No,/Question)
  IF tmp EQ 'Yes' THEN WDELETE,1
END
