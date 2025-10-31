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
;iImageContour�����µ�tif�ļ���ȡ��ImageContourReadTIFF__define.pro
;Modified By DYQ
;-
FUNCTION ImageContourReadTIFF::INIT, _REF_EXTRA = _extra

  ;��ʼ���̳���
  IF (self->IDLITREADER::INIT(["tiff", "tif"],$
    NAME="Tiff �ļ�", $
    DESCRIPTION="TIFF File format", $
    _EXTRA = _extra) NE 1) THEN $
    RETURN, 0
  ; Initialize the instance data field
  self._INDEX = 0
  ;ע����������
  self->REGISTERPROPERTY, 'IMAGE_INDEX', /INTEGER, $
    Description='Index of the image to read from the TIFF file.'
  ; Return success.
  RETURN,1
END
;�������tiff�ļ�
FUNCTION ImageContourReadTIFF::ISA, strFilename
  RETURN, QUERY_TIFF(strFilename);
END
;��ȡtiff�ļ�����
FUNCTION ImageContourReadTIFF::GetData, oImageData
  ; �ļ���
  filename = self->GETFILENAME()
  
  ; �����������򷵻�
  IF (QUERY_TIFF(filename, fInfo, IMAGE_INDEX = self._INDEX) EQ 0) $
    THEN RETURN, 0
  ;����ɫ�����ȡ
  IF (fInfo.HAS_PALETTE) THEN BEGIN
    image = READ_TIFF(filename, palRed, palGreen, palBlue, $
      IMAGE_INDEX = self._INDEX)
  ENDIF ELSE BEGIN
    image = READ_TIFF(filename, IMAGE_INDEX = self._INDEX)
  ENDELSE
  
  ;�������ݵ�IDLitDataIDLImage������
  oImageData = OBJ_NEW('IDLitDataIDLImage', $
    NAME = FILE_BASENAME(fileName))
  result = oImageData->SETDATA(image, 'ImagePixels', /NO_COPY)
  IF (result EQ 0) THEN RETURN, 0
  ;������ɫ������
  IF (fInfo.HAS_PALETTE) THEN $
    result = oImageData->SETDATA( TRANSPOSE([[palRed], $
    [palGreen], [palBlue]]), 'Palette')
  ;������εĶ�ȡ
  IF fInfo.NUM_IMAGES GT 1 THEN $
    self->IDLITIMESSAGING::STATUSMESSAGE, $
    'Read channel ' + STRTRIM(self._INDEX,2)
  RETURN, result
END

; ���Ի�ȡ����
PRO ImageContourReadTIFF::GetProperty, IMAGE_INDEX = image_index, $
    _REF_EXTRA = _extra
    
  IF (ARG_PRESENT(image_index)) THEN image_index = self._INDEX
  
  IF (N_ELEMENTS(_extra) GT 0) THEN $
    self->IDLITREADER::GETPROPERTY, _EXTRA = _extra
END
;�������÷���
PRO ImageContourReadTIFF::SetProperty, IMAGE_INDEX = image_index, $
    _REF_EXTRA = _extra
    
  IF (N_ELEMENTS(image_index) GT 0) THEN $
    self._INDEX = image_index
    
  IF (N_ELEMENTS(_extra) GT 0) THEN $
    self->IDLITREADER::SETPROPERTY, _EXTRA = _extra
END
; �ඨ�壬�̳���IDLitReader
PRO IMAGECONTOURREADTIFF__DEFINE
  struct = {ImageContourReadTIFF, $
    inherits IDLitReader, $
    _index : 0            $
    }
END

