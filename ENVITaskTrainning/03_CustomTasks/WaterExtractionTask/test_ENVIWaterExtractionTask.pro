PRO test_ENVIWaterExtractionTask, $
  INPUT_RASTER=input_raster,      $
  Apply_QUAC=Apply_QUAC,          $
  thresholdValue=thresholdValue,  $
  smoothSize=smoothSize,          $
  minArea=minArea,                $
  OUTPUT_RASTER_URI=output_raster_uri, $
  OUTPUT_VECTOR_URI=output_vector_uri

  COMPILE_OPT idl2
  e=ENVI(/current)

  ;几个可选参数
  IF ~KEYWORD_SET(thresholdValue)    THEN thresholdValue     = 0.0
  IF ~KEYWORD_SET(smoothSize)        THEN smoothSize         = 5
  IF ~KEYWORD_SET(minArea)           THEN minArea            = 0.05

  ;多写一行,第一时间判断是否包含计算MNDWI的波段，不需要先QUAC
  mndwiRaster = ENVISpectralIndexRaster(input_raster, 'mndwi')
  ;
  IF Apply_QUAC THEN BEGIN
    QUACTask = ENVITask('QUAC')
    QUACTask.INPUT_RASTER = input_raster
    QUACTask.Execute
    ;计算mndwi
    mndwiRaster = ENVISpectralIndexRaster(QUACTask.OUTPUT_RASTER, 'mndwi')
  ENDIF

  ;密度分割，提取
  ColorSliceTask = ENVITASK('ColorSliceClassification')
  ColorSliceTask.INPUT_RASTER = mndwiRaster
  ColorSliceTask.DATA_MINIMUM = thresholdValue
  ColorSliceTask.NUMBER_OF_RANGES = 1
  ColorSliceTask.Execute

  ;;初始化平滑Task
  SmoothTask=ENVITASK('ClassificationSmoothing')
  SmoothTask.INPUT_RASTER = ColorSliceTask.OUTPUT_RASTER
  SmoothTask.KERNEL_SIZE = smoothSize
  SmoothTask.EXECUTE

  ;初始化聚类Task
  AggregationTask=ENVITASK('ClassificationAggregation')
  ref = input_raster.SPATIALREF
  aggregateSize = ref EQ !NULL ? 50 : minArea*1000000/PRODUCT(ref.PIXEL_SIZE)
  AggregationTask.INPUT_RASTER = SmoothTask.OUTPUT_RASTER
  AggregationTask.MINIMUM_SIZE = aggregateSize > 9
  AggregationTask.OUTPUT_RASTER_URI = output_raster_uri
  AggregationTask.EXECUTE

  ;更新元数据信息
  waterRaster = e.OpenRaster(output_raster_uri)
  waterRaster.METADATA.UpdateItem, $
    'class names', ['Background', 'Water']
  waterRaster.METADATA.UpdateItem, $
    'class lookup', [[0,0,0],[255,0,0]]
  waterRaster.METADATA.AddItem, $
    'data ignore value', 0, error=err
  waterRaster.WriteMetadata

  ;如果是预览
  IF STRMATCH(output_raster_uri,'*envitempfile*') THEN BEGIN
    ;移除Data Manager
    dataCol = e.DATA
    dataCol.Remove, waterRaster, error=err
  ENDIF ELSE BEGIN
    ;如果不是预览，才转矢量
    ;初始化Task，栅格转矢量
    ClassToVectorTask = ENVITASK('ClassificationToShapefile')
    ;设置输入参数
    ClassToVectorTask.INPUT_RASTER = e.OpenRaster(output_raster_uri)
    ClassToVectorTask.EXPORT_CLASSES = 'Water'
    ClassToVectorTask.OUTPUT_VECTOR_URI = output_vector_uri
    ClassToVectorTask.EXECUTE
  ENDELSE
END