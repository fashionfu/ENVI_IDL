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
;iImageContour��������ļ�
; Copy from ITTVIS
;-
PRO IIMAGECONTOUR, parm1, IDENTIFIER = identifier,$
    _EXTRA = _extra
  IF (N_PARAMS() GT 0) THEN BEGIN
    ;
    ;����IDLitParameterSet�������ݶ���
    ;
    oParmSet = OBJ_NEW('IDLitParameterSet', $
      NAME = '����', $
      ICON = 'image', $
      DESCRIPTION = 'tool parameters')
    ;�����ʱ������������������ݴ洢
    IF (N_ELEMENTS(parm1) GT 0) THEN BEGIN
      ;������ļ�������iopen��ȡ����
      IF (SIZE(parm1, /TNAME) EQ 'STRING') THEN BEGIN
        filenameTmp = parm1
        IOPEN, parm1, data, rgbTableIn, _EXTRA=_extra
      ENDIF
      oData = OBJ_NEW('IDLitDataIDLImagePixels')
      result = oData->SETDATA(data, _EXTRA = _extra)
      oParmSet->ADD, oData, PARAMETER_NAME = 'ImagePixels'
      ;Ĭ����ʾ�Ҷ���ɫ��.
      ramp = BINDGEN(256)
      oPalette = OBJ_NEW('IDLitDataIDLPalette', $
        TRANSPOSE([[ramp], [ramp], [ramp]]), $
        NAME = 'Palette')
      oParmSet->ADD, oPalette, PARAMETER_NAME = 'PALETTE'
    ENDIF
  ENDIF
  ;ע����ӻ�����
  IREGISTER, 'Image Contour tool', 'iImageContour'
  identifier = IDLITSYS_CREATETOOL('Image Contour tool',$
    VISUALIZATION_TYPE = ['Image&Contour'], $
    INITIAL_DATA = oParmSet, _EXTRA = _extra, $
    TITLE = 'Image Contour tool')
    
END