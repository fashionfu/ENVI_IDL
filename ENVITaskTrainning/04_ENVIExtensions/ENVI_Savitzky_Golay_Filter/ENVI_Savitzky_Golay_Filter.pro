; Add the extension to the toolbox. Called automatically on ENVI startup.
PRO ENVI_Savitzky_Golay_Filter_extensions_init

  ; Set compile options
  COMPILE_OPT IDL2

  ; Get ENVI session
  e = ENVI(/CURRENT)

  ; Add the extension to a subfolder
  e.AddExtension, 'Savitzky-Golay Filter', 'ENVI_Savitzky_Golay_Filter', PATH=''
END


; ENVI Extension code. Called when the toolbox item is chosen.
PRO ENVI_Savitzky_Golay_Filter

  ; Set compile options
  COMPILE_OPT IDL2

  ; General error handler
  CATCH, err
  IF (err NE 0) THEN BEGIN
    CATCH, /CANCEL
    IF OBJ_VALID(e) THEN $
      e.ReportError, 'ERROR: ' + !ERROR_STATE.msg + STRING(13B) + $
      'Please sent this error message to duhj@esrichina.com.cn'
    MESSAGE, /RESET
    RETURN
  ENDIF

  ;Get ENVI session
  e = ENVI(/CURRENT)

  ;******************************************
  ; Insert your ENVI Extension code here...
  ;******************************************

  Task = ENVITask('ENVISavitzkyGolayFilterTask')
  Result = e.UI.SelectTaskParameters(Task)
  ;
  IF Result NE 'OK' THEN return

  Task.Execute

  ;�����ʾ���
  IF Task.DISPLAY_RESULT EQ 1 THEN BEGIN
    view = e.GetView()
    layer = view.CreateLayer(Task.output_raster)
  ENDIF
END


PRO ENVISavitzkyGolayFilterTask, $
  input_raster=input_raster, $
  Nleft = Nleft, $
  Nright = Nright, $
  Order = Order, $  ;0 ƽ����1 һ�׵����� 2 ���׵���
  Degree = Degree, $ ;һ��2-4��ֵԽ�ͣ�ƽ��Ч��Խ�ã����ǿ��ܲ���ƫ�ֵԽ�ߣ�ƽ��Ч��Խ��������Խ�󣬵���ƫ��С
  DISPLAY_RESULT=DISPLAY_RESULT, $
  OUTPUT_RASTER_URI=output_raster_uri

  COMPILE_OPT idl2
  e=envi(/current)

  ; General error handler
  CATCH, err
  IF (err NE 0) THEN BEGIN
    CATCH, /CANCEL
    IF OBJ_VALID(e) THEN $
      e.ReportError, 'ERROR: ' + !ERROR_STATE.msg + STRING(13B) + $
      'Please sent this error message to duhj@esrichina.com.cn'
    MESSAGE, /RESET
    ;
    IF ISA(abort) THEN Finish = ENVIFINISHMESSAGE(Abort)
    IF ISA(Finish) THEN Channel.Broadcast, Finish
    IF ISA(Tile_id) THEN ENVI_TILE_DONE, Tile_id
    IF ISA(lun) THEN FREE_LUN, lun
    FILE_DELETE, OUTPUT_RASTER_URI, /QUIET
    RETURN
  ENDIF

  ;
  Channel = e.GetBroadcastChannel()
  Abort = ENVIABORTABLE()
  Start = ENVISTARTMESSAGE('Savitzky-Golay Filter', Abort)
  Channel.Broadcast, Start
  Progress = ENVIPROGRESSMESSAGE('Executing Savitzky-Golay Filter...', 0, Abort)

  ;��ȡ����ֵ
  IF input_raster.metadata.HasTag('data ignore value') THEN $
    missing = input_raster.metadata['data ignore value']

  fid = ENVIRasterToFID(input_raster)

  ENVI_FILE_QUERY, fid, ns = ns, nl = nl, nb = nb, $
    dims = dims, data_type = dt, bnames = bnames
  pos = FINDGEN(nb)

  ;��ʼ���˲���
  IF Order EQ 0 THEN BEGIN
    savgol_filter = SAVGOL(Nleft, Nright, Order, Degree)
  ENDIF ELSE BEGIN
    ;���order����0��Don't forget to normalize the coefficients.
    savgol_filter = SAVGOL(Nleft, Nright, Order, Degree)*(FACTORIAL(Order)/(0.1^Order))
  ENDELSE


  ;�ֿ鴦��, BIP
  tile_id = ENVI_INIT_TILE(fid, pos, $
    num_tiles=num_tiles, interleave = 2)

  ;���������ļ�
  OPENW, lun, output_raster_uri, /get_lun

  FOR i=0, num_tiles-1 DO BEGIN

    percentProgress = ROUND((i)* 100.0/num_tiles)
    Progress.PERCENT = percentProgress
    Channel.Broadcast, Progress
    IF (Abort.ABORT_REQUESTED) THEN BEGIN
      Finish = ENVIFINISHMESSAGE(Abort)
      Channel.Broadcast, Finish
      ENVI_TILE_DONE, Tile_id
      FREE_LUN, lun
      FILE_DELETE, OUTPUT_RASTER_URI, /QUIET
      RETURN
    ENDIF

    ;��ȡ�ֿ�����
    tile_data = ENVI_GET_TILE(tile_id, i)

    ;*******Insert your processing code here**********
    sz = SIZE(tile_data, /DIMENSIONS)
    FOR j=0, sz[1]-1 DO BEGIN

      pixel_data = tile_data[*,j]

      ;������ֵ������Сֵ���򲻴���
      IF MAX(pixel_data) NE MIN(pixel_data) THEN BEGIN

        ;��ȡ����������
        tname = TYPENAME(pixel_data)

        ;2018��3��6�� 09:17:22����
        ;������˫���Ȳſ���
        pixel_data = DOUBLE(pixel_data)

        data = CONVOL(pixel_data, savgol_filter, /nan, /edge_truncate, missing=missing)


        IF dt EQ 2 THEN tname = 'fix'
        tmp = execute('data='+tname+'(data)')

      ENDIF ELSE BEGIN
        data = pixel_data
      ENDELSE
      ;*************************************************
      ;д��
      WRITEU, lun, data
    ENDFOR
  ENDFOR

  out_dt = SIZE(data, /TYPE)

  ;���������
  Finish = ENVIFINISHMESSAGE(Abort)
  Channel.Broadcast, Finish

  ENVI_TILE_DONE, Tile_id
  FREE_LUN, lun

  ENVI_SETUP_HEAD, fname=OUTPUT_RASTER_URI, $
    ns=ns, nl=nl, nb=nb, $
    interleave=2, data_type=out_dt, $
    /write, /open, r_fid = r_fid
  ENVI_FILE_MNG, id=r_fid, /REMOVE

  ;�򿪽����д��Ԫ����
  output_raster = e.OpenRaster(OUTPUT_RASTER_URI, $
    METADATA_OVERRIDE = input_raster.METADATA, $
    SPATIALREF_OVERRIDE = input_raster.SPATIALREF)
  output_raster.WriteMetadata

  ;�����Ԥ��
  IF STRMATCH(output_raster_uri,'*envitempfile*', /fold_case) THEN BEGIN
    ;�Ƴ�Data Manager
    dataCol = e.DATA
    dataCol.Remove, output_raster, error=err
  ENDIF
END