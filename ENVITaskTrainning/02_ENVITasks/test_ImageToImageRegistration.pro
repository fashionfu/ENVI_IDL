PRO test_ImageToImageRegistration
  COMPILE_OPT idl2
  e = ENVI()

  ;获取文件路径
  data_dir = FILEPATH('data', root_dir=ROUTINE_DIR())
  File1 = FILEPATH('quickbird_2.4m.dat', root_dir=data_dir)
  File2 = FILEPATH('ikonos_4.0m.dat', root_dir=data_dir)

  ;打开栅格
  Raster1 = e.OpenRaster(File1)
  Raster2 = e.OpenRaster(File2)

  ;自动寻找同名点
  Task = ENVITask('GenerateTiePointsByCrossCorrelation')
  Task.INPUT_RASTER1 = Raster1
  Task.INPUT_RASTER2 = Raster2
  Task.Execute
  ;获取同名点
  TiePoints = Task.OUTPUT_TIEPOINTS

  ;过滤同名点
  FilterTask = ENVITask('FilterTiePointsByGlobalTransform')
  FilterTask.INPUT_TIEPOINTS = TiePoints
  FilterTask.Execute
  ;获取过滤后连接点
  TiePoints2 = FilterTask.OUTPUT_TIEPOINTS

  ;执行图像配准
  RegistrationTask = ENVITask('ImageToImageRegistration')
  RegistrationTask.INPUT_TIEPOINTS = TiePoints2
  RegistrationTask.WARPING = 'Triangulation'
  RegistrationTask.Execute
  ;获取配准结果
  WarpedRaster = RegistrationTask.OUTPUT_RASTER

  ;结果在ENVI中打开
  DataColl = e.Data
  DataColl.Add, WarpedRaster
  View = e.GetView()
  Layer1 = View.CreateLayer(Raster1)
  Layer2 = View.CreateLayer(Raster2)
  Layer3 = View.CreateLayer(WarpedRaster)
END