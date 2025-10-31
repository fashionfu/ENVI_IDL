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
PRO VECTOR_READ_SHAPEFILE
  ;������ʾ����
  DEVICE, RETAIN=2, DECOMPOSED=0
  ;���ñ�����ɫ
  !P.BACKGROUND=255
  ;������ɫ��
  r=BYTARR(256) & g=BYTARR(256) & b=BYTARR(256)
  r[0]=0 & g[0]=0 & b[0]=0             ;�����ɫ
  r[1]=100 & g[1]=100 & b[1]=255       ;������ɫ
  r[2]=0 & g[2]=255 & b[2]=0           ;������ɫ
  r[3]=255 & g[3]=255 & b[3]=0         ;�����ɫ
  r[255]=255 & g[255]=255 & b[255]=255 ;�����ɫ
  ;������ɫ��
  TVLCT, r, g, b
  black=0 & blue=1 & green=2 & yellow=3 & white=255
  ;����shape��ʾ����ͶӰ
  MAP_SET, /ORTHO,45, -120,  /ISOTROPIC, $
    /HORIZON, E_HORIZON={FILL:1, COLOR:blue}, $
    /GRID, COLOR=black, /NOBORDER
  ;�����ʾ��½
  MAP_CONTINENTS, /FILL_CONTINENTS, COLOR=green
  ;������ʾ ������
  MAP_CONTINENTS, /COASTS, COLOR=black
  ;��ȡExample�µ�shape�ļ�
  myshape=OBJ_NEW('IDLffShape', FILEPATH('states.shp', $
    SUBDIR=['examples', 'data']))
  ;��ʸ�������л�ȡʵ�����
  myshape->IDLFFSHAPE::GETPROPERTY, N_ENTITIES=num_ent
  ;��ȡÿ��ʵ�����Ϣ
  FOR x=1, (num_ent-1) DO BEGIN
    ;��ȡʵ���������Ϣ
    attr = myshape->IDLFFSHAPE::GETATTRIBUTES(x)
    ;��ȡʸ����Colorado������
    IF attr.ATTRIBUTE_1 EQ 'Colorado' THEN BEGIN
      ;��ȡʵ���
      ent=myshape->IDLFFSHAPE::GETENTITY(x)
      ;�û�ɫ����ʵ����
      POLYFILL, (*ent.VERTICES)[0,*], (*ent.VERTICES)[1,*], $
        COLOR=yellow
      ;����ʵ���
      myshape->IDLFFSHAPE::DESTROYENTITY, ent
    ENDIF
  ENDFOR
  ;�ر�ʸ������
  OBJ_DESTROY, myshape
END