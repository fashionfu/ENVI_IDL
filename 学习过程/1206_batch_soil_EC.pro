;+
; 程序名: 1206_batch_soil_EC.pro
; 功能: 批量计算Landsat L2数据的土壤电导率EC
; 输入: Landsat L2 MTL文件（Surface Reflectance数据）
; 输出: 土壤电导率EC影像（保存到指定输出目录）
; 作者: Auto
; 日期: 2024-12
;-

PRO batch_soil_EC

  COMPILE_OPT IDL2
  
  ; 启动ENVI
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()
  
  PRINT, '=========================================='
  PRINT, 'Landsat L2 土壤电导率EC批量计算工具'
  PRINT, '=========================================='
  PRINT, ''
  
  ; 步骤1：选择输入文件（可多选MTL文件）
  PRINT, '步骤1：选择输入文件（可多选MTL文件）...'
  files = ENVI_PICKFILE(TITLE='请选择Landsat L2 MTL文件（可多选）', $
    /MULTIPLE_FILES, $
    FILTER=['*_MTL.txt', '*_MTL.xml', '*_MTL.json', '*.*'])
  
  IF (files[0] EQ '') OR (N_ELEMENTS(files) EQ 0) THEN BEGIN
    PRINT, '未选择文件，退出。'
    RETURN
  ENDIF
  
  n_files = N_ELEMENTS(files)
  PRINT, '已选择 ', n_files, ' 个文件'
  PRINT, ''
  
  ; 步骤2：选择输出目录
  PRINT, '步骤2：选择输出目录...'
  PRINT, '注意: 只能保存为ENVI格式(.dat)才能确保空间参考坐标系被正确保存'
  PRINT, '      TIFF格式可能丢失空间参考信息，因此已禁用TIFF格式输出'
  PRINT, ''
  outdir = ENVI_PICKFILE(/OUTPUT, /DIRECTORY, TITLE='请选择输出目录')
  IF outdir EQ '' THEN BEGIN
    PRINT, '未选择输出目录，退出。'
    RETURN
  ENDIF
  PRINT, '输出目录: ', outdir
  PRINT, ''
  
  ; 固定使用ENVI格式
  output_format = '.dat'
  PRINT, '输出格式: ENVI格式 (.dat)'
  PRINT, '提示: 只能保存为dat格式下才会有空间参考坐标系'
  PRINT, ''
  
  ; 步骤3：设置EC计算参数
  PRINT, '步骤3：设置EC计算参数...'
  PRINT, 'EC计算公式: EC = a * SI + b'
  PRINT, '其中 SI = sqrt((B3*B3 + B4*B4)/2) 或 SI = sqrt(B3*B4)'
  PRINT, ''
  
  ; 使用对话框输入参数（默认值基于文献）
  ; 默认参数：a = 0.5, b = 0.1（可根据实际数据调整）
  a_coef = 0.5
  b_coef = 0.1
  si_method = 1  ; 1 = sqrt((B3*B3+B4*B4)/2), 2 = sqrt(B3*B4)
  
  ; 简化参数输入（使用固定值，用户可手动修改代码）
  PRINT, '使用默认参数:'
  PRINT, '  a系数: ', a_coef
  PRINT, '  b系数: ', b_coef
  PRINT, '  SI计算方法: sqrt((B3*B3+B4*B4)/2)'
  PRINT, ''
  PRINT, '提示: 如需修改参数，请编辑代码中的a_coef和b_coef变量'
  PRINT, ''
  
  ; 步骤4：批量处理所有文件
  PRINT, '步骤4：开始批量处理...'
  PRINT, '=========================================='
  
  DataColl = e.DATA  ; Data Manager
  errMsgs = !NULL    ; 记录错误信息
  success_count = 0
  
  ; 存储每个影像的中心点经纬度，用于计算距离
  imageCenters = LIST()
  
  FOR i=0, n_files-1 DO BEGIN
    mtl_file = files[i]
    PRINT, '处理文件 ', i+1, '/', n_files, ': ', FILE_BASENAME(mtl_file)
    
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
    
    ; 处理返回数组的情况
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
    
    PRINT, '  ✓ 成功打开数据，波段数: ', raster.NBANDS
    
    ; 检查波段数（Landsat 8/9 L2 Surface Reflectance应该有7个波段）
    IF raster.NBANDS LT 4 THEN BEGIN
      PRINT, '  错误: 波段数不足（需要至少4个波段）'
      raster.Close
      errMsg = FILE_BASENAME(mtl_file) + ' --- 波段数不足'
      errMsgs = [errMsgs, errMsg]
      CONTINUE
    ENDIF
    
    ; 检查 / 补充空间参考（从 GeoTIFF 文件直接读取，不依赖 MTL 文件解析）
    PRINT, '  正在检查空间参考信息...'
    spatialRef = !NULL
    CATCH, errCheckSR
    IF errCheckSR EQ 0 THEN BEGIN
      spatialRef = raster.SPATIALREF
      CATCH, /CANCEL

      ; 1) 已有空间参考
      IF OBJ_VALID(spatialRef) THEN BEGIN
        PRINT, '  ✓ raster已有空间参考信息'
      ENDIF ELSE BEGIN
        ; 2) 无空间参考，从 GeoTIFF 文件读取（SR_B3 或 SR_B4）
        PRINT, '  警告: raster缺少空间参考信息，正在从GeoTIFF文件读取...'

        mtlDir   = FILE_DIRNAME(mtl_file)
        
        ; 查找 SR_B3 或 SR_B4 文件
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
          PRINT, '  错误: 未找到SR_B3或SR_B4文件，无法添加空间参考信息'
          PRINT, '  提示: BuildGridDefinitionFromRaster需要空间参考信息'
          errMsg  = FILE_BASENAME(mtl_file) + ' --- 缺少空间参考信息且无法从GeoTIFF文件读取'
          errMsgs = [errMsgs, errMsg]
          raster.Close
          CONTINUE
        ENDELSE

        IF ~FILE_TEST(geotiffFile) THEN BEGIN
          PRINT, '  错误: GeoTIFF文件不存在: ' + geotiffFile
          errMsg  = FILE_BASENAME(mtl_file) + ' --- GeoTIFF文件不存在'
          errMsgs = [errMsgs, errMsg]
          raster.Close
          CONTINUE
        ENDIF

        ; 使用 create_map_info_from_geotiff 函数从 GeoTIFF 创建 MAP_INFO
        mapInfo = create_map_info_from_geotiff(geotiffFile)

        IF mapInfo EQ !NULL THEN BEGIN
          PRINT, '  错误: 无法从GeoTIFF文件创建空间参考信息'
          errMsg  = FILE_BASENAME(mtl_file) + ' --- 无法创建空间参考信息'
          errMsgs = [errMsgs, errMsg]
          raster.Close
          CONTINUE
        ENDIF

        ; 使用 mapInfo 为 raster 设置空间参考
        rasterWithSR = set_spatial_ref_to_raster(raster, mapInfo)
        IF OBJ_VALID(rasterWithSR) THEN BEGIN
          raster.Close
          raster = rasterWithSR

          ; 再验证一次
          CATCH, errCheckSRAfter
          IF errCheckSRAfter EQ 0 THEN BEGIN
            spatialRef = raster.SPATIALREF
            CATCH, /CANCEL
            IF OBJ_VALID(spatialRef) THEN BEGIN
              PRINT, '  ✓ 成功为raster设置空间参考信息'
            ENDIF ELSE BEGIN
              PRINT, '  错误: 设置空间参考后spatialRef仍然无效'
              errMsg  = FILE_BASENAME(mtl_file) + ' --- 空间参考设置失败'
              errMsgs = [errMsgs, errMsg]
              raster.Close
              CONTINUE
            ENDELSE
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '  错误: 验证空间参考时发生错误'
            errMsg  = FILE_BASENAME(mtl_file) + ' --- 空间参考验证失败'
            errMsgs = [errMsgs, errMsg]
            raster.Close
            CONTINUE
          ENDELSE

        ENDIF ELSE BEGIN
          PRINT, '  错误: 设置空间参考失败'
          errMsg  = FILE_BASENAME(mtl_file) + ' --- 空间参考设置失败'
          errMsgs = [errMsgs, errMsg]
          raster.Close
          CONTINUE
        ENDELSE

      ENDELSE  ; IF OBJ_VALID(spatialRef) 的 ELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 检查空间参考时发生错误，将继续处理'
    ENDELSE
    
    ; 再次验证空间参考（在提取波段之前）
    CATCH, errFinalCheckSR
    IF errFinalCheckSR EQ 0 THEN BEGIN
      spatialRef = raster.SPATIALREF
      CATCH, /CANCEL
      IF ~OBJ_VALID(spatialRef) THEN BEGIN
        PRINT, '  错误: raster仍然缺少空间参考信息，无法继续处理'
        errMsg = FILE_BASENAME(mtl_file) + ' --- raster缺少空间参考信息'
        errMsgs = [errMsgs, errMsg]
        raster.Close
        CONTINUE
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 最终空间参考检查失败'
      errMsg = FILE_BASENAME(mtl_file) + ' --- 空间参考检查失败'
      errMsgs = [errMsgs, errMsg]
      raster.Close
      CONTINUE
    ENDELSE
    
    ; 检查并显示经纬度坐标（验证空间参考是否正确）
    PRINT, '  正在检查经纬度坐标...'
    CATCH, errCheckLonLat
    IF errCheckLonLat EQ 0 THEN BEGIN
      spatialRef = raster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(spatialRef) THEN BEGIN
        nCols = raster.NCOLUMNS
        nRows = raster.NROWS
        
        ; 计算关键点：左上角、右上角、左下角、右下角、中心点
        fileX = [0.0, FLOAT(nCols-1), 0.0, FLOAT(nCols-1), FLOAT(nCols-1)/2.0]
        fileY = [0.0, 0.0, FLOAT(nRows-1), FLOAT(nRows-1), FLOAT(nRows-1)/2.0]
        pointNames = ['左上角', '右上角', '左下角', '右下角', '中心点']
        
        ; 转换为地图坐标（投影坐标）
        CATCH, errConvertToMap
        IF errConvertToMap EQ 0 THEN BEGIN
          spatialRef.ConvertFileToMap, fileX, fileY, mapX, mapY
          CATCH, /CANCEL
          
          ; 转换为经纬度坐标
          CATCH, errConvertToLonLat
          IF errConvertToLonLat EQ 0 THEN BEGIN
            spatialRef.ConvertMapToLonLat, mapX, mapY, lonD, latD
            CATCH, /CANCEL
            
            PRINT, '  ========== 空间参考坐标检查 =========='
            PRINT, '  投影坐标系: ' + spatialRef.COORD_SYS_STR
            PRINT, '  像元大小: ' + STRING(spatialRef.PIXEL_SIZE[0], FORMAT='(F6.2)') + ' x ' + STRING(spatialRef.PIXEL_SIZE[1], FORMAT='(F6.2)') + ' 米'
            PRINT, ''
            PRINT, '  关键点坐标:'
            FOR i=0, N_ELEMENTS(pointNames)-1 DO BEGIN
              PRINT, '    ' + pointNames[i] + ':'
              PRINT, '      投影坐标: (' + STRING(mapX[i], FORMAT='(F12.2)') + ', ' + STRING(mapY[i], FORMAT='(F12.2)') + ') 米'
              PRINT, '      经纬度: (' + STRING(lonD[i], FORMAT='(F10.6)') + '°E, ' + STRING(latD[i], FORMAT='(F10.6)') + '°N)'
            ENDFOR
            PRINT, '  ======================================'
            PRINT, ''
            
            ; 保存中心点经纬度，用于后续计算影像间距离
            centerLon = lonD[4]  ; 中心点经度
            centerLat = latD[4]  ; 中心点纬度
            imageInfo = HASH('lon', centerLon, 'lat', centerLat, 'name', FILE_BASENAME(mtl_file))
            imageCenters.Add, imageInfo
            
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '  警告: 无法转换为经纬度坐标: ' + !ERROR_STATE.MSG
            ; 至少显示投影坐标
            PRINT, '  投影坐标（左上角）: (' + STRING(mapX[0], FORMAT='(F12.2)') + ', ' + STRING(mapY[0], FORMAT='(F12.2)') + ') 米'
            PRINT, ''
          ENDELSE
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          PRINT, '  警告: 无法转换为地图坐标: ' + !ERROR_STATE.MSG
          PRINT, ''
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  警告: spatialRef无效，无法检查经纬度'
        PRINT, ''
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 检查经纬度时发生错误: ' + !ERROR_STATE.MSG
      PRINT, ''
    ENDELSE
    
    ; 提取B3（红波段）和B4（近红外波段）
    ; Landsat 8/9 L2 Surface Reflectance波段顺序：
    ; B1: Coastal, B2: Blue, B3: Green, B4: Red, B5: NIR, B6: SWIR1, B7: SWIR2
    ; 注意：对于EC计算，通常使用B3（Green）和B4（Red），但也可以使用B4和B5
    ; 这里使用B3和B4（Green和Red波段）
    
    PRINT, '  正在提取波段...'
    b3_raster = ENVISubsetRaster(raster, bands=[2])  ; B3 (Green, 索引2)
    b4_raster = ENVISubsetRaster(raster, bands=[3])   ; B4 (Red, 索引3)
    
    ; 检查波段数据值范围（用于调试）
    CATCH, errCheckB3
    IF errCheckB3 EQ 0 THEN BEGIN
      ; 获取一小块数据样本来检查值范围
      nCols = b3_raster.NCOLUMNS
      nRows = b3_raster.NROWS
      sampleSize = MIN(1000, MIN(nCols, nRows))
      subRect = [0, 0, sampleSize-1, sampleSize-1]
      b3_sample = b3_raster.GetData(BANDS=0, SUB_RECT=subRect)
      b4_sample = b4_raster.GetData(BANDS=0, SUB_RECT=subRect)
      
      ; 检查有效值（排除可能的填充值）
      ; Landsat L2 Surface Reflectance填充值通常是-9999或0
      valid_mask_b3 = (b3_sample GT -100) AND (b3_sample LT 10000)
      valid_mask_b4 = (b4_sample GT -100) AND (b4_sample LT 10000)
      valid_b3 = b3_sample[WHERE(valid_mask_b3)]
      valid_b4 = b4_sample[WHERE(valid_mask_b4)]
      
      IF N_ELEMENTS(valid_b3) GT 0 THEN BEGIN
        PRINT, '  B3波段数据范围: ' + STRING(MIN(valid_b3), FORMAT='(F8.4)') + ' 至 ' + STRING(MAX(valid_b3), FORMAT='(F8.4)')
        PRINT, '    有效像元数: ' + STRING(N_ELEMENTS(valid_b3)) + ' / ' + STRING(N_ELEMENTS(b3_sample))
      ENDIF ELSE BEGIN
        PRINT, '  警告: B3波段未找到有效数据值'
      ENDELSE
      
      IF N_ELEMENTS(valid_b4) GT 0 THEN BEGIN
        PRINT, '  B4波段数据范围: ' + STRING(MIN(valid_b4), FORMAT='(F8.4)') + ' 至 ' + STRING(MAX(valid_b4), FORMAT='(F8.4)')
        PRINT, '    有效像元数: ' + STRING(N_ELEMENTS(valid_b4)) + ' / ' + STRING(N_ELEMENTS(b4_sample))
      ENDIF ELSE BEGIN
        PRINT, '  警告: B4波段未找到有效数据值'
      ENDELSE
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 无法检查波段数据值范围'
    ENDELSE
    
    ; 计算盐分指数SI
    PRINT, '  正在计算盐分指数SI...'
    
    ; 方法1: SI = sqrt((B3*B3 + B4*B4)/2)
    ; 方法2: SI = sqrt(B3*B4)
    
    IF si_method EQ 1 THEN BEGIN
      ; 方法1: 先计算B3*B3和B4*B4，然后堆叠
      b3_sq_exp = 'b1*b1'
      b4_sq_exp = 'b1*b1'
      
      b3_sq = ENVIPixelwiseBandMathRaster(b3_raster, b3_sq_exp)
      b4_sq = ENVIPixelwiseBandMathRaster(b4_raster, b4_sq_exp)
      
      ; 堆叠两个波段
      gridTask = ENVITask('BuildGridDefinitionFromRaster')
      gridTask.INPUT_RASTER = b3_sq
      gridTask.Execute
      gridDef = gridTask.OUTPUT_GRIDDEFINITION
      
      stacked = ENVILayerStackRaster([b3_sq, b4_sq], grid_definition=gridDef)
      
      ; 计算SI = sqrt((b1+b2)/2)，其中b1=B3*B3, b2=B4*B4
      si_exp = 'sqrt((b1+b2)/2.0)'
      si_raster = ENVIPixelwiseBandMathRaster(stacked, si_exp)
      
      ; 清理临时对象
      b3_sq.Close
      b4_sq.Close
      stacked.Close
    ENDIF ELSE BEGIN
      ; 方法2: SI = sqrt(B3*B4)
      ; 先堆叠B3和B4
      gridTask = ENVITask('BuildGridDefinitionFromRaster')
      gridTask.INPUT_RASTER = b3_raster
      gridTask.Execute
      gridDef = gridTask.OUTPUT_GRIDDEFINITION
      
      stacked = ENVILayerStackRaster([b3_raster, b4_raster], grid_definition=gridDef)
      
      ; 计算SI = sqrt(b1*b2)，其中b1=B3, b2=B4
      si_exp = 'sqrt(b1*b2)'
      si_raster = ENVIPixelwiseBandMathRaster(stacked, si_exp)
      
      ; 清理临时对象
      stacked.Close
    ENDELSE
    
    ; 清理波段子集
    b3_raster.Close
    b4_raster.Close
    
    PRINT, '  ✓ SI计算完成'
    
    ; 检查SI数据值范围（用于调试）
    CATCH, errCheckSI
    IF errCheckSI EQ 0 THEN BEGIN
      nCols = si_raster.NCOLUMNS
      nRows = si_raster.NROWS
      sampleSize = MIN(1000, MIN(nCols, nRows))
      subRect = [0, 0, sampleSize-1, sampleSize-1]
      si_sample = si_raster.GetData(BANDS=0, SUB_RECT=subRect)
      valid_mask_si = (si_sample GT -100) AND (si_sample LT 10000)
      valid_si = si_sample[WHERE(valid_mask_si)]
      IF N_ELEMENTS(valid_si) GT 0 THEN BEGIN
        PRINT, '  SI数据范围: ' + STRING(MIN(valid_si), FORMAT='(F8.4)') + ' 至 ' + STRING(MAX(valid_si), FORMAT='(F8.4)')
        PRINT, '    有效像元数: ' + STRING(N_ELEMENTS(valid_si)) + ' / ' + STRING(N_ELEMENTS(si_sample))
      ENDIF ELSE BEGIN
        PRINT, '  警告: SI未找到有效数据值'
      ENDELSE
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 无法检查SI数据值范围'
    ENDELSE
    
    ; 计算EC = a * SI + b
    PRINT, '  正在计算土壤电导率EC...'
    a_str = STRTRIM(STRING(a_coef, FORMAT='(F10.6)'), 2)
    b_str = STRTRIM(STRING(b_coef, FORMAT='(F10.6)'), 2)
    ec_exp = a_str + '*b1+' + b_str
    ec_raster = ENVIPixelwiseBandMathRaster(si_raster, ec_exp)
    
    ; 清理SI raster
    si_raster.Close
    
    ; 检查EC数据值范围（用于调试）
    CATCH, errCheckEC
    IF errCheckEC EQ 0 THEN BEGIN
      nCols = ec_raster.NCOLUMNS
      nRows = ec_raster.NROWS
      sampleSize = MIN(1000, MIN(nCols, nRows))
      subRect = [0, 0, sampleSize-1, sampleSize-1]
      ec_sample = ec_raster.GetData(BANDS=0, SUB_RECT=subRect)
      valid_mask_ec = (ec_sample GT -1000) AND (ec_sample LT 100000)
      valid_ec = ec_sample[WHERE(valid_mask_ec)]
      IF N_ELEMENTS(valid_ec) GT 0 THEN BEGIN
        PRINT, '  EC数据范围: ' + STRING(MIN(valid_ec), FORMAT='(F8.4)') + ' 至 ' + STRING(MAX(valid_ec), FORMAT='(F8.4)')
        PRINT, '    有效像元数: ' + STRING(N_ELEMENTS(valid_ec)) + ' / ' + STRING(N_ELEMENTS(ec_sample))
      ENDIF ELSE BEGIN
        PRINT, '  警告: EC未找到有效数据值，可能所有值都是nodata'
      ENDELSE
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 无法检查EC数据值范围'
    ENDELSE
    
    PRINT, '  ✓ EC计算完成'
    
    ; 生成输出文件名
    orig_basename = FILE_BASENAME(mtl_file, STRMID(mtl_file, STRPOS(mtl_file, '.', /REVERSE_SEARCH)))
    ; 清理文件名（移除特殊字符）
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
    ; 移除连续的下划线（手动替换，因为STRREPLACE可能不可用）
    WHILE STRPOS(clean_basename, '__') NE -1 DO BEGIN
      posDoubleUnderscore = STRPOS(clean_basename, '__')
      IF posDoubleUnderscore GE 0 THEN BEGIN
        clean_basename = STRMID(clean_basename, 0, posDoubleUnderscore) + '_' + STRMID(clean_basename, posDoubleUnderscore+2)
      ENDIF ELSE BEGIN
        BREAK
      ENDELSE
    ENDWHILE
    ; 移除开头和结尾的下划线
    WHILE (STRLEN(clean_basename) GT 0) AND (STRMID(clean_basename, 0, 1) EQ '_') DO BEGIN
      clean_basename = STRMID(clean_basename, 1)
    ENDWHILE
    WHILE (STRLEN(clean_basename) GT 0) AND (STRMID(clean_basename, STRLEN(clean_basename)-1, 1) EQ '_') DO BEGIN
      clean_basename = STRMID(clean_basename, 0, STRLEN(clean_basename)-1)
    ENDWHILE
    IF STRLEN(clean_basename) EQ 0 THEN clean_basename = 'output'
    
    ; 固定使用ENVI格式
    outfile = FILEPATH(clean_basename + '_EC.dat', root_dir=outdir)
    
    ; 删除已存在的输出文件
    IF FILE_TEST(outfile) THEN BEGIN
      PRINT, '  检测到已存在的输出文件，正在删除...'
      FILE_DELETE, outfile, /QUIET, /ALLOW_NONEXISTENT
      IF output_format EQ '.dat' THEN BEGIN
        hdr_file = FILE_DIRNAME(outfile) + PATH_SEP() + FILE_BASENAME(outfile, '.dat') + '.hdr'
        IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
      ENDIF
    ENDIF
    
    ; 检查并确保EC raster有空间参考信息
    PRINT, '  正在检查EC raster的空间参考信息...'
    ec_spatialRef = !NULL
    CATCH, errCheckECSR
    IF errCheckECSR EQ 0 THEN BEGIN
      ec_spatialRef = ec_raster.SPATIALREF
      CATCH, /CANCEL
      
      IF ~OBJ_VALID(ec_spatialRef) THEN BEGIN
        PRINT, '  警告: EC raster缺少空间参考信息，正在从原始raster复制...'
        
        ; 从原始raster获取空间参考
        originalSR = !NULL
        CATCH, errGetOriginalSR
        IF errGetOriginalSR EQ 0 THEN BEGIN
          originalSR = raster.SPATIALREF
          CATCH, /CANCEL
          
          IF OBJ_VALID(originalSR) THEN BEGIN
            ; 从SPATIALREF获取MAP_INFO
            mapInfo = !NULL
            CATCH, errGetMapInfo
            IF errGetMapInfo EQ 0 THEN BEGIN
              mapInfo = originalSR.MAP_INFO
              CATCH, /CANCEL
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
            ENDELSE
            
            IF mapInfo NE !NULL THEN BEGIN
              ; 使用set_spatial_ref_to_raster函数设置空间参考
              ec_rasterWithSR = set_spatial_ref_to_raster(ec_raster, mapInfo)
            IF OBJ_VALID(ec_rasterWithSR) THEN BEGIN
              ec_raster.Close
              ec_raster = ec_rasterWithSR
              
              ; 再次验证
              CATCH, errVerifyECSR
              IF errVerifyECSR EQ 0 THEN BEGIN
                ec_spatialRef = ec_raster.SPATIALREF
                CATCH, /CANCEL
                IF OBJ_VALID(ec_spatialRef) THEN BEGIN
                  PRINT, '  ✓ 成功为EC raster设置空间参考信息'
                ENDIF ELSE BEGIN
                  PRINT, '  错误: 设置空间参考后仍然无效'
                ENDELSE
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
              ENDELSE
            ENDIF ELSE BEGIN
              PRINT, '  错误: 无法从SPATIALREF获取MAP_INFO'
            ENDELSE
            ENDIF ELSE BEGIN
              PRINT, '  错误: 无法从SPATIALREF获取MAP_INFO'
            ENDELSE
          ENDIF ELSE BEGIN
            PRINT, '  错误: 原始raster也缺少空间参考信息'
          ENDELSE
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
      ENDIF ELSE BEGIN
        PRINT, '  ✓ EC raster已有空间参考信息'
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  警告: 检查EC raster空间参考时发生错误'
    ENDELSE
    PRINT, ''
    
    ; 设置data ignore value（处理NoData区域）
    PRINT, '  正在设置无效值...'
    ec_raster = set_data_ignore_value_to_raster(ec_raster, -999)
    
    ; 最终验证空间参考（导出前）
    PRINT, '  正在最终验证空间参考信息（导出前）...'
    finalSR = !NULL
    CATCH, errFinalSR
    IF errFinalSR EQ 0 THEN BEGIN
      finalSR = ec_raster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(finalSR) THEN BEGIN
        PRINT, '  ✓ EC raster有有效的空间参考信息，准备导出'
      ENDIF ELSE BEGIN
        PRINT, '  错误: EC raster仍然缺少空间参考信息，无法导出'
        errMsg = FILE_BASENAME(mtl_file) + ' --- EC raster缺少空间参考信息'
        errMsgs = [errMsgs, errMsg]
        raster.Close
        ec_raster.Close
        CONTINUE
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 验证空间参考时发生错误'
      errMsg = FILE_BASENAME(mtl_file) + ' --- 空间参考验证失败'
      errMsgs = [errMsgs, errMsg]
      raster.Close
      ec_raster.Close
      CONTINUE
    ENDELSE
    PRINT, ''
    
    ; 保存结果（使用临时ENVI文件方法：先导出ENVI，设置空间参考，再导出最终ENVI格式）
    PRINT, '  正在保存结果...'
    
    ; 获取空间参考信息（导出前）
    ; 注意：不能直接从SPATIALREF获取MAP_INFO，需要从SPATIALREF重新构建
    exportMapInfo = !NULL
    
    ; 从ec_raster的SPATIALREF重新构建MAP_INFO
    CATCH, errGetMapInfoFromEC
    IF errGetMapInfoFromEC EQ 0 THEN BEGIN
      ecSR = ec_raster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(ecSR) THEN BEGIN
        ; 获取左上角坐标（文件坐标0,0对应的地图坐标）
        ulX_file = 0.0
        ulY_file = 0.0
        ecSR.ConvertFileToMap, [ulX_file], [ulY_file], ulX_map, ulY_map
        CATCH, /CANCEL
        
        ; 获取像素大小
        pixelSize = ecSR.PIXEL_SIZE[0]
        
        ; 获取投影信息
        coordSysStr = ecSR.COORD_SYS_STR
        
        ; 解析UTM zone和datum
        utmZone = 51  ; 默认值
        datum = 'WGS84'
        
        ; 从COORD_SYS_STR中提取UTM zone
        zonePos = STRPOS(coordSysStr, 'UTM_Zone_')
        IF zonePos GE 0 THEN BEGIN
          zoneStart = zonePos + 9
          zoneEnd = STRPOS(STRMID(coordSysStr, zoneStart), 'N')
          IF zoneEnd GT 0 THEN BEGIN
            zoneStr = STRMID(coordSysStr, zoneStart, zoneEnd)
            utmZone = FIX(STRTRIM(zoneStr, 2))
          ENDIF
        ENDIF
        
        ; 检查datum
        IF STRPOS(coordSysStr, 'WGS_1984') GE 0 THEN BEGIN
          datum = 'WGS84'
        ENDIF
        
        ; 创建MAP_INFO
        exportMapInfo = ENVI_MAP_INFO_CREATE( $
          /UTM, $
          ZONE=utmZone, $
          /NORTH, $
          DATUM=datum, $
          MC=[0.0, 0.0, ulX_map[0], ulY_map[0]], $
          PS=[pixelSize, pixelSize] $
        )
        CATCH, /CANCEL
        
        IF exportMapInfo EQ !NULL THEN BEGIN
          PRINT, '  警告: 重新构建MAP_INFO失败，将尝试从原始raster获取'
        ENDIF
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
    
    ; 如果从ec_raster获取失败，尝试从原始raster获取
    IF exportMapInfo EQ !NULL THEN BEGIN
      CATCH, errGetMapInfoFromOriginal
      IF errGetMapInfoFromOriginal EQ 0 THEN BEGIN
        originalSR = raster.SPATIALREF
        CATCH, /CANCEL
        IF OBJ_VALID(originalSR) THEN BEGIN
          ; 获取左上角坐标
          ulX_file = 0.0
          ulY_file = 0.0
          originalSR.ConvertFileToMap, [ulX_file], [ulY_file], ulX_map, ulY_map
          CATCH, /CANCEL
          
          ; 获取像素大小
          pixelSize = originalSR.PIXEL_SIZE[0]
          
          ; 获取投影信息
          coordSysStr = originalSR.COORD_SYS_STR
          
          ; 解析UTM zone
          utmZone = 51  ; 默认值
          datum = 'WGS84'
          
          zonePos = STRPOS(coordSysStr, 'UTM_Zone_')
          IF zonePos GE 0 THEN BEGIN
            zoneStart = zonePos + 9
            zoneEnd = STRPOS(STRMID(coordSysStr, zoneStart), 'N')
            IF zoneEnd GT 0 THEN BEGIN
              zoneStr = STRMID(coordSysStr, zoneStart, zoneEnd)
              utmZone = FIX(STRTRIM(zoneStr, 2))
            ENDIF
          ENDIF
          
          ; 创建MAP_INFO
          exportMapInfo = ENVI_MAP_INFO_CREATE( $
            /UTM, $
            ZONE=utmZone, $
            /NORTH, $
            DATUM=datum, $
            MC=[0.0, 0.0, ulX_map[0], ulY_map[0]], $
            PS=[pixelSize, pixelSize] $
          )
          CATCH, /CANCEL
        ENDIF
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF
    
    IF exportMapInfo EQ !NULL THEN BEGIN
      PRINT, '  错误: 无法获取MAP_INFO，无法导出'
      errMsg = FILE_BASENAME(mtl_file) + ' --- 导出失败: 无法获取MAP_INFO'
      errMsgs = [errMsgs, errMsg]
      raster.Close
      ec_raster.Close
      CONTINUE
    ENDIF
    
    ; 保存结果 - 使用与landsat9_classification.pro相同的方法
    PRINT, '  正在保存结果...'
    
    ; 步骤1: 先导出到临时ENVI文件（使用多种方法容错，参考landsat9_classification.pro）
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
    tempBaseName = 'temp_ec_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
    tempFile = tempDirLocal + PATH_SEP() + tempBaseName
    IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
    hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
    
    ; 方法1: 直接使用Export方法
    exportSuccess = 0
    CATCH, errExport
    IF errExport EQ 0 THEN BEGIN
      ec_raster.Export, tempFile, 'ENVI'
      WAIT, 0.5
      IF FILE_TEST(tempFile) THEN BEGIN
        PRINT, '  ✓ 使用方法1（直接Export）成功导出到临时文件'
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
        ec_raster.Export, tempFile, 'ENVI'
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
        tempBaseName = 'temp_ec_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
        tempFile = tempDirLocal + PATH_SEP() + tempBaseName
        IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
        hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
        IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
        
        exportTask = ENVITask('RasterExport')
        exportTask.INPUT_RASTER = ec_raster
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
        tempBaseName = 'temp_ec_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
        tempFile = tempDirLocal + PATH_SEP() + tempBaseName
        IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
        hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
        IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
        
        exportTask2 = ENVITask('ExportRasterToENVI')
        exportTask2.INPUT_RASTER = ec_raster
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
      PRINT, '    1. 磁盘空间不足'
      PRINT, '    2. 文件权限问题'
      PRINT, '    3. 临时目录无法访问'
      errMsg = FILE_BASENAME(mtl_file) + ' --- 导出失败: 所有导出方法均失败'
      errMsgs = [errMsgs, errMsg]
      raster.Close
      ec_raster.Close
      CONTINUE
    ENDIF
    
    ; 步骤2: 使用ENVI_SETUP_HEAD设置空间参考信息到临时文件
    PRINT, '  正在设置空间参考信息到文件头...'
    CATCH, errSetup
    IF errSetup EQ 0 THEN BEGIN
      ENVI_OPEN_FILE, tempFile, r_fid=fid
      IF fid GE 0 THEN BEGIN
        ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=nb, data_type=dt, interleave=interleave
        ENVI_SETUP_HEAD, $
          FNAME=tempFile, $
          NS=ns, NL=nl, NB=nb, DATA_TYPE=dt, INTERLEAVE=interleave, $
          MAP_INFO=exportMapInfo, /WRITE, /OPEN
        ENVI_FILE_MNG, id=fid, /REMOVE
        CATCH, /CANCEL
        PRINT, '  ✓ 空间参考信息已写入文件头'
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  错误: 无法打开临时文件设置空间参考'
        errMsg = FILE_BASENAME(mtl_file) + ' --- 导出失败: 无法设置空间参考'
        errMsgs = [errMsgs, errMsg]
        raster.Close
        ec_raster.Close
        CONTINUE
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 设置空间参考时发生错误: ' + !ERROR_STATE.MSG
      errMsg = FILE_BASENAME(mtl_file) + ' --- 导出失败: ' + !ERROR_STATE.MSG
      errMsgs = [errMsgs, errMsg]
      raster.Close
      ec_raster.Close
      CONTINUE
    ENDELSE
    
    ; 步骤3: 从临时ENVI文件导出到最终格式
    WAIT, 0.5
    tempRaster = e.OpenRaster(tempFile)
    IF OBJ_VALID(tempRaster) THEN BEGIN
      ; 验证临时文件是否有空间参考
      tempSR = !NULL
      CATCH, errCheckTempSR
      IF errCheckTempSR EQ 0 THEN BEGIN
        tempSR = tempRaster.SPATIALREF
        CATCH, /CANCEL
        IF OBJ_VALID(tempSR) THEN BEGIN
          PRINT, '  ✓ 临时ENVI文件包含空间参考信息，准备导出到最终格式'
        ENDIF ELSE BEGIN
          PRINT, '  警告: 临时ENVI文件缺少空间参考信息'
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      
      ; 导出到最终格式（只支持ENVI格式，确保空间参考被保存）
      PRINT, '  注意: 只能保存为dat格式下才会有空间参考坐标系'
      CATCH, errExportFinal
      IF errExportFinal EQ 0 THEN BEGIN
        PRINT, '  正在从临时ENVI文件导出为ENVI...'
        tempRaster.Export, outfile, 'ENVI'
        ; 对于ENVI格式，再次使用ENVI_SETUP_HEAD确保MAP_INFO被写入
        WAIT, 0.5
        IF FILE_TEST(outfile) THEN BEGIN
          CATCH, errSetupFinal
          IF errSetupFinal EQ 0 THEN BEGIN
            ENVI_OPEN_FILE, outfile, r_fid=fidFinal
            IF fidFinal GE 0 THEN BEGIN
              ENVI_FILE_QUERY, fidFinal, ns=nsFinal, nl=nlFinal, nb=nbFinal, data_type=dtFinal, interleave=interleaveFinal
              ENVI_SETUP_HEAD, $
                FNAME=outfile, $
                NS=nsFinal, NL=nlFinal, NB=nbFinal, DATA_TYPE=dtFinal, INTERLEAVE=interleaveFinal, $
                MAP_INFO=exportMapInfo, /WRITE, /OPEN
              ENVI_FILE_MNG, id=fidFinal, /REMOVE
              CATCH, /CANCEL
              PRINT, '  ✓ ENVI格式文件的空间参考信息已确认写入'
            ENDIF
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
          ENDELSE
        ENDIF
        CATCH, /CANCEL
        tempRaster.Close
        WAIT, 1.0
        
        IF FILE_TEST(outfile) THEN BEGIN
          exportSuccess = 1B
          PRINT, '  ✓ 文件已保存'
        ENDIF ELSE BEGIN
          PRINT, '  错误: 从临时文件导出失败，文件不存在'
          errMsg = FILE_BASENAME(mtl_file) + ' --- 导出失败: 文件导出后不存在'
          errMsgs = [errMsgs, errMsg]
          raster.Close
          ec_raster.Close
          CONTINUE
        ENDELSE
        
        ; 删除临时文件
        IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
        IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  错误: 从临时文件导出失败: ' + !ERROR_STATE.MSG
        tempRaster.Close
        errMsg = FILE_BASENAME(mtl_file) + ' --- 导出失败: ' + !ERROR_STATE.MSG
        errMsgs = [errMsgs, errMsg]
        raster.Close
        ec_raster.Close
        CONTINUE
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '  错误: 无法打开临时文件导出'
      errMsg = FILE_BASENAME(mtl_file) + ' --- 导出失败: 无法打开临时文件'
      errMsgs = [errMsgs, errMsg]
      raster.Close
      ec_raster.Close
      CONTINUE
    ENDELSE
    
    ; 验证最终输出文件的空间参考
    IF exportSuccess THEN BEGIN
      WAIT, 1.0
      CATCH, errVerifyOutput
      IF errVerifyOutput EQ 0 THEN BEGIN
        outputRaster = e.OpenRaster(outfile)
        IF OBJ_VALID(outputRaster) THEN BEGIN
          outputSR = outputRaster.SPATIALREF
          IF OBJ_VALID(outputSR) THEN BEGIN
            PRINT, '  ✓ 输出文件包含空间参考信息'
          ENDIF ELSE BEGIN
            PRINT, '  警告: 输出文件缺少空间参考信息'
          ENDELSE
          outputRaster.Close
        ENDIF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF
    
    ; 旧代码已删除，使用上面的简化方法（与landsat9_classification.pro相同）
    
    IF exportSuccess THEN BEGIN
      PRINT, '  ✓ 文件已保存'
    ENDIF ELSE BEGIN
      PRINT, '  错误: 所有导出方法均失败'
      errMsg = FILE_BASENAME(mtl_file) + ' --- 导出失败: 所有方法均失败'
      errMsgs = [errMsgs, errMsg]
      raster.Close
      ec_raster.Close
      CONTINUE
    ENDELSE
    
    
    ; 添加到Data Manager
    DataColl.Add, ec_raster
    
    ; 关闭raster
    raster.Close
    ec_raster.Close
    
    success_count = success_count + 1
    PRINT, '  完成: ', FILE_BASENAME(outfile)
    PRINT, ''
  ENDFOR
  
  PRINT, '=========================================='
  PRINT, '批量处理完成！'
  PRINT, '成功处理: ', success_count, ' 个文件'
  IF errMsgs NE !NULL THEN BEGIN
    PRINT, '失败: ', N_ELEMENTS(errMsgs), ' 个文件'
    PRINT, ''
    PRINT, '错误信息:'
    FOR i=0, N_ELEMENTS(errMsgs)-1 DO BEGIN
      PRINT, '  ', errMsgs[i]
    ENDFOR
  ENDIF
  PRINT, '=========================================='
  
  ; 计算并显示影像之间的距离
  IF imageCenters.Count() GT 1 THEN BEGIN
    PRINT, ''
    PRINT, '=========================================='
    PRINT, '影像位置关系分析'
    PRINT, '=========================================='
    PRINT, ''
    
    FOR i=0, imageCenters.Count()-1 DO BEGIN
      info1 = imageCenters[i]
      lon1 = info1['lon']
      lat1 = info1['lat']
      name1 = info1['name']
      
      FOR j=i+1, imageCenters.Count()-1 DO BEGIN
        info2 = imageCenters[j]
        lon2 = info2['lon']
        lat2 = info2['lat']
        name2 = info2['name']
        
        ; 使用Haversine公式计算两点间距离（大圆距离）
        distance = calculate_distance_haversine(lon1, lat1, lon2, lat2)
        
        PRINT, '影像 ' + STRING(i+1) + ' vs 影像 ' + STRING(j+1) + ':'
        PRINT, '  影像1: ' + name1
        PRINT, '    中心点: (' + STRING(lon1, FORMAT='(F10.6)') + '°E, ' + STRING(lat1, FORMAT='(F10.6)') + '°N)'
        PRINT, '  影像2: ' + name2
        PRINT, '    中心点: (' + STRING(lon2, FORMAT='(F10.6)') + '°E, ' + STRING(lat2, FORMAT='(F10.6)') + '°N)'
        PRINT, '  直线距离: ' + STRING(distance, FORMAT='(F8.2)') + ' 公里'
        PRINT, ''
      ENDFOR
    ENDFOR
    PRINT, '=========================================='
  ENDIF
  
