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

PRO USINGJAVA
  JObj      = OBJ_NEW("IDLJavaObject$java_display_image", "Java_display_image", $
    "IDL calling JAVA", $
    FILEPATH('avhrr.png', SUBDIRECTORY=['examples','data']), $
    720, 360)
END