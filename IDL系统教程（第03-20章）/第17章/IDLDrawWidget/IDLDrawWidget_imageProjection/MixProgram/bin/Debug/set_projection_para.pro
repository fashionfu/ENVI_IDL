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
function set_projection_para
  oMapProjection = OBJ_NEW('ProjectionParameter', $
    Name='�趨ͶӰ����' , $
    projection=3        , $
    datum='WGS84'       )
  ;
  wTlb = Widget_Base(/column)
  wSetBase = Widget_Base(wTlb)
  Widget_Control,wTlb,/Realize  

  pSheet = WIDGET_PROPERTYSHEET( $
    wSetBase, $
    Value = oMapProjection, $
    /Sunken_Frame, $
    Scr_XSize = 310, $
    YSize = 15, $
    UName = 'pSheet', $
    /Multiple_Properties)
    
     prevImage = oMapProjection->Getpreview()
  WSET, wPrevID
  TV, prevImage
end