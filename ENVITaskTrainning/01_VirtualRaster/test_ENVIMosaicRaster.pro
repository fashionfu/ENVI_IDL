PRO test_ENVIMosaicRaster
  ;
  COMPILE_OPT idl2
  e=ENVI()

  ;��Ƕ�����ļ�
  path = FILE_DIRNAME(ROUTINE_FILEPATH())+'\data\'
  files = path+['mosaic_1.hdr','mosaic_2.hdr']

  ;������դ��
  Scenes = !NULL
  FOR i=0,N_ELEMENTS(files)-1 DO BEGIN
    Raster = e.OpenRaster(files[i], $
      data_ignore_value=0, error = err)
    IF err NE '' THEN CONTINUE
    Scenes = [Scenes, Raster]
  ENDFOR

  ;��ʼ��ENVIMosaicRaster
  Mosaic1 = ENVIMosaicRaster(Scenes)

  ;��һ����Ƕ��������ɫ����ʾ���
  View = e.GetView()
  Layer1 = View.CreateLayer(Mosaic1)
  View.zoom, 1, /full_extent

  ;������ͼ
  View2 = e.CreateView()

  ;������ɫ
  Mosaic2 = ENVIMosaicRaster(Scenes)
  Mosaic2.COLOR_MATCHING_METHOD = 'histogram matching'
  ;��ʾ��ɫ���
  Layer2 = View2.CreateLayer(Mosaic2)

  View2.GeoLink, /link_all, /zoom_link
  View2.zoom, 1, /full_extent
  
  ;�ϵ㣬ͣ������󣬿��Ե㹤�������ָ�����ť��F8������ִ�к�������
  STOP
  Layer1.Close
  Layer2.Close
  Mosaic1.Close
  Mosaic2.Close

  FOREACH element, Scenes DO element.CLOSE

  e.LAYOUT = [1,1]

  ;������Ƕ����
  ;  Mosaic.COLOR_MATCHING_METHOD = 'histogram matching'
  ;  Mosaic.COLOR_MATCHING_STATS  = 'overlapping area'
  ;  Mosaic.FEATHERING_METHOD     = 'seamline'
  ;  Mosaic.FEATHERING_DISTANCE   = 10
  ;  Mosaic.SEAMLINE_METHOD       = 'geometry'
  ;  Mosaic.RESAMPLING            = 'Bilinear'
END