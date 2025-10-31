PRO test_VFC
  COMPILE_OPT idl2
  e=envi()

  ;获取文件路径
  path = FILE_DIRNAME(ROUTINE_FILEPATH())
  file = FILEPATH('LC8_beijing_ref_90m.dat', $
    SUBDIRECTORY=['data'], ROOT_DIR=path)

  ;打开栅格文件
  raster = e.OpenRaster(file)

  ;quac
  quac = ENVIQUACRaster(raster)
  ;ndvi
  ndvi = ENVISpectralIndexRaster(quac,'ndvi')
  ;vfc (ndvi-min)/(max-min)
  expression = '(b1 lt 0.05)*0+(b1 gt 0.7)*1+(b1-0.05)/(0.7-0.05)'
  vfc = ENVIPixelwiseBandMathRaster(ndvi, expression)
  ;提取植被覆盖度大于50%的区域
  veg = ENVIBinaryGTThresholdRaster(vfc, 0.5)
  ;
  ;添加元数据信息，修改为分类图像
  veg.METADATA.AddItem, 'classes', 2
  veg.METADATA.AddItem, 'class names', ['Background', 'Vegetation']
  veg.METADATA.AddItem, 'class lookup', [[0,0,0],[90,180,80]]
  IF veg.METADATA.hasTag('data ignore value') THEN $
    veg.METADATA.UpdateItem, 'data ignore value', 0 $
  ELSE veg.METADATA.AddItem, 'data ignore value', 0

  ;将结果显示在视图中，并全图显示
  view = e.getview()
  layer1 = view.createlayer(raster)
  layer2 = view.createlayer(veg)
  view.zoom, 1, /full_extent
END