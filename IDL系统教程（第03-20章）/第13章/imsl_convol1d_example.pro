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
PRO IMSL_Convol1d_example
  IMSL_RANDOMOPT, SET = 1234579L
  ;�������������
  ny = 100
  t = FINDGEN(ny)/(ny-1)
  y = SIN(2*!PI*t) + .5*IMSL_RANDOM(ny, /Uniform) -.25
  ; Define a 1-period sine wave with added noise.
  win=0
  FOR nfltr = 5, 25, 20 DO BEGIN
    nfltr_str = STRCOMPRESS(nfltr,/Remove_All)
    fltr = FLTARR(nfltr)
    fltr(*) = 1./nfltr
    ;�������.
    z = IMSL_CONVOL1D(fltr, y, /Periodic)
    ;ѭ���������ڣ���ʾ����
    WINDOW, win++,xsize =600,ysize=400
    PLOT, y, LINESTYLE = 1, TITLE = nfltr_str + $
      '-point Moving Average'
    OPLOT, SHIFT(z, -nfltr/2)
  ENDFOR
END