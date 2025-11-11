;==========================================
; 分类结果后处理程序
; 功能：对已分类的影像进行平滑和聚合处理
; 输入：classification_2021.dat
; 输出：classification_2021_smooth.dat
;==========================================

PRO test1111_smooth
  COMPILE_OPT idl2
  
  ; 启动ENVI
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()
  
  PRINT, '=========================================='
  PRINT, '分类结果后处理程序'
  PRINT, '功能：平滑 + 聚合'
  PRINT, '=========================================='
  PRINT, ''
  
  ; ============================================
  ; 1. 设置输入和输出文件路径
  ; ============================================
  inputFile = 'E:\1021WaterData\LC09\LC09_L2SP_121043_20211206_20230505_02_T1\results\classification_2021.dat'
  outputDir = FILE_DIRNAME(inputFile)
  outputFile = outputDir + PATH_SEP() + 'classification_2021_smooth.dat'
  
  ; 检查输入文件是否存在
  IF ~FILE_TEST(inputFile) THEN BEGIN
    PRINT, '错误: 输入文件不存在: ' + inputFile
    RETURN
  ENDIF
  
  PRINT, '输入文件: ' + FILE_BASENAME(inputFile)
  PRINT, '输出文件: ' + FILE_BASENAME(outputFile)
  PRINT, ''
  
  ; 删除已存在的输出文件
  IF FILE_TEST(outputFile) THEN BEGIN
    PRINT, '删除已存在的输出文件...'
    FILE_DELETE, outputFile, /QUIET
    hdrFile = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
    PRINT, '  ✓ 旧文件已删除'
    PRINT, ''
  ENDIF
  
  ; ============================================
  ; 2. 打开分类结果文件
  ; ============================================
  PRINT, '正在打开分类结果文件...'
  inputRaster = e.OpenRaster(inputFile)
  IF ~OBJ_VALID(inputRaster) THEN BEGIN
    PRINT, '错误: 无法打开输入文件'
    RETURN
  ENDIF
  
  PRINT, '  ✓ 文件已打开'
  PRINT, '  影像尺寸: ' + STRING(inputRaster.NCOLUMNS) + ' x ' + STRING(inputRaster.NROWS)
  PRINT, '  波段数: ' + STRING(inputRaster.NBANDS)
  PRINT, ''
  
  ; 读取类别信息（如果存在）
  nClasses = 3  ; 默认3个类别
  classNames = ['植被1110', '水体1110', '其他1110']  ; 默认类别名称
  IF inputRaster.METADATA.HasTag('classes') THEN BEGIN
    nClasses = inputRaster.METADATA['classes'] - 1  ; 减去未分类类别
    PRINT, '  检测到类别数: ' + STRING(nClasses)
  ENDIF
  
  IF inputRaster.METADATA.HasTag('class names') THEN BEGIN
    classNamesAll = inputRaster.METADATA['class names']
    ; 跳过第一个（Unclassified），获取实际类别名称
    IF N_ELEMENTS(classNamesAll) GT 1 THEN BEGIN
      classNames = classNamesAll[1:*]  ; 从索引1开始
      PRINT, '  检测到类别名称: ' + STRING(classNames)
    ENDIF
  ENDIF
  PRINT, ''
  
  ; ============================================
  ; 3. 分类平滑
  ; ============================================
  PRINT, '========== 步骤1: 分类平滑 =========='
  PRINT, '正在进行分类平滑处理...'
  
  kernelSize = 5  ; 平滑核大小
  smoothTask = ENVITask('ClassificationSmoothing')
  smoothTask.INPUT_RASTER = inputRaster
  smoothTask.KERNEL_SIZE = kernelSize
  smoothTask.Execute
  
  smoothRaster = smoothTask.OUTPUT_RASTER
  IF ~OBJ_VALID(smoothRaster) THEN BEGIN
    PRINT, '错误: 平滑处理失败'
    inputRaster.Close
    RETURN
  ENDIF
  
  PRINT, '  ✓ 分类平滑完成（核大小: ' + STRING(kernelSize) + '）'
  PRINT, ''
  
  ; ============================================
  ; 3.1 诊断：验证输入和平滑后的数据
  ; ============================================
  PRINT, '========== 诊断：数据验证 =========='
  PRINT, '正在验证输入数据...'
  
  ; 验证输入数据
  skipAggregation = 0  ; 标志：是否跳过聚合（如果数据异常）
  CATCH, errCheckInput
  IF errCheckInput EQ 0 THEN BEGIN
    nColsTempInput = inputRaster.NCOLUMNS
    nRowsTempInput = inputRaster.NROWS
    nColsInput = LONG(nColsTempInput)
    nRowsInput = LONG(nRowsTempInput)
    nColsInputMinus1 = nColsInput - 1L
    nRowsInputMinus1 = nRowsInput - 1L
    rectColsInput = MIN(500L, nColsInputMinus1)
    rectRowsInput = MIN(500L, nRowsInputMinus1)
    subRectArrayInput = [0L, 0L, rectColsInput, rectRowsInput]
    sampleInput = inputRaster.GetData(BANDS=0, SUB_RECT=subRectArrayInput)
    minValInput = MIN(sampleInput)
    maxValInput = MAX(sampleInput)
    nonZeroInput = N_ELEMENTS(WHERE(sampleInput NE 0))
    sortedInput = sampleInput[SORT(sampleInput)]
    uniqueValsInput = sortedInput[UNIQ(sortedInput)]
    PRINT, '  输入数据验证:'
    PRINT, '    样本区域非零像元: ' + STRING(nonZeroInput) + ' / ' + STRING(N_ELEMENTS(sampleInput))
    PRINT, '    数据值范围: ' + STRING(minValInput) + ' - ' + STRING(maxValInput)
    PRINT, '    唯一值数量: ' + STRING(N_ELEMENTS(uniqueValsInput))
    IF N_ELEMENTS(uniqueValsInput) LE 10 THEN BEGIN
      PRINT, '    唯一值: ' + STRING(uniqueValsInput)
    ENDIF ELSE BEGIN
      PRINT, '    唯一值（前10个）: ' + STRING(uniqueValsInput[0:9])
    ENDELSE
    
    ; 检查分类值是否在合理范围内（0到nClasses）
    IF (maxValInput GT (nClasses + 5)) OR (minValInput LT -1) THEN BEGIN
      PRINT, '  警告: 输入数据值异常（范围: ' + STRING(minValInput) + ' - ' + STRING(maxValInput) + '），将跳过聚合步骤'
      skipAggregation = 1
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  警告: 输入数据验证失败: ' + !ERROR_STATE.MSG
    skipAggregation = 1
  ENDELSE
  
  ; 验证平滑后数据
  PRINT, '正在验证平滑后数据...'
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
    sortedSmooth = sampleSmooth[SORT(sampleSmooth)]
    uniqueValsSmooth = sortedSmooth[UNIQ(sortedSmooth)]
    PRINT, '  平滑后数据验证:'
    PRINT, '    样本区域非零像元: ' + STRING(nonZeroSmooth) + ' / ' + STRING(N_ELEMENTS(sampleSmooth))
    PRINT, '    数据值范围: ' + STRING(minValSmooth) + ' - ' + STRING(maxValSmooth)
    PRINT, '    唯一值数量: ' + STRING(N_ELEMENTS(uniqueValsSmooth))
    IF N_ELEMENTS(uniqueValsSmooth) LE 10 THEN BEGIN
      PRINT, '    唯一值: ' + STRING(uniqueValsSmooth)
    ENDIF ELSE BEGIN
      PRINT, '    唯一值（前10个）: ' + STRING(uniqueValsSmooth[0:9])
    ENDELSE
    
    ; 检查平滑后的分类值是否在合理范围内
    IF (maxValSmooth GT (nClasses + 5)) OR (minValSmooth LT -1) THEN BEGIN
      PRINT, '  警告: 平滑后数据值异常（范围: ' + STRING(minValSmooth) + ' - ' + STRING(maxValSmooth) + '），将跳过聚合步骤'
      skipAggregation = 1
    ENDIF
    
    ; 检查平滑后数据是否几乎全为零
    IF nonZeroSmooth LT (N_ELEMENTS(sampleSmooth) * 0.01) THEN BEGIN
      PRINT, '  警告: 平滑后数据几乎全为零（非零像元 < 1%），将跳过聚合步骤'
      skipAggregation = 1
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  警告: 平滑后数据验证失败: ' + !ERROR_STATE.MSG
    skipAggregation = 1
  ENDELSE
  PRINT, ''
  
  ; ============================================
  ; 4. 分类聚合（去除小斑块）- 使用3种方法
  ; ============================================
  ; 如果数据异常，直接跳过聚合
  IF skipAggregation EQ 1 THEN BEGIN
    PRINT, '========== 步骤2: 跳过聚合（数据异常） =========='
    PRINT, '  由于数据验证发现异常，将跳过聚合步骤，直接使用平滑结果'
    PRINT, ''
    ; 直接导出平滑结果
    IF OBJ_VALID(smoothRaster) THEN BEGIN
      smoothRaster.Export, outputFile, 'ENVI'
      PRINT, '  ✓ 平滑结果已保存（跳过聚合）'
      WAIT, 1.0
      finalRaster = e.OpenRaster(outputFile)
      methodUsed = '仅平滑（数据异常，跳过聚合）'
      useAggregation = 0
      smoothRaster.Close
    ENDIF
  ENDIF ELSE BEGIN
    PRINT, '========== 步骤2: 分类聚合（3种方法） =========='
    
    ; 获取空间参考信息
    spatialRef = smoothRaster.SPATIALREF
    aggregateSize = 0  ; 初始化为0
    useAggregation = 0  ; 是否使用聚合
    methodUsed = ''  ; 记录使用的方法
  
  IF OBJ_VALID(spatialRef) THEN BEGIN
    pixelArea = PRODUCT(spatialRef.PIXEL_SIZE) / 1E6  ; km²
    minArea = 0.01  ; 最小面积 0.01 km²
    aggregateSize = FIX(minArea * 1E6 / PRODUCT(spatialRef.PIXEL_SIZE)) > 9
    PRINT, '  像元面积: ' + STRING(pixelArea, FORMAT='(F8.6)') + ' km²'
    PRINT, '  最小面积阈值: ' + STRING(minArea) + ' km²'
    PRINT, '  计算出的聚合阈值: ' + STRING(aggregateSize) + ' 像元'
  ENDIF ELSE BEGIN
    PRINT, '  警告: 无法获取空间参考信息，使用默认聚合阈值'
    aggregateSize = 50  ; 默认50个像元
  ENDELSE
  PRINT, ''
  
  ; ============================================
  ; 方法1：尝试使用原始聚合参数
  ; ============================================
  PRINT, '--- 方法1: 使用原始聚合参数（MINIMUM_SIZE=' + STRING(aggregateSize) + '）---'
  IF aggregateSize GT 9 THEN BEGIN
    CATCH, errMethod1
    IF errMethod1 EQ 0 THEN BEGIN
      aggregateTask1 = ENVITask('ClassificationAggregation')
      aggregateTask1.INPUT_RASTER = smoothRaster
      aggregateTask1.MINIMUM_SIZE = aggregateSize
      tempOutput1 = outputDir + PATH_SEP() + 'classification_2021_smooth_method1.dat'
      IF FILE_TEST(tempOutput1) THEN BEGIN
        FILE_DELETE, tempOutput1, /QUIET
        hdrFile1 = FILE_DIRNAME(tempOutput1) + PATH_SEP() + FILE_BASENAME(tempOutput1, '.dat') + '.hdr'
        IF FILE_TEST(hdrFile1) THEN FILE_DELETE, hdrFile1, /QUIET
      ENDIF
      aggregateTask1.OUTPUT_RASTER_URI = tempOutput1
      aggregateTask1.Execute
      
      tempRaster1 = aggregateTask1.OUTPUT_RASTER
      IF OBJ_VALID(tempRaster1) THEN BEGIN
        ; 验证方法1的结果
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
          sorted1 = sample1[SORT(sample1)]
          uniqueVals1 = sorted1[UNIQ(sorted1)]
          
          minVal1 = MIN(sample1)
          maxVal1 = MAX(sample1)
          PRINT, '  方法1结果验证:'
          PRINT, '    非零像元: ' + STRING(nonZero1) + ' / ' + STRING(N_ELEMENTS(sample1))
          PRINT, '    数据值范围: ' + STRING(minVal1) + ' - ' + STRING(maxVal1)
          PRINT, '    唯一值数量: ' + STRING(N_ELEMENTS(uniqueVals1))
          IF N_ELEMENTS(uniqueVals1) LE 10 THEN BEGIN
            PRINT, '    唯一值: ' + STRING(uniqueVals1)
          ENDIF ELSE BEGIN
            PRINT, '    唯一值（前10个）: ' + STRING(uniqueVals1[0:9])
          ENDELSE
          
          ; 验证数据有效性：1) 非零像元 > 10%, 2) 数据值在合理范围内
          dataValid1 = (nonZero1 GT (N_ELEMENTS(sample1) * 0.1)) AND $
                      (maxVal1 LE (nClasses + 5)) AND (minVal1 GE -1)
          
          ; 如果方法1有效，使用它
          IF dataValid1 THEN BEGIN
            PRINT, '  ✓ 方法1成功，数据有效'
            PRINT, '  [日志] 开始处理方法1的输出文件...'
            
            ; 关闭临时raster对象
            PRINT, '  [日志] 关闭tempRaster1...'
            tempRaster1.Close
            tempRaster1 = !NULL
            PRINT, '  [日志] tempRaster1已关闭'
            
            ; 删除已存在的输出文件
            PRINT, '  [日志] 检查并删除已存在的输出文件...'
            IF FILE_TEST(outputFile) THEN BEGIN
              PRINT, '  [日志] 删除输出文件: ' + outputFile
              FILE_DELETE, outputFile, /QUIET
              hdrFileFinal = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '.hdr'
              IF FILE_TEST(hdrFileFinal) THEN BEGIN
                PRINT, '  [日志] 删除头文件: ' + hdrFileFinal
                FILE_DELETE, hdrFileFinal, /QUIET
              ENDIF
            ENDIF
            PRINT, '  [日志] 输出文件清理完成'
            
            ; 移动临时文件到最终位置
            PRINT, '  [日志] 移动临时文件到最终位置...'
            PRINT, '  [日志] 源文件: ' + tempOutput1
            PRINT, '  [日志] 目标文件: ' + outputFile
            FILE_MOVE, tempOutput1, outputFile, /OVERWRITE
            PRINT, '  [日志] 数据文件移动完成'
            
            ; 移动头文件
            hdrFile1 = FILE_DIRNAME(tempOutput1) + PATH_SEP() + FILE_BASENAME(tempOutput1, '.dat') + '.hdr'
            hdrFileFinal = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '.hdr'
            IF FILE_TEST(hdrFile1) THEN BEGIN
              PRINT, '  [日志] 移动头文件: ' + hdrFile1 + ' -> ' + hdrFileFinal
              FILE_MOVE, hdrFile1, hdrFileFinal, /OVERWRITE
              PRINT, '  [日志] 头文件移动完成'
            ENDIF ELSE BEGIN
              PRINT, '  [日志] 警告: 头文件不存在: ' + hdrFile1
            ENDELSE
            
            ; 等待文件系统同步
            PRINT, '  [日志] 等待文件系统同步...'
            WAIT, 1.0
            PRINT, '  [日志] 文件系统同步完成'
            
            ; 打开最终文件
            PRINT, '  [日志] 打开最终输出文件...'
            CATCH, errOpenFinal
            IF errOpenFinal EQ 0 THEN BEGIN
              finalRaster = e.OpenRaster(outputFile)
              IF OBJ_VALID(finalRaster) THEN BEGIN
                PRINT, '  [日志] 最终文件打开成功'
                methodUsed = '方法1（原始参数）'
                useAggregation = 1
              ENDIF ELSE BEGIN
                PRINT, '  [日志] 错误: 无法打开最终文件'
              ENDELSE
              CATCH, /CANCEL
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
              PRINT, '  [日志] 错误: 打开最终文件失败: ' + !ERROR_STATE.MSG
            ENDELSE
            PRINT, '  [日志] 方法1处理完成'
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            PRINT, '  ✗ 方法1失败，数据无效'
            IF maxVal1 GT (nClasses + 5) THEN BEGIN
              PRINT, '    原因: 数据值超出合理范围（最大值: ' + STRING(maxVal1) + '）'
            ENDIF ELSE IF nonZero1 LE (N_ELEMENTS(sample1) * 0.1) THEN BEGIN
              PRINT, '    原因: 非零像元过少（' + STRING(nonZero1) + ' / ' + STRING(N_ELEMENTS(sample1)) + '）'
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
      PRINT, '  ✗ 方法1执行失败: ' + !ERROR_STATE.MSG
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '  跳过方法1（聚合阈值太小）'
  ENDELSE
  
  ; ============================================
  ; 方法2：使用更小的聚合阈值（如果方法1失败）
  ; ============================================
  IF useAggregation EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, '--- 方法2: 使用更小的聚合阈值（MINIMUM_SIZE=5）---'
    CATCH, errMethod2
    IF errMethod2 EQ 0 THEN BEGIN
      aggregateTask2 = ENVITask('ClassificationAggregation')
      aggregateTask2.INPUT_RASTER = smoothRaster
      aggregateTask2.MINIMUM_SIZE = 5  ; 使用更小的阈值
      tempOutput2 = outputDir + PATH_SEP() + 'classification_2021_smooth_method2.dat'
      IF FILE_TEST(tempOutput2) THEN BEGIN
        FILE_DELETE, tempOutput2, /QUIET
        hdrFile2 = FILE_DIRNAME(tempOutput2) + PATH_SEP() + FILE_BASENAME(tempOutput2, '.dat') + '.hdr'
        IF FILE_TEST(hdrFile2) THEN FILE_DELETE, hdrFile2, /QUIET
      ENDIF
      aggregateTask2.OUTPUT_RASTER_URI = tempOutput2
      aggregateTask2.Execute
      
      tempRaster2 = aggregateTask2.OUTPUT_RASTER
      IF OBJ_VALID(tempRaster2) THEN BEGIN
        ; 验证方法2的结果
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
          sorted2 = sample2[SORT(sample2)]
          uniqueVals2 = sorted2[UNIQ(sorted2)]
          
          minVal2 = MIN(sample2)
          maxVal2 = MAX(sample2)
          PRINT, '  方法2结果验证:'
          PRINT, '    非零像元: ' + STRING(nonZero2) + ' / ' + STRING(N_ELEMENTS(sample2))
          PRINT, '    数据值范围: ' + STRING(minVal2) + ' - ' + STRING(maxVal2)
          PRINT, '    唯一值数量: ' + STRING(N_ELEMENTS(uniqueVals2))
          IF N_ELEMENTS(uniqueVals2) LE 10 THEN BEGIN
            PRINT, '    唯一值: ' + STRING(uniqueVals2)
          ENDIF ELSE BEGIN
            PRINT, '    唯一值（前10个）: ' + STRING(uniqueVals2[0:9])
          ENDELSE
          
          ; 验证数据有效性
          dataValid2 = (nonZero2 GT (N_ELEMENTS(sample2) * 0.1)) AND $
                      (maxVal2 LE (nClasses + 5)) AND (minVal2 GE -1)
          
          ; 如果方法2有效，使用它
          IF dataValid2 THEN BEGIN
            PRINT, '  ✓ 方法2成功，数据有效'
            ; 将临时文件重命名为最终输出文件
            tempRaster2.Close
            IF FILE_TEST(outputFile) THEN BEGIN
              FILE_DELETE, outputFile, /QUIET
              hdrFileFinal = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '.hdr'
              IF FILE_TEST(hdrFileFinal) THEN FILE_DELETE, hdrFileFinal, /QUIET
            ENDIF
            FILE_MOVE, tempOutput2, outputFile, /OVERWRITE
            hdrFile2 = FILE_DIRNAME(tempOutput2) + PATH_SEP() + FILE_BASENAME(tempOutput2, '.dat') + '.hdr'
            hdrFileFinal = FILE_DIRNAME(outputFile) + PATH_SEP() + FILE_BASENAME(outputFile, '.dat') + '.hdr'
            IF FILE_TEST(hdrFile2) THEN FILE_MOVE, hdrFile2, hdrFileFinal, /OVERWRITE
            WAIT, 0.5
            finalRaster = e.OpenRaster(outputFile)
            methodUsed = '方法2（小阈值聚合）'
            useAggregation = 1
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            PRINT, '  ✗ 方法2失败，数据无效'
            IF maxVal2 GT (nClasses + 5) THEN BEGIN
              PRINT, '    原因: 数据值超出合理范围（最大值: ' + STRING(maxVal2) + '）'
            ENDIF ELSE IF nonZero2 LE (N_ELEMENTS(sample2) * 0.1) THEN BEGIN
              PRINT, '    原因: 非零像元过少（' + STRING(nonZero2) + ' / ' + STRING(N_ELEMENTS(sample2)) + '）'
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
      PRINT, '  ✗ 方法2执行失败: ' + !ERROR_STATE.MSG
    ENDELSE
  ENDIF
  
  ; ============================================
  ; 方法3：跳过聚合，直接使用平滑结果（如果方法1和2都失败）
  ; ============================================
  IF useAggregation EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, '--- 方法3: 跳过聚合，直接使用平滑结果 ---'
    PRINT, '  原因: 前两种聚合方法都导致数据丢失'
    PRINT, '  直接保存平滑结果...'
    
    IF OBJ_VALID(smoothRaster) THEN BEGIN
      smoothRaster.Export, outputFile, 'ENVI'
      PRINT, '  ✓ 平滑结果已保存'
      WAIT, 1.0
      finalRaster = e.OpenRaster(outputFile)
      IF OBJ_VALID(finalRaster) THEN BEGIN
        ; 验证方法3的结果
        nColsTemp3 = finalRaster.NCOLUMNS
        nRowsTemp3 = finalRaster.NROWS
        nCols3 = LONG(nColsTemp3)
        nRows3 = LONG(nRowsTemp3)
        nCols3Minus1 = nCols3 - 1L
        nRows3Minus1 = nRows3 - 1L
        rectCols3 = MIN(500L, nCols3Minus1)
        rectRows3 = MIN(500L, nRows3Minus1)
        subRectArray3 = [0L, 0L, rectCols3, rectRows3]
        sample3 = finalRaster.GetData(BANDS=0, SUB_RECT=subRectArray3)
        nonZero3 = N_ELEMENTS(WHERE(sample3 NE 0))
        sorted3 = sample3[SORT(sample3)]
        uniqueVals3 = sorted3[UNIQ(sorted3)]
        
        minVal3 = MIN(sample3)
        maxVal3 = MAX(sample3)
        PRINT, '  方法3结果验证:'
        PRINT, '    非零像元: ' + STRING(nonZero3) + ' / ' + STRING(N_ELEMENTS(sample3))
        PRINT, '    数据值范围: ' + STRING(minVal3) + ' - ' + STRING(maxVal3)
        PRINT, '    唯一值数量: ' + STRING(N_ELEMENTS(uniqueVals3))
        IF N_ELEMENTS(uniqueVals3) LE 10 THEN BEGIN
          PRINT, '    唯一值: ' + STRING(uniqueVals3)
        ENDIF ELSE BEGIN
          PRINT, '    唯一值（前10个）: ' + STRING(uniqueVals3[0:9])
        ENDELSE
        
        dataValid3 = (nonZero3 GT (N_ELEMENTS(sample3) * 0.1)) AND $
                    (maxVal3 LE (nClasses + 5)) AND (minVal3 GE -1)
        
        IF dataValid3 THEN BEGIN
          PRINT, '  ✓ 方法3成功，数据有效'
          methodUsed = '方法3（仅平滑，无聚合）'
        ENDIF ELSE BEGIN
          PRINT, '  ✗ 方法3也失败，数据无效'
          IF maxVal3 GT (nClasses + 5) THEN BEGIN
            PRINT, '    原因: 数据值超出合理范围（最大值: ' + STRING(maxVal3) + '）'
          ENDIF ELSE IF nonZero3 LE (N_ELEMENTS(sample3) * 0.1) THEN BEGIN
            PRINT, '    原因: 非零像元过少（' + STRING(nonZero3) + ' / ' + STRING(N_ELEMENTS(sample3)) + '）'
          ENDIF
        ENDELSE
      ENDIF
      smoothRaster.Close
    ENDIF
  ENDIF
  
  ; 关闭平滑结果（如果还没有关闭，且使用了聚合方法）
  PRINT, '  [日志] 检查是否需要关闭smoothRaster...'
  IF OBJ_VALID(smoothRaster) AND (useAggregation EQ 1) THEN BEGIN
    PRINT, '  [日志] 关闭smoothRaster（已使用聚合方法）...'
    smoothRaster.Close
    smoothRaster = !NULL
    PRINT, '  [日志] smoothRaster已关闭'
  ENDIF ELSE BEGIN
    PRINT, '  [日志] smoothRaster不需要关闭或已关闭'
  ENDELSE
  
  PRINT, ''
  PRINT, '使用的处理方法: ' + methodUsed
  PRINT, ''
  PRINT, '  [日志] 步骤2（聚合）完成，准备进入步骤3（更新元数据）'
  PRINT, ''
  ENDELSE
  
  ; ============================================
  ; 5. 更新元数据
  ; ============================================
  PRINT, '========== 步骤3: 更新元数据 =========='
  PRINT, '正在更新分类结果元数据...'
  PRINT, '  [日志] 进入元数据更新步骤'
  
  ; 等待文件写入完成
  PRINT, '  [日志] 等待文件写入完成...'
  WAIT, 1.0
  PRINT, '  [日志] 等待完成'
  
  ; 如果finalRaster已经打开，先关闭它
  PRINT, '  [日志] 检查finalRaster状态...'
  IF OBJ_VALID(finalRaster) THEN BEGIN
    PRINT, '  [日志] finalRaster已打开，正在关闭...'
    finalRaster.Close
    finalRaster = !NULL
    PRINT, '  [日志] finalRaster已关闭'
  ENDIF ELSE BEGIN
    PRINT, '  [日志] finalRaster未打开或已关闭'
  ENDELSE
  
  ; 等待一下确保文件已关闭
  PRINT, '  [日志] 等待文件关闭完成...'
  WAIT, 0.5
  PRINT, '  [日志] 等待完成'
  
  ; 打开输出文件以更新元数据
  PRINT, '  [日志] 打开输出文件以更新元数据: ' + outputFile
  CATCH, errOpenForMetadata
  IF errOpenForMetadata EQ 0 THEN BEGIN
    finalRaster = e.OpenRaster(outputFile)
    IF OBJ_VALID(finalRaster) THEN BEGIN
      PRINT, '  [日志] 文件打开成功，准备更新元数据'
    ENDIF ELSE BEGIN
      PRINT, '  [日志] 错误: 文件打开失败，对象无效'
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  [日志] 错误: 打开文件异常: ' + !ERROR_STATE.MSG
  ENDELSE
  
  IF ~OBJ_VALID(finalRaster) THEN BEGIN
    PRINT, '错误: 无法打开输出文件'
    PRINT, '  [日志] 清理资源并退出...'
    ; 清理资源
    IF OBJ_VALID(inputRaster) THEN BEGIN
      inputRaster.Close
      inputRaster = !NULL
    ENDIF
    IF OBJ_VALID(smoothRaster) THEN BEGIN
      smoothRaster.Close
      smoothRaster = !NULL
    ENDIF
    RETURN
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
  
  PRINT, '  类别名称列表:'
  FOR i=0, nTotalClasses-1 DO BEGIN
    PRINT, '    类别 ' + STRING(i) + ': ' + classNamesWithUnclassified[i]
  ENDFOR
  
  ; 创建颜色查找表
  classRGB = INTARR(3, nTotalClasses)
  classRGB[*, 0] = [0, 0, 0]  ; 黑色 - 未分类
  
  PRINT, '  分配颜色:'
  PRINT, '    类别 0 (Unclassified): RGB(0, 0, 0) - 黑色'
  
  FOR i=0, nClasses-1 DO BEGIN
    className = STRUPCASE(classNamesWithUnclassified[i+1])
    colorAssigned = 0
    
    ; 优先匹配：植被（绿色 RGB(0, 255, 0)）
    IF STRMATCH(className, '*植被*') OR STRMATCH(className, '*VEG*') OR STRMATCH(className, '*植*') OR $
       STRMATCH(className, '*VEGETATION*') OR STRMATCH(className, '*植物*') THEN BEGIN
      classRGB[*, i+1] = [0, 255, 0]  ; 绿色 - 植被
      PRINT, '    类别 ' + STRING(i+1) + ' (' + classNamesWithUnclassified[i+1] + '): RGB(0, 255, 0) - 绿色（植被）'
      colorAssigned = 1
    ENDIF ELSE IF STRMATCH(className, '*水体*') OR STRMATCH(className, '*WATER*') OR STRMATCH(className, '*水*') OR $
                STRMATCH(className, '*水体*') THEN BEGIN
      ; 蓝色 - 水体
      classRGB[*, i+1] = [0, 0, 255]  ; 蓝色 - 水体
      PRINT, '    类别 ' + STRING(i+1) + ' (' + classNamesWithUnclassified[i+1] + '): RGB(0, 0, 255) - 蓝色（水体）'
      colorAssigned = 1
    ENDIF ELSE IF STRMATCH(className, '*其他*') OR STRMATCH(className, '*OTHER*') OR STRMATCH(className, '*其*') OR $
                STRMATCH(className, '*其它*') THEN BEGIN
      ; 灰色 - 其他
      classRGB[*, i+1] = [128, 128, 128]  ; 灰色 - 其他
      PRINT, '    类别 ' + STRING(i+1) + ' (' + classNamesWithUnclassified[i+1] + '): RGB(128, 128, 128) - 灰色（其他）'
      colorAssigned = 1
    ENDIF ELSE BEGIN
      ; 如果无法匹配，根据类别名称的第一个字符或索引分配颜色
      ; 但优先尝试根据常见的中文关键词匹配
      firstChar = STRMID(className, 0, 1)
      IF (firstChar EQ '植') OR (firstChar EQ 'V') THEN BEGIN
        classRGB[*, i+1] = [0, 255, 0]  ; 绿色
        PRINT, '    类别 ' + STRING(i+1) + ' (' + classNamesWithUnclassified[i+1] + '): RGB(0, 255, 0) - 绿色（根据首字符匹配）'
      ENDIF ELSE IF (firstChar EQ '水') OR (firstChar EQ 'W') THEN BEGIN
        classRGB[*, i+1] = [0, 0, 255]  ; 蓝色
        PRINT, '    类别 ' + STRING(i+1) + ' (' + classNamesWithUnclassified[i+1] + '): RGB(0, 0, 255) - 蓝色（根据首字符匹配）'
      ENDIF ELSE IF (firstChar EQ '其') OR (firstChar EQ 'O') THEN BEGIN
        classRGB[*, i+1] = [128, 128, 128]  ; 灰色
        PRINT, '    类别 ' + STRING(i+1) + ' (' + classNamesWithUnclassified[i+1] + '): RGB(128, 128, 128) - 灰色（根据首字符匹配）'
      ENDIF ELSE BEGIN
        ; 根据索引分配不同颜色，确保每个类别都有不同颜色
        CASE i MOD 6 OF
          0: classRGB[*, i+1] = [0, 255, 0]    ; 绿色（默认第一个类别）
          1: classRGB[*, i+1] = [0, 0, 255]    ; 蓝色（默认第二个类别）
          2: classRGB[*, i+1] = [128, 128, 128] ; 灰色（默认第三个类别）
          3: classRGB[*, i+1] = [255, 255, 0]  ; 黄色
          4: classRGB[*, i+1] = [255, 0, 255]  ; 洋红
          5: classRGB[*, i+1] = [0, 255, 255]  ; 青色
        ENDCASE
        PRINT, '    类别 ' + STRING(i+1) + ' (' + classNamesWithUnclassified[i+1] + '): RGB(' + $
               STRING(classRGB[0, i+1]) + ', ' + STRING(classRGB[1, i+1]) + ', ' + STRING(classRGB[2, i+1]) + ') - 自动分配'
      ENDELSE
    ENDELSE
  ENDFOR
  
  ; 验证颜色是否都不同
  PRINT, '  颜色验证:'
  hasDuplicateColors = 0
  FOR i=1, nTotalClasses-1 DO BEGIN
    FOR j=i+1, nTotalClasses-1 DO BEGIN
      IF (classRGB[0, i] EQ classRGB[0, j]) AND $
         (classRGB[1, i] EQ classRGB[1, j]) AND $
         (classRGB[2, i] EQ classRGB[2, j]) THEN BEGIN
        hasDuplicateColors = 1
        PRINT, '    警告: 类别 ' + STRING(i) + ' (' + classNamesWithUnclassified[i] + ') 和类别 ' + $
               STRING(j) + ' (' + classNamesWithUnclassified[j] + ') 颜色相同!'
        PRINT, '      颜色: RGB(' + STRING(classRGB[0, i]) + ', ' + STRING(classRGB[1, i]) + ', ' + STRING(classRGB[2, i]) + ')'
      ENDIF
    ENDFOR
  ENDFOR
  IF hasDuplicateColors EQ 0 THEN BEGIN
    PRINT, '    ✓ 所有类别颜色都不同'
  ENDIF ELSE BEGIN
    PRINT, '    ✗ 发现重复颜色，这可能导致显示问题!'
  ENDELSE
  
  ; 构建数组字面量格式的class lookup（ENVI标准格式）
  ; 使用简单的数组字面量格式，每个类别一个RGB数组
  classLookupArray = !NULL
  
  ; 根据类别数量动态构建数组字面量
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
  ENDIF ELSE IF nTotalClasses EQ 6 THEN BEGIN
    classLookupArray = [[classRGB[0,0], classRGB[1,0], classRGB[2,0]], $
                       [classRGB[0,1], classRGB[1,1], classRGB[2,1]], $
                       [classRGB[0,2], classRGB[1,2], classRGB[2,2]], $
                       [classRGB[0,3], classRGB[1,3], classRGB[2,3]], $
                       [classRGB[0,4], classRGB[1,4], classRGB[2,4]], $
                       [classRGB[0,5], classRGB[1,5], classRGB[2,5]]]
  ENDIF ELSE BEGIN
    ; 如果类别数量超过6，直接使用3×N格式，不构建数组字面量
    PRINT, '  警告: 类别数量较多（' + STRING(nTotalClasses) + '），将使用3×N格式'
    classLookupArray = !NULL  ; 设置为空，后续使用3×N格式
  ENDELSE
  
  ; 设置元数据 - 使用最简化的方式，避免崩溃
  PRINT, '  准备设置的 class lookup 值:'
  FOR i=0, nTotalClasses-1 DO BEGIN
    PRINT, '    类别 ' + STRING(i) + ' (' + classNamesWithUnclassified[i] + '): RGB(' + $
           STRING(classRGB[0, i]) + ', ' + STRING(classRGB[1, i]) + ', ' + STRING(classRGB[2, i]) + ')'
  ENDFOR
  
  ; 设置classes
  CATCH, errClasses
  IF errClasses EQ 0 THEN BEGIN
    IF ~finalRaster.METADATA.HasTag('classes') THEN BEGIN
      finalRaster.METADATA.AddItem, 'classes', nTotalClasses
    ENDIF ELSE BEGIN
      finalRaster.METADATA.UpdateItem, 'classes', nTotalClasses
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  警告: 设置classes失败: ' + !ERROR_STATE.MSG
  ENDELSE
  
  ; 设置class names
  CATCH, errClassNames
  IF errClassNames EQ 0 THEN BEGIN
    IF ~finalRaster.METADATA.HasTag('class names') THEN BEGIN
      finalRaster.METADATA.AddItem, 'class names', classNamesWithUnclassified
    ENDIF ELSE BEGIN
      finalRaster.METADATA.UpdateItem, 'class names', classNamesWithUnclassified
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  警告: 设置class names失败: ' + !ERROR_STATE.MSG
  ENDELSE
  
  ; 设置class lookup - 直接使用3×N格式（最稳定）
  CATCH, errLookup
  IF errLookup EQ 0 THEN BEGIN
    IF ~finalRaster.METADATA.HasTag('class lookup') THEN BEGIN
      finalRaster.METADATA.AddItem, 'class lookup', classRGB
      PRINT, '  ✓ 已添加 class lookup 元数据（3×N格式）'
    ENDIF ELSE BEGIN
      finalRaster.METADATA.UpdateItem, 'class lookup', classRGB
      PRINT, '  ✓ 已更新 class lookup 元数据（3×N格式）'
    ENDELSE
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  警告: 设置 class lookup 失败: ' + !ERROR_STATE.MSG
  ENDELSE
  
    ; 写入元数据
    CATCH, errWriteMetadata
    IF errWriteMetadata EQ 0 THEN BEGIN
      finalRaster.WriteMetadata
      PRINT, '  ✓ 元数据更新完成'
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 写入元数据失败: ' + !ERROR_STATE.MSG
      PRINT, '  但文件已经创建，可以手动检查元数据'
    ENDELSE
  PRINT, ''
  
  ; 关闭finalRaster，准备验证
  IF OBJ_VALID(finalRaster) THEN BEGIN
    finalRaster.Close
    finalRaster = !NULL
  ENDIF
  
  ; 等待文件系统同步
  WAIT, 0.5
  
  ; ============================================
  ; 6. 验证结果
  ; ============================================
  PRINT, '========== 步骤4: 验证结果 =========='
  IF FILE_TEST(outputFile) THEN BEGIN
    fileInfo = FILE_INFO(outputFile)
    fileSize = fileInfo[0].size
    PRINT, '  ✓ 输出文件已创建: ' + FILE_BASENAME(outputFile)
    PRINT, '  文件大小: ' + STRING(fileSize/1024/1024, FORMAT='(F8.2)') + ' MB'
    
    ; 验证数据（重新打开文件进行验证）
    CATCH, errValidate
    IF errValidate EQ 0 THEN BEGIN
      ; 打开文件进行验证
      validateRaster = e.OpenRaster(outputFile)
      IF OBJ_VALID(validateRaster) THEN BEGIN
        ; 将NCOLUMNS和NROWS转换为LONG类型，分步计算
        nColsTemp = validateRaster.NCOLUMNS
        nRowsTemp = validateRaster.NROWS
        nCols = LONG(nColsTemp)
        nRows = LONG(nRowsTemp)
        nColsMinus1 = nCols - 1L
        nRowsMinus1 = nRows - 1L
        rectCols = MIN(200L, nColsMinus1)
        rectRows = MIN(200L, nRowsMinus1)
        subRectArray = [0L, 0L, rectCols, rectRows]
        sampleData = validateRaster.GetData(BANDS=0, SUB_RECT=subRectArray)
        minValFinal = MIN(sampleData)
        maxValFinal = MAX(sampleData)
        nonZeroCount = N_ELEMENTS(WHERE(sampleData NE 0))
        sortedFinal = sampleData[SORT(sampleData)]
        uniqueValsFinal = sortedFinal[UNIQ(sortedFinal)]
        
        PRINT, '  数据验证:'
        PRINT, '    样本区域非零像元: ' + STRING(nonZeroCount) + ' / ' + STRING(N_ELEMENTS(sampleData))
        PRINT, '    数据值范围: ' + STRING(minValFinal) + ' - ' + STRING(maxValFinal)
        PRINT, '    唯一值数量: ' + STRING(N_ELEMENTS(uniqueValsFinal))
        IF N_ELEMENTS(uniqueValsFinal) LE 10 THEN BEGIN
          PRINT, '    唯一值: ' + STRING(uniqueValsFinal)
        ENDIF ELSE BEGIN
          PRINT, '    唯一值（前10个）: ' + STRING(uniqueValsFinal[0:9])
        ENDELSE
        
        ; 检查最终数据的有效性
        IF (maxValFinal GT (nClasses + 5)) OR (minValFinal LT -1) THEN BEGIN
          PRINT, '  警告: 最终数据值异常（范围: ' + STRING(minValFinal) + ' - ' + STRING(maxValFinal) + '）'
        ENDIF
        IF nonZeroCount LT (N_ELEMENTS(sampleData) * 0.01) THEN BEGIN
          PRINT, '  警告: 最终数据几乎全为零（非零像元 < 1%）'
        ENDIF
        
        ; 关闭验证用的raster对象
        validateRaster.Close
        validateRaster = !NULL
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        PRINT, '  警告: 无法打开文件进行验证'
        CATCH, /CANCEL
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 数据验证失败: ' + !ERROR_STATE.MSG
    ENDELSE
  ENDIF ELSE BEGIN
    PRINT, '错误: 输出文件不存在'
  ENDELSE
  PRINT, ''
  
  ; ============================================
  ; 7. 清理所有对象
  ; ============================================
  PRINT, '正在清理资源...'
  
  ; 关闭所有raster对象
  IF OBJ_VALID(inputRaster) THEN BEGIN
    inputRaster.Close
    inputRaster = !NULL
  ENDIF
  
  IF OBJ_VALID(smoothRaster) THEN BEGIN
    smoothRaster.Close
    smoothRaster = !NULL
  ENDIF
  
  IF OBJ_VALID(finalRaster) THEN BEGIN
    finalRaster.Close
    finalRaster = !NULL
  ENDIF
  
  ; 清理临时raster对象（如果存在）
  ; 注意：这些变量可能在某些执行路径中未定义，使用CATCH避免错误
  CATCH, errCleanTemp1
  IF errCleanTemp1 EQ 0 THEN BEGIN
    IF OBJ_VALID(tempRaster1) THEN BEGIN
      tempRaster1.Close
      tempRaster1 = !NULL
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE CATCH, /CANCEL
  
  CATCH, errCleanTemp2
  IF errCleanTemp2 EQ 0 THEN BEGIN
    IF OBJ_VALID(tempRaster2) THEN BEGIN
      tempRaster2.Close
      tempRaster2 = !NULL
    ENDIF
    CATCH, /CANCEL
  ENDIF ELSE CATCH, /CANCEL
  
  ; 清理ENVITask对象（如果存在）
  ; ENVITask对象通常会自动清理，但设置为!NULL有助于释放引用
  CATCH, errCleanTask1
  IF errCleanTask1 EQ 0 THEN BEGIN
    IF OBJ_VALID(smoothTask) THEN smoothTask = !NULL
    CATCH, /CANCEL
  ENDIF ELSE CATCH, /CANCEL
  
  CATCH, errCleanTask2
  IF errCleanTask2 EQ 0 THEN BEGIN
    IF OBJ_VALID(aggregateTask1) THEN aggregateTask1 = !NULL
    CATCH, /CANCEL
  ENDIF ELSE CATCH, /CANCEL
  
  CATCH, errCleanTask3
  IF errCleanTask3 EQ 0 THEN BEGIN
    IF OBJ_VALID(aggregateTask2) THEN aggregateTask2 = !NULL
    CATCH, /CANCEL
  ENDIF ELSE CATCH, /CANCEL
  
  ; 等待文件系统同步，确保所有文件操作完成
  WAIT, 1.0
  
  PRINT, '  ✓ 资源清理完成'
  PRINT, ''
  
  PRINT, '=========================================='
  PRINT, '后处理完成！'
  PRINT, '输出文件: ' + outputFile
  PRINT, '=========================================='
  
  ; 最后等待一下，确保所有操作完成
  WAIT, 0.5
  
END

