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
PRO USING_CATCH

  CATCH, error_status
  
  A = INDGEN(6)
  ;��������Ϣ
  IF Error_status NE 0 THEN BEGIN
    PRINT, 'Error index: ', Error_status
    PRINT, 'Error message: ', !ERROR_STATE.MSG
    ;���¶���A
    A = INDGEN(7)
    CATCH, /CANCEL
  ENDIF
  
  A[6]=12
  PRINT, A
  
END
