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
PRO WIDGET_DRAW_EXAMPLE
  ;����base
  tlb = WIDGET_BASE(title='ֱ��ͼ�η�')
  ;����ֱ��ͼ�η���draw
  wDraw = WIDGET_DRAW(tlb, $
    xSize =200,ySize =200)
  ;��ʾ
  WIDGET_CONTROL,tlb,/realize
  WIDGET_CONTROL, wDraw,get_value = ddraw
  HELP, ddraw
  ;��ʾһ��ͼ��
  WSET,ddraw
  TVSCL,DIST(200)
  ;����tlb1
  tlb1 = WIDGET_BASE(title='����ͼ�η�', $
    xOffset = 200)
  ;�������󷨵�draw
  wDraw1 = WIDGET_DRAW(tlb1, $
    xSize =200,ySize =200, $
    graphics_level = 2,$
    /DRAG_NOTIFY , $
    /wheel_events, $
    retain = 2, $
    /Expose_events )
  ;��ʾ
  WIDGET_CONTROL,tlb1,/realize
  ;��ȡdraw��value
  WIDGET_CONTROL, wDraw1,get_value = odraw
  oDraw.Draw,Obj_New('IDLgrView')
  
  HELP,odraw
END