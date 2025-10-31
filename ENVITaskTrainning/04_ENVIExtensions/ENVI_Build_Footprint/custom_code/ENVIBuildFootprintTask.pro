PRO ENVIBuildFootprintTask, input_raster=Raster, $
  background_Value=backValue, $
  output_vector_uri=outShpFile
  COMPILE_OPT idl2
  e=envi(/current)
  view=e.GetView()

  ;���βü���������Ĥ�ļ�
  band1 = ENVISubsetRaster(Raster, BANDS=[Raster.NBANDS-1])
  maskRaster = ENVIDataValuesMaskRaster(band1, [backValue,backValue], /inverse)
  maskRaster.METADATA.removeItem,'data ignore value', error=err

  ;���ɷ�����������ʾ
  Task = ENVITASK('ColorSliceClassification')
  Task.INPUT_RASTER = maskRaster
  Task.NUMBER_OF_RANGES = 1
  Task.OUTPUT_RASTER_URI = e.GetTemporaryFilename()
  Task.Execute
  Task.OUTPUT_RASTER.METADATA.UpdateItem,'CLASS NAMES', ['ROI','Background']

  ;����shp�ļ�
  ClassToVectorTask = ENVITASK('ClassificationToShapefile')
  ClassToVectorTask.INPUT_RASTER = Task.OUTPUT_RASTER
  ClassToVectorTask.EXPORT_CLASSES = 'ROI'
  ClassToVectorTask.OUTPUT_VECTOR_URI = outShpFile
  ClassToVectorTask.Execute

  output_vector = e.OpenVector(outShpFile)

  ;ɾ����ʱ���
  Task.OUTPUT_RASTER.Close
  tmpFiles = FILE_SEARCH(FILE_DIRNAME(e.GetTemporaryFilename()),'*envi*',COUNT=count)
  IF count NE 0 THEN FILE_DELETE, tmpFiles, /QUIET
END