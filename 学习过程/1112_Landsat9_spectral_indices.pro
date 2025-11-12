;+
; 程序名: landsat9_spectral_indices.pro
; 功能: 处理2021和2025年Landsat 9数据，计算NDVI、NDWI、NDBI光谱指数
; 输入: Landsat 9 MTL文件
; 输出: NDVI、NDWI、NDBI影像（保存到results文件夹）
; 作者: Auto
; 日期: 2025
;-

; 辅助函数：从XML文件中提取标签值（通用函数）
FUNCTION extract_xml_tag_value, xmlLines, tagName, defaultValue
  COMPILE_OPT IDL2
  
  ; 参数：
  ;   xmlLines: XML文件行数组
  ;   tagName: 标签名称（不包含<>）
  ;   defaultValue: 默认值（如果未找到）
  ; 返回值：提取的值（字符串），如果未找到返回默认值
  
  tagStartTag = '<' + tagName + '>'
  tagEndTag = '</' + tagName + '>'
  tagStartLen = STRLEN(tagStartTag)
  
  FOR i=0, N_ELEMENTS(xmlLines)-1 DO BEGIN
    line = xmlLines[i]
    lineUpper = STRUPCASE(line)
    tagPos = STRPOS(lineUpper, STRUPCASE(tagStartTag))
    IF tagPos GE 0 THEN BEGIN
      tagStart = tagPos + tagStartLen
      tagEnd = STRPOS(lineUpper, STRUPCASE(tagEndTag))
      IF tagEnd GT tagStart THEN BEGIN
        valueStr = STRMID(line, tagStart, tagEnd - tagStart)
        valueStr = STRTRIM(valueStr, 2)
        RETURN, valueStr
      ENDIF
    ENDIF
  ENDFOR
  
  RETURN, defaultValue
END

