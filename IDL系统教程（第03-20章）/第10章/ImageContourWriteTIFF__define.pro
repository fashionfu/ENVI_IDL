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
;+
;Copy from ITTVIS
;iImageContour���ߵ����ļ���������ඨ��
;Modified By DYQ
;-
FUNCTION ImageContourWriteTIFF::Init, _REF_EXTRA = _extra

   IF (self->IDLitWriter::Init('tiff', $
      TYPES=['IDLIMAGE', 'IDLIMAGEPIXELS', 'IDLARRAY2D'], $
      NAME='Tag Image File Format', $
      DESCRIPTION='Tag Image File Format (TIFF)', $
      _EXTRA = _extra) EQ 0) THEN $
      RETURN, 0

   RETURN, 1

END

;������д��Ϊtiff�ļ�
FUNCTION ImageContourWriteTIFF::SetData, oImageData

   ;��ȡ����ļ���
   strFilename = self->GetFilename()
   IF (strFilename EQ '') THEN RETURN, 0

   ;��������������Ч
   IF (~ OBJ_VALID(oImageData)) THEN BEGIN
      MESSAGE, 'Invalid image data object.', /CONTINUE
      RETURN, 0 
   ENDIF

   ;��ȡһάʸ��������
   oData = (oImageData->GetByType('IDLIMAGEPIXELS'))[0]

   ;��ȡ��ά��������
   IF (~ OBJ_VALID(oData)) THEN BEGIN
      oData = (oImageData->GetByType('IDLARRAY2D'))[0]
      IF (~ OBJ_VALID(oData)) THEN RETURN, 0
   ENDIF

   ; δ����κ����ݣ���ʧ��
   IF (~ oData->GetData(image)) THEN BEGIN
      MESSAGE, 'Error retrieving image data.', /CONTINUE
      RETURN, 0 
   ENDIF

   ; ��ȡ��ɫ��
   oPalette = (oImageData->GetByType('IDLPALETTE'))[0]

   ; ��ȡ��ɫ���������ɫ��
   IF (OBJ_VALID(oPalette)) THEN BEGIN
      success = oPalette->GetData(palette)
      IF (N_ELEMENTS(palette) GT 0) THEN BEGIN
         red = REFORM(palette[0,*])
         green = REFORM(palette[1,*])
         blue = REFORM(palette[2,*])
      ENDIF
   ENDIF

   ;���ݵ�ά��
   ndim = SIZE(image, /N_DIMENSIONS)

   ;���Ϊtiff�ļ�����ɫ��reverse��֤��ʽ��ͨ����
   WRITE_TIFF, strFilename, REVERSE(image, ndim), $
      RED = red, GREEN = green, BLUE = blue
   RETURN, 1  ; success
END
; �ඨ��
PRO ImageContourWriteTIFF__Define
   struct = {ImageContourWriteTIFF,       $
             inherits IDLitWriter  $
           }
END

