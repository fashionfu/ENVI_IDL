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
;
;����(b1+b2)/(b1-b2)��������������
;
FUNCTION bm_divz, b1, b2, check=check, div_zero=div_zero

  ;���������check�ؼ���
  IF (KEYWORD_SET(check)) THEN BEGIN
    ; ����ĸΪ0ʱ�Ĵ���ʽ
    IF (N_ELEMENTS(div_zero) GT 0) THEN $
      temp_value = div_zero $
    ELSE temp_value = 0.0

    ; ��λ������Ϊ0����Ԫ
    temp = FLOAT(b1) - b2
    ptr = WHERE(temp EQ 0, count)

    ;�����0ֵ��������Ϊ1
    IF (count GT 0) THEN temp(ptr) = 1

    ;�����ֵ
    result = (FLOAT(b1) + b2) / temp

    ; ��������˳�0������
    IF (count GT 0) THEN result(ptr) = temp_value

  ENDIF ELSE BEGIN

    ;�������0ֵ�ı�ֵ
    result = (FLOAT(b1) + b2) / (FLOAT(b1) - b2)

  ENDELSE

  RETURN, result

END
