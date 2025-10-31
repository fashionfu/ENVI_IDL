;+
; :Description:
;    ����ǰ��ͼ����ʾ��ͼ����������ΪTIFF�ļ�����������Ч��
;
; :Author: duhj@esrichina.com.cn
;
; :Date: 2018-3-15 16:37:11
;-
PRO test_ExportRasterLayers_Batch
  COMPILE_OPT idl2
  e=envi()
  view=e.getview()
  layers=view.getlayer(/all)
  IF layers EQ !NULL THEN return
  ;
  outdir = FILE_DIRNAME(ROUTINE_FILEPATH())+PATH_SEP()+'output'
  n_layers = N_ELEMENTS(layers)
  FOR i=0, n_layers-1 DO BEGIN
    outfile=outdir+layers[i].NAME+'.tif'
    layers[i].EXPORT, outfile, 'tiff'
  ENDFOR
END