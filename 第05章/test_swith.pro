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
PRO TEST_SWITH
  x=2  
  SWITCH x OF
    1: PRINT,'one'
    2: PRINT,'two'
    3: PRINT,'three'
    4: PRINT, 'four'
  ENDSWITCH
  PRINT,'end'
END