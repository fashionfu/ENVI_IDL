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
;iImageContour���ߵ��ඨ���ļ�
;Modified By DYQ
;-
FUNCTION IIMAGECONTOUR::INIT, _REF_EXTRA = _extra

  ;��ʼ���̳���
  IF ( self->IDLITTOOLBASE::INIT(_EXTRA = _extra) EQ 0) THEN $
    RETURN, 0
  ;*** ���ӻ�
  ; ע����ӻ�����
  self->REGISTERVISUALIZATION, 'Image&Contour', 'VisImageContour', $
    ICON = 'image', /DEFAULT
    
  ;*** �����˵�
  ; ���ӻ�ʱ���ò˵�������Canny��ť��������ImageContourCanny�ඨ��
  self->REGISTEROPERATION, 'Canny�߽���', 'ImageContourCanny', $
    IDENTIFIER = 'Operations/Canny'
    
  ;***��������ť
  ; �ɲο����С�idldir/examples/doc/itools/example3tool.pro��
    
  ;***�ļ���ȡ
  ; ����ض���ʽ�ļ���ȡ
  self->REGISTERFILEREADER, '��ȡTIFF��ʽ', 'ImageContourReadTIFF', $
    ICON='demo', /DEFAULT
  ;***�ļ�д��
  ; �Ƚ�iTools�Դ����ļ�д����������
  self->UNREGISTERFILEWRITER, 'Tag Image File Format'
  ;ע���д��tif�ļ��������
  self->REGISTERFILEWRITER, 'д��TIFF��ʽ', 'ImageContourWriteTIFF', $
    ICON='demo', /DEFAULT
    
  ;���ʼ���ɹ�
  RETURN, 1
  
END

; �ඨ��
PRO IIMAGECONTOUR__DEFINE

  struct = { iImageContour,              $
    INHERITS IDLitToolbase     $ ; Provides iTool interface
    }
    
END

