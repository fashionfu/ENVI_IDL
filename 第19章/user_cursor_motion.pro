;+
;         ��IDL������ơ�
; --���ݿ��ٿ��ӻ���ENVI���ο��������̣�
;
; ʾ��Դ����
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;
;-

PRO USER_CURSOR_MOTION, dn, $
    xfloc, yfloc,$
    xstart=xstart, $
    ystart=ystart, $
    event=event
  COMPILE_OPT IDL2
  ;��갴��
  IF (event.PRESS EQ 1) THEN BEGIN
    DISP_GET_LOCATION, dn, xfloc, yfloc
    PRINT,'�����ʱλ�ã�', xfloc, yfloc
  ENDIF
  ;��굯��
  IF (event.RELEASE EQ 1) THEN BEGIN
    DISP_GET_LOCATION, dn, xfloc, yfloc
    PRINT,'��굯��ʱλ�ã�', xfloc, yfloc
  ENDIF
END

