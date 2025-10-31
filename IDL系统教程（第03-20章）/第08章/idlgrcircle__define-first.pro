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
;Բ�����ඨ��Դ��,δ��IDLgrPolygon�̳С�
;

;���Ի�ȡ����
PRO IDLgrCircle::GetProperty,Center = Center, Radius = Radius
  IF (ARG_PRESENT(Center)) THEN center = self.CENTER
  IF (ARG_PRESENT(Radius)) THEN radius = self.RADIUS
END
;������ʾ����
PRO IDLgrCircle::Show
  XOBJVIEW,OBJ_NEW('IDLgrPolygon',self.XCOORDS,self.YCOORDS,style =1)
END
;����Բ�ĺͰ뾶����Բ
PRO IDLgrCircle::BuildCircle
  self.XCOORDS = self.CENTER[0] + self.RADIUS * COS(INDGEN(361) * !DtoR)
  self.YCOORDS = self.CENTER[1] + self.RADIUS * SIN(INDGEN(361) * !DtoR)
END

;Բ�������ʼ��
FUNCTION IDLgrCircle::INIT, Center, Radius
  initSucess =1b
  ;Բ�����趨��Ϊ��ά
  IF (N_ELEMENTS(Center) NE 0) THEN BEGIN
    IF (N_ELEMENTS(Center) EQ 2) THEN  self.CENTER = center ELSE initSucess =0b
  ENDIF ELSE initSucess =0b
  ;Բ�뾶���趨
  IF (N_ELEMENTS(Radius) NE 0) THEN BEGIN
    IF (N_ELEMENTS(Radius) EQ 1) THEN  self.RADIUS = Radius ELSE initSucess =0b
  ENDIF ELSE initSucess =0b
  ;����buildCircle��������
  self->BUILDCIRCLE
  ;���س�ʼ���ɹ���־
  RETURN,initSucess
END
;Բ�����ඨ��
PRO IDLGRCIRCLE__DEFINE
  struct = { IDLgrCircle, $
    center:FLTARR(2), $
    oCircle: OBJ_NEW(), $
    xcoords:FINDGEN(361), $
    ycoords:FINDGEN(361), $
    Radius:0.}
END

oCircle = OBJ_NEW('IDLgrCircle',[0,0])
PRINT,OBJ_VALID(oCircle)
oCircle = OBJ_NEW('IDLgrCircle',[0,0],1.5)
oCircle->GETPROPERTY,Radius = r
PRINT,r
oCircle.SHOW
END