END

; 辅助函数：从MTL TXT文件中提取键值
FUNCTION extract_mtl_txt_value, txtLines, keyName, defaultValue
  COMPILE_OPT IDL2
  
  ; 参数：
  ;   txtLines: TXT文件行数组
  ;   keyName: 键名称（如 'CORNER_UL_PROJECTION_X_PRODUCT'）
  ;   defaultValue: 默认值（如果未找到）
  ; 返回值：提取的值（字符串），如果未找到返回默认值
  
  ; 改进的匹配逻辑：键名可能有缩进，等号前后可能有空格
  keyNameUpper = STRUPCASE(keyName)
  
  FOR i=0, N_ELEMENTS(txtLines)-1 DO BEGIN
    line = txtLines[i]
    lineTrimmed = STRTRIM(line, 2)  ; 先去除首尾空格
    lineUpper = STRUPCASE(lineTrimmed)
    
    ; 方法1: 查找 "KEY = VALUE" 格式（等号前后可能有空格）
    keyPos = STRPOS(lineUpper, keyNameUpper)
    IF keyPos GE 0 THEN BEGIN
      ; 检查键名后面是否有等号（可能有空格）
      afterKey = STRMID(lineTrimmed, keyPos + STRLEN(keyName))
      afterKey = STRTRIM(afterKey, 2)
      
      ; 如果以等号开头，说明找到了
      IF (STRLEN(afterKey) GT 0) AND (STRMID(afterKey, 0, 1) EQ '=') THEN BEGIN
        ; 提取等号后的值
        valueStr = STRMID(afterKey, 1)
        valueStr = STRTRIM(valueStr, 2)
        ; 移除可能的引号
        IF STRLEN(valueStr) GT 0 THEN BEGIN
          IF (STRMID(valueStr, 0, 1) EQ '"') AND (STRMID(valueStr, STRLEN(valueStr)-1, 1) EQ '"') THEN BEGIN
            valueStr = STRMID(valueStr, 1, STRLEN(valueStr)-2)
          ENDIF
          IF STRLEN(valueStr) GT 0 THEN RETURN, valueStr
        ENDIF
      ENDIF
    ENDIF
    
    ; 方法2: 直接查找包含键名和等号的行（更宽松的匹配）
    IF (STRPOS(lineUpper, keyNameUpper) GE 0) AND (STRPOS(lineUpper, '=') GE 0) THEN BEGIN
      ; 找到等号位置
      eqPos = STRPOS(lineTrimmed, '=')
      IF eqPos GT 0 THEN BEGIN
        ; 检查等号前是否是我们要找的键名
        beforeEq = STRTRIM(STRMID(lineTrimmed, 0, eqPos), 2)
        beforeEqUpper = STRUPCASE(beforeEq)
        IF STRMATCH(beforeEqUpper, '*' + keyNameUpper) THEN BEGIN
          ; 提取等号后的值
          valueStr = STRMID(lineTrimmed, eqPos+1)
          valueStr = STRTRIM(valueStr, 2)
          ; 移除可能的引号
          IF STRLEN(valueStr) GT 0 THEN BEGIN
            IF (STRMID(valueStr, 0, 1) EQ '"') AND (STRMID(valueStr, STRLEN(valueStr)-1, 1) EQ '"') THEN BEGIN
              valueStr = STRMID(valueStr, 1, STRLEN(valueStr)-2)
            ENDIF
            IF STRLEN(valueStr) GT 0 THEN RETURN, valueStr
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  ENDFOR
  
  RETURN, defaultValue
