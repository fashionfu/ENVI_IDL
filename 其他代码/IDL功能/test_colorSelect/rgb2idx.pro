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
FUNCTION RGB2IDX, RGB

  return, rgb[0] + (rgb[1]*2L^8) + (rgb[2]*2L^16)
  
END





























