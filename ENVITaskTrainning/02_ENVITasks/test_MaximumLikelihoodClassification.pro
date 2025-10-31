PRO test_MaximumLikelihoodClassification
  e = ENVI()

  ;打开多光谱数据，用于图像分类
  File1 = Filepath('qb_boulder_msi', Subdir=['data'], $
    Root_Dir=e.ROOT_DIR)
  Raster = e.OpenRaster(File1)

  ;打开样本数据，shp格式
  File2 = Filepath('qb_boulder_msi_vectors.shp', Subdir=['data'], $
    Root_Dir=e.ROOT_DIR)
  Vector = e.OpenVector(File2)

  ;统计样本信息
  StatTask = ENVITask('TrainingClassificationStatistics')
  StatTask.INPUT_RASTER = Raster
  StatTask.INPUT_VECTOR = Vector
  StatTask.Execute

  ;最大似然监督分类
  Task = ENVITask('MaximumLikelihoodClassification')
  Task.INPUT_RASTER = Raster
  Task.COVARIANCE = StatTask.COVARIANCE
  Task.MEAN = StatTask.MEAN
  Task.OUTPUT_RASTER_URI = e.GetTemporaryFilename()
  Task.Execute

  ;将结果添加到Data Manager
  DataColl = e.DATA
  DataColl.Add, Task.OUTPUT_RASTER

  ;显示结果
  View1 = e.GetView()
  Layer1 = View1.CreateLayer(Task.OUTPUT_RASTER)
END