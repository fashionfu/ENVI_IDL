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
PRO USING_BLAS_AXPY
  ;��ʼ����������
  X = LINDGEN(4000,4000)
  Y = LINDGEN(4000,4000)
  ;��¼��ʼʱ��
  start = SYSTIME(1)
  FOR i=0,9 DO BEGIN
    Y=x*3+Y
  ENDFOR
  PRINT,'����ֱ��������ʱ:',SYSTIME(1)-start
  ;
  X = LINDGEN(4000,4000)
  Y = LINDGEN(4000,4000)
  start = SYSTIME(1)
  FOR i=0,9 DO BEGIN
    BLAS_AXPY, Y, 3, X
  ENDFOR
  PRINT,'BLAS_AXPY������ʱ:',SYSTIME(1)-start
END