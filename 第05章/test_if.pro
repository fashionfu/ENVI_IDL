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
PRO TEST_IF,num,div
  IF((num MOD 2) EQ 0) THEN BEGIN
    tmp = DIALOG_MESSAGE(STRING(num)+' ��ż����')
  ENDIF
  IF((num MOD div) EQ 0) THEN BEGIN
    tmp = DIALOG_MESSAGE(STRING(num)+'�ܹ���'+STRING(div)+'������')
  ENDIF ELSE BEGIN
    tmp = DIALOG_MESSAGE(STRING(num)+'���ܹ���'+STRING(div)+'������')
  ENDELSE
  IF 0 THEN BEGIN
  ENDIF ELSE IF 0 THEN BEGIN
  ENDIF ELSE IF 1 THEN BEGIN
    PRINT,'end'
  ENDIF
END