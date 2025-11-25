;+
; 程序名: 1125_kunming_gengdi.pro
; 功能: 昆明近十年耕地变化监测与分析 - 完整运行流程
;       整合数据预处理、监督分类、非监督分类等所有处理步骤
; 作者: Auto
; 日期: 2024-11-25
;-
PRO kunming_gengdi_main
  COMPILE_OPT IDL2
  
  ; 启动ENVI
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()
  
  PRINT, '================================================================================'
  PRINT, '昆明近十年耕地变化监测与分析 - 完整运行流程'
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '本程序整合了以下处理步骤：'
  PRINT, '  1. 数据预处理：批量堆叠Landsat数据'
  PRINT, '  2. 监督分类：随机森林分类（需要ROI标注）'
  PRINT, '  3. 非监督分类：ISODATA分类'
  PRINT, '  4. 结果分析：统计计算和报告生成'
  PRINT, ''
  PRINT, '================================================================================'
  PRINT, ''
  
  ; ============================================
  ; 设置路径
  ; ============================================
  basePath = 'F:\TestDemo\gengdi'
  PRINT, '项目根目录: ' + basePath
  PRINT, ''
  
  ; ============================================
  ; 显示菜单
  ; ============================================
  PRINT, '请选择要执行的处理步骤：'
  PRINT, '  1. 数据预处理（批量堆叠Landsat数据）'
  PRINT, '  2. 监督分类（随机森林，需要ROI标注）'
  PRINT, '  3. 非监督分类（ISODATA）'
  PRINT, '  4. 查看处理状态和结果'
  PRINT, '  5. 执行完整流程（1→2→3）'
  PRINT, '  6. 快速统计（显示耕地面积变化趋势）'
  PRINT, '  7. 数据验证（检查文件完整性）'
  PRINT, '  8. 帮助信息'
  PRINT, '  0. 退出'
  PRINT, ''
  
  ; 注意：在实际运行中，用户需要手动输入选择
  ; 这里提供默认选择（可以根据需要修改）
  defaultChoice = 4  ; 默认查看状态
  
  PRINT, '提示：请在ENVI命令行中手动输入选择（1-8），或修改代码中的defaultChoice变量'
  PRINT, '当前默认选择: ' + STRING(defaultChoice)
  PRINT, ''
  
  ; 根据选择执行相应操作
  choice = defaultChoice
  
  IF choice EQ 1 THEN BEGIN
    PRINT, '>>> 执行步骤1：数据预处理'
    PRINT, ''
    kunming_gengdi_step1_preprocess
  ENDIF ELSE IF choice EQ 2 THEN BEGIN
    PRINT, '>>> 执行步骤2：监督分类'
    PRINT, ''
    kunming_gengdi_step2_supervised
  ENDIF ELSE IF choice EQ 3 THEN BEGIN
    PRINT, '>>> 执行步骤3：非监督分类'
    PRINT, ''
    kunming_gengdi_step3_unsupervised
  ENDIF ELSE IF choice EQ 4 THEN BEGIN
    PRINT, '>>> 执行步骤4：查看处理状态'
    PRINT, ''
    kunming_gengdi_step4_status
  ENDIF ELSE IF choice EQ 5 THEN BEGIN
    PRINT, '>>> 执行完整流程（1→2→3）'
    PRINT, ''
    kunming_gengdi_full_workflow
  ENDIF ELSE IF choice EQ 6 THEN BEGIN
    PRINT, '>>> 执行步骤6：快速统计'
    PRINT, ''
    kunming_gengdi_step6_statistics
  ENDIF ELSE IF choice EQ 7 THEN BEGIN
    PRINT, '>>> 执行步骤7：数据验证'
    PRINT, ''
    kunming_gengdi_step7_validation
  ENDIF ELSE IF choice EQ 8 THEN BEGIN
    PRINT, '>>> 执行步骤8：帮助信息'
    PRINT, ''
    kunming_gengdi_step8_help
  ENDIF ELSE BEGIN
    PRINT, '已退出'
    RETURN
  ENDELSE
  
  PRINT, ''
  PRINT, '================================================================================'
  PRINT, '处理完成'
  PRINT, '================================================================================'
  
END

; ============================================
; 步骤1：数据预处理（批量堆叠Landsat数据）
; ============================================
PRO kunming_gengdi_step1_preprocess
  COMPILE_OPT IDL2
  
  PRINT, '步骤1：数据预处理 - 批量堆叠Landsat数据'
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '功能说明：'
  PRINT, '  - 批量处理Landsat 8/9 L2级数据'
  PRINT, '  - 从MTL XML文件读取空间参考信息'
  PRINT, '  - 打开并堆叠7个原始波段'
  PRINT, '  - 保存堆叠结果到 results_batch_roi 文件夹'
  PRINT, ''
  PRINT, '输入数据：'
  PRINT, '  - 原始Landsat数据文件夹（包含SR_B*.TIF文件）'
  PRINT, '  - MTL XML文件（包含空间参考信息）'
  PRINT, ''
  PRINT, '输出结果：'
  PRINT, '  - results_batch_roi/*_stacked.dat（堆叠后的多光谱影像）'
  PRINT, ''
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '请执行以下命令进行数据预处理：'
  PRINT, '  .compile -v ''F:\TestDemo\gengdi\1121_LandsatBatch.pro'''
  PRINT, '  landsatbatch'
  PRINT, ''
  PRINT, '或者对于2025年数据，执行：'
  PRINT, '  .compile -v ''F:\TestDemo\gengdi\1124_Landsat2025.pro'''
  PRINT, '  landsat2025'
  PRINT, ''
  
