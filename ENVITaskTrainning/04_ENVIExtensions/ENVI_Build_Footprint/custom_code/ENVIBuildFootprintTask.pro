PRO ENVIBuildFootprintTask, input_raster=Raster, $
  background_Value=backValue, $
  output_vector_uri=outShpFile
  COMPILE_OPT idl2
  e=envi(/current)
  view=e.GetView()

  ;波段裁剪，制作掩膜文件
  band1 = ENVISubsetRaster(Raster, BANDS=[Raster.NBANDS-1])
  maskRaster = ENVIDataValuesMaskRaster(band1, [backValue,backValue], /inverse)
  maskRaster.METADATA.removeItem,'data ignore value', error=err

  ;生成分类结果，并显示
  Task = ENVITASK('ColorSliceClassification')
  Task.INPUT_RASTER = maskRaster
  Task.NUMBER_OF_RANGES = 1
  Task.OUTPUT_RASTER_URI = e.GetTemporaryFilename()
  Task.Execute
  Task.OUTPUT_RASTER.METADATA.UpdateItem,'CLASS NAMES', ['ROI','Background']

  ;生成shp文件
  ClassToVectorTask = ENVITASK('ClassificationToShapefile')
  ClassToVectorTask.INPUT_RASTER = Task.OUTPUT_RASTER
  ClassToVectorTask.EXPORT_CLASSES = 'ROI'
  ClassToVectorTask.OUTPUT_VECTOR_URI = outShpFile
  ClassToVectorTask.Execute

  output_vector = e.OpenVector(outShpFile)

  ;删除临时结果
  Task.OUTPUT_RASTER.Close
  tmpFiles = FILE_SEARCH(FILE_DIRNAME(e.GetTemporaryFilename()),'*envi*',COUNT=count)
  IF count NE 0 THEN FILE_DELETE, tmpFiles, /QUIET
END