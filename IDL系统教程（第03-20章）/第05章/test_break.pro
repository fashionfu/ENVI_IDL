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
PRO TEST_BREAK
  I = 0
  WHILE (1) DO BEGIN
    i = i + 1
    IF (i EQ 5) THEN BREAK
    PRINT,i
  ENDWHILE
  PRINT,'Start For'
  FOR i=2,10 DO BEGIN
    IF i EQ 5 THEN CONTINUE
    PRINT,i
  ENDFOR
END