END

; ============================================
; 步骤2：监督分类（随机森林）
; ============================================
PRO kunming_gengdi_step2_supervised
  COMPILE_OPT IDL2
  
  PRINT, '步骤2：监督分类 - 随机森林分类'
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '功能说明：'
  PRINT, '  - 使用ROI样本进行随机森林监督分类'
  PRINT, '  - 分类类别：耕地、非耕地（2类）'
  PRINT, '  - 输入特征：7个原始波段 + 3种光谱指数（NDVI、NDWI、NDBI）'
  PRINT, '  - 后处理：分类平滑、聚合、元数据更新'
  PRINT, '  - 统计计算：各类别像素数量、占比、面积'
  PRINT, ''
  PRINT, '前置条件：'
  PRINT, '  1. 已完成数据预处理（步骤1）'
  PRINT, '  2. 已在ENVI中标注ROI，并保存到 ROIData 文件夹'
  PRINT, '     - ROI文件命名格式：YYYY.xml（如2014.xml）'
  PRINT, '     - ROI应包含两类：耕地、非耕地'
  PRINT, ''
  PRINT, '输入数据：'
  PRINT, '  - results_batch_roi/*_stacked.dat（堆叠后的多光谱影像）'
  PRINT, '  - ROIData/YYYY.xml（各年份的ROI标注文件）'
  PRINT, ''
  PRINT, '输出结果：'
  PRINT, '  - gengdi_results/classification_YYYY.dat（原始分类结果）'
  PRINT, '  - gengdi_results/classification_YYYY_final.dat（后处理结果）'
  PRINT, '  - gengdi_results/classification_statistics_YYYY.txt（统计报告）'
  PRINT, ''
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '请执行以下命令进行监督分类：'
  PRINT, '  .compile -v ''F:\TestDemo\gengdi\kunming_1124.pro'''
  PRINT, '  kunming_1124'
  PRINT, ''
  PRINT, '注意：'
  PRINT, '  - 代码中设置了resumeFromYear变量，可以从特定年份开始处理'
  PRINT, '  - 默认从2019年开始处理（之前的年份已处理过）'
  PRINT, '  - 如需修改，请编辑kunming_1124.pro中的resumeFromYear变量'
  PRINT, ''
  
END

; ============================================
; 步骤3：非监督分类（ISODATA）
; ============================================
PRO kunming_gengdi_step3_unsupervised
  COMPILE_OPT IDL2
  
  PRINT, '步骤3：非监督分类 - ISODATA分类'
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '功能说明：'
  PRINT, '  - 使用ISODATA非监督分类方法'
  PRINT, '  - 自动识别18个光谱类别'
  PRINT, '  - 优化参数：类别数18，迭代次数28，最小类别大小100像素'
  PRINT, '  - 适用于16GB内存服务器，充分利用计算资源'
  PRINT, '  - 输入特征：7个原始波段 + 3种光谱指数（NDVI、NDWI、NDBI）'
  PRINT, '  - 后处理：分类平滑、聚合、元数据更新'
  PRINT, '  - 统计计算：各类别像素数量、占比、面积'
  PRINT, ''
  PRINT, '前置条件：'
  PRINT, '  1. 已完成数据预处理（步骤1）'
  PRINT, '     - 或者有原始TIF文件（程序会自动堆叠）'
  PRINT, ''
  PRINT, '输入数据：'
  PRINT, '  - D:\IDL\1124\*_stacked.dat（堆叠后的多光谱影像）'
  PRINT, '  - 或者：D:\IDL\1124\LC08_*\SR_B*.TIF（原始TIF文件，自动堆叠）'
  PRINT, ''
  PRINT, '输出结果：'
  PRINT, '  - D:\IDL\1124\ResultData\isodata_classification_YYYY.dat（原始分类结果）'
  PRINT, '  - D:\IDL\1124\ResultData\isodata_classification_YYYY_final.dat（后处理结果）'
  PRINT, '  - D:\IDL\1124\ResultData\classification_statistics_YYYY.txt（统计报告）'
  PRINT, ''
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '请执行以下命令进行非监督分类：'
  PRINT, '  .compile -v ''D:\IDL\1124\gengdi_1125.pro'''
  PRINT, '  gengdi_1125'
  PRINT, ''
  PRINT, '注意：'
  PRINT, '  - 非监督分类不需要ROI标注'
  PRINT, '  - 处理时间较长（每个年份可能需要30-90分钟）'
  PRINT, '  - 如果堆叠文件不存在，程序会自动从原始TIF文件堆叠'
  PRINT, ''
  
