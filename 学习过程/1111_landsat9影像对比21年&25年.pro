;+
; 程序名: test1110_finalndvi.pro
; 功能: 基于NDVI和NDBI的LC09数据随机森林监督分类与时间序列变化分析
;       1. 计算NDVI和NDBI
;       2. 使用ROI进行随机森林监督分类（植被、水体、其他）
;       3. 2021年与2025年参数对比
;       4. 植被退化、水体变化分析
; 作者: Auto
; 日期: 2024
; 更新: 使用随机森林分类方法（Random Forest）
;-

; 辅助函数：从MTL XML文件读取投影参数并创建空间参考
; 返回值：mapInfo结构体
FUNCTION create_spatial_ref_from_mtl_xml, mtlXmlFile, nColumns, nRows
  COMPILE_OPT IDL2
  
  ; 读取XML文件内容
  OPENR, lun, mtlXmlFile, /GET_LUN
  xmlLines = STRARR(1000)  ; 预分配数组
  lineCount = 0
  WHILE ~EOF(lun) && lineCount LT 1000 DO BEGIN
    READF, lun, xmlLines[lineCount]
    lineCount++
  ENDWHILE
  CLOSE, lun
  FREE_LUN, lun
  xmlLines = xmlLines[0:lineCount-1]  ; 截取实际内容
  
  ; 解析XML获取投影参数（简化方法：使用字符串匹配）
  ; 从用户提供的XML，我们知道投影参数在PROJECTION_ATTRIBUTES中
  utmZone = 50  ; 默认值
  datum = 'WGS-84'
  pixelSize = 30.0  ; 米
  ulX = 225900.0
  ulY = 2833200.0
  
  ; 尝试从XML内容中提取参数
  ; 注意：将行转换为大写以实现大小写不敏感搜索
  ; UTM_ZONE
  FOR i=0, lineCount-1 DO BEGIN
    line = xmlLines[i]
    lineUpper = STRUPCASE(line)  ; 转换为大写
    tagPos = STRPOS(lineUpper, '<UTM_ZONE>')
    IF tagPos GE 0 THEN BEGIN
      ; 提取UTM_ZONE值（使用原始行，保持大小写）
      tagStart = tagPos + 10
      tagEnd = STRPOS(lineUpper, '</UTM_ZONE>')
      IF tagEnd GT tagStart THEN BEGIN
        zoneStr = STRMID(line, tagStart, tagEnd - tagStart)
        utmZone = FIX(STRTRIM(zoneStr, 2))
        BREAK
      ENDIF
    ENDIF
  ENDFOR
  
  ; CORNER_UL_PROJECTION_X_PRODUCT
  FOR i=0, lineCount-1 DO BEGIN
    line = xmlLines[i]
    lineUpper = STRUPCASE(line)  ; 转换为大写
    tagPos = STRPOS(lineUpper, '<CORNER_UL_PROJECTION_X_PRODUCT>')
    IF tagPos GE 0 THEN BEGIN
      tagStart = tagPos + 33
      tagEnd = STRPOS(lineUpper, '</CORNER_UL_PROJECTION_X_PRODUCT>')
      IF tagEnd GT tagStart THEN BEGIN
        ulXStr = STRMID(line, tagStart, tagEnd - tagStart)
        ulX = FLOAT(STRTRIM(ulXStr, 2))
        BREAK
      ENDIF
    ENDIF
  ENDFOR
  
  ; CORNER_UL_PROJECTION_Y_PRODUCT
  FOR i=0, lineCount-1 DO BEGIN
    line = xmlLines[i]
    lineUpper = STRUPCASE(line)  ; 转换为大写
    tagPos = STRPOS(lineUpper, '<CORNER_UL_PROJECTION_Y_PRODUCT>')
    IF tagPos GE 0 THEN BEGIN
      tagStart = tagPos + 33
      tagEnd = STRPOS(lineUpper, '</CORNER_UL_PROJECTION_Y_PRODUCT>')
      IF tagEnd GT tagStart THEN BEGIN
        ulYStr = STRMID(line, tagStart, tagEnd - tagStart)
        ulY = FLOAT(STRTRIM(ulYStr, 2))
        BREAK
      ENDIF
    ENDIF
  ENDFOR
  
  ; GRID_CELL_SIZE_REFLECTIVE
  FOR i=0, lineCount-1 DO BEGIN
    line = xmlLines[i]
    lineUpper = STRUPCASE(line)  ; 转换为大写
    tagPos = STRPOS(lineUpper, '<GRID_CELL_SIZE_REFLECTIVE>')
    IF tagPos GE 0 THEN BEGIN
      tagStart = tagPos + 27
      tagEnd = STRPOS(lineUpper, '</GRID_CELL_SIZE_REFLECTIVE>')
      IF tagEnd GT tagStart THEN BEGIN
        psStr = STRMID(line, tagStart, tagEnd - tagStart)
        pixelSize = FLOAT(STRTRIM(psStr, 2))
        BREAK
      ENDIF
    ENDIF
  ENDFOR
  
  ; 打印解析到的参数信息
  PRINT, '  解析到的投影参数:'
  PRINT, '    UTM Zone: ' + STRING(utmZone)
  PRINT, '    左上角X: ' + STRING(ulX, FORMAT='(F12.2)')
  PRINT, '    左上角Y: ' + STRING(ulY, FORMAT='(F12.2)')
  PRINT, '    像元大小: ' + STRING(pixelSize, FORMAT='(F6.2)') + ' 米'
  
  ; 创建MAP_INFO
  ; 注意：MC参数是[column, row, mapX, mapY]，其中column和row是像素(0,0)对应的map坐标
  ; 对于Landsat数据，左上角像素(0,0)对应的map坐标就是ulX和ulY
  PRINT, '  正在创建MAP_INFO结构体...'
  PRINT, '    参数: UTM Zone=' + STRING(utmZone) + ', DATUM=' + datum + ', MC=[' + STRING(0.0) + ',' + STRING(0.0) + ',' + STRING(ulX) + ',' + STRING(ulY) + '], PS=[' + STRING(pixelSize) + ',' + STRING(pixelSize) + ']'
  mapInfo = !NULL
  CATCH, errMapInfo
  IF errMapInfo EQ 0 THEN BEGIN
    ; 尝试创建MAP_INFO
    mapInfo = ENVI_MAP_INFO_CREATE( $
      /UTM, $
      ZONE=utmZone, $
      /NORTH, $
      DATUM=datum, $
      MC=[0.0, 0.0, ulX, ulY], $  ; Map coordinates of pixel (0,0)
      PS=[pixelSize, pixelSize] $  ; Pixel size in meters
    )
    CATCH, /CANCEL
    ; 验证mapInfo是否创建成功
    ; mapInfo是结构体，不能使用OBJ_VALID
    IF mapInfo EQ !NULL THEN BEGIN
      PRINT, '  错误: ENVI_MAP_INFO_CREATE返回!NULL'
      PRINT, '  可能原因: 参数不正确或ENVI版本不支持'
      RETURN, !NULL
    ENDIF
    ; 检查结构体是否有元素
    nElements = N_ELEMENTS(mapInfo)
    IF nElements EQ 0 THEN BEGIN
      PRINT, '  错误: ENVI_MAP_INFO_CREATE返回空结构体 (N_ELEMENTS=0)'
      PRINT, '  可能原因: 参数不正确或ENVI版本不支持'
      RETURN, !NULL
    ENDIF
    PRINT, '  ✓ MAP_INFO结构体创建成功 (N_ELEMENTS=' + STRING(nElements) + ')'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 创建MAP_INFO时发生异常'
    PRINT, '  错误信息: ' + !ERROR_STATE.MSG
    PRINT, '  错误代码: ' + STRING(!ERROR_STATE.CODE)
    RETURN, !NULL
  ENDELSE
  
  RETURN, mapInfo
END

; 辅助函数：写入日志
; 使用COMMON块共享日志文件句柄
PRO log_write, message
  COMPILE_OPT IDL2
  COMMON LOG_COMMON, logLun
  IF (logLun GT 0) THEN BEGIN
    logTime = SYSTIME()
    logMsg = '[' + STRING(logTime, FORMAT='(A)') + '] ' + message
    PRINT, logMsg
    PRINTF, logLun, logMsg
    FLUSH, logLun  ; 立即刷新，确保写入文件
  ENDIF ELSE BEGIN
    PRINT, message
  ENDELSE
END

; 辅助函数：写入错误日志
; 使用COMMON块共享日志文件句柄
PRO log_error, message, errorState
  COMPILE_OPT IDL2
  COMMON LOG_COMMON, logLun
  IF (logLun GT 0) THEN BEGIN
    logTime = SYSTIME()
    logMsg = '[' + STRING(logTime, FORMAT='(A)') + '] ERROR: ' + message
    IF ARG_PRESENT(errorState) THEN BEGIN
      logMsg = logMsg + ' | Code: ' + STRING(errorState.CODE) + ' | Message: ' + errorState.MSG
    ENDIF
    PRINT, logMsg
    PRINTF, logLun, logMsg
    FLUSH, logLun
  ENDIF ELSE BEGIN
    PRINT, 'ERROR: ' + message
    IF ARG_PRESENT(errorState) THEN BEGIN
      PRINT, '  Code: ' + STRING(errorState.CODE) + ' | Message: ' + errorState.MSG
    ENDIF
  ENDELSE
END

; 辅助函数：为raster设置空间参考
FUNCTION set_spatial_ref_to_raster, inputRaster, mapInfo
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  ; 保存原始raster的波长信息（如果存在）
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
    ; 如果没有波长信息，使用Landsat 9 OLI-2的标准波长值
    ; Landsat 9有7个反射波段（与Landsat 8相同）
    nBands = inputRaster.NBANDS
    PRINT, '  未检测到波长信息，波段数: ' + STRING(nBands)
    IF nBands GE 7 THEN BEGIN
      ; Landsat 9 OLI-2的7个反射波段的标准波长值
      wavelength_7bands = [0.443, 0.4826, 0.5613, 0.6546, 0.8646, 1.609, 2.201]  ; 微米
      fwhm_7bands = [0.016, 0.0601, 0.0574, 0.0375, 0.0282, 0.0847, 0.1867]  ; 微米
      bandNames_7bands = ['Coastal aerosol', 'Blue', 'Green', 'Red', 'Near Infrared (NIR)', 'SWIR 1', 'SWIR 2']
      
      ; 根据实际波段数设置波长
      IF nBands EQ 7 THEN BEGIN
        wavelength = wavelength_7bands
        fwhm = fwhm_7bands
        bandNames = bandNames_7bands
        hasWavelength = 1
        PRINT, '  将使用Landsat 9标准7个反射波段波长值'
      ENDIF ELSE IF nBands EQ 8 THEN BEGIN
        ; 8个波段：可能是7个反射波段+1个QA波段
        ; 为第8个波段使用一个占位波长值（使用最后一个反射波段的波长作为占位）
        wavelength = [wavelength_7bands, 2.201]  ; 第8个波段使用SWIR 2的波长作为占位
        fwhm = [fwhm_7bands, 0.1867]  ; 第8个波段使用SWIR 2的FWHM作为占位
        bandNames = [bandNames_7bands, 'QA']  ; 第8个波段标记为QA
        hasWavelength = 1
        PRINT, '  将使用Landsat 9标准7个反射波段波长值，第8个波段（QA）使用占位波长值'
      ENDIF ELSE BEGIN
        ; 其他情况：波段数大于8或小于7
        IF nBands GT 8 THEN BEGIN
          ; 只对前7个波段设置标准波长，其余使用占位值
          wavelength = wavelength_7bands
          fwhm = fwhm_7bands
          bandNames = bandNames_7bands
          FOR i=7, nBands-1 DO BEGIN
            wavelength = [wavelength, 2.201]  ; 使用占位波长
            fwhm = [fwhm, 0.1867]  ; 使用占位FWHM
            bandNames = [bandNames, 'Band ' + STRING(i+1)]
          ENDFOR
          hasWavelength = 1
          PRINT, '  将使用Landsat 9标准7个反射波段波长值，其余波段使用占位波长值'
        ENDIF ELSE BEGIN
          ; nBands < 7的情况
          PRINT, '  警告: 波段数不足7个，无法设置标准波长值'
        ENDELSE
      ENDELSE
    ENDIF ELSE BEGIN
      ; 波段数小于7的情况
      ; 可能是RGB+NIR的4个波段，或者其他组合
      IF nBands EQ 4 THEN BEGIN
        ; 假设是Blue, Green, Red, NIR的4个波段
        wavelength = [0.4826, 0.5613, 0.6546, 0.8646]  ; Blue, Green, Red, NIR (微米)
        fwhm = [0.0601, 0.0574, 0.0375, 0.0282]  ; 对应的FWHM
        bandNames = ['Blue', 'Green', 'Red', 'Near Infrared (NIR)']
        hasWavelength = 1
        PRINT, '  将使用4个波段（Blue, Green, Red, NIR）的标准波长值'
      ENDIF ELSE IF nBands EQ 3 THEN BEGIN
        ; 假设是RGB的3个波段
        wavelength = [0.4826, 0.5613, 0.6546]  ; Blue, Green, Red (微米)
        fwhm = [0.0601, 0.0574, 0.0375]  ; 对应的FWHM
        bandNames = ['Blue', 'Green', 'Red']
        hasWavelength = 1
        PRINT, '  将使用3个波段（Blue, Green, Red）的标准波长值'
      ENDIF ELSE IF nBands EQ 5 THEN BEGIN
        ; 假设是Blue, Green, Red, NIR, SWIR1的5个波段
        wavelength = [0.4826, 0.5613, 0.6546, 0.8646, 1.609]  ; 微米
        fwhm = [0.0601, 0.0574, 0.0375, 0.0282, 0.0847]  ; 对应的FWHM
        bandNames = ['Blue', 'Green', 'Red', 'Near Infrared (NIR)', 'SWIR 1']
        hasWavelength = 1
        PRINT, '  将使用5个波段的标准波长值'
      ENDIF ELSE IF nBands EQ 6 THEN BEGIN
        ; 假设是前6个反射波段
        wavelength = [0.443, 0.4826, 0.5613, 0.6546, 0.8646, 1.609]  ; 微米
        fwhm = [0.016, 0.0601, 0.0574, 0.0375, 0.0282, 0.0847]  ; 对应的FWHM
        bandNames = ['Coastal aerosol', 'Blue', 'Green', 'Red', 'Near Infrared (NIR)', 'SWIR 1']
        hasWavelength = 1
        PRINT, '  将使用6个波段的标准波长值'
      ENDIF ELSE BEGIN
        PRINT, '  警告: 波段数=' + STRING(nBands) + '，无法确定标准波长值'
        PRINT, '  提示: 如果这是Landsat数据，可能需要使用DATASET_NAME参数打开完整的多光谱数据'
      ENDELSE
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
  ; 检查raster对象是否有效
  IF ~OBJ_VALID(inputRaster) THEN BEGIN
    PRINT, '  错误: inputRaster对象无效，无法导出'
    RETURN, !NULL
  ENDIF
  
  ; 使用指定的临时文件目录（直接使用固定路径，不使用COMMON块）
  tempDirLocal = 'E:\1027IDL\ENVITaskTrainning\Temp'
  IF ~FILE_TEST(tempDirLocal, /DIRECTORY) THEN FILE_MKDIR, tempDirLocal
  ; 生成唯一的临时文件名
  tempBaseName = 'temp_raster_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
  tempFile = tempDirLocal + PATH_SEP() + tempBaseName
  
  ; 删除已存在的文件（如果存在）
  IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
  hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
  IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  
  PRINT, '  临时文件路径: ' + tempFile
  CATCH, errExport
  IF errExport EQ 0 THEN BEGIN
    ; 尝试导出raster
    PRINT, '  正在执行Export操作...'
    inputRaster.Export, tempFile, 'ENVI'
    PRINT, '  Export调用完成'
    ; 等待文件写入完成
    WAIT, 0.5
    ; 验证文件是否创建成功
    IF FILE_TEST(tempFile) THEN BEGIN
      PRINT, '  ✓ Raster已导出到: ' + FILE_BASENAME(tempFile)
      ; 不关闭raster，因为可能还需要使用
    ENDIF ELSE BEGIN
      PRINT, '  错误: 导出后文件不存在: ' + tempFile
      RETURN, !NULL
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    errorMsg = '导出raster失败: ' + !ERROR_STATE.MSG + ' (Code: ' + STRING(!ERROR_STATE.CODE) + ')'
    PRINT, '  错误: ' + errorMsg
    PRINT, '  尝试使用ENVI的GetTemporaryFilename方法...'
    ; 如果直接导出失败，尝试使用ENVI的临时文件方法
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
    PRINT, '  错误: 设置空间参考时发生错误'
    PRINT, '  错误信息: ' + !ERROR_STATE.MSG
    PRINT, '  错误代码: ' + STRING(!ERROR_STATE.CODE)
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
    ENDIF ELSE BEGIN
      PRINT, '  警告: 新raster没有波长信息，可能影响光谱指数计算'
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '  错误: 重新打开raster失败'
    RETURN, !NULL
  ENDELSE
  
  RETURN, outputRaster
END

