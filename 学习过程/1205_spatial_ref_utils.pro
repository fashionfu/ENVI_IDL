;+
; 辅助函数文件：空间参考处理工具函数
; 用于batch_water_extraction_UI.pro和batch_water_extraction.pro
;-

;+
; 辅助函数：从 GeoTIFF 文件中读取空间参考信息，并创建 ENVI MAP_INFO 结构
; 参考: test_1204_geotiff_spatial_ref/1204_create_map_info_from_geotiff.pro
;-
FUNCTION create_map_info_from_geotiff, geotiffFile
  COMPILE_OPT IDL2

  ; 检查文件是否存在
  IF ~FILE_TEST(geotiffFile) THEN BEGIN
    PRINT, '  错误: GeoTIFF 文件不存在: ' + geotiffFile
    RETURN, !NULL
  ENDIF

  ; 初始化变量
  utmZone = 50
  datum = 'WGS84'
  pixelSize = 30.0
  ulX = 0.0
  ulY = 0.0

  ;------------------------------------------------------------------
  ; 方法2: 使用 ENVI_OPEN_DATA_FILE + /TIFF（优先方法）
  ; 注意: 不使用 ENVI_BATCH_INIT，因为主程序已经启动了ENVI会话
  ;------------------------------------------------------------------
  CATCH, errEnviOpen
  IF errEnviOpen EQ 0 THEN BEGIN
    ENVI_OPEN_DATA_FILE, geotiffFile, /TIFF, R_FID=fid
    CATCH, /CANCEL

    IF (fid NE -1) THEN BEGIN
      ; 获取投影信息
      CATCH, errProj
      IF errProj EQ 0 THEN BEGIN
        proj = ENVI_GET_PROJECTION(FID=fid)
        CATCH, /CANCEL

        IF N_ELEMENTS(proj) GT 0 THEN BEGIN
          ; 提取 UTM Zone
          CATCH, errParams
          IF errParams EQ 0 THEN BEGIN
            params = proj.PARAMS
            CATCH, /CANCEL
            IF N_ELEMENTS(params) GT 0 THEN BEGIN
              utmZone = FIX(params[0])
            ENDIF
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
          ENDELSE

          ; 提取基准面
          CATCH, errDatum
          IF errDatum EQ 0 THEN BEGIN
            datumStr = proj.DATUM
            CATCH, /CANCEL
            IF STRMATCH(datumStr, '*WGS*84*') OR STRMATCH(datumStr, '*WGS-84*') THEN BEGIN
              datum = 'WGS84'
            ENDIF ELSE BEGIN
              datum = datumStr
            ENDELSE
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
          ENDELSE

          ; 使用 ENVI_CONVERT_FILE_COORDINATES 获取左上角坐标
          CATCH, errConvert
          IF errConvert EQ 0 THEN BEGIN
            xf = [0]
            yf = [0]
            ENVI_CONVERT_FILE_COORDINATES, fid, xf, yf, xMap, yMap, /TO_MAP
            CATCH, /CANCEL
            ulX = xMap[0]
            ulY = yMap[0]
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
          ENDELSE

          ; 获取像元大小（需要查询文件信息）
          CATCH, errFileQuery
          IF errFileQuery EQ 0 THEN BEGIN
            ENVI_FILE_QUERY, fid, NS=ns, NL=nl
            CATCH, /CANCEL
            ; 如果能够获取文件尺寸，可以尝试从投影坐标计算像元大小
            ; 但这里我们使用默认值 30.0，或者从方法1获取
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
          ENDELSE

          ; 关闭文件
          ENVI_FILE_MNG, id=fid, /REMOVE

          ; 如果成功获取了坐标，创建 MAP_INFO
          IF (ulX NE 0.0) OR (ulY NE 0.0) THEN BEGIN
            mapInfo = ENVI_MAP_INFO_CREATE( $
              /UTM, $
              ZONE=utmZone, $
              /NORTH, $
              DATUM=datum, $
              MC=[0.0, 0.0, ulX, ulY], $
              PS=[pixelSize, pixelSize] $
            )
            RETURN, mapInfo
          ENDIF
        ENDIF ELSE BEGIN
          ; 投影信息为空，关闭文件
          ENVI_FILE_MNG, id=fid, /REMOVE
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        ; 获取投影信息失败，关闭文件
        IF fid NE -1 THEN ENVI_FILE_MNG, id=fid, /REMOVE
      ENDELSE
    ENDIF
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
  ENDELSE

  ;------------------------------------------------------------------
  ; 方法1: 使用 READ_TIFF 的 GEOTIFF 参数（备用方法）
  ;------------------------------------------------------------------
  CATCH, errReadTiff
  IF errReadTiff EQ 0 THEN BEGIN
    img = READ_TIFF(geotiffFile, GEOTIFF=GeoKeys, SUB_RECT=[0, 0, 1, 1])
    CATCH, /CANCEL

    IF N_ELEMENTS(GeoKeys) GT 0 THEN BEGIN
      ; 提取像元大小
      CATCH, errPixelScale
      IF errPixelScale EQ 0 THEN BEGIN
        pixelScale = GeoKeys.MODELPIXELSCALETAG
        CATCH, /CANCEL
        IF N_ELEMENTS(pixelScale) GE 2 THEN BEGIN
          pixelSize = pixelScale[0]
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE

      ; 提取左上角坐标
      CATCH, errTiePoint
      IF errTiePoint EQ 0 THEN BEGIN
        tiePoint = GeoKeys.MODELTIEPOINTTAG
        CATCH, /CANCEL
        IF N_ELEMENTS(tiePoint) GE 6 THEN BEGIN
          ulX = tiePoint[3]
          ulY = tiePoint[4]
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE

      ; 提取 UTM Zone（从投影信息字符串中解析）
      CATCH, errCitation
      IF errCitation EQ 0 THEN BEGIN
        citation = GeoKeys.GTCITATIONGEOKEY
        CATCH, /CANCEL
        ; 尝试从字符串中提取 UTM Zone，例如 "WGS 84 / UTM zone 52N"
        zonePos = STRPOS(STRUPCASE(citation), 'ZONE')
        IF zonePos GE 0 THEN BEGIN
          zoneStr = STRMID(citation, zonePos+4)
          zoneStr = STRTRIM(zoneStr, 1)
          ; 提取数字部分
          zoneNum = ''
          FOR i=0, STRLEN(zoneStr)-1 DO BEGIN
            char = STRMID(zoneStr, i, 1)
            IF (char GE '0') AND (char LE '9') THEN BEGIN
              zoneNum = zoneNum + char
            ENDIF ELSE BEGIN
              BREAK
            ENDELSE
          ENDFOR
          IF STRLEN(zoneNum) GT 0 THEN BEGIN
            utmZone = FIX(zoneNum)
          ENDIF
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE

      ; 提取基准面
      CATCH, errGeogCitation
      IF errGeogCitation EQ 0 THEN BEGIN
        geogCitation = GeoKeys.GEOGCITATIONGEOKEY
        CATCH, /CANCEL
        IF STRMATCH(geogCitation, '*WGS*84*') OR STRMATCH(geogCitation, '*WGS-84*') THEN BEGIN
          datum = 'WGS84'
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE

      ; 创建 MAP_INFO
      IF (ulX NE 0.0) OR (ulY NE 0.0) THEN BEGIN
        mapInfo = ENVI_MAP_INFO_CREATE( $
          /UTM, $
          ZONE=utmZone, $
          /NORTH, $
          DATUM=datum, $
          MC=[0.0, 0.0, ulX, ulY], $
          PS=[pixelSize, pixelSize] $
        )
        RETURN, mapInfo
      ENDIF
    ENDIF
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
  ENDELSE

  ; 如果两种方法都失败，返回 !NULL
  RETURN, !NULL

