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
FUNCTION FUN_TOTAL, x,y
  RETURN, x+y
END


PRO usingfunction
  a = 1
  b = 2
  result = FUN_TOTAL(a,b)
  PRINT,result
END
;