END

; ============================================
; 步骤4：查看处理状态和结果
; ============================================
PRO kunming_gengdi_step4_status
  COMPILE_OPT IDL2
  
  PRINT, '步骤4：查看处理状态和结果'
  PRINT, '================================================================================'
  PRINT, ''
  
  basePath = 'F:\TestDemo\gengdi'
  stackedDataPath = basePath + PATH_SEP() + 'results_batch_roi'
  roiDataPath = basePath + PATH_SEP() + 'ROIData'
  supervisedOutputDir = basePath + PATH_SEP() + 'gengdi_results'
  unsupervisedOutputDir = 'D:\IDL\1124\ResultData'
  
  ; 定义年份数据
  yearData = [$
    {year:'2014', stackedFile:'LC08_L2SP_129042_20140101_20200912_02_T1_stacked.dat'}, $
    {year:'2015', stackedFile:'LC08_L2SP_129042_20150104_20200910_02_T1_stacked.dat'}, $
    {year:'2016', stackedFile:'LC08_L2SP_129042_20161208_20200905_02_T1_stacked.dat'}, $
    {year:'2017', stackedFile:'LC08_L2SP_129042_20170314_20200904_02_T1_stacked.dat'}, $
    {year:'2019', stackedFile:'LC08_L2SP_129042_20190320_20200829_02_T1_stacked.dat'}, $
    {year:'2020', stackedFile:'LC08_L2SP_129042_20200509_20200820_02_T1_stacked.dat'}, $
    {year:'2021', stackedFile:'LC08_L2SP_129042_20211104_20211109_02_T1_stacked.dat'}, $
    {year:'2022', stackedFile:'LC08_L2SP_129042_20220123_20220128_02_T1_stacked.dat'}, $
    {year:'2023', stackedFile:'LC08_L2SP_129042_20230126_20230208_02_T1_stacked.dat'}, $
    {year:'2024', stackedFile:'LC09_L2SP_129042_20240410_20240411_02_T1_stacked.dat'}, $
    {year:'2025', stackedFile:'LC08_L2SP_129043_20250507_20250513_02_T1_stacked.dat'} $
  ]
  
  nYears = N_ELEMENTS(yearData)
  
  ; 检查数据预处理状态
  PRINT, '1. 数据预处理状态（堆叠影像）：'
  PRINT, '  路径: ' + stackedDataPath
  PRINT, '  ----------------------------------------------------------------------------'
  stackedCount = 0
  FOR yearIdx = 0, nYears - 1 DO BEGIN
    currentYear = yearData[yearIdx].year
    stackedFileName = yearData[yearIdx].stackedFile
    stackedFile = stackedDataPath + PATH_SEP() + stackedFileName
    IF FILE_TEST(stackedFile) THEN BEGIN
      PRINT, '  ✓ ' + currentYear + '年: ' + FILE_BASENAME(stackedFile)
      stackedCount++
    ENDIF ELSE BEGIN
      PRINT, '  ✗ ' + currentYear + '年: 缺失'
    ENDELSE
  ENDFOR
  PRINT, '  总计: ' + STRING(stackedCount) + '/' + STRING(nYears) + ' 个年份已完成堆叠'
  PRINT, ''
  
  ; 检查ROI标注状态
  PRINT, '2. ROI标注状态：'
  PRINT, '  路径: ' + roiDataPath
  PRINT, '  ----------------------------------------------------------------------------'
  roiCount = 0
  FOR yearIdx = 0, nYears - 1 DO BEGIN
    currentYear = yearData[yearIdx].year
    roiFile = roiDataPath + PATH_SEP() + currentYear + '.xml'
    IF FILE_TEST(roiFile) THEN BEGIN
      PRINT, '  ✓ ' + currentYear + '年: ' + FILE_BASENAME(roiFile)
      roiCount++
    ENDIF ELSE BEGIN
      PRINT, '  ✗ ' + currentYear + '年: 缺失'
    ENDELSE
  ENDFOR
  PRINT, '  总计: ' + STRING(roiCount) + '/' + STRING(nYears) + ' 个年份已标注ROI'
  PRINT, ''
  
  ; 检查监督分类结果
  PRINT, '3. 监督分类结果状态：'
  PRINT, '  路径: ' + supervisedOutputDir
  PRINT, '  ----------------------------------------------------------------------------'
  supervisedCount = 0
  FOR yearIdx = 0, nYears - 1 DO BEGIN
    currentYear = yearData[yearIdx].year
    finalFile = supervisedOutputDir + PATH_SEP() + 'classification_' + currentYear + '_final.dat'
    statsFile = supervisedOutputDir + PATH_SEP() + 'classification_statistics_' + currentYear + '.txt'
    IF FILE_TEST(finalFile) AND FILE_TEST(statsFile) THEN BEGIN
      PRINT, '  ✓ ' + currentYear + '年: 完成（分类结果 + 统计报告）'
      supervisedCount++
    ENDIF ELSE IF FILE_TEST(finalFile) THEN BEGIN
      PRINT, '  ⚠ ' + currentYear + '年: 分类结果存在，但统计报告缺失'
    ENDIF ELSE BEGIN
      PRINT, '  ✗ ' + currentYear + '年: 未处理'
    ENDELSE
  ENDFOR
  PRINT, '  总计: ' + STRING(supervisedCount) + '/' + STRING(nYears) + ' 个年份已完成监督分类'
  PRINT, ''
  
  ; 检查非监督分类结果
  PRINT, '4. 非监督分类结果状态：'
  PRINT, '  路径: ' + unsupervisedOutputDir
  PRINT, '  ----------------------------------------------------------------------------'
  unsupervisedCount = 0
  FOR yearIdx = 0, nYears - 1 DO BEGIN
    currentYear = yearData[yearIdx].year
    finalFile = unsupervisedOutputDir + PATH_SEP() + 'isodata_classification_' + currentYear + '_final.dat'
    statsFile = unsupervisedOutputDir + PATH_SEP() + 'classification_statistics_' + currentYear + '.txt'
    IF FILE_TEST(finalFile) AND FILE_TEST(statsFile) THEN BEGIN
      PRINT, '  ✓ ' + currentYear + '年: 完成（分类结果 + 统计报告）'
      unsupervisedCount++
    ENDIF ELSE IF FILE_TEST(finalFile) THEN BEGIN
      PRINT, '  ⚠ ' + currentYear + '年: 分类结果存在，但统计报告缺失'
    ENDIF ELSE BEGIN
      PRINT, '  ✗ ' + currentYear + '年: 未处理'
    ENDELSE
  ENDFOR
  PRINT, '  总计: ' + STRING(unsupervisedCount) + '/' + STRING(nYears) + ' 个年份已完成非监督分类'
  PRINT, ''
  
  ; 总结
  PRINT, '================================================================================'
  PRINT, '处理状态总结：'
  PRINT, '  - 数据预处理: ' + STRING(stackedCount) + '/' + STRING(nYears) + ' 完成'
  PRINT, '  - ROI标注: ' + STRING(roiCount) + '/' + STRING(nYears) + ' 完成'
  PRINT, '  - 监督分类: ' + STRING(supervisedCount) + '/' + STRING(nYears) + ' 完成'
  PRINT, '  - 非监督分类: ' + STRING(unsupervisedCount) + '/' + STRING(nYears) + ' 完成'
  PRINT, '================================================================================'
  PRINT, ''
  
  ; 提供下一步建议
  PRINT, '下一步建议：'
  IF stackedCount LT nYears THEN BEGIN
    PRINT, '  → 执行步骤1：数据预处理（' + STRING(nYears - stackedCount) + ' 个年份待处理）'
  ENDIF
  IF (stackedCount EQ nYears) AND (roiCount LT nYears) THEN BEGIN
    PRINT, '  → 标注ROI（' + STRING(nYears - roiCount) + ' 个年份待标注）'
  ENDIF
  IF (stackedCount EQ nYears) AND (roiCount EQ nYears) AND (supervisedCount LT nYears) THEN BEGIN
    PRINT, '  → 执行步骤2：监督分类（' + STRING(nYears - supervisedCount) + ' 个年份待处理）'
  ENDIF
  IF (stackedCount EQ nYears) AND (unsupervisedCount LT nYears) THEN BEGIN
    PRINT, '  → 执行步骤3：非监督分类（' + STRING(nYears - unsupervisedCount) + ' 个年份待处理）'
  ENDIF
  IF (supervisedCount EQ nYears) AND (unsupervisedCount EQ nYears) THEN BEGIN
    PRINT, '  → 所有处理已完成！可以查看分析报告：1125.txt'
  ENDIF
  PRINT, ''
  
