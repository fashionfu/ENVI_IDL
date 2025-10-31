PRO test_ISODATAClassification
  COMPILE_OPT idl2
  
  ;启动ENVI
  e = ENVI()

  ;打开栅格
  file = FILEPATH('qb_boulder_msi', subdirectory=['data'], root_dir=e.ROOT_DIR)
  raster = e.OpenRaster(file)

  ;初始化ENVITask。可以调用 task.parameterNames() 获取所有参数
  task = ENVITask('ISODATAClassification')

  ;设置ENVITask参数
  task.INPUT_RASTER = raster
  task.NUMBER_OF_CLASSES = 5
  task.ITERATIONS = 1 ;迭代次数为1，节省演示时间
  ;设置输出路径。若不设置，则输出到临时目录，在关闭ENVI时将自动清除
  ;task.OUTPUT_RASTER_URI = 'C:\temp\isodata.dat'

  ;执行ENVITask
  task.Execute

  ;获取处理结果
  output_raster = task.OUTPUT_RASTER

  ;添加结果到Data Manager并加载显示
  e.DATA.Add, output_raster
  view = e.GetView()
  layer = view.CreateLayer(output_raster)
END