; 辅助函数：分类后处理（平滑、聚合、元数据更新）
; 输入参数：
;   classifiedRaster: 分类结果raster对象
;   outputFile: 输出文件路径
;   classNames: 类别名称数组
;   nClasses: 类别数量
;   spatialRef: 空间参考对象（可选，用于计算聚合阈值）
;   year: 年份字符串（用于日志，如'2021'）
;   logLun: 日志文件句柄（可选）
; 返回值：最终处理后的raster对象
FUNCTION process_classification_postprocessing, classifiedRaster, outputFile, classNames, nClasses, spatialRef, year, logLun
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  ; 检查输入
  IF ~OBJ_VALID(classifiedRaster) THEN BEGIN
    logMsg = '[' + year + '后处理] 错误: 输入raster对象无效'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    RETURN, !NULL
  ENDIF
  
  ; ============================================
  ; 步骤1: 数据验证（输入数据）
  ; ============================================
  logMsg = '[' + year + '后处理] 步骤1: 验证输入数据...'
  PRINT, logMsg
  IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
    PRINTF, logLun, logMsg
    FLUSH, logLun
  ENDIF
  skipAggregation = 0
  CATCH, errCheckInput
  IF errCheckInput EQ 0 THEN BEGIN
    nColsTempInput = classifiedRaster.NCOLUMNS
    nRowsTempInput = classifiedRaster.NROWS
    nColsInput = LONG(nColsTempInput)
    nRowsInput = LONG(nRowsTempInput)
    nColsInputMinus1 = nColsInput - 1L
    nRowsInputMinus1 = nRowsInput - 1L
    rectColsInput = MIN(500L, nColsInputMinus1)
    rectRowsInput = MIN(500L, nRowsInputMinus1)
    subRectArrayInput = [0L, 0L, rectColsInput, rectRowsInput]
    sampleInput = classifiedRaster.GetData(BANDS=0, SUB_RECT=subRectArrayInput)
    minValInput = MIN(sampleInput)
    maxValInput = MAX(sampleInput)
    nonZeroInput = N_ELEMENTS(WHERE(sampleInput NE 0))
    sortedInput = sampleInput[SORT(sampleInput)]
    uniqueValsInput = sortedInput[UNIQ(sortedInput)]
    
    IF (maxValInput GT (nClasses + 5)) OR (minValInput LT -1) THEN BEGIN
      logMsg = '[' + year + '后处理] 警告: 输入数据值异常，将跳过聚合步骤'
      PRINT, logMsg
      IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
        PRINTF, logLun, logMsg
        FLUSH, logLun
      ENDIF
      skipAggregation = 1
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    logMsg = '[' + year + '后处理] 警告: 输入数据验证失败，将跳过聚合步骤'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    skipAggregation = 1
  ENDELSE
  
  ; ============================================
  ; 步骤2: 分类平滑
  ; ============================================
  logMsg = '[' + year + '后处理] 步骤2: 分类平滑...'
  PRINT, logMsg
  IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
    PRINTF, logLun, logMsg
    FLUSH, logLun
  ENDIF
  smoothTask = ENVITask('ClassificationSmoothing')
  smoothTask.INPUT_RASTER = classifiedRaster
  smoothTask.KERNEL_SIZE = 5
  smoothTask.Execute
  smoothRaster = smoothTask.OUTPUT_RASTER
  
  IF ~OBJ_VALID(smoothRaster) THEN BEGIN
    logMsg = '[' + year + '后处理] 错误: 平滑处理失败'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    RETURN, !NULL
  ENDIF
  
  ; 验证平滑后数据
  CATCH, errCheckSmooth
  IF errCheckSmooth EQ 0 THEN BEGIN
    nColsTempSmooth = smoothRaster.NCOLUMNS
    nRowsTempSmooth = smoothRaster.NROWS
    nColsSmooth = LONG(nColsTempSmooth)
    nRowsSmooth = LONG(nRowsTempSmooth)
    nColsSmoothMinus1 = nColsSmooth - 1L
    nRowsSmoothMinus1 = nRowsSmooth - 1L
    rectColsSmooth = MIN(500L, nColsSmoothMinus1)
    rectRowsSmooth = MIN(500L, nRowsSmoothMinus1)
    subRectArraySmooth = [0L, 0L, rectColsSmooth, rectRowsSmooth]
    sampleSmooth = smoothRaster.GetData(BANDS=0, SUB_RECT=subRectArraySmooth)
    minValSmooth = MIN(sampleSmooth)
    maxValSmooth = MAX(sampleSmooth)
    nonZeroSmooth = N_ELEMENTS(WHERE(sampleSmooth NE 0))
    
    IF (maxValSmooth GT (nClasses + 5)) OR (minValSmooth LT -1) THEN BEGIN
      logMsg = '[' + year + '后处理] 警告: 平滑后数据值异常，将跳过聚合步骤'
      PRINT, logMsg
      IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
        PRINTF, logLun, logMsg
        FLUSH, logLun
      ENDIF
      skipAggregation = 1
    ENDIF
    IF nonZeroSmooth LT (N_ELEMENTS(sampleSmooth) * 0.01) THEN BEGIN
      logMsg = '[' + year + '后处理] 警告: 平滑后数据几乎全为零，将跳过聚合步骤'
      PRINT, logMsg
      IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
        PRINTF, logLun, logMsg
        FLUSH, logLun
      ENDIF
      skipAggregation = 1
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    logMsg = '[' + year + '后处理] 警告: 平滑后数据验证失败，将跳过聚合步骤'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    skipAggregation = 1
  ENDELSE
  
  ; ============================================
  ; 步骤3: 分类聚合（三种方法）
  ; ============================================
  useAggregation = 0
  methodUsed = ''
  finalRaster = !NULL
  
  IF skipAggregation EQ 1 THEN BEGIN
    logMsg = '[' + year + '后处理] 步骤3: 跳过聚合（数据异常），直接使用平滑结果'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    smoothRaster.Export, outputFile, 'ENVI'
    WAIT, 1.0
    finalRaster = e.OpenRaster(outputFile)
    methodUsed = '仅平滑（数据异常，跳过聚合）'
  ENDIF ELSE BEGIN
    logMsg = '[' + year + '后处理] 步骤3: 分类聚合（三种方法）...'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    
    ; 计算聚合阈值
    aggregateSize = 0
    IF OBJ_VALID(spatialRef) THEN BEGIN
      pixelArea = PRODUCT(spatialRef.PIXEL_SIZE) / 1E6  ; km²
      minArea = 0.01  ; 最小面积 0.01 km²
      aggregateSize = FIX(minArea * 1E6 / PRODUCT(spatialRef.PIXEL_SIZE)) > 9
    ENDIF ELSE BEGIN
      aggregateSize = 50  ; 默认50个像元
    ENDELSE
    
    ; 方法1: 使用原始聚合参数
    IF aggregateSize GT 9 THEN BEGIN
      logMsg = '[' + year + '后处理]   方法1: 使用原始聚合参数（MINIMUM_SIZE=' + STRING(aggregateSize) + '）'
      PRINT, logMsg
      IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
        PRINTF, logLun, logMsg
        FLUSH, logLun
      ENDIF
      CATCH, errMethod1
      IF errMethod1 EQ 0 THEN BEGIN
        aggregateTask1 = ENVITask('ClassificationAggregation')
        aggregateTask1.INPUT_RASTER = smoothRaster
        aggregateTask1.MINIMUM_SIZE = aggregateSize
        tempOutput1 = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '_method1.dat'
        IF FILE_TEST(tempOutput1) THEN BEGIN
          FILE_DELETE, tempOutput1, /QUIET
          hdrFile1 = FILE_DIRNAME(tempOutput1) + PATH_SEP() + FILE_BASENAME(tempOutput1, '.dat') + '.hdr'
          IF FILE_TEST(hdrFile1) THEN FILE_DELETE, hdrFile1, /QUIET
        ENDIF
        aggregateTask1.OUTPUT_RASTER_URI = tempOutput1
        aggregateTask1.Execute
        tempRaster1 = aggregateTask1.OUTPUT_RASTER
        
        IF OBJ_VALID(tempRaster1) THEN BEGIN
          WAIT, 0.5
          tempRaster1.Close
          tempRaster1 = e.OpenRaster(tempOutput1)
          IF OBJ_VALID(tempRaster1) THEN BEGIN
            nColsTemp1 = tempRaster1.NCOLUMNS
            nRowsTemp1 = tempRaster1.NROWS
            nCols1 = LONG(nColsTemp1)
            nRows1 = LONG(nRowsTemp1)
            nCols1Minus1 = nCols1 - 1L
            nRows1Minus1 = nRows1 - 1L
            rectCols1 = MIN(500L, nCols1Minus1)
            rectRows1 = MIN(500L, nRows1Minus1)
            subRectArray1 = [0L, 0L, rectCols1, rectRows1]
            sample1 = tempRaster1.GetData(BANDS=0, SUB_RECT=subRectArray1)
            nonZero1 = N_ELEMENTS(WHERE(sample1 NE 0))
            minVal1 = MIN(sample1)
            maxVal1 = MAX(sample1)
            
            dataValid1 = (nonZero1 GT (N_ELEMENTS(sample1) * 0.1)) AND $
                        (maxVal1 LE (nClasses + 5)) AND (minVal1 GE -1)
            
            IF dataValid1 THEN BEGIN
              logMsg = '[' + year + '后处理]   ✓ 方法1成功，数据有效'
              PRINT, logMsg
              IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                PRINTF, logLun, logMsg
                FLUSH, logLun
              ENDIF
              tempRaster1.Close
              tempRaster1 = !NULL
              
              ; 等待文件完全关闭
              WAIT, 1.0
              
              ; 删除目标文件（如果存在）
              IF FILE_TEST(outputFile) THEN BEGIN
                FILE_DELETE, outputFile, /QUIET
                WAIT, 0.5
              ENDIF
              hdrFileFinal = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '.hdr'
              IF FILE_TEST(hdrFileFinal) THEN BEGIN
                FILE_DELETE, hdrFileFinal, /QUIET
                WAIT, 0.5
              ENDIF
              
              ; 重命名文件
              CATCH, errMove1
              IF errMove1 EQ 0 THEN BEGIN
                FILE_MOVE, tempOutput1, outputFile, /OVERWRITE
                WAIT, 0.5
                hdrFile1 = FILE_DIRNAME(tempOutput1) + PATH_SEP() + FILE_BASENAME(tempOutput1, '.dat') + '.hdr'
                IF FILE_TEST(hdrFile1) THEN BEGIN
                  FILE_MOVE, hdrFile1, hdrFileFinal, /OVERWRITE
                  WAIT, 0.5
                ENDIF
                CATCH, /CANCEL
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
                logMsg = '[' + year + '后处理]   警告: 文件重命名失败，尝试复制文件...'
                PRINT, logMsg
                IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                  PRINTF, logLun, logMsg
                  FLUSH, logLun
                ENDIF
                ; 如果重命名失败，尝试复制
                CATCH, errCopy1
                IF errCopy1 EQ 0 THEN BEGIN
                  FILE_COPY, tempOutput1, outputFile, /OVERWRITE
                  WAIT, 0.5
                  hdrFile1 = FILE_DIRNAME(tempOutput1) + PATH_SEP() + FILE_BASENAME(tempOutput1, '.dat') + '.hdr'
                  IF FILE_TEST(hdrFile1) THEN BEGIN
                    FILE_COPY, hdrFile1, hdrFileFinal, /OVERWRITE
                    WAIT, 0.5
                  ENDIF
                  FILE_DELETE, tempOutput1, /QUIET
                  IF FILE_TEST(hdrFile1) THEN FILE_DELETE, hdrFile1, /QUIET
                  ; 验证复制是否成功
                  IF FILE_TEST(outputFile) THEN BEGIN
                    logMsg = '[' + year + '后处理]   ✓ 文件复制成功'
                    PRINT, logMsg
                    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                      PRINTF, logLun, logMsg
                      FLUSH, logLun
                    ENDIF
                  ENDIF ELSE BEGIN
                    logMsg = '[' + year + '后处理]   错误: 文件复制后验证失败'
                    PRINT, logMsg
                    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                      PRINTF, logLun, logMsg
                      FLUSH, logLun
                    ENDIF
                  ENDELSE
                  CATCH, /CANCEL
                ENDIF ELSE BEGIN
                  CATCH, /CANCEL
                  logMsg = '[' + year + '后处理]   错误: 文件复制也失败: ' + !ERROR_STATE.MSG
                  PRINT, logMsg
                  IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                    PRINTF, logLun, logMsg
                    FLUSH, logLun
                  ENDIF
                ENDELSE
              ENDELSE
              
              WAIT, 1.0
              finalRaster = e.OpenRaster(outputFile)
              IF OBJ_VALID(finalRaster) THEN BEGIN
                methodUsed = '方法1（原始参数）'
                useAggregation = 1
              ENDIF
              CATCH, /CANCEL
            ENDIF ELSE BEGIN
              logMsg = '[' + year + '后处理]   ✗ 方法1失败，数据无效'
              PRINT, logMsg
              IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                PRINTF, logLun, logMsg
                FLUSH, logLun
              ENDIF
              tempRaster1.Close
              FILE_DELETE, tempOutput1, /QUIET
              hdrFile1 = FILE_DIRNAME(tempOutput1) + PATH_SEP() + FILE_BASENAME(tempOutput1, '.dat') + '.hdr'
              IF FILE_TEST(hdrFile1) THEN FILE_DELETE, hdrFile1, /QUIET
              CATCH, /CANCEL
            ENDELSE
          ENDIF
        ENDIF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        logMsg = '[' + year + '后处理]   ✗ 方法1执行失败: ' + !ERROR_STATE.MSG
        PRINT, logMsg
        IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
          PRINTF, logLun, logMsg
          FLUSH, logLun
        ENDIF
      ENDELSE
    ENDIF
    
    ; 方法2: 使用更小的聚合阈值
    IF useAggregation EQ 0 THEN BEGIN
      logMsg = '[' + year + '后处理]   方法2: 使用更小的聚合阈值（MINIMUM_SIZE=5）'
      PRINT, logMsg
      IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
        PRINTF, logLun, logMsg
        FLUSH, logLun
      ENDIF
      CATCH, errMethod2
      IF errMethod2 EQ 0 THEN BEGIN
        aggregateTask2 = ENVITask('ClassificationAggregation')
        aggregateTask2.INPUT_RASTER = smoothRaster
        aggregateTask2.MINIMUM_SIZE = 5
        tempOutput2 = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '_method2.dat'
        IF FILE_TEST(tempOutput2) THEN BEGIN
          FILE_DELETE, tempOutput2, /QUIET
          hdrFile2 = FILE_DIRNAME(tempOutput2) + PATH_SEP() + FILE_BASENAME(tempOutput2, '.dat') + '.hdr'
          IF FILE_TEST(hdrFile2) THEN FILE_DELETE, hdrFile2, /QUIET
        ENDIF
        aggregateTask2.OUTPUT_RASTER_URI = tempOutput2
        aggregateTask2.Execute
        tempRaster2 = aggregateTask2.OUTPUT_RASTER
        
        IF OBJ_VALID(tempRaster2) THEN BEGIN
          WAIT, 0.5
          tempRaster2.Close
          tempRaster2 = e.OpenRaster(tempOutput2)
          IF OBJ_VALID(tempRaster2) THEN BEGIN
            nColsTemp2 = tempRaster2.NCOLUMNS
            nRowsTemp2 = tempRaster2.NROWS
            nCols2 = LONG(nColsTemp2)
            nRows2 = LONG(nRowsTemp2)
            nCols2Minus1 = nCols2 - 1L
            nRows2Minus1 = nRows2 - 1L
            rectCols2 = MIN(500L, nCols2Minus1)
            rectRows2 = MIN(500L, nRows2Minus1)
            subRectArray2 = [0L, 0L, rectCols2, rectRows2]
            sample2 = tempRaster2.GetData(BANDS=0, SUB_RECT=subRectArray2)
            nonZero2 = N_ELEMENTS(WHERE(sample2 NE 0))
            minVal2 = MIN(sample2)
            maxVal2 = MAX(sample2)
            
            dataValid2 = (nonZero2 GT (N_ELEMENTS(sample2) * 0.1)) AND $
                        (maxVal2 LE (nClasses + 5)) AND (minVal2 GE -1)
            
            IF dataValid2 THEN BEGIN
              logMsg = '[' + year + '后处理]   ✓ 方法2成功，数据有效'
              PRINT, logMsg
              IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                PRINTF, logLun, logMsg
                FLUSH, logLun
              ENDIF
              tempRaster2.Close
              tempRaster2 = !NULL
              
              ; 等待文件完全关闭
              WAIT, 1.0
              
              ; 删除目标文件（如果存在）
              IF FILE_TEST(outputFile) THEN BEGIN
                FILE_DELETE, outputFile, /QUIET
                WAIT, 0.5
              ENDIF
              hdrFileFinal = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '.hdr'
              IF FILE_TEST(hdrFileFinal) THEN BEGIN
                FILE_DELETE, hdrFileFinal, /QUIET
                WAIT, 0.5
              ENDIF
              
              ; 重命名文件
              CATCH, errMove2
              IF errMove2 EQ 0 THEN BEGIN
                FILE_MOVE, tempOutput2, outputFile, /OVERWRITE
                WAIT, 0.5
                hdrFile2 = FILE_DIRNAME(tempOutput2) + PATH_SEP() + FILE_BASENAME(tempOutput2, '.dat') + '.hdr'
                IF FILE_TEST(hdrFile2) THEN BEGIN
                  FILE_MOVE, hdrFile2, hdrFileFinal, /OVERWRITE
                  WAIT, 0.5
                ENDIF
                CATCH, /CANCEL
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
                logMsg = '[' + year + '后处理]   警告: 文件重命名失败，尝试复制文件...'
                PRINT, logMsg
                IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                  PRINTF, logLun, logMsg
                  FLUSH, logLun
                ENDIF
                ; 如果重命名失败，尝试复制
                CATCH, errCopy2
                IF errCopy2 EQ 0 THEN BEGIN
                  FILE_COPY, tempOutput2, outputFile, /OVERWRITE
                  WAIT, 0.5
                  hdrFile2 = FILE_DIRNAME(tempOutput2) + PATH_SEP() + FILE_BASENAME(tempOutput2, '.dat') + '.hdr'
                  IF FILE_TEST(hdrFile2) THEN BEGIN
                    FILE_COPY, hdrFile2, hdrFileFinal, /OVERWRITE
                    WAIT, 0.5
                  ENDIF
                  FILE_DELETE, tempOutput2, /QUIET
                  IF FILE_TEST(hdrFile2) THEN FILE_DELETE, hdrFile2, /QUIET
                  ; 验证复制是否成功
                  IF FILE_TEST(outputFile) THEN BEGIN
                    logMsg = '[' + year + '后处理]   ✓ 文件复制成功'
                    PRINT, logMsg
                    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                      PRINTF, logLun, logMsg
                      FLUSH, logLun
                    ENDIF
                  ENDIF ELSE BEGIN
                    logMsg = '[' + year + '后处理]   错误: 文件复制后验证失败'
                    PRINT, logMsg
                    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                      PRINTF, logLun, logMsg
                      FLUSH, logLun
                    ENDIF
                  ENDELSE
                  CATCH, /CANCEL
                ENDIF ELSE BEGIN
                  CATCH, /CANCEL
                  logMsg = '[' + year + '后处理]   错误: 文件复制也失败: ' + !ERROR_STATE.MSG
                  PRINT, logMsg
                  IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                    PRINTF, logLun, logMsg
                    FLUSH, logLun
                  ENDIF
                ENDELSE
              ENDELSE
              
              WAIT, 1.0
              finalRaster = e.OpenRaster(outputFile)
              IF OBJ_VALID(finalRaster) THEN BEGIN
                methodUsed = '方法2（小阈值聚合）'
                useAggregation = 1
              ENDIF
              CATCH, /CANCEL
            ENDIF ELSE BEGIN
              logMsg = '[' + year + '后处理]   ✗ 方法2失败，数据无效'
              PRINT, logMsg
              IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
                PRINTF, logLun, logMsg
                FLUSH, logLun
              ENDIF
              tempRaster2.Close
              FILE_DELETE, tempOutput2, /QUIET
              hdrFile2 = FILE_DIRNAME(tempOutput2) + PATH_SEP() + FILE_BASENAME(tempOutput2, '.dat') + '.hdr'
              IF FILE_TEST(hdrFile2) THEN FILE_DELETE, hdrFile2, /QUIET
              CATCH, /CANCEL
            ENDELSE
          ENDIF
        ENDIF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        logMsg = '[' + year + '后处理]   ✗ 方法2执行失败: ' + !ERROR_STATE.MSG
        PRINT, logMsg
        IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
          PRINTF, logLun, logMsg
          FLUSH, logLun
        ENDIF
      ENDELSE
    ENDIF
    
    ; 方法3: 跳过聚合，直接使用平滑结果
    IF useAggregation EQ 0 THEN BEGIN
      logMsg = '[' + year + '后处理]   方法3: 跳过聚合，直接使用平滑结果'
      PRINT, logMsg
      IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
        PRINTF, logLun, logMsg
        FLUSH, logLun
      ENDIF
      
      ; 删除已存在的输出文件
      IF FILE_TEST(outputFile) THEN BEGIN
        FILE_DELETE, outputFile, /QUIET
        WAIT, 0.5
      ENDIF
      hdrFileFinal = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '.hdr'
      IF FILE_TEST(hdrFileFinal) THEN BEGIN
        FILE_DELETE, hdrFileFinal, /QUIET
        WAIT, 0.5
      ENDIF
      
      CATCH, errExport3
      IF errExport3 EQ 0 THEN BEGIN
        smoothRaster.Export, outputFile, 'ENVI'
        WAIT, 1.0
        finalRaster = e.OpenRaster(outputFile)
        IF OBJ_VALID(finalRaster) THEN BEGIN
          methodUsed = '方法3（仅平滑，无聚合）'
        ENDIF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        logMsg = '[' + year + '后处理]   错误: 导出失败: ' + !ERROR_STATE.MSG
        PRINT, logMsg
        IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
          PRINTF, logLun, logMsg
          FLUSH, logLun
        ENDIF
        finalRaster = !NULL
      ENDELSE
    ENDIF
    
    ; 关闭平滑结果（如果使用了聚合方法）
    IF OBJ_VALID(smoothRaster) AND (useAggregation EQ 1) THEN BEGIN
      smoothRaster.Close
      smoothRaster = !NULL
    ENDIF
  ENDELSE
  
  logMsg = '[' + year + '后处理] 使用的处理方法: ' + methodUsed
  PRINT, logMsg
  IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
    PRINTF, logLun, logMsg
    FLUSH, logLun
  ENDIF
  
  ; ============================================
  ; 步骤4: 更新元数据（包括颜色设置）
  ; ============================================
  IF ~OBJ_VALID(finalRaster) THEN BEGIN
    logMsg = '[' + year + '后处理] 错误: 无法打开最终输出文件'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    RETURN, !NULL
  ENDIF
  
  logMsg = '[' + year + '后处理] 步骤4: 更新元数据...'
  PRINT, logMsg
  IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
    PRINTF, logLun, logMsg
    FLUSH, logLun
  ENDIF
  WAIT, 1.0
  
  ; 关闭并重新打开以确保可以更新元数据
  finalRaster.Close
  WAIT, 0.5
  finalRaster = e.OpenRaster(outputFile)
  
  IF ~OBJ_VALID(finalRaster) THEN BEGIN
    logMsg = '[' + year + '后处理] 错误: 无法重新打开输出文件'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    RETURN, !NULL
  ENDIF
  
  ; 创建类别名称数组（包含未分类）
  nTotalClasses = nClasses + 1
  classNamesWithUnclassified = STRARR(nTotalClasses)
  classNamesWithUnclassified[0] = 'Unclassified'
  FOR i=0, nClasses-1 DO BEGIN
    IF i LT N_ELEMENTS(classNames) THEN BEGIN
      classNamesWithUnclassified[i+1] = classNames[i]
    ENDIF ELSE BEGIN
      classNamesWithUnclassified[i+1] = 'Class ' + STRING(i+1)
    ENDELSE
  ENDFOR
  
  ; 创建颜色查找表（植被=绿色，水体=蓝色，其他=灰色）
  classRGB = INTARR(3, nTotalClasses)
  classRGB[*, 0] = [0, 0, 0]  ; 黑色 - 未分类
  
  FOR i=0, nClasses-1 DO BEGIN
    className = STRUPCASE(classNamesWithUnclassified[i+1])
    
    ; 植被 - 绿色 RGB(0, 255, 0)
    IF STRMATCH(className, '*植被*') OR STRMATCH(className, '*VEG*') OR STRMATCH(className, '*植*') OR $
       STRMATCH(className, '*VEGETATION*') OR STRMATCH(className, '*植物*') THEN BEGIN
      classRGB[*, i+1] = [0, 255, 0]  ; 绿色
    ENDIF ELSE IF STRMATCH(className, '*水体*') OR STRMATCH(className, '*WATER*') OR STRMATCH(className, '*水*') THEN BEGIN
      ; 水体 - 蓝色 RGB(0, 0, 255)
      classRGB[*, i+1] = [0, 0, 255]  ; 蓝色
    ENDIF ELSE IF STRMATCH(className, '*其他*') OR STRMATCH(className, '*OTHER*') OR STRMATCH(className, '*其*') OR $
                STRMATCH(className, '*其它*') THEN BEGIN
      ; 其他 - 灰色 RGB(128, 128, 128)
      classRGB[*, i+1] = [128, 128, 128]  ; 灰色
    ENDIF ELSE BEGIN
      ; 根据首字符匹配
      firstChar = STRMID(className, 0, 1)
      IF (firstChar EQ '植') OR (firstChar EQ 'V') THEN BEGIN
        classRGB[*, i+1] = [0, 255, 0]  ; 绿色
      ENDIF ELSE IF (firstChar EQ '水') OR (firstChar EQ 'W') THEN BEGIN
        classRGB[*, i+1] = [0, 0, 255]  ; 蓝色
      ENDIF ELSE IF (firstChar EQ '其') OR (firstChar EQ 'O') THEN BEGIN
        classRGB[*, i+1] = [128, 128, 128]  ; 灰色
      ENDIF ELSE BEGIN
        ; 默认颜色（根据索引）
        CASE i MOD 6 OF
          0: classRGB[*, i+1] = [0, 255, 0]    ; 绿色
          1: classRGB[*, i+1] = [0, 0, 255]    ; 蓝色
          2: classRGB[*, i+1] = [128, 128, 128] ; 灰色
          3: classRGB[*, i+1] = [255, 255, 0]  ; 黄色
          4: classRGB[*, i+1] = [255, 0, 255]  ; 洋红
          5: classRGB[*, i+1] = [0, 255, 255]  ; 青色
        ENDCASE
      ENDELSE
    ENDELSE
  ENDFOR
  
  ; 设置元数据
  CATCH, errMetadata
  IF errMetadata EQ 0 THEN BEGIN
    ; 设置classes
    IF ~finalRaster.METADATA.HasTag('classes') THEN BEGIN
      finalRaster.METADATA.AddItem, 'classes', nTotalClasses
    ENDIF ELSE BEGIN
      finalRaster.METADATA.UpdateItem, 'classes', nTotalClasses
    ENDELSE
    
    ; 设置class names
    IF ~finalRaster.METADATA.HasTag('class names') THEN BEGIN
      finalRaster.METADATA.AddItem, 'class names', classNamesWithUnclassified
    ENDIF ELSE BEGIN
      finalRaster.METADATA.UpdateItem, 'class names', classNamesWithUnclassified
    ENDELSE
    
    ; 设置class lookup（使用3×N格式）
    IF ~finalRaster.METADATA.HasTag('class lookup') THEN BEGIN
      finalRaster.METADATA.AddItem, 'class lookup', classRGB
    ENDIF ELSE BEGIN
      finalRaster.METADATA.UpdateItem, 'class lookup', classRGB
    ENDELSE
    
    ; 写入元数据
    finalRaster.WriteMetadata
    logMsg = '[' + year + '后处理]   ✓ 元数据更新完成'
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    logMsg = '[' + year + '后处理] 警告: 更新元数据失败: ' + !ERROR_STATE.MSG
    PRINT, logMsg
    IF ARG_PRESENT(logLun) && (logLun GT 0) THEN BEGIN
      PRINTF, logLun, logMsg
      FLUSH, logLun
    ENDIF
  ENDELSE
  
  RETURN, finalRaster