END

; ============================================
; 完整工作流程（1→2→3）
; ============================================
PRO kunming_gengdi_full_workflow
  COMPILE_OPT IDL2
  
  PRINT, '完整工作流程：数据预处理 → 监督分类 → 非监督分类'
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '本流程将依次执行以下步骤：'
  PRINT, '  1. 数据预处理（批量堆叠Landsat数据）'
  PRINT, '  2. 监督分类（随机森林，需要ROI标注）'
  PRINT, '  3. 非监督分类（ISODATA）'
  PRINT, ''
  PRINT, '注意：'
  PRINT, '  - 步骤1和步骤3可以自动执行'
  PRINT, '  - 步骤2需要先完成ROI标注（在ENVI中手动标注）'
  PRINT, '  - 建议先查看处理状态（步骤4），确认前置条件是否满足'
  PRINT, ''
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '请按照以下顺序执行：'
  PRINT, ''
  PRINT, '【步骤1】数据预处理'
  PRINT, '  .compile -v ''F:\TestDemo\gengdi\1121_LandsatBatch.pro'''
  PRINT, '  landsatbatch'
  PRINT, ''
  PRINT, '【步骤2】ROI标注（在ENVI中手动完成）'
  PRINT, '  1. 打开堆叠后的影像'
  PRINT, '  2. 使用ROI工具标注耕地和非耕地区域'
  PRINT, '  3. 保存ROI文件到 ROIData 文件夹（命名格式：YYYY.xml）'
  PRINT, ''
  PRINT, '【步骤3】监督分类'
  PRINT, '  .compile -v ''F:\TestDemo\gengdi\kunming_1124.pro'''
  PRINT, '  kunming_1124'
  PRINT, ''
  PRINT, '【步骤4】非监督分类'
  PRINT, '  .compile -v ''D:\IDL\1124\gengdi_1125.pro'''
  PRINT, '  gengdi_1125'
  PRINT, ''
  PRINT, '【步骤5】查看结果'
  PRINT, '  kunming_gengdi_step4_status'
  PRINT, ''
  PRINT, '【步骤6】分析报告'
  PRINT, '  查看文件：1125.txt（耕地变化与驱动力分析报告）'
  PRINT, ''
  
