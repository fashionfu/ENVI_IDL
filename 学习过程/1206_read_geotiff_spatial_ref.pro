;+
; 程序名: 1206_read_geotiff_spatial_ref.pro
; 功能  : 使用两种方法从 Landsat SR_B3/SR_B4 GeoTIFF 文件中读取空间参考信息
;         方法1: 使用 READ_TIFF 的 GEOTIFF 参数
;         方法2: 使用 ENVI_OPEN_DATA_FILE + /TIFF 关键字
; 说明  : 
;   - 此工具用于测试和验证从GeoTIFF文件读取空间参考的方法
;   - 注意：不再使用MTL XML/TXT文件读取空间参考（因为该方法不可靠）
;   - 参考: test_1204_geotiff_spatial_ref/1204_create_map_info_from_geotiff.pro
;-

PRO read_geotiff_spatial_ref
  COMPILE_OPT IDL2

  PRINT, '=========================================='
  PRINT, 'Landsat GeoTIFF 空间参考检查工具'
  PRINT, '方法1: READ_TIFF + GEOTIFF 参数'
  PRINT, '方法2: ENVI_OPEN_DATA_FILE + /TIFF 关键字'
  PRINT, '=========================================='
  PRINT, ''
  PRINT, '注意: 此工具从GeoTIFF文件读取空间参考，不再使用MTL文件'
  PRINT, ''

  ;------------------------------------------------------------------
  ; 1. 选择一个 Landsat SR_B3 或 SR_B4 文件
  ;------------------------------------------------------------------

  bandFile = ENVI_PICKFILE(TITLE='请选择 Landsat SR_B3 或 SR_B4 文件 (*_SR_B*.TIF)', $
    FILTER=['*_SR_B3.TIF', '*_SR_B3.tif', '*_SR_B4.TIF', '*_SR_B4.tif'])

  IF (bandFile EQ '') OR (bandFile EQ !NULL) THEN BEGIN
    PRINT, '未选择文件，退出。'
    RETURN
  ENDIF

  IF ~FILE_TEST(bandFile) THEN BEGIN
    PRINT, '错误: 文件不存在: ' + bandFile
    RETURN
  ENDIF

  PRINT, '选择的文件: ' + bandFile
  PRINT, ''

  ;------------------------------------------------------------------
  ; 方法1: 使用 READ_TIFF 的 GEOTIFF 参数
  ;------------------------------------------------------------------

  PRINT, '========== 方法1: READ_TIFF + GEOTIFF =========='
  PRINT, ''

  CATCH, errReadTiff
  IF errReadTiff EQ 0 THEN BEGIN
    ; 读取 GeoTIFF 信息（只读取元数据，不读取全部图像数据）
    ; 注意：READ_TIFF 会读取整个图像到内存，对于大文件可能很慢
    ; 但我们可以只读取第一行来获取 GEOTIFF 信息
    
    PRINT, '正在使用 READ_TIFF 读取 GeoTIFF 信息...'
    
    ; 尝试读取 GeoTIFF 元数据
    ; 注意：READ_TIFF 必须读取图像数据才能获取 GEOTIFF，但我们可以只读取一小部分
    img = READ_TIFF(bandFile, GEOTIFF=GeoKeys, SUB_RECT=[0, 0, 1, 1])
    CATCH, /CANCEL
    
    IF N_ELEMENTS(GeoKeys) GT 0 THEN BEGIN
      PRINT, '  ✓ 成功读取 GeoTIFF 信息！'
      PRINT, ''
      PRINT, 'GeoTIFF 结构信息:'
      HELP, GeoKeys, /STRUCTURE
      PRINT, ''
      PRINT, 'GeoTIFF 内容:'
      PRINT, GeoKeys
      PRINT, ''
      
      ; 提取关键信息（使用 CATCH 来安全访问结构体标签）
      CATCH, errPixelScale
      IF errPixelScale EQ 0 THEN BEGIN
        pixelScale = GeoKeys.MODELPIXELSCALETAG
        CATCH, /CANCEL
        IF N_ELEMENTS(pixelScale) GE 2 THEN BEGIN
          PRINT, '  像元大小 (MODELPIXELSCALETAG): ', pixelScale[0], ' x ', pixelScale[1], ' 米'
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      
      CATCH, errTiePoint
      IF errTiePoint EQ 0 THEN BEGIN
        tiePoint = GeoKeys.MODELTIEPOINTTAG
        CATCH, /CANCEL
        IF N_ELEMENTS(tiePoint) GE 6 THEN BEGIN
          ; MODELTIEPOINTTAG 的前三个是栅格坐标，后三个是模型坐标
          rasterX = tiePoint[0]
          rasterY = tiePoint[1]
          modelX = tiePoint[3]
          modelY = tiePoint[4]
          PRINT, '  左上角栅格坐标: (', rasterX, ', ', rasterY, ')'
          PRINT, '  左上角投影坐标: (', modelX, ', ', modelY, ') 米'
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      
      CATCH, errCitation
      IF errCitation EQ 0 THEN BEGIN
        PRINT, '  投影信息: ', GeoKeys.GTCITATIONGEOKEY
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      
      CATCH, errGeogCitation
      IF errGeogCitation EQ 0 THEN BEGIN
        PRINT, '  地理坐标系: ', GeoKeys.GEOGCITATIONGEOKEY
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      
      CATCH, errProjCode
      IF errProjCode EQ 0 THEN BEGIN
        PRINT, '  投影坐标系代码: ', GeoKeys.PROJECTEDCSTYPEGEOKEY
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      
      PRINT, ''
    ENDIF ELSE BEGIN
      PRINT, '  ✗ 未找到 GeoTIFF 信息（文件可能不是 GeoTIFF 格式）'
      PRINT, ''
    ENDELSE
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  ✗ READ_TIFF 读取失败: ' + !ERROR_STATE.MSG
    PRINT, ''
  ENDELSE

  ;------------------------------------------------------------------
  ; 方法2: 使用 ENVI_OPEN_DATA_FILE + /TIFF 关键字
  ;------------------------------------------------------------------

  PRINT, '========== 方法2: ENVI_OPEN_DATA_FILE + /TIFF =========='
  PRINT, ''

  ; 启动 ENVI Batch 模式
  ENVI_BATCH_INIT

  CATCH, errEnviOpen
  IF errEnviOpen EQ 0 THEN BEGIN
    PRINT, '正在使用 ENVI_OPEN_DATA_FILE 打开 TIF 文件...'
    
    ENVI_OPEN_DATA_FILE, bandFile, /TIFF, R_FID=fid
    
    IF (fid EQ -1) THEN BEGIN
      PRINT, '  ✗ ENVI_OPEN_DATA_FILE 返回 fid = -1，打开失败。'
    ENDIF ELSE BEGIN
      PRINT, '  ✓ 成功打开，fid = ', fid
      PRINT, ''
      
      ; 获取投影信息
      CATCH, errProj
      IF errProj EQ 0 THEN BEGIN
        proj = ENVI_GET_PROJECTION(FID=fid)
        CATCH, /CANCEL
        
        IF N_ELEMENTS(proj) GT 0 THEN BEGIN
          PRINT, '  投影结构信息:'
          HELP, proj, /STRUCTURE
          PRINT, ''
          PRINT, '  投影内容:'
          PRINT, proj
          PRINT, ''
          
          ; 提取关键信息（使用 CATCH 来安全访问结构体标签）
          CATCH, errName
          IF errName EQ 0 THEN BEGIN
            PRINT, '  投影名称: ', proj.NAME
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
          ENDELSE
          
          CATCH, errDatum
          IF errDatum EQ 0 THEN BEGIN
            PRINT, '  基准面: ', proj.DATUM
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
          ENDELSE
          
          CATCH, errParams
          IF errParams EQ 0 THEN BEGIN
            params = proj.PARAMS
            CATCH, /CANCEL
            IF N_ELEMENTS(params) GT 0 THEN BEGIN
              PRINT, '  UTM Zone: ', params[0]
            ENDIF
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
          ENDELSE
          
          PRINT, ''
          
          ; 使用 ENVI_CONVERT_FILE_COORDINATES 获取左上角坐标
          CATCH, errConvert
          IF errConvert EQ 0 THEN BEGIN
            xf = [0]
            yf = [0]
            ENVI_CONVERT_FILE_COORDINATES, fid, xf, yf, xMap, yMap, /TO_MAP
            CATCH, /CANCEL
            
            PRINT, '  使用 ENVI_CONVERT_FILE_COORDINATES 转换坐标:'
            PRINT, '    像素坐标 (0, 0) -> 投影坐标: (', xMap[0], ', ', yMap[0], ') 米'
            PRINT, ''
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '  警告: ENVI_CONVERT_FILE_COORDINATES 失败: ' + !ERROR_STATE.MSG
            PRINT, ''
          ENDELSE
        ENDIF ELSE BEGIN
          PRINT, '  ✗ 未找到投影信息'
          PRINT, ''
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  ✗ 获取投影信息失败: ' + !ERROR_STATE.MSG
        PRINT, ''
      ENDELSE
    ENDELSE
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  ✗ ENVI_OPEN_DATA_FILE 打开失败: ' + !ERROR_STATE.MSG
    PRINT, ''
  ENDELSE

  ; 退出 ENVI Batch 模式
  ENVI_BATCH_EXIT

  PRINT, '=========================================='
  PRINT, 'GeoTIFF 空间参考检查完成'
  PRINT, '=========================================='
  PRINT, ''

END
