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
PRO test_goto

  GOTO, JUMP1
  PRINT, 'Skip this' ; This statement is skipped
  PRINT, 'Skip this' ; This statement is also skipped
  JUMP1: PRINT, 'Do this'
  
END