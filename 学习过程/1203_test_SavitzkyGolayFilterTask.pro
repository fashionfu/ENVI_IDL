PRO 1203_test_SavitzkyGolayFilterTask, $
  input_raster=input_raster, $
  Nleft = Nleft, $
  Nright = Nright, $
  Order = Order, $  ;0 平滑；1 一阶导数； 2 二阶导数
  Degree = Degree, $ ;一般2-4，值越低，平滑效果越好，但是可能产生偏差；值越高，平滑效果越差，但是偏差越小
  DISPLAY_RESULT=DISPLAY_RESULT, $
  OUTPUT_RASTER_URI=output_raster_uri

  COMPILE_OPT idl2
  e=envi(/current)

  ; General error handler
  CATCH, err
  IF (err NE 0) THEN BEGIN
    CATCH, /CANCEL
    IF OBJ_VALID(e) THEN $
      e.ReportError, 'ERROR: ' + !ERROR_STATE.MSG + STRING(13B) + $
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

  ;获取缺失值
  IF input_raster.METADATA.HasTag('data ignore value') THEN $
    missing = input_raster.METADATA['data ignore value']

  fid = ENVIRasterToFID(input_raster)

  ENVI_FILE_QUERY, fid, ns = ns, nl = nl, nb = nb, $
    dims = dims, data_type = dt, bnames = bnames
  pos = FINDGEN(nb)

  ;检查波段数是否足够
  min_bands = Nleft + Nright + 1
  IF nb LT min_bands THEN BEGIN
    e.ReportError, 'ERROR: 输入数据波段数不足！' + STRING(13B) + $
      '当前波段数: ' + STRING(nb) + STRING(13B) + $
      '需要至少: ' + STRING(min_bands) + ' 个波段 (Nleft + Nright + 1)' + STRING(13B) + $
      '请减小 Nleft 和 Nright 的值，或使用波段数更多的数据。'
    RETURN
  ENDIF

  ;初始化滤波器
  IF Order EQ 0 THEN BEGIN
    savgol_filter = SAVGOL(Nleft, Nright, Order, Degree)
  ENDIF ELSE BEGIN
    ;如果order不等于0，Don't forget to normalize the coefficients.
    savgol_filter = SAVGOL(Nleft, Nright, Order, Degree)*(FACTORIAL(Order)/(0.1^Order))
  ENDELSE


  ;分块处理, BIP
  tile_id = ENVI_INIT_TILE(fid, pos, $
    num_tiles=num_tiles, interleave = 2)

  ;创建输出文件
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

      ;如果最大值等于最小值，不处理
      IF MAX(pixel_data) NE MIN(pixel_data) THEN BEGIN

        ;获取数据类型名称
        tname = TYPENAME(pixel_data)

        ;2018年3月6日 09:17:22修改
        ;必须转换为双精度才可以
        pixel_data = DOUBLE(pixel_data)

        data = CONVOL(pixel_data, savgol_filter, /nan, /edge_truncate, missing=missing)


        IF dt EQ 2 THEN tname = 'fix'
        tmp = execute('data='+tname+'(data)')

      ENDIF ELSE BEGIN
        data = pixel_data
      ENDELSE
      ;*************************************************
      ;写入
      WRITEU, lun, data
    ENDFOR
  ENDFOR

  out_dt = SIZE(data, /TYPE)

  ;完成处理
  Finish = ENVIFINISHMESSAGE(Abort)
  Channel.Broadcast, Finish

  ENVI_TILE_DONE, Tile_id
  FREE_LUN, lun

  ENVI_SETUP_HEAD, fname=OUTPUT_RASTER_URI, $
    ns=ns, nl=nl, nb=nb, $
    interleave=2, data_type=out_dt, $
    /write, /open, r_fid = r_fid
  ENVI_FILE_MNG, id=r_fid, /REMOVE

  ;打开输出并写入元数据
  output_raster = e.OpenRaster(OUTPUT_RASTER_URI, $
    METADATA_OVERRIDE = input_raster.METADATA, $
    SPATIALREF_OVERRIDE = input_raster.SPATIALREF)
  output_raster.WriteMetadata

  ;临时文件处理
  IF STRMATCH(output_raster_uri,'*envitempfile*', /fold_case) THEN BEGIN
    ;移除Data Manager
    dataCol = e.DATA
    dataCol.Remove, output_raster, error=err
  ENDIF
END