END

; 辅助函数：从XML文件中提取标签值
FUNCTION extract_xml_tag_value, xmlLines, tagName, defaultValue
  COMPILE_OPT IDL2
  
  ; 尝试多种可能的标签格式
  ; 1. 标准格式: <tagName>value</tagName>
  ; 2. 带命名空间: <eos:tagName>value</eos:tagName>
  ; 3. 带属性: <tagName attr="...">value</tagName>
  ; 4. 自闭合标签: <tagName value="..."/>
  
  tagNames = [tagName, 'eos:' + tagName, 'EOS:' + tagName]
  
  FOR tagIdx=0, N_ELEMENTS(tagNames)-1 DO BEGIN
    currentTag = tagNames[tagIdx]
    
    ; 方法1: 查找 <tag>value</tag> 格式
    tagStartTag = '<' + currentTag + '>'
    tagEndTag = '</' + currentTag + '>'
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
          IF STRLEN(valueStr) GT 0 THEN RETURN, valueStr
        ENDIF
      ENDIF
    ENDFOR
    
    ; 方法2: 查找 <tag attr="...">value</tag> 格式（标签有属性）
    tagStartPattern = '<' + currentTag
    tagEndTag = '</' + currentTag + '>'
    
    FOR i=0, N_ELEMENTS(xmlLines)-1 DO BEGIN
      line = xmlLines[i]
      lineUpper = STRUPCASE(line)
      tagStartPos = STRPOS(lineUpper, STRUPCASE(tagStartPattern))
      IF tagStartPos GE 0 THEN BEGIN
        ; 查找标签结束位置（>）
        tagEndPos = STRPOS(lineUpper, '>', tagStartPos)
        IF tagEndPos GT tagStartPos THEN BEGIN
          ; 查找对应的结束标签
          endTagPos = STRPOS(lineUpper, STRUPCASE(tagEndTag), tagEndPos)
          IF endTagPos GT tagEndPos THEN BEGIN
            valueStart = tagEndPos + 1
            valueEnd = endTagPos
            valueStr = STRMID(line, valueStart, valueEnd - valueStart)
            valueStr = STRTRIM(valueStr, 2)
            IF STRLEN(valueStr) GT 0 THEN RETURN, valueStr
          ENDIF
        ENDIF
      ENDIF
    ENDFOR
    
    ; 方法3: 查找自闭合标签 <tag value="..."/> 或 <tag>value</tag> 在同一行
    FOR i=0, N_ELEMENTS(xmlLines)-1 DO BEGIN
      line = xmlLines[i]
      lineUpper = STRUPCASE(line)
      tagStartPos = STRPOS(lineUpper, STRUPCASE('<' + currentTag))
      IF tagStartPos GE 0 THEN BEGIN
        ; 查找 value="..." 属性
        valueAttrPos = STRPOS(lineUpper, 'VALUE="', tagStartPos)
        IF valueAttrPos GT tagStartPos THEN BEGIN
          valueStart = valueAttrPos + 7  ; 跳过 'VALUE="'
          valueEnd = STRPOS(lineUpper, '"', valueStart)
          IF valueEnd GT valueStart THEN BEGIN
            valueStr = STRMID(line, valueStart, valueEnd - valueStart)
            valueStr = STRTRIM(valueStr, 2)
            IF STRLEN(valueStr) GT 0 THEN RETURN, valueStr
          ENDIF
        ENDIF
      ENDIF
    ENDFOR
  ENDFOR
  
  RETURN, defaultValue