END

;+
; 辅助函数：为raster设置空间参考
;-
FUNCTION set_spatial_ref_to_raster, inputRaster, mapInfo
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)

  IF ~OBJ_VALID(inputRaster) THEN BEGIN
    PRINT, '  错误: inputRaster对象无效'
    RETURN, !NULL
  ENDIF

  IF mapInfo EQ !NULL THEN BEGIN
    PRINT, '  错误: mapInfo为空'
    RETURN, !NULL
  ENDIF

  ; 导出raster到临时文件
  PRINT, '  正在导出raster到临时文件...'
  tempFile = e.GetTemporaryFilename('dat')
  IF FILE_TEST(tempFile) THEN BEGIN
    FILE_DELETE, tempFile, /QUIET, /ALLOW_NONEXISTENT
    hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET, /ALLOW_NONEXISTENT
  ENDIF

  CATCH, errExport
  IF errExport EQ 0 THEN BEGIN
    inputRaster.Export, tempFile, 'ENVI'
    CATCH, /CANCEL
    WAIT, 0.5
    IF ~FILE_TEST(tempFile) THEN BEGIN
      PRINT, '  错误: 导出后临时文件不存在'
      RETURN, !NULL
    ENDIF
    PRINT, '  ✓ Raster已导出到临时文件'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 导出raster失败: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE

  ; 使用ENVI_SETUP_HEAD设置空间参考
  PRINT, '  正在设置空间参考信息到文件头...'
  CATCH, errSetup
  IF errSetup EQ 0 THEN BEGIN
    ENVI_OPEN_FILE, tempFile, r_fid=fid
    IF fid GE 0 THEN BEGIN
      ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=nb, data_type=dt, interleave=interleave
      ENVI_SETUP_HEAD, $
        FNAME=tempFile, $
        NS=ns, $
        NL=nl, $
        NB=nb, $
        DATA_TYPE=dt, $
        INTERLEAVE=interleave, $
        MAP_INFO=mapInfo, $
        /WRITE, /OPEN
      ENVI_FILE_MNG, id=fid, /REMOVE
      CATCH, /CANCEL
      PRINT, '  ✓ 空间参考信息已写入文件头'
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 无法打开临时文件'
      RETURN, !NULL
    ENDELSE
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 设置空间参考时发生错误: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE

  ; 重新打开raster并验证空间参考
  PRINT, '  正在重新打开raster并验证空间参考...'
  WAIT, 0.5
  outputRaster = e.OpenRaster(tempFile)
  IF OBJ_VALID(outputRaster) THEN BEGIN
    ; 验证空间参考是否成功设置
    CATCH, errVerifySR
    IF errVerifySR EQ 0 THEN BEGIN
      spatialRef = outputRaster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(spatialRef) THEN BEGIN
        PRINT, '  ✓ 空间参考验证成功'
        RETURN, outputRaster
      ENDIF ELSE BEGIN
        PRINT, '  错误: 重新打开后raster仍然没有空间参考信息'
        outputRaster.Close
        RETURN, !NULL
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 验证空间参考时发生错误'
      outputRaster.Close
      RETURN, !NULL
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '  错误: 重新打开raster失败'
    RETURN, !NULL
  ENDELSE

