;+
; 程序名: 1206_mosaic_rasters.pro
; 功能: 镶嵌多个影像（自动处理不同投影系统和缺少空间参考的情况）
; 输入: 多个影像文件（可多选）
; 输出: 镶嵌后的影像（保存到指定输出目录）
; 说明: 
;   - 自动检测投影系统，如果不同则重投影到第一个影像的投影系统
;   - 如果影像缺少空间参考，自动从同目录下的SR_B3或SR_B4文件读取
; 依赖: 需要1206_batch_soil_EC.pro中的create_map_info_from_geotiff和set_spatial_ref_to_raster函数
; 作者: Auto
; 日期: 2024-12-04
;-

PRO mosaic_rasters
  COMPILE_OPT IDL2
  
  ; 确保依赖的函数已编译（从batch_soil_EC.pro）
  ; 如果函数不存在，尝试编译batch_soil_EC.pro
  ; 使用CATCH来检查函数是否存在
  ; 确保依赖的函数已编译（从batch_soil_EC.pro）
  ; 直接尝试编译batch_soil_EC.pro（如果函数不存在会自动编译）
  batchECFile = FILE_DIRNAME(ROUTINE_FILEPATH()) + PATH_SEP() + '1206_batch_soil_EC.pro'
  IF FILE_TEST(batchECFile) THEN BEGIN
    ; 尝试编译，如果已经编译过也不会报错
    CATCH, errCompile
    IF errCompile EQ 0 THEN BEGIN
      COMPILE, batchECFile
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      ; 编译失败或已经编译过，继续执行
    ENDELSE
  ENDIF
  
  ; 启动ENVI
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()
  
  PRINT, '=========================================='
  PRINT, '影像镶嵌工具（支持不同投影系统）'
  PRINT, '=========================================='
  PRINT, ''
  
  ; 步骤1：选择输入文件（可多选）
  PRINT, '步骤1：选择要镶嵌的影像文件（可多选）...'
  files = ENVI_PICKFILE(TITLE='请选择要镶嵌的影像文件（可多选）', $
    /MULTIPLE_FILES, $
    FILTER=['*.tif', '*.TIF', '*.dat', '*.DAT', '*.*'])
  
  IF (files[0] EQ '') OR (N_ELEMENTS(files) EQ 0) THEN BEGIN
    PRINT, '未选择文件，退出。'
    RETURN
  ENDIF
  
  n_files = N_ELEMENTS(files)
  PRINT, '已选择 ', n_files, ' 个文件'
  PRINT, ''
  
  IF n_files LT 2 THEN BEGIN
    PRINT, '错误: 至少需要2个文件才能进行镶嵌'
    RETURN
  ENDIF
  
  ; 步骤2：选择输出目录和文件名
  PRINT, '步骤2：选择输出目录和文件名...'
  outdir = ENVI_PICKFILE(/OUTPUT, /DIRECTORY, TITLE='请选择输出目录')
  IF outdir EQ '' THEN BEGIN
    PRINT, '未选择输出目录，退出。'
    RETURN
  ENDIF
  PRINT, '输出目录: ', outdir
  PRINT, ''
  
  ; 固定使用ENVI格式
  PRINT, '注意: 只能保存为ENVI格式(.dat)才能确保空间参考坐标系被正确保存'
  PRINT, '      TIFF格式可能丢失空间参考信息，因此已禁用TIFF格式输出'
  PRINT, ''
  output_format = '.dat'
  PRINT, '输出格式: ENVI格式 (.dat)'
  PRINT, '提示: 只能保存为dat格式下才会有空间参考坐标系'
  PRINT, ''
  
  ; 生成输出文件名（使用默认名称，基于第一个输入文件名）
  default_name = 'mosaic_result'
  IF n_files GT 0 THEN BEGIN
    ; 尝试从第一个文件名提取基础名称
    first_file = files[0]
    first_basename = FILE_BASENAME(first_file, STRMID(first_file, STRPOS(first_file, '.', /REVERSE_SEARCH)))
    ; 移除可能的特殊字符，只保留字母、数字、下划线和连字符
    clean_basename = ''
    FOR k=0, STRLEN(first_basename)-1 DO BEGIN
      char = STRMID(first_basename, k, 1)
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
    IF STRLEN(clean_basename) GT 0 THEN BEGIN
      default_name = clean_basename + '_mosaic'
    ENDIF
  ENDIF
  
  output_name = default_name
  PRINT, '输出文件名: ' + output_name + output_format
  PRINT, '（提示: 如需修改文件名，请编辑代码中的 default_name 变量）'
  PRINT, ''
  
  ; 生成完整输出路径（固定使用ENVI格式）
  outfile = FILEPATH(output_name + '.dat', root_dir=outdir)
  
  ; 删除已存在的输出文件
  IF FILE_TEST(outfile) THEN BEGIN
    PRINT, '检测到已存在的输出文件，正在删除...'
    FILE_DELETE, outfile, /QUIET, /ALLOW_NONEXISTENT
    hdr_file = FILE_DIRNAME(outfile) + PATH_SEP() + FILE_BASENAME(outfile, '.dat') + '.hdr'
    IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
  ENDIF
  PRINT, ''
  
  ; 步骤3：打开所有影像并检查投影信息
  PRINT, '步骤3：打开影像并检查投影信息...'
  PRINT, '=========================================='
  
  rasters = LIST()
  projections = LIST()
  needReproject = 0B
  
  FOR i=0, n_files-1 DO BEGIN
    file = files[i]
    PRINT, '处理文件 ', i+1, '/', n_files, ': ', FILE_BASENAME(file)
    
    CATCH, errOpen
    IF errOpen EQ 0 THEN BEGIN
      raster = e.OpenRaster(file)
      CATCH, /CANCEL
      
      IF ~OBJ_VALID(raster) THEN BEGIN
        PRINT, '  错误: 无法打开文件'
        CONTINUE
      ENDIF
      
      ; 检查空间参考
      spatialRef = !NULL
      CATCH, errSR
      IF errSR EQ 0 THEN BEGIN
        spatialRef = raster.SPATIALREF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
      
      IF OBJ_VALID(spatialRef) THEN BEGIN
        coordSysStr = spatialRef.COORD_SYS_STR
        coordSysLen = STRLEN(coordSysStr)
        coordSysDisplayLen = MIN(60, coordSysLen)
        PRINT, '  ✓ 投影系统: ' + STRMID(coordSysStr, 0, coordSysDisplayLen)
        projections.Add, coordSysStr
        
        ; 检查是否需要重投影（与第一个影像比较）
        IF i GT 0 THEN BEGIN
          firstCoordSys = projections[0]
          IF coordSysStr NE firstCoordSys THEN BEGIN
            needReproject = 1B
            PRINT, '  警告: 投影系统与第一个影像不同，将进行重投影'
          ENDIF
        ENDIF
      ENDIF ELSE BEGIN
        PRINT, '  警告: 文件缺少空间参考信息，正在尝试从GeoTIFF文件读取...'
        
        ; 尝试从同目录下的SR_B3或SR_B4文件读取空间参考
        fileDir = FILE_DIRNAME(file)
        fileBase = FILE_BASENAME(file, STRMID(file, STRPOS(file, '.', /REVERSE_SEARCH)))
        
        ; 查找对应的SR_B3或SR_B4文件
        ; 尝试从文件名中提取Landsat场景ID
        ; 例如: LC08_L2SP_118029_20190102_20200829_02_T1_MTL_EC.tif
        ; 对应的SR_B3文件可能是: LC08_L2SP_118029_20190102_20200829_02_T1_SR_B3.TIF
        
        ; 尝试多种可能的文件名模式
        ; 手动实现字符串替换（因为STRREPLACE可能不可用）
        fileBaseNoEC = fileBase
        posEC = STRPOS(fileBase, '_EC')
        IF posEC GE 0 THEN BEGIN
          fileBaseNoEC = STRMID(fileBase, 0, posEC) + STRMID(fileBase, posEC+3)
        ENDIF
        
        fileBaseNoMTLEC = fileBase
        posMTLEC = STRPOS(fileBase, '_MTL_EC')
        IF posMTLEC GE 0 THEN BEGIN
          fileBaseNoMTLEC = STRMID(fileBase, 0, posMTLEC) + STRMID(fileBase, posMTLEC+7)
        ENDIF
        
        possiblePatterns = [fileBase, fileBaseNoEC, fileBaseNoMTLEC]
        geotiffFile = ''
        
        FOR p=0, N_ELEMENTS(possiblePatterns)-1 DO BEGIN
          pattern = possiblePatterns[p]
          ; 移除可能的_EC后缀
          IF STRMATCH(pattern, '*_EC') THEN BEGIN
            posEC2 = STRPOS(pattern, '_EC')
            IF posEC2 GE 0 THEN BEGIN
              pattern = STRMID(pattern, 0, posEC2) + STRMID(pattern, posEC2+3)
            ENDIF
          ENDIF
          
          ; 查找SR_B3文件
          srB3Files = FILE_SEARCH(fileDir, pattern + '*_SR_B3.TIF', COUNT=countB3)
          IF countB3 GT 0 THEN BEGIN
            geotiffFile = srB3Files[0]
            BREAK
          ENDIF
          
          ; 查找SR_B4文件
          srB4Files = FILE_SEARCH(fileDir, pattern + '*_SR_B4.TIF', COUNT=countB4)
          IF countB4 GT 0 THEN BEGIN
            geotiffFile = srB4Files[0]
            BREAK
          ENDIF
        ENDFOR
        
        ; 如果没找到，尝试更通用的搜索
        IF geotiffFile EQ '' THEN BEGIN
          srB3Files = FILE_SEARCH(fileDir, '*_SR_B3.TIF', COUNT=countB3)
          IF countB3 GT 0 THEN geotiffFile = srB3Files[0]
        ENDIF
        
        IF geotiffFile EQ '' THEN BEGIN
          srB4Files = FILE_SEARCH(fileDir, '*_SR_B4.TIF', COUNT=countB4)
          IF countB4 GT 0 THEN geotiffFile = srB4Files[0]
        ENDIF
        
        IF (geotiffFile NE '') AND FILE_TEST(geotiffFile) THEN BEGIN
          PRINT, '  找到GeoTIFF文件: ' + FILE_BASENAME(geotiffFile)
          
          ; 使用create_map_info_from_geotiff函数创建MAP_INFO
          mapInfo = create_map_info_from_geotiff(geotiffFile)
          
          IF mapInfo NE !NULL THEN BEGIN
            ; 使用set_spatial_ref_to_raster函数设置空间参考
            rasterWithSR = set_spatial_ref_to_raster(raster, mapInfo)
            IF OBJ_VALID(rasterWithSR) THEN BEGIN
              raster.Close
              raster = rasterWithSR
              
              ; 再次检查空间参考
              CATCH, errCheckSR
              IF errCheckSR EQ 0 THEN BEGIN
                spatialRef = raster.SPATIALREF
                CATCH, /CANCEL
                IF OBJ_VALID(spatialRef) THEN BEGIN
                  coordSysStr = spatialRef.COORD_SYS_STR
                  PRINT, '  ✓ 成功设置空间参考信息'
                  coordSysLen2 = STRLEN(coordSysStr)
                  coordSysDisplayLen2 = MIN(60, coordSysLen2)
                  PRINT, '  投影系统: ' + STRMID(coordSysStr, 0, coordSysDisplayLen2)
                  projections.Add, coordSysStr
                  
                  ; 检查是否需要重投影
                  IF i GT 0 THEN BEGIN
                    firstCoordSys = projections[0]
                    IF coordSysStr NE firstCoordSys THEN BEGIN
                      needReproject = 1B
                      PRINT, '  警告: 投影系统与第一个影像不同，将进行重投影'
                    ENDIF
                  ENDIF
                ENDIF ELSE BEGIN
                  PRINT, '  错误: 设置空间参考后仍然无效'
                  projections.Add, ''
                ENDELSE
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
                PRINT, '  错误: 验证空间参考时发生错误'
                projections.Add, ''
              ENDELSE
            ENDIF ELSE BEGIN
              PRINT, '  错误: 设置空间参考失败'
              projections.Add, ''
            ENDELSE
          ENDIF ELSE BEGIN
            PRINT, '  错误: 无法从GeoTIFF文件创建空间参考信息'
            projections.Add, ''
          ENDELSE
        ENDIF ELSE BEGIN
          PRINT, '  错误: 未找到对应的GeoTIFF文件（SR_B3或SR_B4）'
          PRINT, '  提示: 请确保GeoTIFF文件与输入文件在同一目录下'
          projections.Add, ''
        ENDELSE
      ENDELSE
      
      rasters.Add, raster
      PRINT, '  ✓ 成功打开，尺寸: ', raster.NCOLUMNS, ' x ', raster.NROWS, ', 波段数: ', raster.NBANDS
      PRINT, ''
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 打开文件失败: ' + !ERROR_STATE.MSG
      PRINT, ''
    ENDELSE
  ENDFOR
  
  IF rasters.Count() LT 2 THEN BEGIN
    PRINT, '错误: 成功打开的影像少于2个，无法进行镶嵌'
    FOREACH r, rasters DO r.Close
    RETURN
  ENDIF
  
  PRINT, '=========================================='
  PRINT, ''
  
  ; 步骤4：如果需要，进行重投影
  IF needReproject THEN BEGIN
    PRINT, '步骤4：重投影影像到统一投影系统...'
    PRINT, '=========================================='
    
    ; 使用第一个影像的投影系统作为目标投影
    firstRaster = rasters[0]
    firstSR = firstRaster.SPATIALREF
    targetCoordSys = ENVICoordSys(COORD_SYS_STR=firstSR.COORD_SYS_STR)
    
    PRINT, '目标投影系统: ' + STRMID(firstSR.COORD_SYS_STR, 0, MIN(60, STRLEN(firstSR.COORD_SYS_STR)))
    PRINT, ''
    
    reprojectedRasters = LIST()
    reprojectedRasters.Add, firstRaster  ; 第一个影像不需要重投影
    
    FOR i=1, rasters.Count()-1 DO BEGIN
      raster = rasters[i]
      PRINT, '重投影影像 ', i+1, '/', rasters.Count()-1, ': ', FILE_BASENAME(files[i])
      
      CATCH, errReproject
      IF errReproject EQ 0 THEN BEGIN
        ; 使用ENVIReprojectRaster进行重投影
        reprojectedRaster = ENVIReprojectRaster(raster, COORD_SYS=targetCoordSys, $
          RESAMPLING='Bilinear', PIXEL_SIZE=firstSR.PIXEL_SIZE)
        CATCH, /CANCEL
        
        IF OBJ_VALID(reprojectedRaster) THEN BEGIN
          reprojectedRasters.Add, reprojectedRaster
          PRINT, '  ✓ 重投影完成，新尺寸: ', reprojectedRaster.NCOLUMNS, ' x ', reprojectedRaster.NROWS
          PRINT, ''
        ENDIF ELSE BEGIN
          PRINT, '  错误: 重投影失败'
          PRINT, ''
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  错误: 重投影时发生错误: ' + !ERROR_STATE.MSG
        PRINT, ''
      ENDELSE
    ENDFOR
    
    ; 关闭原始影像（第一个除外，因为已经添加到reprojectedRasters）
    FOR i=1, rasters.Count()-1 DO BEGIN
      rasters[i].Close
    ENDFOR
    
    ; 使用重投影后的影像列表
    rasters = reprojectedRasters
    
    PRINT, '=========================================='
    PRINT, ''
  ENDIF ELSE BEGIN
    PRINT, '步骤4：所有影像使用相同的投影系统，无需重投影'
    PRINT, ''
  ENDELSE
  
  ; 步骤5：验证所有影像都有空间参考
  PRINT, '步骤5：验证空间参考信息...'
  PRINT, '=========================================='
  
  allHaveSR = 1B
  FOR i=0, rasters.Count()-1 DO BEGIN
    raster = rasters[i]
    spatialRef = !NULL
    CATCH, errCheck
    IF errCheck EQ 0 THEN BEGIN
      spatialRef = raster.SPATIALREF
      CATCH, /CANCEL
      IF ~OBJ_VALID(spatialRef) THEN BEGIN
        PRINT, '  错误: 影像 ', i+1, ' 仍然缺少空间参考信息'
        allHaveSR = 0B
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      allHaveSR = 0B
    ENDELSE
  ENDFOR
  
  IF ~allHaveSR THEN BEGIN
    PRINT, '  错误: 部分影像缺少空间参考信息，无法进行镶嵌'
    PRINT, '  提示: 请确保所有影像都有有效的空间参考信息'
    PRINT, '  或者确保同目录下有对应的SR_B3或SR_B4文件'
    FOREACH r, rasters DO BEGIN
      IF OBJ_VALID(r) THEN r.Close
    ENDFOREACH
    RETURN
  ENDIF
  
  PRINT, '  ✓ 所有影像都有有效的空间参考信息'
  PRINT, ''
  PRINT, '=========================================='
  PRINT, ''
  
  ; 步骤6：检查并统一data ignore value
  PRINT, '步骤6：检查data ignore value...'
  PRINT, '=========================================='
  
  ; 检查所有输入raster的data ignore value
  commonIgnoreValue = !NULL
  hasIgnoreValue = 0B
  FOR i=0, rasters.Count()-1 DO BEGIN
    raster = rasters[i]
    IF OBJ_VALID(raster) THEN BEGIN
      CATCH, errCheckDIV
      IF errCheckDIV EQ 0 THEN BEGIN
        IF raster.METADATA.HasTag('data ignore value') THEN BEGIN
          ignoreValue = raster.METADATA['data ignore value']
          IF N_ELEMENTS(ignoreValue) GT 0 THEN BEGIN
            currentIgnoreValue = ignoreValue[0]
            IF commonIgnoreValue EQ !NULL THEN BEGIN
              commonIgnoreValue = currentIgnoreValue
              hasIgnoreValue = 1B
              PRINT, '  检测到data ignore value: ' + STRING(commonIgnoreValue)
            ENDIF ELSE BEGIN
              IF currentIgnoreValue NE commonIgnoreValue THEN BEGIN
                PRINT, '  警告: 不同影像的data ignore value不一致，将使用第一个值: ' + STRING(commonIgnoreValue)
              ENDIF
            ENDELSE
          ENDIF
        ENDIF
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF
  ENDFOR
  
  ; 如果没有检测到data ignore value，使用默认值0.1（EC计算中的b系数，对应背景/黑边）
  IF ~hasIgnoreValue THEN BEGIN
    commonIgnoreValue = 0.1
    PRINT, '  未检测到data ignore value，将使用默认值: 0.1'
    PRINT, '  提示: 镶嵌时将忽略值为0.1的像元（背景/黑边，对应EC公式中的b系数）'
  ENDIF
  PRINT, ''
  
  ; 确保所有输入raster都有data ignore value设置
  PRINT, '  正在为所有输入影像设置data ignore value...'
  FOR i=0, rasters.Count()-1 DO BEGIN
    raster = rasters[i]
    IF OBJ_VALID(raster) THEN BEGIN
      CATCH, errSetInputDIV
      IF errSetInputDIV EQ 0 THEN BEGIN
        IF raster.METADATA.HasTag('data ignore value') THEN BEGIN
          raster.METADATA.UpdateItem, 'data ignore value', commonIgnoreValue
        ENDIF ELSE BEGIN
          raster.METADATA.AddItem, 'data ignore value', commonIgnoreValue
        ENDELSE
        raster.WriteMetadata
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF
  ENDFOR
  PRINT, '  ✓ 所有输入影像已设置data ignore value: ' + STRING(commonIgnoreValue)
  PRINT, ''
  
  ; 步骤7：执行镶嵌
  PRINT, '步骤7：执行影像镶嵌...'
  PRINT, '=========================================='
  
  ; 将LIST转换为数组
  rasterArray = OBJARR(rasters.Count())
  FOR i=0, rasters.Count()-1 DO BEGIN
    rasterArray[i] = rasters[i]
  ENDFOR
  
  CATCH, errMosaic
  IF errMosaic EQ 0 THEN BEGIN
    ; 使用ENVIMosaicRaster进行镶嵌
    PRINT, '正在创建镶嵌影像...'
    PRINT, '  设置data ignore value: ' + STRING(commonIgnoreValue) + '（将忽略背景/黑边）'
    mosaicRaster = ENVIMosaicRaster(rasterArray)
    
    ; 设置镶嵌后的data ignore value
    IF hasIgnoreValue OR (commonIgnoreValue NE !NULL) THEN BEGIN
      CATCH, errSetDIV
      IF errSetDIV EQ 0 THEN BEGIN
        IF mosaicRaster.METADATA.HasTag('data ignore value') THEN BEGIN
          mosaicRaster.METADATA.UpdateItem, 'data ignore value', commonIgnoreValue
        ENDIF ELSE BEGIN
          mosaicRaster.METADATA.AddItem, 'data ignore value', commonIgnoreValue
        ENDELSE
        mosaicRaster.WriteMetadata
        PRINT, '  ✓ 已设置data ignore value: ' + STRING(commonIgnoreValue)
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
      ENDELSE
    ENDIF
    
    ; 设置镶嵌参数（可选）
    ; mosaicRaster.COLOR_MATCHING_METHOD = 'None'  ; 'None', 'Histogram Matching'
    ; mosaicRaster.FEATHERING_METHOD = 'None'      ; 'None', 'Blend', 'Seamline'
    ; mosaicRaster.RESAMPLING = 'Bilinear'         ; 'Nearest Neighbor', 'Bilinear', 'Cubic Convolution'
    
    PRINT, '  ✓ 镶嵌完成'
    PRINT, '  输出尺寸: ', mosaicRaster.NCOLUMNS, ' x ', mosaicRaster.NROWS
    PRINT, '  波段数: ', mosaicRaster.NBANDS
    PRINT, ''
    
    ; 检查空间参考
    mosaicSR = !NULL
    CATCH, errMosaicSR
    IF errMosaicSR EQ 0 THEN BEGIN
      mosaicSR = mosaicRaster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(mosaicSR) THEN BEGIN
        PRINT, '  ✓ 镶嵌影像包含空间参考信息'
        mosaicCoordSysStr = mosaicSR.COORD_SYS_STR
        mosaicCoordSysLen = STRLEN(mosaicCoordSysStr)
        mosaicCoordSysDisplayLen = MIN(60, mosaicCoordSysLen)
        PRINT, '  投影系统: ' + STRMID(mosaicCoordSysStr, 0, mosaicCoordSysDisplayLen)
        PRINT, ''
      ENDIF ELSE BEGIN
        PRINT, '  警告: 镶嵌影像缺少空间参考信息'
        PRINT, ''
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
    
    PRINT, '=========================================='
    PRINT, ''
    
    ; 步骤8：保存结果
    PRINT, '步骤8：保存镶嵌结果...'
    PRINT, '输出文件: ', FILE_BASENAME(outfile)
    
    PRINT, '  注意: 只能保存为dat格式下才会有空间参考坐标系'
    CATCH, errExport
    IF errExport EQ 0 THEN BEGIN
      ; 固定使用ENVI格式
      mosaicRaster.Export, outfile, 'ENVI'
      CATCH, /CANCEL
      
      WAIT, 0.5
      IF FILE_TEST(outfile) THEN BEGIN
        PRINT, '  ✓ 文件已保存'
        
        ; 使用ENVI_SETUP_HEAD确保data ignore value和空间参考写入文件头
        IF commonIgnoreValue NE !NULL THEN BEGIN
          PRINT, '  正在设置data ignore value到文件头...'
          CATCH, errSetupDIV
          IF errSetupDIV EQ 0 THEN BEGIN
            ENVI_OPEN_FILE, outfile, r_fid=fidDIV
            IF fidDIV GE 0 THEN BEGIN
              ENVI_FILE_QUERY, fidDIV, ns=nsDIV, nl=nlDIV, nb=nbDIV, data_type=dtDIV, interleave=interleaveDIV
              ; 获取MAP_INFO（如果存在）
              mapInfoDIV = !NULL
              CATCH, errMapInfo
              IF errMapInfo EQ 0 THEN BEGIN
                IF OBJ_VALID(mosaicSR) THEN BEGIN
                  ; 从SPATIALREF重建MAP_INFO
                  pixelSizeX = mosaicSR.PIXEL_SIZE[0]
                  pixelSizeY = ABS(mosaicSR.PIXEL_SIZE[1])
                  ulX = mosaicSR.TIE_POINT_MAP[0]
                  ulY = mosaicSR.TIE_POINT_MAP[1]
                  coordSysStrDIV = mosaicSR.COORD_SYS_STR
                  mapInfoDIV = ENVI_MAP_INFO_CREATE(/UTM, ZONE=51, /NORTH, DATUM='WGS-84', MC=[ulX, ulY, 0, 0], PS=[pixelSizeX, pixelSizeY])
                ENDIF
                CATCH, /CANCEL
              ENDIF ELSE BEGIN
                CATCH, /CANCEL
              ENDELSE
              
              IF mapInfoDIV NE !NULL THEN BEGIN
                ENVI_SETUP_HEAD, $
                  FNAME=outfile, $
                  NS=nsDIV, NL=nlDIV, NB=nbDIV, DATA_TYPE=dtDIV, INTERLEAVE=interleaveDIV, $
                  MAP_INFO=mapInfoDIV, $
                  DATA_IGNORE_VALUE=commonIgnoreValue, $
                  /WRITE, /OPEN
              ENDIF ELSE BEGIN
                ENVI_SETUP_HEAD, $
                  FNAME=outfile, $
                  NS=nsDIV, NL=nlDIV, NB=nbDIV, DATA_TYPE=dtDIV, INTERLEAVE=interleaveDIV, $
                  DATA_IGNORE_VALUE=commonIgnoreValue, $
                  /WRITE, /OPEN
              ENDELSE
              ENVI_FILE_MNG, id=fidDIV, /REMOVE
              PRINT, '  ✓ data ignore value已写入文件头: ' + STRING(commonIgnoreValue)
              CATCH, /CANCEL
            ENDIF ELSE BEGIN
              CATCH, /CANCEL
            ENDELSE
          ENDIF ELSE BEGIN
            CATCH, /CANCEL
            PRINT, '  警告: 设置data ignore value到文件头时发生错误'
          ENDELSE
        ENDIF
        
        ; 添加到Data Manager
        e.DATA.Add, mosaicRaster
        PRINT, '  ✓ 已添加到Data Manager'
      ENDIF ELSE BEGIN
        PRINT, '  警告: 文件导出后不存在，尝试使用ENVITask导出...'
        ; 尝试使用ENVITask导出（固定使用ENVI格式）
        exportTask = ENVITask('RasterExport')
        exportTask.INPUT_RASTER = mosaicRaster
        exportTask.OUTPUT_RASTER_URI = outfile
        exportTask.FORMAT = 'ENVI'
        exportTask.Execute
        WAIT, 1.0
        IF FILE_TEST(outfile) THEN BEGIN
          PRINT, '  ✓ 文件已保存（使用ENVITask）'
        ENDIF ELSE BEGIN
          PRINT, '  错误: 文件导出失败'
        ENDELSE
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '  错误: 导出失败: ' + !ERROR_STATE.MSG
    ENDELSE
    
    PRINT, ''
    PRINT, '=========================================='
    PRINT, '镶嵌完成！'
    PRINT, '输出文件: ', outfile
    PRINT, '=========================================='
    
    ; 关闭镶嵌影像（如果用户不需要在ENVI中查看，可以取消注释）
    ; mosaicRaster.Close
    
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 镶嵌失败: ' + !ERROR_STATE.MSG
    PRINT, ''
  ENDELSE
  
  ; 清理：关闭所有打开的影像
  FOREACH r, rasters DO BEGIN
    IF OBJ_VALID(r) THEN r.Close
  ENDFOREACH
  
END

