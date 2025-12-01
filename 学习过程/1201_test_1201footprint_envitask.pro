PRO test_1201Footprint_ENVITask, $
  input_raster=Raster, $
  input_file_uri=inputFileURI, $
  Background_Value=backValue, $
  output_vector_uri=outShpFile
  COMPILE_OPT idl2
  
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '>>> 任务开始执行 <<<'
  PRINT, '=========================================='
  PRINT, '时间: ', SYSTIME()
  PRINT, ''
  
  PRINT, '正在初始化ENVI对象...'
  e=envi()
  PRINT, 'ENVI对象初始化完成'
  ; Don't get view for batch processing - it can cause hanging
  ; view=e.GetView()

  ; Check input parameters - accept either raster object or file path
  ; If input_file_uri is provided, open the file internally
  PRINT, '正在检查输入参数...'
  
  ; 检查 input_file_uri 参数
  ; 注意：在ENVI Task中，如果参数未传递，直接访问可能会卡住
  ; 使用ARG_PRESENT检查参数是否存在（但这在ENVI Task中可能不工作）
  ; 所以改用更安全的方式：先检查栅格对象，如果没有再尝试文件URI
  PRINT, '检查输入参数...'
  hasFileURI = 0
  
  ; 先检查是否有栅格对象（更安全）
  PRINT, '先检查 input_raster 参数...'
  hasRasterObject = 0
  CATCH, rasterCheckErr
  IF ISA(Raster) THEN BEGIN
    hasRasterObject = 1
    PRINT, 'input_raster 已提供（栅格对象）'
  ENDIF
  CATCH, /CANCEL
  
  ; 如果没有栅格对象，再尝试检查文件URI
  IF ~hasRasterObject THEN BEGIN
    PRINT, '未找到栅格对象，检查 input_file_uri 参数...'
    
    ; ENVI Task传递的ENVIURI可能是对象，需要获取.URI属性
    ; 使用嵌套CATCH来安全地访问参数
    PRINT, '尝试安全访问 input_file_uri 参数...'
    
    ; 外层CATCH：捕获所有访问错误
    CATCH, uriErr
    ; 内层CATCH：检查是否是对象
    CATCH, isaErr
    isObject = ISA(inputFileURI)
    CATCH, /CANCEL
    
    IF isaErr EQ 0 AND isObject THEN BEGIN
      ; 是对象，尝试获取URI属性
      PRINT, 'input_file_uri 是对象类型，获取URI属性...'
      CATCH, uriPropErr
      uriStr = inputFileURI.URI
      IF uriPropErr EQ 0 AND STRLEN(uriStr) GT 0 THEN BEGIN
        hasFileURI = 1
        inputFileURI = uriStr
        PRINT, 'input_file_uri 已提供（从对象）: ', uriStr
      ENDIF ELSE BEGIN
        PRINT, '注意: 无法从对象获取URI'
        inputFileURI = ''
      ENDELSE
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      ; 不是对象或无法检查，尝试作为字符串
      PRINT, 'input_file_uri 不是对象，尝试作为字符串...'
      CATCH, strErr
      uriStr = STRING(inputFileURI)
      IF strErr EQ 0 AND STRLEN(uriStr) GT 0 THEN BEGIN
        hasFileURI = 1
        inputFileURI = uriStr
        PRINT, 'input_file_uri 已提供（字符串）: ', uriStr
      ENDIF ELSE BEGIN
        PRINT, '注意: input_file_uri 转换失败或为空'
        inputFileURI = ''
      ENDELSE
      CATCH, /CANCEL
    ENDELSE
    CATCH, /CANCEL
    
    ; 如果外层CATCH捕获到错误，说明参数访问失败
    IF uriErr NE 0 THEN BEGIN
      PRINT, 'ERROR: 无法访问 input_file_uri 参数'
      PRINT, '      错误信息: ', !ERROR_STATE.MSG
      PRINT, '      这可能是因为参数未定义或访问方式不正确'
      inputFileURI = ''
      hasFileURI = 0
    ENDIF
  ENDIF ELSE BEGIN
    PRINT, '使用栅格对象模式，跳过文件URI检查'
    inputFileURI = ''
  ENDELSE
  
  PRINT, '正在判断输入模式...'
  PRINT, 'hasFileURI = ', hasFileURI
  IF hasFileURI THEN BEGIN
    PRINT, '>>> 将使用文件路径模式处理'
  ENDIF ELSE BEGIN
    PRINT, '>>> 将使用栅格对象模式处理'
  ENDELSE
  IF hasFileURI THEN BEGIN
    PRINT, '>>> 使用文件路径模式'
    ; Open raster from file path
    PRINT, '正在打开栅格文件: ', inputFileURI
    PRINT, '提示: 如果文件很大，这一步可能需要一些时间...'
    
    CATCH, openErr
    Raster = e.OpenRaster(inputFileURI)
    IF openErr NE 0 THEN BEGIN
      PRINT, 'ERROR: 打开栅格文件失败: ', !ERROR_STATE.MSG
      CATCH, /CANCEL
      RETURN
    ENDIF
    CATCH, /CANCEL
    
    PRINT, '文件打开完成，正在验证栅格对象...'
    IF ~OBJ_VALID(Raster) THEN BEGIN
      PRINT, 'ERROR: 无法创建有效的栅格对象!'
      RETURN
    ENDIF
    PRINT, '栅格对象验证通过'
  ENDIF ELSE BEGIN
    ; Use provided raster object
    PRINT, '>>> 使用栅格对象模式'
    PRINT, '检查提供的栅格对象...'
    IF ~ISA(Raster) THEN BEGIN
      PRINT, 'ERROR: 无效的输入栅格! 必须提供 input_raster 或 input_file_uri.'
      RETURN
    ENDIF
    PRINT, '栅格对象类型检查通过'
  ENDELSE
  
  ; Verify raster object is valid
  PRINT, '正在验证栅格对象...'
  IF ~OBJ_VALID(Raster) THEN BEGIN
    PRINT, 'ERROR: 无效的栅格对象!'
    RETURN
  ENDIF
  PRINT, '栅格对象验证通过'
  PRINT, ''
  
  ; Process output file path
  PRINT, '正在处理输出文件路径...'
  PRINT, '输出文件路径: ', outShpFile
  dotPos = STRPOS(outShpFile, '.', /REVERSE_SEARCH)
  IF dotPos GE 0 THEN BEGIN
    FileFormat = STRMID(outShpFile, dotPos)
    IF ~STRMATCH(FileFormat, '.shp', /FOLD_CASE) THEN BEGIN
      outDir = FILE_DIRNAME(outShpFile)+PATH_SEP()
      outShpFile = outDir + FILE_BASENAME(outShpFile, FileFormat)+'.shp'
    ENDIF
  ENDIF ELSE BEGIN
    ; No extension found, add .shp
    outShpFile = outShpFile + '.shp'
  ENDELSE

  ; ============================================================
  ; 检查背景值（整合check_background_value功能）
  ; ============================================================
  
  IF ~OBJ_VALID(Raster) THEN BEGIN
    PRINT, 'ERROR: Invalid raster object!'
    RETURN
  ENDIF
  
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '步骤1: 检查栅格背景值'
  PRINT, '=========================================='
  step1Start = SYSTIME(/SECONDS)
  PRINT, '开始时间: ', SYSTIME()
  
  PRINT, '栅格信息:'
  PRINT, '  尺寸: ', Raster.NROWS, ' x ', Raster.NCOLUMNS
  PRINT, '  波段数: ', Raster.NBANDS
  PRINT, '  数据类型: ', Raster.DATA_TYPE
  PRINT, ''
  
  ; 检查NoData值
  hasNoData = Raster.METADATA.HasTag('data ignore value')
  detectedNoData = !NULL
  recommendedBackground = !NULL
  
  IF hasNoData THEN BEGIN
    detectedNoData = Raster.METADATA['data ignore value']
    PRINT, '元数据中的NoData值: ', detectedNoData
  ENDIF ELSE BEGIN
    PRINT, '未在元数据中找到NoData值'
  ENDELSE
  PRINT, ''
  
  ; 检查各波段统计信息（采样前1000x1000像素，用于推荐背景值）
  PRINT, '波段统计信息（采样前1000x1000像素，用于推荐背景值）:'
  FOR bandIdx = 0, Raster.NBANDS-1 DO BEGIN
    band = ENVISubsetRaster(Raster, BANDS=[bandIdx])
    ncols = LONG(band.NCOLUMNS)
    nrows = LONG(band.NROWS)
    minDim = ncols
    IF nrows LT ncols THEN minDim = nrows
    sampleSize = 1000L
    IF minDim LT 1000L THEN sampleSize = minDim
    
    sampleData = band.GetData(SUB_RECT=[0L, 0L, sampleSize-1L, sampleSize-1L])
    dataMin = MIN(sampleData)
    dataMax = MAX(sampleData)
    dataMean = MEAN(sampleData)
    
    ; 检查最常见的值（可能是背景值）
    hist = HISTOGRAM(sampleData, MIN=dataMin, MAX=dataMax, BINSIZE=1)
    maxCount = MAX(hist, maxIdx)
    mostCommonValue = dataMin + maxIdx
    
    ; 检查边界值（边界通常是背景）
    sampleSizeInt = FIX(sampleSize)
    edgeCols = sampleData[0, *]
    edgeRows = sampleData[*, 0]
    edgeColsEnd = sampleData[sampleSizeInt-1, *]
    edgeRowsEnd = sampleData[*, sampleSizeInt-1]
    edgePixels = REFORM(edgeCols, N_ELEMENTS(edgeCols))
    edgePixels = [edgePixels, REFORM(edgeRows, N_ELEMENTS(edgeRows))]
    edgePixels = [edgePixels, REFORM(edgeColsEnd, N_ELEMENTS(edgeColsEnd))]
    edgePixels = [edgePixels, REFORM(edgeRowsEnd, N_ELEMENTS(edgeRowsEnd))]
    edgeHist = HISTOGRAM(edgePixels, MIN=dataMin, MAX=dataMax, BINSIZE=1)
    edgeMaxCount = MAX(edgeHist, edgeMaxIdx)
    edgeMostCommon = dataMin + edgeMaxIdx
    
    PRINT, FORMAT='(%"  波段 %d:")', bandIdx+1
    PRINT, FORMAT='(%"    最小值: %d, 最大值: %d, 平均值: %.2f")', dataMin, dataMax, dataMean
    PRINT, FORMAT='(%"    最常见值: %d (出现 %d 次)")', mostCommonValue, maxCount
    PRINT, FORMAT='(%"    边界最常见值: %d (出现 %d 次)")', edgeMostCommon, edgeMaxCount
    
    IF hasNoData THEN BEGIN
      noDataCount = N_ELEMENTS(WHERE(sampleData EQ detectedNoData))
      noDataPercent = 100.0 * noDataCount / N_ELEMENTS(sampleData)
      PRINT, FORMAT='(%"    NoData值(%d)出现: %d 次 (%.2f%%)")', $
        detectedNoData, noDataCount, noDataPercent
    ENDIF
    PRINT, ''
    
    ; 如果是最后一个波段，记录推荐背景值
    IF bandIdx EQ Raster.NBANDS-1 THEN BEGIN
      IF hasNoData THEN BEGIN
        recommendedBackground = detectedNoData
      ENDIF ELSE BEGIN
        recommendedBackground = edgeMostCommon
      ENDELSE
    ENDIF
    
    band.Close
  ENDFOR
  
  ; 显示推荐值
  PRINT, '=========================================='
  PRINT, '背景值建议:'
  PRINT, '=========================================='
  IF hasNoData THEN BEGIN
    PRINT, '1. 推荐使用NoData值作为背景值: ', detectedNoData
  ENDIF ELSE BEGIN
    PRINT, '1. 检查边界最常见值，可能是背景值'
    PRINT, '2. 如果数据有固定背景（如0），使用该值'
  ENDELSE
  PRINT, ''
  
  ; ============================================================
  ; 确定背景值
  ; ============================================================
  
  step1End = SYSTIME(/SECONDS)
  PRINT, '步骤1完成，耗时: ', STRTRIM(STRING(step1End - step1Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '步骤2: 确定背景值'
  PRINT, '=========================================='
  step2Start = SYSTIME(/SECONDS)
  PRINT, '开始时间: ', SYSTIME()
  
  ; 确定使用的背景值
  ; 检查背景值是否真正被指定（考虑ENVI Task可能传递默认值0的情况）
  ; 如果backValue是0，需要判断是用户指定的0还是默认值0
  ; 使用KEYWORD_SET检查参数是否真正被传递
  isBackgroundValueSet = 0
  
  ; 尝试检查参数是否被设置
  CATCH, bgCheckErr
  ; 如果参数未定义，N_ELEMENTS会返回0
  IF N_ELEMENTS(backValue) GT 0 THEN BEGIN
    ; 参数有值，但需要判断是否是用户指定的
    ; 在ENVI Task中，如果用户没有填写，参数可能是未定义或!NULL
    ; 如果用户填写了0，backValue会是0
    ; 为了区分"用户指定0"和"未指定"，我们检查参数是否真的被传递
    ; 但ENVI Task总是会传递参数（即使为空），所以我们需要另一种方式
    ; 简单方式：如果backValue是0，且数据有NoData值，优先使用NoData值
    ; 但如果用户明确指定了0，我们也应该尊重
    ; 这里我们采用：如果backValue是0且数据有NoData值，使用NoData值（更智能）
    ; 如果backValue是0且数据没有NoData值，使用0（可能是用户指定的）
    IF backValue EQ 0 AND hasNoData THEN BEGIN
      ; backValue是0，但数据有NoData值，可能是默认值，使用NoData值更合理
      PRINT, '注意: Background Value为0，但检测到NoData值，优先使用NoData值进行自动检测'
      isBackgroundValueSet = 0  ; 视为未指定，使用自动检测
    ENDIF ELSE BEGIN
      isBackgroundValueSet = 1  ; 视为已指定
    ENDELSE
  ENDIF
  CATCH, /CANCEL
  
  ; 如果检查出错，说明参数未定义，使用自动检测
  IF bgCheckErr NE 0 THEN BEGIN
    isBackgroundValueSet = 0
  ENDIF
  
  ; 根据是否指定来决定使用的背景值
  IF ~isBackgroundValueSet THEN BEGIN
    ; 未指定背景值，使用检测到的NoData值或推荐值（自动检测模式）
    IF hasNoData THEN BEGIN
      backValue = detectedNoData
      PRINT, '自动检测模式: 使用NoData值作为背景值: ', backValue
    ENDIF ELSE BEGIN
      IF N_ELEMENTS(recommendedBackground) GT 0 THEN BEGIN
        backValue = recommendedBackground
        PRINT, '自动检测模式: 使用推荐的背景值: ', backValue
      ENDIF ELSE BEGIN
        backValue = 0L
        PRINT, '自动检测模式: 未检测到NoData值，使用默认背景值: ', backValue
      ENDELSE
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '手动指定模式: 使用指定的背景值: ', backValue
  ENDELSE
  PRINT, ''

  ; ============================================================
  ; 提取轮廓
  ; ============================================================
  
  step2End = SYSTIME(/SECONDS)
  PRINT, '步骤2完成，耗时: ', STRTRIM(STRING(step2End - step2Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '步骤3: 提取栅格轮廓'
  PRINT, '=========================================='
  step3Start = SYSTIME(/SECONDS)
  PRINT, '开始时间: ', SYSTIME()
  
  ; Use last band to create mask (usually contains more information)
  ; Check raster is still valid
  IF ~OBJ_VALID(Raster) THEN BEGIN
    PRINT, 'ERROR: Raster object became invalid!'
    RETURN
  ENDIF
  
  ; Get number of bands
  CATCH, err
  numBands = Raster.NBANDS
  IF err NE 0 THEN BEGIN
    PRINT, 'ERROR: Failed to get number of bands: ', !ERROR_STATE.MSG
    CATCH, /CANCEL
    RETURN
  ENDIF
  CATCH, /CANCEL
  
  IF numBands LE 0 THEN BEGIN
    PRINT, 'ERROR: Invalid number of bands: ', numBands
    RETURN
  ENDIF
  
  bandIndex = numBands - 1
  IF bandIndex LT 0 THEN bandIndex = 0
  IF bandIndex GE numBands THEN bandIndex = numBands - 1
  PRINT, '使用波段 ', bandIndex, ' (共 ', numBands, ' 个波段)'
  
  ; Verify Raster is still valid before ENVISubsetRaster
  IF ~OBJ_VALID(Raster) THEN BEGIN
    PRINT, 'ERROR: Raster object invalid before ENVISubsetRaster!'
    RETURN
  ENDIF
  
  ; Create band subset - use same format as original code
  ; Original uses BANDS=[0], we use BANDS=[bandIndex]
  CATCH, err
  band1 = ENVISubsetRaster(Raster, BANDS=[bandIndex])
  IF err NE 0 THEN BEGIN
    PRINT, 'ERROR: Failed to create band subset: ', !ERROR_STATE.MSG
    PRINT, 'Raster object valid: ', OBJ_VALID(Raster)
    PRINT, 'Band index: ', bandIndex, ' (type: ', SIZE(bandIndex, /TNAME), ')'
    CATCH, /CANCEL
    RETURN
  ENDIF
  CATCH, /CANCEL
  
  IF ~OBJ_VALID(band1) THEN BEGIN
    PRINT, 'ERROR: Failed to create valid band subset!'
    RETURN
  ENDIF
  
  ; Check band data range - sample from center area instead of corner
  ncols = LONG(band1.NCOLUMNS)
  nrows = LONG(band1.NROWS)
  minDim = ncols
  IF nrows LT ncols THEN minDim = nrows
  sampleSize = 1000L
  IF minDim LT 1000L THEN sampleSize = minDim
  
  ; Sample from center area instead of top-left corner
  centerX = ncols / 2L
  centerY = nrows / 2L
  halfSize = sampleSize / 2L
  x0 = centerX - halfSize
  y0 = centerY - halfSize
  x1 = centerX + halfSize - 1L
  y1 = centerY + halfSize - 1L
  
  ; Ensure within bounds
  IF x0 LT 0L THEN x0 = 0L
  IF y0 LT 0L THEN y0 = 0L
  IF x1 GE ncols THEN x1 = ncols - 1L
  IF y1 GE nrows THEN y1 = nrows - 1L
  
  sampleData = band1.GetData(SUB_RECT=[x0, y0, x1, y1])
  validPixels = sampleData[WHERE(sampleData NE backValue, count)]
  PRINT, '中心区域采样统计:'
  PRINT, '  总像素数: ', N_ELEMENTS(sampleData)
  PRINT, '  有效像素数（不等于背景值）: ', count
  IF count EQ 0 THEN BEGIN
    PRINT, 'WARNING: 中心区域未找到有效像素!'
    PRINT, '数据范围: ', MIN(sampleData), ' 到 ', MAX(sampleData)
    PRINT, '这可能表示整个影像都是背景，或背景值设置不正确。'
    PRINT, '继续处理完整影像...'
  ENDIF

  ; Create mask file
  PRINT, '正在创建掩膜（排除背景值: ', backValue, '）...'
  ; Sample original band from center to check data
  bandCols = LONG(band1.NCOLUMNS)
  bandRows = LONG(band1.NROWS)
  bandCenterX = bandCols / 2L
  bandCenterY = bandRows / 2L
  bandSampleSize = 100L
  bandHalfSize = bandSampleSize / 2L
  bandX0 = bandCenterX - bandHalfSize
  bandY0 = bandCenterY - bandHalfSize
  bandX1 = bandCenterX + bandHalfSize - 1L
  bandY1 = bandCenterY + bandHalfSize - 1L
  IF bandX0 LT 0L THEN bandX0 = 0L
  IF bandY0 LT 0L THEN bandY0 = 0L
  IF bandX1 GE bandCols THEN bandX1 = bandCols - 1L
  IF bandY1 GE bandRows THEN bandY1 = bandRows - 1L
  bandSample = band1.GetData(SUB_RECT=[bandX0, bandY0, bandX1, bandY1])
  PRINT, '原始波段数据范围（中心采样）: ', MIN(bandSample), ' 到 ', MAX(bandSample)
  PRINT, '原始波段非零像素数（中心采样）: ', N_ELEMENTS(WHERE(bandSample GT 0))
  
  ; Create binary mask: 1 for non-background pixels, 0 for background
  ; This is simpler and more reliable than ENVIDataValuesMaskRaster
  PRINT, '正在创建二进制掩膜（1=非背景, 0=背景）...'
  maskRaster = ENVIBinaryGTThresholdRaster(band1, backValue)
  PRINT, '二进制掩膜已创建: 0=背景, 1=ROI'
  PRINT, ''

  ; Generate classification raster from binary mask
  ; Use NUMBER_OF_RANGES=1 like original code - outputs classes 0 and 1
  ; Class 0 = Background (value 0), Class 1 = ROI (value 1)
  PRINT, '正在从二进制掩膜创建分类栅格...'
  Task = ENVITASK('ColorSliceClassification')
  Task.INPUT_RASTER = maskRaster
  Task.NUMBER_OF_RANGES = 1
  Task.OUTPUT_RASTER_URI = e.GetTemporaryFilename()
  Task.Execute
  
  ; Set classification metadata - required for ClassificationToShapefile
  ; NUMBER_OF_RANGES=1 outputs classes 0 and 1
  ; Class 0 = Background, Class 1 = ROI
  CATCH, err
  ; Set class names metadata - use uppercase like original code
  ; Note: Order is [Class0, Class1] = [Background, ROI]
  Task.OUTPUT_RASTER.METADATA.UpdateItem, 'CLASS NAMES', ['Background', 'ROI']
  
  ; Write metadata to make it a proper classification image
  Task.OUTPUT_RASTER.WriteMetadata
  
  IF err NE 0 THEN BEGIN
    PRINT, 'Warning: Error setting metadata: ', !ERROR_STATE.MSG
    PRINT, 'Continuing anyway...'
  ENDIF
  CATCH, /CANCEL

  ; Check classification result
  classCols = LONG(Task.OUTPUT_RASTER.NCOLUMNS)
  classRows = LONG(Task.OUTPUT_RASTER.NROWS)
  classMinDim = classCols
  IF classRows LT classCols THEN classMinDim = classRows
  classSampleSize = 100L
  IF classMinDim LT 100L THEN classSampleSize = classMinDim
  
  ; Sample from center
  classCenterX = classCols / 2L
  classCenterY = classRows / 2L
  classHalfSize = classSampleSize / 2L
  classX0 = classCenterX - classHalfSize
  classY0 = classCenterY - classHalfSize
  classX1 = classCenterX + classHalfSize - 1L
  classY1 = classCenterY + classHalfSize - 1L
  
  IF classX0 LT 0L THEN classX0 = 0L
  IF classY0 LT 0L THEN classY0 = 0L
  IF classX1 GE classCols THEN classX1 = classCols - 1L
  IF classY1 GE classRows THEN classY1 = classRows - 1L
  
  classSample = Task.OUTPUT_RASTER.GetData(SUB_RECT=[classX0, classY0, classX1, classY1])
  
  ; Check what class values exist
  sortedSample = SORT(classSample)
  uniqIndices = UNIQ(sortedSample)
  IF N_ELEMENTS(uniqIndices) GT 0 THEN BEGIN
    ; 正确获取唯一值：从排序后的数组中取唯一索引位置的值
    uniqueClasses = sortedSample[uniqIndices]
  ENDIF ELSE BEGIN
    uniqueClasses = [MIN(classSample)]
  ENDELSE
  ; 只显示前10个唯一值，避免输出过长
  numUnique = N_ELEMENTS(uniqueClasses)
  IF numUnique GT 10 THEN BEGIN
    PRINT, '分类结果 - 唯一类别值（采样，前10个）: ', uniqueClasses[0:9], ' ... (共', numUnique, '个)'
  ENDIF ELSE BEGIN
    PRINT, '分类结果 - 唯一类别值（采样）: ', uniqueClasses
  ENDELSE
  PRINT, '类别值范围: ', MIN(classSample), ' 到 ', MAX(classSample)
  PRINT, '采样总像素数: ', N_ELEMENTS(classSample)
  
  ; ColorSliceClassification with NUMBER_OF_RANGES=1 on binary mask (0,1)
  ; outputs classes 0 and 1, where 0=Background, 1=ROI
  roiClassValue = 1  ; ROI should be class value 1
  IF N_ELEMENTS(uniqueClasses) GT 1 THEN BEGIN
    ; Find the non-zero class value (should be 1 for ROI)
    nonZeroClasses = uniqueClasses[WHERE(uniqueClasses GT 0)]
    IF N_ELEMENTS(nonZeroClasses) GT 0 THEN roiClassValue = nonZeroClasses[0]
  ENDIF ELSE BEGIN
    ; Only one class value
    roiClassValue = uniqueClasses[0]
    IF roiClassValue EQ 0 THEN BEGIN
      PRINT, 'WARNING: 仅找到背景类别（0）!'
    ENDIF
  ENDELSE
  
  roiPixels = classSample[WHERE(classSample EQ roiClassValue, roiCount)]
  PRINT, 'ROI类别值: ', roiClassValue
  PRINT, 'ROI类别像素数（采样）: ', roiCount
  IF roiCount EQ 0 THEN BEGIN
    PRINT, 'WARNING: 分类结果中未找到ROI像素!'
    PRINT, '所有像素似乎都是背景（类别0）。'
    PRINT, '这可能表示掩膜未正确工作。'
  ENDIF
  PRINT, ''

  ; Delete output file if it exists
  IF FILE_TEST(outShpFile) THEN BEGIN
    FILE_DELETE, outShpFile, /QUIET
    ; Also delete associated files
    shpBase = STRMID(outShpFile, 0, STRPOS(outShpFile, '.shp', /REVERSE_SEARCH))
    FILE_DELETE, shpBase + '.shx', /QUIET
    FILE_DELETE, shpBase + '.dbf', /QUIET
    FILE_DELETE, shpBase + '.prj', /QUIET
  ENDIF

  ; ============================================================
  ; 生成矢量文件
  ; ============================================================
  
  step3End = SYSTIME(/SECONDS)
  PRINT, '步骤3完成，耗时: ', STRTRIM(STRING(step3End - step3Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '步骤4: 生成矢量文件'
  PRINT, '=========================================='
  step4Start = SYSTIME(/SECONDS)
  PRINT, '开始时间: ', SYSTIME()
  
  ; Generate shp file
  PRINT, '正在生成矢量文件: ', outShpFile
  ClassToVectorTask = ENVITASK('ClassificationToShapefile')
  ClassToVectorTask.INPUT_RASTER = Task.OUTPUT_RASTER
  ; Export class 1 (ROI) - ColorSliceClassification with NUMBER_OF_RANGES=1 outputs 0 and 1
  ; Use class name 'ROI' like original code
  ClassToVectorTask.EXPORT_CLASSES = 'ROI'
  ClassToVectorTask.OUTPUT_VECTOR_URI = outShpFile
  ClassToVectorTask.Execute

  ; Check output vector - don't open or display for batch processing
  IF FILE_TEST(outShpFile) THEN BEGIN
    ; Just verify file exists, don't open it to avoid hanging
    fileInfo = FILE_INFO(outShpFile)
    fileSize = fileInfo.size
    PRINT, '矢量文件创建成功! 文件大小: ', fileSize, ' 字节'
    PRINT, '输出文件: ', outShpFile
  ENDIF ELSE BEGIN
    PRINT, 'ERROR: 矢量文件创建失败!'
  ENDELSE
  PRINT, ''

  ; ============================================================
  ; 清理资源
  ; ============================================================
  
  step4End = SYSTIME(/SECONDS)
  PRINT, '步骤4完成，耗时: ', STRTRIM(STRING(step4End - step4Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '步骤5: 清理资源'
  PRINT, '=========================================='
  step5Start = SYSTIME(/SECONDS)
  PRINT, '开始时间: ', SYSTIME()
  
  ; Clean up resources to prevent ENVI from hanging
  PRINT, '正在清理资源...'
  
  ; Close raster objects to free memory - do this immediately after vector generation
  IF OBJ_VALID(Task.OUTPUT_RASTER) THEN BEGIN
    Task.OUTPUT_RASTER.Close
    PRINT, '已关闭分类栅格'
  ENDIF
  IF OBJ_VALID(maskRaster) THEN BEGIN
    maskRaster.Close
    PRINT, '已关闭掩膜栅格'
  ENDIF
  IF OBJ_VALID(band1) THEN BEGIN
    band1.Close
    PRINT, '已关闭波段子集'
  ENDIF
  
  ; Force garbage collection if possible
  PRINT, '资源清理完成'
  step5End = SYSTIME(/SECONDS)
  PRINT, '步骤5完成，耗时: ', STRTRIM(STRING(step5End - step5Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, ''
  
  ; Delete temporary files (optional - may be slow)
  ; tmpFiles = FILE_SEARCH(FILE_DIRNAME(e.GetTemporaryFilename()),'*envi*',COUNT=count)
  ; IF count NE 0 THEN FILE_DELETE, tmpFiles, /QUIET
  
  ; 计算总耗时
  totalTime = step5End - step1Start
  
  PRINT, '=========================================='
  PRINT, '处理完成!'
  PRINT, '=========================================='
  PRINT, '输入文件: ', inputFileURI
  IF STRLEN(inputFileURI) EQ 0 THEN BEGIN
    IF OBJ_VALID(Raster) THEN BEGIN
      CATCH, uriErr
      rasterURI = Raster.URI
      IF uriErr EQ 0 THEN PRINT, '输入文件: ', rasterURI
      CATCH, /CANCEL
    ENDIF
  ENDIF
  PRINT, '输出文件: ', outShpFile
  PRINT, '使用的背景值: ', backValue
  PRINT, ''
  PRINT, '处理时间统计:'
  PRINT, '  步骤1 (检查背景值): ', STRTRIM(STRING(step1End - step1Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, '  步骤2 (确定背景值): ', STRTRIM(STRING(step2End - step2Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, '  步骤3 (提取轮廓): ', STRTRIM(STRING(step3End - step3Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, '  步骤4 (生成矢量): ', STRTRIM(STRING(step4End - step4Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, '  步骤5 (清理资源): ', STRTRIM(STRING(step5End - step5Start, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, '  总耗时: ', STRTRIM(STRING(totalTime, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, '=========================================='
END