END

; 辅助函数：从MTL TXT文件读取投影参数并创建空间参考
FUNCTION create_spatial_ref_from_mtl_txt, mtlTxtFile, nColumns, nRows
  COMPILE_OPT IDL2
  
  ; 检查文件是否存在
  IF ~FILE_TEST(mtlTxtFile) THEN BEGIN
    PRINT, '  错误: MTL TXT文件不存在: ' + mtlTxtFile
    RETURN, !NULL
  ENDIF
  
  ; 读取TXT文件内容
  CATCH, errOpen
  IF errOpen EQ 0 THEN BEGIN
    OPENR, lun, mtlTxtFile, /GET_LUN
    txtLines = STRARR(2000)
    lineCount = 0
    WHILE ~EOF(lun) && lineCount LT 2000 DO BEGIN
      READF, lun, txtLines[lineCount]
      lineCount++
    ENDWHILE
    CLOSE, lun
    FREE_LUN, lun
    txtLines = txtLines[0:lineCount-1]
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 无法打开MTL TXT文件: ' + mtlTxtFile + ' - ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  
  ; 解析TXT获取投影参数
  utmZone = 50
  datum = 'WGS84'
  pixelSize = 30.0
  ulX = 0.0
  ulY = 0.0
  
  ; 提取DATUM
  datumStr = extract_mtl_txt_value(txtLines, 'DATUM', 'WGS84')
  IF STRMATCH(datumStr, '*WGS84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE BEGIN
    datum = datumStr
  ENDELSE
  
  ; 提取UTM_ZONE
  zoneStr = extract_mtl_txt_value(txtLines, 'UTM_ZONE', '50')
  IF STRLEN(zoneStr) GT 0 THEN utmZone = FIX(STRTRIM(zoneStr, 2))
  
  ; 提取GRID_CELL_SIZE_REFLECTIVE
  psStr = extract_mtl_txt_value(txtLines, 'GRID_CELL_SIZE_REFLECTIVE', '30.0')
  IF STRLEN(psStr) GT 0 THEN pixelSize = FLOAT(STRTRIM(psStr, 2))
  
  ; 提取四角投影坐标
  PRINT, '  正在提取坐标信息...'
  ulXStr = extract_mtl_txt_value(txtLines, 'CORNER_UL_PROJECTION_X_PRODUCT', '')
  IF STRLEN(ulXStr) GT 0 THEN BEGIN
    ulX = FLOAT(STRTRIM(ulXStr, 2))
    PRINT, '  ✓ 读取到左上角X坐标: ' + STRING(ulX, FORMAT='(F12.2)') + ' (原始字符串: "' + ulXStr + '")'
  ENDIF ELSE BEGIN
    PRINT, '  警告: 未找到 CORNER_UL_PROJECTION_X_PRODUCT'
  ENDELSE
  
  ulYStr = extract_mtl_txt_value(txtLines, 'CORNER_UL_PROJECTION_Y_PRODUCT', '')
  IF STRLEN(ulYStr) GT 0 THEN BEGIN
    ulY = FLOAT(STRTRIM(ulYStr, 2))
    PRINT, '  ✓ 读取到左上角Y坐标: ' + STRING(ulY, FORMAT='(F12.2)') + ' (原始字符串: "' + ulYStr + '")'
  ENDIF ELSE BEGIN
    PRINT, '  警告: 未找到 CORNER_UL_PROJECTION_Y_PRODUCT'
  ENDELSE
  
  ; 从四角坐标计算像元大小（更准确）
  urXStr = extract_mtl_txt_value(txtLines, 'CORNER_UR_PROJECTION_X_PRODUCT', '')
  llYStr = extract_mtl_txt_value(txtLines, 'CORNER_LL_PROJECTION_Y_PRODUCT', '')
  IF (STRLEN(urXStr) GT 0) AND (STRLEN(llYStr) GT 0) AND (nColumns GT 1) AND (nRows GT 1) THEN BEGIN
    urX = FLOAT(STRTRIM(urXStr, 2))
    llY = FLOAT(STRTRIM(llYStr, 2))
    pixelSizeX = ABS(urX - ulX) / FLOAT(nColumns - 1)
    pixelSizeY = ABS(ulY - llY) / FLOAT(nRows - 1)
    pixelSize = (pixelSizeX + pixelSizeY) / 2.0
    PRINT, '  从四角坐标计算像元大小: ' + STRING(pixelSize, FORMAT='(F6.2)') + ' 米'
  ENDIF
  
  ; 创建MAP_INFO结构（使用ENVI_MAP_INFO_CREATE函数）
  PRINT, '  正在创建MAP_INFO结构体...'
  mapInfo = !NULL
  CATCH, errMapInfo
  IF errMapInfo EQ 0 THEN BEGIN
    mapInfo = ENVI_MAP_INFO_CREATE( $
      /UTM, $
      ZONE=utmZone, $
      /NORTH, $
      DATUM=datum, $
      MC=[0.0, 0.0, ulX, ulY], $  ; Map coordinates of pixel (0,0) - 使用投影坐标
      PS=[pixelSize, pixelSize] $  ; Pixel size in meters
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
    PRINT, '    左上角投影坐标: (' + STRING(ulX, FORMAT='(F12.2)') + ', ' + STRING(ulY, FORMAT='(F12.2)') + ') 米'
    PRINT, '    像元大小: ' + STRING(pixelSize, FORMAT='(F6.2)') + ' 米'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 创建MAP_INFO时发生异常: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  
  RETURN, mapInfo
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
  ulX = 0.0
  ulY = 0.0
  
  ; 提取DATUM
  datumStr = extract_xml_tag_value(xmlLines, 'DATUM', 'WGS84')
  IF STRMATCH(datumStr, '*WGS84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE BEGIN
    datum = datumStr
  ENDELSE
  
  ; 提取UTM_ZONE
  zoneStr = extract_xml_tag_value(xmlLines, 'UTM_ZONE', '50')
  IF STRLEN(zoneStr) GT 0 THEN utmZone = FIX(STRTRIM(zoneStr, 2))
  
  ; 提取GRID_CELL_SIZE_REFLECTIVE
  psStr = extract_xml_tag_value(xmlLines, 'GRID_CELL_SIZE_REFLECTIVE', '30.0')
  IF STRLEN(psStr) GT 0 THEN pixelSize = FLOAT(STRTRIM(psStr, 2))
  
  ; 提取四角投影坐标
  ; 尝试多种可能的标签格式
  PRINT, '  正在搜索坐标标签...'
  
  ; 方法1: 标准格式 CORNER_UL_PROJECTION_X_PRODUCT
  ulXStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_PROJECTION_X_PRODUCT', '')
  IF STRLEN(ulXStr) GT 0 THEN BEGIN
    ulX = FLOAT(STRTRIM(ulXStr, 2))
    PRINT, '  ✓ 读取到左上角X坐标: ' + STRING(ulX, FORMAT='(F12.2)')
  ENDIF
  
  ulYStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_PROJECTION_Y_PRODUCT', '')
  IF STRLEN(ulYStr) GT 0 THEN BEGIN
    ulY = FLOAT(STRTRIM(ulYStr, 2))
    PRINT, '  ✓ 读取到左上角Y坐标: ' + STRING(ulY, FORMAT='(F12.2)')
  ENDIF
  
  ; 方法2: 如果未找到，尝试直接搜索包含坐标的行（更灵活的方法）
  IF (ulX EQ 0.0) OR (ulY EQ 0.0) THEN BEGIN
    PRINT, '  尝试直接搜索包含坐标的行...'
    FOR i=0, N_ELEMENTS(xmlLines)-1 DO BEGIN
      line = xmlLines[i]
      lineUpper = STRUPCASE(line)
      
      ; 搜索包含 CORNER_UL_PROJECTION_X 的行
      IF (ulX EQ 0.0) AND (STRPOS(lineUpper, 'CORNER_UL_PROJECTION_X') GE 0) THEN BEGIN
        ; 尝试提取数值（查找数字）
        ; 查找 >数字< 或 "数字" 或 =数字
        numStart = STRPOS(lineUpper, '>')
        IF numStart GE 0 THEN BEGIN
          numEnd = STRPOS(lineUpper, '<', numStart+1)
          IF numEnd GT numStart THEN BEGIN
            numStr = STRMID(line, numStart+1, numEnd-numStart-1)
            numStr = STRTRIM(numStr, 2)
            IF STRLEN(numStr) GT 0 THEN BEGIN
              ulX = FLOAT(numStr)
              IF ulX NE 0.0 THEN BEGIN
                PRINT, '  ✓ 从行中提取到左上角X坐标: ' + STRING(ulX, FORMAT='(F12.2)')
              ENDIF
            ENDIF
          ENDIF
        ENDIF
      ENDIF
      
      ; 搜索包含 CORNER_UL_PROJECTION_Y 的行
      IF (ulY EQ 0.0) AND (STRPOS(lineUpper, 'CORNER_UL_PROJECTION_Y') GE 0) THEN BEGIN
        numStart = STRPOS(lineUpper, '>')
        IF numStart GE 0 THEN BEGIN
          numEnd = STRPOS(lineUpper, '<', numStart+1)
          IF numEnd GT numStart THEN BEGIN
            numStr = STRMID(line, numStart+1, numEnd-numStart-1)
            numStr = STRTRIM(numStr, 2)
            IF STRLEN(numStr) GT 0 THEN BEGIN
              ulY = FLOAT(numStr)
              IF ulY NE 0.0 THEN BEGIN
                PRINT, '  ✓ 从行中提取到左上角Y坐标: ' + STRING(ulY, FORMAT='(F12.2)')
              ENDIF
            ENDIF
          ENDIF
        ENDIF
      ENDIF
      
      ; 如果两个坐标都找到了，可以提前退出
      IF (ulX NE 0.0) AND (ulY NE 0.0) THEN BREAK
    ENDFOR
  ENDIF
  
  ; 如果仍然未找到，打印前几行XML内容用于调试
  IF (ulX EQ 0.0) OR (ulY EQ 0.0) THEN BEGIN
    PRINT, '  警告: 无法读取坐标，打印XML文件前10行用于调试:'
    nXmlLines = N_ELEMENTS(xmlLines)
    IF nXmlLines GT 0 THEN BEGIN
      ; IDL 的 MIN 对标量参数有副作用，这里手动计算上限，避免“Attempt to store into an expression”错误
      maxLines = LONG(nXmlLines) - 1L
      IF maxLines GT 9L THEN maxLines = 9L
      IF maxLines GE 0 THEN BEGIN
        FOR i=0, maxLines DO BEGIN
          PRINT, '    行' + STRING(i+1) + ': ' + STRTRIM(xmlLines[i], 2)
        ENDFOR
      ENDIF ELSE BEGIN
        PRINT, '    错误: XML文件为空'
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '    错误: 无法读取XML文件内容'
    ENDELSE
  ENDIF
  
  ; 从四角坐标计算像元大小（更准确）
  urXStr = extract_xml_tag_value(xmlLines, 'CORNER_UR_PROJECTION_X_PRODUCT', '')
  llYStr = extract_xml_tag_value(xmlLines, 'CORNER_LL_PROJECTION_Y_PRODUCT', '')
  IF (STRLEN(urXStr) GT 0) AND (STRLEN(llYStr) GT 0) AND (nColumns GT 1) AND (nRows GT 1) THEN BEGIN
    urX = FLOAT(STRTRIM(urXStr, 2))
    llY = FLOAT(STRTRIM(llYStr, 2))
    pixelSizeX = ABS(urX - ulX) / FLOAT(nColumns - 1)
    pixelSizeY = ABS(ulY - llY) / FLOAT(nRows - 1)
    pixelSize = (pixelSizeX + pixelSizeY) / 2.0
    PRINT, '  从四角坐标计算像元大小: ' + STRING(pixelSize, FORMAT='(F6.2)') + ' 米'
  ENDIF
  
  ; 创建MAP_INFO结构（使用ENVI_MAP_INFO_CREATE函数）
  PRINT, '  正在创建MAP_INFO结构体...'
  mapInfo = !NULL
  CATCH, errMapInfo
  IF errMapInfo EQ 0 THEN BEGIN
    mapInfo = ENVI_MAP_INFO_CREATE( $
      /UTM, $
      ZONE=utmZone, $
      /NORTH, $
      DATUM=datum, $
      MC=[0.0, 0.0, ulX, ulY], $  ; Map coordinates of pixel (0,0) - 使用投影坐标
      PS=[pixelSize, pixelSize] $  ; Pixel size in meters
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
    PRINT, '    左上角投影坐标: (' + STRING(ulX, FORMAT='(F12.2)') + ', ' + STRING(ulY, FORMAT='(F12.2)') + ') 米'
    PRINT, '    像元大小: ' + STRING(pixelSize, FORMAT='(F6.2)') + ' 米'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 创建MAP_INFO时发生异常: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  
  RETURN, mapInfo
END

; 辅助函数：为raster设置空间参考
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
    FILE_DELETE, tempFile, /QUIET
    hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
    IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
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

; 辅助函数：设置raster的data ignore value
FUNCTION set_data_ignore_value_to_raster, input_raster, ignore_value
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  IF ~OBJ_VALID(input_raster) THEN BEGIN
    RETURN, input_raster
  ENDIF
  
  ; 使用ENVI的SetDataIgnoreValue方法
  CATCH, errSet
  IF errSet EQ 0 THEN BEGIN
    input_raster.SetDataIgnoreValue, ignore_value
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    ; 如果方法不存在，尝试其他方式
    PRINT, '  警告: 无法直接设置data ignore value'
  ENDELSE
  
  RETURN, input_raster
END

; 辅助函数：从 GeoTIFF 文件中读取空间参考信息，并创建 ENVI MAP_INFO 结构
; 功能  : 从 GeoTIFF 文件中读取空间参考信息，并创建 ENVI MAP_INFO 结构
;         用于后续设置到 ENVIRaster 对象
; 输入  : geotiffFile - GeoTIFF 文件路径（SR_B3 或 SR_B4）
; 输出  : mapInfo - ENVI MAP_INFO 结构体，如果失败返回 !NULL
; 说明  : 优先使用方法2（ENVI_OPEN_DATA_FILE），如果失败则使用方法1（READ_TIFF）
;         参考: test_1204_geotiff_spatial_ref/1204_create_map_info_from_geotiff.pro
; 日期  : 2024-12-04
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

; 辅助函数：使用Haversine公式计算两点间的大圆距离（公里）
; 输入: lon1, lat1 - 第一点的经纬度（度）
;       lon2, lat2 - 第二点的经纬度（度）
; 输出: 距离（公里）
FUNCTION calculate_distance_haversine, lon1, lat1, lon2, lat2
  COMPILE_OPT IDL2
  
  ; 地球半径（公里）
  R = 6371.0
  
  ; 转换为弧度
  lat1_rad = lat1 * !DTOR
  lat2_rad = lat2 * !DTOR
  dlat_rad = (lat2 - lat1) * !DTOR
  dlon_rad = (lon2 - lon1) * !DTOR
  
  ; Haversine公式
  a = SIN(dlat_rad/2.0)^2 + COS(lat1_rad) * COS(lat2_rad) * SIN(dlon_rad/2.0)^2
  c = 2.0 * ATAN(SQRT(a), SQRT(1.0 - a))
  distance = R * c
  
  RETURN, distance
END