END

; ============================================
; 步骤6：快速统计（显示耕地面积变化趋势）
; ============================================
PRO kunming_gengdi_step6_statistics
  COMPILE_OPT IDL2
  
  PRINT, '步骤6：快速统计 - 耕地面积变化趋势'
  PRINT, '================================================================================'
  PRINT, ''
  
  basePath = 'F:\TestDemo\gengdi'
  supervisedOutputDir = basePath + PATH_SEP() + 'gengdi_results'
  
  ; 定义年份数据
  yearData = [$
    {year:'2014'}, {year:'2015'}, {year:'2016'}, {year:'2017'}, $
    {year:'2019'}, {year:'2020'}, {year:'2021'}, {year:'2022'}, $
    {year:'2023'}, {year:'2024'}, {year:'2025'} $
  ]
  
  nYears = N_ELEMENTS(yearData)
  
  ; 读取统计文件
  PRINT, '正在读取监督分类统计结果...'
  PRINT, ''
  
  ; 存储统计结果
  statsData = []
  validCount = 0
  
  FOR yearIdx = 0, nYears - 1 DO BEGIN
    currentYear = yearData[yearIdx]
    statsFile = supervisedOutputDir + PATH_SEP() + 'classification_statistics_' + currentYear + '.txt'
    
    IF FILE_TEST(statsFile) THEN BEGIN
      ; 读取统计文件
      CATCH, errRead
      IF errRead EQ 0 THEN BEGIN
        OPENR, lun, statsFile, /GET_LUN
        lines = STRARR(100)
        lineCount = 0
        WHILE ~EOF(lun) && lineCount LT 100 DO BEGIN
          READF, lun, lines[lineCount]
          lineCount++
        ENDWHILE
        CLOSE, lun
        FREE_LUN, lun
        lines = lines[0:lineCount-1]
        CATCH, /CANCEL
        
        ; 解析统计文件，查找耕地面积（类别2）
        cultivatedArea = 0.0
        foundClass2 = 0
        
        FOR i=0, lineCount-1 DO BEGIN
          line = lines[i]
          ; 查找"类别        2"这一行（耕地类别）
          IF STRPOS(line, '类别        2') GE 0 THEN BEGIN
            foundClass2 = 1
            ; 查找该行或下一行的面积信息
            ; 先检查当前行
            areaPos = STRPOS(line, '面积:')
            IF areaPos GE 0 THEN BEGIN
              areaStr = STRMID(line, areaPos + 5)
              areaStr = STRTRIM(areaStr, 2)
              ; 提取数字部分（到第一个空格或"公顷"之前）
              spacePos = STRPOS(areaStr, ' ')
              IF spacePos GT 0 THEN BEGIN
                areaNumStr = STRMID(areaStr, 0, spacePos)
                cultivatedArea = FLOAT(STRTRIM(areaNumStr, 2))
              ENDIF
            ENDIF ELSE BEGIN
              ; 如果当前行没有面积信息，检查下一行
              IF i+1 LT lineCount THEN BEGIN
                nextLine = lines[i+1]
                areaPos = STRPOS(nextLine, '面积:')
                IF areaPos GE 0 THEN BEGIN
                  areaStr = STRMID(nextLine, areaPos + 5)
                  areaStr = STRTRIM(areaStr, 2)
                  spacePos = STRPOS(areaStr, ' ')
                  IF spacePos GT 0 THEN BEGIN
                    areaNumStr = STRMID(areaStr, 0, spacePos)
                    cultivatedArea = FLOAT(STRTRIM(areaNumStr, 2))
                  ENDIF
                ENDIF
              ENDIF
            ENDELSE
            BREAK  ; 找到类别2后退出循环
          ENDIF
        ENDFOR
        
        ; 如果没找到类别2，尝试查找包含"耕地"的行（备用方法）
        IF (foundClass2 EQ 0) OR (cultivatedArea EQ 0.0) THEN BEGIN
          FOR i=0, lineCount-1 DO BEGIN
            line = lines[i]
            IF STRPOS(STRUPCASE(line), '耕地') GE 0 THEN BEGIN
              areaPos = STRPOS(line, '面积:')
              IF areaPos GE 0 THEN BEGIN
                areaStr = STRMID(line, areaPos + 5)
                areaStr = STRTRIM(areaStr, 2)
                spacePos = STRPOS(areaStr, ' ')
                IF spacePos GT 0 THEN BEGIN
                  areaNumStr = STRMID(areaStr, 0, spacePos)
                  cultivatedArea = FLOAT(STRTRIM(areaNumStr, 2))
                  BREAK
                ENDIF
              ENDIF
            ENDIF
          ENDFOR
        ENDIF
        
        IF cultivatedArea GT 0 THEN BEGIN
          statInfo = {year:currentYear, areaHa:cultivatedArea, areaKm2:cultivatedArea/100.0}
          statsData = [statsData, statInfo]
          validCount++
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF
  ENDFOR
  
  ; 显示统计结果
  IF validCount GT 0 THEN BEGIN
    ; 按年份排序（确保按时间顺序显示）
    ; 创建年份索引数组用于排序
    yearValues = INTARR(N_ELEMENTS(statsData))
    FOR i=0, N_ELEMENTS(statsData)-1 DO BEGIN
      yearValues[i] = FIX(statsData[i].year)
    ENDFOR
    sortedIndices = SORT(yearValues)
    
    PRINT, '耕地面积变化趋势（监督分类结果）：'
    PRINT, '================================================================================'
    PRINT, '年份    耕地面积（公顷）    耕地面积（平方公里）'
    PRINT, '----------------------------------------------------------------------------'
    
    FOR i=0, N_ELEMENTS(sortedIndices)-1 DO BEGIN
      idx = sortedIndices[i]
      stat = statsData[idx]
      PRINT, STRING(stat.year, FORMAT='(A4)') + '    ' + $
             STRING(stat.areaHa, FORMAT='(F12.2)') + '        ' + $
             STRING(stat.areaKm2, FORMAT='(F10.2)'))
    ENDFOR
    
    PRINT, '================================================================================'
    PRINT, ''
    
    ; 计算变化趋势（使用排序后的数据）
    IF N_ELEMENTS(statsData) GE 2 THEN BEGIN
      firstIdx = sortedIndices[0]
      lastIdx = sortedIndices[N_ELEMENTS(sortedIndices)-1]
      firstArea = statsData[firstIdx].areaHa
      lastArea = statsData[lastIdx].areaHa
      totalChange = lastArea - firstArea
      IF firstArea GT 0 THEN BEGIN
        changePercent = (totalChange / firstArea) * 100.0
      ENDIF ELSE BEGIN
        changePercent = 0.0
      ENDELSE
      
      PRINT, '变化趋势分析：'
      PRINT, '  起始年份（' + statsData[firstIdx].year + '）: ' + STRING(firstArea, FORMAT='(F12.2)') + ' 公顷'
      PRINT, '  结束年份（' + statsData[lastIdx].year + '）: ' + STRING(lastArea, FORMAT='(F12.2)') + ' 公顷'
      PRINT, '  总变化: ' + STRING(totalChange, FORMAT='(F12.2)') + ' 公顷 (' + STRING(changePercent, FORMAT='(F8.2)') + '%)'
      IF totalChange GT 0 THEN BEGIN
        PRINT, '  趋势: 增加'
      ENDIF ELSE IF totalChange LT 0 THEN BEGIN
        PRINT, '  趋势: 减少'
      ENDIF ELSE BEGIN
        PRINT, '  趋势: 基本稳定'
      ENDELSE
      PRINT, ''
      
      ; 找出最大值和最小值
      maxArea = statsData[sortedIndices[0]].areaHa
      minArea = statsData[sortedIndices[0]].areaHa
      maxYear = statsData[sortedIndices[0]].year
      minYear = statsData[sortedIndices[0]].year
      
      FOR i=1, N_ELEMENTS(sortedIndices)-1 DO BEGIN
        idx = sortedIndices[i]
        IF statsData[idx].areaHa GT maxArea THEN BEGIN
          maxArea = statsData[idx].areaHa
          maxYear = statsData[idx].year
        ENDIF
        IF statsData[idx].areaHa LT minArea THEN BEGIN
          minArea = statsData[idx].areaHa
          minYear = statsData[idx].year
        ENDIF
      ENDFOR
      
      PRINT, '极值分析：'
      PRINT, '  最大面积: ' + STRING(maxArea, FORMAT='(F12.2)') + ' 公顷（' + maxYear + '年）'
      PRINT, '  最小面积: ' + STRING(minArea, FORMAT='(F12.2)') + ' 公顷（' + minYear + '年）'
      PRINT, '  变化幅度: ' + STRING(maxArea - minArea, FORMAT='(F12.2)') + ' 公顷'
      PRINT, ''
    ENDIF
  ENDIF ELSE BEGIN
    PRINT, '警告: 未找到有效的统计文件'
    PRINT, '请先执行监督分类（步骤2）'
    PRINT, ''
  ENDELSE
  
