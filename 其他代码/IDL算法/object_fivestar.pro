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
;�������ʾ
PRO OBJECT_FIVESTAR
  ;����α���
  sidenumber = 5
  r = 1
  ;�㼰���ӹ�ϵ������ֵ
  points = [0.,0]
  polylines = 0
  ;
  ica = 2*!pi/sidenumber
  startAngle = !pi /(2*sidenumber)
  ;ѭ�����ɵ㼰���ӹ�ϵ
  FOR curs =0,sidenumber -1 DO BEGIN
    curPoints = [r*COS(startAngle +curs*ica),r*SIN(startAngle +curs*ica)]
    points = [[points],[curPoints]]
    polylines = [polylines,2,curs, (curs+2) MOD sidenumber]
  ENDFOR
  ;�޳���ʼֵ
  points = points[*,1:(N_ELEMENTS(points)/2-1)]
  polylines = polylines[1:N_ELEMENTS(polylines)-1]
  ;��ʾ
  XOBJVIEW, OBJ_NEW('IDLgrPolyline',points, $
    polylines = polylines)
    
END