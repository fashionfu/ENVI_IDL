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
;Բ�����ඨ��Դ��,�̳�IDLgrPolygon��

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
  if (N_Elements(_extra) gt 0) then $
        self->IDLgrPolygon::GetProperty, _EXTRA=_extra
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
;������ʾ
PRO IDLgrCircle::Show
  XOBJVIEW, self
END
;����Բ�ĺͰ뾶����Բ
PRO IDLgrCircle::BuildCircle
  self.xcoords = self.Center[0] + self.Radius * COS(INDGEN(361) * !DtoR)
  self.ycoords = self.Center[1] + self.Radius * SIN(INDGEN(361) * !DtoR)
END
;Բ�������ʼ��
FUNCTION IDLgrCircle::INIT, Center = Center, $
    Radius = Radius,_EXTRA = e ; ��ʼ������, ��_Extra
  initSucess =1b
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
  ;�̳�IDLgrPolygon����ĳ�ʼ������
  initSucess = self->IDLGRPOLYGON::INIT(self.xcoords, $
    self.YCOORDS, self.zcoords, _EXTRA = e)
  ;���س�ʼ���ɹ���־
  RETURN, initSucess
END
;Բ�����ඨ��
PRO IDLGRCIRCLE__DEFINE
  struct = { IDLgrCircle, $
    INHERITS IDLGRPOLYGON, $
    center:FLTARR(2), $
    xcoords:FINDGEN(361), $
    ycoords:FINDGEN(361), $
    zcoords:FINDGEN(361), $
    Radius:0.}
END

;oCircle = OBJ_NEW('IDLgrCircle',[0,0])
;PRINT,OBJ_VALID(oCircle)
;oCircle = OBJ_NEW('IDLgrCircle',[0,0],1.5)
;oCircle->GETPROPERTY,Radius = r
;PRINT,r
;oCircle.SHOW