END

; ============================================
; 步骤7：数据验证（检查文件完整性）
; ============================================
PRO kunming_gengdi_step7_validation
  COMPILE_OPT IDL2
  
  PRINT, '步骤7：数据验证 - 检查文件完整性'
  PRINT, '================================================================================'
  PRINT, ''
  
  basePath = 'F:\TestDemo\gengdi'
  stackedDataPath = basePath + PATH_SEP() + 'results_batch_roi'
  supervisedOutputDir = basePath + PATH_SEP() + 'gengdi_results'
  
  ; 定义年份数据
  yearData = [$
    {year:'2014', stackedFile:'LC08_L2SP_129042_20140101_20200912_02_T1_stacked.dat'}, $
    {year:'2015', stackedFile:'LC08_L2SP_129042_20150104_20200910_02_T1_stacked.dat'}, $
    {year:'2016', stackedFile:'LC08_L2SP_129042_20161208_20200905_02_T1_stacked.dat'}, $
    {year:'2017', stackedFile:'LC08_L2SP_129042_20170314_20200904_02_T1_stacked.dat'}, $
    {year:'2019', stackedFile:'LC08_L2SP_129042_20190320_20200829_02_T1_stacked.dat'}, $
    {year:'2020', stackedFile:'LC08_L2SP_129042_20200509_20200820_02_T1_stacked.dat'}, $
    {year:'2021', stackedFile:'LC08_L2SP_129042_20211104_20211109_02_T1_stacked.dat'}, $
    {year:'2022', stackedFile:'LC08_L2SP_129042_20220123_20220128_02_T1_stacked.dat'}, $
    {year:'2023', stackedFile:'LC08_L2SP_129042_20230126_20230208_02_T1_stacked.dat'}, $
    {year:'2024', stackedFile:'LC09_L2SP_129042_20240410_20240411_02_T1_stacked.dat'}, $
    {year:'2025', stackedFile:'LC08_L2SP_129043_20250507_20250513_02_T1_stacked.dat'} $
  ]
  
  nYears = N_ELEMENTS(yearData)
  
  PRINT, '正在验证文件完整性...'
  PRINT, ''
  
  ; 验证堆叠文件
  PRINT, '1. 验证堆叠影像文件：'
  PRINT, '  ----------------------------------------------------------------------------'
  validStackedCount = 0
  totalStackedSize = 0L
  
  FOR yearIdx = 0, nYears - 1 DO BEGIN
    currentYear = yearData[yearIdx].year
    stackedFile = stackedDataPath + PATH_SEP() + yearData[yearIdx].stackedFile
    hdrFile = FILE_DIRNAME(stackedFile) + PATH_SEP() + FILE_BASENAME(stackedFile, '.dat') + '.hdr'
    
    IF FILE_TEST(stackedFile) THEN BEGIN
      fileSize = FILE_INFO(stackedFile).size
      totalStackedSize = totalStackedSize + fileSize
      fileSizeMB = FLOAT(fileSize) / (1024.0 * 1024.0)
      
      IF FILE_TEST(hdrFile) THEN BEGIN
        PRINT, '  ✓ ' + currentYear + '年: ' + FILE_BASENAME(stackedFile) + ' (' + STRING(fileSizeMB, FORMAT='(F8.1)') + ' MB)'
        validStackedCount++
      ENDIF ELSE BEGIN
        PRINT, '  ⚠ ' + currentYear + '年: 数据文件存在，但头文件缺失'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '  ✗ ' + currentYear + '年: 文件缺失'
    ENDELSE
  ENDFOR
  
  PRINT, '  总计: ' + STRING(validStackedCount) + '/' + STRING(nYears) + ' 个文件完整'
  PRINT, '  总大小: ' + STRING(FLOAT(totalStackedSize) / (1024.0 * 1024.0 * 1024.0), FORMAT='(F6.2)') + ' GB'
  PRINT, ''
  
  ; 验证监督分类结果
  PRINT, '2. 验证监督分类结果文件：'
  PRINT, '  ----------------------------------------------------------------------------'
  validSupervisedCount = 0
  totalSupervisedSize = 0L
  
  FOR yearIdx = 0, nYears - 1 DO BEGIN
    currentYear = yearData[yearIdx].year
    finalFile = supervisedOutputDir + PATH_SEP() + 'classification_' + currentYear + '_final.dat'
    statsFile = supervisedOutputDir + PATH_SEP() + 'classification_statistics_' + currentYear + '.txt'
    
    IF FILE_TEST(finalFile) AND FILE_TEST(statsFile) THEN BEGIN
      fileSize = FILE_INFO(finalFile).size
      totalSupervisedSize = totalSupervisedSize + fileSize
      fileSizeMB = FLOAT(fileSize) / (1024.0 * 1024.0)
      PRINT, '  ✓ ' + currentYear + '年: 完整（' + STRING(fileSizeMB, FORMAT='(F8.1)') + ' MB）'
      validSupervisedCount++
    ENDIF ELSE BEGIN
      PRINT, '  ✗ ' + currentYear + '年: 文件不完整'
    ENDELSE
  ENDFOR
  
  PRINT, '  总计: ' + STRING(validSupervisedCount) + '/' + STRING(nYears) + ' 个文件完整'
  PRINT, '  总大小: ' + STRING(FLOAT(totalSupervisedSize) / (1024.0 * 1024.0 * 1024.0), FORMAT='(F6.2)') + ' GB'
  PRINT, ''
  
  ; 总结
  PRINT, '================================================================================'
  PRINT, '验证结果总结：'
  PRINT, '  - 堆叠影像: ' + STRING(validStackedCount) + '/' + STRING(nYears) + ' 完整'
  PRINT, '  - 监督分类结果: ' + STRING(validSupervisedCount) + '/' + STRING(nYears) + ' 完整'
  PRINT, '================================================================================'
  PRINT, ''
  
