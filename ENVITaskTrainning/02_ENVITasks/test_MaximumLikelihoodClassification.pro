PRO test_MaximumLikelihoodClassification
  e = ENVI()

  ;�򿪶�������ݣ�����ͼ�����
  File1 = Filepath('qb_boulder_msi', Subdir=['data'], $
    Root_Dir=e.ROOT_DIR)
  Raster = e.OpenRaster(File1)

  ;���������ݣ�shp��ʽ
  File2 = Filepath('qb_boulder_msi_vectors.shp', Subdir=['data'], $
    Root_Dir=e.ROOT_DIR)
  Vector = e.OpenVector(File2)

  ;ͳ��������Ϣ
  StatTask = ENVITask('TrainingClassificationStatistics')
  StatTask.INPUT_RASTER = Raster
  StatTask.INPUT_VECTOR = Vector
  StatTask.Execute

  ;�����Ȼ�ල����
  Task = ENVITask('MaximumLikelihoodClassification')
  Task.INPUT_RASTER = Raster
  Task.COVARIANCE = StatTask.COVARIANCE
  Task.MEAN = StatTask.MEAN
  Task.OUTPUT_RASTER_URI = e.GetTemporaryFilename()
  Task.Execute

  ;�������ӵ�Data Manager
  DataColl = e.DATA
  DataColl.Add, Task.OUTPUT_RASTER

  ;��ʾ���
  View1 = e.GetView()
  Layer1 = View1.CreateLayer(Task.OUTPUT_RASTER)
END