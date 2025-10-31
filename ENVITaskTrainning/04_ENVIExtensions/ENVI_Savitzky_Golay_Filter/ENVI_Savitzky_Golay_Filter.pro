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

  ;如果显示结果
  IF Task.DISPLAY_RESULT EQ 1 THEN BEGIN
    view = e.GetView()
    layer = view.CreateLayer(Task.output_raster)
  ENDIF
END


PRO ENVISavitzkyGolayFilterTask, $
  input_raster=input_raster, $
  Nleft = Nleft, $
  Nright = Nright, $
  Order = Order, $  ;0 平滑；1 一阶导数； 2 二阶导数
  Degree = Degree, $ ;一般2-4，值越低，平滑效果越好，但是可能差生偏差；值越高，平滑效果越差，结果噪声越大，但是偏差小
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

  ;获取忽略值
  IF input_raster.metadata.HasTag('data ignore value') THEN $
    missing = input_raster.metadata['data ignore value']

  fid = ENVIRasterToFID(input_raster)

  ENVI_FILE_QUERY, fid, ns = ns, nl = nl, nb = nb, $
    dims = dims, data_type = dt, bnames = bnames
  pos = FINDGEN(nb)

  ;初始化滤波器
  IF Order EQ 0 THEN BEGIN
    savgol_filter = SAVGOL(Nleft, Nright, Order, Degree)
  ENDIF ELSE BEGIN
    ;如果order大于0，Don't forget to normalize the coefficients.
    savgol_filter = SAVGOL(Nleft, Nright, Order, Degree)*(FACTORIAL(Order)/(0.1^Order))
  ENDELSE


  ;分块处理, BIP
  tile_id = ENVI_INIT_TILE(fid, pos, $
    num_tiles=num_tiles, interleave = 2)

  ;打开输出结果文件
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

    ;获取分块数据
    tile_data = ENVI_GET_TILE(tile_id, i)

    ;*******Insert your processing code here**********
    sz = SIZE(tile_data, /DIMENSIONS)
    FOR j=0, sz[1]-1 DO BEGIN

      pixel_data = tile_data[*,j]

      ;如果最大值等于最小值，则不处理
      IF MAX(pixel_data) NE MIN(pixel_data) THEN BEGIN

        ;获取数据类型名
        tname = TYPENAME(pixel_data)

        ;2018年3月6日 09:17:22更新
        ;必须是双精度才可以
        pixel_data = DOUBLE(pixel_data)

        data = CONVOL(pixel_data, savgol_filter, /nan, /edge_truncate, missing=missing)


        IF dt EQ 2 THEN tname = 'fix'
        tmp = execute('data='+tname+'(data)')

      ENDIF ELSE BEGIN
        data = pixel_data
      ENDELSE
      ;*************************************************
      ;写出
      WRITEU, lun, data
    ENDFOR
  ENDFOR

  out_dt = SIZE(data, /TYPE)

  ;进度条完成
  Finish = ENVIFINISHMESSAGE(Abort)
  Channel.Broadcast, Finish

  ENVI_TILE_DONE, Tile_id
  FREE_LUN, lun

  ENVI_SETUP_HEAD, fname=OUTPUT_RASTER_URI, $
    ns=ns, nl=nl, nb=nb, $
    interleave=2, data_type=out_dt, $
    /write, /open, r_fid = r_fid
  ENVI_FILE_MNG, id=r_fid, /REMOVE

  ;打开结果，写出元数据
  output_raster = e.OpenRaster(OUTPUT_RASTER_URI, $
    METADATA_OVERRIDE = input_raster.METADATA, $
    SPATIALREF_OVERRIDE = input_raster.SPATIALREF)
  output_raster.WriteMetadata

  ;如果是预览
  IF STRMATCH(output_raster_uri,'*envitempfile*', /fold_case) THEN BEGIN
    ;移除Data Manager
    dataCol = e.DATA
    dataCol.Remove, output_raster, error=err
  ENDIF
END