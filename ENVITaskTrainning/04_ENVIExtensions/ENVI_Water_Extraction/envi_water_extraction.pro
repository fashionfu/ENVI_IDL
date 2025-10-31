; Add the extension to the toolbox. Called automatically on ENVI startup.
PRO ENVI_Water_Extraction_extensions_init

  ; Set compile options
  COMPILE_OPT IDL2

  ; Get ENVI session
  e = ENVI(/CURRENT)

  ; Add the extension to a subfolder
  e.AddExtension, 'Water Extraction', 'ENVI_Water_Extraction', PATH=''
END


PRO ENVIWaterExtractionTask,              $
  input_raster=input_raster,              $
  apply_QUAC=apply_QUAC,                  $
  thresholdValue=thresholdValue,          $
  smoothSize=smoothSize, minArea=minArea, $
  output_raster_uri=output_raster_uri,    $
  output_vector_uri=output_vector_uri

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


; ENVI Extension code. Called when the toolbox item is chosen.
PRO ENVI_Water_Extraction

  ; Set compile options
  COMPILE_OPT IDL2

  ; General error handler
  CATCH, err
  IF (err NE 0) THEN BEGIN
    CATCH, /CANCEL
    IF OBJ_VALID(e) THEN $
      e.ReportError, 'ERROR: ' + !ERROR_STATE.MSG
    MESSAGE, /RESET
    return
  ENDIF

  ;Get ENVI session
  e = ENVI(/CURRENT)

  ;******************************************
  ; Insert your ENVI Extension code here...
  ;******************************************

  ;  taskfile='D:\IDLWorkspace851\ENVI_Water_Extraction\ENVIWaterExtractionTask.task'
  task = envitask('WaterExtraction')
  ui=e.UI
  r=ui.SelectTaskParameters(task, DIALOG_PARENT=e.WIDGET_ID)

  ;如果进行了预览操作
  tmpFiles = FILE_SEARCH(FILE_DIRNAME(e.GetTemporaryFilename()),'*envitemp*',$
    COUNT=count)
  IF count NE 0 THEN FILE_DELETE, tmpFiles, /QUIET, /ALLOW_NONEXISTENT

  IF r NE 'OK' THEN return
  task.execute

  ;显示结果
  view = e.GetView()
  layer = view.Createlayer(task.OUTPUT_RASTER, error=err)
  dataCol = e.DATA
  dataCol.Add, task.OUTPUT_VECTOR, error=err
  layer = view.Createlayer(task.OUTPUT_VECTOR, error=err)

END
