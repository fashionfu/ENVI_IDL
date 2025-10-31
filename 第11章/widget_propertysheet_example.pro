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
;��������
;
;Բ�����ඨ��Դ��,�̳�IDLgrPolygon��
;�����ʾ��init�����������tlb������

;��������
PRO IDLgrCircle::CLEANUP
  ;����IDLgrPolygon����������
  self->IDLGRPOLYGON::CLEANUP
END

;���Ի�ȡ
PRO IDLgrCircle::GetProperty,Center = Center, $
    Radius = Radius, _REF_EXTRA=_extra ; ��ȡ���ø��������, Ҫʹ��_Ref_Extra
  IF (ARG_PRESENT(Center)) THEN center = self.center
  IF (ARG_PRESENT(Radius)) THEN radius = self.radius
  ;self->IDLGRPOLYGON::GETPROPERTY, _EXTRA = re
  IF (N_ELEMENTS(_extra) GT 0) THEN $
    self->IDLGRPOLYGON::GETPROPERTY, _EXTRA=_extra
END
;��������
PRO IDLgrCircle::SetProperty, Center = Center, $
    Radius = Radius, _REF_EXTRA = e ; ��ȡ���ø��������, Ҫʹ��_Ref_Extra
  ;Բ�����趨��Ϊ��ά
  IF (N_ELEMENTS(Center) NE 0) THEN BEGIN
    IF (N_ELEMENTS(Center) EQ 2) THEN  self.Center = center
  ENDIF
  ;Բ�뾶���趨
  IF (N_ELEMENTS(Radius) NE 0) THEN BEGIN
    IF (N_ELEMENTS(Radius) EQ 1) THEN  self.Radius = Radius
  ENDIF
  ;����Բ
  self->BUILDCIRCLE
  ;���������
  self->IDLGRPOLYGON::SETPROPERTY, $
    DATA = TRANSPOSE([[self.xcoords],[self.ycoords]]), _EXTRA = e
END
;ˢ����ʾ
PRO IDLgrCircle::Refresh
  XOBJVIEW, REFRESH=self.xObjViewTlb
END
;������ʾ
PRO IDLgrCircle::Show

  XOBJVIEW, self,TLB=xObjViewTlb, GROUP=self.tlb
  ;����XOBJVIEW�Ľ���ID
  self.xObjViewTlb = xObjViewTlb
END
;����Բ�ĺͰ뾶����Բ
PRO IDLgrCircle::BuildCircle
  self.xcoords = self.Center[0] + self.Radius * COS(INDGEN(361) * !DtoR)
  self.ycoords = self.Center[1] + self.Radius * SIN(INDGEN(361) * !DtoR)
END
;Բ�������ʼ��
FUNCTION IDLgrCircle::INIT, tlb, Center = Center, $
    Radius = Radius,_EXTRA = e
  ;��ʼ����ʶ
  initSucess =1b
  ;�洢�������ID
  self.tlb = tlb
  ;Բ�����趨��Ϊ��ά
  IF (N_ELEMENTS(Center) NE 0) THEN BEGIN
    IF (N_ELEMENTS(Center) EQ 2) THEN  self.Center = center ELSE BEGIN
      self.center = [0,0]
      initSucess =0b
    ENDELSE
  ENDIF ELSE self.center = [0,0]
  
  ;Բ�뾶���趨
  IF (N_ELEMENTS(Radius) NE 0) THEN BEGIN
    IF (N_ELEMENTS(Radius) EQ 1) THEN  self.Radius = Radius ELSE BEGIN
      initSucess =0b
      self.Radius = 1
    ENDELSE
  ENDIF ELSE self.Radius = 1
  
  ;����buildCircle��������
  self->BUILDCIRCLE
  self.SHOW
  ;�̳�IDLgrPolygon����ĳ�ʼ������
  initSucess = self->IDLGRPOLYGON::INIT(self.xcoords, $
    self.YCOORDS, self.zcoords, _EXTRA = e)
  ;���س�ʼ���ɹ���־
  RETURN, initSucess
END

;Բ�����ඨ��
PRO IDLGRCIRCLE__DEFINE
  struct = { IDLgrCircle, $
    tlb : 0L, $
    xObjViewTlb : 0L, $
    INHERITS IDLGRPOLYGON, $
    center:FLTARR(2), $
    xcoords:FINDGEN(361), $
    ycoords:FINDGEN(361), $
    zcoords:FINDGEN(361), $
    Radius:0.}
END

;�����Ӧ�¼�����
PRO WIDGET_PROPERTYSHEET_EXAMPLE_EVENT, event
  ;����޸�������ֵ
  IF (event.type EQ 0) THEN BEGIN 
    ;��ȡ�����ʶ���޸ĵ�����
    value = WIDGET_INFO(event.ID, COMPONENT = event.component, $
      PROPERTY_VALUE = event.identifier) 
    ;�����������������.
    event.component->SETPROPERTYBYIDENTIFIER, event.identifier, $
      value
    ;����ˢ����ʾ��������ˢ��
    event.component->refresh
    ;����̨���
    PRINT, '�޸ĵ�������: ', event.identifier, ': ', value    
  ENDIF   
END
;��������
PRO WIDGET_PROPERTYSHEET_EXAMPLE_cleanup, wID
  WIDGET_CONTROL, wID, GET_UVALUE=obj
  ;���ٶ���
  OBJ_DESTROY, obj
END

;���Խ��������ʾ
PRO WIDGET_PROPERTYSHEET_EXAMPLE

  ;����tlb����.
  tlb = WIDGET_BASE(/TLB_SIZE_EVENT, $
    TITLE = '���Խ�����ʾ', $
    KILL_NOTIFY = 'WIDGET_PROPERTYSHEET_EXAMPLE_cleanup')
  
  ;����Բ����
  oCircle = OBJ_NEW('IDLgrCircle', $
    tlb, $
    /REGISTER_PROPERTIES)
  ;����Բ��name���Բ���
  oCircle->Setpropertyattribute, 'name', /Hide
  ;�޸�Բ�����Բ���descriptionΪ'�Զ���Բ����'
  oCircle->Setpropertyattribute, 'description',name = '�Զ���Բ����'
  ;ע��IDLgrCircle�еĸ��Ӳ������Ե����ý���
  oCircle->IDLitComponent::RegisterProperty,'Radius',3,name='�뾶'
  ;���������޸Ľ������
  prop = WIDGET_PROPERTYSHEET(tlb, $
    VALUE = oCircle,$
    ySize = 20)    
  ;��ʾ���
  WIDGET_CONTROL, tlb, SET_UVALUE = oCircle, /REALIZE
  
  ;�����¼���Ӧ
  XMANAGER, 'WIDGET_PROPERTYSHEET_EXAMPLE', tlb, /NO_BLOCK  
END
