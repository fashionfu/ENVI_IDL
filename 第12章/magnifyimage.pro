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
;  $Id: //depot/idl/releases/IDL_80/idldir/examples/doc/image/magnifyimage.pro#1 $
;  Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved.
;
PRO MAGNIFYIMAGE

  ;��������
  file = FILEPATH('convec.dat', $
    SUBDIRECTORY = ['examples', 'data'])
  image = READ_BINARY(file, DATA_DIMS = [248, 248])
  
  ;����һ��ɫ��.
  LOADCT, 28
  DEVICE, DECOMPOSED = 0, RETAIN = 2
  WINDOW, 0, XSIZE = 248, YSIZE = 248
  
  ;��ʾͼ��.
  TV, image
  
  ;��һ�´����зŴ���ʾ.
  magnifiedImg = CONGRID(image, 600, 600, /INTERP)
  WINDOW, 1, XSIZE = 600, YSIZE = 600
  TV, magnifiedImg
  
END