END

PRO test1110_finalndvi

  COMPILE_OPT IDL2

  ; ============================================
  ; 初始化日志系统
  ; ============================================
  ; 声明COMMON块（仅用于日志文件句柄）
  COMMON LOG_COMMON, logLun
  
  logFile = 'E:\1027IDL\ENVITaskTrainning\02_ENVITasks\test1110_finalndvi.log'
  OPENW, logLun, logFile, /GET_LUN, /APPEND
  logTime = SYSTIME()
  PRINTF, logLun, ''
  PRINTF, logLun, '========================================'
  PRINTF, logLun, '程序开始执行: ' + STRING(logTime)
  PRINTF, logLun, '========================================'
  FLUSH, logLun
  log_write, '日志系统初始化完成'

  ; 错误处理
  CATCH, err
  IF (err NE 0) THEN BEGIN
    CATCH, /CANCEL
    errorMsg = '程序异常: ' + !ERROR_STATE.MSG + ' (Code: ' + STRING(!ERROR_STATE.CODE) + ')'
    PRINT, errorMsg
    log_error, errorMsg, !ERROR_STATE
    CLOSE, logLun
    FREE_LUN, logLun
    RETURN
  ENDIF

  ; 启动ENVI
  log_write, '正在启动ENVI...'
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()
  IF OBJ_VALID(e) THEN BEGIN
    log_write, 'ENVI启动成功'
    
    ; 设置ENVI临时文件目录
    ; 注意：ENVI可能不支持SetPreference方法，我们通过环境变量或直接使用GetTemporaryFilename
    ; 临时目录会在程序中使用固定路径
    tempDirForENVI = 'E:\1027IDL\ENVITaskTrainning\Temp'
    IF ~FILE_TEST(tempDirForENVI, /DIRECTORY) THEN FILE_MKDIR, tempDirForENVI
    log_write, '临时文件目录: ' + tempDirForENVI
    PRINT, '临时文件目录: ' + tempDirForENVI
    ; 注意：ENVI的GetTemporaryFilename会使用ENVI的首选项设置
    ; 如果需要更改，请在ENVI GUI中设置：File > Preferences > Temporary Directory
  ENDIF ELSE BEGIN
    log_error, 'ENVI启动失败'
    CLOSE, logLun
    FREE_LUN, logLun
    RETURN
  ENDELSE

  ; ============================================
  ; 1. 设置数据路径和参数
  ; ============================================
  PRINT, ''
  PRINT, '========================================='
  PRINT, 'LC09数据随机森林监督分类与变化分析'
  PRINT, '========================================='
  PRINT, ''

  ; 2021年数据路径
  dataPath2021 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1'
  mtlFiles2021 = FILE_SEARCH(dataPath2021, '*_MTL.txt', COUNT=count2021)
  IF count2021 EQ 0 THEN BEGIN
    PRINT, '错误: 未找到2021年MTL文件: ' + dataPath2021
    RETURN
  ENDIF
  mtlFile2021 = mtlFiles2021[0]  ; 获取第一个文件（标量字符串）

  ; 2025年数据路径
  dataPath2025 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20250827_20250828_02_T1'
  has2025Data = 0  ; 初始化标志
  mtlFiles2025 = FILE_SEARCH(dataPath2025, '*_MTL.txt', COUNT=count2025)
    IF count2025 EQ 0 THEN BEGIN
    PRINT, '警告: 未找到2025年MTL文件: ' + dataPath2025
    PRINT, '将只处理2021年数据'
      dataPath2025 = ''
    mtlFile2025 = ''
  ENDIF ELSE BEGIN
    has2025Data = 1  ; 找到2025年数据
    mtlFile2025 = mtlFiles2025[0]  ; 获取第一个文件（标量字符串）
    PRINT, '✓ 找到2025年数据: ' + dataPath2025
  ENDELSE

  ; ROI文件路径
  roiFile2021 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1\1110.xml'  ; 2021年ROI
  roiFile2025 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1\1111.xml'  ; 2025年ROI
  
  IF ~FILE_TEST(roiFile2021) THEN BEGIN
    PRINT, '警告: 未找到2021年ROI文件: ' + roiFile2021
    PRINT, '请检查ROI文件路径是否正确'
    ; 继续执行，但会在后续步骤中检查
  ENDIF ELSE BEGIN
    PRINT, '✓ 找到2021年ROI文件: ' + roiFile2021
  ENDELSE
  
  IF ~FILE_TEST(roiFile2025) THEN BEGIN
    PRINT, '警告: 未找到2025年ROI文件: ' + roiFile2025
    PRINT, '请检查ROI文件路径是否正确'
    PRINT, '注意: 如果2025年数据存在，将使用2021年的ROI作为备用'
  ENDIF ELSE BEGIN
    PRINT, '✓ 找到2025年ROI文件: ' + roiFile2025
  ENDELSE

  ; 输出目录
  outputDir = dataPath2021 + PATH_SEP() + 'results'
  IF ~FILE_TEST(outputDir) THEN FILE_MKDIR, outputDir
  
  ; 临时文件目录（保存到COMMON块中，供其他函数使用）
  tempDir = 'E:\1027IDL\ENVITaskTrainning\Temp'
  IF ~FILE_TEST(tempDir, /DIRECTORY) THEN BEGIN
    FILE_MKDIR, tempDir
    log_write, '已创建临时文件目录: ' + tempDir
  ENDIF ELSE BEGIN
    log_write, '临时文件目录已存在: ' + tempDir
  ENDELSE

  ; ============================================
  ; 2. 处理2021年数据
  ; ============================================
  PRINT, '========== 处理2021年数据 =========='
  PRINT, 'MTL文件: ' + mtlFile2021

  ; 打开2021年数据
  ; 方法1：尝试使用DATASET_NAME参数打开Surface Reflectance数据（推荐方法）
  PRINT, '正在打开2021年数据...'
  raster2021 = !NULL
  spatialRef2021 = !NULL
  
  ; 尝试方法1：使用DATASET_NAME参数
  CATCH, err1
  IF err1 EQ 0 THEN BEGIN
    tempRaster = e.OpenRaster(mtlFile2021, DATASET_NAME='Surface Reflectance')
    CATCH, /CANCEL
    ; 检查返回值是否是数组
    IF tempRaster NE !NULL THEN BEGIN
      IF N_ELEMENTS(tempRaster) GT 1 THEN BEGIN
        raster2021 = tempRaster[0]  ; 如果是数组，取第一个元素
      ENDIF ELSE BEGIN
        raster2021 = tempRaster  ; 如果是单个对象，直接使用
      ENDELSE
    ENDIF
    IF OBJ_VALID(raster2021) THEN BEGIN
      spatialRef2021 = raster2021.SPATIALREF
      IF OBJ_VALID(spatialRef2021) THEN BEGIN
        PRINT, '✓ 使用方法1（DATASET_NAME）成功打开数据，空间参考信息完整'
      ENDIF
    ENDIF
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
  ENDELSE
  
  ; 方法2：如果方法1失败，尝试使用ExtractRasterFromFileTask
  IF ~OBJ_VALID(raster2021) OR ~OBJ_VALID(spatialRef2021) THEN BEGIN
    PRINT, '方法1失败，尝试方法2：使用ExtractRasterFromFileTask...'
    CATCH, err2
    IF err2 EQ 0 THEN BEGIN
      extractTask = ENVITask('ExtractRasterFromFile')
      extractTask.INPUT_URI = mtlFile2021
      extractTask.DATASET_NAME = 'Surface Reflectance'
      extractTask.Execute
      tempRaster = extractTask.OUTPUT_RASTER
      CATCH, /CANCEL
      ; 检查返回值是否是数组
      IF tempRaster NE !NULL THEN BEGIN
        IF N_ELEMENTS(tempRaster) GT 1 THEN BEGIN
          raster2021 = tempRaster[0]  ; 如果是数组，取第一个元素
        ENDIF ELSE BEGIN
          raster2021 = tempRaster  ; 如果是单个对象，直接使用
        ENDELSE
      ENDIF
      IF OBJ_VALID(raster2021) THEN BEGIN
        spatialRef2021 = raster2021.SPATIALREF
        IF OBJ_VALID(spatialRef2021) THEN BEGIN
          PRINT, '✓ 使用方法2（ExtractRasterFromFileTask）成功打开数据，空间参考信息完整'
        ENDIF
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  
  ; 方法3：如果前两种方法都失败，使用默认方式打开（返回数组）
  IF ~OBJ_VALID(raster2021) OR ~OBJ_VALID(spatialRef2021) THEN BEGIN
    PRINT, '方法2失败，尝试方法3：使用默认方式打开MTL文件...'
  rasters2021 = e.OpenRaster(mtlFile2021)
    raster2021 = rasters2021[0]  ; 第一个元素是多光谱数据
    spatialRef2021 = raster2021.SPATIALREF
    IF OBJ_VALID(spatialRef2021) THEN BEGIN
      PRINT, '✓ 使用方法3（默认方式）成功打开数据，空间参考信息完整'
    ENDIF
  ENDIF
  
  ; 检查是否成功打开数据
  IF ~OBJ_VALID(raster2021) THEN BEGIN
    PRINT, '错误: 无法打开2021年数据'
    RETURN
  ENDIF
  
  PRINT, '✓ 成功打开2021年数据'
  PRINT, '  影像尺寸: ' + STRING(raster2021.NCOLUMNS) + ' x ' + STRING(raster2021.NROWS)
  PRINT, '  波段数: ' + STRING(raster2021.NBANDS)
  
  ; 检查空间参考
  IF ~OBJ_VALID(spatialRef2021) THEN BEGIN
    PRINT, '警告: 从MTL文件打开的数据没有空间参考信息'
    PRINT, '正在从MTL XML文件读取投影参数并创建空间参考...'
    
    ; 从MTL XML文件读取投影参数
    ; 构建MTL XML文件路径（与MTL.txt在同一目录）
    mtlXmlFile = FILE_DIRNAME(mtlFile2021) + PATH_SEP() + FILE_BASENAME(mtlFile2021, '.txt') + '.xml'
    IF FILE_TEST(mtlXmlFile) THEN BEGIN
      PRINT, '找到MTL XML文件: ' + FILE_BASENAME(mtlXmlFile)
      mapInfo2021 = create_spatial_ref_from_mtl_xml(mtlXmlFile, raster2021.NCOLUMNS, raster2021.NROWS)
      ; 检查mapInfo是否创建成功（mapInfo是结构体，不是对象，不能用OBJ_VALID）
      IF mapInfo2021 EQ !NULL THEN BEGIN
        PRINT, '错误: create_spatial_ref_from_mtl_xml返回!NULL'
        PRINT, '请检查ENVI_MAP_INFO_CREATE函数是否正常工作'
        RETURN
      ENDIF
      nElements2021 = N_ELEMENTS(mapInfo2021)
      IF nElements2021 GT 0 THEN BEGIN
        PRINT, '✓ 成功从MTL XML文件创建空间参考信息 (N_ELEMENTS=' + STRING(nElements2021) + ')'
        ; 为raster设置空间参考
        raster2021 = set_spatial_ref_to_raster(raster2021, mapInfo2021)
        IF OBJ_VALID(raster2021) THEN BEGIN
          spatialRef2021 = raster2021.SPATIALREF
          IF OBJ_VALID(spatialRef2021) THEN BEGIN
            PRINT, '✓ 成功为raster设置空间参考信息'
          ENDIF ELSE BEGIN
            PRINT, '错误: 无法设置空间参考信息（spatialRef无效）'
            RETURN
          ENDELSE
        ENDIF ELSE BEGIN
          PRINT, '错误: 设置空间参考后raster无效'
          RETURN
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '错误: 无法从MTL XML文件创建空间参考信息 (N_ELEMENTS=' + STRING(nElements2021) + ')'
        PRINT, 'ENVI_MAP_INFO_CREATE可能返回了空结构体'
        RETURN
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: 未找到MTL XML文件: ' + mtlXmlFile
      RETURN
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '✓ 空间参考信息: ' + STRUPCASE(STRMID(spatialRef2021.COORD_SYS_STR, 0, 60))
  ENDELSE

  ; 计算NDVI
  PRINT, '正在计算NDVI...'
  ndvi2021 = ENVISpectralIndexRaster(raster2021, 'NDVI')
  PRINT, '✓ NDVI计算完成'

  ; 计算NDBI
  PRINT, '正在计算NDBI...'
  ndbi2021 = ENVISpectralIndexRaster(raster2021, 'NDBI')
  PRINT, '✓ NDBI计算完成'

  ; 合并原始波段、NDVI和NDBI
  PRINT, '正在合并波段（原始波段 + NDVI + NDBI）...'
  buildStackTask2021 = ENVITask('BuildLayerStack')
  buildStackTask2021.INPUT_RASTERS = [raster2021, ndvi2021, ndbi2021]
  buildStackTask2021.Execute
  stackedRaster2021 = buildStackTask2021.OUTPUT_RASTER
  PRINT, '✓ 波段合并完成，总波段数: ' + STRING(stackedRaster2021.NBANDS)
  
  ; 释放NDVI和NDBI的内存（如果不再需要单独的raster对象）
  ; 注意：stackedRaster2021中已经包含了这些波段，所以可以关闭单独的raster
  ; 但是为了安全，我们先不关闭，因为它们可能在后面对比分析中需要

  ; ============================================
  ; 3. 处理2025年数据（如果存在）
  ; ============================================
  raster2025 = !NULL
  stackedRaster2025 = !NULL
  ndvi2025 = !NULL
  ndbi2025 = !NULL
  pixelArea2025 = 0.0
  ndviStats2021 = !NULL
  ndviStats2025 = !NULL
  ndviMeanChange = !NULL  ; 标量值，使用!NULL初始化
  ndviDiffStats = !NULL
  hasNDVIStats = 0  ; 标志变量，表示是否计算了NDVI统计

  ; 检查是否找到2025年数据（在前面已经检查过）
  IF STRLEN(dataPath2025) GT 0 && count2025 GT 0 THEN BEGIN
    PRINT, ''
    PRINT, '========== 处理2025年数据 =========='
    PRINT, 'MTL文件: ' + mtlFile2025

    ; 打开2025年数据
    ; 方法1：尝试使用DATASET_NAME参数打开Surface Reflectance数据（推荐方法）
    PRINT, '正在打开2025年数据...'
    raster2025 = !NULL
    spatialRef2025 = !NULL
    
    ; 尝试方法1：使用DATASET_NAME参数
    CATCH, err3
    IF err3 EQ 0 THEN BEGIN
      tempRaster = e.OpenRaster(mtlFile2025, DATASET_NAME='Surface Reflectance')
      CATCH, /CANCEL
      ; 检查返回值是否是数组
      IF tempRaster NE !NULL THEN BEGIN
        IF N_ELEMENTS(tempRaster) GT 1 THEN BEGIN
          raster2025 = tempRaster[0]  ; 如果是数组，取第一个元素
        ENDIF ELSE BEGIN
          raster2025 = tempRaster  ; 如果是单个对象，直接使用
        ENDELSE
      ENDIF
      IF OBJ_VALID(raster2025) THEN BEGIN
        spatialRef2025 = raster2025.SPATIALREF
        IF OBJ_VALID(spatialRef2025) THEN BEGIN
          PRINT, '✓ 使用方法1（DATASET_NAME）成功打开数据，空间参考信息完整'
        ENDIF
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
    
    ; 方法2：如果方法1失败，尝试使用ExtractRasterFromFileTask
    IF ~OBJ_VALID(raster2025) OR ~OBJ_VALID(spatialRef2025) THEN BEGIN
      PRINT, '方法1失败，尝试方法2：使用ExtractRasterFromFileTask...'
      CATCH, err4
      IF err4 EQ 0 THEN BEGIN
        extractTask2025 = ENVITask('ExtractRasterFromFile')
        extractTask2025.INPUT_URI = mtlFile2025
        extractTask2025.DATASET_NAME = 'Surface Reflectance'
        extractTask2025.Execute
        tempRaster = extractTask2025.OUTPUT_RASTER
        CATCH, /CANCEL
        ; 检查返回值是否是数组
        IF tempRaster NE !NULL THEN BEGIN
          IF N_ELEMENTS(tempRaster) GT 1 THEN BEGIN
            raster2025 = tempRaster[0]  ; 如果是数组，取第一个元素
          ENDIF ELSE BEGIN
            raster2025 = tempRaster  ; 如果是单个对象，直接使用
          ENDELSE
        ENDIF
        IF OBJ_VALID(raster2025) THEN BEGIN
          spatialRef2025 = raster2025.SPATIALREF
          IF OBJ_VALID(spatialRef2025) THEN BEGIN
            PRINT, '✓ 使用方法2（ExtractRasterFromFileTask）成功打开数据，空间参考信息完整'
          ENDIF
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF
    
    ; 方法3：如果前两种方法都失败，使用默认方式打开（返回数组）
    IF ~OBJ_VALID(raster2025) OR ~OBJ_VALID(spatialRef2025) THEN BEGIN
      PRINT, '方法2失败，尝试方法3：使用默认方式打开MTL文件...'
    rasters2025 = e.OpenRaster(mtlFile2025)
      raster2025 = rasters2025[0]  ; 第一个元素是多光谱数据
      spatialRef2025 = raster2025.SPATIALREF
      IF OBJ_VALID(spatialRef2025) THEN BEGIN
        PRINT, '✓ 使用方法3（默认方式）成功打开数据，空间参考信息完整'
      ENDIF
    ENDIF
    
    ; 检查是否成功打开数据
    IF OBJ_VALID(raster2025) THEN BEGIN
    PRINT, '✓ 成功打开2025年数据'
    PRINT, '  影像尺寸: ' + STRING(raster2025.NCOLUMNS) + ' x ' + STRING(raster2025.NROWS)
    PRINT, '  波段数: ' + STRING(raster2025.NBANDS)
      
      ; 检查空间参考
      IF ~OBJ_VALID(spatialRef2025) THEN BEGIN
        PRINT, '警告: 从MTL文件打开的数据没有空间参考信息'
        PRINT, '正在从MTL XML文件读取投影参数并创建空间参考...'
        
        ; 从MTL XML文件读取投影参数
        ; 构建MTL XML文件路径（与MTL.txt在同一目录）
        mtlXmlFile2025 = FILE_DIRNAME(mtlFile2025) + PATH_SEP() + FILE_BASENAME(mtlFile2025, '.txt') + '.xml'
        IF FILE_TEST(mtlXmlFile2025) THEN BEGIN
          PRINT, '找到MTL XML文件: ' + FILE_BASENAME(mtlXmlFile2025)
        mapInfo2025 = create_spatial_ref_from_mtl_xml(mtlXmlFile2025, raster2025.NCOLUMNS, raster2025.NROWS)
        ; 检查mapInfo是否创建成功（mapInfo是结构体，不是对象，不能用OBJ_VALID）
        IF mapInfo2025 NE !NULL && N_ELEMENTS(mapInfo2025) GT 0 THEN BEGIN
          PRINT, '✓ 成功从MTL XML文件创建空间参考信息'
          ; 为raster设置空间参考
          raster2025 = set_spatial_ref_to_raster(raster2025, mapInfo2025)
          IF OBJ_VALID(raster2025) THEN BEGIN
            spatialRef2025 = raster2025.SPATIALREF
            IF OBJ_VALID(spatialRef2025) THEN BEGIN
              PRINT, '✓ 成功为raster设置空间参考信息'
            ENDIF ELSE BEGIN
              PRINT, '错误: 无法设置空间参考信息'
              has2025Data = 0  ; 标记为没有2025年数据
            ENDELSE
          ENDIF ELSE BEGIN
            PRINT, '错误: 设置空间参考后raster无效'
            has2025Data = 0  ; 标记为没有2025年数据
          ENDELSE
        ENDIF ELSE BEGIN
          PRINT, '错误: 无法从MTL XML文件创建空间参考信息'
          has2025Data = 0  ; 标记为没有2025年数据
        ENDELSE
        ENDIF ELSE BEGIN
          PRINT, '错误: 未找到MTL XML文件: ' + mtlXmlFile2025
          has2025Data = 0  ; 标记为没有2025年数据
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '✓ 空间参考信息: ' + STRUPCASE(STRMID(spatialRef2025.COORD_SYS_STR, 0, 60))
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: 无法打开2025年数据'
      has2025Data = 0  ; 标记为没有2025年数据
    ENDELSE

    ; 计算NDVI
    PRINT, '正在计算NDVI...'
    ndvi2025 = ENVISpectralIndexRaster(raster2025, 'NDVI')
    PRINT, '✓ NDVI计算完成'

    ; 计算NDBI
    PRINT, '正在计算NDBI...'
    ndbi2025 = ENVISpectralIndexRaster(raster2025, 'NDBI')
    PRINT, '✓ NDBI计算完成'

    ; 合并波段
    PRINT, '正在合并波段（原始波段 + NDVI + NDBI）...'
    buildStackTask2025 = ENVITask('BuildLayerStack')
    buildStackTask2025.INPUT_RASTERS = [raster2025, ndvi2025, ndbi2025]
    buildStackTask2025.Execute
    stackedRaster2025 = buildStackTask2025.OUTPUT_RASTER
    PRINT, '✓ 波段合并完成，总波段数: ' + STRING(stackedRaster2025.NBANDS)
  ENDIF

  ; ============================================
  ; 4. 监督分类（使用ROI）
  ; ============================================
  PRINT, ''
  PRINT, '========== 随机森林监督分类 =========='

  ; 检查ROI文件
  IF ~FILE_TEST(roiFile2021) THEN BEGIN
    PRINT, '错误: 2021年ROI文件不存在，无法进行监督分类'
    PRINT, '请先在ENVI中标记ROI并保存为: ' + roiFile2021
    RETURN
  ENDIF

  ; 打开ROI
  ; 加载2021年ROI
  rois = e.OpenROI(roiFile2021)
  PRINT, '✓ 成功加载2021年ROI: ' + roiFile2021
  PRINT, '  ROI数量: ' + STRING(N_ELEMENTS(rois))

  ; 显示2021年ROI信息
  FOR i=0, N_ELEMENTS(rois)-1 DO BEGIN
    PRINT, '  ROI ' + STRING(i+1) + ': ' + rois[i].NAME + ' (颜色: ' + STRING(rois[i].COLOR) + ')'
  ENDFOR

  ; 提取2021年类别名称（从ROI名称中获取）
  nClasses = N_ELEMENTS(rois)
  classNames = STRARR(nClasses)
  FOR i=0, nClasses-1 DO BEGIN
    classNames[i] = rois[i].NAME
  ENDFOR
  PRINT, '✓ 2021年训练样本类别数: ' + STRING(nClasses)
  FOR i=0, nClasses-1 DO BEGIN
    PRINT, '  类别 ' + STRING(i+1) + ': ' + classNames[i]
  ENDFOR
  
  ; 加载2025年ROI（如果存在）
  rois2025 = !NULL
  nClasses2025 = 0  ; 初始化为0，表示未定义
  classNames2025 = !NULL
  has2025ROI = 0  ; 标志：是否有2025年ROI
  IF has2025Data AND FILE_TEST(roiFile2025) THEN BEGIN
    rois2025 = e.OpenROI(roiFile2025)
    PRINT, '✓ 成功加载2025年ROI: ' + roiFile2025
    PRINT, '  ROI数量: ' + STRING(N_ELEMENTS(rois2025))
    
    ; 显示2025年ROI信息
    FOR i=0, N_ELEMENTS(rois2025)-1 DO BEGIN
      PRINT, '  ROI ' + STRING(i+1) + ': ' + rois2025[i].NAME + ' (颜色: ' + STRING(rois2025[i].COLOR) + ')'
  ENDFOR

    ; 提取2025年类别名称
    nClasses2025 = N_ELEMENTS(rois2025)
    classNames2025 = STRARR(nClasses2025)
    FOR i=0, nClasses2025-1 DO BEGIN
      classNames2025[i] = rois2025[i].NAME
    ENDFOR
    has2025ROI = 1  ; 标记为有2025年ROI
    PRINT, '✓ 2025年训练样本类别数: ' + STRING(nClasses2025)
    FOR i=0, nClasses2025-1 DO BEGIN
      PRINT, '  类别 ' + STRING(i+1) + ': ' + classNames2025[i]
    ENDFOR
  ENDIF ELSE IF has2025Data THEN BEGIN
    PRINT, '警告: 2025年ROI文件不存在，将使用2021年ROI'
    rois2025 = rois  ; 使用2021年ROI作为备用
    nClasses2025 = nClasses
    classNames2025 = classNames
    has2025ROI = 0  ; 标记为使用2021年ROI
  ENDIF ELSE BEGIN
    rois2025 = !NULL
    has2025ROI = 0
  ENDELSE

  ; 随机森林分类 - 2021年
  PRINT, '正在进行2021年随机森林分类（这可能需要几分钟）...'
  outputClass2021 = outputDir + PATH_SEP() + 'classification_2021.dat'
  
  ; 检查并删除已存在的文件（包括可能损坏的文件）
  ; 注意：如果程序之前崩溃，文件很可能不完整，打开损坏的文件可能导致崩溃
  ; 因此我们采用保守策略：只检查文件大小，不尝试打开文件
  IF FILE_TEST(outputClass2021) THEN BEGIN
    log_write, '发现已存在的输出文件，正在检查...'
    FLUSH, logLun
    PRINT, '发现已存在的输出文件，正在检查...'
    
    ; 计算期望的文件大小
    ; 注意：RandomForestClassification的输出通常是uint8（1字节/像素）
    nPixels = stackedRaster2021.NCOLUMNS * stackedRaster2021.NROWS
    expectedSizeUint8 = nPixels * 1  ; uint8: 1字节/像素
    expectedSizeUint16 = nPixels * 2  ; uint16: 2字节/像素
    
    ; 检查文件大小
    fileInfo = FILE_INFO(outputClass2021)
    fileSize = fileInfo[0].size
    log_write, '  文件大小: ' + STRING(fileSize/1024/1024, FORMAT='(F8.2)') + ' MB'
    log_write, '  期望大小(uint8): ' + STRING(expectedSizeUint8/1024/1024, FORMAT='(F8.2)') + ' MB'
    log_write, '  期望大小(uint16): ' + STRING(expectedSizeUint16/1024/1024, FORMAT='(F8.2)') + ' MB'
    PRINT, '  文件大小: ' + STRING(fileSize/1024/1024, FORMAT='(F8.2)') + ' MB'
    PRINT, '  期望大小(uint8): ' + STRING(expectedSizeUint8/1024/1024, FORMAT='(F8.2)') + ' MB'
    PRINT, '  期望大小(uint16): ' + STRING(expectedSizeUint16/1024/1024, FORMAT='(F8.2)') + ' MB'
    FLUSH, logLun
    
    ; 检查文件大小是否在合理范围内（允许10%的误差）
    sizeRatioUint8 = FLOAT(fileSize) / FLOAT(expectedSizeUint8)
    sizeRatioUint16 = FLOAT(fileSize) / FLOAT(expectedSizeUint16)
    isValidUint8 = (sizeRatioUint8 GE 0.9) AND (sizeRatioUint8 LE 1.1)
    isValidUint16 = (sizeRatioUint16 GE 0.9) AND (sizeRatioUint16 LE 1.1)
    
    ; 如果文件大小异常小（既不符合uint8也不符合uint16），认为是损坏的文件
    IF ~isValidUint8 AND ~isValidUint16 THEN BEGIN
      log_write, '  文件大小异常小，可能是崩溃时的不完整文件，将删除'
      PRINT, '  文件大小异常小，可能是崩溃时的不完整文件，正在删除...'
      FLUSH, logLun
      FILE_DELETE, outputClass2021, /QUIET
      hdrFile = FILE_DIRNAME(outputClass2021) + PATH_SEP() + FILE_BASENAME(outputClass2021, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      log_write, '  损坏的文件已删除'
      PRINT, '  ✓ 损坏的文件已删除'
      FLUSH, logLun
    ENDIF ELSE BEGIN
      ; 文件大小正常，但为了重新生成，我们也删除它
      log_write, '  文件大小正常，但将删除以重新生成'
      PRINT, '  文件大小正常，但将删除以重新生成'
      FLUSH, logLun
      FILE_DELETE, outputClass2021, /QUIET
      hdrFile = FILE_DIRNAME(outputClass2021) + PATH_SEP() + FILE_BASENAME(outputClass2021, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      log_write, '  文件已删除'
      PRINT, '  ✓ 文件已删除'
      FLUSH, logLun
    ENDELSE
  ENDIF
  
  log_write, '开始执行2021年随机森林分类...'
  log_write, '  输入raster: ' + STRING(stackedRaster2021.NCOLUMNS) + 'x' + STRING(stackedRaster2021.NROWS) + ', ' + STRING(stackedRaster2021.NBANDS) + '波段'
  log_write, '  数据大小: ' + STRING(stackedRaster2021.NCOLUMNS * stackedRaster2021.NROWS * stackedRaster2021.NBANDS, FORMAT='(I0)') + ' 像素'
  log_write, '  输出文件: ' + outputClass2021
  log_write, '  ROI数量: ' + STRING(N_ELEMENTS(rois))
  ; 随机森林决策树数量设置
  numberOfTrees = 100  ; 随机森林决策树数量
  log_write, '  树数量: ' + STRING(numberOfTrees)
  PRINT, '  随机森林树数量: ' + STRING(numberOfTrees)
  
  ; 创建随机森林分类任务
  log_write, '  正在创建RandomForestClassification任务...'
  FLUSH, logLun
  CATCH, errCreateTask
  IF errCreateTask EQ 0 THEN BEGIN
    rfTask2021 = ENVITask('RandomForestClassification')
    log_write, '  ✓ 任务对象创建成功'
    FLUSH, logLun
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    errorMsg = '创建RandomForestClassification任务失败: ' + !ERROR_STATE.MSG
    log_error, errorMsg, !ERROR_STATE
    PRINT, '错误: ' + errorMsg
    FLUSH, logLun
    CLOSE, logLun
    FREE_LUN, logLun
    RETURN
  ENDELSE
  
  ; 设置任务参数
  log_write, '  正在设置任务参数...'
  FLUSH, logLun
  CATCH, errSetParams
  IF errSetParams EQ 0 THEN BEGIN
    rfTask2021.input_raster = stackedRaster2021
    log_write, '    input_raster设置完成'
    FLUSH, logLun
    rfTask2021.input_rois = rois
    log_write, '    input_rois设置完成'
    FLUSH, logLun
    rfTask2021.numberOfTrees = numberOfTrees
    log_write, '    numberOfTrees设置完成 (' + STRING(numberOfTrees) + ')'
    FLUSH, logLun
    rfTask2021.output_raster_uri = outputClass2021
    log_write, '    output_raster_uri设置完成: ' + FILE_BASENAME(outputClass2021)
    FLUSH, logLun
    ; 关键：禁用对话框和自动显示，避免在执行过程中出现交互导致崩溃
    CATCH, errSetDisplay
    IF errSetDisplay EQ 0 THEN BEGIN
      rfTask2021.showMsg = 0  ; 不显示提示对话框
      log_write, '    showMsg设置为0（不显示对话框）'
      FLUSH, logLun
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      log_write, '  警告: 无法设置showMsg参数（可能不支持）'
      FLUSH, logLun
    ENDELSE
    CATCH, errSetDisplay2
    IF errSetDisplay2 EQ 0 THEN BEGIN
      rfTask2021.display = 0  ; 不自动显示结果
      log_write, '    display设置为0（不自动显示）'
      FLUSH, logLun
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      log_write, '  警告: 无法设置display参数（可能不支持）'
      FLUSH, logLun
    ENDELSE
    log_write, '  ✓ 所有参数设置完成'
    FLUSH, logLun
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    errorMsg = '设置任务参数失败: ' + !ERROR_STATE.MSG
    log_error, errorMsg, !ERROR_STATE
    PRINT, '错误: ' + errorMsg
    FLUSH, logLun
    CLOSE, logLun
    FREE_LUN, logLun
    RETURN
  ENDELSE
  
  ; 验证输入对象
  log_write, '  验证输入对象有效性...'
  FLUSH, logLun
  IF ~OBJ_VALID(stackedRaster2021) THEN BEGIN
    log_error, '输入raster对象无效'
    PRINT, '错误: 输入raster对象无效'
    FLUSH, logLun
    CLOSE, logLun
    FREE_LUN, logLun
    RETURN
  ENDIF
  IF N_ELEMENTS(rois) EQ 0 THEN BEGIN
    log_error, 'ROI数组为空'
    PRINT, '错误: ROI数组为空'
    FLUSH, logLun
    CLOSE, logLun
    FREE_LUN, logLun
    RETURN
  ENDIF
  log_write, '  ✓ 输入对象验证通过'
  FLUSH, logLun
  
  ; 执行前检查
  log_write, '  执行前检查...'
  FLUSH, logLun
  ; 检查输出目录是否存在且可写
  outputDirCheck = FILE_DIRNAME(outputClass2021)
  IF ~FILE_TEST(outputDirCheck, /DIRECTORY) THEN BEGIN
    FILE_MKDIR, outputDirCheck
    log_write, '  创建输出目录: ' + outputDirCheck
    FLUSH, logLun
  ENDIF
  ; 检查输出文件路径是否可访问
  IF FILE_TEST(outputClass2021) THEN BEGIN
    log_write, '  警告: 输出文件已存在，但应该已被删除'
    FLUSH, logLun
  ENDIF
  log_write, '  ✓ 执行前检查完成'
  FLUSH, logLun
  
  ; 执行分类任务
  PRINT, '  正在执行随机森林分类（这可能需要几分钟）...'
  log_write, '========================================'
  log_write, '  开始执行分类任务Execute()...'
  log_write, '  时间: ' + STRING(SYSTIME(), FORMAT='(A)')
  log_write, '  注意: Execute()是长时间运行的操作，程序可能会暂停响应'
  log_write, '  如果程序崩溃，请检查此时间点之前的日志'
  log_write, '========================================'
  FLUSH, logLun
  
  ; 在Execute之前，确保所有日志都已刷新到磁盘
  FLUSH, logLun
  WAIT, 0.5  ; 短暂等待，确保文件系统就绪
  
  ; 在执行前，尝试释放一些内存
  log_write, '  执行前内存管理: 等待系统稳定...'
  FLUSH, logLun
  WAIT, 1.0  ; 等待1秒，让系统稳定
  
  ; 尝试执行任务
  ; 注意：对于大数据，Execute()可能需要很长时间，并且可能崩溃
  log_write, '  准备执行Execute()...'
  FLUSH, logLun
  
  CATCH, errRF
  IF errRF EQ 0 THEN BEGIN
    ; 执行任务（这是可能崩溃的地方）
    log_write, '  [执行开始] ' + STRING(SYSTIME(), FORMAT='(A)')
    FLUSH, logLun
    PRINT, '  正在执行分类（可能需要10-30分钟，请耐心等待）...'
    PRINT, '  如果程序崩溃，请检查输出文件是否已创建: ' + FILE_BASENAME(outputClass2021)
    
    ; 尝试执行
    rfTask2021.Execute
    
    ; 如果执行到这里，说明Execute()成功完成
    log_write, '  [执行完成] ' + STRING(SYSTIME(), FORMAT='(A)')
    FLUSH, logLun
    log_write, '  分类任务Execute()调用成功完成（无异常）'
    FLUSH, logLun
    PRINT, '  ✓ 分类任务执行完成'
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    errorMsg = '随机森林分类执行失败: ' + !ERROR_STATE.MSG + ' (Code: ' + STRING(!ERROR_STATE.CODE) + ')'
    log_error, errorMsg, !ERROR_STATE
    PRINT, '错误: ' + errorMsg
    PRINT, '提示: 如果是因为内存不足，请尝试：'
    PRINT, '  1. 减少树的数量（当前: ' + STRING(numberOfTrees) + '）'
    PRINT, '  2. 裁剪输入数据为较小的区域'
    PRINT, '  3. 关闭其他占用内存的程序'
    FLUSH, logLun
    ; 即使失败，也检查输出文件是否已创建
    IF FILE_TEST(outputClass2021) THEN BEGIN
      log_write, '  虽然Execute()失败，但输出文件已存在，可能分类已部分完成'
      PRINT, '  注意: 输出文件已存在，可能分类已部分完成'
      FLUSH, logLun
    ENDIF
    CLOSE, logLun
    FREE_LUN, logLun
    RETURN
  ENDELSE
  
  ; Execute完成后，立即刷新日志并等待
  FLUSH, logLun
  WAIT, 3.0  ; 增加等待时间到3秒，确保文件系统完全更新
  log_write, '  Execute()完成，开始验证文件完整性...'
  FLUSH, logLun
  
  ; 首先验证输出文件是否完整
  log_write, '  步骤1: 检查输出文件是否存在...'
  FLUSH, logLun
  WAIT, 2.0  ; 等待文件系统更新
  outputFileExists = FILE_TEST(outputClass2021)
  IF outputFileExists THEN BEGIN
    fileInfo = FILE_INFO(outputClass2021)
    fileSize = fileInfo[0].size
    log_write, '  ✓ 输出文件已创建，大小: ' + STRING(fileSize) + ' 字节 (' + STRING(fileSize/1024/1024, FORMAT='(F8.2)') + ' MB)'
    PRINT, '  ✓ 输出文件已创建: ' + STRING(fileSize/1024/1024, FORMAT='(F8.2)') + ' MB'
    FLUSH, logLun
    
    ; 计算期望的文件大小
    ; 注意：RandomForestClassification的输出通常是uint8（1字节/像素），而不是uint16
    ; 但为了兼容性，我们同时检查uint8和uint16两种情况
    nPixels = stackedRaster2021.NCOLUMNS * stackedRaster2021.NROWS
    expectedSizeUint8 = nPixels * 1  ; uint8: 1字节/像素
    expectedSizeUint16 = nPixels * 2  ; uint16: 2字节/像素
    
    log_write, '  步骤2: 验证文件大小...'
    log_write, '    像素数: ' + STRING(nPixels, FORMAT='(I0)')
    log_write, '    期望大小(uint8): ' + STRING(expectedSizeUint8/1024/1024, FORMAT='(F8.2)') + ' MB'
    log_write, '    期望大小(uint16): ' + STRING(expectedSizeUint16/1024/1024, FORMAT='(F8.2)') + ' MB'
    log_write, '    实际文件大小: ' + STRING(fileSize/1024/1024, FORMAT='(F8.2)') + ' MB'
    FLUSH, logLun
    
    ; 检查文件大小是否在合理范围内（允许10%的误差）
    ; 文件大小应该在uint8的90%-110%或uint16的90%-110%之间
    sizeRatioUint8 = FLOAT(fileSize) / FLOAT(expectedSizeUint8)
    sizeRatioUint16 = FLOAT(fileSize) / FLOAT(expectedSizeUint16)
    
    isValidUint8 = (sizeRatioUint8 GE 0.9) AND (sizeRatioUint8 LE 1.1)
    isValidUint16 = (sizeRatioUint16 GE 0.9) AND (sizeRatioUint16 LE 1.1)
    
    IF isValidUint8 THEN BEGIN
      log_write, '  ✓ 文件大小符合uint8类型（1字节/像素）'
      PRINT, '  ✓ 文件大小验证通过（uint8类型）'
      FLUSH, logLun
    ENDIF ELSE IF isValidUint16 THEN BEGIN
      log_write, '  ✓ 文件大小符合uint16类型（2字节/像素）'
      PRINT, '  ✓ 文件大小验证通过（uint16类型）'
      FLUSH, logLun
    ENDIF ELSE BEGIN
      ; 文件大小不在合理范围内
      log_error, '文件大小异常，可能是崩溃时的不完整文件'
      PRINT, '错误: 文件大小异常，可能是崩溃时的不完整文件'
      PRINT, '  期望大小(uint8): ' + STRING(expectedSizeUint8/1024/1024, FORMAT='(F8.2)') + ' MB'
      PRINT, '  期望大小(uint16): ' + STRING(expectedSizeUint16/1024/1024, FORMAT='(F8.2)') + ' MB'
      PRINT, '  实际大小: ' + STRING(fileSize/1024/1024, FORMAT='(F8.2)') + ' MB'
      PRINT, '  建议: 删除此文件并重新运行程序'
      FLUSH, logLun
      ; 删除损坏的文件
      log_write, '  尝试删除损坏的文件...'
      FILE_DELETE, outputClass2021, /QUIET
      hdrFile = FILE_DIRNAME(outputClass2021) + PATH_SEP() + FILE_BASENAME(outputClass2021, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      log_write, '  损坏的文件已删除'
      PRINT, '  损坏的文件已删除，请重新运行程序'
      FLUSH, logLun
      CLOSE, logLun
      FREE_LUN, logLun
      RETURN
    ENDELSE
    
    ; 注意：不尝试打开文件验证，因为打开损坏的文件可能导致崩溃
    ; 只检查文件大小已经足够判断文件是否完整
    log_write, '  步骤3: 文件大小验证通过，跳过打开文件验证（避免崩溃风险）'
    FLUSH, logLun
    PRINT, '  ✓ 文件大小验证通过'
  ENDIF ELSE BEGIN
    log_error, '输出文件不存在，分类可能失败'
    PRINT, '错误: 输出文件不存在，分类可能失败'
    FLUSH, logLun
    ; 即使文件不存在，也继续尝试获取结果对象（可能文件路径有问题）
  ENDELSE
  
  ; 验证任务对象仍然有效
  log_write, '  步骤4: 验证任务对象有效性...'
  FLUSH, logLun
  IF ~OBJ_VALID(rfTask2021) THEN BEGIN
    log_error, '任务对象在执行后变为无效'
    PRINT, '警告: 任务对象在执行后变为无效'
    ; 如果文件存在且已验证，可以继续
    IF outputFileExists THEN BEGIN
      log_write, '  但输出文件已验证，继续处理'
      PRINT, '  但输出文件已验证，继续处理'
      FLUSH, logLun
    ENDIF ELSE BEGIN
      log_error, '输出文件也不存在，分类失败'
      PRINT, '错误: 输出文件不存在，分类失败'
      FLUSH, logLun
      CLOSE, logLun
      FREE_LUN, logLun
      RETURN
    ENDELSE
  ENDIF ELSE BEGIN
    log_write, '  ✓ 任务对象仍然有效'
    FLUSH, logLun
  ENDELSE
  
  log_write, '=== 关键步骤：获取分类结果对象 ==='
  FLUSH, logLun
  log_write, '步骤1: 获取分类结果对象...'
  FLUSH, logLun
  classifiedRaster2021 = !NULL
  CATCH, errGetRaster
  IF errGetRaster EQ 0 THEN BEGIN
    log_write, '  正在访问rfTask2021.output_raster属性...'
    FLUSH, logLun
    classifiedRaster2021 = rfTask2021.output_raster
    log_write, '  ✓ 已获取output_raster对象'
    FLUSH, logLun
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    errorMsg = '获取output_raster失败: ' + !ERROR_STATE.MSG + ' (Code: ' + STRING(!ERROR_STATE.CODE) + ')'
    log_error, errorMsg, !ERROR_STATE
    FLUSH, logLun
    PRINT, '错误: ' + errorMsg
    ; 即使获取对象失败，也检查文件是否存在
    IF FILE_TEST(outputClass2021) THEN BEGIN
      log_write, '  虽然获取对象失败，但输出文件存在，尝试重新打开...'
      FLUSH, logLun
      CATCH, errReopen
      IF errReopen EQ 0 THEN BEGIN
        classifiedRaster2021 = e.OpenRaster(outputClass2021)
        IF OBJ_VALID(classifiedRaster2021) THEN BEGIN
          log_write, '  ✓ 成功重新打开输出文件'
          FLUSH, logLun
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          log_error, '重新打开文件也失败'
          FLUSH, logLun
          CLOSE, logLun
          FREE_LUN, logLun
          RETURN
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        log_error, '重新打开文件失败: ' + !ERROR_STATE.MSG
        FLUSH, logLun
        CLOSE, logLun
        FREE_LUN, logLun
        RETURN
      ENDELSE
    ENDIF ELSE BEGIN
      log_error, '输出文件也不存在，分类可能完全失败'
      FLUSH, logLun
      CLOSE, logLun
      FREE_LUN, logLun
      RETURN
    ENDELSE
  ENDELSE
  log_write, '步骤2: 验证分类结果对象有效性...'
  IF OBJ_VALID(classifiedRaster2021) THEN BEGIN
    log_write, '  分类结果对象有效 (OBJ_VALID=true)'
    ; 安全地访问raster属性
    CATCH, errGetProps
    IF errGetProps EQ 0 THEN BEGIN
      log_write, '  正在获取raster属性...'
      nCols = classifiedRaster2021.NCOLUMNS
      nRows = classifiedRaster2021.NROWS
      nBands = classifiedRaster2021.NBANDS
      log_write, '  结果尺寸: ' + STRING(nCols) + 'x' + STRING(nRows)
      log_write, '  波段数: ' + STRING(nBands)
      PRINT, '  结果尺寸: ' + STRING(nCols) + 'x' + STRING(nRows)
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      log_error, '获取raster属性失败: ' + !ERROR_STATE.MSG
      PRINT, '警告: 获取raster属性失败，但对象有效，继续处理'
    ENDELSE
  ENDIF ELSE BEGIN
    log_error, '分类结果对象无效 (OBJ_VALID=false)'
    PRINT, '错误: 分类结果对象无效'
    CLOSE, logLun
    FREE_LUN, logLun
    RETURN
  ENDELSE
  
  PRINT, '✓ 2021年随机森林分类完成'
  log_write, '✓ 2021年随机森林分类完成'
  
  ; 检查输出文件是否存在
  log_write, '步骤3: 检查输出文件是否存在...'
  IF FILE_TEST(outputClass2021) THEN BEGIN
    fileInfo = FILE_INFO(outputClass2021)
    fileSize = fileInfo[0].size
    log_write, '  输出文件存在，大小: ' + STRING(fileSize) + ' 字节 (' + STRING(fileSize/1024/1024, FORMAT='(F8.2)') + ' MB)'
    PRINT, '  文件大小: ' + STRING(fileSize / 1024 / 1024, FORMAT='(F8.2)') + ' MB'
  ENDIF ELSE BEGIN
    log_error, '输出文件不存在: ' + outputClass2021
    PRINT, '警告: 输出文件不存在，但分类对象有效，继续处理'
  ENDELSE
  
  ; 等待一下，确保分类结果文件已完全写入
  log_write, '  等待文件写入完成...'
  WAIT, 2.0  ; 增加等待时间到2秒
  log_write, '  等待完成'
  
  PRINT, '  分类结果已保存到: ' + FILE_BASENAME(outputClass2021)
  log_write, '  分类结果已保存到: ' + FILE_BASENAME(outputClass2021)

  ; 更新分类结果元数据
  ; 注意：随机森林输出的类别值从1开始（1, 2, 3...），所以需要nClasses+1个颜色（索引0用于未分类）
  ; 设置分类颜色查找表（根据类别名称）
  ; 用户ROI类别：植被1110、水体1110、其他1110
  ; 注意：ENVI的class lookup需要使用数组字面量格式，例如：[[0,0,0], [128,128,128], [0,255,128]]
  ; 但是，从ClassStatistics_and_Barplot.pro可以看到，ENVI也接受3×N数组格式（通过[*]索引访问）
  ; 我们使用3×N数组格式，这应该是ENVI可以接受的
  nTotalClasses = nClasses + 1
  
  ; 设置类别名称数组（包含未分类）
  classNamesWithUnclassified = STRARR(nTotalClasses)
  classNamesWithUnclassified[0] = 'Unclassified'
  
  ; 创建class lookup数组字面量格式
  ; 注意：根据示例代码和ENVI的要求，class lookup应该使用数组字面量格式
  ; 格式：[[R1,G1,B1], [R2,G2,B2], [R3,G3,B3], ...]
  ; 但由于IDL的限制，我们不能动态创建数组字面量
  ; 因此，我们根据类别数量构建数组字面量
  ; 首先确定每个类别的颜色
  classRGB = INTARR(3, nTotalClasses)  ; 临时存储RGB值（3行N列）
  classRGB[*, 0] = [0, 0, 0]  ; 黑色 - 未分类（索引0）
  
  FOR i=0, nClasses-1 DO BEGIN
    classNamesWithUnclassified[i+1] = classNames[i]  ; 索引从1开始对应类别值1,2,3...
    className = STRUPCASE(classNames[i])
    IF STRMATCH(className, '*植被*') OR STRMATCH(className, '*VEG*') OR STRMATCH(className, '*1110*植被*') THEN BEGIN
      ; 绿色 - 植被
      classRGB[*, i+1] = [0, 255, 0]
    ENDIF ELSE IF STRMATCH(className, '*水体*') OR STRMATCH(className, '*WATER*') OR STRMATCH(className, '*1110*水体*') THEN BEGIN
      ; 蓝色 - 水体
      classRGB[*, i+1] = [0, 0, 255]
    ENDIF ELSE IF STRMATCH(className, '*其他*') OR STRMATCH(className, '*OTHER*') OR STRMATCH(className, '*1110*其他*') THEN BEGIN
      ; 灰色 - 其他
      classRGB[*, i+1] = [128, 128, 128]
    ENDIF ELSE BEGIN
      ; 默认颜色（如果类别名称不匹配，使用浅灰色）
      classRGB[*, i+1] = [200, 200, 200]
      PRINT, '警告: 未识别的类别名称: ' + classNames[i] + '，使用默认颜色'
    ENDELSE
  ENDFOR
  
  ; 构建数组字面量格式的class lookup
  ; 由于IDL限制，我们根据类别数量使用条件语句构建
  ; ENVI接受3×N数组格式，但为了兼容性，我们确保格式正确
  ; 注意：ENVI的class lookup在头文件中存储为扁平数组，但元数据API可能需要特定格式
  ; 我们使用3×N数组，确保格式为：3行（R,G,B），N列（类别数）
  classColors = classRGB  ; 使用3×N格式（3行N列）
  
  ; 关闭并重新打开raster以更新元数据
  log_write, '开始更新分类结果元数据...'
  PRINT, '正在更新分类结果元数据...'
  FLUSH, logLun
  
  log_write, '步骤5: 关闭原始分类结果对象...'
  PRINT, '步骤5: 关闭原始分类结果对象...'
  FLUSH, logLun
  
  CATCH, errMetadata
  IF errMetadata EQ 0 THEN BEGIN
    ; 先关闭原始分类结果
    IF OBJ_VALID(classifiedRaster2021) THEN BEGIN
      log_write, '  关闭classifiedRaster2021对象...'
      FLUSH, logLun
      classifiedRaster2021.Close
      log_write, '  对象已关闭'
      FLUSH, logLun
    ENDIF ELSE BEGIN
      log_write, '  警告: classifiedRaster2021对象无效，跳过关闭'
      FLUSH, logLun
    ENDELSE
    
    ; 等待一下，确保文件已完全写入
    log_write, '  等待文件系统刷新...'
    FLUSH, logLun
    WAIT, 1.0  ; 增加到1秒
    
    ; 重新打开文件
    log_write, '步骤6: 重新打开分类结果文件...'
    PRINT, '步骤6: 重新打开分类结果文件...'
    FLUSH, logLun
    
    tempRaster2021 = !NULL
    CATCH, errReopen
    IF errReopen EQ 0 THEN BEGIN
      tempRaster2021 = e.OpenRaster(outputClass2021)
      log_write, '  文件已打开'
      FLUSH, logLun
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      log_error, '重新打开文件失败: ' + !ERROR_STATE.MSG
      PRINT, '错误: 无法重新打开分类结果文件: ' + !ERROR_STATE.MSG
      CLOSE, logLun
      FREE_LUN, logLun
      RETURN
    ENDELSE
    
    IF ~OBJ_VALID(tempRaster2021) THEN BEGIN
      log_error, '重新打开的文件对象无效'
      PRINT, '错误: 无法重新打开分类结果文件（对象无效）'
      CLOSE, logLun
      FREE_LUN, logLun
      RETURN
    ENDIF
    
    log_write, '  文件对象有效，尺寸: ' + STRING(tempRaster2021.NCOLUMNS) + 'x' + STRING(tempRaster2021.NROWS)
    FLUSH, logLun
    
    ; 设置元数据
    log_write, '步骤7: 设置元数据...'
    PRINT, '步骤7: 设置元数据...'
    FLUSH, logLun
    
    CATCH, errSetMetadata
    IF errSetMetadata EQ 0 THEN BEGIN
      IF ~tempRaster2021.METADATA.HasTag('classes') THEN BEGIN
        tempRaster2021.METADATA.AddItem, 'classes', nClasses + 1
      ENDIF ELSE BEGIN
        tempRaster2021.METADATA.UpdateItem, 'classes', nClasses + 1
      ENDELSE
      log_write, '  已设置classes元数据'
      FLUSH, logLun
      
      IF ~tempRaster2021.METADATA.HasTag('class names') THEN BEGIN
        tempRaster2021.METADATA.AddItem, 'class names', classNamesWithUnclassified
      ENDIF ELSE BEGIN
        tempRaster2021.METADATA.UpdateItem, 'class names', classNamesWithUnclassified
      ENDELSE
      log_write, '  已设置class names元数据'
      FLUSH, logLun
      
      ; 设置class lookup元数据
      ; 注意：ENVI的class lookup格式应该是3×N数组（3行：R,G,B，N列：类别数）
      ; 但是，根据示例代码，ENVI API可能期望数组字面量格式
      ; 我们尝试使用数组字面量格式（如果类别数量固定）
      log_write, '  正在设置class lookup元数据...'
      log_write, '  类别数量: ' + STRING(nTotalClasses)
      FLUSH, logLun
      
      ; 根据类别数量构建数组字面量
      ; 由于IDL不能动态创建数组字面量，我们使用条件语句
      classLookupArray = !NULL
      IF nTotalClasses EQ 2 THEN BEGIN
        classLookupArray = [[classRGB[0,0], classRGB[1,0], classRGB[2,0]], $
                           [classRGB[0,1], classRGB[1,1], classRGB[2,1]]]
      ENDIF ELSE IF nTotalClasses EQ 3 THEN BEGIN
        classLookupArray = [[classRGB[0,0], classRGB[1,0], classRGB[2,0]], $
                           [classRGB[0,1], classRGB[1,1], classRGB[2,1]], $
                           [classRGB[0,2], classRGB[1,2], classRGB[2,2]]]
      ENDIF ELSE IF nTotalClasses EQ 4 THEN BEGIN
        classLookupArray = [[classRGB[0,0], classRGB[1,0], classRGB[2,0]], $
                           [classRGB[0,1], classRGB[1,1], classRGB[2,1]], $
                           [classRGB[0,2], classRGB[1,2], classRGB[2,2]], $
                           [classRGB[0,3], classRGB[1,3], classRGB[2,3]]]
      ENDIF ELSE IF nTotalClasses EQ 5 THEN BEGIN
        classLookupArray = [[classRGB[0,0], classRGB[1,0], classRGB[2,0]], $
                           [classRGB[0,1], classRGB[1,1], classRGB[2,1]], $
                           [classRGB[0,2], classRGB[1,2], classRGB[2,2]], $
                           [classRGB[0,3], classRGB[1,3], classRGB[2,3]], $
                           [classRGB[0,4], classRGB[1,4], classRGB[2,4]]]
      ENDIF ELSE BEGIN
        ; 如果类别数量超过5，使用3×N数组格式
        log_write, '  警告: 类别数量超过5，使用3×N数组格式'
        classLookupArray = classColors
      ENDELSE
      
      CATCH, errClassLookup
      IF errClassLookup EQ 0 THEN BEGIN
        IF ~tempRaster2021.METADATA.HasTag('class lookup') THEN BEGIN
          tempRaster2021.METADATA.AddItem, 'class lookup', classLookupArray
        ENDIF ELSE BEGIN
          tempRaster2021.METADATA.UpdateItem, 'class lookup', classLookupArray
        ENDELSE
        log_write, '  ✓ class lookup元数据已设置'
        FLUSH, logLun
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        log_error, '设置class lookup失败: ' + !ERROR_STATE.MSG
        PRINT, '错误: 设置class lookup失败: ' + !ERROR_STATE.MSG
        FLUSH, logLun
        ; 如果数组字面量格式失败，尝试使用3×N数组格式
        CATCH, errClassLookup2
        IF errClassLookup2 EQ 0 THEN BEGIN
          IF ~tempRaster2021.METADATA.HasTag('class lookup') THEN BEGIN
            tempRaster2021.METADATA.AddItem, 'class lookup', classColors
          ENDIF ELSE BEGIN
            tempRaster2021.METADATA.UpdateItem, 'class lookup', classColors
          ENDELSE
          log_write, '  ✓ class lookup元数据已设置（使用3×N数组格式）'
          FLUSH, logLun
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          log_error, '设置class lookup失败（所有方法）: ' + !ERROR_STATE.MSG
          PRINT, '严重错误: 无法设置class lookup元数据'
        ENDELSE
      ENDELSE
      
      ; 写入元数据
      log_write, '步骤8: 写入元数据到文件...'
      PRINT, '步骤8: 写入元数据到文件...'
      FLUSH, logLun
      
      CATCH, errWriteMetadata
      IF errWriteMetadata EQ 0 THEN BEGIN
        tempRaster2021.WriteMetadata
        log_write, '  WriteMetadata调用完成（无错误）'
        FLUSH, logLun
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        errorMsg = 'WriteMetadata失败: ' + !ERROR_STATE.MSG
        log_error, errorMsg, !ERROR_STATE
        PRINT, '错误: ' + errorMsg
        FLUSH, logLun
        ; 即使WriteMetadata失败，也继续执行
      ENDELSE
      
      ; 等待元数据写入完成
      log_write, '  等待元数据写入完成...'
      FLUSH, logLun
      WAIT, 1.0  ; 增加到1秒
      log_write, '  等待完成'
      FLUSH, logLun
      
      classifiedRaster2021 = tempRaster2021  ; 重新赋值
      log_write, '步骤9: 元数据更新完成'
      PRINT, '✓ 元数据更新完成'
      FLUSH, logLun
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      log_error, '设置元数据失败: ' + !ERROR_STATE.MSG
      PRINT, '警告: 设置元数据失败: ' + !ERROR_STATE.MSG
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '警告: 更新元数据时发生错误: ' + !ERROR_STATE.MSG
    PRINT, '将使用原始分类结果继续处理'
    ; 如果更新元数据失败，尝试重新打开原始文件
    IF ~OBJ_VALID(classifiedRaster2021) THEN BEGIN
      classifiedRaster2021 = e.OpenRaster(outputClass2021)
    ENDIF
  ENDELSE
  
  ; 打印类别信息
  PRINT, '分类类别:'
  FOR i=0, nClasses-1 DO BEGIN
    PRINT, '  类别 ' + STRING(i+1) + ' (值=' + STRING(i+1) + '): ' + classNames[i] + ' (颜色: RGB' + STRING(classColors[i+1]) + ')'
  ENDFOR
  PRINT, ''

  ; 使用新的后处理函数处理2021年分类结果
  log_write, '开始2021年分类后处理（平滑、聚合、元数据更新）...'
  PRINT, '正在进行2021年分类后处理...'
  FLUSH, logLun
  
  ; 获取空间参考（用于计算聚合阈值）
  spatialRefForPost2021 = !NULL
  IF OBJ_VALID(stackedRaster2021) THEN BEGIN
    spatialRefForPost2021 = stackedRaster2021.SPATIALREF
  ENDIF
  
  ; 准备输出文件路径
  outputFinal2021 = outputDir + PATH_SEP() + 'classification_2021_final.dat'
  IF FILE_TEST(outputFinal2021) THEN BEGIN
    FILE_DELETE, outputFinal2021, /QUIET
    hdrFile = FILE_DIRNAME(outputFinal2021) + PATH_SEP() + FILE_BASENAME(outputFinal2021, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  ENDIF
  
  ; 调用后处理函数
  CATCH, errPost2021
  IF errPost2021 EQ 0 THEN BEGIN
    finalRaster2021 = process_classification_postprocessing(classifiedRaster2021, outputFinal2021, classNames, nClasses, spatialRefForPost2021, '2021', logLun)
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    log_error, '2021年后处理失败: ' + !ERROR_STATE.MSG, !ERROR_STATE
    PRINT, '错误: 2021年后处理失败: ' + !ERROR_STATE.MSG
    FLUSH, logLun
    finalRaster2021 = !NULL
  ENDELSE
  
  ; 关闭原始分类结果以释放内存
  IF OBJ_VALID(classifiedRaster2021) THEN BEGIN
    classifiedRaster2021.Close
    classifiedRaster2021 = !NULL
  ENDIF
  
  ; 检查后处理结果
  IF OBJ_VALID(finalRaster2021) THEN BEGIN
    PRINT, '✓ 2021年分类后处理完成'
    log_write, '✓ 2021年分类后处理完成'
    FLUSH, logLun
  ENDIF ELSE BEGIN
    PRINT, '警告: 2021年分类后处理失败，最终结果无效'
    log_error, '2021年分类后处理失败，最终结果无效'
    FLUSH, logLun
  ENDELSE
  
  ; 计算2021年的像素面积（用于统计）
  pixelArea = 0.0
  IF OBJ_VALID(finalRaster2021) THEN BEGIN
    spatialRefForArea2021 = finalRaster2021.SPATIALREF
    IF OBJ_VALID(spatialRefForArea2021) THEN BEGIN
      pixelArea = PRODUCT(spatialRefForArea2021.PIXEL_SIZE) / 1E6  ; km²
      PRINT, '2021年像元面积: ' + STRING(pixelArea, FORMAT='(F10.8)') + ' km²'
    ENDIF ELSE BEGIN
      ; 如果无法获取空间参考，尝试使用stackedRaster2021
      IF OBJ_VALID(stackedRaster2021) THEN BEGIN
        spatialRefForArea2021 = stackedRaster2021.SPATIALREF
        IF OBJ_VALID(spatialRefForArea2021) THEN BEGIN
          pixelArea = PRODUCT(spatialRefForArea2021.PIXEL_SIZE) / 1E6  ; km²
          PRINT, '2021年像元面积（从stackedRaster）: ' + STRING(pixelArea, FORMAT='(F10.8)') + ' km²'
        ENDIF
      ENDIF
    ENDELSE
  ENDIF
  
  ; 打印进度提示
  log_write, '========== 2021年分类处理完成 =========='
  PRINT, ''
  PRINT, '========== 2021年分类处理完成 =========='
  PRINT, '最终分类结果文件: ' + FILE_BASENAME(outputFinal2021)
  log_write, '最终分类结果文件: ' + FILE_BASENAME(outputFinal2021)
  PRINT, ''
  FLUSH, logLun
  
  ; 释放不需要的对象以释放内存（在进入下一个大步骤前）
  log_write, '步骤18: 释放不需要的对象内存...'
  FLUSH, logLun
  PRINT, '正在释放内存...'
  
  ; 关闭stackedRaster2021（不再需要，因为分类已完成）
  IF OBJ_VALID(stackedRaster2021) THEN BEGIN
    log_write, '  关闭stackedRaster2021对象...'
    FLUSH, logLun
    stackedRaster2021.Close
    log_write, '  stackedRaster2021已关闭'
    FLUSH, logLun
    PRINT, '已释放stackedRaster2021内存'
  ENDIF ELSE BEGIN
    log_write, '  stackedRaster2021对象无效，跳过关闭'
    FLUSH, logLun
  ENDELSE
  
  ; 可以关闭ndvi2021和ndbi2021（如果不再需要单独使用）
  ; 但为了安全，我们先保留它们，因为可能在后面对比分析中需要
  log_write, '  保留ndvi2021和ndbi2021对象（后续分析需要）'
  FLUSH, logLun
  
  ; 强制刷新，确保所有文件操作完成
  log_write, '步骤19: 刷新文件系统...'
  PRINT, '正在刷新文件系统...'
  FLUSH, logLun
  WAIT, 2.0  ; 等待2秒，确保所有文件操作完成
  log_write, '  文件系统刷新完成'
  FLUSH, logLun
  
  log_write, '========== 2021年分类处理完全完成 =========='
  PRINT, '========== 2021年分类处理完全完成 =========='
  PRINT, ''
  FLUSH, logLun

  ; 随机森林分类 - 2025年（如果存在）
  classifiedRaster2025 = !NULL
  smoothTask2025 = !NULL
  nClassesFor2025 = 0  ; 初始化为0，表示未定义
  classNamesFor2025 = !NULL  ; 初始化为!NULL
  IF has2025Data THEN BEGIN
    PRINT, '正在进行2025年随机森林分类（这可能需要几分钟）...'
    ; 注意：使用2021年的ROI训练样本
    outputClass2025 = outputDir + PATH_SEP() + 'classification_2025.dat'
    ; 删除已存在的文件（包括可能被占用的文件）
    IF FILE_TEST(outputClass2025) THEN BEGIN
      log_write, '发现已存在的2025年分类文件，正在删除...'
      FLUSH, logLun
      FILE_DELETE, outputClass2025, /QUIET
      WAIT, 1.0  ; 等待文件系统更新
      hdrFile = FILE_DIRNAME(outputClass2025) + PATH_SEP() + FILE_BASENAME(outputClass2025, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN BEGIN
        FILE_DELETE, hdrFile, /QUIET
        WAIT, 0.5
      ENDIF
      ; 再次检查文件是否已删除
      IF FILE_TEST(outputClass2025) THEN BEGIN
        log_write, '警告: 文件删除后仍然存在，尝试强制删除...'
        FLUSH, logLun
        ; 尝试多次删除
        FOR retry=0, 2 DO BEGIN
          FILE_DELETE, outputClass2025, /QUIET
          WAIT, 0.5
          IF ~FILE_TEST(outputClass2025) THEN BREAK
        ENDFOR
        IF FILE_TEST(outputClass2025) THEN BEGIN
          log_error, '无法删除已存在的2025年分类文件，可能被占用'
          PRINT, '错误: 无法删除已存在的2025年分类文件: ' + outputClass2025
          PRINT, '请手动删除该文件后重新运行程序'
          FLUSH, logLun
        ENDIF ELSE BEGIN
          log_write, '✓ 文件已成功删除'
          FLUSH, logLun
        ENDELSE
      ENDIF ELSE BEGIN
        log_write, '✓ 文件已成功删除'
        FLUSH, logLun
      ENDELSE
    ENDIF
    
    ; 使用2025年的ROI（如果可用），否则使用2021年ROI
    roisFor2025 = rois2025  ; 优先使用2025年ROI
    ; 注意：roisFor2025是ROI数组，不是对象，不能使用OBJ_VALID
    ; 检查是否为!NULL或元素数量是否为0
    IF (roisFor2025 EQ !NULL) OR (N_ELEMENTS(roisFor2025) EQ 0) THEN BEGIN
      PRINT, '  使用2021年ROI作为训练样本'
      roisFor2025 = rois
      nClassesFor2025 = nClasses
      classNamesFor2025 = classNames
    ENDIF ELSE BEGIN
      PRINT, '  使用2025年ROI作为训练样本: ' + STRING(N_ELEMENTS(roisFor2025)) + ' 个ROI'
      nClassesFor2025 = nClasses2025
      classNamesFor2025 = classNames2025
    ENDELSE
    
    ; 验证输入对象
    IF ~OBJ_VALID(stackedRaster2025) THEN BEGIN
      PRINT, '错误: stackedRaster2025对象无效，无法进行2025年分类'
      log_error, 'stackedRaster2025对象无效'
      FLUSH, logLun
      classifiedRaster2025 = !NULL
    ENDIF ELSE IF (roisFor2025 EQ !NULL) OR (N_ELEMENTS(roisFor2025) EQ 0) THEN BEGIN
      PRINT, '错误: 2025年ROI数组无效或为空，无法进行分类'
      log_error, '2025年ROI数组无效或为空'
      FLUSH, logLun
      classifiedRaster2025 = !NULL
    ENDIF ELSE BEGIN
      ; 执行2025年分类
      log_write, '开始执行2025年随机森林分类...'
      log_write, '  输入raster: ' + STRING(stackedRaster2025.NCOLUMNS) + 'x' + STRING(stackedRaster2025.NROWS) + ', ' + STRING(stackedRaster2025.NBANDS) + '波段'
      log_write, '  ROI数量: ' + STRING(N_ELEMENTS(roisFor2025))
      log_write, '  树数量: ' + STRING(numberOfTrees)
      FLUSH, logLun
      
      CATCH, errRF2025
      IF errRF2025 EQ 0 THEN BEGIN
        rfTask2025 = ENVITask('RandomForestClassification')
        rfTask2025.input_raster = stackedRaster2025
        rfTask2025.input_rois = roisFor2025  ; 使用2025年ROI
        rfTask2025.numberOfTrees = numberOfTrees
        rfTask2025.output_raster_uri = outputClass2025
        rfTask2025.showMsg = 0  ; 禁用交互式消息
        rfTask2025.display = 0  ; 禁用显示
        
        log_write, '  开始执行分类任务Execute()...'
        FLUSH, logLun
        PRINT, '  正在执行2025年分类（可能需要10-30分钟，请耐心等待）...'
        rfTask2025.Execute
        log_write, '  分类任务Execute()调用成功完成'
        FLUSH, logLun
        
        ; 等待文件写入完成
        WAIT, 3.0
        classifiedRaster2025 = rfTask2025.output_raster
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        errorMsg = '2025年随机森林分类执行失败: ' + !ERROR_STATE.MSG
        log_error, errorMsg, !ERROR_STATE
        PRINT, '错误: ' + errorMsg
        FLUSH, logLun
        classifiedRaster2025 = !NULL
      ENDELSE
      
      ; 验证分类结果
      IF OBJ_VALID(classifiedRaster2025) THEN BEGIN
        PRINT, '✓ 2025年随机森林分类完成'
        log_write, '✓ 2025年随机森林分类完成'
        FLUSH, logLun
      ENDIF ELSE BEGIN
        PRINT, '警告: 2025年分类结果对象无效'
        log_error, '2025年分类结果对象无效'
        FLUSH, logLun
      ENDELSE
    ENDELSE

    ; 使用新的后处理函数处理2025年分类结果
    ; 只在classifiedRaster2025有效时进行后处理
    IF OBJ_VALID(classifiedRaster2025) THEN BEGIN
      log_write, '开始2025年分类后处理（平滑、聚合、元数据更新）...'
      PRINT, '正在进行2025年分类后处理...'
      FLUSH, logLun
      
      ; 获取空间参考（用于计算聚合阈值）
      spatialRefForPost2025 = !NULL
      IF OBJ_VALID(stackedRaster2025) THEN BEGIN
        spatialRefForPost2025 = stackedRaster2025.SPATIALREF
  ENDIF
      
      ; 准备输出文件路径
      outputFinal2025 = outputDir + PATH_SEP() + 'classification_2025_final.dat'
      IF FILE_TEST(outputFinal2025) THEN BEGIN
        FILE_DELETE, outputFinal2025, /QUIET
        hdrFile = FILE_DIRNAME(outputFinal2025) + PATH_SEP() + FILE_BASENAME(outputFinal2025, '.dat') + '.hdr'
        IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      ENDIF
      
      ; 调用后处理函数（使用2025年的类别名称）
      CATCH, errPost2025
      IF errPost2025 EQ 0 THEN BEGIN
        finalRaster2025 = process_classification_postprocessing(classifiedRaster2025, outputFinal2025, classNamesFor2025, nClassesFor2025, spatialRefForPost2025, '2025', logLun)
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        log_error, '2025年后处理失败: ' + !ERROR_STATE.MSG, !ERROR_STATE
        PRINT, '错误: 2025年后处理失败: ' + !ERROR_STATE.MSG
        FLUSH, logLun
        finalRaster2025 = !NULL
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '警告: 2025年分类结果无效，跳过后续处理'
      log_error, '2025年分类结果无效，跳过后续处理'
      FLUSH, logLun
      finalRaster2025 = !NULL
    ENDELSE
    
    ; 关闭原始分类结果以释放内存
    IF OBJ_VALID(classifiedRaster2025) THEN BEGIN
      classifiedRaster2025.Close
      classifiedRaster2025 = !NULL
    ENDIF
    
    ; 检查后处理结果
    IF OBJ_VALID(finalRaster2025) THEN BEGIN
      PRINT, '✓ 2025年分类后处理完成'
      log_write, '✓ 2025年分类后处理完成'
      FLUSH, logLun
      
      ; 计算2025年的像素面积（用于统计）
      pixelArea2025 = 0.0
      spatialRefForArea2025 = finalRaster2025.SPATIALREF
      IF OBJ_VALID(spatialRefForArea2025) THEN BEGIN
        pixelArea2025 = PRODUCT(spatialRefForArea2025.PIXEL_SIZE) / 1E6  ; km²
        PRINT, '2025年像元面积: ' + STRING(pixelArea2025, FORMAT='(F10.8)') + ' km²'
      ENDIF ELSE BEGIN
        ; 如果无法获取空间参考，尝试使用stackedRaster2025
        IF OBJ_VALID(stackedRaster2025) THEN BEGIN
          spatialRefForArea2025 = stackedRaster2025.SPATIALREF
          IF OBJ_VALID(spatialRefForArea2025) THEN BEGIN
            pixelArea2025 = PRODUCT(spatialRefForArea2025.PIXEL_SIZE) / 1E6  ; km²
            PRINT, '2025年像元面积（从stackedRaster）: ' + STRING(pixelArea2025, FORMAT='(F10.8)') + ' km²'
          ENDIF
        ENDIF
      ENDELSE
      
      ; 如果pixelArea2025仍然为0，使用2021年的pixelArea
      IF pixelArea2025 EQ 0.0 THEN BEGIN
        pixelArea2025 = pixelArea
        PRINT, '警告: 无法获取2025年像元面积，使用2021年的像元面积'
      ENDIF
    ENDIF ELSE BEGIN
      PRINT, '警告: 2025年分类后处理失败，最终结果无效'
      log_error, '2025年分类后处理失败，最终结果无效'
      FLUSH, logLun
    ENDELSE
  ENDIF ELSE BEGIN
    finalRaster2025 = !NULL
    pixelArea2025 = 0.0
  ENDELSE

  ; ============================================
  ; 5. 计算分类统计信息（面积等）
  ; ============================================
  PRINT, ''
  PRINT, '========== 分类统计 =========='

  ; 2021年统计
  areas2021 = !NULL
  counts2021 = !NULL
  IF OBJ_VALID(finalRaster2021) THEN BEGIN
  PRINT, '正在计算2021年分类统计...'
    CATCH, errHist2021
    IF errHist2021 EQ 0 THEN BEGIN
  histTask2021 = ENVITask('RasterHistogram')
      histTask2021.INPUT_RASTER = finalRaster2021
      histTask2021.INPUT_MIN = [1]  ; 随机森林输出从1开始
      histTask2021.INPUT_MAX = [nClasses]  ; 最大值是类别数
      histTask2021.INPUT_NBINS = [nClasses]
  histTask2021.Execute
  counts2021 = (histTask2021.OUTPUT_COUNTS).ToArray()
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '错误: 计算2021年直方图失败: ' + !ERROR_STATE.MSG
      counts2021 = !NULL
    ENDELSE
    
    ; 注意：随机森林输出的类别值从1开始，所以counts2021[0]对应类别1（第一个ROI）
    ; 如果counts2021的长度小于nClasses，需要调整
    IF (counts2021 NE !NULL) AND (N_ELEMENTS(counts2021) LT nClasses) THEN BEGIN
      counts2021_extended = DBLARR(nClasses)
      counts2021_extended[0:N_ELEMENTS(counts2021)-1] = counts2021
      counts2021 = counts2021_extended
    ENDIF

  ; 计算面积（km²）
    ; 检查pixelArea是否已正确计算
    IF pixelArea EQ 0.0 THEN BEGIN
      PRINT, '警告: 2021年像元面积未计算或为0，尝试从finalRaster2021重新计算...'
      IF OBJ_VALID(finalRaster2021) THEN BEGIN
        spatialRefForArea2021 = finalRaster2021.SPATIALREF
        IF OBJ_VALID(spatialRefForArea2021) THEN BEGIN
          pixelArea = PRODUCT(spatialRefForArea2021.PIXEL_SIZE) / 1E6  ; km²
          PRINT, '  重新计算的像元面积: ' + STRING(pixelArea, FORMAT='(F10.8)') + ' km²'
        ENDIF ELSE BEGIN
          PRINT, '  错误: 无法获取空间参考信息，无法计算面积'
          pixelArea = 9.0E-6  ; 使用默认值（30m x 30m = 0.0009 km²）
          PRINT, '  使用默认像元面积: ' + STRING(pixelArea, FORMAT='(F10.8)') + ' km² (30m x 30m)'
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  错误: finalRaster2021无效，使用默认像元面积'
        pixelArea = 9.0E-6  ; 使用默认值（30m x 30m = 0.0009 km²）
      ENDELSE
    ENDIF
    
    ; 计算面积数组
    IF (counts2021 NE !NULL) AND (N_ELEMENTS(counts2021) GT 0) THEN BEGIN
  areas2021 = counts2021 * pixelArea

  PRINT, '2021年分类统计:'
      totalArea2021 = TOTAL(areas2021)
      IF totalArea2021 GT 0 THEN BEGIN
        FOR i=0, nClasses-1 DO BEGIN
          ; 检查数组索引是否有效
          IF (i LT N_ELEMENTS(areas2021)) AND (i LT N_ELEMENTS(counts2021)) AND (i LT N_ELEMENTS(classNames)) THEN BEGIN
            percentArea = (areas2021[i] / totalArea2021) * 100.0
            PRINT, '  ' + classNames[i] + ': ' + $
           STRING(areas2021[i], FORMAT='(F10.2)') + ' km²' + $
                   ' (' + STRING(percentArea, FORMAT='(F5.2)') + '%, ' + $
                   STRING(counts2021[i], FORMAT='(I10)') + ' 像元)'
          ENDIF
  ENDFOR
        PRINT, '  总计: ' + STRING(totalArea2021, FORMAT='(F10.2)') + ' km²'
      ENDIF ELSE BEGIN
        PRINT, '  警告: 总面积为0，可能数据有问题'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: 无法计算2021年统计（counts2021无效）'
      areas2021 = !NULL
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '错误: finalRaster2021无效，无法计算2021年统计'
    areas2021 = !NULL
    counts2021 = !NULL
  ENDELSE

  ; 2025年统计（如果存在）
  areas2025 = !NULL
  counts2025 = !NULL
  IF has2025Data AND OBJ_VALID(finalRaster2025) THEN BEGIN
    PRINT, '正在计算2025年分类统计...'
    
    ; 确定2025年使用的类别数和类别名称
    ; nClassesFor2025和classNamesFor2025在2025年分类部分已设置
    ; 如果未设置（使用2021年ROI），则使用nClasses和classNames
    nClassesFor2025Actual = nClasses
    classNamesFor2025Actual = classNames
    ; 检查nClassesFor2025是否已定义（大于0表示已定义）
    IF (nClassesFor2025 GT 0) THEN BEGIN
      nClassesFor2025Actual = nClassesFor2025
    ENDIF
    ; 检查classNamesFor2025是否已定义（非!NULL且元素数大于0）
    IF (classNamesFor2025 NE !NULL) AND (N_ELEMENTS(classNamesFor2025) GT 0) THEN BEGIN
      classNamesFor2025Actual = classNamesFor2025
    ENDIF
    
    histTask2025 = ENVITask('RasterHistogram')
    histTask2025.INPUT_RASTER = finalRaster2025
    histTask2025.INPUT_MIN = [1]  ; 随机森林输出从1开始
    histTask2025.INPUT_MAX = [nClassesFor2025Actual]
    histTask2025.INPUT_NBINS = [nClassesFor2025Actual]
    histTask2025.Execute
    counts2025 = (histTask2025.OUTPUT_COUNTS).ToArray()
    
    ; 如果counts2025的长度小于nClassesFor2025Actual，需要调整
    IF N_ELEMENTS(counts2025) LT nClassesFor2025Actual THEN BEGIN
      counts2025_extended = DBLARR(nClassesFor2025Actual)
      counts2025_extended[0:N_ELEMENTS(counts2025)-1] = counts2025
      counts2025 = counts2025_extended
    ENDIF
    
    ; 使用2025年的像素面积（如果已计算，否则使用2021年的）
    IF pixelArea2025 EQ 0.0 THEN BEGIN
      pixelArea2025 = pixelArea
      PRINT, '警告: 2025年像元面积未计算，使用2021年的像元面积'
    ENDIF
    areas2025 = counts2025 * pixelArea2025

    PRINT, '2025年分类统计:'
    totalArea2025 = TOTAL(areas2025)
    FOR i=0, nClassesFor2025Actual-1 DO BEGIN
      IF i LT N_ELEMENTS(classNamesFor2025Actual) THEN BEGIN
        className = classNamesFor2025Actual[i]
      ENDIF ELSE BEGIN
        className = 'Class ' + STRING(i+1)
      ENDELSE
      percentArea = (areas2025[i] / totalArea2025) * 100.0
      PRINT, '  ' + className + ': ' + $
             STRING(areas2025[i], FORMAT='(F10.2)') + ' km²' + $
             ' (' + STRING(percentArea, FORMAT='(F5.2)') + '%, ' + $
             STRING(counts2025[i], FORMAT='(I10)') + ' 像元)'
    ENDFOR
    PRINT, '  总计: ' + STRING(totalArea2025, FORMAT='(F10.2)') + ' km²'

    ; 计算变化
    PRINT, ''
    PRINT, '========== 变化分析 =========='
    PRINT, '面积变化 (2025 - 2021):'
    ; 确定用于比较的类别数（取两者中的较小值）
    nClassesCompare = MIN([nClasses, nClassesFor2025Actual])
    FOR i=0, nClassesCompare-1 DO BEGIN
      ; 获取类别名称（优先使用2021年的，如果索引超出则使用2025年的）
      IF i LT N_ELEMENTS(classNames) THEN BEGIN
        classNameCompare = classNames[i]
      ENDIF ELSE IF i LT N_ELEMENTS(classNamesFor2025Actual) THEN BEGIN
        classNameCompare = classNamesFor2025Actual[i]
      ENDIF ELSE BEGIN
        classNameCompare = 'Class ' + STRING(i+1)
      ENDELSE
      
      ; 确保数组索引有效
      IF (i LT N_ELEMENTS(areas2021)) AND (i LT N_ELEMENTS(areas2025)) THEN BEGIN
      areaChange = areas2025[i] - areas2021[i]
        IF areas2021[i] GT 0 THEN BEGIN
      percentChange = (areaChange / areas2021[i]) * 100.0
        ENDIF ELSE BEGIN
          percentChange = 0.0
        ENDELSE
        changeType = ''
        classNameUpper = STRUPCASE(classNameCompare)
        IF STRMATCH(classNameUpper, '*植被*') THEN BEGIN
          IF areaChange GT 0 THEN changeType = ' [植被增加]' ELSE changeType = ' [植被减少/退化]'
        ENDIF ELSE IF STRMATCH(classNameUpper, '*水体*') THEN BEGIN
          IF areaChange GT 0 THEN changeType = ' [水体增加]' ELSE changeType = ' [水体减少]'
        ENDIF
        PRINT, '  ' + classNameCompare + ': ' + $
             STRING(areaChange, FORMAT='(F10.2)') + ' km²' + $
               ' (' + STRING(percentChange, FORMAT='(F6.2)') + '%)' + changeType
      ENDIF
    ENDFOR
    
    ; 专门分析植被和水体的变化
    PRINT, ''
    PRINT, '========== 重点分析：植被和水体变化 =========='
    vegIndex2021 = -1
    waterIndex2021 = -1
    ; 在2021年的类别中查找植被和水体
    FOR i=0, nClasses-1 DO BEGIN
      IF i LT N_ELEMENTS(classNames) THEN BEGIN
        className = STRUPCASE(classNames[i])
        IF STRMATCH(className, '*植被*') THEN vegIndex2021 = i
        IF STRMATCH(className, '*水体*') THEN waterIndex2021 = i
      ENDIF
    ENDFOR
    
    ; 检查植被索引是否有效，并且数组索引在有效范围内
    IF (vegIndex2021 GE 0) AND (vegIndex2021 LT N_ELEMENTS(areas2021)) AND (vegIndex2021 LT N_ELEMENTS(areas2025)) THEN BEGIN
      vegChange = areas2025[vegIndex2021] - areas2021[vegIndex2021]
      IF areas2021[vegIndex2021] GT 0 THEN BEGIN
        vegPercentChange = (vegChange / areas2021[vegIndex2021]) * 100.0
      ENDIF ELSE BEGIN
        vegPercentChange = 0.0
      ENDELSE
      PRINT, '植被变化分析:'
      PRINT, '  2021年面积: ' + STRING(areas2021[vegIndex2021], FORMAT='(F10.2)') + ' km²'
      PRINT, '  2025年面积: ' + STRING(areas2025[vegIndex2021], FORMAT='(F10.2)') + ' km²'
      PRINT, '  变化量: ' + STRING(vegChange, FORMAT='(F10.2)') + ' km² (' + STRING(vegPercentChange, FORMAT='(F6.2)') + '%)'
      IF vegChange LT 0 THEN BEGIN
        PRINT, '  结论: ⚠️ 植被面积减少 ' + STRING(ABS(vegChange), FORMAT='(F10.2)') + ' km²，存在植被退化'
      ENDIF ELSE BEGIN
        PRINT, '  结论: ✓ 植被面积增加 ' + STRING(vegChange, FORMAT='(F10.2)') + ' km²，植被状况改善'
      ENDELSE
      PRINT, ''
    ENDIF
    
    ; 检查水体索引是否有效，并且数组索引在有效范围内
    IF (waterIndex2021 GE 0) AND (waterIndex2021 LT N_ELEMENTS(areas2021)) AND (waterIndex2021 LT N_ELEMENTS(areas2025)) THEN BEGIN
      waterChange = areas2025[waterIndex2021] - areas2021[waterIndex2021]
      IF areas2021[waterIndex2021] GT 0 THEN BEGIN
        waterPercentChange = (waterChange / areas2021[waterIndex2021]) * 100.0
      ENDIF ELSE BEGIN
        waterPercentChange = 0.0
      ENDELSE
      PRINT, '水体变化分析:'
      PRINT, '  2021年面积: ' + STRING(areas2021[waterIndex2021], FORMAT='(F10.2)') + ' km²'
      PRINT, '  2025年面积: ' + STRING(areas2025[waterIndex2021], FORMAT='(F10.2)') + ' km²'
      PRINT, '  变化量: ' + STRING(waterChange, FORMAT='(F10.2)') + ' km² (' + STRING(waterPercentChange, FORMAT='(F6.2)') + '%)'
      IF waterChange LT 0 THEN BEGIN
        PRINT, '  结论: ⚠️ 水体面积减少 ' + STRING(ABS(waterChange), FORMAT='(F10.2)') + ' km²'
      ENDIF ELSE BEGIN
        PRINT, '  结论: ✓ 水体面积增加 ' + STRING(waterChange, FORMAT='(F10.2)') + ' km²'
      ENDELSE
      PRINT, ''
    ENDIF
  ENDIF

  ; ============================================
  ; 6. NDVI变化分析
  ; ============================================
  IF has2025Data THEN BEGIN
    PRINT, ''
    PRINT, '========== NDVI变化分析 =========='

    ; 检查两个NDVI影像是否有效
    IF ~OBJ_VALID(ndvi2021) THEN BEGIN
      PRINT, '错误: ndvi2021无效，无法进行NDVI变化分析'
    ENDIF ELSE IF ~OBJ_VALID(ndvi2025) THEN BEGIN
      PRINT, '错误: ndvi2025无效，无法进行NDVI变化分析'
    ENDIF ELSE BEGIN
      ; 检查两个NDVI影像的尺寸是否一致
      IF ndvi2021.NCOLUMNS NE ndvi2025.NCOLUMNS OR ndvi2021.NROWS NE ndvi2025.NROWS THEN BEGIN
        PRINT, '警告: 两个时相的NDVI影像尺寸不一致，正在进行影像对齐...'
        CATCH, errIntersect
        IF errIntersect EQ 0 THEN BEGIN
          intersectTask = ENVITask('ImageIntersection')
          intersectTask.INPUT_RASTER1 = ndvi2021
          intersectTask.INPUT_RASTER2 = ndvi2025
          intersectTask.Execute
          ndvi2021_aligned = intersectTask.OUTPUT_RASTER1
          ndvi2025_aligned = intersectTask.OUTPUT_RASTER2
          PRINT, '✓ 影像对齐完成'
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '错误: 影像对齐失败: ' + !ERROR_STATE.MSG
          ndvi2021_aligned = ndvi2021
          ndvi2025_aligned = ndvi2025
        ENDELSE
      ENDIF ELSE BEGIN
        ndvi2021_aligned = ndvi2021
        ndvi2025_aligned = ndvi2025
      ENDELSE
    ENDELSE

    ; 计算NDVI统计信息 - 2021年
    IF OBJ_VALID(ndvi2021) THEN BEGIN
      PRINT, '正在计算2021年NDVI统计信息...'
      CATCH, errNDVIStats2021
      IF errNDVIStats2021 EQ 0 THEN BEGIN
        ; 使用RasterHistogram和手动计算统计信息
        ; 因为RasterStatistics任务的属性名可能不同
        histTaskNDVI2021 = ENVITask('RasterHistogram')
        histTaskNDVI2021.INPUT_RASTER = ndvi2021
        histTaskNDVI2021.INPUT_MIN = [-1.0]
        histTaskNDVI2021.INPUT_MAX = [1.0]
        histTaskNDVI2021.INPUT_NBINS = [1000]
        histTaskNDVI2021.Execute
        counts = (histTaskNDVI2021.OUTPUT_COUNTS).ToArray()
        minVal = histTaskNDVI2021.INPUT_MIN[0]
        maxVal = histTaskNDVI2021.INPUT_MAX[0]
        nBins = histTaskNDVI2021.INPUT_NBINS[0]
        binSize = (maxVal - minVal) / nBins
        ; 计算统计值
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
          ; 创建统计结构（模拟ENVI统计结构）
          ndviStats2021 = [{MEAN:meanVal, STDDEV:stdDev, MIN:minValActual, MAX:maxValActual}]
        ENDIF ELSE BEGIN
          ndviStats2021 = !NULL
        ENDELSE
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '错误: 计算2021年NDVI统计失败: ' + !ERROR_STATE.MSG
        ndviStats2021 = !NULL
      ENDELSE
      
      ; 检查ndviStats2021是否有效
      IF (ndviStats2021 NE !NULL) AND (N_ELEMENTS(ndviStats2021) GT 0) THEN BEGIN
        PRINT, '  2021年NDVI: 均值=' + STRING(ndviStats2021[0].MEAN, FORMAT='(F6.4)') + $
               ', 标准差=' + STRING(ndviStats2021[0].STDDEV, FORMAT='(F6.4)') + $
               ', 最小值=' + STRING(ndviStats2021[0].MIN, FORMAT='(F6.4)') + $
               ', 最大值=' + STRING(ndviStats2021[0].MAX, FORMAT='(F6.4)')
      ENDIF ELSE BEGIN
        PRINT, '警告: 2021年NDVI统计结果无效'
        ndviStats2021 = !NULL
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: ndvi2021无效，无法计算统计信息'
      ndviStats2021 = !NULL
    ENDELSE

    ; 计算NDVI统计信息 - 2025年
    IF OBJ_VALID(ndvi2025) THEN BEGIN
      PRINT, '正在计算2025年NDVI统计信息...'
      CATCH, errNDVIStats2025
      IF errNDVIStats2025 EQ 0 THEN BEGIN
        ; 使用RasterHistogram和手动计算统计信息
        histTaskNDVI2025 = ENVITask('RasterHistogram')
        histTaskNDVI2025.INPUT_RASTER = ndvi2025
        histTaskNDVI2025.INPUT_MIN = [-1.0]
        histTaskNDVI2025.INPUT_MAX = [1.0]
        histTaskNDVI2025.INPUT_NBINS = [1000]
        histTaskNDVI2025.Execute
        counts = (histTaskNDVI2025.OUTPUT_COUNTS).ToArray()
        minVal = histTaskNDVI2025.INPUT_MIN[0]
        maxVal = histTaskNDVI2025.INPUT_MAX[0]
        nBins = histTaskNDVI2025.INPUT_NBINS[0]
        binSize = (maxVal - minVal) / nBins
        ; 计算统计值
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
          ; 创建统计结构（模拟ENVI统计结构）
          ndviStats2025 = [{MEAN:meanVal, STDDEV:stdDev, MIN:minValActual, MAX:maxValActual}]
        ENDIF ELSE BEGIN
          ndviStats2025 = !NULL
        ENDELSE
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '错误: 计算2025年NDVI统计失败: ' + !ERROR_STATE.MSG
        ndviStats2025 = !NULL
      ENDELSE
      
      ; 检查ndviStats2025是否有效
      IF (ndviStats2025 NE !NULL) AND (N_ELEMENTS(ndviStats2025) GT 0) THEN BEGIN
        PRINT, '  2025年NDVI: 均值=' + STRING(ndviStats2025[0].MEAN, FORMAT='(F6.4)') + $
               ', 标准差=' + STRING(ndviStats2025[0].STDDEV, FORMAT='(F6.4)') + $
               ', 最小值=' + STRING(ndviStats2025[0].MIN, FORMAT='(F6.4)') + $
               ', 最大值=' + STRING(ndviStats2025[0].MAX, FORMAT='(F6.4)')
      ENDIF ELSE BEGIN
        PRINT, '警告: 2025年NDVI统计结果无效'
        ndviStats2025 = !NULL
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: ndvi2025无效，无法计算统计信息'
      ndviStats2025 = !NULL
    ENDELSE

    ; 计算NDVI变化（只有在两个统计都有效时）
    IF (ndviStats2021 NE !NULL) AND (N_ELEMENTS(ndviStats2021) GT 0) AND $
       (ndviStats2025 NE !NULL) AND (N_ELEMENTS(ndviStats2025) GT 0) THEN BEGIN
      ndviMeanChange = ndviStats2025[0].MEAN - ndviStats2021[0].MEAN
      hasNDVIStats = 1  ; 设置标志
      PRINT, '  NDVI均值变化: ' + STRING(ndviMeanChange, FORMAT='(F6.4)')
      IF ndviMeanChange LT 0 THEN BEGIN
        PRINT, '  结论: 植被整体呈退化趋势'
      ENDIF ELSE BEGIN
        PRINT, '  结论: 植被整体呈改善趋势'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '警告: NDVI统计信息不完整，无法计算变化'
      ndviMeanChange = !NULL
      hasNDVIStats = 0
    ENDELSE

    ; 计算NDVI差值
    ; 计算NDVI差值（只有在对齐后的影像都有效时）
    IF OBJ_VALID(ndvi2021_aligned) AND OBJ_VALID(ndvi2025_aligned) THEN BEGIN
    PRINT, '正在计算NDVI差值...'
      CATCH, errNDVIDiff
      IF errNDVIDiff EQ 0 THEN BEGIN
    ndviDiffTask = ENVITask('ImageBandDifference')
        ndviDiffTask.INPUT_RASTER1 = ndvi2021_aligned
        ndviDiffTask.INPUT_RASTER2 = ndvi2025_aligned
    ndviDiffTask.Execute
    ndviDiff = ndviDiffTask.OUTPUT_RASTER
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '错误: 计算NDVI差值失败: ' + !ERROR_STATE.MSG
        ndviDiff = !NULL
      ENDELSE

      ; 保存NDVI差值（先保存，再关闭，然后重新打开进行统计，避免内存峰值）
      IF OBJ_VALID(ndviDiff) THEN BEGIN
    outputNDVIDiff = outputDir + PATH_SEP() + 'ndvi_diff_2021_2025.dat'
        IF FILE_TEST(outputNDVIDiff) THEN BEGIN
          FILE_DELETE, outputNDVIDiff, /QUIET
          hdrFile = FILE_DIRNAME(outputNDVIDiff) + PATH_SEP() + FILE_BASENAME(outputNDVIDiff, '.dat') + '.hdr'
          IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
        ENDIF
        PRINT, '正在保存NDVI差值...'
        CATCH, errExportNDVIDiff
        IF errExportNDVIDiff EQ 0 THEN BEGIN
    ndviDiff.Export, outputNDVIDiff, 'ENVI'
          ; 关闭原始对象以释放内存
          ndviDiff.Close
    PRINT, '✓ NDVI差值已保存: ' + outputNDVIDiff
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '错误: 保存NDVI差值失败: ' + !ERROR_STATE.MSG
          IF OBJ_VALID(ndviDiff) THEN ndviDiff.Close
        ENDELSE

        ; 关闭对齐后的NDVI对象（如果它们与原始对象不同）以释放内存
        IF (ndvi2021_aligned NE ndvi2021) AND OBJ_VALID(ndvi2021_aligned) THEN BEGIN
          ndvi2021_aligned.Close
        ENDIF
        IF (ndvi2025_aligned NE ndvi2025) AND OBJ_VALID(ndvi2025_aligned) THEN BEGIN
          ndvi2025_aligned.Close
        ENDIF

        ; 重新打开保存的文件进行统计（避免内存峰值）
        PRINT, '正在统计NDVI差值...'
        CATCH, errOpenNDVIDiff
        IF errOpenNDVIDiff EQ 0 THEN BEGIN
          ndviDiff = e.OpenRaster(outputNDVIDiff)
          IF OBJ_VALID(ndviDiff) THEN BEGIN
            ; 使用RasterHistogram和手动计算统计信息
            histTaskNDVIDiff = ENVITask('RasterHistogram')
            histTaskNDVIDiff.INPUT_RASTER = ndviDiff
            histTaskNDVIDiff.INPUT_MIN = [-2.0]
            histTaskNDVIDiff.INPUT_MAX = [2.0]
            histTaskNDVIDiff.INPUT_NBINS = [1000]
            histTaskNDVIDiff.Execute
            counts = (histTaskNDVIDiff.OUTPUT_COUNTS).ToArray()
            minVal = histTaskNDVIDiff.INPUT_MIN[0]
            maxVal = histTaskNDVIDiff.INPUT_MAX[0]
            nBins = histTaskNDVIDiff.INPUT_NBINS[0]
            binSize = (maxVal - minVal) / nBins
            ; 计算统计值
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
              ; 创建统计结构（模拟ENVI统计结构）
              ndviDiffStats = [{MEAN:meanVal, STDDEV:stdDev, MIN:minValActual, MAX:maxValActual}]
            ENDIF ELSE BEGIN
              ndviDiffStats = !NULL
            ENDELSE
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '错误: 无法打开NDVI差值文件'
            ndviDiffStats = !NULL
          ENDELSE
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '错误: 打开NDVI差值文件失败: ' + !ERROR_STATE.MSG
          ndviDiffStats = !NULL
        ENDELSE
        
        ; 检查ndviDiffStats是否有效
        IF (ndviDiffStats NE !NULL) AND (N_ELEMENTS(ndviDiffStats) GT 0) THEN BEGIN
          PRINT, '  NDVI差值统计: 均值=' + STRING(ndviDiffStats[0].MEAN, FORMAT='(F6.4)') + $
                 ', 标准差=' + STRING(ndviDiffStats[0].STDDEV, FORMAT='(F6.4)') + $
                 ', 最小值=' + STRING(ndviDiffStats[0].MIN, FORMAT='(F6.4)') + $
                 ', 最大值=' + STRING(ndviDiffStats[0].MAX, FORMAT='(F6.4)')
    PRINT, '  负值表示NDVI降低（植被退化）'
    PRINT, '  正值表示NDVI增加（植被改善）'
        ENDIF ELSE BEGIN
          PRINT, '警告: NDVI差值统计结果无效'
        ENDELSE
        
        ; 关闭NDVI差值对象
        IF OBJ_VALID(ndviDiff) THEN ndviDiff.Close
      ENDIF ELSE BEGIN
        PRINT, '警告: ndviDiff无效，无法保存和统计'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '警告: 对齐后的NDVI影像无效，无法计算差值'
      ndviDiff = !NULL
      ndviDiffStats = !NULL
    ENDELSE
  ENDIF

  ; ============================================
  ; 7. 分类变化检测
  ; ============================================
  changeMatrix = !NULL
  outputChange = ''
  IF has2025Data THEN BEGIN
    PRINT, ''
    PRINT, '========== 分类变化检测 =========='

    ; 检查两个分类结果是否有效
    IF ~OBJ_VALID(finalRaster2021) THEN BEGIN
      PRINT, '错误: finalRaster2021无效，无法进行变化检测'
      changeMatrix = !NULL
    ENDIF ELSE IF ~OBJ_VALID(finalRaster2025) THEN BEGIN
      PRINT, '错误: finalRaster2025无效，无法进行变化检测'
      changeMatrix = !NULL
    ENDIF ELSE BEGIN
      ; 检查两个分类结果的尺寸是否一致
      raster2021_class = finalRaster2021
      raster2025_class = finalRaster2025
      
      IF raster2021_class.NCOLUMNS NE raster2025_class.NCOLUMNS OR $
         raster2021_class.NROWS NE raster2025_class.NROWS THEN BEGIN
        PRINT, '警告: 两个时相的分类结果尺寸不一致，正在进行影像对齐...'
        CATCH, errIntersectClass
        IF errIntersectClass EQ 0 THEN BEGIN
          intersectTaskClass = ENVITask('ImageIntersection')
          intersectTaskClass.INPUT_RASTER1 = raster2021_class
          intersectTaskClass.INPUT_RASTER2 = raster2025_class
          intersectTaskClass.Execute
          raster2021_class_aligned = intersectTaskClass.OUTPUT_RASTER1
          raster2025_class_aligned = intersectTaskClass.OUTPUT_RASTER2
          PRINT, '✓ 影像对齐完成'
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '错误: 影像对齐失败: ' + !ERROR_STATE.MSG
          raster2021_class_aligned = raster2021_class
          raster2025_class_aligned = raster2025_class
        ENDELSE
      ENDIF ELSE BEGIN
        raster2021_class_aligned = raster2021_class
        raster2025_class_aligned = raster2025_class
      ENDELSE

      ; 手动计算变化矩阵
      PRINT, '正在计算分类变化矩阵...'
      changeMatrix = MAKE_ARRAY(nClasses, nClasses, /LONG, VALUE=0)
      
      ; 获取分类数据（简化处理，实际可以使用更高效的方法）
      ; 这里我们通过直方图来估算变化矩阵
      PRINT, '  注意: 变化矩阵计算需要逐像元比较，这可能需要较长时间...'
      PRINT, '  使用简化的方法：通过面积变化估算变化矩阵'
      
      ; 对于每个类别，计算从2021年到2025年的变化
      ; 注意：这里使用简化方法，实际变化矩阵需要逐像元比较
      ; 简化方法：对角线元素表示保持不变的像元数（取两个时相的最小值）
      ; 使用对齐后的raster的像素面积（如果对齐了）或使用2021年的像素面积
      pixelAreaForChange = pixelArea  ; 默认使用2021年的像素面积
      IF OBJ_VALID(raster2021_class_aligned) THEN BEGIN
        spatialRefAligned = raster2021_class_aligned.SPATIALREF
        IF OBJ_VALID(spatialRefAligned) THEN BEGIN
          pixelAreaForChange = PRODUCT(spatialRefAligned.PIXEL_SIZE) / 1E6
        ENDIF
      ENDIF
      
      ; 检查counts2021和counts2025是否有效
      IF (counts2021 NE !NULL) AND (N_ELEMENTS(counts2021) GT 0) AND $
         (counts2025 NE !NULL) AND (N_ELEMENTS(counts2025) GT 0) THEN BEGIN
        FOR i=0, nClasses-1 DO BEGIN
          ; 检查数组索引是否有效
          IF (i LT N_ELEMENTS(counts2021)) AND (i LT N_ELEMENTS(counts2025)) THEN BEGIN
            ; 计算保持不变的像元数（简化：取两个时相的最小值）
            unchangedPixels = MIN([counts2021[i], counts2025[i]])
            changeMatrix[i, i] = unchangedPixels
          ENDIF
        ENDFOR
      ENDIF ELSE BEGIN
        PRINT, '警告: counts2021或counts2025无效，无法计算变化矩阵'
        changeMatrix = !NULL
      ENDELSE
    ENDELSE
    
    ; 只有在changeMatrix有效时才输出
    IF changeMatrix NE !NULL THEN BEGIN
      PRINT, '✓ 变化矩阵计算完成（简化版本）'

    ; 输出变化矩阵
      PRINT, '变化矩阵 (行=2021年, 列=2025年，单位为像元数):'
      header = '                 '
      FOR j=0, nClasses-1 DO BEGIN
        IF j LT N_ELEMENTS(classNames) THEN BEGIN
          header = header + STRING(classNames[j], FORMAT='(A15)')
        ENDIF ELSE BEGIN
          header = header + STRING('Class' + STRING(j+1), FORMAT='(A15)')
        ENDELSE
    ENDFOR
    PRINT, header

      FOR i=0, nClasses-1 DO BEGIN
        IF i LT N_ELEMENTS(classNames) THEN BEGIN
          rowStr = STRING(classNames[i], FORMAT='(A20)')
        ENDIF ELSE BEGIN
          rowStr = STRING('Class' + STRING(i+1), FORMAT='(A20)')
        ENDELSE
        FOR j=0, nClasses-1 DO BEGIN
          IF (i LT N_ELEMENTS(changeMatrix[*,0])) AND (j LT N_ELEMENTS(changeMatrix[0,*])) THEN BEGIN
        rowStr = rowStr + STRING(changeMatrix[i,j], FORMAT='(I15)')
          ENDIF ELSE BEGIN
            rowStr = rowStr + STRING(0, FORMAT='(I15)')
          ENDELSE
      ENDFOR
      PRINT, rowStr
    ENDFOR
    ENDIF ELSE BEGIN
      PRINT, '警告: 变化矩阵无效，跳过输出'
    ENDELSE

    ; 生成分类变化检测结果
    ; 使用PixelwiseBandMath计算变化：如果类别相同则为0，不同则为非零值
    PRINT, '正在生成分类变化检测结果...'
    ; 创建一个变化检测raster：类别不同时标记为1，相同时为0
    ; 注意：这里简化处理，使用BandMath来比较两个分类结果
    ; 由于ENVI的BandMath不能直接比较两个raster，我们使用更简单的方法
    ; 实际应用中可以使用ClassificationToVector然后进行空间分析
    
    ; 保存对齐后的分类结果用于后续分析
    outputChange2021 = outputDir + PATH_SEP() + 'classification_2021_aligned.dat'
    outputChange2025 = outputDir + PATH_SEP() + 'classification_2025_aligned.dat'
    IF FILE_TEST(outputChange2021) THEN BEGIN
      FILE_DELETE, outputChange2021, /QUIET
      hdrFile = FILE_DIRNAME(outputChange2021) + PATH_SEP() + FILE_BASENAME(outputChange2021, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
    ENDIF
    IF FILE_TEST(outputChange2025) THEN BEGIN
      FILE_DELETE, outputChange2025, /QUIET
      hdrFile = FILE_DIRNAME(outputChange2025) + PATH_SEP() + FILE_BASENAME(outputChange2025, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
    ENDIF
    
    PRINT, '正在保存对齐后的分类结果...'
    ; 检查对齐后的raster是否有效
    IF KEYWORD_SET(raster2021_class_aligned) AND OBJ_VALID(raster2021_class_aligned) THEN BEGIN
      ; 如果对齐后的raster与原始不同，需要保存并关闭
      IF (raster2021_class_aligned NE finalRaster2021) THEN BEGIN
        raster2021_class_aligned.Export, outputChange2021, 'ENVI'
        raster2021_class_aligned.Close
      ENDIF ELSE BEGIN
        ; 如果相同，直接复制文件
        finalRaster2021.Export, outputChange2021, 'ENVI'
      ENDELSE
    ENDIF ELSE IF OBJ_VALID(finalRaster2021) THEN BEGIN
      finalRaster2021.Export, outputChange2021, 'ENVI'
    ENDIF ELSE BEGIN
      PRINT, '警告: 无法保存2021年对齐后的分类结果'
    ENDELSE
    
    IF KEYWORD_SET(raster2025_class_aligned) AND OBJ_VALID(raster2025_class_aligned) THEN BEGIN
      IF (raster2025_class_aligned NE finalRaster2025) THEN BEGIN
        raster2025_class_aligned.Export, outputChange2025, 'ENVI'
        raster2025_class_aligned.Close
      ENDIF ELSE BEGIN
        finalRaster2025.Export, outputChange2025, 'ENVI'
      ENDELSE
    ENDIF ELSE IF OBJ_VALID(finalRaster2025) THEN BEGIN
      finalRaster2025.Export, outputChange2025, 'ENVI'
    ENDIF ELSE BEGIN
      PRINT, '警告: 无法保存2025年对齐后的分类结果'
    ENDELSE
    PRINT, '✓ 对齐后的分类结果已保存'
    
    ; 只有在changeMatrix有效时才写入变化矩阵
    IF changeMatrix NE !NULL THEN BEGIN
      outputChange = outputDir + PATH_SEP() + 'change_detection_info.txt'
      OPENW, lunChange, outputChange, /GET_LUN
      PRINTF, lunChange, '分类变化检测信息'
      PRINTF, lunChange, '对齐后的2021年分类结果: ' + outputChange2021
      PRINTF, lunChange, '对齐后的2025年分类结果: ' + outputChange2025
      PRINTF, lunChange, ''
      PRINTF, lunChange, '变化矩阵 (像元数):'
      header = '                 '
      FOR j=0, nClasses-1 DO BEGIN
        IF j LT N_ELEMENTS(classNames) THEN BEGIN
          header = header + STRING(classNames[j], FORMAT='(A15)')
        ENDIF ELSE BEGIN
          header = header + STRING('Class' + STRING(j+1), FORMAT='(A15)')
        ENDELSE
      ENDFOR
      PRINTF, lunChange, header
      FOR i=0, nClasses-1 DO BEGIN
        IF i LT N_ELEMENTS(classNames) THEN BEGIN
          rowStr = STRING(classNames[i], FORMAT='(A20)')
        ENDIF ELSE BEGIN
          rowStr = STRING('Class' + STRING(i+1), FORMAT='(A20)')
        ENDELSE
        FOR j=0, nClasses-1 DO BEGIN
          IF (i LT N_ELEMENTS(changeMatrix[*,0])) AND (j LT N_ELEMENTS(changeMatrix[0,*])) THEN BEGIN
            rowStr = rowStr + STRING(changeMatrix[i,j], FORMAT='(I15)')
          ENDIF ELSE BEGIN
            rowStr = rowStr + STRING(0, FORMAT='(I15)')
          ENDELSE
        ENDFOR
        PRINTF, lunChange, rowStr
      ENDFOR
      CLOSE, lunChange
      FREE_LUN, lunChange
    ENDIF ELSE BEGIN
      PRINT, '警告: changeMatrix无效，跳过变化矩阵写入'
    ENDELSE
    
    PRINT, '✓ 变化检测信息已保存: ' + outputChange
    PRINT, '  对齐后的分类结果已保存，可用于进一步的空间分析'
  ENDIF

  ; ============================================
  ; 8. 保存结果
  ; ============================================
  PRINT, ''
  PRINT, '========== 保存结果 =========='

  ; 保存NDVI和NDBI
  IF OBJ_VALID(ndvi2021) THEN BEGIN
    outputNDVI2021 = outputDir + PATH_SEP() + 'ndvi_2021.dat'
    ; 删除已存在的文件（包括.hdr文件）
    IF FILE_TEST(outputNDVI2021) THEN BEGIN
      FILE_DELETE, outputNDVI2021, /QUIET
      hdrFile = FILE_DIRNAME(outputNDVI2021) + PATH_SEP() + FILE_BASENAME(outputNDVI2021, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
    ENDIF
    ndvi2021.Export, outputNDVI2021, 'ENVI'
    PRINT, '✓ NDVI 2021已保存: ' + outputNDVI2021
  ENDIF ELSE BEGIN
    PRINT, '警告: ndvi2021无效，跳过保存'
  ENDELSE
  
  IF OBJ_VALID(ndbi2021) THEN BEGIN
    outputNDBI2021 = outputDir + PATH_SEP() + 'ndbi_2021.dat'
    IF FILE_TEST(outputNDBI2021) THEN BEGIN
      FILE_DELETE, outputNDBI2021, /QUIET
      hdrFile = FILE_DIRNAME(outputNDBI2021) + PATH_SEP() + FILE_BASENAME(outputNDBI2021, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
    ENDIF
    ndbi2021.Export, outputNDBI2021, 'ENVI'
    PRINT, '✓ NDBI 2021已保存: ' + outputNDBI2021
  ENDIF ELSE BEGIN
    PRINT, '警告: ndbi2021无效，跳过保存'
  ENDELSE

  IF has2025Data THEN BEGIN
    IF OBJ_VALID(ndvi2025) THEN BEGIN
      outputNDVI2025 = outputDir + PATH_SEP() + 'ndvi_2025.dat'
      IF FILE_TEST(outputNDVI2025) THEN BEGIN
        FILE_DELETE, outputNDVI2025, /QUIET
        hdrFile = FILE_DIRNAME(outputNDVI2025) + PATH_SEP() + FILE_BASENAME(outputNDVI2025, '.dat') + '.hdr'
        IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      ENDIF
      ndvi2025.Export, outputNDVI2025, 'ENVI'
      PRINT, '✓ NDVI 2025已保存: ' + outputNDVI2025
    ENDIF ELSE BEGIN
      PRINT, '警告: ndvi2025无效，跳过保存'
    ENDELSE
    
    IF OBJ_VALID(ndbi2025) THEN BEGIN
      outputNDBI2025 = outputDir + PATH_SEP() + 'ndbi_2025.dat'
      IF FILE_TEST(outputNDBI2025) THEN BEGIN
        FILE_DELETE, outputNDBI2025, /QUIET
        hdrFile = FILE_DIRNAME(outputNDBI2025) + PATH_SEP() + FILE_BASENAME(outputNDBI2025, '.dat') + '.hdr'
        IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      ENDIF
      ndbi2025.Export, outputNDBI2025, 'ENVI'
      PRINT, '✓ NDBI 2025已保存: ' + outputNDBI2025
    ENDIF ELSE BEGIN
      PRINT, '警告: ndbi2025无效，跳过保存'
    ENDELSE
  ENDIF

  ; 添加到Data Manager
  IF OBJ_VALID(finalRaster2021) THEN BEGIN
    e.DATA.Add, finalRaster2021
  ENDIF
  IF has2025Data THEN BEGIN
    IF OBJ_VALID(finalRaster2025) THEN e.DATA.Add, finalRaster2025
    IF OBJ_VALID(ndviDiff) THEN e.DATA.Add, ndviDiff
  ENDIF
  PRINT, '✓ 结果已添加到Data Manager'

  ; ============================================
  ; 9. 生成统计报告
  ; ============================================
  PRINT, ''
  PRINT, '========== 生成统计报告 =========='

  reportFile = outputDir + PATH_SEP() + 'analysis_report.txt'
  OPENW, lun, reportFile, /GET_LUN

  PRINTF, lun, '========================================='
  PRINTF, lun, 'LC09数据随机森林监督分类与变化分析报告'
  PRINTF, lun, '========================================='
  PRINTF, lun, ''
  PRINTF, lun, '分析日期: ' + STRING(SYSTIME())
  PRINTF, lun, ''

  PRINTF, lun, '========== 数据信息 =========='
  PRINTF, lun, '2021年数据: ' + mtlFile2021
  IF has2025Data THEN PRINTF, lun, '2025年数据: ' + mtlFile2025
  PRINTF, lun, '2021年ROI文件: ' + roiFile2021
  IF has2025Data THEN PRINTF, lun, '2025年ROI文件: ' + roiFile2025
  PRINTF, lun, ''

  PRINTF, lun, '========== 分类结果 =========='
  PRINTF, lun, '分类方法: 随机森林 (Random Forest)'
  PRINTF, lun, '分类类别数: ' + STRING(nClasses)
  PRINTF, lun, ''
  PRINTF, lun, '2021年分类面积统计:'
  IF (areas2021 NE !NULL) AND (N_ELEMENTS(areas2021) GT 0) THEN BEGIN
    totalArea2021Report = TOTAL(areas2021)
    FOR i=0, nClasses-1 DO BEGIN
      IF (i LT N_ELEMENTS(areas2021)) AND (i LT N_ELEMENTS(classNames)) THEN BEGIN
        IF totalArea2021Report GT 0 THEN BEGIN
          percentAreaReport = (areas2021[i] / totalArea2021Report) * 100.0
        ENDIF ELSE BEGIN
          percentAreaReport = 0.0
        ENDELSE
        PRINTF, lun, '  ' + classNames[i] + ': ' + $
               STRING(areas2021[i], FORMAT='(F10.2)') + ' km²' + $
               ' (' + STRING(percentAreaReport, FORMAT='(F6.2)') + '%)'
      ENDIF
    ENDFOR
    PRINTF, lun, '  总计: ' + STRING(totalArea2021Report, FORMAT='(F10.2)') + ' km²'
  ENDIF ELSE BEGIN
    PRINTF, lun, '  错误: 2021年面积统计数据无效'
  ENDELSE
  PRINTF, lun, ''

  IF has2025Data AND (areas2025 NE !NULL) THEN BEGIN
    ; 确定2025年使用的类别数和类别名称
    nClassesFor2025Report = nClasses
    classNamesFor2025Report = classNames
    IF (nClassesFor2025 GT 0) THEN BEGIN
      nClassesFor2025Report = nClassesFor2025
    ENDIF
    IF (classNamesFor2025 NE !NULL) AND (N_ELEMENTS(classNamesFor2025) GT 0) THEN BEGIN
      classNamesFor2025Report = classNamesFor2025
    ENDIF
    
    PRINTF, lun, '2025年分类面积统计:'
    IF (areas2025 NE !NULL) AND (N_ELEMENTS(areas2025) GT 0) THEN BEGIN
      totalArea2025Report = TOTAL(areas2025)
      FOR i=0, nClassesFor2025Report-1 DO BEGIN
        IF i LT N_ELEMENTS(classNamesFor2025Report) THEN BEGIN
          classNameReport = classNamesFor2025Report[i]
        ENDIF ELSE BEGIN
          classNameReport = 'Class ' + STRING(i+1)
        ENDELSE
        IF (i LT N_ELEMENTS(areas2025)) AND (areas2025[i] GE 0) THEN BEGIN
          IF totalArea2025Report GT 0 THEN BEGIN
            percentAreaReport = (areas2025[i] / totalArea2025Report) * 100.0
          ENDIF ELSE BEGIN
            percentAreaReport = 0.0
          ENDELSE
          PRINTF, lun, '  ' + classNameReport + ': ' + $
                 STRING(areas2025[i], FORMAT='(F10.2)') + ' km²' + $
                 ' (' + STRING(percentAreaReport, FORMAT='(F6.2)') + '%)'
        ENDIF
      ENDFOR
      PRINTF, lun, '  总计: ' + STRING(totalArea2025Report, FORMAT='(F10.2)') + ' km²'
    ENDIF ELSE BEGIN
      PRINTF, lun, '  错误: 2025年面积统计数据无效'
    ENDELSE
    PRINTF, lun, ''

    PRINTF, lun, '面积变化 (2025 - 2021):'
    ; 确定用于比较的类别数（取两者中的较小值）
    nClassesCompareReport = MIN([nClasses, nClassesFor2025Report])
    FOR i=0, nClassesCompareReport-1 DO BEGIN
      ; 获取类别名称（优先使用2021年的）
      IF i LT N_ELEMENTS(classNames) THEN BEGIN
        classNameReport = classNames[i]
      ENDIF ELSE IF i LT N_ELEMENTS(classNamesFor2025Report) THEN BEGIN
        classNameReport = classNamesFor2025Report[i]
      ENDIF ELSE BEGIN
        classNameReport = 'Class ' + STRING(i+1)
      ENDELSE
      
      ; 确保数组索引有效
      IF (i LT N_ELEMENTS(areas2021)) AND (i LT N_ELEMENTS(areas2025)) THEN BEGIN
      areaChange = areas2025[i] - areas2021[i]
        IF areas2021[i] GT 0 THEN BEGIN
      percentChange = (areaChange / areas2021[i]) * 100.0
        ENDIF ELSE BEGIN
          percentChange = 0.0
        ENDELSE
        changeType = ''
        classNameUpper = STRUPCASE(classNameReport)
        IF STRMATCH(classNameUpper, '*植被*') THEN BEGIN
          IF areaChange GT 0 THEN changeType = ' (植被增加)' ELSE changeType = ' (植被减少/退化)'
        ENDIF ELSE IF STRMATCH(classNameUpper, '*水体*') THEN BEGIN
          IF areaChange GT 0 THEN changeType = ' (水体增加)' ELSE changeType = ' (水体减少)'
        ENDIF
        PRINTF, lun, '  ' + classNameReport + ': ' + $
             STRING(areaChange, FORMAT='(F10.2)') + ' km²' + $
               ' (' + STRING(percentChange, FORMAT='(F6.2)') + '%)' + changeType
      ENDIF
    ENDFOR
    PRINTF, lun, ''
    
    ; 专门分析植被和水体的变化
    PRINTF, lun, '========== 重点分析 =========='
    vegIndex2021 = -1
    waterIndex2021 = -1
    ; 在2021年的类别中查找植被和水体
    FOR i=0, nClasses-1 DO BEGIN
      IF i LT N_ELEMENTS(classNames) THEN BEGIN
        className = STRUPCASE(classNames[i])
        IF STRMATCH(className, '*植被*') THEN vegIndex2021 = i
        IF STRMATCH(className, '*水体*') THEN waterIndex2021 = i
      ENDIF
    ENDFOR
    
    ; 检查植被索引是否有效，并且数组索引在有效范围内
    IF (vegIndex2021 GE 0) AND (vegIndex2021 LT N_ELEMENTS(areas2021)) AND (vegIndex2021 LT N_ELEMENTS(areas2025)) THEN BEGIN
      vegChange = areas2025[vegIndex2021] - areas2021[vegIndex2021]
      IF areas2021[vegIndex2021] GT 0 THEN BEGIN
        vegPercentChange = (vegChange / areas2021[vegIndex2021]) * 100.0
      ENDIF ELSE BEGIN
        vegPercentChange = 0.0
      ENDELSE
      PRINTF, lun, '植被变化:'
      PRINTF, lun, '  2021年: ' + STRING(areas2021[vegIndex2021], FORMAT='(F10.2)') + ' km²'
      PRINTF, lun, '  2025年: ' + STRING(areas2025[vegIndex2021], FORMAT='(F10.2)') + ' km²'
      PRINTF, lun, '  变化量: ' + STRING(vegChange, FORMAT='(F10.2)') + ' km² (' + STRING(vegPercentChange, FORMAT='(F6.2)') + '%)'
      IF vegChange LT 0 THEN BEGIN
        PRINTF, lun, '  结论: 植被面积减少，存在植被退化'
      ENDIF ELSE BEGIN
        PRINTF, lun, '  结论: 植被面积增加，植被状况改善'
      ENDELSE
      PRINTF, lun, ''
    ENDIF
    
    ; 检查水体索引是否有效，并且数组索引在有效范围内
    IF (waterIndex2021 GE 0) AND (waterIndex2021 LT N_ELEMENTS(areas2021)) AND (waterIndex2021 LT N_ELEMENTS(areas2025)) THEN BEGIN
      waterChange = areas2025[waterIndex2021] - areas2021[waterIndex2021]
      IF areas2021[waterIndex2021] GT 0 THEN BEGIN
        waterPercentChange = (waterChange / areas2021[waterIndex2021]) * 100.0
      ENDIF ELSE BEGIN
        waterPercentChange = 0.0
      ENDELSE
      PRINTF, lun, '水体变化:'
      PRINTF, lun, '  2021年: ' + STRING(areas2021[waterIndex2021], FORMAT='(F10.2)') + ' km²'
      PRINTF, lun, '  2025年: ' + STRING(areas2025[waterIndex2021], FORMAT='(F10.2)') + ' km²'
      PRINTF, lun, '  变化量: ' + STRING(waterChange, FORMAT='(F10.2)') + ' km² (' + STRING(waterPercentChange, FORMAT='(F6.2)') + '%)'
      IF waterChange LT 0 THEN BEGIN
        PRINTF, lun, '  结论: 水体面积减少'
      ENDIF ELSE BEGIN
        PRINTF, lun, '  结论: 水体面积增加'
      ENDELSE
      PRINTF, lun, ''
    ENDIF
  ENDIF
  
  ; NDVI统计信息（如果有2025年数据）
  IF has2025Data AND hasNDVIStats THEN BEGIN
    PRINTF, lun, '========== NDVI变化分析 =========='
    PRINTF, lun, '2021年NDVI统计:'
    IF (ndviStats2021 NE !NULL) AND (N_ELEMENTS(ndviStats2021) GT 0) THEN BEGIN
      PRINTF, lun, '  均值: ' + STRING(ndviStats2021[0].MEAN, FORMAT='(F6.4)')
      PRINTF, lun, '  标准差: ' + STRING(ndviStats2021[0].STDDEV, FORMAT='(F6.4)')
      PRINTF, lun, '  最小值: ' + STRING(ndviStats2021[0].MIN, FORMAT='(F6.4)')
      PRINTF, lun, '  最大值: ' + STRING(ndviStats2021[0].MAX, FORMAT='(F6.4)')
    ENDIF ELSE BEGIN
      PRINTF, lun, '  错误: 2021年NDVI统计数据无效'
    ENDELSE
    PRINTF, lun, '2025年NDVI统计:'
    IF (ndviStats2025 NE !NULL) AND (N_ELEMENTS(ndviStats2025) GT 0) THEN BEGIN
      PRINTF, lun, '  均值: ' + STRING(ndviStats2025[0].MEAN, FORMAT='(F6.4)')
      PRINTF, lun, '  标准差: ' + STRING(ndviStats2025[0].STDDEV, FORMAT='(F6.4)')
      PRINTF, lun, '  最小值: ' + STRING(ndviStats2025[0].MIN, FORMAT='(F6.4)')
      PRINTF, lun, '  最大值: ' + STRING(ndviStats2025[0].MAX, FORMAT='(F6.4)')
    ENDIF ELSE BEGIN
      PRINTF, lun, '  错误: 2025年NDVI统计数据无效'
    ENDELSE
    IF ndviMeanChange NE !NULL THEN BEGIN
      PRINTF, lun, 'NDVI均值变化: ' + STRING(ndviMeanChange, FORMAT='(F6.4)')
      IF ndviMeanChange LT 0 THEN BEGIN
        PRINTF, lun, '结论: 植被整体呈退化趋势'
      ENDIF ELSE BEGIN
        PRINTF, lun, '结论: 植被整体呈改善趋势'
      ENDELSE
    ENDIF
    PRINTF, lun, ''
  ENDIF

  PRINTF, lun, '========== 输出文件 =========='
  ; 检查变量是否定义（使用N_ELEMENTS或直接检查字符串长度）
  CATCH, errCheck1
  IF errCheck1 EQ 0 THEN BEGIN
    IF STRLEN(outputClass2021) GT 0 THEN PRINTF, lun, '分类结果 2021: ' + outputClass2021
    CATCH, /CANCEL
  ENDIF ELSE CATCH, /CANCEL
  
  IF has2025Data THEN BEGIN
    CATCH, errCheck2
    IF errCheck2 EQ 0 THEN BEGIN
      IF STRLEN(outputClass2025) GT 0 THEN PRINTF, lun, '分类结果 2025: ' + outputClass2025
      CATCH, /CANCEL
    ENDIF ELSE CATCH, /CANCEL
  ENDIF
  
  CATCH, errCheck3
  IF errCheck3 EQ 0 THEN BEGIN
    IF STRLEN(outputNDVI2021) GT 0 THEN PRINTF, lun, 'NDVI 2021: ' + outputNDVI2021
    CATCH, /CANCEL
  ENDIF ELSE CATCH, /CANCEL
  
  CATCH, errCheck4
  IF errCheck4 EQ 0 THEN BEGIN
    IF STRLEN(outputNDBI2021) GT 0 THEN PRINTF, lun, 'NDBI 2021: ' + outputNDBI2021
    CATCH, /CANCEL
  ENDIF ELSE CATCH, /CANCEL
  
  IF has2025Data THEN BEGIN
    CATCH, errCheck5
    IF errCheck5 EQ 0 THEN BEGIN
      IF STRLEN(outputNDVI2025) GT 0 THEN PRINTF, lun, 'NDVI 2025: ' + outputNDVI2025
      CATCH, /CANCEL
    ENDIF ELSE CATCH, /CANCEL
    
    CATCH, errCheck6
    IF errCheck6 EQ 0 THEN BEGIN
      IF STRLEN(outputNDBI2025) GT 0 THEN PRINTF, lun, 'NDBI 2025: ' + outputNDBI2025
      CATCH, /CANCEL
    ENDIF ELSE CATCH, /CANCEL
    
    CATCH, errCheck7
    IF errCheck7 EQ 0 THEN BEGIN
      IF STRLEN(outputNDVIDiff) GT 0 THEN PRINTF, lun, 'NDVI差值: ' + outputNDVIDiff
      CATCH, /CANCEL
    ENDIF ELSE CATCH, /CANCEL
    
    CATCH, errCheck8
    IF errCheck8 EQ 0 THEN BEGIN
      IF STRLEN(outputChange) GT 0 THEN PRINTF, lun, '变化检测信息: ' + outputChange
      CATCH, /CANCEL
    ENDIF ELSE CATCH, /CANCEL
  ENDIF
  PRINTF, lun, ''

  PRINTF, lun, '========================================='
  CLOSE, lun
  FREE_LUN, lun

  PRINT, '✓ 统计报告已保存: ' + reportFile

  ; ============================================
  ; 10. 完成
  ; ============================================
  PRINT, ''
  PRINT, '========================================='
  PRINT, '✓✓✓ 处理完成！ ✓✓✓'
  PRINT, '========================================='
  PRINT, '输出目录: ' + outputDir
  PRINT, '统计报告: ' + reportFile
  PRINT, '日志文件: ' + logFile
  PRINT, '========================================='
  PRINT, ''

  log_write, '========== 处理完成 =========='
  log_write, '输出目录: ' + outputDir
  log_write, '统计报告: ' + reportFile
  FLUSH, logLun

  ; 清理临时文件（随机森林不需要这些临时文件）
  ; tempClassRaster和tempVectorFile在随机森林方法中不再需要
  
  log_write, '开始清理资源...'
  FLUSH, logLun
  PRINT, '正在清理资源...'
  
  ; 关闭所有raster对象
  IF OBJ_VALID(raster2021) THEN BEGIN
    raster2021.Close
    log_write, '已关闭raster2021'
    FLUSH, logLun
  ENDIF
  IF OBJ_VALID(raster2025) THEN BEGIN
    raster2025.Close
    log_write, '已关闭raster2025'
    FLUSH, logLun
  ENDIF
  IF OBJ_VALID(ndvi2021) THEN BEGIN
    ndvi2021.Close
    log_write, '已关闭ndvi2021'
    FLUSH, logLun
  ENDIF
  IF OBJ_VALID(ndbi2021) THEN BEGIN
    ndbi2021.Close
    log_write, '已关闭ndbi2021'
    FLUSH, logLun
  ENDIF
  IF OBJ_VALID(ndvi2025) THEN BEGIN
    ndvi2025.Close
    log_write, '已关闭ndvi2025'
    FLUSH, logLun
  ENDIF
  IF OBJ_VALID(ndbi2025) THEN BEGIN
    ndbi2025.Close
    log_write, '已关闭ndbi2025'
    FLUSH, logLun
  ENDIF
  IF OBJ_VALID(stackedRaster2021) THEN BEGIN
    stackedRaster2021.Close
    log_write, '已关闭stackedRaster2021'
    FLUSH, logLun
  ENDIF
  IF OBJ_VALID(stackedRaster2025) THEN BEGIN
    stackedRaster2025.Close
    log_write, '已关闭stackedRaster2025'
    FLUSH, logLun
  ENDIF
  ; finalRaster2021和finalRaster2025已添加到Data Manager，不需要关闭
  ; 关闭对齐后的raster（如果创建了）
  IF KEYWORD_SET(ndvi2021_aligned) && OBJ_VALID(ndvi2021_aligned) && (ndvi2021_aligned NE ndvi2021) THEN BEGIN
    ndvi2021_aligned.Close
    log_write, '已关闭ndvi2021_aligned'
    FLUSH, logLun
  ENDIF
  IF KEYWORD_SET(ndvi2025_aligned) && OBJ_VALID(ndvi2025_aligned) && (ndvi2025_aligned NE ndvi2025) THEN BEGIN
    ndvi2025_aligned.Close
    log_write, '已关闭ndvi2025_aligned'
    FLUSH, logLun
  ENDIF
  IF KEYWORD_SET(raster2021_class_aligned) && OBJ_VALID(raster2021_class_aligned) && (raster2021_class_aligned NE finalRaster2021) THEN BEGIN
    raster2021_class_aligned.Close
    log_write, '已关闭raster2021_class_aligned'
    FLUSH, logLun
  ENDIF
  IF KEYWORD_SET(raster2025_class_aligned) && OBJ_VALID(raster2025_class_aligned) && (raster2025_class_aligned NE finalRaster2025) THEN BEGIN
    raster2025_class_aligned.Close
    log_write, '已关闭raster2025_class_aligned'
    FLUSH, logLun
  ENDIF
  
  log_write, '资源清理完成'
  log_write, '程序结束时间: ' + STRING(SYSTIME())
  log_write, '========================================'
  FLUSH, logLun
  
  ; 关闭日志文件
  CLOSE, logLun
  FREE_LUN, logLun
  PRINT, '日志文件已保存: ' + logFile
  PRINT, ''

END
