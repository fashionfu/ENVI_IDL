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
PRO TEST_CONTINUE

  FOR i = 1,5 DO BEGIN
    IF (i GT 2) THEN CONTINUE
    PRINT, i
  ENDFOR
  PRINT,'end'
END