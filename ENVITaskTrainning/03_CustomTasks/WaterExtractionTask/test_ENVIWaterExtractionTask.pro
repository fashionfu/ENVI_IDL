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

  ;������ѡ����
  IF ~KEYWORD_SET(thresholdValue)    THEN thresholdValue     = 0.0
  IF ~KEYWORD_SET(smoothSize)        THEN smoothSize         = 5
  IF ~KEYWORD_SET(minArea)           THEN minArea            = 0.05

  ;��дһ��,��һʱ���ж��Ƿ��������MNDWI�Ĳ��Σ�����Ҫ��QUAC
  mndwiRaster = ENVISpectralIndexRaster(input_raster, 'mndwi')
  ;
  IF Apply_QUAC THEN BEGIN
    QUACTask = ENVITask('QUAC')
    QUACTask.INPUT_RASTER = input_raster
    QUACTask.Execute
    ;����mndwi
    mndwiRaster = ENVISpectralIndexRaster(QUACTask.OUTPUT_RASTER, 'mndwi')
  ENDIF

  ;�ܶȷָ��ȡ
  ColorSliceTask = ENVITASK('ColorSliceClassification')
  ColorSliceTask.INPUT_RASTER = mndwiRaster
  ColorSliceTask.DATA_MINIMUM = thresholdValue
  ColorSliceTask.NUMBER_OF_RANGES = 1
  ColorSliceTask.Execute

  ;;��ʼ��ƽ��Task
  SmoothTask=ENVITASK('ClassificationSmoothing')
  SmoothTask.INPUT_RASTER = ColorSliceTask.OUTPUT_RASTER
  SmoothTask.KERNEL_SIZE = smoothSize
  SmoothTask.EXECUTE

  ;��ʼ������Task
  AggregationTask=ENVITASK('ClassificationAggregation')
  ref = input_raster.SPATIALREF
  aggregateSize = ref EQ !NULL ? 50 : minArea*1000000/PRODUCT(ref.PIXEL_SIZE)
  AggregationTask.INPUT_RASTER = SmoothTask.OUTPUT_RASTER
  AggregationTask.MINIMUM_SIZE = aggregateSize > 9
  AggregationTask.OUTPUT_RASTER_URI = output_raster_uri
  AggregationTask.EXECUTE

  ;����Ԫ������Ϣ
  waterRaster = e.OpenRaster(output_raster_uri)
  waterRaster.METADATA.UpdateItem, $
    'class names', ['Background', 'Water']
  waterRaster.METADATA.UpdateItem, $
    'class lookup', [[0,0,0],[255,0,0]]
  waterRaster.METADATA.AddItem, $
    'data ignore value', 0, error=err
  waterRaster.WriteMetadata

  ;�����Ԥ��
  IF STRMATCH(output_raster_uri,'*envitempfile*') THEN BEGIN
    ;�Ƴ�Data Manager
    dataCol = e.DATA
    dataCol.Remove, waterRaster, error=err
  ENDIF ELSE BEGIN
    ;�������Ԥ������תʸ��
    ;��ʼ��Task��դ��תʸ��
    ClassToVectorTask = ENVITASK('ClassificationToShapefile')
    ;�����������
    ClassToVectorTask.INPUT_RASTER = e.OpenRaster(output_raster_uri)
    ClassToVectorTask.EXPORT_CLASSES = 'Water'
    ClassToVectorTask.OUTPUT_VECTOR_URI = output_vector_uri
    ClassToVectorTask.EXECUTE
  ENDELSE
END