END

;+
; 辅助函数：递归搜索文件
; 输入: rootDir - 根目录路径
;       pattern - 文件匹配模式（如 '*_MTL.xml'）
; 输出: 文件路径数组
;-
FUNCTION search_files_recursive, rootDir, pattern
  COMPILE_OPT IDL2
  
  result = !NULL
  
  ; 在当前目录搜索文件
  files = FILE_SEARCH(rootDir + PATH_SEP() + pattern, COUNT=count)
  IF count GT 0 THEN BEGIN
    IF result EQ !NULL THEN BEGIN
      result = files
    ENDIF ELSE BEGIN
      result = [result, files]
    ENDELSE
  ENDIF
  
  ; 获取所有子项（文件和目录）
  allItems = FILE_SEARCH(rootDir + PATH_SEP() + '*', COUNT=item_count)
  IF item_count GT 0 THEN BEGIN
    FOR i=0, item_count-1 DO BEGIN
      itemPath = allItems[i]
      ; 检查是否为目录（通过检查是否存在且不是文件）
      ; 使用FILE_TEST检查路径，如果是目录则递归搜索
      IF FILE_TEST(itemPath, /DIRECTORY) THEN BEGIN
        ; 递归搜索子目录
        subFiles = search_files_recursive(itemPath, pattern)
        IF subFiles NE !NULL THEN BEGIN
          IF result EQ !NULL THEN BEGIN
            result = subFiles
          ENDIF ELSE BEGIN
            result = [result, subFiles]
          ENDELSE
        ENDIF
      ENDIF
    ENDFOR
  ENDIF
  
  RETURN, result
END