; 辅助函数：从MTL XML文件读取投影参数并创建空间参考
FUNCTION create_spatial_ref_from_mtl_xml, mtlXmlFile, nColumns, nRows
  COMPILE_OPT IDL2
  
  ; 检查文件是否存在
  IF ~FILE_TEST(mtlXmlFile) THEN BEGIN
    PRINT, '  错误: MTL XML文件不存在: ' + mtlXmlFile
    RETURN, !NULL
  ENDIF
  
  ; 读取XML文件内容
  CATCH, errOpen
  IF errOpen EQ 0 THEN BEGIN
    OPENR, lun, mtlXmlFile, /GET_LUN
    xmlLines = STRARR(1000)
    lineCount = 0
    WHILE ~EOF(lun) && lineCount LT 1000 DO BEGIN
      READF, lun, xmlLines[lineCount]
      lineCount++
    ENDWHILE
    CLOSE, lun
    FREE_LUN, lun
    xmlLines = xmlLines[0:lineCount-1]
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 无法打开MTL XML文件: ' + mtlXmlFile + ' - ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  
  ; 解析XML获取投影参数和地理坐标
  utmZone = 50
  datum = 'WGS84'  ; 默认值，将从XML读取
  pixelSize = 30.0
  ulX = 225900.0
  ulY = 2833200.0
  
  ; 初始化四个角的经纬度坐标
  ulLat = 0.0
  ulLon = 0.0
  urLat = 0.0
  urLon = 0.0
  llLat = 0.0
  llLon = 0.0
  lrLat = 0.0
  lrLon = 0.0
  
  ; 初始化影像尺寸（用于验证）
  expectedLines = 0
  expectedSamples = 0
  
  ; 初始化其他信息
  dateAcquired = ''
  cloudCover = 0.0
  sunAzimuth = 0.0
  sunElevation = 0.0
  
  ; 使用辅助函数提取XML标签值
  ; 提取DATUM
  datumStr = extract_xml_tag_value(xmlLines, 'DATUM', 'WGS84')
  ; 标准化DATUM名称（WGS84 -> WGS84，WGS-84 -> WGS84）
  IF STRMATCH(datumStr, '*WGS84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE IF STRMATCH(datumStr, '*WGS-84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE BEGIN
    datum = datumStr
  ENDELSE
  
  ; 提取UTM_ZONE
  zoneStr = extract_xml_tag_value(xmlLines, 'UTM_ZONE', '50')
        utmZone = FIX(STRTRIM(zoneStr, 2))
  
  ; 提取REFLECTIVE_LINES和REFLECTIVE_SAMPLES（用于验证影像尺寸）
  linesStr = extract_xml_tag_value(xmlLines, 'REFLECTIVE_LINES', '0')
  IF STRLEN(linesStr) GT 0 THEN expectedLines = FIX(STRTRIM(linesStr, 2))
  
  samplesStr = extract_xml_tag_value(xmlLines, 'REFLECTIVE_SAMPLES', '0')
  IF STRLEN(samplesStr) GT 0 THEN expectedSamples = FIX(STRTRIM(samplesStr, 2))
  
  ; 提取DATE_ACQUIRED（用于验证）
  dateAcquired = extract_xml_tag_value(xmlLines, 'DATE_ACQUIRED', '')
  
  ; 提取CLOUD_COVER（用于评估数据质量）
  cloudStr = extract_xml_tag_value(xmlLines, 'CLOUD_COVER', '0')
  IF STRLEN(cloudStr) GT 0 THEN cloudCover = FLOAT(STRTRIM(cloudStr, 2))
  
  ; 提取SUN_AZIMUTH和SUN_ELEVATION（用于后续分析）
  sunAzStr = extract_xml_tag_value(xmlLines, 'SUN_AZIMUTH', '0')
  IF STRLEN(sunAzStr) GT 0 THEN sunAzimuth = FLOAT(STRTRIM(sunAzStr, 2))
  
  sunElStr = extract_xml_tag_value(xmlLines, 'SUN_ELEVATION', '0')
  IF STRLEN(sunElStr) GT 0 THEN sunElevation = FLOAT(STRTRIM(sunElStr, 2))
  
  ; 使用辅助函数提取投影坐标（所有四个角）
  ulXStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_PROJECTION_X_PRODUCT', '225900.0')
  IF STRLEN(ulXStr) GT 0 THEN ulX = FLOAT(STRTRIM(ulXStr, 2))
  
  ulYStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_PROJECTION_Y_PRODUCT', '2833200.0')
  IF STRLEN(ulYStr) GT 0 THEN ulY = FLOAT(STRTRIM(ulYStr, 2))
  
  ; 读取其他角的投影坐标（用于验证）
  urXStr = extract_xml_tag_value(xmlLines, 'CORNER_UR_PROJECTION_X_PRODUCT', '0')
  urYStr = extract_xml_tag_value(xmlLines, 'CORNER_UR_PROJECTION_Y_PRODUCT', '0')
  llXStr = extract_xml_tag_value(xmlLines, 'CORNER_LL_PROJECTION_X_PRODUCT', '0')
  llYStr = extract_xml_tag_value(xmlLines, 'CORNER_LL_PROJECTION_Y_PRODUCT', '0')
  lrXStr = extract_xml_tag_value(xmlLines, 'CORNER_LR_PROJECTION_X_PRODUCT', '0')
  lrYStr = extract_xml_tag_value(xmlLines, 'CORNER_LR_PROJECTION_Y_PRODUCT', '0')
  
  ; 使用辅助函数提取四个角的经纬度坐标（地理坐标）
  ulLatStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_LAT_PRODUCT', '0')
  IF STRLEN(ulLatStr) GT 0 THEN ulLat = FLOAT(STRTRIM(ulLatStr, 2))
  
  ulLonStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_LON_PRODUCT', '0')
  IF STRLEN(ulLonStr) GT 0 THEN ulLon = FLOAT(STRTRIM(ulLonStr, 2))
  
  urLatStr = extract_xml_tag_value(xmlLines, 'CORNER_UR_LAT_PRODUCT', '0')
  IF STRLEN(urLatStr) GT 0 THEN urLat = FLOAT(STRTRIM(urLatStr, 2))
  
  urLonStr = extract_xml_tag_value(xmlLines, 'CORNER_UR_LON_PRODUCT', '0')
  IF STRLEN(urLonStr) GT 0 THEN urLon = FLOAT(STRTRIM(urLonStr, 2))
  
  llLatStr = extract_xml_tag_value(xmlLines, 'CORNER_LL_LAT_PRODUCT', '0')
  IF STRLEN(llLatStr) GT 0 THEN llLat = FLOAT(STRTRIM(llLatStr, 2))
  
  llLonStr = extract_xml_tag_value(xmlLines, 'CORNER_LL_LON_PRODUCT', '0')
  IF STRLEN(llLonStr) GT 0 THEN llLon = FLOAT(STRTRIM(llLonStr, 2))
  
  lrLatStr = extract_xml_tag_value(xmlLines, 'CORNER_LR_LAT_PRODUCT', '0')
  IF STRLEN(lrLatStr) GT 0 THEN lrLat = FLOAT(STRTRIM(lrLatStr, 2))
  
  lrLonStr = extract_xml_tag_value(xmlLines, 'CORNER_LR_LON_PRODUCT', '0')
  IF STRLEN(lrLonStr) GT 0 THEN lrLon = FLOAT(STRTRIM(lrLonStr, 2))
  
  ; 提取GRID_CELL_SIZE_REFLECTIVE
  psStr = extract_xml_tag_value(xmlLines, 'GRID_CELL_SIZE_REFLECTIVE', '30.0')
  IF STRLEN(psStr) GT 0 THEN pixelSize = FLOAT(STRTRIM(psStr, 2))
  
  ; 验证投影坐标的一致性（使用四个角坐标计算影像范围）
  IF (STRLEN(urXStr) GT 0) AND (STRLEN(llYStr) GT 0) THEN BEGIN
    ; 计算期望的影像尺寸（基于投影坐标）
    urX = FLOAT(STRTRIM(urXStr, 2))
    llY = FLOAT(STRTRIM(llYStr, 2))
    expectedWidth = FIX((urX - ulX) / pixelSize) + 1
    expectedHeight = FIX((ulY - llY) / pixelSize) + 1
    ; 与XML中定义的尺寸比较
    IF (expectedLines GT 0) AND (expectedSamples GT 0) THEN BEGIN
      IF (ABS(expectedWidth - expectedSamples) GT 5) OR (ABS(expectedHeight - expectedLines) GT 5) THEN BEGIN
        PRINT, '  警告: 投影坐标计算的影像尺寸与XML定义不一致'
        PRINT, '    投影坐标计算: ' + STRING(expectedHeight) + ' 行 x ' + STRING(expectedWidth) + ' 列'
        PRINT, '    XML定义: ' + STRING(expectedLines) + ' 行 x ' + STRING(expectedSamples) + ' 列'
      ENDIF
    ENDIF
  ENDIF
  
  ; 验证影像尺寸
  IF (expectedLines GT 0) AND (expectedSamples GT 0) THEN BEGIN
    IF (nRows NE expectedLines) OR (nColumns NE expectedSamples) THEN BEGIN
      PRINT, '  警告: 影像尺寸与XML文件中的定义不一致'
      PRINT, '    XML定义: ' + STRING(expectedLines) + ' 行 x ' + STRING(expectedSamples) + ' 列'
      PRINT, '    实际尺寸: ' + STRING(nRows) + ' 行 x ' + STRING(nColumns) + ' 列'
      PRINT, '    将使用实际影像尺寸创建空间参考'
    ENDIF ELSE BEGIN
      PRINT, '  ✓ 影像尺寸验证通过: ' + STRING(nRows) + ' 行 x ' + STRING(nColumns) + ' 列'
    ENDELSE
      ENDIF
  
  ; 打印解析到的参数
  PRINT, '  解析到的投影参数:'
  PRINT, '    DATUM: ' + datum
  PRINT, '    UTM Zone: ' + STRING(utmZone)
  PRINT, '    左上角投影坐标: (' + STRING(ulX, FORMAT='(F12.2)') + ', ' + STRING(ulY, FORMAT='(F12.2)') + ') 米'
  IF (STRLEN(urXStr) GT 0) AND (STRLEN(urYStr) GT 0) THEN BEGIN
    urX = FLOAT(STRTRIM(urXStr, 2))
    urY = FLOAT(STRTRIM(urYStr, 2))
    PRINT, '    右上角投影坐标: (' + STRING(urX, FORMAT='(F12.2)') + ', ' + STRING(urY, FORMAT='(F12.2)') + ') 米'
    ENDIF
  IF (STRLEN(llXStr) GT 0) AND (STRLEN(llYStr) GT 0) THEN BEGIN
    llX = FLOAT(STRTRIM(llXStr, 2))
    llY = FLOAT(STRTRIM(llYStr, 2))
    PRINT, '    左下角投影坐标: (' + STRING(llX, FORMAT='(F12.2)') + ', ' + STRING(llY, FORMAT='(F12.2)') + ') 米'
  ENDIF
  IF (STRLEN(lrXStr) GT 0) AND (STRLEN(lrYStr) GT 0) THEN BEGIN
    lrX = FLOAT(STRTRIM(lrXStr, 2))
    lrY = FLOAT(STRTRIM(lrYStr, 2))
    PRINT, '    右下角投影坐标: (' + STRING(lrX, FORMAT='(F12.2)') + ', ' + STRING(lrY, FORMAT='(F12.2)') + ') 米'
  ENDIF
  PRINT, '    像元大小: ' + STRING(pixelSize, FORMAT='(F6.2)') + ' 米'
  
  ; 打印其他信息
  IF STRLEN(dateAcquired) GT 0 THEN BEGIN
    PRINT, '  数据获取日期: ' + dateAcquired
      ENDIF
  IF cloudCover GT 0.0 THEN BEGIN
    PRINT, '  云覆盖: ' + STRING(cloudCover, FORMAT='(F4.2)') + '%'
    IF cloudCover GT 20.0 THEN BEGIN
      PRINT, '    警告: 云覆盖较高，可能影响分析结果'
    ENDIF
  ENDIF
  IF (sunAzimuth NE 0.0) OR (sunElevation NE 0.0) THEN BEGIN
    PRINT, '  太阳角度: 方位角 ' + STRING(sunAzimuth, FORMAT='(F8.4)') + '°, 高度角 ' + STRING(sunElevation, FORMAT='(F8.4)') + '°'
  ENDIF
  
  ; 打印解析到的地理坐标（经纬度）
  IF (ulLat NE 0.0) OR (ulLon NE 0.0) THEN BEGIN
    PRINT, '  解析到的地理坐标（经纬度）:'
    PRINT, '    左上角: 纬度 ' + STRING(ulLat, FORMAT='(F10.6)') + '°, 经度 ' + STRING(ulLon, FORMAT='(F10.6)') + '°'
    IF (urLat NE 0.0) OR (urLon NE 0.0) THEN BEGIN
      PRINT, '    右上角: 纬度 ' + STRING(urLat, FORMAT='(F10.6)') + '°, 经度 ' + STRING(urLon, FORMAT='(F10.6)') + '°'
      ENDIF
    IF (llLat NE 0.0) OR (llLon NE 0.0) THEN BEGIN
      PRINT, '    左下角: 纬度 ' + STRING(llLat, FORMAT='(F10.6)') + '°, 经度 ' + STRING(llLon, FORMAT='(F10.6)') + '°'
    ENDIF
    IF (lrLat NE 0.0) OR (lrLon NE 0.0) THEN BEGIN
      PRINT, '    右下角: 纬度 ' + STRING(lrLat, FORMAT='(F10.6)') + '°, 经度 ' + STRING(lrLon, FORMAT='(F10.6)') + '°'
    ENDIF
    
    ; 计算影像覆盖的地理范围
    IF (urLat NE 0.0) AND (urLon NE 0.0) AND (llLat NE 0.0) AND (llLon NE 0.0) THEN BEGIN
      latMin = MIN([ulLat, urLat, llLat, lrLat])
      latMax = MAX([ulLat, urLat, llLat, lrLat])
      lonMin = MIN([ulLon, urLon, llLon, lrLon])
      lonMax = MAX([ulLon, urLon, llLon, lrLon])
      latSpan = latMax - latMin
      lonSpan = lonMax - lonMin
      PRINT, '  影像覆盖范围:'
      PRINT, '    纬度范围: ' + STRING(latMin, FORMAT='(F10.6)') + '° 至 ' + STRING(latMax, FORMAT='(F10.6)') + '° (跨度: ' + STRING(latSpan, FORMAT='(F10.6)') + '°)'
      PRINT, '    经度范围: ' + STRING(lonMin, FORMAT='(F10.6)') + '° 至 ' + STRING(lonMax, FORMAT='(F10.6)') + '° (跨度: ' + STRING(lonSpan, FORMAT='(F10.6)') + '°)'
    ENDIF
  ENDIF
  
  ; 创建MAP_INFO
  ; 优先使用投影坐标（UTM），因为这样可以进行精确的像元级对齐
  ; 如果投影坐标不可用或失败，可以使用地理坐标（经纬度）
  PRINT, '  正在创建MAP_INFO结构体（优先使用UTM投影坐标）...'
  
  ; 方法1：尝试使用UTM投影坐标（推荐，精确对齐）
  mapInfo = !NULL
  useGeographic = 0
  CATCH, errMapInfo
  IF errMapInfo EQ 0 THEN BEGIN
    ; 尝试创建MAP_INFO（使用UTM投影坐标）
    mapInfo = ENVI_MAP_INFO_CREATE( $
      /UTM, $
      ZONE=utmZone, $
      /NORTH, $
      DATUM=datum, $
      MC=[0.0, 0.0, ulX, ulY], $  ; Map coordinates of pixel (0,0) - 使用投影坐标
      PS=[pixelSize, pixelSize] $  ; Pixel size in meters
    )
    CATCH, /CANCEL
    ; 验证mapInfo是否创建成功
    IF mapInfo EQ !NULL THEN BEGIN
      useGeographic = 1  ; 标记需要使用地理坐标
      PRINT, '  警告: UTM投影坐标创建失败，将尝试使用地理坐标（经纬度）'
    ENDIF ELSE BEGIN
      ; 检查结构体是否有元素
      nElements = N_ELEMENTS(mapInfo)
      IF nElements EQ 0 THEN BEGIN
        useGeographic = 1  ; 标记需要使用地理坐标
        PRINT, '  警告: UTM投影坐标创建失败（空结构体），将尝试使用地理坐标（经纬度）'
      ENDIF ELSE BEGIN
        PRINT, '  ✓ 使用UTM投影坐标创建MAP_INFO成功 (N_ELEMENTS=' + STRING(nElements) + ')' 
        PRINT, '    左上角投影坐标: (' + STRING(ulX, FORMAT='(F12.2)') + ', ' + STRING(ulY, FORMAT='(F12.2)') + ') 米'
        IF (ulLat NE 0.0) AND (ulLon NE 0.0) THEN BEGIN
          PRINT, '    对应地理坐标: 纬度 ' + STRING(ulLat, FORMAT='(F10.6)') + '°, 经度 ' + STRING(ulLon, FORMAT='(F10.6)') + '°'
        ENDIF
      ENDELSE
    ENDELSE
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    useGeographic = 1  ; 标记需要使用地理坐标
    PRINT, '  警告: UTM投影坐标创建异常: ' + !ERROR_STATE.MSG
    PRINT, '  将尝试使用地理坐标（经纬度）'
  ENDELSE
  
  ; 方法2：如果UTM投影失败，使用地理坐标（经纬度）
  IF useGeographic THEN BEGIN
    IF (ulLat NE 0.0) AND (ulLon NE 0.0) THEN BEGIN
      PRINT, '  正在使用地理坐标（经纬度）创建MAP_INFO...'
      ; 计算像元大小（度）
      ; 使用四个角坐标计算像元大小
      lonPixelSize = 0.0
      latPixelSize = 0.0
      
      ; 计算经度方向像元大小（使用左上角和右上角）
      IF (urLat NE 0.0) AND (urLon NE 0.0) THEN BEGIN
        lonSpan = ABS(urLon - ulLon)
        lonPixelSize = lonSpan / FLOAT(nColumns)
      ENDIF ELSE BEGIN
        ; 如果无法从右上角计算，使用默认值（约30米对应的度数）
        ; 在中等纬度（约25度），1度经度约等于111320 * cos(25°) ≈ 100900米
        lonPixelSize = pixelSize / (111320.0 * COS(!DTOR * ulLat))  ; 转换为度
      ENDELSE
      
      ; 计算纬度方向像元大小（使用左上角和左下角）
      IF (llLat NE 0.0) AND (llLon NE 0.0) THEN BEGIN
        latSpan = ABS(ulLat - llLat)
        latPixelSize = latSpan / FLOAT(nRows)
      ENDIF ELSE BEGIN
        ; 如果无法从左下角计算，使用默认值（约30米对应的度数）
        ; 1度纬度约等于111320米
        latPixelSize = pixelSize / 111320.0  ; 转换为度
      ENDELSE
      
      ; 如果计算出的像元大小为0，使用默认值
      IF lonPixelSize EQ 0.0 THEN lonPixelSize = pixelSize / 111320.0
      IF latPixelSize EQ 0.0 THEN latPixelSize = pixelSize / 111320.0
      
      PRINT, '    参数: 地理坐标系, DATUM=' + datum
      PRINT, '    左上角地理坐标: 纬度 ' + STRING(ulLat, FORMAT='(F10.6)') + '°, 经度 ' + STRING(ulLon, FORMAT='(F10.6)') + '°'
      PRINT, '    像元大小: 经度方向 ' + STRING(lonPixelSize, FORMAT='(F10.8)') + '°, 纬度方向 ' + STRING(latPixelSize, FORMAT='(F10.8)') + '°'
      
      CATCH, errGeoMapInfo
      IF errGeoMapInfo EQ 0 THEN BEGIN
        ; 创建地理坐标系MAP_INFO
        mapInfo = ENVI_MAP_INFO_CREATE( $
          /GEOGRAPHIC, $  ; 使用地理坐标系统（经纬度）
          DATUM=datum, $
          MC=[0.0, 0.0, ulLon, ulLat], $  ; Map coordinates of pixel (0,0) - 使用经纬度坐标
          PS=[lonPixelSize, latPixelSize] $  ; Pixel size in degrees
        )
        CATCH, /CANCEL
        ; 验证mapInfo是否创建成功
        IF mapInfo EQ !NULL THEN BEGIN
          PRINT, '  错误: 使用地理坐标创建MAP_INFO失败'
      RETURN, !NULL
    ENDIF
    ; 检查结构体是否有元素
    nElements = N_ELEMENTS(mapInfo)
    IF nElements EQ 0 THEN BEGIN
          PRINT, '  错误: 使用地理坐标创建MAP_INFO返回空结构体'
      RETURN, !NULL
    ENDIF
        PRINT, '  ✓ 使用地理坐标（经纬度）创建MAP_INFO成功 (N_ELEMENTS=' + STRING(nElements) + ')'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
        PRINT, '  错误: 使用地理坐标创建MAP_INFO时发生异常'
    PRINT, '  错误信息: ' + !ERROR_STATE.MSG
    PRINT, '  错误代码: ' + STRING(!ERROR_STATE.CODE)
    RETURN, !NULL
  ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '  错误: 无法获取经纬度坐标，无法创建MAP_INFO'
      RETURN, !NULL
    ENDELSE
  ENDIF
  
  RETURN, mapInfo
END

; 辅助函数：为raster设置空间参考
FUNCTION set_spatial_ref_to_raster, inputRaster, mapInfo
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  ; 保存原始raster的波长信息
  hasWavelength = 0
  wavelength = !NULL
  wavelengthUnits = 'Micrometers'
  fwhm = !NULL
  bandNames = !NULL
  IF inputRaster.METADATA.HasTag('wavelength') THEN BEGIN
    wavelength = inputRaster.METADATA['wavelength']
    hasWavelength = 1
    PRINT, '  检测到原始raster有波长信息，将保留'
  ENDIF ELSE BEGIN
    nBands = inputRaster.NBANDS
    PRINT, '  未检测到波长信息，波段数: ' + STRING(nBands)
    IF nBands GE 7 THEN BEGIN
      wavelength_7bands = [0.443, 0.4826, 0.5613, 0.6546, 0.8646, 1.609, 2.201]
      fwhm_7bands = [0.016, 0.0601, 0.0574, 0.0375, 0.0282, 0.0847, 0.1867]
      bandNames_7bands = ['Coastal aerosol', 'Blue', 'Green', 'Red', 'Near Infrared (NIR)', 'SWIR 1', 'SWIR 2']
      
      IF nBands EQ 7 THEN BEGIN
        wavelength = wavelength_7bands
        fwhm = fwhm_7bands
        bandNames = bandNames_7bands
        hasWavelength = 1
        PRINT, '  将使用Landsat 9标准7个反射波段波长值'
      ENDIF ELSE IF nBands EQ 8 THEN BEGIN
        wavelength = [wavelength_7bands, 2.201]
        fwhm = [fwhm_7bands, 0.1867]
        bandNames = [bandNames_7bands, 'QA']
        hasWavelength = 1
        PRINT, '  将使用Landsat 9标准7个反射波段波长值，第8个波段（QA）使用占位波长值'
      ENDIF ELSE BEGIN
        IF nBands GT 8 THEN BEGIN
          wavelength = wavelength_7bands
          fwhm = fwhm_7bands
          bandNames = bandNames_7bands
          FOR i=7, nBands-1 DO BEGIN
            wavelength = [wavelength, 2.201]
            fwhm = [fwhm, 0.1867]
            bandNames = [bandNames, 'Band ' + STRING(i+1)]
          ENDFOR
          hasWavelength = 1
          PRINT, '  将使用Landsat 9标准7个反射波段波长值，其余波段使用占位波长值'
        ENDIF
      ENDELSE
    ENDIF ELSE BEGIN
      IF nBands EQ 5 THEN BEGIN
        ; 5个波段：Blue, Green, Red, NIR, SWIR1
        wavelength = [0.4826, 0.5613, 0.6546, 0.8646, 1.609]  ; 微米
        fwhm = [0.0601, 0.0574, 0.0375, 0.0282, 0.0847]  ; 对应的FWHM
        bandNames = ['Blue', 'Green', 'Red', 'Near Infrared (NIR)', 'SWIR 1']
        hasWavelength = 1
        PRINT, '  将使用5个波段的标准波长值'
      ENDIF ELSE IF nBands EQ 4 THEN BEGIN
        wavelength = [0.4826, 0.5613, 0.6546, 0.8646]
        fwhm = [0.0601, 0.0574, 0.0375, 0.0282]
        bandNames = ['Blue', 'Green', 'Red', 'Near Infrared (NIR)']
        hasWavelength = 1
        PRINT, '  将使用4个波段的标准波长值'
      ENDIF ELSE IF nBands EQ 3 THEN BEGIN
        wavelength = [0.4826, 0.5613, 0.6546]
        fwhm = [0.0601, 0.0574, 0.0375]
        bandNames = ['Blue', 'Green', 'Red']
        hasWavelength = 1
        PRINT, '  将使用3个波段的标准波长值'
      ENDIF ELSE IF nBands EQ 1 THEN BEGIN
        ; 单个波段文件（如单个TIF文件），不需要设置波长信息
        ; 波长信息将在堆叠后设置
        hasWavelength = 0
        PRINT, '  单个波段文件，不设置波长信息（将在堆叠后设置）'
      ENDIF
    ENDELSE
  ENDELSE
  
  IF inputRaster.METADATA.HasTag('wavelength units') THEN BEGIN
    wavelengthUnits = STRING(inputRaster.METADATA['wavelength units'])
  ENDIF
  IF inputRaster.METADATA.HasTag('fwhm') THEN BEGIN
    fwhm = inputRaster.METADATA['fwhm']
  ENDIF
  IF inputRaster.METADATA.HasTag('band names') THEN BEGIN
    bandNames = inputRaster.METADATA['band names']
  ENDIF
  
  ; 导出raster到临时文件
  PRINT, '  正在导出raster到临时文件...'
  IF ~OBJ_VALID(inputRaster) THEN BEGIN
    PRINT, '  错误: inputRaster对象无效，无法导出'
    RETURN, !NULL
  ENDIF
  
  tempDirLocal = 'E:\1027IDL\ENVITaskTrainning\Temp'
  IF ~FILE_TEST(tempDirLocal, /DIRECTORY) THEN BEGIN
    CATCH, errMkTempDir
    IF errMkTempDir EQ 0 THEN BEGIN
      FILE_MKDIR, tempDirLocal
      CATCH, /CANCEL
      ; 验证目录是否创建成功
      IF ~FILE_TEST(tempDirLocal, /DIRECTORY) THEN BEGIN
        PRINT, '  错误: 无法创建临时目录: ' + tempDirLocal
        RETURN, !NULL
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 创建临时目录失败: ' + tempDirLocal + ' - ' + !ERROR_STATE.MSG
      RETURN, !NULL
    ENDELSE
  ENDIF
  tempBaseName = 'temp_raster_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
  tempFile = tempDirLocal + PATH_SEP() + tempBaseName
  
  IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
  hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
  IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  
  PRINT, '  临时文件路径: ' + tempFile
  CATCH, errExport
  IF errExport EQ 0 THEN BEGIN
    inputRaster.Export, tempFile, 'ENVI'
    WAIT, 0.5
    IF FILE_TEST(tempFile) THEN BEGIN
      PRINT, '  ✓ Raster已导出到: ' + FILE_BASENAME(tempFile)
    ENDIF ELSE BEGIN
      PRINT, '  警告: 直接导出后文件不存在，尝试使用ENVI的GetTemporaryFilename方法...'
      ; 尝试使用ENVI的临时文件方法（参考test1110_finalndvi.pro）
      tempFile = e.GetTemporaryFilename('dat')
      CATCH, errExportTask
      IF errExportTask EQ 0 THEN BEGIN
        inputRaster.Export, tempFile, 'ENVI'
        WAIT, 0.5
        IF FILE_TEST(tempFile) THEN BEGIN
          PRINT, '  ✓ 使用ENVI临时文件方法成功: ' + FILE_BASENAME(tempFile)
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '  错误: 使用ENVI临时文件方法也失败'
          RETURN, !NULL
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  错误: 所有导出方法都失败'
        RETURN, !NULL
      ENDELSE
    ENDELSE
    CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      errorMsg = '导出raster失败: ' + !ERROR_STATE.MSG + ' (Code: ' + STRING(!ERROR_STATE.CODE) + ')'
      PRINT, '  错误: ' + errorMsg
      PRINT, '  尝试使用ENVI的GetTemporaryFilename方法...'
      ; 如果直接导出失败，尝试使用ENVI的临时文件方法（参考test1110_finalndvi.pro）
      tempFile = e.GetTemporaryFilename('dat')
      CATCH, errExport2
      IF errExport2 EQ 0 THEN BEGIN
        inputRaster.Export, tempFile, 'ENVI'
        WAIT, 0.5
        IF FILE_TEST(tempFile) THEN BEGIN
          PRINT, '  ✓ 使用ENVI临时文件方法成功: ' + FILE_BASENAME(tempFile)
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '  错误: 使用ENVI临时文件方法也失败'
          RETURN, !NULL
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  错误: 所有导出方法都失败'
        RETURN, !NULL
      ENDELSE
    ENDELSE
  
  ; 使用ENVI_SETUP_HEAD设置空间参考
  PRINT, '  正在设置空间参考信息到文件头...'
  CATCH, errSetup
  IF errSetup EQ 0 THEN BEGIN
    ENVI_OPEN_FILE, tempFile, r_fid=fid
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
    PRINT, '  错误: 设置空间参考时发生错误: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  
  ; 重新打开raster
  PRINT, '  正在重新打开raster...'
  outputRaster = e.OpenRaster(tempFile)
  IF OBJ_VALID(outputRaster) THEN BEGIN
    PRINT, '  ✓ 成功重新打开raster'
    
    ; 如果原始raster有波长信息，或者我们设置了标准波长值，复制到新raster
    IF hasWavelength THEN BEGIN
      PRINT, '  正在设置波长信息到新raster...'
      IF outputRaster.METADATA.HasTag('wavelength') THEN BEGIN
        outputRaster.METADATA.UpdateItem, 'wavelength', wavelength
      ENDIF ELSE BEGIN
        outputRaster.METADATA.AddItem, 'wavelength', wavelength
      ENDELSE
      
      IF wavelengthUnits NE '' THEN BEGIN
        IF outputRaster.METADATA.HasTag('wavelength units') THEN BEGIN
          outputRaster.METADATA.UpdateItem, 'wavelength units', wavelengthUnits
        ENDIF ELSE BEGIN
          outputRaster.METADATA.AddItem, 'wavelength units', wavelengthUnits
        ENDELSE
      ENDIF
      
      IF fwhm NE !NULL THEN BEGIN
        IF outputRaster.METADATA.HasTag('fwhm') THEN BEGIN
          outputRaster.METADATA.UpdateItem, 'fwhm', fwhm
        ENDIF ELSE BEGIN
          outputRaster.METADATA.AddItem, 'fwhm', fwhm
        ENDELSE
      ENDIF
      
      IF bandNames NE !NULL THEN BEGIN
        IF outputRaster.METADATA.HasTag('band names') THEN BEGIN
          outputRaster.METADATA.UpdateItem, 'band names', bandNames
        ENDIF ELSE BEGIN
          outputRaster.METADATA.AddItem, 'band names', bandNames
        ENDELSE
      ENDIF
      
      outputRaster.WriteMetadata
      PRINT, '  ✓ 波长信息已设置到新raster'
    ENDIF
  ENDIF ELSE BEGIN
    PRINT, '  错误: 重新打开raster失败'
    RETURN, !NULL
  ENDELSE
  
  RETURN, outputRaster
END

; 辅助函数：为缺少空间参考的影像添加空间参考信息
; 参数：
;   raster: 需要添加空间参考的raster对象
;   dataPath: 原始数据路径（用于查找MTL XML文件）
;   rasterFile: raster文件路径（用于设置空间参考）
; 返回值：添加了空间参考的raster对象，如果失败返回原始raster
FUNCTION add_spatial_ref_to_raster_file, raster, dataPath, rasterFile
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  ; 检查raster是否有效
  IF ~OBJ_VALID(raster) THEN BEGIN
    PRINT, '  错误: raster对象无效'
    RETURN, !NULL
  ENDIF
  
  ; 检查是否已有空间参考信息
  spatialRef = !NULL
  CATCH, errCheckSR
  IF errCheckSR EQ 0 THEN BEGIN
    spatialRef = raster.SPATIALREF
    CATCH, /CANCEL
    IF OBJ_VALID(spatialRef) THEN BEGIN
      PRINT, '  ✓ 影像已有空间参考信息，无需添加'
      RETURN, raster
    ENDIF
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
  ENDELSE
  
  ; 如果没有空间参考信息，从MTL XML文件读取
  PRINT, '  检测到影像缺少空间参考信息，正在从MTL XML文件读取...'
  
  ; 查找MTL XML文件
  mtlXmlFiles = FILE_SEARCH(dataPath, '*_MTL.xml', COUNT=count)
  IF count EQ 0 THEN BEGIN
    PRINT, '  警告: 未找到MTL XML文件，无法添加空间参考信息'
    RETURN, raster
  ENDIF
  mtlXmlFile = mtlXmlFiles[0]
  PRINT, '  找到MTL XML文件: ' + FILE_BASENAME(mtlXmlFile)
  
  ; 从MTL XML文件创建空间参考信息
  mapInfo = create_spatial_ref_from_mtl_xml(mtlXmlFile, raster.NCOLUMNS, raster.NROWS)
  IF mapInfo EQ !NULL THEN BEGIN
    PRINT, '  错误: 无法从MTL XML文件创建空间参考信息'
    RETURN, raster
  ENDIF
  
  ; 关闭raster以便直接修改文件头
  PRINT, '  正在关闭raster对象...'
  raster.Close
  WAIT, 0.5
  
  ; 直接使用ENVI_SETUP_HEAD为文件添加空间参考信息
  PRINT, '  正在为文件添加空间参考信息...'
  CATCH, errSetup
  IF errSetup EQ 0 THEN BEGIN
    ; 打开文件获取文件信息
    ENVI_OPEN_FILE, rasterFile, r_fid=fid
    IF fid LT 0 THEN BEGIN
      PRINT, '  错误: 无法打开文件: ' + rasterFile
      ; 重新打开raster
      raster = e.OpenRaster(rasterFile)
      RETURN, raster
    ENDIF
    
    ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=nb, data_type=dt, interleave=interleave
    ENVI_SETUP_HEAD, $
      FNAME=rasterFile, $
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
    PRINT, '  错误: 设置空间参考时发生错误: ' + !ERROR_STATE.MSG
    ; 重新打开raster
    raster = e.OpenRaster(rasterFile)
    RETURN, raster
  ENDELSE
  
  ; 重新打开raster
  WAIT, 0.5
  rasterWithSR = e.OpenRaster(rasterFile)
  IF OBJ_VALID(rasterWithSR) THEN BEGIN
    ; 验证空间参考是否成功添加
    spatialRefNew = !NULL
    CATCH, errCheckSRNew
    IF errCheckSRNew EQ 0 THEN BEGIN
      spatialRefNew = rasterWithSR.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(spatialRefNew) THEN BEGIN
        PRINT, '  ✓ 空间参考信息已成功添加到文件'
        RETURN, rasterWithSR
      ENDIF ELSE BEGIN
        PRINT, '  警告: 空间参考信息添加后无效'
        RETURN, rasterWithSR
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 无法验证空间参考信息'
      RETURN, rasterWithSR
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '  错误: 重新打开文件失败'
    RETURN, !NULL
  ENDELSE
END

; 处理单一年份的数据
FUNCTION process_year_data, dataPath, year, outputDir
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  ; 查找MTL文件
  mtlFiles = FILE_SEARCH(dataPath, '*_MTL.txt', COUNT=count)
  IF count EQ 0 THEN BEGIN
    PRINT, '错误: 未找到' + year + '年MTL文件: ' + dataPath
    RETURN, !NULL
  ENDIF
  mtlFile = mtlFiles[0]
  
  PRINT, '========== 处理' + year + '年数据 =========='
  PRINT, 'MTL文件: ' + mtlFile
  
  ; 打开数据
  PRINT, '正在打开' + year + '年数据...'
  raster = !NULL
  spatialRef = !NULL
  
  ; 方法1：使用DATASET_NAME参数
  CATCH, err1
  IF err1 EQ 0 THEN BEGIN
    tempRaster = e.OpenRaster(mtlFile, DATASET_NAME='Surface Reflectance')
    CATCH, /CANCEL
    IF tempRaster NE !NULL THEN BEGIN
      IF N_ELEMENTS(tempRaster) GT 1 THEN BEGIN
        raster = tempRaster[0]
      ENDIF ELSE IF N_ELEMENTS(tempRaster) EQ 1 THEN BEGIN
        raster = tempRaster
      ENDIF
    ENDIF
    IF OBJ_VALID(raster) THEN BEGIN
      nBands = raster.NBANDS
      PRINT, '✓ 使用方法1（DATASET_NAME）成功打开数据，' + STRING(nBands) + ' 个波段'
      ; 安全地获取空间参考信息
      CATCH, errSpatialRef1
      IF errSpatialRef1 EQ 0 THEN BEGIN
        spatialRef = raster.SPATIALREF
        CATCH, /CANCEL
        IF OBJ_VALID(spatialRef) THEN BEGIN
          PRINT, '  ✓ 空间参考信息完整'
        ENDIF ELSE BEGIN
          spatialRef = !NULL
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        spatialRef = !NULL
      ENDELSE
    ENDIF
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '方法1失败: ' + !ERROR_STATE.MSG
  ENDELSE
  
  ; 方法2：使用ExtractRasterFromFileTask
  IF ~OBJ_VALID(raster) THEN BEGIN
    PRINT, '方法1失败，尝试方法2：使用ExtractRasterFromFileTask...'
    CATCH, err2
    IF err2 EQ 0 THEN BEGIN
      extractTask = ENVITask('ExtractRasterFromFile')
      extractTask.INPUT_URI = mtlFile
      extractTask.DATASET_NAME = 'Surface Reflectance'
      extractTask.Execute
      tempRaster = extractTask.OUTPUT_RASTER
      CATCH, /CANCEL
      IF tempRaster NE !NULL THEN BEGIN
        IF N_ELEMENTS(tempRaster) GT 1 THEN BEGIN
          raster = tempRaster[0]
        ENDIF ELSE BEGIN
          raster = tempRaster
        ENDELSE
      ENDIF
      IF OBJ_VALID(raster) THEN BEGIN
        nBands = raster.NBANDS
        PRINT, '✓ 使用方法2（ExtractRasterFromFileTask）成功打开数据，' + STRING(nBands) + ' 个波段'
        ; 安全地获取空间参考信息
        CATCH, errSpatialRef2
        IF errSpatialRef2 EQ 0 THEN BEGIN
        spatialRef = raster.SPATIALREF
          CATCH, /CANCEL
        IF OBJ_VALID(spatialRef) THEN BEGIN
            PRINT, '  ✓ 空间参考信息完整'
          ENDIF ELSE BEGIN
            spatialRef = !NULL
          ENDELSE
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          spatialRef = !NULL
        ENDELSE
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '方法2失败: ' + !ERROR_STATE.MSG
    ENDELSE
  ENDIF
  
  ; 方法3：使用默认方式打开，并查找Surface Reflectance数据集
  IF ~OBJ_VALID(raster) THEN BEGIN
    PRINT, '方法2失败，尝试方法3：使用默认方式打开MTL文件...'
    CATCH, err3
    IF err3 EQ 0 THEN BEGIN
      rasters = e.OpenRaster(mtlFile)
      CATCH, /CANCEL
      IF (rasters NE !NULL) AND (N_ELEMENTS(rasters) GT 0) THEN BEGIN
        ; 遍历所有raster，查找Surface Reflectance数据集（通常有7个波段）
        PRINT, '  找到 ' + STRING(N_ELEMENTS(rasters)) + ' 个数据集，正在查找Surface Reflectance...'
        foundSurfaceReflectance = 0
        FOR i=0, N_ELEMENTS(rasters)-1 DO BEGIN
          tempRaster = rasters[i]
          IF OBJ_VALID(tempRaster) THEN BEGIN
            nBands = tempRaster.NBANDS
            PRINT, '    数据集 ' + STRING(i+1) + ': ' + STRING(nBands) + ' 个波段'
            ; Surface Reflectance通常有7个波段（B1-B7）
            ; 也检查是否有5个或更多波段（可能是部分波段）
            IF nBands GE 5 THEN BEGIN
              raster = tempRaster
              foundSurfaceReflectance = 1
              PRINT, '    ✓ 找到Surface Reflectance数据集（' + STRING(nBands) + ' 个波段）'
              BREAK
            ENDIF
          ENDIF
        ENDFOR
        
        ; 如果没有找到7个波段的，使用第一个raster
        IF ~foundSurfaceReflectance THEN BEGIN
        raster = rasters[0]
          PRINT, '  警告: 未找到完整的Surface Reflectance数据集，使用第一个数据集（' + STRING(raster.NBANDS) + ' 个波段）'
        ENDIF
        
        IF OBJ_VALID(raster) THEN BEGIN
          ; 安全地获取空间参考信息
          CATCH, errSpatialRef
          IF errSpatialRef EQ 0 THEN BEGIN
          spatialRef = raster.SPATIALREF
            CATCH, /CANCEL
          IF OBJ_VALID(spatialRef) THEN BEGIN
            PRINT, '✓ 使用方法3（默认方式）成功打开数据，空间参考信息完整'
            ENDIF ELSE BEGIN
              spatialRef = !NULL
            ENDELSE
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            spatialRef = !NULL
          ENDELSE
          ENDIF
        ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
      ENDIF
  
  ; 方法4：如果raster没有空间参考，尝试从MTL XML添加空间参考（参考test1110_finalndvi.pro）
  ; 注意：即使只有4个波段，也先尝试为整个raster添加空间参考，然后继续处理
  IF OBJ_VALID(raster) AND ~OBJ_VALID(spatialRef) THEN BEGIN
    PRINT, '检测到raster没有空间参考信息，正在从MTL XML文件读取并添加空间参考...'
    ; 查找MTL XML文件
    mtlXmlFile = FILE_DIRNAME(mtlFile) + PATH_SEP() + FILE_BASENAME(mtlFile, '.txt') + '.xml'
    IF FILE_TEST(mtlXmlFile) THEN BEGIN
      PRINT, '找到MTL XML文件: ' + FILE_BASENAME(mtlXmlFile)
      mapInfo = create_spatial_ref_from_mtl_xml(mtlXmlFile, raster.NCOLUMNS, raster.NROWS)
      IF mapInfo NE !NULL THEN BEGIN
        nElements = N_ELEMENTS(mapInfo)
        IF nElements GT 0 THEN BEGIN
          PRINT, '✓ 成功从MTL XML文件创建空间参考信息 (N_ELEMENTS=' + STRING(nElements) + ')'
          ; 为整个raster设置空间参考（参考test1110_finalndvi.pro）
          rasterWithSR = set_spatial_ref_to_raster(raster, mapInfo)
          IF OBJ_VALID(rasterWithSR) THEN BEGIN
            ; 关闭原始raster，使用新的raster
            raster.Close
            raster = rasterWithSR
            CATCH, errCheckSRAfter
            IF errCheckSRAfter EQ 0 THEN BEGIN
              spatialRef = raster.SPATIALREF
              CATCH, /CANCEL
              IF OBJ_VALID(spatialRef) THEN BEGIN
                PRINT, '✓ 成功为raster设置空间参考信息'
              ENDIF ELSE BEGIN
                PRINT, '警告: 设置空间参考后spatialRef无效，将继续处理'
                spatialRef = !NULL
              ENDELSE
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
              spatialRef = !NULL
            ENDELSE
          ENDIF ELSE BEGIN
            PRINT, '警告: 设置空间参考失败，将使用原始raster继续处理（无空间参考）'
            ; 保留原始raster，继续处理
            spatialRef = !NULL
          ENDELSE
        ENDIF ELSE BEGIN
          PRINT, '错误: 无法从MTL XML文件创建空间参考信息 (N_ELEMENTS=' + STRING(nElements) + ')'
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '错误: create_spatial_ref_from_mtl_xml返回!NULL'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '警告: 未找到MTL XML文件: ' + mtlXmlFile
    ENDELSE
  ENDIF
  
  ; 方法5：如果仍然只有4个或更少波段，尝试直接打开Surface Reflectance TIF文件
  ; 不堆叠全部波段，而是只堆叠需要的波段（B1, B2, B3, B4, B5）
  IF OBJ_VALID(raster) AND (raster.NBANDS LT 5) THEN BEGIN
    PRINT, '当前raster只有' + STRING(raster.NBANDS) + '个波段，尝试方法5：直接打开Surface Reflectance TIF文件（B1-B5）...'
    ; 查找Surface Reflectance TIF文件（SR_B1到SR_B7）
    ; 我们需要：B1(Blue), B2(Green), B3(Red), B4(NIR), B5(SWIR1) 至少5个波段
    srB1File = FILE_SEARCH(dataPath, '*_SR_B1.TIF', COUNT=countB1)
    srB2File = FILE_SEARCH(dataPath, '*_SR_B2.TIF', COUNT=countB2)
    srB3File = FILE_SEARCH(dataPath, '*_SR_B3.TIF', COUNT=countB3)
    srB4File = FILE_SEARCH(dataPath, '*_SR_B4.TIF', COUNT=countB4)
    srB5File = FILE_SEARCH(dataPath, '*_SR_B5.TIF', COUNT=countB5)
    
    IF (countB1 GT 0) AND (countB2 GT 0) AND (countB3 GT 0) AND (countB4 GT 0) AND (countB5 GT 0) THEN BEGIN
      PRINT, '  找到所需的Surface Reflectance TIF文件（B1-B5）'
      ; 只打开需要的波段：B1, B2, B3, B4, B5
      srFiles = [srB1File[0], srB2File[0], srB3File[0], srB4File[0], srB5File[0]]
      countSR = 5
      
      PRINT, '  正在打开需要的TIF文件（B1-B5）...'
      ; 使用BuildLayerStackTask堆叠需要的波段
      CATCH, err4
      IF err4 EQ 0 THEN BEGIN
        ; 创建raster数组
        srRasters = OBJARR(countSR)
        allValid = 1
        FOR i=0, countSR-1 DO BEGIN
          bandNum = i + 1
          PRINT, '    打开文件 ' + STRING(i+1) + '/' + STRING(countSR) + ': ' + FILE_BASENAME(srFiles[i])
          CATCH, errOpenSR
          IF errOpenSR EQ 0 THEN BEGIN
            srRasters[i] = e.OpenRaster(srFiles[i])
            CATCH, /CANCEL
            IF ~OBJ_VALID(srRasters[i]) THEN BEGIN
              PRINT, '      错误: 无法打开文件: ' + srFiles[i]
              allValid = 0
            ENDIF ELSE BEGIN
              ; 检查是否有空间参考信息
              CATCH, errCheckSR
              IF errCheckSR EQ 0 THEN BEGIN
                tempSR = srRasters[i].SPATIALREF
                CATCH, /CANCEL
                IF OBJ_VALID(tempSR) THEN BEGIN
                  PRINT, '      ✓ 成功打开B' + STRING(bandNum) + '，尺寸: ' + STRING(srRasters[i].NCOLUMNS) + ' x ' + STRING(srRasters[i].NROWS) + '，有空间参考'
                ENDIF ELSE BEGIN
                  PRINT, '      ✓ 成功打开B' + STRING(bandNum) + '，尺寸: ' + STRING(srRasters[i].NCOLUMNS) + ' x ' + STRING(srRasters[i].NROWS) + '，无空间参考'
                  ; 如果TIF文件没有空间参考，尝试从MTL XML添加
                  ; 注意：单个TIF文件可能已经有空间参考（从GeoTIFF头），如果没有，我们稍后再添加
                ENDELSE
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
                PRINT, '      ✓ 成功打开B' + STRING(bandNum) + '，尺寸: ' + STRING(srRasters[i].NCOLUMNS) + ' x ' + STRING(srRasters[i].NROWS)
              ENDELSE
            ENDELSE
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '      错误: 打开文件失败: ' + srFiles[i] + ' - ' + !ERROR_STATE.MSG
            allValid = 0
          ENDELSE
        ENDFOR
        
        IF allValid THEN BEGIN
          ; 检查是否有TIF文件缺少空间参考信息
          ; 如果有，需要先为它们添加空间参考（从MTL XML读取）
          PRINT, '  检查TIF文件的空间参考信息...'
          needAddSpatialRef = 0
          FOR i=0, countSR-1 DO BEGIN
            IF OBJ_VALID(srRasters[i]) THEN BEGIN
              CATCH, errCheckSR3
              IF errCheckSR3 EQ 0 THEN BEGIN
                tempSR = srRasters[i].SPATIALREF
                CATCH, /CANCEL
                IF ~OBJ_VALID(tempSR) THEN BEGIN
                  needAddSpatialRef = 1
                  BREAK
                ENDIF
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
                needAddSpatialRef = 1
                BREAK
              ENDELSE
            ENDIF
          ENDFOR
          
          ; 如果有TIF文件缺少空间参考，先为它们添加空间参考
          IF needAddSpatialRef THEN BEGIN
            PRINT, '  检测到部分TIF文件缺少空间参考信息，正在从MTL XML文件读取并添加...'
            ; 查找MTL XML文件
            mtlXmlFile = FILE_SEARCH(dataPath, '*_MTL.xml', COUNT=countXml)
            IF countXml GT 0 THEN BEGIN
              mtlXmlFile = mtlXmlFile[0]
              PRINT, '  找到MTL XML文件: ' + FILE_BASENAME(mtlXmlFile)
              ; 从MTL XML创建空间参考信息（使用第一个raster的尺寸）
              mapInfo = create_spatial_ref_from_mtl_xml(mtlXmlFile, srRasters[0].NCOLUMNS, srRasters[0].NROWS)
              IF mapInfo NE !NULL THEN BEGIN
                PRINT, '  ✓ 成功从MTL XML创建空间参考信息'
                ; 为每个没有空间参考的TIF文件添加空间参考
                ; 参考ex.pro的方法：导出为ENVI格式，然后使用ENVI_SETUP_HEAD添加MAP_INFO
                tempDirLocal = 'E:\1027IDL\ENVITaskTrainning\Temp'
                IF ~FILE_TEST(tempDirLocal, /DIRECTORY) THEN BEGIN
                  FILE_MKDIR, tempDirLocal
                ENDIF
                
                ; 为每个TIF文件添加空间参考
                ; 方法：使用set_spatial_ref_to_raster函数（参考test1110_finalndvi.pro）
                ; 该函数会：导出到临时文件 → 设置空间参考 → 重新打开并保留波长信息
                FOR i=0, countSR-1 DO BEGIN
                  IF OBJ_VALID(srRasters[i]) THEN BEGIN
                    CATCH, errCheckSR4
                    IF errCheckSR4 EQ 0 THEN BEGIN
                      tempSR = srRasters[i].SPATIALREF
                      CATCH, /CANCEL
                      IF ~OBJ_VALID(tempSR) THEN BEGIN
                        PRINT, '    正在为B' + STRING(i+1) + '添加空间参考（使用set_spatial_ref_to_raster函数）...'
                        ; 使用set_spatial_ref_to_raster函数添加空间参考
                        CATCH, errSetSR
                        IF errSetSR EQ 0 THEN BEGIN
                          rasterWithSR = set_spatial_ref_to_raster(srRasters[i], mapInfo)
                          CATCH, /CANCEL
                          
                          IF OBJ_VALID(rasterWithSR) THEN BEGIN
                            ; 关闭原始raster，使用新的raster
                            srRasters[i].Close
                            srRasters[i] = rasterWithSR
                            ; 验证空间参考
                            CATCH, errCheckSR5
                            IF errCheckSR5 EQ 0 THEN BEGIN
                              tempSR2 = srRasters[i].SPATIALREF
                              CATCH, /CANCEL
                              IF OBJ_VALID(tempSR2) THEN BEGIN
                                PRINT, '      ✓ B' + STRING(i+1) + '空间参考已添加'
                              ENDIF ELSE BEGIN
                                PRINT, '      警告: B' + STRING(i+1) + '空间参考添加后验证失败'
                              ENDELSE
                            ENDIF ELSE BEGIN
                              CATCH, /CANCEL
                            ENDELSE
                          ENDIF ELSE BEGIN
                            PRINT, '      警告: set_spatial_ref_to_raster返回的raster无效，B' + STRING(i+1) + '将保持无空间参考'
                          ENDELSE
                        ENDIF ELSE BEGIN
                          CATCH, /CANCEL
                          PRINT, '      警告: set_spatial_ref_to_raster执行失败: ' + !ERROR_STATE.MSG
                          PRINT, '      B' + STRING(i+1) + '将保持无空间参考，将尝试直接堆叠（如果所有TIF尺寸相同）'
                        ENDELSE
                      ENDIF
                    ENDIF ELSE BEGIN
                      CATCH, /CANCEL
                    ENDELSE
                  ENDIF
                ENDFOR
                PRINT, '  ✓ 空间参考信息添加完成'
              ENDIF ELSE BEGIN
                PRINT, '  警告: 无法从MTL XML创建空间参考信息，将尝试直接堆叠'
              ENDELSE
            ENDIF ELSE BEGIN
              PRINT, '  警告: 未找到MTL XML文件，无法添加空间参考信息'
            ENDELSE
          ENDIF
          
          PRINT, '  所有TIF文件已打开，尝试使用ENVILayerStackRaster函数堆叠（B1-B5）...'
          PRINT, '  注意: 参考test1110_finalndvi.pro，使用ENVILayerStackRaster函数而不是BuildLayerStack任务'
          
          ; 初始化stackedRaster变量
          stackedRaster = !NULL
          
          ; 方法4a：尝试使用ENVILayerStackRaster函数（参考用户提供的代码）
          ; 这个函数使用grid_definition参数，需要至少一个raster有空间参考
          CATCH, errLayerStack
          IF errLayerStack EQ 0 THEN BEGIN
            ; 首先从第一个有空间参考的raster创建grid_definition
            gridDefRaster = !NULL
            FOR i=0, countSR-1 DO BEGIN
              IF OBJ_VALID(srRasters[i]) THEN BEGIN
                CATCH, errCheckGridSR
                IF errCheckGridSR EQ 0 THEN BEGIN
                  tempSR = srRasters[i].SPATIALREF
                  CATCH, /CANCEL
                  IF OBJ_VALID(tempSR) THEN BEGIN
                    gridDefRaster = srRasters[i]
                    PRINT, '  使用B' + STRING(i+1) + '创建grid_definition（有空间参考）'
                    BREAK
                  ENDIF
                ENDIF ELSE BEGIN
                  CATCH, /CANCEL
                ENDELSE
              ENDIF
            ENDFOR
            
            ; 如果所有raster都没有空间参考，使用第一个raster（但会失败）
            IF ~OBJ_VALID(gridDefRaster) THEN BEGIN
              IF OBJ_VALID(srRasters[0]) THEN BEGIN
                gridDefRaster = srRasters[0]
                PRINT, '  警告: 所有TIF文件都没有空间参考，尝试使用B1创建grid_definition（可能会失败）'
              ENDIF
            ENDIF
            
            IF OBJ_VALID(gridDefRaster) THEN BEGIN
              ; 创建grid_definition
              PRINT, '  正在创建grid_definition...'
              CATCH, errGridDef
              IF errGridDef EQ 0 THEN BEGIN
                gridTask = ENVITask('BuildGridDefinitionFromRaster')
                gridTask.INPUT_RASTER = gridDefRaster
                gridTask.Execute
                gridDef = gridTask.OUTPUT_GRIDDEFINITION
                CATCH, /CANCEL
                
                IF gridDef NE !NULL THEN BEGIN
                  PRINT, '  ✓ grid_definition创建成功'
                  ; 使用ENVILayerStackRaster函数堆叠所有波段
                  PRINT, '  正在使用ENVILayerStackRaster函数堆叠波段...'
                  CATCH, errLayerStack2
                  IF errLayerStack2 EQ 0 THEN BEGIN
                    stackedRaster = ENVILayerStackRaster(srRasters, grid_definition=gridDef)
                    CATCH, /CANCEL
                    
                    IF OBJ_VALID(stackedRaster) THEN BEGIN
                      nBandsStacked = stackedRaster.NBANDS
                      PRINT, '  ✓ 使用ENVILayerStackRaster堆叠成功，堆叠后的raster有 ' + STRING(nBandsStacked) + ' 个波段'
                      ; 关闭之前的raster和单个TIF raster
                      IF OBJ_VALID(raster) THEN BEGIN
                        oldNBands = raster.NBANDS
                        raster.Close
                        PRINT, '  已关闭之前的raster（' + STRING(oldNBands) + ' 个波段）'
                      ENDIF
                      ; 关闭单个TIF raster以释放内存
                      FOR i=0, countSR-1 DO BEGIN
                        IF OBJ_VALID(srRasters[i]) THEN srRasters[i].Close
                      ENDFOR
                      raster = stackedRaster
                      PRINT, '  ✓ 使用方法4（ENVILayerStackRaster）成功打开Surface Reflectance数据，' + STRING(raster.NBANDS) + ' 个波段'
                      ; 尝试获取空间参考
                      CATCH, errSpatialRef4
                      IF errSpatialRef4 EQ 0 THEN BEGIN
                        spatialRef = raster.SPATIALREF
                        CATCH, /CANCEL
                        IF OBJ_VALID(spatialRef) THEN BEGIN
                          PRINT, '  ✓ 空间参考信息完整'
                        ENDIF ELSE BEGIN
                          spatialRef = !NULL
                          PRINT, '  警告: 堆叠后的raster没有空间参考信息，将在后续步骤中添加'
                        ENDELSE
                      ENDIF ELSE BEGIN
                        CATCH, /CANCEL
                        spatialRef = !NULL
                      ENDELSE
                    ENDIF ELSE BEGIN
                      PRINT, '  错误: ENVILayerStackRaster返回的raster无效'
                      CATCH, /CANCEL
                    ENDELSE
                  ENDIF ELSE BEGIN
                    CATCH, /CANCEL
                    PRINT, '  错误: ENVILayerStackRaster执行失败: ' + !ERROR_STATE.MSG
                  ENDELSE
                ENDIF ELSE BEGIN
                  PRINT, '  错误: 无法创建grid_definition'
                ENDELSE
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
                PRINT, '  错误: BuildGridDefinitionFromRaster执行失败: ' + !ERROR_STATE.MSG
              ENDELSE
            ENDIF ELSE BEGIN
              PRINT, '  错误: 无法找到有效的raster来创建grid_definition'
            ENDELSE
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '  错误: ENVILayerStackRaster初始化失败: ' + !ERROR_STATE.MSG
          ENDELSE
          
          ; 如果ENVILayerStackRaster失败，尝试使用BuildLayerStack任务（保留原有逻辑作为备用）
          IF ~OBJ_VALID(stackedRaster) THEN BEGIN
            PRINT, '  ENVILayerStackRaster失败，尝试使用BuildLayerStack任务...'
            ; 检查所有raster是否都有空间参考信息
            hasSpatialRef = 1
            FOR i=0, countSR-1 DO BEGIN
              IF OBJ_VALID(srRasters[i]) THEN BEGIN
                CATCH, errCheckSR2
                IF errCheckSR2 EQ 0 THEN BEGIN
                  tempSR = srRasters[i].SPATIALREF
                  CATCH, /CANCEL
                  IF ~OBJ_VALID(tempSR) THEN BEGIN
                    hasSpatialRef = 0
                    PRINT, '    警告: B' + STRING(i+1) + '没有空间参考信息'
                  ENDIF
                ENDIF ELSE BEGIN
                  CATCH, /CANCEL
                  hasSpatialRef = 0
                ENDELSE
              ENDIF
            ENDFOR
            
            IF hasSpatialRef THEN BEGIN
              PRINT, '  所有TIF文件都有空间参考信息，使用BuildLayerStack任务堆叠（B1-B5）...'
              CATCH, errStack
              IF errStack EQ 0 THEN BEGIN
                stackTask = ENVITask('BuildLayerStack')
                stackTask.INPUT_RASTERS = srRasters
                stackTask.Execute
                stackedRaster = stackTask.OUTPUT_RASTER
                CATCH, /CANCEL
                
                IF OBJ_VALID(stackedRaster) THEN BEGIN
                  nBandsStacked = stackedRaster.NBANDS
                  PRINT, '  ✓ BuildLayerStack堆叠成功，堆叠后的raster有 ' + STRING(nBandsStacked) + ' 个波段'
                  ; 关闭之前的raster和单个TIF raster
                  IF OBJ_VALID(raster) THEN BEGIN
                    oldNBands = raster.NBANDS
                    raster.Close
                    PRINT, '  已关闭之前的raster（' + STRING(oldNBands) + ' 个波段）'
                  ENDIF
                  ; 关闭单个TIF raster以释放内存
                  FOR i=0, countSR-1 DO BEGIN
                    IF OBJ_VALID(srRasters[i]) THEN srRasters[i].Close
                  ENDFOR
                  raster = stackedRaster
                  PRINT, '  ✓ 使用方法4（BuildLayerStack）成功打开Surface Reflectance数据，' + STRING(raster.NBANDS) + ' 个波段'
                  ; 尝试获取空间参考
                  CATCH, errSpatialRef4
                  IF errSpatialRef4 EQ 0 THEN BEGIN
                    spatialRef = raster.SPATIALREF
                    CATCH, /CANCEL
                    IF OBJ_VALID(spatialRef) THEN BEGIN
                      PRINT, '  ✓ 空间参考信息完整'
                    ENDIF ELSE BEGIN
                      spatialRef = !NULL
                      PRINT, '  警告: 堆叠后的raster没有空间参考信息，将在后续步骤中添加'
                    ENDELSE
                  ENDIF ELSE BEGIN
                    CATCH, /CANCEL
                    spatialRef = !NULL
                  ENDELSE
                ENDIF ELSE BEGIN
                  PRINT, '  错误: BuildLayerStack返回的raster无效'
                ENDELSE
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
                PRINT, '  错误: BuildLayerStack执行失败: ' + !ERROR_STATE.MSG
              ENDELSE
            ENDIF ELSE BEGIN
              ; 即使没有空间参考，如果所有TIF文件尺寸相同，也尝试直接堆叠
              PRINT, '  警告: 部分TIF文件缺少空间参考信息'
              ; 检查所有TIF文件尺寸是否相同
              allSameSize = 1
              refCols = srRasters[0].NCOLUMNS
              refRows = srRasters[0].NROWS
              FOR i=1, countSR-1 DO BEGIN
                IF OBJ_VALID(srRasters[i]) THEN BEGIN
                  IF (srRasters[i].NCOLUMNS NE refCols) OR (srRasters[i].NROWS NE refRows) THEN BEGIN
                    allSameSize = 0
                    BREAK
                  ENDIF
                ENDIF
              ENDFOR
              
              IF allSameSize THEN BEGIN
                PRINT, '  所有TIF文件尺寸相同（' + STRING(refCols) + ' x ' + STRING(refRows) + '），尝试直接使用BuildLayerStack堆叠（即使没有空间参考）...'
                CATCH, errStackNoSR
                IF errStackNoSR EQ 0 THEN BEGIN
                  stackTask = ENVITask('BuildLayerStack')
                  stackTask.INPUT_RASTERS = srRasters
                  stackTask.Execute
                  stackedRaster = stackTask.OUTPUT_RASTER
                  CATCH, /CANCEL
                  
                  IF OBJ_VALID(stackedRaster) THEN BEGIN
                    nBandsStacked = stackedRaster.NBANDS
                    PRINT, '  ✓ BuildLayerStack堆叠成功（无空间参考），堆叠后的raster有 ' + STRING(nBandsStacked) + ' 个波段'
                    ; 关闭之前的raster和单个TIF raster
                    IF OBJ_VALID(raster) THEN BEGIN
                      oldNBands = raster.NBANDS
                      raster.Close
                      PRINT, '  已关闭之前的raster（' + STRING(oldNBands) + ' 个波段）'
                    ENDIF
                    ; 关闭单个TIF raster以释放内存
                    FOR i=0, countSR-1 DO BEGIN
                      IF OBJ_VALID(srRasters[i]) THEN srRasters[i].Close
                    ENDFOR
                    raster = stackedRaster
                    PRINT, '  ✓ 使用方法4（BuildLayerStack，无空间参考）成功打开Surface Reflectance数据，' + STRING(raster.NBANDS) + ' 个波段'
                    PRINT, '  注意: 堆叠后的raster没有空间参考信息，将在后续步骤中添加'
                    spatialRef = !NULL
                  ENDIF ELSE BEGIN
                    PRINT, '  错误: BuildLayerStack返回的raster无效（即使尺寸相同）'
                  ENDELSE
                ENDIF ELSE BEGIN
                  CATCH, /CANCEL
                  PRINT, '  错误: BuildLayerStack执行失败（即使尺寸相同）: ' + !ERROR_STATE.MSG
                  PRINT, '  当前将使用之前打开的raster（' + STRING(raster.NBANDS) + '个波段）继续处理'
                  ; 关闭单个TIF raster
                  FOR i=0, countSR-1 DO BEGIN
                    IF OBJ_VALID(srRasters[i]) THEN srRasters[i].Close
                  ENDFOR
                ENDELSE
              ENDIF ELSE BEGIN
                PRINT, '  错误: TIF文件尺寸不一致，无法堆叠'
                PRINT, '  当前将使用之前打开的raster（' + STRING(raster.NBANDS) + '个波段）继续处理'
                ; 关闭单个TIF raster
                FOR i=0, countSR-1 DO BEGIN
                  IF OBJ_VALID(srRasters[i]) THEN srRasters[i].Close
                ENDFOR
              ENDELSE
            ENDELSE
          ENDIF
        ENDIF ELSE BEGIN
          PRINT, '  错误: 部分TIF文件打开失败，无法堆叠'
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  错误: 方法4初始化失败: ' + !ERROR_STATE.MSG
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '  警告: 未找到完整的Surface Reflectance TIF文件（需要B1-B5）'
      IF countB1 EQ 0 THEN PRINT, '    缺少: B1 (Blue)'
      IF countB2 EQ 0 THEN PRINT, '    缺少: B2 (Green)'
      IF countB3 EQ 0 THEN PRINT, '    缺少: B3 (Red)'
      IF countB4 EQ 0 THEN PRINT, '    缺少: B4 (NIR)'
      IF countB5 EQ 0 THEN PRINT, '    缺少: B5 (SWIR1)'
    ENDELSE
  ENDIF
  
  ; 检查是否成功打开数据
  IF ~OBJ_VALID(raster) THEN BEGIN
    PRINT, '错误: 无法打开' + year + '年数据'
    RETURN, !NULL
  ENDIF
  
  PRINT, '✓ 成功打开' + year + '年数据'
  PRINT, '  影像尺寸: ' + STRING(raster.NCOLUMNS) + ' x ' + STRING(raster.NROWS)
  PRINT, '  波段数: ' + STRING(raster.NBANDS)
  
  ; 验证影像尺寸（如果MTL XML文件可用）
  mtlXmlFile = FILE_DIRNAME(mtlFile) + PATH_SEP() + FILE_BASENAME(mtlFile, '.txt') + '.xml'
  IF FILE_TEST(mtlXmlFile) THEN BEGIN
    ; 从XML读取期望的影像尺寸
    CATCH, errCheckSize
    IF errCheckSize EQ 0 THEN BEGIN
      ; 简单读取XML文件检查尺寸
      OPENR, lun, mtlXmlFile, /GET_LUN
      xmlContent = ''
      WHILE ~EOF(lun) DO BEGIN
        READF, lun, line
        xmlContent = xmlContent + line
      ENDWHILE
      CLOSE, lun
      FREE_LUN, lun
      
      ; 查找REFLECTIVE_LINES
      lineTagPos = STRPOS(STRUPCASE(xmlContent), '<REFLECTIVE_LINES>')
      IF lineTagPos GE 0 THEN BEGIN
        lineStart = lineTagPos + 18
        lineEnd = STRPOS(STRUPCASE(xmlContent), '</REFLECTIVE_LINES>')
        IF lineEnd GT lineStart THEN BEGIN
          expectedLinesStr = STRMID(xmlContent, lineStart, lineEnd - lineStart)
          expectedLines = FIX(STRTRIM(expectedLinesStr, 2))
        ENDIF
      ENDIF
      
      ; 查找REFLECTIVE_SAMPLES
      sampleTagPos = STRPOS(STRUPCASE(xmlContent), '<REFLECTIVE_SAMPLES>')
      IF sampleTagPos GE 0 THEN BEGIN
        sampleStart = sampleTagPos + 20
        sampleEnd = STRPOS(STRUPCASE(xmlContent), '</REFLECTIVE_SAMPLES>')
        IF sampleEnd GT sampleStart THEN BEGIN
          expectedSamplesStr = STRMID(xmlContent, sampleStart, sampleEnd - sampleStart)
          expectedSamples = FIX(STRTRIM(expectedSamplesStr, 2))
        ENDIF
      ENDIF
      
      ; 验证尺寸
      IF (expectedLines GT 0) AND (expectedSamples GT 0) THEN BEGIN
        IF (raster.NROWS NE expectedLines) OR (raster.NCOLUMNS NE expectedSamples) THEN BEGIN
          PRINT, '  警告: 影像尺寸与XML文件中的定义不一致'
          PRINT, '    XML定义: ' + STRING(expectedLines) + ' 行 x ' + STRING(expectedSamples) + ' 列'
          PRINT, '    实际尺寸: ' + STRING(raster.NROWS) + ' 行 x ' + STRING(raster.NCOLUMNS) + ' 列'
        ENDIF ELSE BEGIN
          PRINT, '  ✓ 影像尺寸验证通过: ' + STRING(raster.NROWS) + ' 行 x ' + STRING(raster.NCOLUMNS) + ' 列'
        ENDELSE
      ENDIF
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  
  ; 检查空间参考
  IF ~OBJ_VALID(spatialRef) THEN BEGIN
    PRINT, '警告: 从MTL文件打开的数据没有空间参考信息'
    PRINT, '  注意: 光谱指数计算不强制需要空间参考信息，将继续处理'
    PRINT, '  如果输出的光谱指数文件需要空间参考，可以在ENVI中手动添加'
    PRINT, '  或者使用ENVI的RasterSpatialRef任务在后续处理中添加'
  ENDIF ELSE BEGIN
    PRINT, '✓ 空间参考信息: ' + STRUPCASE(STRMID(spatialRef.COORD_SYS_STR, 0, 60))
  ENDELSE
  
  ; 检查并设置波长信息（光谱指数计算需要）
  PRINT, '正在检查波长信息...'
  hasWavelength = 0
  IF raster.METADATA.HasTag('wavelength') THEN BEGIN
    wavelength = raster.METADATA['wavelength']
    IF (N_ELEMENTS(wavelength) GE raster.NBANDS) AND (MIN(wavelength) GT 0) THEN BEGIN
      hasWavelength = 1
      PRINT, '✓ 检测到波长信息: ' + STRING(N_ELEMENTS(wavelength)) + ' 个波段'
    ENDIF
  ENDIF
  
  IF hasWavelength EQ 0 THEN BEGIN
    PRINT, '警告: raster缺少波长信息，正在设置Landsat 9标准波长值...'
    nBands = raster.NBANDS
    wavelength = !NULL
    fwhm = !NULL
    bandNames = !NULL
    
    IF nBands GE 7 THEN BEGIN
      ; Landsat 9标准7个反射波段波长值（微米）
      wavelength = [0.443, 0.4826, 0.5613, 0.6546, 0.8646, 1.609, 2.201]
      fwhm = [0.016, 0.0601, 0.0574, 0.0375, 0.0282, 0.0847, 0.1867]
      bandNames = ['Coastal aerosol', 'Blue', 'Green', 'Red', 'Near Infrared (NIR)', 'SWIR 1', 'SWIR 2']
      
      IF nBands GT 7 THEN BEGIN
        ; 如果有更多波段，使用占位值
        FOR i=7, nBands-1 DO BEGIN
          wavelength = [wavelength, 2.201]
          fwhm = [fwhm, 0.1867]
          bandNames = [bandNames, 'Band ' + STRING(i+1)]
        ENDFOR
      ENDIF
    ENDIF ELSE IF nBands EQ 4 THEN BEGIN
      ; 4个波段（Blue, Green, Red, NIR）
      wavelength = [0.4826, 0.5613, 0.6546, 0.8646]
      fwhm = [0.0601, 0.0574, 0.0375, 0.0282]
      bandNames = ['Blue', 'Green', 'Red', 'Near Infrared (NIR)']
    ENDIF ELSE IF nBands EQ 3 THEN BEGIN
      ; 3个波段（Blue, Green, Red）
      wavelength = [0.4826, 0.5613, 0.6546]
      fwhm = [0.0601, 0.0574, 0.0375]
      bandNames = ['Blue', 'Green', 'Red']
    ENDIF
    
    IF wavelength NE !NULL THEN BEGIN
      ; 尝试设置波长信息到raster元数据
      CATCH, errSetWavelength
      IF errSetWavelength EQ 0 THEN BEGIN
        IF raster.METADATA.HasTag('wavelength') THEN BEGIN
          raster.METADATA.UpdateItem, 'wavelength', wavelength
        ENDIF ELSE BEGIN
          raster.METADATA.AddItem, 'wavelength', wavelength
        ENDELSE
        
        IF raster.METADATA.HasTag('wavelength units') THEN BEGIN
          raster.METADATA.UpdateItem, 'wavelength units', 'Micrometers'
        ENDIF ELSE BEGIN
          raster.METADATA.AddItem, 'wavelength units', 'Micrometers'
        ENDELSE
        
        IF fwhm NE !NULL THEN BEGIN
          IF raster.METADATA.HasTag('fwhm') THEN BEGIN
            raster.METADATA.UpdateItem, 'fwhm', fwhm
          ENDIF ELSE BEGIN
            raster.METADATA.AddItem, 'fwhm', fwhm
          ENDELSE
        ENDIF
        
        IF bandNames NE !NULL THEN BEGIN
          IF raster.METADATA.HasTag('band names') THEN BEGIN
            raster.METADATA.UpdateItem, 'band names', bandNames
          ENDIF ELSE BEGIN
            raster.METADATA.AddItem, 'band names', bandNames
          ENDELSE
        ENDIF
        
        raster.WriteMetadata
        PRINT, '✓ 已设置Landsat 9标准波长信息'
        hasWavelength = 1
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  警告: 无法设置波长信息到raster元数据: ' + !ERROR_STATE.MSG
        PRINT, '  将尝试使用PixelwiseBandMath手动计算光谱指数'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '  错误: 无法确定波段配置，无法设置波长信息'
    ENDELSE
  ENDIF
  
  ; 计算光谱指数
  ; 注意：由于ENVISpectralIndexRaster在当前环境下失败并破坏ENVI环境，
  ; 我们直接使用PixelwiseBandMathRaster进行手动计算
  
  ; 计算NDVI
  PRINT, '正在计算NDVI...'
  ; 使用手动计算：NDVI = (NIR - Red) / (NIR + Red)
  ; 首先检查波段数量，确定正确的波段索引
  nBands = raster.NBANDS
  PRINT, '  检测到波段数: ' + STRING(nBands)
  
  ; 根据波段数量确定波段索引
  ; Landsat 9 Surface Reflectance通常有7个波段：B1(Blue), B2(Green), B3(Red), B4(NIR), B5(SWIR1), B6(SWIR2), B7(其他)
  ; 但有时可能只有部分波段，需要根据实际波段数调整
  ; 波段索引从0开始：b1=索引0, b2=索引1, b3=索引2, b4=索引3, b5=索引4, b6=索引5
  
  ; 确定Red和NIR的索引
  redIndex = -1
  nirIndex = -1
  greenIndex = -1
  swir1Index = -1
  
  IF nBands GE 4 THEN BEGIN
    ; 如果有4个或更多波段，假设是：B1(Blue), B2(Green), B3(Red), B4(NIR)
    redIndex = 2  ; B3 = 索引2
    nirIndex = 3  ; B4 = 索引3
    greenIndex = 1  ; B2 = 索引1
    IF nBands GE 5 THEN BEGIN
      swir1Index = 4  ; B5 = 索引4
    ENDIF
    IF nBands GE 6 THEN BEGIN
      ; 如果有6个或更多波段，B6可能是SWIR2
    ENDIF
    ENDIF ELSE BEGIN
    PRINT, '  错误: 波段数不足，无法计算光谱指数（需要至少4个波段）'
    RETURN, ''
    ENDELSE
  
  ; 根据实际波段索引构建表达式
  ; PixelwiseBandMathRaster使用b1, b2, b3...表示波段（索引从1开始，不是0）
  ; 所以b1=第一个波段（索引0），b2=第二个波段（索引1），以此类推
  ndvi = !NULL
  IF OBJ_VALID(raster) AND (redIndex GE 0) AND (nirIndex GE 0) THEN BEGIN
    ; 重新获取ENVI实例，确保环境正常
    e = ENVI(/CURRENT)
    IF OBJ_VALID(e) THEN BEGIN
      ; 使用波段编号（从1开始）：b1, b2, b3, b4...
      ; redIndex=2对应b3, nirIndex=3对应b4
      redBand = redIndex + 1  ; 转换为波段编号（从1开始）
      nirBand = nirIndex + 1
      ; 使用STRTRIM去除前导空格，确保表达式格式正确
      redBandStr = STRTRIM(STRING(redBand), 2)
      nirBandStr = STRTRIM(STRING(nirBand), 2)
      ndviExpr = '(b' + nirBandStr + ' - b' + redBandStr + ') / (b' + nirBandStr + ' + b' + redBandStr + ')'
      PRINT, '  使用波段: Red=' + redBandStr + ', NIR=' + nirBandStr
      PRINT, '  NDVI表达式: ' + ndviExpr
    CATCH, errNDVI
    IF errNDVI EQ 0 THEN BEGIN
        ndviTask = ENVITask('PixelwiseBandMathRaster')
        IF OBJ_VALID(ndviTask) THEN BEGIN
          ndviTask.INPUT_RASTER = raster
        ndviTask.EXPRESSION = ndviExpr
        ndviTask.Execute
        ndvi = ndviTask.OUTPUT_RASTER
          CATCH, /CANCEL
        IF OBJ_VALID(ndvi) THEN BEGIN
            PRINT, '✓ NDVI计算完成'
        ENDIF ELSE BEGIN
          PRINT, '错误: NDVI计算失败'
        ENDELSE
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '错误: NDVI任务对象创建失败'
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
        PRINT, '错误: NDVI计算任务创建失败: ' + !ERROR_STATE.MSG
      ENDELSE
      ENDIF ELSE BEGIN
      PRINT, '错误: ENVI实例无效，无法计算NDVI'
      ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '错误: raster对象无效，无法计算NDVI'
  ENDELSE
  
  ; 计算NDWI
  PRINT, '正在计算NDWI...'
    ; 使用MNDWI (Modified NDWI) = (Green - SWIR1) / (Green + SWIR1)
  ndwi = !NULL
  IF OBJ_VALID(raster) AND (greenIndex GE 0) THEN BEGIN
    ; 重新获取ENVI实例，确保环境正常
    e = ENVI(/CURRENT)
    IF OBJ_VALID(e) THEN BEGIN
      ; 确定SWIR1索引
      IF swir1Index LT 0 THEN BEGIN
        ; 如果没有SWIR1，尝试使用NIR作为替代（不理想，但可以计算）
        IF nirIndex GE 0 THEN BEGIN
          swir1Index = nirIndex
          PRINT, '  警告: 未找到SWIR1波段，将使用NIR波段作为替代（NDWI计算结果可能不准确）'
    ENDIF ELSE BEGIN
          PRINT, '  错误: 无法找到SWIR1或NIR波段，无法计算NDWI'
          ndwi = !NULL
    ENDELSE
      ENDIF
      
      IF swir1Index GE 0 THEN BEGIN
        greenBand = greenIndex + 1  ; 转换为波段编号（从1开始）
        swir1Band = swir1Index + 1
        ; 使用STRTRIM去除前导空格，确保表达式格式正确
        greenBandStr = STRTRIM(STRING(greenBand), 2)
        swir1BandStr = STRTRIM(STRING(swir1Band), 2)
        ndwiExpr = '(b' + greenBandStr + ' - b' + swir1BandStr + ') / (b' + greenBandStr + ' + b' + swir1BandStr + ')'
        PRINT, '  使用波段: Green=' + greenBandStr + ', SWIR1=' + swir1BandStr
        PRINT, '  NDWI表达式: ' + ndwiExpr
    CATCH, errNDWI
    IF errNDWI EQ 0 THEN BEGIN
        ndwiTask = ENVITask('PixelwiseBandMathRaster')
          IF OBJ_VALID(ndwiTask) THEN BEGIN
            ndwiTask.INPUT_RASTER = raster
        ndwiTask.EXPRESSION = ndwiExpr
        ndwiTask.Execute
        ndwi = ndwiTask.OUTPUT_RASTER
            CATCH, /CANCEL
        IF OBJ_VALID(ndwi) THEN BEGIN
              PRINT, '✓ NDWI计算完成（使用MNDWI公式）'
        ENDIF ELSE BEGIN
          PRINT, '错误: NDWI计算失败'
        ENDELSE
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '错误: NDWI任务对象创建失败'
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
          PRINT, '错误: NDWI计算任务创建失败: ' + !ERROR_STATE.MSG
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  错误: SWIR1索引无效，无法计算NDWI'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '  错误: ENVI实例无效，无法计算NDWI'
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '错误: raster对象无效，无法计算NDWI'
  ENDELSE
  
  ; 计算NDBI
  PRINT, '正在计算NDBI...'
  ; 使用手动计算：NDBI = (SWIR1 - NIR) / (SWIR1 + NIR)
  ndbi = !NULL
  IF OBJ_VALID(raster) AND (nirIndex GE 0) THEN BEGIN
    ; 重新获取ENVI实例，确保环境正常
    e = ENVI(/CURRENT)
    IF OBJ_VALID(e) THEN BEGIN
      ; 确定SWIR1索引
      IF swir1Index LT 0 THEN BEGIN
        ; 如果没有SWIR1，尝试使用Red作为替代（不理想，但可以计算）
        IF redIndex GE 0 THEN BEGIN
          swir1Index = redIndex
          PRINT, '  警告: 未找到SWIR1波段，将使用Red波段作为替代（NDBI计算结果可能不准确）'
    ENDIF ELSE BEGIN
          PRINT, '  错误: 无法找到SWIR1或Red波段，无法计算NDBI'
          ndbi = !NULL
    ENDELSE
      ENDIF
      
      IF swir1Index GE 0 THEN BEGIN
        swir1Band = swir1Index + 1  ; 转换为波段编号（从1开始）
        nirBand = nirIndex + 1
        ; 使用STRTRIM去除前导空格，确保表达式格式正确
        swir1BandStr = STRTRIM(STRING(swir1Band), 2)
        nirBandStr = STRTRIM(STRING(nirBand), 2)
        ; 检查SWIR1和NIR是否相同，如果相同则无法计算NDBI
        IF swir1Band EQ nirBand THEN BEGIN
          PRINT, '  错误: SWIR1和NIR波段相同，无法计算NDBI'
          PRINT, '    提示: 需要5个或更多波段才能正确计算NDBI（需要SWIR1和NIR是不同的波段）'
          ndbi = !NULL
  ENDIF ELSE BEGIN
          ndbiExpr = '(b' + swir1BandStr + ' - b' + nirBandStr + ') / (b' + swir1BandStr + ' + b' + nirBandStr + ')'
          PRINT, '  使用波段: SWIR1=' + swir1BandStr + ', NIR=' + nirBandStr
          PRINT, '  NDBI表达式: ' + ndbiExpr
    CATCH, errNDBI
    IF errNDBI EQ 0 THEN BEGIN
        ndbiTask = ENVITask('PixelwiseBandMathRaster')
            IF OBJ_VALID(ndbiTask) THEN BEGIN
              ndbiTask.INPUT_RASTER = raster
        ndbiTask.EXPRESSION = ndbiExpr
        ndbiTask.Execute
        ndbi = ndbiTask.OUTPUT_RASTER
              CATCH, /CANCEL
        IF OBJ_VALID(ndbi) THEN BEGIN
                PRINT, '✓ NDBI计算完成'
        ENDIF ELSE BEGIN
          PRINT, '错误: NDBI计算失败'
        ENDELSE
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
              PRINT, '错误: NDBI任务对象创建失败'
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
            PRINT, '错误: NDBI计算任务创建失败: ' + !ERROR_STATE.MSG
          ENDELSE
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  错误: SWIR1索引无效，无法计算NDBI'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '  错误: ENVI实例无效，无法计算NDBI'
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '错误: raster对象无效，无法计算NDBI'
  ENDELSE
  
  ; 检查计算结果
  IF (~OBJ_VALID(ndvi)) OR (~OBJ_VALID(ndwi)) OR (~OBJ_VALID(ndbi)) THEN BEGIN
    PRINT, '错误: 部分光谱指数计算失败'
    IF ~OBJ_VALID(ndvi) THEN PRINT, '  - NDVI计算失败'
    IF ~OBJ_VALID(ndwi) THEN PRINT, '  - NDWI计算失败'
    IF ~OBJ_VALID(ndbi) THEN PRINT, '  - NDBI计算失败'
    ; 返回空字符串而不是!NULL，避免主程序中的STRLEN错误
    RETURN, ''
  ENDIF
  
  ; 保存结果
  PRINT, '正在保存结果...'
  
  ; 保存NDVI
  outputNDVI = outputDir + PATH_SEP() + 'ndvi_' + year + '.dat'
  IF FILE_TEST(outputNDVI) THEN BEGIN
    FILE_DELETE, outputNDVI, /QUIET
    hdrFile = FILE_DIRNAME(outputNDVI) + PATH_SEP() + FILE_BASENAME(outputNDVI, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  ENDIF
  CATCH, errNDVI
  IF errNDVI EQ 0 THEN BEGIN
    IF OBJ_VALID(ndvi) THEN BEGIN
      ndvi.Export, outputNDVI, 'ENVI'
      WAIT, 0.5
      IF FILE_TEST(outputNDVI) THEN BEGIN
        PRINT, '✓ NDVI已保存: ' + FILE_BASENAME(outputNDVI)
      ENDIF ELSE BEGIN
        PRINT, '警告: NDVI文件导出后不存在，尝试使用ENVITask导出...'
        ; 尝试使用ENVITask导出
        exportTask = ENVITask('RasterExport')
        exportTask.INPUT_RASTER = ndvi
        exportTask.OUTPUT_RASTER_URI = outputNDVI
        exportTask.Execute
        WAIT, 1.0
        IF FILE_TEST(outputNDVI) THEN BEGIN
          PRINT, '✓ NDVI已保存（使用ENVITask）: ' + FILE_BASENAME(outputNDVI)
        ENDIF ELSE BEGIN
          PRINT, '错误: NDVI导出失败'
        ENDELSE
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: NDVI对象无效，无法导出'
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '错误: NDVI导出失败: ' + !ERROR_STATE.MSG
  ENDELSE
  
  ; 保存NDWI
  outputNDWI = outputDir + PATH_SEP() + 'ndwi_' + year + '.dat'
  IF FILE_TEST(outputNDWI) THEN BEGIN
    FILE_DELETE, outputNDWI, /QUIET
    hdrFile = FILE_DIRNAME(outputNDWI) + PATH_SEP() + FILE_BASENAME(outputNDWI, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  ENDIF
  CATCH, errNDWI
  IF errNDWI EQ 0 THEN BEGIN
    IF OBJ_VALID(ndwi) THEN BEGIN
      ndwi.Export, outputNDWI, 'ENVI'
      WAIT, 0.5
      IF FILE_TEST(outputNDWI) THEN BEGIN
        PRINT, '✓ NDWI已保存: ' + FILE_BASENAME(outputNDWI)
      ENDIF ELSE BEGIN
        PRINT, '警告: NDWI文件导出后不存在，尝试使用ENVITask导出...'
        exportTask = ENVITask('RasterExport')
        exportTask.INPUT_RASTER = ndwi
        exportTask.OUTPUT_RASTER_URI = outputNDWI
        exportTask.Execute
        WAIT, 1.0
        IF FILE_TEST(outputNDWI) THEN BEGIN
          PRINT, '✓ NDWI已保存（使用ENVITask）: ' + FILE_BASENAME(outputNDWI)
        ENDIF ELSE BEGIN
          PRINT, '错误: NDWI导出失败'
        ENDELSE
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: NDWI对象无效，无法导出'
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '错误: NDWI导出失败: ' + !ERROR_STATE.MSG
  ENDELSE
  
  ; 保存NDBI
  outputNDBI = outputDir + PATH_SEP() + 'ndbi_' + year + '.dat'
  IF FILE_TEST(outputNDBI) THEN BEGIN
    FILE_DELETE, outputNDBI, /QUIET
    hdrFile = FILE_DIRNAME(outputNDBI) + PATH_SEP() + FILE_BASENAME(outputNDBI, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  ENDIF
  CATCH, errNDBI
  IF errNDBI EQ 0 THEN BEGIN
    IF OBJ_VALID(ndbi) THEN BEGIN
      ndbi.Export, outputNDBI, 'ENVI'
      WAIT, 0.5
      IF FILE_TEST(outputNDBI) THEN BEGIN
        PRINT, '✓ NDBI已保存: ' + FILE_BASENAME(outputNDBI)
      ENDIF ELSE BEGIN
        PRINT, '警告: NDBI文件导出后不存在，尝试使用ENVITask导出...'
        exportTask = ENVITask('RasterExport')
        exportTask.INPUT_RASTER = ndbi
        exportTask.OUTPUT_RASTER_URI = outputNDBI
        exportTask.Execute
        WAIT, 1.0
        IF FILE_TEST(outputNDBI) THEN BEGIN
          PRINT, '✓ NDBI已保存（使用ENVITask）: ' + FILE_BASENAME(outputNDBI)
        ENDIF ELSE BEGIN
          PRINT, '错误: NDBI导出失败'
        ENDELSE
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: NDBI对象无效，无法导出'
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '错误: NDBI导出失败: ' + !ERROR_STATE.MSG
  ENDELSE
  
  ; 验证所有结果是否成功保存
  IF (~OBJ_VALID(raster)) OR (~OBJ_VALID(ndvi)) OR (~OBJ_VALID(ndwi)) OR (~OBJ_VALID(ndbi)) THEN BEGIN
    PRINT, '错误: 部分结果无效'
    IF ~OBJ_VALID(raster) THEN PRINT, '  - raster无效'
    IF ~OBJ_VALID(ndvi) THEN PRINT, '  - ndvi无效'
    IF ~OBJ_VALID(ndwi) THEN PRINT, '  - ndwi无效'
    IF ~OBJ_VALID(ndbi) THEN PRINT, '  - ndbi无效'
    RETURN, ''
  ENDIF
  
  ; 关闭对象以释放内存（文件已保存，在主程序中会重新打开进行对比）
  IF OBJ_VALID(raster) THEN raster.Close
  IF OBJ_VALID(ndvi) THEN ndvi.Close
  IF OBJ_VALID(ndwi) THEN ndwi.Close
  IF OBJ_VALID(ndbi) THEN ndbi.Close
  
  ; 返回保存的文件路径（用于后续对比分析）
  ; 返回格式：'ndvi_file|ndwi_file|ndbi_file'
  filePaths = outputNDVI + '|' + outputNDWI + '|' + outputNDBI
  
  RETURN, filePaths
END

PRO landsat9_spectral_indices
  COMPILE_OPT IDL2
  
  ; 启动ENVI
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()
  
  PRINT, '========================================='
  PRINT, 'Landsat 9 光谱指数计算'
  PRINT, '功能: 计算NDVI、NDWI、NDBI'
  PRINT, '========================================='
  PRINT, ''
  
  ; 设置数据路径
  dataPath2021 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1'
  dataPath2025 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20250827_20250828_02_T1'
  
  ; 设置输出目录
  outputDir = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1\results_fenkuaidaima'
  
  ; 创建输出目录（如果不存在）
  IF ~FILE_TEST(outputDir, /DIRECTORY) THEN BEGIN
    CATCH, errMkDir
    IF errMkDir EQ 0 THEN BEGIN
      FILE_MKDIR, outputDir
      CATCH, /CANCEL
      ; 验证目录是否创建成功
      IF ~FILE_TEST(outputDir, /DIRECTORY) THEN BEGIN
        PRINT, '错误: 无法创建输出目录: ' + outputDir
        RETURN
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '错误: 创建输出目录失败: ' + outputDir + ' - ' + !ERROR_STATE.MSG
      RETURN
    ENDELSE
  ENDIF
  
  PRINT, '输出目录: ' + outputDir
  PRINT, ''
  
  ; 处理2021年数据
  files2021 = process_year_data(dataPath2021, '2021', outputDir)
  IF STRLEN(files2021) EQ 0 THEN BEGIN
    PRINT, '错误: 2021年数据处理失败'
    RETURN
  ENDIF
  
  PRINT, ''
  
  ; 处理2025年数据
  files2025 = process_year_data(dataPath2025, '2025', outputDir)
  IF STRLEN(files2025) EQ 0 THEN BEGIN
    PRINT, '警告: 2025年数据处理失败，仅处理2021年数据'
  PRINT, ''
  PRINT, '========================================='
  PRINT, '✓✓✓ 处理完成！ ✓✓✓'
  PRINT, '========================================='
  PRINT, '输出目录: ' + outputDir
  PRINT, ''
    PRINT, '✓ 处理完成，所有结果已保存（仅2021年数据）'
    RETURN
  ENDIF
  
  PRINT, ''
  PRINT, '========================================='
  PRINT, '========== 开始对比分析 =========='
  PRINT, '========================================='
  PRINT, ''
  
  ; 解析文件路径
  files2021_array = STRSPLIT(files2021, '|', /EXTRACT)
  files2025_array = STRSPLIT(files2025, '|', /EXTRACT)
  
  IF (N_ELEMENTS(files2021_array) LT 3) OR (N_ELEMENTS(files2025_array) LT 3) THEN BEGIN
    PRINT, '错误: 文件路径解析失败'
    RETURN
  ENDIF
  
  ndvi2021_file = files2021_array[0]
  ndwi2021_file = files2021_array[1]
  ndbi2021_file = files2021_array[2]
  ndvi2025_file = files2025_array[0]
  ndwi2025_file = files2025_array[1]
  ndbi2025_file = files2025_array[2]
  
  ; 重新打开文件进行对比分析
  PRINT, '正在打开2021年和2025年的光谱指数文件...'
  ndvi2021 = e.OpenRaster(ndvi2021_file)
  ndwi2021 = e.OpenRaster(ndwi2021_file)
  ndbi2021 = e.OpenRaster(ndbi2021_file)
  ndvi2025 = e.OpenRaster(ndvi2025_file)
  ndwi2025 = e.OpenRaster(ndwi2025_file)
  ndbi2025 = e.OpenRaster(ndbi2025_file)
  
  ; 检查文件是否都成功打开
  IF ~OBJ_VALID(ndvi2021) OR ~OBJ_VALID(ndvi2025) THEN BEGIN
    PRINT, '错误: 无法打开NDVI文件进行对比分析'
  ENDIF ELSE BEGIN
    ; ============================================
    ; 为缺少空间参考的影像添加空间参考信息
    ; ============================================
    PRINT, ''
    PRINT, '========== 检查并添加空间参考信息 =========='
    PRINT, '正在检查2021年和2025年影像的空间参考信息...'
    
    ; 为2021年影像添加空间参考（如果需要）
    IF OBJ_VALID(ndvi2021) THEN BEGIN
      spatialRef2021 = !NULL
      CATCH, errSR2021
      IF errSR2021 EQ 0 THEN BEGIN
        spatialRef2021 = ndvi2021.SPATIALREF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      IF ~OBJ_VALID(spatialRef2021) THEN BEGIN
        PRINT, '  2021年NDVI影像缺少空间参考信息，正在添加...'
        ndvi2021_temp = add_spatial_ref_to_raster_file(ndvi2021, dataPath2021, ndvi2021_file)
        IF OBJ_VALID(ndvi2021_temp) THEN BEGIN
          ; 注意：add_spatial_ref_to_raster_file内部已经关闭了原始raster并重新打开
          ; 所以这里直接使用返回的新对象
          ndvi2021 = ndvi2021_temp
          PRINT, '  ✓ 2021年NDVI影像空间参考信息已添加'
  ENDIF
      ENDIF
    ENDIF
    
    IF OBJ_VALID(ndwi2021) THEN BEGIN
      spatialRefNDWI2021 = !NULL
      CATCH, errSRNDWI2021
      IF errSRNDWI2021 EQ 0 THEN BEGIN
        spatialRefNDWI2021 = ndwi2021.SPATIALREF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      IF ~OBJ_VALID(spatialRefNDWI2021) THEN BEGIN
        PRINT, '  2021年NDWI影像缺少空间参考信息，正在添加...'
        ndwi2021_temp = add_spatial_ref_to_raster_file(ndwi2021, dataPath2021, ndwi2021_file)
        IF OBJ_VALID(ndwi2021_temp) THEN BEGIN
          ndwi2021 = ndwi2021_temp
        ENDIF
      ENDIF
    ENDIF
    
    IF OBJ_VALID(ndbi2021) THEN BEGIN
      spatialRefNDBI2021 = !NULL
      CATCH, errSRNDBI2021
      IF errSRNDBI2021 EQ 0 THEN BEGIN
        spatialRefNDBI2021 = ndbi2021.SPATIALREF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      IF ~OBJ_VALID(spatialRefNDBI2021) THEN BEGIN
        PRINT, '  2021年NDBI影像缺少空间参考信息，正在添加...'
        ndbi2021_temp = add_spatial_ref_to_raster_file(ndbi2021, dataPath2021, ndbi2021_file)
        IF OBJ_VALID(ndbi2021_temp) THEN BEGIN
          ndbi2021 = ndbi2021_temp
        ENDIF
      ENDIF
    ENDIF
    
    ; 为2025年影像添加空间参考（如果需要）
    IF OBJ_VALID(ndvi2025) THEN BEGIN
      spatialRef2025 = !NULL
      CATCH, errSR2025
      IF errSR2025 EQ 0 THEN BEGIN
        spatialRef2025 = ndvi2025.SPATIALREF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      IF ~OBJ_VALID(spatialRef2025) THEN BEGIN
        PRINT, '  2025年NDVI影像缺少空间参考信息，正在添加...'
        ndvi2025_temp = add_spatial_ref_to_raster_file(ndvi2025, dataPath2025, ndvi2025_file)
        IF OBJ_VALID(ndvi2025_temp) THEN BEGIN
          ndvi2025 = ndvi2025_temp
          PRINT, '  ✓ 2025年NDVI影像空间参考信息已添加'
        ENDIF
      ENDIF
    ENDIF
    
    IF OBJ_VALID(ndwi2025) THEN BEGIN
      spatialRefNDWI2025 = !NULL
      CATCH, errSRNDWI2025
      IF errSRNDWI2025 EQ 0 THEN BEGIN
        spatialRefNDWI2025 = ndwi2025.SPATIALREF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      IF ~OBJ_VALID(spatialRefNDWI2025) THEN BEGIN
        PRINT, '  2025年NDWI影像缺少空间参考信息，正在添加...'
        ndwi2025_temp = add_spatial_ref_to_raster_file(ndwi2025, dataPath2025, ndwi2025_file)
        IF OBJ_VALID(ndwi2025_temp) THEN BEGIN
          ndwi2025 = ndwi2025_temp
        ENDIF
      ENDIF
    ENDIF
    
    IF OBJ_VALID(ndbi2025) THEN BEGIN
      spatialRefNDBI2025 = !NULL
      CATCH, errSRNDBI2025
      IF errSRNDBI2025 EQ 0 THEN BEGIN
        spatialRefNDBI2025 = ndbi2025.SPATIALREF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      IF ~OBJ_VALID(spatialRefNDBI2025) THEN BEGIN
        PRINT, '  2025年NDBI影像缺少空间参考信息，正在添加...'
        ndbi2025_temp = add_spatial_ref_to_raster_file(ndbi2025, dataPath2025, ndbi2025_file)
        IF OBJ_VALID(ndbi2025_temp) THEN BEGIN
          ndbi2025 = ndbi2025_temp
        ENDIF
      ENDIF
    ENDIF
    
    ; 重新检查空间参考信息
    PRINT, '重新检查空间参考信息...'
    spatialRef2021 = !NULL
    spatialRef2025 = !NULL
    CATCH, errSR2021
    IF errSR2021 EQ 0 THEN BEGIN
      spatialRef2021 = ndvi2021.SPATIALREF
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
    CATCH, errSR2025
    IF errSR2025 EQ 0 THEN BEGIN
      spatialRef2025 = ndvi2025.SPATIALREF
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
    
    IF OBJ_VALID(spatialRef2021) AND OBJ_VALID(spatialRef2025) THEN BEGIN
      PRINT, '✓ 所有影像都有空间参考信息，将按地理坐标对齐'
    ENDIF ELSE BEGIN
      PRINT, '警告: 部分影像仍然缺少空间参考信息，对齐可能不精确'
    ENDELSE
    PRINT, ''
    
    ; ============================================
    ; NDVI对比分析
    ; ============================================
    PRINT, '========== NDVI变化分析 =========='
    
    ; 始终使用ImageIntersection进行对齐，确保按地理坐标精确对齐
    ; 即使尺寸一致，也应该对齐，因为可能存在地理位置的微小偏移
    PRINT, '正在按地理坐标对齐影像（ImageIntersection会根据空间参考信息对齐）...'
    
    ; 检查尺寸是否一致（用于提示）
    IF (ndvi2021.NCOLUMNS NE ndvi2025.NCOLUMNS) OR (ndvi2021.NROWS NE ndvi2025.NROWS) THEN BEGIN
      PRINT, '  检测到: 两个时相的NDVI影像尺寸不一致'
      PRINT, '    2021年尺寸: ' + STRING(ndvi2021.NCOLUMNS) + ' x ' + STRING(ndvi2021.NROWS)
      PRINT, '    2025年尺寸: ' + STRING(ndvi2025.NCOLUMNS) + ' x ' + STRING(ndvi2025.NROWS)
    ENDIF ELSE BEGIN
      PRINT, '  检测到: 两个时相的NDVI影像尺寸一致'
      PRINT, '    尺寸: ' + STRING(ndvi2021.NCOLUMNS) + ' x ' + STRING(ndvi2021.NROWS)
      PRINT, '    将使用ImageIntersection确保按地理坐标精确对齐（消除可能的偏移）'
    ENDELSE
    
    IF OBJ_VALID(spatialRef2021) AND OBJ_VALID(spatialRef2025) THEN BEGIN
      PRINT, '  ✓ 两个影像都有空间参考信息，将按地理坐标对齐'
    ENDIF ELSE BEGIN
      PRINT, '  警告: 部分影像缺少空间参考信息，对齐可能不精确'
    ENDELSE
    
    ; 使用ImageIntersection进行对齐
    ndvi2021_aligned = !NULL
    ndvi2025_aligned = !NULL
    CATCH, errIntersectNDVI
    IF errIntersectNDVI EQ 0 THEN BEGIN
      intersectTask = ENVITask('ImageIntersection')
      intersectTask.INPUT_RASTER1 = ndvi2021
      intersectTask.INPUT_RASTER2 = ndvi2025
      intersectTask.Execute
      ndvi2021_aligned = intersectTask.OUTPUT_RASTER1
      ndvi2025_aligned = intersectTask.OUTPUT_RASTER2
      CATCH, /CANCEL
      
      IF OBJ_VALID(ndvi2021_aligned) AND OBJ_VALID(ndvi2025_aligned) THEN BEGIN
        PRINT, '  ✓ NDVI影像对齐完成（按地理坐标）'
        ; 验证对齐后的尺寸
        PRINT, '  对齐后尺寸: ' + STRING(ndvi2021_aligned.NCOLUMNS) + ' x ' + STRING(ndvi2021_aligned.NROWS)
        
        ; 验证对齐后的空间参考
        spatialRef2021_aligned = !NULL
        spatialRef2025_aligned = !NULL
        CATCH, errSR2021Aligned
        IF errSR2021Aligned EQ 0 THEN BEGIN
          spatialRef2021_aligned = ndvi2021_aligned.SPATIALREF
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
        CATCH, errSR2025Aligned
        IF errSR2025Aligned EQ 0 THEN BEGIN
          spatialRef2025_aligned = ndvi2025_aligned.SPATIALREF
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
        
        IF OBJ_VALID(spatialRef2021_aligned) AND OBJ_VALID(spatialRef2025_aligned) THEN BEGIN
          PRINT, '  ✓ 对齐后的影像都有空间参考信息'
        ENDIF
      ENDIF ELSE BEGIN
        PRINT, '  错误: ImageIntersection返回的对象无效'
        ndvi2021_aligned = ndvi2021
        ndvi2025_aligned = ndvi2025
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: NDVI影像对齐失败: ' + !ERROR_STATE.MSG
      PRINT, '  将使用原始影像（可能有偏移）'
      ndvi2021_aligned = ndvi2021
      ndvi2025_aligned = ndvi2025
    ENDELSE
    
    ; 计算NDVI差值
    IF OBJ_VALID(ndvi2021_aligned) AND OBJ_VALID(ndvi2025_aligned) THEN BEGIN
      PRINT, '正在计算NDVI差值（2025 - 2021）...'
      CATCH, errNDVIDiff
      IF errNDVIDiff EQ 0 THEN BEGIN
        ndviDiffTask = ENVITask('ImageBandDifference')
        ndviDiffTask.INPUT_RASTER1 = ndvi2021_aligned
        ndviDiffTask.INPUT_RASTER2 = ndvi2025_aligned
        ndviDiffTask.Execute
        ndviDiff = ndviDiffTask.OUTPUT_RASTER
        CATCH, /CANCEL
        
        IF OBJ_VALID(ndviDiff) THEN BEGIN
          ; 保存NDVI差值
          outputNDVIDiff = outputDir + PATH_SEP() + 'ndvi_diff_2021_2025.dat'
          IF FILE_TEST(outputNDVIDiff) THEN BEGIN
            FILE_DELETE, outputNDVIDiff, /QUIET
            hdrFile = FILE_DIRNAME(outputNDVIDiff) + PATH_SEP() + FILE_BASENAME(outputNDVIDiff, '.dat') + '.hdr'
            IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
          ENDIF
          ndviDiff.Export, outputNDVIDiff, 'ENVI'
          WAIT, 0.5
          PRINT, '✓ NDVI差值已保存: ' + FILE_BASENAME(outputNDVIDiff)
          
          ; 关闭原始对象
          ndviDiff.Close
          
          ; 重新打开进行统计
          ndviDiff = e.OpenRaster(outputNDVIDiff)
          IF OBJ_VALID(ndviDiff) THEN BEGIN
            PRINT, '正在计算NDVI差值统计信息...'
            histTask = ENVITask('RasterHistogram')
            histTask.INPUT_RASTER = ndviDiff
            histTask.INPUT_MIN = [-2.0]
            histTask.INPUT_MAX = [2.0]
            histTask.INPUT_NBINS = [1000]
            histTask.Execute
            counts = (histTask.OUTPUT_COUNTS).ToArray()
            minVal = histTask.INPUT_MIN[0]
            maxVal = histTask.INPUT_MAX[0]
            nBins = histTask.INPUT_NBINS[0]
            binSize = (maxVal - minVal) / nBins
            binCenters = minVal + (FINDGEN(nBins) + 0.5) * binSize
            totalPixels = TOTAL(counts)
            IF totalPixels GT 0 THEN BEGIN
              meanVal = TOTAL(binCenters * counts) / totalPixels
              variance = TOTAL((binCenters - meanVal)^2 * counts) / totalPixels
              stdDev = SQRT(variance)
              minIdx = WHERE(counts GT 0, count)
              IF count GT 0 THEN minValActual = binCenters[minIdx[0]] ELSE minValActual = minVal
              maxIdx = WHERE(counts GT 0, count)
              IF count GT 0 THEN maxValActual = binCenters[maxIdx[count-1]] ELSE maxValActual = maxVal
              PRINT, '  NDVI差值统计:'
              PRINT, '    均值: ' + STRING(meanVal, FORMAT='(F6.4)')
              PRINT, '    标准差: ' + STRING(stdDev, FORMAT='(F6.4)')
              PRINT, '    最小值: ' + STRING(minValActual, FORMAT='(F6.4)')
              PRINT, '    最大值: ' + STRING(maxValActual, FORMAT='(F6.4)')
              PRINT, '  说明: 负值表示NDVI降低（植被退化），正值表示NDVI增加（植被改善）'
            ENDIF
            ndviDiff.Close
          ENDIF
        ENDIF
        
        ; 关闭对齐后的对象（如果不同）
        IF (ndvi2021_aligned NE ndvi2021) AND OBJ_VALID(ndvi2021_aligned) THEN ndvi2021_aligned.Close
        IF (ndvi2025_aligned NE ndvi2025) AND OBJ_VALID(ndvi2025_aligned) THEN ndvi2025_aligned.Close
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '错误: 计算NDVI差值失败: ' + !ERROR_STATE.MSG
      ENDELSE
    ENDIF
  ENDELSE
  
  ; ============================================
  ; NDWI对比分析
  ; ============================================
  IF OBJ_VALID(ndwi2021) AND OBJ_VALID(ndwi2025) THEN BEGIN
    PRINT, ''
    PRINT, '========== NDWI变化分析 =========='
    
    ; 始终使用ImageIntersection进行对齐，确保按地理坐标精确对齐
    PRINT, '正在按地理坐标对齐NDWI影像...'
    IF (ndwi2021.NCOLUMNS NE ndwi2025.NCOLUMNS) OR (ndwi2021.NROWS NE ndwi2025.NROWS) THEN BEGIN
      PRINT, '  检测到: 两个时相的NDWI影像尺寸不一致'
    ENDIF ELSE BEGIN
      PRINT, '  检测到: 两个时相的NDWI影像尺寸一致，将确保按地理坐标精确对齐'
    ENDELSE
    
    ndwi2021_aligned = !NULL
    ndwi2025_aligned = !NULL
    CATCH, errIntersectNDWI
    IF errIntersectNDWI EQ 0 THEN BEGIN
      intersectTask = ENVITask('ImageIntersection')
      intersectTask.INPUT_RASTER1 = ndwi2021
      intersectTask.INPUT_RASTER2 = ndwi2025
      intersectTask.Execute
      ndwi2021_aligned = intersectTask.OUTPUT_RASTER1
      ndwi2025_aligned = intersectTask.OUTPUT_RASTER2
      CATCH, /CANCEL
      
      IF OBJ_VALID(ndwi2021_aligned) AND OBJ_VALID(ndwi2025_aligned) THEN BEGIN
        PRINT, '  ✓ NDWI影像对齐完成（按地理坐标）'
        PRINT, '  对齐后尺寸: ' + STRING(ndwi2021_aligned.NCOLUMNS) + ' x ' + STRING(ndwi2021_aligned.NROWS)
      ENDIF ELSE BEGIN
        PRINT, '  错误: ImageIntersection返回的对象无效'
        ndwi2021_aligned = ndwi2021
        ndwi2025_aligned = ndwi2025
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: NDWI影像对齐失败: ' + !ERROR_STATE.MSG
      PRINT, '  将使用原始影像（可能有偏移）'
      ndwi2021_aligned = ndwi2021
      ndwi2025_aligned = ndwi2025
    ENDELSE
    
    ; 计算NDWI差值
    IF OBJ_VALID(ndwi2021_aligned) AND OBJ_VALID(ndwi2025_aligned) THEN BEGIN
      PRINT, '正在计算NDWI差值（2025 - 2021）...'
      CATCH, errNDWIDiff
      IF errNDWIDiff EQ 0 THEN BEGIN
        ndwiDiffTask = ENVITask('ImageBandDifference')
        ndwiDiffTask.INPUT_RASTER1 = ndwi2021_aligned
        ndwiDiffTask.INPUT_RASTER2 = ndwi2025_aligned
        ndwiDiffTask.Execute
        ndwiDiff = ndwiDiffTask.OUTPUT_RASTER
        CATCH, /CANCEL
        
        IF OBJ_VALID(ndwiDiff) THEN BEGIN
          outputNDWIDiff = outputDir + PATH_SEP() + 'ndwi_diff_2021_2025.dat'
          IF FILE_TEST(outputNDWIDiff) THEN BEGIN
            FILE_DELETE, outputNDWIDiff, /QUIET
            hdrFile = FILE_DIRNAME(outputNDWIDiff) + PATH_SEP() + FILE_BASENAME(outputNDWIDiff, '.dat') + '.hdr'
            IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
          ENDIF
          ndwiDiff.Export, outputNDWIDiff, 'ENVI'
          WAIT, 0.5
          PRINT, '✓ NDWI差值已保存: ' + FILE_BASENAME(outputNDWIDiff)
          ndwiDiff.Close
          IF (ndwi2021_aligned NE ndwi2021) AND OBJ_VALID(ndwi2021_aligned) THEN ndwi2021_aligned.Close
          IF (ndwi2025_aligned NE ndwi2025) AND OBJ_VALID(ndwi2025_aligned) THEN ndwi2025_aligned.Close
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '错误: 计算NDWI差值失败: ' + !ERROR_STATE.MSG
      ENDELSE
    ENDIF
  ENDIF
  
  ; ============================================
  ; NDBI对比分析
  ; ============================================
  IF OBJ_VALID(ndbi2021) AND OBJ_VALID(ndbi2025) THEN BEGIN
    PRINT, ''
    PRINT, '========== NDBI变化分析 =========='
    
    ; 始终使用ImageIntersection进行对齐，确保按地理坐标精确对齐
    PRINT, '正在按地理坐标对齐NDBI影像...'
    IF (ndbi2021.NCOLUMNS NE ndbi2025.NCOLUMNS) OR (ndbi2021.NROWS NE ndbi2025.NROWS) THEN BEGIN
      PRINT, '  检测到: 两个时相的NDBI影像尺寸不一致'
    ENDIF ELSE BEGIN
      PRINT, '  检测到: 两个时相的NDBI影像尺寸一致，将确保按地理坐标精确对齐'
    ENDELSE
    
    ndbi2021_aligned = !NULL
    ndbi2025_aligned = !NULL
    CATCH, errIntersectNDBI
    IF errIntersectNDBI EQ 0 THEN BEGIN
      intersectTask = ENVITask('ImageIntersection')
      intersectTask.INPUT_RASTER1 = ndbi2021
      intersectTask.INPUT_RASTER2 = ndbi2025
      intersectTask.Execute
      ndbi2021_aligned = intersectTask.OUTPUT_RASTER1
      ndbi2025_aligned = intersectTask.OUTPUT_RASTER2
      CATCH, /CANCEL
      
      IF OBJ_VALID(ndbi2021_aligned) AND OBJ_VALID(ndbi2025_aligned) THEN BEGIN
        PRINT, '  ✓ NDBI影像对齐完成（按地理坐标）'
        PRINT, '  对齐后尺寸: ' + STRING(ndbi2021_aligned.NCOLUMNS) + ' x ' + STRING(ndbi2021_aligned.NROWS)
      ENDIF ELSE BEGIN
        PRINT, '  错误: ImageIntersection返回的对象无效'
        ndbi2021_aligned = ndbi2021
        ndbi2025_aligned = ndbi2025
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: NDBI影像对齐失败: ' + !ERROR_STATE.MSG
      PRINT, '  将使用原始影像（可能有偏移）'
      ndbi2021_aligned = ndbi2021
      ndbi2025_aligned = ndbi2025
    ENDELSE
    
    ; 计算NDBI差值
    IF OBJ_VALID(ndbi2021_aligned) AND OBJ_VALID(ndbi2025_aligned) THEN BEGIN
      PRINT, '正在计算NDBI差值（2025 - 2021）...'
      CATCH, errNDBIDiff
      IF errNDBIDiff EQ 0 THEN BEGIN
        ndbiDiffTask = ENVITask('ImageBandDifference')
        ndbiDiffTask.INPUT_RASTER1 = ndbi2021_aligned
        ndbiDiffTask.INPUT_RASTER2 = ndbi2025_aligned
        ndbiDiffTask.Execute
        ndbiDiff = ndbiDiffTask.OUTPUT_RASTER
        CATCH, /CANCEL
        
        IF OBJ_VALID(ndbiDiff) THEN BEGIN
          outputNDBIDiff = outputDir + PATH_SEP() + 'ndbi_diff_2021_2025.dat'
          IF FILE_TEST(outputNDBIDiff) THEN BEGIN
            FILE_DELETE, outputNDBIDiff, /QUIET
            hdrFile = FILE_DIRNAME(outputNDBIDiff) + PATH_SEP() + FILE_BASENAME(outputNDBIDiff, '.dat') + '.hdr'
            IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
          ENDIF
          ndbiDiff.Export, outputNDBIDiff, 'ENVI'
          WAIT, 0.5
          PRINT, '✓ NDBI差值已保存: ' + FILE_BASENAME(outputNDBIDiff)
          ndbiDiff.Close
          IF (ndbi2021_aligned NE ndbi2021) AND OBJ_VALID(ndbi2021_aligned) THEN ndbi2021_aligned.Close
          IF (ndbi2025_aligned NE ndbi2025) AND OBJ_VALID(ndbi2025_aligned) THEN ndbi2025_aligned.Close
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '错误: 计算NDBI差值失败: ' + !ERROR_STATE.MSG
      ENDELSE
    ENDIF
  ENDIF
  
  ; 关闭所有对象
  IF OBJ_VALID(ndvi2021) THEN ndvi2021.Close
  IF OBJ_VALID(ndwi2021) THEN ndwi2021.Close
  IF OBJ_VALID(ndbi2021) THEN ndbi2021.Close
  IF OBJ_VALID(ndvi2025) THEN ndvi2025.Close
  IF OBJ_VALID(ndwi2025) THEN ndwi2025.Close
  IF OBJ_VALID(ndbi2025) THEN ndbi2025.Close
  
  PRINT, ''
  PRINT, '========================================='
  PRINT, '✓✓✓ 处理完成！ ✓✓✓'
  PRINT, '========================================='
  PRINT, '输出目录: ' + outputDir
  PRINT, ''
  PRINT, '✓ 所有结果已保存，包括：'
  PRINT, '  - 2021年和2025年的NDVI、NDWI、NDBI'
  PRINT, '  - NDVI、NDWI、NDBI的差值（2025 - 2021）'
  
END

