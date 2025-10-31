PRO test_ENVIMosaicRaster
  ;
  COMPILE_OPT idl2
  e=ENVI()

  ;镶嵌输入文件
  path = FILE_DIRNAME(ROUTINE_FILEPATH())+'\data\'
  files = path+['mosaic_1.hdr','mosaic_2.hdr']

  ;打开输入栅格
  Scenes = !NULL
  FOR i=0,N_ELEMENTS(files)-1 DO BEGIN
    Raster = e.OpenRaster(files[i], $
      data_ignore_value=0, error = err)
    IF err NE '' THEN CONTINUE
    Scenes = [Scenes, Raster]
  ENDFOR

  ;初始化ENVIMosaicRaster
  Mosaic1 = ENVIMosaicRaster(Scenes)

  ;第一次镶嵌不进行匀色，显示结果
  View = e.GetView()
  Layer1 = View.CreateLayer(Mosaic1)
  View.zoom, 1, /full_extent

  ;创建视图
  View2 = e.CreateView()

  ;设置匀色
  Mosaic2 = ENVIMosaicRaster(Scenes)
  Mosaic2.COLOR_MATCHING_METHOD = 'histogram matching'
  ;显示匀色结果
  Layer2 = View2.CreateLayer(Mosaic2)

  View2.GeoLink, /link_all, /zoom_link
  View2.zoom, 1, /full_extent
  
  ;断点，停到这里后，可以点工具栏“恢复”按钮（F8）继续执行后续代码
  STOP
  Layer1.Close
  Layer2.Close
  Mosaic1.Close
  Mosaic2.Close

  FOREACH element, Scenes DO element.CLOSE

  e.LAYOUT = [1,1]

  ;设置镶嵌参数
  ;  Mosaic.COLOR_MATCHING_METHOD = 'histogram matching'
  ;  Mosaic.COLOR_MATCHING_STATS  = 'overlapping area'
  ;  Mosaic.FEATHERING_METHOD     = 'seamline'
  ;  Mosaic.FEATHERING_DISTANCE   = 10
  ;  Mosaic.SEAMLINE_METHOD       = 'geometry'
  ;  Mosaic.RESAMPLING            = 'Bilinear'
END