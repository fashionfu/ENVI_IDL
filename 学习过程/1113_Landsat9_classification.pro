;+
; 程序名: landsat9_classification.pro
; 功能: 对2021和2025年Landsat 9数据进行随机森林监督分类
;       包括平滑和聚合后处理，去除小斑点
; 输入: ROI文件、光谱指数结果（NDVI、NDWI、NDBI）
; 输出: 分类结果（保存到results文件夹）
; 作者: Auto
; 日期: 2025-11-13
;-

; 辅助函数：从XML文件中提取标签值（通用函数）
FUNCTION extract_xml_tag_value, xmlLines, tagName, defaultValue
  COMPILE_OPT IDL2
  
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
  
  ; 解析XML获取投影参数
  utmZone = 50
  datum = 'WGS84'
  pixelSize = 30.0
  ulX = 225900.0
  ulY = 2833200.0
  
  ; 使用辅助函数提取XML标签值
  datumStr = extract_xml_tag_value(xmlLines, 'DATUM', 'WGS84')
  IF STRMATCH(datumStr, '*WGS84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE IF STRMATCH(datumStr, '*WGS-84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE BEGIN
    datum = datumStr
  ENDELSE
  
  zoneStr = extract_xml_tag_value(xmlLines, 'UTM_ZONE', '50')
  utmZone = FIX(STRTRIM(zoneStr, 2))
  
  ulXStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_PROJECTION_X_PRODUCT', '225900.0')
  IF STRLEN(ulXStr) GT 0 THEN ulX = FLOAT(STRTRIM(ulXStr, 2))
  
  ulYStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_PROJECTION_Y_PRODUCT', '2833200.0')
  IF STRLEN(ulYStr) GT 0 THEN ulY = FLOAT(STRTRIM(ulYStr, 2))
  
  psStr = extract_xml_tag_value(xmlLines, 'GRID_CELL_SIZE_REFLECTIVE', '30.0')
  IF STRLEN(psStr) GT 0 THEN pixelSize = FLOAT(STRTRIM(psStr, 2))
  
  ; 创建MAP_INFO
  PRINT, '  正在创建MAP_INFO结构体...'
  mapInfo = !NULL
  CATCH, errMapInfo
  IF errMapInfo EQ 0 THEN BEGIN
    mapInfo = ENVI_MAP_INFO_CREATE( $
      /UTM, $
      ZONE=utmZone, $
      /NORTH, $
      DATUM=datum, $
      MC=[0.0, 0.0, ulX, ulY], $
      PS=[pixelSize, pixelSize] $
    )
    CATCH, /CANCEL
    IF mapInfo EQ !NULL THEN BEGIN
      PRINT, '  错误: ENVI_MAP_INFO_CREATE返回!NULL'
      RETURN, !NULL
    ENDIF
    nElements = N_ELEMENTS(mapInfo)
    IF nElements EQ 0 THEN BEGIN
      PRINT, '  错误: ENVI_MAP_INFO_CREATE返回空结构体'
      RETURN, !NULL
    ENDIF
    PRINT, '  ✓ MAP_INFO结构体创建成功 (N_ELEMENTS=' + STRING(nElements) + ')'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 创建MAP_INFO时发生异常: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  
  RETURN, mapInfo
END

; 辅助函数：为raster设置空间参考（简化版本，用于分类）
FUNCTION set_spatial_ref_to_raster, inputRaster, mapInfo
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  IF ~OBJ_VALID(inputRaster) THEN BEGIN
    PRINT, '  错误: inputRaster对象无效，无法导出'
    RETURN, !NULL
  ENDIF
  
  ; 导出raster到临时文件（尝试多种方法）
  PRINT, '  正在导出raster到临时文件...'
  tempDirLocal = 'E:\1027IDL\ENVITaskTrainning\Temp'
  IF ~FILE_TEST(tempDirLocal, /DIRECTORY) THEN BEGIN
    CATCH, errMkTempDir
    IF errMkTempDir EQ 0 THEN BEGIN
      FILE_MKDIR, tempDirLocal
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  tempBaseName = 'temp_raster_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
  tempFile = tempDirLocal + PATH_SEP() + tempBaseName
  
  IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
  hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
  IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  
  ; 方法1: 直接使用Export方法
  exportSuccess = 0
  CATCH, errExport
  IF errExport EQ 0 THEN BEGIN
    inputRaster.Export, tempFile, 'ENVI'
    WAIT, 0.5
    IF FILE_TEST(tempFile) THEN BEGIN
      PRINT, '  ✓ 使用方法1（直接Export）成功'
      exportSuccess = 1
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
  ENDELSE
  
  ; 方法2: 如果方法1失败，尝试使用GetTemporaryFilename
  IF exportSuccess EQ 0 THEN BEGIN
    PRINT, '  方法1失败，尝试方法2（使用GetTemporaryFilename）...'
    CATCH, errExport2
    IF errExport2 EQ 0 THEN BEGIN
      tempFile = e.GetTemporaryFilename('dat')
      inputRaster.Export, tempFile, 'ENVI'
      WAIT, 0.5
      IF FILE_TEST(tempFile) THEN BEGIN
        PRINT, '  ✓ 使用方法2（GetTemporaryFilename）成功'
        exportSuccess = 1
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  
  ; 方法3: 如果方法2失败，尝试使用RasterExport任务
  IF exportSuccess EQ 0 THEN BEGIN
    PRINT, '  方法2失败，尝试方法3（使用RasterExport任务）...'
    CATCH, errExport3
    IF errExport3 EQ 0 THEN BEGIN
      ; 重新生成临时文件名
      tempBaseName = 'temp_raster_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
      tempFile = tempDirLocal + PATH_SEP() + tempBaseName
      IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
      hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      
      exportTask = ENVITask('RasterExport')
      exportTask.INPUT_RASTER = inputRaster
      exportTask.OUTPUT_RASTER_URI = tempFile
      exportTask.Execute
      WAIT, 1.0
      IF FILE_TEST(tempFile) THEN BEGIN
        PRINT, '  ✓ 使用方法3（RasterExport任务）成功'
        exportSuccess = 1
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  
  ; 方法4: 如果方法3失败，尝试使用ExportRasterToENVI任务
  IF exportSuccess EQ 0 THEN BEGIN
    PRINT, '  方法3失败，尝试方法4（使用ExportRasterToENVI任务）...'
    CATCH, errExport4
    IF errExport4 EQ 0 THEN BEGIN
      ; 重新生成临时文件名
      tempBaseName = 'temp_raster_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
      tempFile = tempDirLocal + PATH_SEP() + tempBaseName
      IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
      hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
      IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      
      exportTask2 = ENVITask('ExportRasterToENVI')
      exportTask2.INPUT_RASTER = inputRaster
      exportTask2.OUTPUT_RASTER_URI = tempFile
      exportTask2.Execute
      WAIT, 1.0
      IF FILE_TEST(tempFile) THEN BEGIN
        PRINT, '  ✓ 使用方法4（ExportRasterToENVI任务）成功'
        exportSuccess = 1
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  
  ; 如果所有方法都失败
  IF exportSuccess EQ 0 THEN BEGIN
    PRINT, '  错误: 所有导出方法都失败'
    PRINT, '  可能原因:'
    PRINT, '    1. TIF文件可能是只读的'
    PRINT, '    2. 磁盘空间不足'
    PRINT, '    3. 文件权限问题'
    RETURN, !NULL
  ENDIF
  
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
  
  ; 步骤1: 数据验证
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
    
    IF (maxValInput GT (nClasses + 5)) OR (minValInput LT -1) THEN BEGIN
      PRINT, '[' + year + '后处理] 警告: 输入数据值异常，将跳过聚合步骤'
      skipAggregation = 1
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    skipAggregation = 1
  ENDELSE
  
  ; 步骤2: 分类平滑
  PRINT, '[' + year + '后处理] 步骤2: 分类平滑...'
  smoothTask = ENVITask('ClassificationSmoothing')
  smoothTask.INPUT_RASTER = classifiedRaster
  smoothTask.KERNEL_SIZE = 5
  smoothTask.Execute
  smoothRaster = smoothTask.OUTPUT_RASTER
  
  IF ~OBJ_VALID(smoothRaster) THEN BEGIN
    PRINT, '[' + year + '后处理] 错误: 平滑处理失败'
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
      skipAggregation = 1
    ENDIF
    IF nonZeroSmooth LT (N_ELEMENTS(sampleSmooth) * 0.01) THEN BEGIN
      skipAggregation = 1
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    skipAggregation = 1
  ENDELSE
  
  ; 步骤3: 分类聚合
  useAggregation = 0
  methodUsed = ''
  finalRaster = !NULL
  
  IF skipAggregation EQ 1 THEN BEGIN
    PRINT, '[' + year + '后处理] 步骤3: 跳过聚合（数据异常），直接使用平滑结果'
    smoothRaster.Export, outputFile, 'ENVI'
    WAIT, 1.0
    finalRaster = e.OpenRaster(outputFile)
    methodUsed = '仅平滑（数据异常，跳过聚合）'
  ENDIF ELSE BEGIN
    PRINT, '[' + year + '后处理] 步骤3: 分类聚合（三种方法）...'
    
    ; 计算聚合阈值
    aggregateSize = 0
    IF OBJ_VALID(spatialRef) THEN BEGIN
      pixelArea = PRODUCT(spatialRef.PIXEL_SIZE) / 1E6
      minArea = 0.01
      aggregateSize = FIX(minArea * 1E6 / PRODUCT(spatialRef.PIXEL_SIZE))
      IF aggregateSize LT 9 THEN aggregateSize = 9  ; 最小聚合大小为9
    ENDIF ELSE BEGIN
      aggregateSize = 50
    ENDELSE
    
    ; 方法1: 使用原始聚合参数
    IF aggregateSize GT 9 THEN BEGIN
      PRINT, '[' + year + '后处理]   方法1: 使用原始聚合参数（MINIMUM_SIZE=' + STRING(aggregateSize) + '）'
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
              PRINT, '[' + year + '后处理]   ✓ 方法1成功，数据有效'
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
      ENDELSE
    ENDIF
    
    ; 方法2: 使用更小的聚合阈值
    IF useAggregation EQ 0 THEN BEGIN
      PRINT, '[' + year + '后处理]   方法2: 使用更小的聚合阈值（MINIMUM_SIZE=5）'
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
    
    ; 植被 - 绿色
    IF STRMATCH(className, '*植被*') OR STRMATCH(className, '*VEG*') OR STRMATCH(className, '*植*') OR $
       STRMATCH(className, '*VEGETATION*') OR STRMATCH(className, '*植物*') THEN BEGIN
      classRGB[*, i+1] = [0, 255, 0]  ; 绿色
    ENDIF ELSE IF STRMATCH(className, '*水体*') OR STRMATCH(className, '*WATER*') OR STRMATCH(className, '*水*') THEN BEGIN
      ; 水体 - 蓝色
      classRGB[*, i+1] = [0, 0, 255]  ; 蓝色
    ENDIF ELSE IF STRMATCH(className, '*其他*') OR STRMATCH(className, '*OTHER*') OR STRMATCH(className, '*其*') OR $
                STRMATCH(className, '*其它*') THEN BEGIN
      ; 其他 - 灰色
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

; 处理单一年份的分类
; 参数：
;   dataPath: 数据路径
;   year: 年份字符串
;   roiFile: ROI文件路径
;   outputDir: 输出目录
;   useSpectralIndices: 是否使用光谱指数（可选，默认1=使用，0=不使用）
FUNCTION process_year_classification, dataPath, year, roiFile, outputDir, useSpectralIndices=useSpectralIndices
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  ; 默认使用光谱指数（原始波段 + NDVI、NDWI、NDBI）
  IF ~ARG_PRESENT(useSpectralIndices) THEN useSpectralIndices = 1
  
  PRINT, '========== ' + year + '年随机森林分类 =========='
  
  ; 打开原始数据
  mtlFiles = FILE_SEARCH(dataPath, '*_MTL.txt', COUNT=count)
  IF count EQ 0 THEN BEGIN
    PRINT, '错误: 未找到' + year + '年MTL文件: ' + dataPath
    RETURN, !NULL
  ENDIF
  mtlFile = mtlFiles[0]
  PRINT, '找到的MTL文件: ' + mtlFile
  
  ; 打开数据（尝试多种方法）
  raster = !NULL
  
  ; 首先尝试不指定数据集名称，查看所有可用数据集
  PRINT, '正在检查可用的数据集...'
  CATCH, errCheck
  IF errCheck EQ 0 THEN BEGIN
    allRasters = e.OpenRaster(mtlFile)
    CATCH, /CANCEL
    IF (allRasters NE !NULL) AND (N_ELEMENTS(allRasters) GT 0) THEN BEGIN
      PRINT, '找到 ' + STRING(N_ELEMENTS(allRasters)) + ' 个数据集:'
      FOR i=0, N_ELEMENTS(allRasters)-1 DO BEGIN
        IF OBJ_VALID(allRasters[i]) THEN BEGIN
          datasetName = allRasters[i].DATASET_NAME
          PRINT, '  数据集 ' + STRING(i) + ': ' + datasetName
        ENDIF
      ENDFOR
      ; 优先使用第一个数据集（通常是多光谱数据）
      raster = allRasters[0]
      PRINT, '使用数据集: ' + raster.DATASET_NAME
    ENDIF
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '警告: 无法打开MTL文件查看数据集列表'
  ENDELSE
  
  ; 如果上面的方法失败，尝试指定数据集名称
  IF ~OBJ_VALID(raster) THEN BEGIN
    PRINT, '尝试使用指定的数据集名称...'
    ; 尝试多种可能的数据集名称
    datasetNames = ['Multispectral', 'Surface Reflectance', 'Top of Atmosphere Reflectance']
    
    FOR dsIdx=0, N_ELEMENTS(datasetNames)-1 DO BEGIN
      IF ~OBJ_VALID(raster) THEN BEGIN
        datasetName = datasetNames[dsIdx]
        PRINT, '  尝试数据集名称: ' + datasetName
        CATCH, err1
        IF err1 EQ 0 THEN BEGIN
          tempRaster = e.OpenRaster(mtlFile, DATASET_NAME=datasetName)
          CATCH, /CANCEL
          IF tempRaster NE !NULL THEN BEGIN
            IF N_ELEMENTS(tempRaster) GT 1 THEN BEGIN
              raster = tempRaster[0]
            ENDIF ELSE IF N_ELEMENTS(tempRaster) EQ 1 THEN BEGIN
              raster = tempRaster
            ENDIF
            IF OBJ_VALID(raster) THEN BEGIN
              PRINT, '  ✓ 成功使用数据集: ' + datasetName
              BREAK
            ENDIF
          ENDIF
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
      ENDIF
    ENDFOR
  ENDIF
  
  ; 如果还是失败，尝试使用ExtractRasterFromFile任务
  IF ~OBJ_VALID(raster) THEN BEGIN
    PRINT, '尝试使用ExtractRasterFromFile任务...'
    datasetNames = ['Multispectral', 'Surface Reflectance', 'Top of Atmosphere Reflectance']
    
    FOR dsIdx=0, N_ELEMENTS(datasetNames)-1 DO BEGIN
      IF ~OBJ_VALID(raster) THEN BEGIN
        datasetName = datasetNames[dsIdx]
        PRINT, '  尝试数据集名称: ' + datasetName
        CATCH, err2
        IF err2 EQ 0 THEN BEGIN
          extractTask = ENVITask('ExtractRasterFromFile')
          extractTask.INPUT_URI = mtlFile
          extractTask.DATASET_NAME = datasetName
          extractTask.Execute
          tempRaster = extractTask.OUTPUT_RASTER
          CATCH, /CANCEL
          IF tempRaster NE !NULL THEN BEGIN
            IF N_ELEMENTS(tempRaster) GT 1 THEN BEGIN
              raster = tempRaster[0]
            ENDIF ELSE BEGIN
              raster = tempRaster
            ENDELSE
            IF OBJ_VALID(raster) THEN BEGIN
              PRINT, '  ✓ 成功使用ExtractRasterFromFile提取数据集: ' + datasetName
              BREAK
            ENDIF
          ENDIF
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
      ENDIF
    ENDFOR
  ENDIF
  
  ; 如果所有方法都失败，尝试直接打开TIF文件（适用于L2SP数据）
  IF ~OBJ_VALID(raster) THEN BEGIN
    PRINT, '尝试直接打开TIF文件（适用于L2SP数据）...'
    
    ; 搜索SR_B*.TIF文件（表面反射率波段）
    srBands = ['SR_B1', 'SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'SR_B6', 'SR_B7']
    bandFiles = []
    baseName = FILE_BASENAME(mtlFile, '_MTL.txt')
    dataDir = FILE_DIRNAME(mtlFile)
    
    FOR bandIdx=0, N_ELEMENTS(srBands)-1 DO BEGIN
      bandPattern = baseName + '_' + srBands[bandIdx] + '.TIF'
      bandFile = dataDir + PATH_SEP() + bandPattern
      
      IF FILE_TEST(bandFile) THEN BEGIN
        PRINT, '  找到波段文件: ' + FILE_BASENAME(bandFile)
        bandFiles = [bandFiles, bandFile]
      ENDIF ELSE BEGIN
        ; 尝试小写扩展名
        bandFileLower = dataDir + PATH_SEP() + FILE_BASENAME(bandFile, '.TIF') + '.tif'
        IF FILE_TEST(bandFileLower) THEN BEGIN
          PRINT, '  找到波段文件: ' + FILE_BASENAME(bandFileLower)
          bandFiles = [bandFiles, bandFileLower]
        ENDIF
      ENDELSE
    ENDFOR
    
    IF N_ELEMENTS(bandFiles) GE 3 THEN BEGIN
      PRINT, '找到 ' + STRING(N_ELEMENTS(bandFiles)) + ' 个波段文件，正在打开...'
      bandRasters = []
      
      FOR fileIdx=0, N_ELEMENTS(bandFiles)-1 DO BEGIN
        bandNum = fileIdx + 1
        PRINT, '    打开文件 ' + STRING(fileIdx+1) + '/' + STRING(N_ELEMENTS(bandFiles)) + ': ' + FILE_BASENAME(bandFiles[fileIdx])
        CATCH, errOpen
        IF errOpen EQ 0 THEN BEGIN
          bandRaster = e.OpenRaster(bandFiles[fileIdx])
          CATCH, /CANCEL
          IF OBJ_VALID(bandRaster) THEN BEGIN
            bandRasters = [bandRasters, bandRaster]
            ; 检查是否有空间参考信息
            CATCH, errCheckSR
            IF errCheckSR EQ 0 THEN BEGIN
              tempSR = bandRaster.SPATIALREF
              CATCH, /CANCEL
              IF OBJ_VALID(tempSR) THEN BEGIN
                PRINT, '      ✓ 成功打开B' + STRING(bandNum) + '，尺寸: ' + STRING(bandRaster.NCOLUMNS) + ' x ' + STRING(bandRaster.NROWS) + '，有空间参考'
              ENDIF ELSE BEGIN
                PRINT, '      ✓ 成功打开B' + STRING(bandNum) + '，尺寸: ' + STRING(bandRaster.NCOLUMNS) + ' x ' + STRING(bandRaster.NROWS) + '，无空间参考'
              ENDELSE
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
              PRINT, '      ✓ 成功打开B' + STRING(bandNum) + '，尺寸: ' + STRING(bandRaster.NCOLUMNS) + ' x ' + STRING(bandRaster.NROWS)
            ENDELSE
          ENDIF ELSE BEGIN
            PRINT, '      错误: 无法打开文件: ' + bandFiles[fileIdx]
          ENDELSE
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '      错误: 打开文件失败: ' + bandFiles[fileIdx] + ' - ' + !ERROR_STATE.MSG
        ENDELSE
      ENDFOR
      
      IF N_ELEMENTS(bandRasters) GE 3 THEN BEGIN
        ; 检查是否有TIF文件缺少空间参考信息
        PRINT, '  检查TIF文件的空间参考信息...'
        needAddSpatialRef = 0
        FOR i=0, N_ELEMENTS(bandRasters)-1 DO BEGIN
          IF OBJ_VALID(bandRasters[i]) THEN BEGIN
            CATCH, errCheckSR2
            IF errCheckSR2 EQ 0 THEN BEGIN
              tempSR = bandRasters[i].SPATIALREF
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
        
        ; 如果有TIF文件缺少空间参考，先从MTL XML文件读取并添加空间参考
        IF needAddSpatialRef THEN BEGIN
          PRINT, '  检测到部分TIF文件缺少空间参考信息，正在从MTL XML文件读取并添加...'
          ; 查找MTL XML文件
          mtlXmlFile = FILE_DIRNAME(mtlFile) + PATH_SEP() + FILE_BASENAME(mtlFile, '.txt') + '.xml'
          IF FILE_TEST(mtlXmlFile) THEN BEGIN
            PRINT, '  找到MTL XML文件: ' + FILE_BASENAME(mtlXmlFile)
            ; 从MTL XML创建空间参考信息（使用第一个raster的尺寸）
            ; 检查bandRasters数组是否为空
            mapInfo = !NULL
            IF (N_ELEMENTS(bandRasters) GT 0) AND OBJ_VALID(bandRasters[0]) THEN BEGIN
              mapInfo = create_spatial_ref_from_mtl_xml(mtlXmlFile, bandRasters[0].NCOLUMNS, bandRasters[0].NROWS)
            ENDIF ELSE BEGIN
              PRINT, '  错误: bandRasters数组为空或第一个元素无效'
            ENDELSE
            
            IF mapInfo NE !NULL THEN BEGIN
              PRINT, '  ✓ 成功从MTL XML创建空间参考信息'
              ; 为每个没有空间参考的TIF文件添加空间参考
              FOR i=0, N_ELEMENTS(bandRasters)-1 DO BEGIN
                IF OBJ_VALID(bandRasters[i]) THEN BEGIN
                  CATCH, errCheckSR3
                  IF errCheckSR3 EQ 0 THEN BEGIN
                    tempSR = bandRasters[i].SPATIALREF
                    CATCH, /CANCEL
                    IF ~OBJ_VALID(tempSR) THEN BEGIN
                      PRINT, '    正在为B' + STRING(i+1) + '添加空间参考...'
                      ; 使用set_spatial_ref_to_raster函数添加空间参考
                      CATCH, errSetSR
                      IF errSetSR EQ 0 THEN BEGIN
                        rasterWithSR = set_spatial_ref_to_raster(bandRasters[i], mapInfo)
                        CATCH, /CANCEL
                        
                        IF OBJ_VALID(rasterWithSR) THEN BEGIN
                          ; 关闭原始raster，使用新的raster
                          bandRasters[i].Close
                          bandRasters[i] = rasterWithSR
                          ; 验证空间参考
                          CATCH, errCheckSR4
                          IF errCheckSR4 EQ 0 THEN BEGIN
                            tempSR2 = bandRasters[i].SPATIALREF
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
            PRINT, '  警告: 未找到MTL XML文件: ' + mtlXmlFile
            PRINT, '  将尝试直接堆叠（如果所有TIF尺寸相同）'
          ENDELSE
        ENDIF
        
        ; 现在尝试使用BuildLayerStack堆叠
        PRINT, '  正在使用BuildLayerStack任务组合波段...'
        CATCH, errStack
        IF errStack EQ 0 THEN BEGIN
          buildStackTask = ENVITask('BuildLayerStack')
          buildStackTask.INPUT_RASTERS = bandRasters
          buildStackTask.Execute
          raster = buildStackTask.OUTPUT_RASTER
          CATCH, /CANCEL
          
          IF OBJ_VALID(raster) THEN BEGIN
            PRINT, '  ✓ 成功组合波段，总波段数: ' + STRING(raster.NBANDS)
            PRINT, '  组合后尺寸: ' + STRING(raster.NCOLUMNS) + ' x ' + STRING(raster.NROWS)
            ; 关闭单个TIF raster以释放内存
            FOR i=0, N_ELEMENTS(bandRasters)-1 DO BEGIN
              IF OBJ_VALID(bandRasters[i]) THEN bandRasters[i].Close
            ENDFOR
          ENDIF ELSE BEGIN
            PRINT, '  错误: BuildLayerStack返回的raster无效'
            PRINT, '  错误信息: ' + !ERROR_STATE.MSG
            ; 关闭已打开的文件
            FOR i=0, N_ELEMENTS(bandRasters)-1 DO BEGIN
              IF OBJ_VALID(bandRasters[i]) THEN bandRasters[i].Close
            ENDFOR
          ENDELSE
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '  错误: BuildLayerStack执行失败: ' + !ERROR_STATE.MSG
          PRINT, '  错误代码: ' + STRING(!ERROR_STATE.CODE)
          ; 关闭已打开的文件
          FOR i=0, N_ELEMENTS(bandRasters)-1 DO BEGIN
            IF OBJ_VALID(bandRasters[i]) THEN bandRasters[i].Close
          ENDFOR
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  错误: 部分TIF文件打开失败，无法堆叠'
        PRINT, '  需要至少3个文件，成功打开: ' + STRING(N_ELEMENTS(bandRasters)) + ' 个文件'
        ; 关闭已打开的文件
        FOR i=0, N_ELEMENTS(bandRasters)-1 DO BEGIN
          IF OBJ_VALID(bandRasters[i]) THEN bandRasters[i].Close
        ENDFOR
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '  未找到足够的波段文件（需要至少3个）'
      PRINT, '  找到: ' + STRING(N_ELEMENTS(bandFiles)) + ' 个文件'
    ENDELSE
  ENDIF
  
  IF ~OBJ_VALID(raster) THEN BEGIN
    PRINT, '错误: 无法打开' + year + '年数据'
    PRINT, '请检查：'
    PRINT, '  1. MTL文件路径是否正确: ' + mtlFile
    PRINT, '  2. 文件是否存在且可读'
    PRINT, '  3. ENVI版本是否支持Landsat 9格式'
    PRINT, '  4. 数据集名称是否正确（可能需要手动检查MTL文件）'
    PRINT, '  5. TIF波段文件是否存在（SR_B1到SR_B7）'
    RETURN, !NULL
  ENDIF
  
  ; 根据参数决定是否使用光谱指数
  IF useSpectralIndices EQ 1 THEN BEGIN
    PRINT, '使用模式: 原始波段 + 光谱指数（NDVI、NDWI、NDBI）'
    ; 读取光谱指数结果（从results文件夹）
    PRINT, '正在读取光谱指数结果...'
    ndviFile = outputDir + PATH_SEP() + 'ndvi_' + year + '.dat'
    ndwiFile = outputDir + PATH_SEP() + 'ndwi_' + year + '.dat'
    ndbiFile = outputDir + PATH_SEP() + 'ndbi_' + year + '.dat'
  ENDIF ELSE BEGIN
    PRINT, '使用模式: 仅使用原始波段（不计算光谱指数）'
    ; 跳过光谱指数计算，直接使用原始波段
    ndvi = !NULL
    ndwi = !NULL
    ndbi = !NULL
  ENDELSE
  
  IF useSpectralIndices EQ 1 THEN BEGIN
    ; 确定波段索引（Landsat 9 Surface Reflectance: B1=Blue, B2=Green, B3=Red, B4=NIR, B5=SWIR1, B6=SWIR2, B7=其他）
    nBands = raster.NBANDS
    redIndex = -1
    nirIndex = -1
    greenIndex = -1
    swir1Index = -1
    
    IF nBands GE 4 THEN BEGIN
      redIndex = 2  ; B3 = 索引2
      nirIndex = 3  ; B4 = 索引3
      greenIndex = 1  ; B2 = 索引1
      IF nBands GE 5 THEN BEGIN
        swir1Index = 4  ; B5 = 索引4
      ENDIF
    ENDIF
  
    ; 计算NDVI（如果文件不存在）
    ndvi = !NULL
    IF ~FILE_TEST(ndviFile) THEN BEGIN
      PRINT, '警告: NDVI文件不存在，正在计算...'
      IF (redIndex GE 0) AND (nirIndex GE 0) THEN BEGIN
        redBand = redIndex + 1  ; 转换为波段编号（从1开始）
        nirBand = nirIndex + 1
        redBandStr = STRTRIM(STRING(redBand), 2)
        nirBandStr = STRTRIM(STRING(nirBand), 2)
        ndviExpr = '(b' + nirBandStr + ' - b' + redBandStr + ') / (b' + nirBandStr + ' + b' + redBandStr + ')'
        CATCH, errNDVI
        IF errNDVI EQ 0 THEN BEGIN
          ndviTask = ENVITask('PixelwiseBandMathRaster')
          ndviTask.INPUT_RASTER = raster
          ndviTask.EXPRESSION = ndviExpr
          ndviTask.Execute
          ndvi = ndviTask.OUTPUT_RASTER
          CATCH, /CANCEL
          IF OBJ_VALID(ndvi) THEN BEGIN
            ; 保存NDVI结果
            ndvi.Export, ndviFile, 'ENVI'
            WAIT, 0.5
            PRINT, '  ✓ NDVI计算完成并已保存'
          ENDIF
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '  错误: NDVI计算失败: ' + !ERROR_STATE.MSG
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  错误: 无法确定Red和NIR波段索引'
      ENDELSE
  ENDIF
  
    ; 如果文件存在，尝试打开
    IF ndvi EQ !NULL THEN BEGIN
      IF FILE_TEST(ndviFile) THEN BEGIN
        ndvi = e.OpenRaster(ndviFile)
        IF ~OBJ_VALID(ndvi) THEN BEGIN
          PRINT, '警告: 无法打开NDVI文件，重新计算...'
          IF (redIndex GE 0) AND (nirIndex GE 0) THEN BEGIN
            redBand = redIndex + 1
            nirBand = nirIndex + 1
            redBandStr = STRTRIM(STRING(redBand), 2)
            nirBandStr = STRTRIM(STRING(nirBand), 2)
            ndviExpr = '(b' + nirBandStr + ' - b' + redBandStr + ') / (b' + nirBandStr + ' + b' + redBandStr + ')'
            CATCH, errNDVI2
            IF errNDVI2 EQ 0 THEN BEGIN
              ndviTask = ENVITask('PixelwiseBandMathRaster')
              ndviTask.INPUT_RASTER = raster
              ndviTask.EXPRESSION = ndviExpr
              ndviTask.Execute
              ndvi = ndviTask.OUTPUT_RASTER
              CATCH, /CANCEL
              IF OBJ_VALID(ndvi) THEN BEGIN
                ndvi.Export, ndviFile, 'ENVI'
                WAIT, 0.5
                PRINT, '  ✓ NDVI重新计算完成并已保存'
              ENDIF
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
            ENDELSE
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  
    ; 计算NDWI（如果文件不存在）
    ndwi = !NULL
    IF ~FILE_TEST(ndwiFile) THEN BEGIN
      PRINT, '警告: NDWI文件不存在，正在计算...'
      IF (greenIndex GE 0) AND (swir1Index GE 0) THEN BEGIN
        greenBand = greenIndex + 1
        swir1Band = swir1Index + 1
        greenBandStr = STRTRIM(STRING(greenBand), 2)
        swir1BandStr = STRTRIM(STRING(swir1Band), 2)
        ndwiExpr = '(b' + greenBandStr + ' - b' + swir1BandStr + ') / (b' + greenBandStr + ' + b' + swir1BandStr + ')'
        CATCH, errNDWI
        IF errNDWI EQ 0 THEN BEGIN
          ndwiTask = ENVITask('PixelwiseBandMathRaster')
          ndwiTask.INPUT_RASTER = raster
          ndwiTask.EXPRESSION = ndwiExpr
          ndwiTask.Execute
          ndwi = ndwiTask.OUTPUT_RASTER
          CATCH, /CANCEL
          IF OBJ_VALID(ndwi) THEN BEGIN
            ndwi.Export, ndwiFile, 'ENVI'
            WAIT, 0.5
            PRINT, '  ✓ NDWI计算完成并已保存'
          ENDIF
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '  错误: NDWI计算失败: ' + !ERROR_STATE.MSG
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  错误: 无法确定Green和SWIR1波段索引'
      ENDELSE
  ENDIF
  
    ; 如果文件存在，尝试打开
    IF ndwi EQ !NULL THEN BEGIN
      IF FILE_TEST(ndwiFile) THEN BEGIN
        ndwi = e.OpenRaster(ndwiFile)
        IF ~OBJ_VALID(ndwi) THEN BEGIN
          PRINT, '警告: 无法打开NDWI文件，重新计算...'
          IF (greenIndex GE 0) AND (swir1Index GE 0) THEN BEGIN
            greenBand = greenIndex + 1
            swir1Band = swir1Index + 1
            greenBandStr = STRTRIM(STRING(greenBand), 2)
            swir1BandStr = STRTRIM(STRING(swir1Band), 2)
            ndwiExpr = '(b' + greenBandStr + ' - b' + swir1BandStr + ') / (b' + greenBandStr + ' + b' + swir1BandStr + ')'
            CATCH, errNDWI2
            IF errNDWI2 EQ 0 THEN BEGIN
              ndwiTask = ENVITask('PixelwiseBandMathRaster')
              ndwiTask.INPUT_RASTER = raster
              ndwiTask.EXPRESSION = ndwiExpr
              ndwiTask.Execute
              ndwi = ndwiTask.OUTPUT_RASTER
              CATCH, /CANCEL
              IF OBJ_VALID(ndwi) THEN BEGIN
                ndwi.Export, ndwiFile, 'ENVI'
                WAIT, 0.5
                PRINT, '  ✓ NDWI重新计算完成并已保存'
              ENDIF
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
            ENDELSE
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  
    ; 计算NDBI（如果文件不存在）
    ndbi = !NULL
    IF ~FILE_TEST(ndbiFile) THEN BEGIN
      PRINT, '警告: NDBI文件不存在，正在计算...'
      IF (nirIndex GE 0) AND (swir1Index GE 0) THEN BEGIN
        nirBand = nirIndex + 1
        swir1Band = swir1Index + 1
        nirBandStr = STRTRIM(STRING(nirBand), 2)
        swir1BandStr = STRTRIM(STRING(swir1Band), 2)
        ndbiExpr = '(b' + swir1BandStr + ' - b' + nirBandStr + ') / (b' + swir1BandStr + ' + b' + nirBandStr + ')'
        CATCH, errNDBI
        IF errNDBI EQ 0 THEN BEGIN
          ndbiTask = ENVITask('PixelwiseBandMathRaster')
          ndbiTask.INPUT_RASTER = raster
          ndbiTask.EXPRESSION = ndbiExpr
          ndbiTask.Execute
          ndbi = ndbiTask.OUTPUT_RASTER
          CATCH, /CANCEL
          IF OBJ_VALID(ndbi) THEN BEGIN
            ndbi.Export, ndbiFile, 'ENVI'
            WAIT, 0.5
            PRINT, '  ✓ NDBI计算完成并已保存'
          ENDIF
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '  错误: NDBI计算失败: ' + !ERROR_STATE.MSG
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  错误: 无法确定NIR和SWIR1波段索引'
      ENDELSE
  ENDIF
  
    ; 如果文件存在，尝试打开
    IF ndbi EQ !NULL THEN BEGIN
      IF FILE_TEST(ndbiFile) THEN BEGIN
        ndbi = e.OpenRaster(ndbiFile)
        IF ~OBJ_VALID(ndbi) THEN BEGIN
          PRINT, '警告: 无法打开NDBI文件，重新计算...'
          IF (nirIndex GE 0) AND (swir1Index GE 0) THEN BEGIN
            nirBand = nirIndex + 1
            swir1Band = swir1Index + 1
            nirBandStr = STRTRIM(STRING(nirBand), 2)
            swir1BandStr = STRTRIM(STRING(swir1Band), 2)
            ndbiExpr = '(b' + swir1BandStr + ' - b' + nirBandStr + ') / (b' + swir1BandStr + ' + b' + nirBandStr + ')'
            CATCH, errNDBI2
            IF errNDBI2 EQ 0 THEN BEGIN
              ndbiTask = ENVITask('PixelwiseBandMathRaster')
              ndbiTask.INPUT_RASTER = raster
              ndbiTask.EXPRESSION = ndbiExpr
              ndbiTask.Execute
              ndbi = ndbiTask.OUTPUT_RASTER
              CATCH, /CANCEL
              IF OBJ_VALID(ndbi) THEN BEGIN
                ndbi.Export, ndbiFile, 'ENVI'
                WAIT, 0.5
                PRINT, '  ✓ NDBI重新计算完成并已保存'
              ENDIF
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
            ENDELSE
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  
    IF (~OBJ_VALID(ndvi)) OR (~OBJ_VALID(ndwi)) OR (~OBJ_VALID(ndbi)) THEN BEGIN
      PRINT, '错误: 无法加载或计算光谱指数'
      ; 清理已创建的资源
      IF OBJ_VALID(ndvi) THEN ndvi.Close
      IF OBJ_VALID(ndwi) THEN ndwi.Close
      IF OBJ_VALID(ndbi) THEN ndbi.Close
      IF OBJ_VALID(raster) THEN raster.Close
      RETURN, !NULL
    ENDIF
    
    PRINT, '✓ 光谱指数加载完成'
    
    ; 合并波段（原始波段 + NDVI + NDWI + NDBI）
    PRINT, '正在合并波段（原始波段 + 光谱指数）...'
    buildStackTask = ENVITask('BuildLayerStack')
    buildStackTask.INPUT_RASTERS = [raster, ndvi, ndwi, ndbi]
    buildStackTask.Execute
    stackedRaster = buildStackTask.OUTPUT_RASTER
    
    IF ~OBJ_VALID(stackedRaster) THEN BEGIN
      PRINT, '错误: 波段合并失败'
      ; 清理资源
      IF OBJ_VALID(ndvi) THEN ndvi.Close
      IF OBJ_VALID(ndwi) THEN ndwi.Close
      IF OBJ_VALID(ndbi) THEN ndbi.Close
      RETURN, !NULL
    ENDIF
    
    PRINT, '✓ 波段合并完成，总波段数: ' + STRING(stackedRaster.NBANDS) + '（原始波段 + 3个光谱指数）'
    
    ; 关闭光谱指数raster（已合并到stackedRaster中）
    IF OBJ_VALID(ndvi) THEN BEGIN
      ndvi.Close
      ndvi = !NULL
    ENDIF
    IF OBJ_VALID(ndwi) THEN BEGIN
      ndwi.Close
      ndwi = !NULL
    ENDIF
    IF OBJ_VALID(ndbi) THEN BEGIN
      ndbi.Close
      ndbi = !NULL
    ENDIF
  ENDIF ELSE BEGIN
    ; 不使用光谱指数，直接使用原始波段
    PRINT, '✓ 使用原始波段进行分类，波段数: ' + STRING(raster.NBANDS)
    stackedRaster = raster
  ENDELSE
  
  ; 加载ROI
  IF ~FILE_TEST(roiFile) THEN BEGIN
    PRINT, '错误: ROI文件不存在: ' + roiFile
    ; 清理资源（此时stackedRaster已创建）
    IF OBJ_VALID(stackedRaster) THEN BEGIN
      stackedRaster.Close
      ; 如果stackedRaster和raster是同一个对象，避免重复关闭
      IF (stackedRaster EQ raster) THEN raster = !NULL
    ENDIF
    IF OBJ_VALID(raster) THEN raster.Close
    RETURN, !NULL
  ENDIF
  
  rois = e.OpenROI(roiFile)
  IF (rois EQ !NULL) OR (N_ELEMENTS(rois) EQ 0) THEN BEGIN
    PRINT, '错误: 无法加载ROI或ROI文件为空: ' + roiFile
    ; 清理资源（此时stackedRaster已创建）
    IF OBJ_VALID(stackedRaster) THEN BEGIN
      stackedRaster.Close
      ; 如果stackedRaster和raster是同一个对象，避免重复关闭
      IF (stackedRaster EQ raster) THEN raster = !NULL
    ENDIF
    IF OBJ_VALID(raster) THEN raster.Close
    RETURN, !NULL
  ENDIF
  
  PRINT, '✓ 成功加载ROI: ' + FILE_BASENAME(roiFile)
  PRINT, '  ROI数量: ' + STRING(N_ELEMENTS(rois))
  
  ; 提取类别名称
  nClasses = N_ELEMENTS(rois)
  IF nClasses LE 0 THEN BEGIN
    PRINT, '错误: ROI数量为0'
    ; 清理资源（此时stackedRaster已创建）
    IF OBJ_VALID(stackedRaster) THEN BEGIN
      stackedRaster.Close
      ; 如果stackedRaster和raster是同一个对象，避免重复关闭
      IF (stackedRaster EQ raster) THEN raster = !NULL
    ENDIF
    IF OBJ_VALID(raster) THEN raster.Close
    RETURN, !NULL
  ENDIF
  
  classNames = STRARR(nClasses)
  FOR i=0, nClasses-1 DO BEGIN
    IF (i LT N_ELEMENTS(rois)) AND OBJ_VALID(rois[i]) THEN BEGIN
      classNames[i] = rois[i].NAME
      PRINT, '  ROI ' + STRING(i+1) + ': ' + classNames[i]
    ENDIF ELSE BEGIN
      PRINT, '  警告: ROI ' + STRING(i+1) + ' 无效'
    ENDELSE
  ENDFOR
  
  ; 随机森林分类
  PRINT, '正在进行随机森林分类（这可能需要几分钟）...'
  outputClass = outputDir + PATH_SEP() + 'classification_' + year + '.dat'
  hdrFile = FILE_DIRNAME(outputClass) + PATH_SEP() + FILE_BASENAME(outputClass, '.dat') + '.hdr'
  
  ; 如果输出文件已存在，先删除（包括.dat和.hdr文件）
  IF FILE_TEST(outputClass) THEN BEGIN
    PRINT, '  检测到已存在的分类文件，正在删除: ' + FILE_BASENAME(outputClass)
    FILE_DELETE, outputClass, /QUIET
    WAIT, 0.5
    ; 如果删除后文件仍然存在，尝试多次删除
    IF FILE_TEST(outputClass) THEN BEGIN
      WAIT, 1.0
      FILE_DELETE, outputClass, /QUIET
      WAIT, 0.5
    ENDIF
    ; 验证删除是否成功
    IF FILE_TEST(outputClass) THEN BEGIN
      PRINT, '  警告: 无法删除已存在的文件: ' + outputClass
      PRINT, '  请手动删除该文件后重试'
    ENDIF ELSE BEGIN
      PRINT, '  ✓ 已删除旧文件: ' + FILE_BASENAME(outputClass)
    ENDELSE
  ENDIF
  
  IF FILE_TEST(hdrFile) THEN BEGIN
    FILE_DELETE, hdrFile, /QUIET
    WAIT, 0.5
    IF FILE_TEST(hdrFile) THEN BEGIN
      WAIT, 1.0
      FILE_DELETE, hdrFile, /QUIET
      WAIT, 0.5
    ENDIF
    IF ~FILE_TEST(hdrFile) THEN BEGIN
      PRINT, '  ✓ 已删除旧文件: ' + FILE_BASENAME(hdrFile)
    ENDIF
  ENDIF
  
  numberOfTrees = 100
  PRINT, '  随机森林树数量: ' + STRING(numberOfTrees)
  
  CATCH, errRF
  IF errRF EQ 0 THEN BEGIN
    rfTask = ENVITask('RandomForestClassification')
    rfTask.input_raster = stackedRaster
    rfTask.input_rois = rois
    rfTask.numberOfTrees = numberOfTrees
    rfTask.output_raster_uri = outputClass
    rfTask.showMsg = 0
    rfTask.display = 0
    
    PRINT, '  正在执行分类任务（可能需要10-30分钟，请耐心等待）...'
    rfTask.Execute
    PRINT, '  ✓ 分类任务执行完成'
    
    WAIT, 3.0
    classifiedRaster = rfTask.output_raster
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '错误: 随机森林分类执行失败: ' + !ERROR_STATE.MSG
    ; 清理资源
    IF OBJ_VALID(stackedRaster) THEN BEGIN
      stackedRaster.Close
      ; 如果stackedRaster和raster是同一个对象，避免重复关闭
      IF (stackedRaster EQ raster) THEN raster = !NULL
    ENDIF
    IF OBJ_VALID(raster) THEN raster.Close
    RETURN, !NULL
  ENDELSE
  
  IF ~OBJ_VALID(classifiedRaster) THEN BEGIN
    PRINT, '错误: 分类结果对象无效'
    ; 清理资源（此时stackedRaster已创建）
    IF OBJ_VALID(stackedRaster) THEN BEGIN
      stackedRaster.Close
      ; 如果stackedRaster和raster是同一个对象，避免重复关闭
      IF (stackedRaster EQ raster) THEN raster = !NULL
    ENDIF
    IF OBJ_VALID(raster) THEN raster.Close
    RETURN, !NULL
  ENDIF
  
  PRINT, '✓ ' + year + '年随机森林分类完成'
  
  ; 后处理（平滑、聚合、元数据更新）
  PRINT, '正在进行' + year + '年分类后处理...'
  spatialRef = stackedRaster.SPATIALREF
  outputFinal = outputDir + PATH_SEP() + 'classification_' + year + '_final.dat'
  IF FILE_TEST(outputFinal) THEN BEGIN
    FILE_DELETE, outputFinal, /QUIET
    hdrFile = FILE_DIRNAME(outputFinal) + PATH_SEP() + FILE_BASENAME(outputFinal, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  ENDIF
  
  finalRaster = process_classification_postprocessing(classifiedRaster, outputFinal, classNames, nClasses, spatialRef, year)
  
  ; 关闭原始分类结果和堆叠raster
  IF OBJ_VALID(classifiedRaster) THEN BEGIN
    classifiedRaster.Close
  ENDIF
  ; 注意：如果stackedRaster和raster是同一个对象（不使用光谱指数时），只关闭一次
  IF OBJ_VALID(stackedRaster) THEN BEGIN
    stackedRaster.Close
    ; 如果stackedRaster和raster是同一个对象，将raster设为!NULL避免重复关闭
    IF (stackedRaster EQ raster) THEN raster = !NULL
  ENDIF
  IF OBJ_VALID(raster) THEN BEGIN
    raster.Close
  ENDIF
  
  ; 检查后处理结果
  IF OBJ_VALID(finalRaster) THEN BEGIN
    PRINT, '✓ ' + year + '年分类后处理完成'
  ENDIF ELSE BEGIN
    PRINT, '警告: ' + year + '年分类后处理失败'
  ENDELSE
  
  ; 创建结果结构
  result = {finalRaster:finalRaster, classNames:classNames, nClasses:nClasses}
  
  RETURN, result
END

PRO landsat9_classification
  COMPILE_OPT IDL2
  
  ; 启动ENVI
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()
  
  PRINT, '========================================='
  PRINT, 'Landsat 9 随机森林监督分类'
  PRINT, '功能: 随机森林分类 + 平滑 + 聚合后处理'
  PRINT, '========================================='
  PRINT, ''
  
  ; 设置数据路径
  dataPath2021 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1'
  dataPath2025 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20250827_20250828_02_T1'
  
  ; ROI文件路径（用于监督分类）
  roiFile2021 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1\1110.xml'
  roiFile2025 = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1\1111.xml'
  
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
  result2021 = process_year_classification(dataPath2021, '2021', roiFile2021, outputDir)
  IF result2021 EQ !NULL THEN BEGIN
    PRINT, '错误: 2021年分类处理失败'
    RETURN
  ENDIF
  
  PRINT, ''
  
  ; 处理2025年数据
  result2025 = process_year_classification(dataPath2025, '2025', roiFile2025, outputDir)
  IF result2025 EQ !NULL THEN BEGIN
    PRINT, '警告: 2025年分类处理失败'
  ENDIF
  
  PRINT, ''
  PRINT, '========================================='
  PRINT, '✓✓✓ 分类处理完成！ ✓✓✓'
  PRINT, '========================================='
  PRINT, '输出目录: ' + outputDir
  PRINT, ''
  
  ; ============================================
  ; 对比分析（如果两个年份都成功）
  ; ============================================
  IF (result2021 NE !NULL) AND (result2025 NE !NULL) THEN BEGIN
    PRINT, ''
    PRINT, '========================================='
    PRINT, '========== 开始对比分析 =========='
    PRINT, '========================================='
    PRINT, ''
    
    ; 读取分类结果文件（使用已配准的文件）
    classification2021File = outputDir + PATH_SEP() + 'classification_2021.dat'
    classification2025File = outputDir + PATH_SEP() + 'classification_2025_warp.dat'
    
    IF ~FILE_TEST(classification2021File) THEN BEGIN
      PRINT, '错误: 2021年分类结果文件不存在: ' + classification2021File
      PRINT, '跳过对比分析'
    ENDIF ELSE IF ~FILE_TEST(classification2025File) THEN BEGIN
      PRINT, '错误: 2025年分类结果文件不存在: ' + classification2025File
      PRINT, '跳过对比分析'
    ENDIF ELSE BEGIN
      PRINT, '正在打开分类结果文件...'
      class2021 = e.OpenRaster(classification2021File)
      class2025 = e.OpenRaster(classification2025File)
      
      IF ~OBJ_VALID(class2021) OR ~OBJ_VALID(class2025) THEN BEGIN
        PRINT, '错误: 无法打开分类结果文件'
        PRINT, '跳过对比分析'
        ; 清理已打开的对象
        IF OBJ_VALID(class2021) THEN class2021.Close
        IF OBJ_VALID(class2025) THEN class2025.Close
      ENDIF ELSE BEGIN
        ; ============================================
        ; 检查并添加空间参考信息
        ; ============================================
        PRINT, ''
        PRINT, '========== 检查并添加空间参考信息 =========='
        PRINT, '正在检查2021年和2025年分类结果的空间参考信息...'
        
        ; 为2021年分类结果添加空间参考（如果需要）
        spatialRef2021 = !NULL
        CATCH, errSR2021
        IF errSR2021 EQ 0 THEN BEGIN
          spatialRef2021 = class2021.SPATIALREF
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
        IF ~OBJ_VALID(spatialRef2021) THEN BEGIN
          PRINT, '  2021年分类结果缺少空间参考信息，正在添加...'
          class2021_temp = add_spatial_ref_to_raster_file(class2021, dataPath2021, classification2021File)
          IF OBJ_VALID(class2021_temp) THEN BEGIN
            class2021.Close
            class2021 = class2021_temp
            PRINT, '  ✓ 2021年分类结果空间参考信息已添加'
          ENDIF
        ENDIF
        
        ; 为2025年分类结果添加空间参考（如果需要）
        spatialRef2025 = !NULL
        CATCH, errSR2025
        IF errSR2025 EQ 0 THEN BEGIN
          spatialRef2025 = class2025.SPATIALREF
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
        IF ~OBJ_VALID(spatialRef2025) THEN BEGIN
          PRINT, '  2025年分类结果缺少空间参考信息，正在添加...'
          ; 注意：2025年影像已配准到2021年基础影像，因此使用dataPath2021获取空间参考
          class2025_temp = add_spatial_ref_to_raster_file(class2025, dataPath2021, classification2025File)
          IF OBJ_VALID(class2025_temp) THEN BEGIN
            class2025.Close
            class2025 = class2025_temp
            PRINT, '  ✓ 2025年分类结果空间参考信息已添加'
          ENDIF
        ENDIF
        
        ; 重新检查空间参考信息
        PRINT, '重新检查空间参考信息...'
        spatialRef2021 = !NULL
        spatialRef2025 = !NULL
        CATCH, errSR2021
        IF errSR2021 EQ 0 THEN BEGIN
          spatialRef2021 = class2021.SPATIALREF
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
        CATCH, errSR2025
        IF errSR2025 EQ 0 THEN BEGIN
          spatialRef2025 = class2025.SPATIALREF
          CATCH, /CANCEL
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
        
        IF OBJ_VALID(spatialRef2021) AND OBJ_VALID(spatialRef2025) THEN BEGIN
          PRINT, '✓ 所有分类结果都有空间参考信息，将按地理坐标对齐'
        ENDIF ELSE BEGIN
          PRINT, '警告: 部分分类结果仍然缺少空间参考信息，对齐可能不精确'
        ENDELSE
        PRINT, ''
        
        ; ============================================
        ; 使用ImageIntersection进行对齐
        ; ============================================
        PRINT, '========== 分类结果对齐 =========='
        PRINT, '正在按地理坐标对齐分类结果（ImageIntersection会根据空间参考信息对齐）...'
        
        ; 检查尺寸是否一致（用于提示）
        IF (class2021.NCOLUMNS NE class2025.NCOLUMNS) OR (class2021.NROWS NE class2025.NROWS) THEN BEGIN
          PRINT, '  检测到: 两个时相的分类结果尺寸不一致'
          PRINT, '    2021年尺寸: ' + STRING(class2021.NCOLUMNS) + ' x ' + STRING(class2021.NROWS)
          PRINT, '    2025年尺寸: ' + STRING(class2025.NCOLUMNS) + ' x ' + STRING(class2025.NROWS)
        ENDIF ELSE BEGIN
          PRINT, '  检测到: 两个时相的分类结果尺寸一致'
          PRINT, '    尺寸: ' + STRING(class2021.NCOLUMNS) + ' x ' + STRING(class2021.NROWS)
          PRINT, '    将使用ImageIntersection确保按地理坐标精确对齐（消除可能的偏移）'
        ENDELSE
        
        IF OBJ_VALID(spatialRef2021) AND OBJ_VALID(spatialRef2025) THEN BEGIN
          PRINT, '  ✓ 两个分类结果都有空间参考信息，将按地理坐标对齐'
        ENDIF ELSE BEGIN
          PRINT, '  警告: 部分分类结果缺少空间参考信息，对齐可能不精确'
        ENDELSE
        
        ; 使用ImageIntersection进行对齐
        class2021_aligned = !NULL
        class2025_aligned = !NULL
        CATCH, errIntersect
        IF errIntersect EQ 0 THEN BEGIN
          intersectTask = ENVITask('ImageIntersection')
          intersectTask.INPUT_RASTER1 = class2021
          intersectTask.INPUT_RASTER2 = class2025
          intersectTask.Execute
          class2021_aligned = intersectTask.OUTPUT_RASTER1
          class2025_aligned = intersectTask.OUTPUT_RASTER2
          CATCH, /CANCEL
          
          IF OBJ_VALID(class2021_aligned) AND OBJ_VALID(class2025_aligned) THEN BEGIN
            PRINT, '  ✓ 分类结果对齐完成（按地理坐标）'
            PRINT, '  对齐后尺寸: ' + STRING(class2021_aligned.NCOLUMNS) + ' x ' + STRING(class2021_aligned.NROWS)
            
            ; 保存对齐后的分类结果
            output2021Aligned = outputDir + PATH_SEP() + 'classification_2021_aligned.dat'
            output2025Aligned = outputDir + PATH_SEP() + 'classification_2025_aligned.dat'
            
            IF FILE_TEST(output2021Aligned) THEN FILE_DELETE, output2021Aligned, /QUIET
            IF FILE_TEST(output2025Aligned) THEN FILE_DELETE, output2025Aligned, /QUIET
            
            class2021_aligned.Export, output2021Aligned, 'ENVI'
            class2025_aligned.Export, output2025Aligned, 'ENVI'
            WAIT, 1.0
            PRINT, '  ✓ 对齐后的分类结果已保存'
          ENDIF ELSE BEGIN
            PRINT, '  错误: ImageIntersection返回的对象无效'
            class2021_aligned = class2021
            class2025_aligned = class2025
          ENDELSE
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '  错误: 分类结果对齐失败: ' + !ERROR_STATE.MSG
          PRINT, '  将使用原始分类结果（可能有偏移）'
          class2021_aligned = class2021
          class2025_aligned = class2025
        ENDELSE
        
        ; ============================================
        ; 计算变化检测
        ; ============================================
        IF OBJ_VALID(class2021_aligned) AND OBJ_VALID(class2025_aligned) THEN BEGIN
          PRINT, ''
          PRINT, '========== 计算变化检测 =========='
          PRINT, '正在计算分类结果变化（2025 - 2021）...'
          
          ; 计算变化矩阵（使用PixelwiseBandMath或直接比较）
          ; 方法：创建一个变化检测影像，其中每个像素的值表示从2021年到2025年的类别变化
          ; 变化编码：2021年类别 * 10 + 2025年类别（例如：11=植被到植被，12=植被到水体，21=水体到植被等）
          
          CATCH, errChange
          ; 初始化变量，避免在错误路径中访问未定义变量
          stackedChange = !NULL
          changeRaster = !NULL
          IF errChange EQ 0 THEN BEGIN
            ; 使用PixelwiseBandMath计算变化编码
            ; 公式：b1 * 10 + b2，其中b1是2021年类别，b2是2025年类别
            changeExpr = '(b1 * 10) + b2'
            
            ; 先堆叠两个分类结果
            stackTask = ENVITask('BuildLayerStack')
            stackTask.INPUT_RASTERS = [class2021_aligned, class2025_aligned]
            stackTask.Execute
            stackedChange = stackTask.OUTPUT_RASTER
            
            IF OBJ_VALID(stackedChange) THEN BEGIN
              ; 使用PixelwiseBandMath计算变化编码
              changeTask = ENVITask('PixelwiseBandMathRaster')
              changeTask.INPUT_RASTER = stackedChange
              changeTask.EXPRESSION = changeExpr
              changeTask.Execute
              changeRaster = changeTask.OUTPUT_RASTER
              
              IF OBJ_VALID(changeRaster) THEN BEGIN
                ; 保存变化检测结果
                outputChange = outputDir + PATH_SEP() + 'change_detection_2021_2025.dat'
                IF FILE_TEST(outputChange) THEN BEGIN
                  FILE_DELETE, outputChange, /QUIET
                  hdrFile = FILE_DIRNAME(outputChange) + PATH_SEP() + FILE_BASENAME(outputChange, '.dat') + '.hdr'
                  IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
                ENDIF
                
                changeRaster.Export, outputChange, 'ENVI'
                WAIT, 1.0
                PRINT, '✓ 变化检测结果已保存: ' + FILE_BASENAME(outputChange)
                
                ; 计算变化统计
                PRINT, '正在计算变化统计信息...'
                ; 首先获取变化编码的实际范围
                CATCH, errGetRange
                IF errGetRange EQ 0 THEN BEGIN
                  ; 确保SUB_RECT索引在有效范围内
                  nCols = changeRaster.NCOLUMNS
                  nRows = changeRaster.NROWS
                  rectCols = MIN(1000, MAX(0, nCols-1))
                  rectRows = MIN(1000, MAX(0, nRows-1))
                  IF (rectCols GT 0) AND (rectRows GT 0) THEN BEGIN
                    sampleData = changeRaster.GetData(BANDS=0, SUB_RECT=[0, 0, rectCols, rectRows])
                    minCode = MIN(sampleData)
                    maxCode = MAX(sampleData)
                    ; 扩展范围以确保覆盖所有值
                    histMin = MAX(0.0, minCode - 5.0)
                    histMax = MIN(999.0, maxCode + 5.0)
                  ENDIF ELSE BEGIN
                    histMin = 0.0
                    histMax = 100.0
                  ENDELSE
                  CATCH, /CANCEL
                ENDIF ELSE BEGIN
                  CATCH, /CANCEL
                  histMin = 0.0
                  histMax = 100.0
                ENDELSE
                
                histTask = ENVITask('RasterHistogram')
                histTask.INPUT_RASTER = changeRaster
                histTask.INPUT_MIN = [histMin]
                histTask.INPUT_MAX = [histMax]
                histTask.INPUT_NBINS = [FIX((histMax - histMin) * 10)]  ; 每个编码值一个bin
                IF histTask.INPUT_NBINS[0] LT 100 THEN histTask.INPUT_NBINS = [100]
                IF histTask.INPUT_NBINS[0] GT 10000 THEN histTask.INPUT_NBINS = [10000]
                histTask.Execute
                counts = (histTask.OUTPUT_COUNTS).ToArray()
                minVal = histTask.INPUT_MIN[0]
                maxVal = histTask.INPUT_MAX[0]
                nBins = histTask.INPUT_NBINS[0]
                ; 检查nBins是否有效，避免除零错误
                IF nBins LE 0 THEN BEGIN
                  PRINT, '  错误: 直方图bin数量无效: ' + STRING(nBins)
                  nBins = 100  ; 使用默认值
                ENDIF
                binSize = (maxVal - minVal) / nBins
                ; 检查binSize是否有效
                IF binSize LE 0 THEN BEGIN
                  PRINT, '  警告: binSize无效，使用默认值'
                  binSize = 1.0
                ENDIF
                binCenters = minVal + (FINDGEN(nBins) + 0.5) * binSize
                
                ; 检查counts数组的实际大小
                countsSize = N_ELEMENTS(counts)
                IF countsSize NE nBins THEN BEGIN
                  PRINT, '  警告: counts数组大小(' + STRING(countsSize) + ')与nBins(' + STRING(nBins) + ')不一致，使用实际大小'
                  nBins = countsSize
                  ; 重新计算binCenters
                  binCenters = minVal + (FINDGEN(nBins) + 0.5) * binSize
                ENDIF
                
                ; 解析变化编码，统计各类别变化
                ; 检查result2021结构体是否有效
                IF result2021 NE !NULL THEN BEGIN
                  nClasses = result2021.nClasses
                  classNames = result2021.classNames
                  
                  ; 检查nClasses和classNames是否有效
                  IF (nClasses LE 0) OR (N_ELEMENTS(classNames) NE nClasses) THEN BEGIN
                    PRINT, '  错误: 类别信息无效，nClasses=' + STRING(nClasses) + ', classNames数量=' + STRING(N_ELEMENTS(classNames))
                    ; 清理资源
                    IF OBJ_VALID(changeRaster) THEN changeRaster.Close
                    IF OBJ_VALID(stackedChange) THEN stackedChange.Close
                  ENDIF ELSE BEGIN
                    PRINT, '  变化矩阵（2021年 → 2025年）:'
                    PRINT, '    行=2021年类别，列=2025年类别'
                    PRINT, '    类别: ' + STRJOIN(classNames, ', ')
                    
                    ; 计算变化矩阵
                    ; 注意：分类结果中类别编号通常是0,1,2,3...（0=未分类，1=类别1，2=类别2，3=类别3）
                    ; 编码公式：class2021*10 + class2025
                    changeMatrix = INTARR(nClasses + 1, nClasses + 1)  ; +1 for unclassified (0)
                    totalPixels = 0
                    FOR i=0, nBins-1 DO BEGIN
                      ; 确保索引在有效范围内
                      IF (i LT N_ELEMENTS(counts)) AND (i LT N_ELEMENTS(binCenters)) AND (counts[i] GT 0) THEN BEGIN
                        changeCode = FIX(binCenters[i] + 0.5)  ; 四舍五入到最近的整数
                        class2021Code = changeCode / 10  ; 整数除法（2021年类别编码）
                        class2025Code = changeCode MOD 10  ; 取模（2025年类别编码）
                        ; 验证类别编号范围（0到nClasses，包括未分类）
                        IF (class2021Code GE 0) AND (class2021Code LE nClasses) AND (class2025Code GE 0) AND (class2025Code LE nClasses) THEN BEGIN
                          changeMatrix[class2021Code, class2025Code] = changeMatrix[class2021Code, class2025Code] + LONG(counts[i])
                          totalPixels = totalPixels + LONG(counts[i])
                        ENDIF
                      ENDIF
                    ENDFOR
                    
                    ; 打印变化矩阵
                    PRINT, '    变化矩阵（像素数）:'
                    ; 构建表头
                    headerStr = '      2025年\2021年 | 未分类'
                    FOR j=0, nClasses-1 DO BEGIN
                      headerStr = headerStr + ' | ' + classNames[j]
                    ENDFOR
                    PRINT, headerStr
                    ; 打印矩阵行
                    FOR i=0, nClasses DO BEGIN
                      rowStr = '      '
                      IF i EQ 0 THEN BEGIN
                        rowStr = rowStr + '未分类    | '
                      ENDIF ELSE BEGIN
                        ; 确保索引在有效范围内
                        IF (i-1 GE 0) AND (i-1 LT N_ELEMENTS(classNames)) THEN BEGIN
                          rowStr = rowStr + classNames[i-1] + ' | '
                        ENDIF ELSE BEGIN
                          rowStr = rowStr + '类别' + STRING(i) + ' | '
                        ENDELSE
                      ENDELSE
                      FOR j=0, nClasses DO BEGIN
                        ; 确保索引在有效范围内
                        IF (i GE 0) AND (i LE nClasses) AND (j GE 0) AND (j LE nClasses) THEN BEGIN
                          rowStr = rowStr + STRING(changeMatrix[i, j], FORMAT='(I8)') + ' | '
                        ENDIF ELSE BEGIN
                          rowStr = rowStr + '   N/A   | '
                        ENDELSE
                      ENDFOR
                      PRINT, rowStr
                    ENDFOR
                    
                    ; 计算各类别面积变化
                    PRINT, '  各类别面积变化:'
                    FOR i=0, nClasses-1 DO BEGIN
                      ; 确保索引在有效范围内（changeMatrix大小为nClasses+1，索引范围0到nClasses）
                      IF (i+1 GE 0) AND (i+1 LE nClasses) AND (i GE 0) AND (i LT N_ELEMENTS(classNames)) THEN BEGIN
                        area2021 = TOTAL(changeMatrix[i+1, *])
                        area2025 = TOTAL(changeMatrix[*, i+1])
                        changeArea = area2025 - area2021
                        changePercent = 0.0
                        IF area2021 GT 0 THEN changePercent = (changeArea / area2021) * 100.0
                        className = classNames[i]
                        PRINT, '    ' + className + ':'
                        PRINT, '      2021年: ' + STRING(area2021, FORMAT='(I10)') + ' 像素'
                        PRINT, '      2025年: ' + STRING(area2025, FORMAT='(I10)') + ' 像素'
                        PRINT, '      变化: ' + STRING(changeArea, FORMAT='(I10)') + ' 像素 (' + STRING(changePercent, FORMAT='(F6.2)') + '%)'
                      ENDIF ELSE BEGIN
                        PRINT, '    警告: 类别索引 ' + STRING(i) + ' 超出范围，跳过'
                      ENDELSE
                    ENDFOR
                    
                    changeRaster.Close
                    stackedChange.Close
                  ENDELSE
                ENDIF ELSE BEGIN
                  PRINT, '  错误: result2021结构体无效，无法获取类别信息'
                  ; 清理资源
                  IF OBJ_VALID(changeRaster) THEN changeRaster.Close
                  IF OBJ_VALID(stackedChange) THEN stackedChange.Close
                ENDELSE
              ENDIF ELSE BEGIN
                PRINT, '  警告: 变化检测raster无效'
                ; 清理已创建的对象
                IF OBJ_VALID(changeRaster) THEN changeRaster.Close
                IF OBJ_VALID(stackedChange) THEN stackedChange.Close
              ENDELSE
            ENDIF ELSE BEGIN
              PRINT, '  警告: 堆叠raster无效'
              ; 清理已创建的对象（虽然changeRaster可能还未创建，但为了安全起见检查）
              IF OBJ_VALID(changeRaster) THEN changeRaster.Close
              IF OBJ_VALID(stackedChange) THEN stackedChange.Close
            ENDELSE
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '错误: 计算变化检测失败: ' + !ERROR_STATE.MSG
            ; 清理已创建的对象
            IF OBJ_VALID(changeRaster) THEN changeRaster.Close
            IF OBJ_VALID(stackedChange) THEN stackedChange.Close
          ENDELSE
          
          ; 关闭对齐后的对象（如果不同）
          ; 安全地检查对象是否相同（先检查有效性，再比较）
          IF OBJ_VALID(class2021_aligned) AND OBJ_VALID(class2021) THEN BEGIN
            ; 如果两个对象都有效，检查它们是否不同
            IF (class2021_aligned NE class2021) THEN class2021_aligned.Close
          ENDIF ELSE BEGIN
            ; 如果class2021_aligned有效但class2021无效，说明它们是不同的对象
            IF OBJ_VALID(class2021_aligned) THEN class2021_aligned.Close
          ENDELSE
          
          IF OBJ_VALID(class2025_aligned) AND OBJ_VALID(class2025) THEN BEGIN
            ; 如果两个对象都有效，检查它们是否不同
            IF (class2025_aligned NE class2025) THEN class2025_aligned.Close
          ENDIF ELSE BEGIN
            ; 如果class2025_aligned有效但class2025无效，说明它们是不同的对象
            IF OBJ_VALID(class2025_aligned) THEN class2025_aligned.Close
          ENDELSE
        ENDIF
        
        ; 关闭分类结果
        IF OBJ_VALID(class2021) THEN class2021.Close
        IF OBJ_VALID(class2025) THEN class2025.Close
        
        PRINT, ''
        PRINT, '========================================='
        PRINT, '✓✓✓ 对比分析完成！ ✓✓✓'
        PRINT, '========================================='
        PRINT, '输出文件:'
        PRINT, '  - classification_2021_aligned.dat (对齐后的2021年分类结果)'
        PRINT, '  - classification_2025_aligned.dat (对齐后的2025年分类结果)'
        PRINT, '  - change_detection_2021_2025.dat (变化检测结果)'
        PRINT, ''
      ENDELSE
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '跳过对比分析（需要两个年份的分类结果都成功）'
  ENDELSE
  
  ; 清理资源
  PRINT, '正在清理资源...'
  IF result2021 NE !NULL THEN BEGIN
    IF OBJ_VALID(result2021.finalRaster) THEN result2021.finalRaster.Close
  ENDIF
  IF result2025 NE !NULL THEN BEGIN
    IF OBJ_VALID(result2025.finalRaster) THEN result2025.finalRaster.Close
  ENDIF
  PRINT, '✓ 资源清理完成'
  
END

