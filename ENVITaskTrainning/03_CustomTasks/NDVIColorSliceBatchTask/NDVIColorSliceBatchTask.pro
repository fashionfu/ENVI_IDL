PRO NDVIColorSliceBatchTask, $
  input_rasters=input_rasters, $
  color_table_name=color_table_name, $
  number_of_ranges=number_of_ranges, $
  display_results=display_results, $
  output_extension=output_extension, $
  output_dir=output_dir
  COMPILE_OPT idl2
  e=envi()

  DataColl = e.DATA  ;Data Manager
  View = e.GetView()

  errMsgs = !NULL    ;��¼������Ϣ
  n_files = N_ELEMENTS(input_rasters)
  FOR i=0, n_files-1 DO BEGIN
    file = input_rasters[i].URI
    ;������
    Catch, errorStatus
    IF (errorStatus NE 0) THEN BEGIN
      Catch, /CANCEL
      errMsgs = [errMsgs, file +' --- '+ !ERROR_STATE.MSG]
      MESSAGE, /RESET
      CONTINUE
    ENDIF
    ;
    raster = input_rasters[i]
    ndvi = ENVISpectralIndexRaster(raster, 'ndvi')
    ndvi = ENVIPixelwiseBandMathRaster(ndvi,'b1>(-1)<1')

    ;���������ļ������Զ��趨����ļ���
    basename = FILE_BASENAME(file,STRMID(file,STRPOS(file,'.',/reverse_search)))
    outfile = FILEPATH(basename+output_extension, root_dir=output_dir)
    File_Delete_Enhanced, outfile ;ɾ���Ѵ����ļ�
    ;�ܶȷָ�
    Task = ENVITask('ColorSliceClassification')
    Task.INPUT_RASTER = ndvi
    Task.COLOR_TABLE_NAME = color_table_name
    Task.DATA_MINIMUM = 0.0
    Task.DATA_MAXIMUM = 1.0
    Task.NUMBER_OF_RANGES = number_of_ranges
    Task.OUTPUT_RASTER_URI = outfile
    Task.Execute

    ;�������ӵ�Data Manager�У�����ʾ
    DataColl.Add, Task.OUTPUT_RASTER
    IF display_results THEN $
      Layer = View.CreateLayer(Task.OUTPUT_RASTER)
  ENDFOR

  ;��ʾ�����ļ�����Ӧ�ı�����Ϣ
  IF errMsgs NE !NULL THEN BEGIN
    logFile = e.GetTemporaryFilename('log')
    XDISPLAYFILE, logFile, group=e.WIDGET_ID, title='������Ϣ', $
      text=['Input File --- Error Message', errMsgs], /grow_to_screen, $
      done_button='Exit', height=20, width=120, /modal
  ENDIF
END