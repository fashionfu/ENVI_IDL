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
FUNCTION PF_ZERO_MEAN, x, y, bbl, bbl_array, _extra=_extra
  Bbl_ptr=WHERE(bbl_array EQ 1,count)
  IF(count GT 0) THEN $
    Result=y-(TOTAL(y[bbl_ptr])/count) $
  ELSE $
    Result=FLTARR(N_ELEMENTS(y))
  RETURN, result
END
