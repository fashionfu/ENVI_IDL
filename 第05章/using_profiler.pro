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
PRO USING_PROFILER
  ;
  PROFILER, /SYSTEM
  a =  DIST(2000,2000)
  sum = 0.
  sum1 = 0.
  FOR i=0L,N_ELEMENTS(a)-1L DO IF(a[i] GT 100.0)THEN sum = sum +a[i]
  i=0L
  WHILE i LT N_ELEMENTS(a)-1L DO BEGIN
    IF(a[i] GT 100.0)THEN sum = sum +a[i]
    i++
  ENDWHILE
  sum = TOTAL(a * (a GT 100.0))
  PROFILER,/REPORT
END
