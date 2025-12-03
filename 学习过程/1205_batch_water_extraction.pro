;+
; 程序�? 1205_batch_water_extraction.pro
; 功能: 批量计算Landsat L2数据的水体提�?
; 输入: Landsat L2 MTL文件（Surface Reflectance数据）所在的文件�?
; 输出: 水体提取结果（栅格和矢量，保存到指定输出目录�?
; 作�? Auto
; 日期: 2024-12
; 依赖: spatial_ref_utils.pro (空间参考处理函数)�?
;-

; 编译依赖文件
@spatial_ref_utils

PRO batch_water_extraction

  COMPILE_OPT IDL2

  ; 启动ENVI
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()

  ; 编译水体提取任务文件（直接尝试编译，不检查文件是否存在）
  ; 构建可能的文件路径
  waterExtractionFile = ''
  currentDir = ROUTINE_DIR()
  IF STRLEN(currentDir) GT 0 THEN BEGIN
    ; 确保路径以 PATH_SEP() 结尾
    IF STRMID(currentDir, STRLEN(currentDir)-1) NE PATH_SEP() THEN BEGIN
      waterExtractionFile = currentDir + PATH_SEP() + 'test_ENVIWaterExtractionTask.pro'
    ENDIF ELSE BEGIN
      waterExtractionFile = currentDir + 'test_ENVIWaterExtractionTask.pro'
    ENDELSE
  ENDIF
  
  ; 如果 ROUTINE_DIR() 失败，使用 ROUTINE_FILEPATH()
  IF (STRLEN(waterExtractionFile) EQ 0) THEN BEGIN
    routinePath = ROUTINE_FILEPATH()
    IF STRLEN(routinePath) GT 0 THEN BEGIN
      fileDir = FILE_DIRNAME(routinePath)
      waterExtractionFile = fileDir + PATH_SEP() + 'test_ENVIWaterExtractionTask.pro'
    ENDIF
  ENDIF
  
  ; 如果还是空，使用服务器路径
  IF (STRLEN(waterExtractionFile) EQ 0) THEN BEGIN
    waterExtractionFile = 'D:\IDL\test_1205_WaterExtractionBatch\test_ENVIWaterExtractionTask.pro'
  ENDIF
  
  ; 直接尝试编译（不检查文件是否存在，让 COMPILE 自己处理）
  CATCH, errCompile
  IF errCompile EQ 0 THEN BEGIN
    COMPILE, waterExtractionFile
    CATCH, /CANCEL
    PRINT, '已编译水体提取任务文件: ', waterExtractionFile
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    ; 编译失败，提示用户手动编译
    PRINT, '警告: 无法编译 test_ENVIWaterExtractionTask.pro'
    PRINT, '尝试的路径: ', waterExtractionFile
    PRINT, '请手动编译: .compile ''', waterExtractionFile, ''''
  ENDELSE

  ; 水体提取任务文件已在文件开头通过 @test_ENVIWaterExtractionTask 包含并编译

  PRINT, '=========================================='
  PRINT, 'Landsat L2 水体提取批量处理工具'
  PRINT, '=========================================='
  PRINT, ''

  ; 步骤1：选择输入文件夹（包含多个Landsat L2数据文件夹）
  PRINT, '步骤1：选择输入文件夹（包含Landsat L2数据�?..'
  input_dir = ENVI_PICKFILE(/DIRECTORY, TITLE='请选择包含Landsat L2数据的文件夹')
  IF input_dir EQ '' THEN BEGIN
    PRINT, '未选择输入文件夹，退出�?
    RETURN
  ENDIF
  PRINT, '输入目录: ', input_dir
  PRINT, ''

  ; 步骤2：选择输出目录和格�?
  PRINT, '步骤2：选择输出目录和格�?..'
  outdir = ENVI_PICKFILE(/OUTPUT, /DIRECTORY, TITLE='请选择输出目录')
  IF outdir EQ '' THEN BEGIN
    PRINT, '未选择输出目录，退出�?
    RETURN
  ENDIF
  PRINT, '输出目录: ', outdir
  PRINT, ''

  ; 选择输出格式
  PRINT, '请选择输出格式�?
  PRINT, '  点击"Yes" = TIFF格式 (.tif)'
  PRINT, '  点击"No"  = ENVI格式 (.dat)'
  PRINT, ''
  format_msg = 'Select Output Format:' + STRING(10B) + STRING(10B) + $
    'Click "Yes" for TIFF format (.tif)' + STRING(10B) + $
    'Click "No"  for ENVI format (.dat)'
  format_result = DIALOG_MESSAGE(format_msg, TITLE='Output Format', /QUESTION)

  IF STRUPCASE(format_result) EQ 'YES' THEN BEGIN
    output_format = '.tif'
    PRINT, '已选择: TIFF格式 (.tif)'
  ENDIF ELSE BEGIN
    output_format = '.dat'
    PRINT, '已选择: ENVI格式 (.dat)'
  ENDELSE
  PRINT, ''

  ; 步骤3：设置水体提取参�?
  PRINT, '步骤3：设置水体提取参�?..'
  PRINT, '使用默认参数:'
  PRINT, '  是否应用QUAC: �?
  PRINT, '  阈�? 0.0'
  PRINT, '  平滑大小: 5'
  PRINT, '  最小面�? 0.05 km²'
  PRINT, ''
  PRINT, '提示: 如需修改参数，请编辑代码中的参数变量'
  PRINT, ''

  ; 参数设置
  Apply_QUAC = 0
  thresholdValue = 0.0
  smoothSize = 5
  minArea = 0.05

  ; 步骤4：查找所有XML文件（MTL文件�?
  PRINT, '步骤4：正在搜索XML文件（MTL文件�?..'
  xml_files = search_files_recursive(input_dir, '*_MTL.xml')
  IF xml_files NE !NULL THEN BEGIN
    xml_count = N_ELEMENTS(xml_files)
  ENDIF ELSE BEGIN
    xml_count = 0
  ENDELSE
  
  ; 如果没找到XML，尝试查找TXT格式的MTL文件
  IF xml_count EQ 0 THEN BEGIN
    PRINT, '未找到XML格式的MTL文件，尝试查找TXT格式...'
    txt_files = search_files_recursive(input_dir, '*_MTL.txt')
    IF txt_files NE !NULL THEN BEGIN
      txt_count = N_ELEMENTS(txt_files)
    ENDIF ELSE BEGIN
      txt_count = 0
    ENDELSE
    IF txt_count GT 0 THEN BEGIN
      ; 将TXT文件也加入处理列�?
      all_files = txt_files
      xml_count = txt_count
      PRINT, '找到 ', txt_count, ' 个TXT格式的MTL文件'
    ENDIF ELSE BEGIN
      PRINT, '未找到任何MTL文件，退出�?
      RETURN
    ENDELSE
  ENDIF ELSE BEGIN
    all_files = xml_files
    PRINT, '找到 ', xml_count, ' 个XML格式的MTL文件'
  ENDELSE

  IF xml_count EQ 0 THEN BEGIN
    PRINT, '未找到任何MTL文件，退出�?
    RETURN
  ENDIF

  PRINT, ''

  ; 步骤5：批量处理所有文�?
  PRINT, '步骤5：开始批量处�?..'
  PRINT, '=========================================='

  DataColl = e.DATA  ; Data Manager
  errMsgs = !NULL    ; 记录错误信息
  success_count = 0

  FOR i=0, xml_count-1 DO BEGIN
    mtl_file = all_files[i]
    PRINT, '处理文件 ', i+1, '/', xml_count, ': ', FILE_BASENAME(mtl_file)

    ; 错误捕获
    Catch, errorStatus
    IF (errorStatus NE 0) THEN BEGIN
      Catch, /CANCEL
      errMsg = FILE_BASENAME(mtl_file) + ' --- ' + !ERROR_STATE.MSG
      errMsgs = [errMsgs, errMsg]
      PRINT, '  错误: ', !ERROR_STATE.MSG
      MESSAGE, /RESET
      CONTINUE
    ENDIF

    ; 打开Surface Reflectance数据
    PRINT, '  正在打开Surface Reflectance数据...'
    raster = e.OpenRaster(mtl_file, DATASET_NAME='Surface Reflectance')

    ; 处理返回数组的情�?
    IF raster NE !NULL THEN BEGIN
      tempSize = SIZE(raster, /N_DIMENSIONS)
      IF tempSize GT 0 THEN raster = raster[0]
    ENDIF

    IF (raster EQ !NULL) OR ~OBJ_VALID(raster) THEN BEGIN
      PRINT, '  错误: 无法打开Surface Reflectance数据'
      errMsg = FILE_BASENAME(mtl_file) + ' --- 无法打开Surface Reflectance数据'
      errMsgs = [errMsgs, errMsg]
      CONTINUE
    ENDIF

    PRINT, '  �?成功打开数据，波段数: ', raster.NBANDS

    ; 检查波段数（Landsat 8/9 L2 Surface Reflectance应该�?个波段）
    IF raster.NBANDS LT 4 THEN BEGIN
      PRINT, '  错误: 波段数不足（需要至�?个波段）'
      raster.Close
      errMsg = FILE_BASENAME(mtl_file) + ' --- 波段数不�?
      errMsgs = [errMsgs, errMsg]
      CONTINUE
    ENDIF

    ; 检�?/ 补充空间参考（�?GeoTIFF 文件直接读取，不依赖 MTL 文件解析�?
    PRINT, '  正在检查空间参考信�?..'
    spatialRef = !NULL
    CATCH, errCheckSR
    IF errCheckSR EQ 0 THEN BEGIN
      spatialRef = raster.SPATIALREF
      CATCH, /CANCEL
      ; 1) 已有空间参�?
      IF OBJ_VALID(spatialRef) THEN BEGIN
        PRINT, '  �?raster已有空间参考信�?
      ENDIF ELSE BEGIN
        ; 2) 无空间参考，�?GeoTIFF 文件读取（SR_B3 �?SR_B4�?
        PRINT, '  警告: raster缺少空间参考信息，正在从GeoTIFF文件读取...'
        mtlDir   = FILE_DIRNAME(mtl_file)

        ; 查找 SR_B3 �?SR_B4 文件
        srB3Files = FILE_SEARCH(mtlDir, '*_SR_B3.TIF', COUNT=countB3)
        srB4Files = FILE_SEARCH(mtlDir, '*_SR_B4.TIF', COUNT=countB4)

        geotiffFile = ''
        IF countB3 GT 0 THEN BEGIN
          geotiffFile = srB3Files[0]
          PRINT, '  找到SR_B3文件: ' + FILE_BASENAME(geotiffFile)
        ENDIF ELSE IF countB4 GT 0 THEN BEGIN
          geotiffFile = srB4Files[0]
          PRINT, '  找到SR_B4文件: ' + FILE_BASENAME(geotiffFile)
        ENDIF ELSE BEGIN
          PRINT, '  错误: 未找到SR_B3或SR_B4文件，无法添加空间参考信�?
          PRINT, '  提示: 水体提取需要空间参考信�?
          errMsg  = FILE_BASENAME(mtl_file) + ' --- 缺少空间参考信息且无法从GeoTIFF文件读取'
          errMsgs = [errMsgs, errMsg]
          raster.Close
          CONTINUE
        ENDELSE

        IF ~FILE_TEST(geotiffFile) THEN BEGIN
          PRINT, '  错误: GeoTIFF文件不存�? ' + geotiffFile
          errMsg  = FILE_BASENAME(mtl_file) + ' --- GeoTIFF文件不存�?
          errMsgs = [errMsgs, errMsg]
          raster.Close
          CONTINUE
        ENDIF

        ; 使用 create_map_info_from_geotiff 函数�?GeoTIFF 创建 MAP_INFO
        mapInfo = create_map_info_from_geotiff(geotiffFile)
        IF mapInfo EQ !NULL THEN BEGIN
          PRINT, '  错误: 无法从GeoTIFF文件创建空间参考信�?
          errMsg  = FILE_BASENAME(mtl_file) + ' --- 无法创建空间参考信�?
          errMsgs = [errMsgs, errMsg]
          raster.Close
          CONTINUE
        ENDIF

        ; 使用 mapInfo �?raster 设置空间参�?
        rasterWithSR = set_spatial_ref_to_raster(raster, mapInfo)
        IF OBJ_VALID(rasterWithSR) THEN BEGIN
          raster.Close
          raster = rasterWithSR
          ; 再验证一�?
          CATCH, errCheckSRAfter
          IF errCheckSRAfter EQ 0 THEN BEGIN
            spatialRef = raster.SPATIALREF
            CATCH, /CANCEL
            IF OBJ_VALID(spatialRef) THEN BEGIN
              PRINT, '  �?成功为raster设置空间参考信�?
            ENDIF ELSE BEGIN
              PRINT, '  错误: 设置空间参考后spatialRef仍然无效'
              errMsg  = FILE_BASENAME(mtl_file) + ' --- 空间参考设置失�?
              errMsgs = [errMsgs, errMsg]
              raster.Close
              CONTINUE
            ENDELSE
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '  错误: 验证空间参考时发生错误'
            errMsg  = FILE_BASENAME(mtl_file) + ' --- 空间参考验证失�?
            errMsgs = [errMsgs, errMsg]
            raster.Close
            CONTINUE
          ENDELSE
        ENDIF ELSE BEGIN
          PRINT, '  错误: 设置空间参考失�?
          errMsg  = FILE_BASENAME(mtl_file) + ' --- 空间参考设置失�?
          errMsgs = [errMsgs, errMsg]
          raster.Close
          CONTINUE
        ENDELSE
      ENDELSE  ; IF OBJ_VALID(spatialRef) �?ELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 检查空间参考时发生错误，将继续处理'
    ENDELSE

    ; 再次验证空间参考（在执行水体提取之前）
    CATCH, errFinalCheckSR
    IF errFinalCheckSR EQ 0 THEN BEGIN
      spatialRef = raster.SPATIALREF
      CATCH, /CANCEL
      IF ~OBJ_VALID(spatialRef) THEN BEGIN
        PRINT, '  错误: raster仍然缺少空间参考信息，无法继续处理'
        errMsg = FILE_BASENAME(mtl_file) + ' --- raster缺少空间参考信�?
        errMsgs = [errMsgs, errMsg]
        raster.Close
        CONTINUE
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 最终空间参考检查失�?
      errMsg = FILE_BASENAME(mtl_file) + ' --- 空间参考检查失�?
      errMsgs = [errMsgs, errMsg]
      raster.Close
      CONTINUE
    ENDELSE

    ; 生成输出文件�?
    orig_basename = FILE_BASENAME(mtl_file, STRMID(mtl_file, STRPOS(mtl_file, '.', /REVERSE_SEARCH)))
    ; 清理文件名（移除特殊字符�?
    clean_basename = ''
    FOR k=0, STRLEN(orig_basename)-1 DO BEGIN
      char = STRMID(orig_basename, k, 1)
      char_bytes = BYTE(char)
      ascii_val = char_bytes[0]
      IF ((ascii_val GE 48 AND ascii_val LE 57) OR $  ; 0-9
          (ascii_val GE 65 AND ascii_val LE 90) OR $  ; A-Z
          (ascii_val GE 97 AND ascii_val LE 122) OR $  ; a-z
          (ascii_val EQ 95) OR $                        ; _
          (ascii_val EQ 45)) THEN BEGIN                 ; -
        clean_basename = clean_basename + char
      ENDIF ELSE BEGIN
        clean_basename = clean_basename + '_'
      ENDELSE
    ENDFOR
    ; 移除连续的下划线
    WHILE STRPOS(clean_basename, '__') NE -1 DO BEGIN
      clean_basename = STRREPLACE(clean_basename, '__', '_')
    ENDWHILE
    ; 移除开头和结尾的下划线
    WHILE (STRLEN(clean_basename) GT 0) AND (STRMID(clean_basename, 0, 1) EQ '_') DO BEGIN
      clean_basename = STRMID(clean_basename, 1)
    ENDWHILE
    WHILE (STRLEN(clean_basename) GT 0) AND (STRMID(clean_basename, STRLEN(clean_basename)-1, 1) EQ '_') DO BEGIN
      clean_basename = STRMID(clean_basename, 0, STRLEN(clean_basename)-1)
    ENDWHILE
    IF STRLEN(clean_basename) EQ 0 THEN clean_basename = 'output'

    ; 生成输出文件路径
    IF output_format EQ '.tif' THEN BEGIN
      output_raster_uri = FILEPATH(clean_basename + '_Water.tif', root_dir=outdir)
      output_vector_uri = FILEPATH(clean_basename + '_Water.shp', root_dir=outdir)
    ENDIF ELSE BEGIN
      output_raster_uri = FILEPATH(clean_basename + '_Water.dat', root_dir=outdir)
      output_vector_uri = FILEPATH(clean_basename + '_Water.shp', root_dir=outdir)
    ENDELSE

    ; 删除已存在的输出文件
    IF FILE_TEST(output_raster_uri) THEN BEGIN
      PRINT, '  检测到已存在的输出文件，正在删�?..'
      FILE_DELETE, output_raster_uri, /QUIET, /ALLOW_NONEXISTENT
      IF output_format EQ '.dat' THEN BEGIN
        hdr_file = FILE_DIRNAME(output_raster_uri) + PATH_SEP() + FILE_BASENAME(output_raster_uri, '.dat') + '.hdr'
        IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
      ENDIF
    ENDIF
    IF FILE_TEST(output_vector_uri) THEN BEGIN
      FILE_DELETE, output_vector_uri, /QUIET, /ALLOW_NONEXISTENT
      ; 删除Shapefile相关文件
      shp_files = FILE_SEARCH(FILE_DIRNAME(output_vector_uri), FILE_BASENAME(output_vector_uri) + '.*', COUNT=shp_count)
      IF shp_count GT 0 THEN BEGIN
        FOR j=0, shp_count-1 DO BEGIN
          FILE_DELETE, shp_files[j], /QUIET, /ALLOW_NONEXISTENT
        ENDFOR
      ENDIF
    ENDIF

    ; 执行水体提取任务
    PRINT, '  正在执行水体提取...'
    CATCH, errWaterExtraction
    IF errWaterExtraction EQ 0 THEN BEGIN
      ; 调用水体提取任务
      test_ENVIWaterExtractionTask, $
        INPUT_RASTER=raster, $
        Apply_QUAC=Apply_QUAC, $
        thresholdValue=thresholdValue, $
        smoothSize=smoothSize, $
        minArea=minArea, $
        OUTPUT_RASTER_URI=output_raster_uri, $
        OUTPUT_VECTOR_URI=output_vector_uri
      CATCH, /CANCEL

      WAIT, 0.5
      IF FILE_TEST(output_raster_uri) THEN BEGIN
        PRINT, '  �?水体提取完成'
        PRINT, '    栅格文件: ', FILE_BASENAME(output_raster_uri)
        IF FILE_TEST(output_vector_uri) THEN BEGIN
          PRINT, '    矢量文件: ', FILE_BASENAME(output_vector_uri)
        ENDIF
      ENDIF ELSE BEGIN
        PRINT, '  警告: 输出文件不存在，可能处理失败'
        errMsg = FILE_BASENAME(mtl_file) + ' --- 输出文件不存�?
        errMsgs = [errMsgs, errMsg]
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 水体提取失败: ' + !ERROR_STATE.MSG
      errMsg = FILE_BASENAME(mtl_file) + ' --- 水体提取失败: ' + !ERROR_STATE.MSG
      errMsgs = [errMsgs, errMsg]
      raster.Close
      CONTINUE
    ENDELSE

    ; 关闭raster
    raster.Close

    success_count = success_count + 1
    PRINT, '  完成: ', FILE_BASENAME(output_raster_uri)
    PRINT, ''
  ENDFOR

  PRINT, '=========================================='
  PRINT, '批量处理完成�?
  PRINT, '成功处理: ', success_count, ' 个文�?
  IF errMsgs NE !NULL THEN BEGIN
    PRINT, '失败: ', N_ELEMENTS(errMsgs), ' 个文�?
    PRINT, ''
    PRINT, '错误信息:'
    FOR i=0, N_ELEMENTS(errMsgs)-1 DO BEGIN
      PRINT, '  ', errMsgs[i]
    ENDFOR
  ENDIF
  PRINT, '=========================================='

END
