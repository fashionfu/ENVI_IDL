PRO test_ImageToImageRegistration
  COMPILE_OPT idl2
  e = ENVI()

  ;��ȡ�ļ�·��
  data_dir = FILEPATH('data', root_dir=ROUTINE_DIR())
  File1 = FILEPATH('quickbird_2.4m.dat', root_dir=data_dir)
  File2 = FILEPATH('ikonos_4.0m.dat', root_dir=data_dir)

  ;��դ��
  Raster1 = e.OpenRaster(File1)
  Raster2 = e.OpenRaster(File2)

  ;�Զ�Ѱ��ͬ����
  Task = ENVITask('GenerateTiePointsByCrossCorrelation')
  Task.INPUT_RASTER1 = Raster1
  Task.INPUT_RASTER2 = Raster2
  Task.Execute
  ;��ȡͬ����
  TiePoints = Task.OUTPUT_TIEPOINTS

  ;����ͬ����
  FilterTask = ENVITask('FilterTiePointsByGlobalTransform')
  FilterTask.INPUT_TIEPOINTS = TiePoints
  FilterTask.Execute
  ;��ȡ���˺����ӵ�
  TiePoints2 = FilterTask.OUTPUT_TIEPOINTS

  ;ִ��ͼ����׼
  RegistrationTask = ENVITask('ImageToImageRegistration')
  RegistrationTask.INPUT_TIEPOINTS = TiePoints2
  RegistrationTask.WARPING = 'Triangulation'
  RegistrationTask.Execute
  ;��ȡ��׼���
  WarpedRaster = RegistrationTask.OUTPUT_RASTER

  ;�����ENVI�д�
  DataColl = e.Data
  DataColl.Add, WarpedRaster
  View = e.GetView()
  Layer1 = View.CreateLayer(Raster1)
  Layer2 = View.CreateLayer(Raster2)
  Layer3 = View.CreateLayer(WarpedRaster)
END