END

; ============================================
; 步骤8：帮助信息
; ============================================
PRO kunming_gengdi_step8_help
  COMPILE_OPT IDL2
  
  PRINT, '步骤8：帮助信息'
  PRINT, '================================================================================'
  PRINT, ''
  PRINT, '项目概述：'
  PRINT, '  本项目基于Landsat 8/9卫星遥感影像数据，采用监督分类和非监督分类两种方法，'
  PRINT, '  对昆明市及其周边地区2014-2025年（共11年）的耕地变化进行监测与分析。'
  PRINT, ''
  PRINT, '主要功能：'
  PRINT, '  1. 数据预处理：批量堆叠Landsat数据，添加空间参考信息'
  PRINT, '  2. 监督分类：使用随机森林方法，基于ROI样本进行分类'
  PRINT, '  3. 非监督分类：使用ISODATA方法，自动识别18个光谱类别'
  PRINT, '  4. 结果分析：统计计算、变化趋势分析、驱动力分析'
  PRINT, ''
  PRINT, '文件结构：'
  PRINT, '  - 代码文件: *.pro（IDL程序文件）'
  PRINT, '  - 原始数据: LC08_* 或 LC09_* 文件夹'
  PRINT, '  - 堆叠结果: results_batch_roi/*_stacked.dat'
  PRINT, '  - ROI标注: ROIData/YYYY.xml'
  PRINT, '  - 监督分类结果: gengdi_results/classification_*'
  PRINT, '  - 非监督分类结果: D:\IDL\1124\ResultData\isodata_classification_*'
  PRINT, '  - 分析报告: 1125.txt'
  PRINT, ''
  PRINT, '使用流程：'
  PRINT, '  1. 数据预处理：执行 1121_LandsatBatch.pro'
  PRINT, '  2. ROI标注：在ENVI中手动标注耕地和非耕地区域'
  PRINT, '  3. 监督分类：执行 kunming_1124.pro'
  PRINT, '  4. 非监督分类：执行 gengdi_1125.pro'
  PRINT, '  5. 查看结果：使用本程序的步骤4查看处理状态'
  PRINT, '  6. 统计分析：使用本程序的步骤6查看耕地面积变化趋势'
  PRINT, ''
  PRINT, '注意事项：'
  PRINT, '  - 确保ENVI和IDL已正确安装和配置'
  PRINT, '  - 路径设置：根据实际情况修改代码中的路径变量'
  PRINT, '  - ROI文件命名：必须为YYYY.xml格式（如2014.xml）'
  PRINT, '  - 内存要求：非监督分类建议16GB以上内存'
  PRINT, '  - 处理时间：每个年份可能需要30-90分钟'
  PRINT, ''
  PRINT, '技术支持：'
  PRINT, '  - 查看详细文档：1125_昆明近十年耕地变化尝试.md'
  PRINT, '  - 查看分析报告：1125.txt'
  PRINT, '  - 代码参考：各.pro文件中的注释说明'
  PRINT, ''
  PRINT, '================================================================================'
  PRINT, ''
  
END

; ============================================
; 主程序入口（简化版，直接调用主函数）
; ============================================
PRO kunming_gengdi
  COMPILE_OPT IDL2
  kunming_gengdi_main
END
