PRO NDVIColorSliceBatchTask, $
  input_rasters=input_rasters, $
  color_table_name=color_table_name, $
  number_of_ranges=number_of_ranges, $
  display_results=display_results, $
  output_extension=output_extension, $
  output_dir=output_dir
  COMPILE_OPT idl2
  e=envi()

  DataColl = e.DATA  ;Data Manager
  View = e.GetView()

  errMsgs = !NULL    ;记录错误信息
  n_files = N_ELEMENTS(input_rasters)
  PRINT, '开始处理 ', n_files, ' 个文件...'
  PRINT, ''
  FOR i=0, n_files-1 DO BEGIN
    file = input_rasters[i].URI
    PRINT, '处理文件 ', i+1, '/', n_files, ': ', FILE_BASENAME(file)
    ;错误处理
    Catch, errorStatus
    IF (errorStatus NE 0) THEN BEGIN
      Catch, /CANCEL
      errMsgs = [errMsgs, file +' --- '+ !ERROR_STATE.MSG]
      MESSAGE, /RESET
      CONTINUE
    ENDIF
    ;
    raster = input_rasters[i]
    
    ; 检查是否有波长信息
    hasWavelength = 0
    CATCH, errWavelength
    IF errWavelength EQ 0 THEN BEGIN
      wavelengths = raster.WAVELENGTH
      CATCH, /CANCEL
      IF wavelengths NE !NULL THEN BEGIN
        IF N_ELEMENTS(wavelengths) GT 0 THEN hasWavelength = 1
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
    
    ; 如果没有波长信息，尝试手动设置（Landsat 8/9标准波长）
    IF ~hasWavelength THEN BEGIN
      PRINT, '  警告: 数据缺少波长信息，尝试手动设置...'
      CATCH, errSetWavelength
      IF errSetWavelength EQ 0 THEN BEGIN
        ; Landsat 8/9 OLI标准波长（微米）
        ; B1: 0.433-0.453 (Coastal/Aerosol)
        ; B2: 0.450-0.515 (Blue)
        ; B3: 0.525-0.600 (Green)
        ; B4: 0.630-0.680 (Red) - 用于NDVI
        ; B5: 0.845-0.885 (NIR) - 用于NDVI
        ; B6: 1.560-1.660 (SWIR1)
        ; B7: 2.100-2.300 (SWIR2)
        ; 使用中心波长
        landSat8Wavelengths = [0.443, 0.4825, 0.5625, 0.655, 0.865, 1.61, 2.2]
        
        ; 根据波段数设置波长
        IF raster.NBANDS GE 7 THEN BEGIN
          raster.WAVELENGTH = landSat8Wavelengths[0:6]
          PRINT, '  ✓ 已设置Landsat 8/9标准波长（7个波段）'
          hasWavelength = 1
        ENDIF ELSE IF raster.NBANDS GE 5 THEN BEGIN
          raster.WAVELENGTH = landSat8Wavelengths[0:4]
          PRINT, '  ✓ 已设置Landsat 8/9标准波长（5个波段）'
          hasWavelength = 1
        ENDIF ELSE BEGIN
          PRINT, '  警告: 波段数不足，无法设置标准波长'
        ENDELSE
        CATCH, /CANCEL
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  警告: 无法设置波长信息'
      ENDELSE
    ENDIF
    
    ; 计算NDVI（参考test_1202VFCTask的实现方式）
    ndvi = !NULL
    IF hasWavelength THEN BEGIN
      ; 如果有波长信息，直接使用ENVISpectralIndexRaster（返回虚拟栅格）
      CATCH, errSpectral
      IF errSpectral EQ 0 THEN BEGIN
        PRINT, '  正在使用SpectralIndexRaster计算NDVI...'
        ndvi = ENVISpectralIndexRaster(raster, 'ndvi')
        CATCH, /CANCEL
        IF (ndvi EQ !NULL) OR ~OBJ_VALID(ndvi) THEN BEGIN
          PRINT, '  警告: SpectralIndexRaster失败，尝试手动计算...'
          hasWavelength = 0  ; 回退到手动计算
        ENDIF ELSE BEGIN
          PRINT, '  ✓ NDVI计算成功（使用SpectralIndexRaster）'
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '  警告: SpectralIndexRaster失败: ' + !ERROR_STATE.MSG
        PRINT, '  尝试手动计算NDVI...'
        hasWavelength = 0  ; 回退到手动计算
      ENDELSE
    ENDIF
    
    IF ~hasWavelength THEN BEGIN
      ; 手动计算NDVI（参考test_1202VFCTask，使用ENVIPixelwiseBandMathRaster函数）
      PRINT, '警告: 数据缺少波长信息，使用默认波段计算NDVI'
      
      ; 根据波段数自动判断数据类型
      ; GF1通常有4个波段：B1(蓝), B2(绿), B3(红), B4(近红外)
      ; Landsat 8/9通常有7个波段：B1-B7，其中B4(红), B5(近红外)
      nbands = raster.NBANDS
      
      IF nbands EQ 4 THEN BEGIN
        ; 高分一号数据：波段3是红光，波段4是近红外
        PRINT, '  检测到4个波段，使用高分一号波段配置'
        PRINT, '  波段3为红光，波段4为近红外'
        
        ; 检查波段数是否足够
        IF nbands LT 4 THEN BEGIN
          errMsgs = [errMsgs, file +' --- 波段数不足（需要至少4个波段，当前' + STRTRIM(STRING(nbands), 2) + '个）']
          CONTINUE
        ENDIF
        
        ; GF1: NDVI = (B4 - B3) / (B4 + B3)，显式使用FLOAT防止整数除法
        PRINT, '  正在计算NDVI（使用波段索引b3和b4，FLOAT运算）...'
        CATCH, errNDVI
        IF errNDVI EQ 0 THEN BEGIN
          ndvi = ENVIPixelwiseBandMathRaster(raster, $
            '(FLOAT(b4)-FLOAT(b3))/(FLOAT(b4)+FLOAT(b3))')
          CATCH, /CANCEL
          
          ; 检查NDVI是否成功创建
          IF (ndvi EQ !NULL) OR ~OBJ_VALID(ndvi) THEN BEGIN
            errMsgs = [errMsgs, file +' --- NDVI计算失败（返回无效结果）']
            CONTINUE
          ENDIF
          PRINT, '  ✓ NDVI计算成功'
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          errMsgs = [errMsgs, file +' --- NDVI计算失败: ' + !ERROR_STATE.MSG]
          CONTINUE
        ENDELSE
        
      ENDIF ELSE BEGIN
        ; Landsat 8/9数据：波段4是红光，波段5是近红外
        PRINT, '  检测到', nbands, '个波段，使用Landsat 8/9波段配置'
        PRINT, '  波段4为红光，波段5为近红外'
        
        ; 检查波段数是否足够
        IF nbands LT 5 THEN BEGIN
          errMsgs = [errMsgs, file +' --- 波段数不足（需要至少5个波段，当前' + STRTRIM(STRING(nbands), 2) + '个）']
          CONTINUE
        ENDIF
        
        ; Landsat: NDVI = (B5 - B4) / (B5 + B4)，显式使用FLOAT防止整数除法
        PRINT, '  正在计算NDVI（使用波段索引b4和b5，FLOAT运算）...'
        CATCH, errNDVI
        IF errNDVI EQ 0 THEN BEGIN
          ndvi = ENVIPixelwiseBandMathRaster(raster, $
            '(FLOAT(b5)-FLOAT(b4))/(FLOAT(b5)+FLOAT(b4))')
          CATCH, /CANCEL
          
          ; 检查NDVI是否成功创建
          IF (ndvi EQ !NULL) OR ~OBJ_VALID(ndvi) THEN BEGIN
            errMsgs = [errMsgs, file +' --- NDVI计算失败（返回无效结果）']
            CONTINUE
          ENDIF
          PRINT, '  ✓ NDVI计算成功'
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
          errMsgs = [errMsgs, file +' --- NDVI计算失败: ' + !ERROR_STATE.MSG]
          CONTINUE
        ENDELSE
      ENDELSE
    ENDIF
    
    ; 检查ndvi是否有效
    IF (ndvi EQ !NULL) OR ~OBJ_VALID(ndvi) THEN BEGIN
      errMsgs = [errMsgs, file +' --- NDVI计算结果无效']
      CONTINUE
    ENDIF
    
    ; 检查NDVI值的实际范围（用于诊断）
    PRINT, '  正在检查NDVI值范围...'
    CATCH, errCheckRange
    IF errCheckRange EQ 0 THEN BEGIN
      ; 采样检查NDVI值范围（从中心区域采样，避免边缘效应）
      ncols = ndvi.NCOLUMNS
      nrows = ndvi.NROWS
      sample_size = 1000
      IF ncols GT sample_size THEN sample_size = sample_size ELSE sample_size = ncols
      IF nrows GT sample_size THEN sample_size = sample_size ELSE sample_size = nrows
      
      x0 = (ncols - sample_size) / 2
      y0 = (nrows - sample_size) / 2
      x1 = x0 + sample_size - 1
      y1 = y0 + sample_size - 1
      
      CATCH, errSample
      IF errSample EQ 0 THEN BEGIN
        sample_data = ndvi.GetData(SUB_RECT=[x0, y0, x1, y1])
        CATCH, /CANCEL
        valid_pixels = sample_data[WHERE(FINITE(sample_data), count)]
        IF count GT 0 THEN BEGIN
          min_ndvi = MIN(valid_pixels)
          max_ndvi = MAX(valid_pixels)
          mean_ndvi = MEAN(valid_pixels)
          PRINT, '    NDVI值范围: ', STRING(min_ndvi, FORMAT='(F6.3)'), ' 到 ', STRING(max_ndvi, FORMAT='(F6.3)')
          PRINT, '    NDVI平均值: ', STRING(mean_ndvi, FORMAT='(F6.3)')
        ENDIF ELSE BEGIN
          PRINT, '    警告: 无法采样NDVI值'
        ENDELSE
      ENDIF ELSE BEGIN
        CATCH, /CANCEL
        PRINT, '    警告: 采样NDVI值时发生错误'
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '    警告: 检查NDVI值范围时发生错误'
    ENDELSE
    
    ; 将NDVI值限制在-1到1之间（修复表达式）
    PRINT, '  正在限制NDVI值范围...'
    CATCH, errLimit
    IF errLimit EQ 0 THEN BEGIN
      ; 使用正确的表达式：将值限制在-1到1之间
      ; 表达式: (b1 GT -1) AND (b1 LT 1) ? b1 : (b1 GE 1 ? 1 : -1)
      ; 简化版本: b1*(b1 GT -1)*(b1 LT 1) + 1*(b1 GE 1) + (-1)*(b1 LE -1)
      ; 更简单的版本: (b1 LT -1)*(-1) + (b1 GT 1)*1 + (b1 GE -1 AND b1 LE 1)*b1
      ndvi_limited = ENVIPixelwiseBandMathRaster(ndvi, $
        '(b1 LT -1)*(-1) + (b1 GT 1)*1 + (b1 GE -1 AND b1 LE 1)*b1')
      CATCH, /CANCEL
      IF OBJ_VALID(ndvi_limited) THEN BEGIN
        ; 注意：不需要关闭ndvi，因为它是虚拟栅格，会被ndvi_limited引用
        ndvi = ndvi_limited
        PRINT, '  ✓ NDVI值范围限制完成'
      ENDIF ELSE BEGIN
        ; 如果限制失败，继续使用原始ndvi
        PRINT, '  警告: NDVI值范围限制失败，使用原始NDVI'
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      ; 如果限制失败，继续使用原始ndvi
      PRINT, '  警告: NDVI值范围限制失败，使用原始NDVI'
    ENDELSE

    ; 再次检查ndvi是否有效（在传递给ColorSliceClassification之前）
    IF (ndvi EQ !NULL) OR ~OBJ_VALID(ndvi) THEN BEGIN
      errMsgs = [errMsgs, file +' --- NDVI处理失败，无法进行颜色分片']
      CONTINUE
    ENDIF

    ;生成输出文件名，自动设定输出文件名
    basename = FILE_BASENAME(file,STRMID(file,STRPOS(file,'.',/reverse_search)))
    outfile = FILEPATH(basename+output_extension, root_dir=output_dir)
    
    ;删除已存在的输出文件（参考test_1202VFCTask的实现）
    IF FILE_TEST(outfile) THEN BEGIN
      PRINT, '  检测到已存在的输出文件，正在删除...'
      FILE_DELETE, outfile, /QUIET, /ALLOW_NONEXISTENT
      
      ;删除相关的.hdr头文件（如果是ENVI格式）
      IF STRPOS(STRUPCASE(outfile), '.DAT') GE 0 THEN BEGIN
        hdr_file = FILE_DIRNAME(outfile) + PATH_SEP() + FILE_BASENAME(outfile, '.dat') + '.hdr'
        IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
      ENDIF
    ENDIF
    
    ;密度分割
    PRINT, '  正在执行颜色分片分类...'
    CATCH, errColorSlice
    IF errColorSlice EQ 0 THEN BEGIN
      Task = ENVITask('ColorSliceClassification')
      Task.INPUT_RASTER = ndvi
      Task.COLOR_TABLE_NAME = color_table_name
      Task.DATA_MINIMUM = 0.0
      Task.DATA_MAXIMUM = 1.0
      Task.NUMBER_OF_RANGES = number_of_ranges
      Task.OUTPUT_RASTER_URI = outfile
      Task.Execute
      CATCH, /CANCEL
      
      ;检查任务执行结果
      IF OBJ_VALID(Task.OUTPUT_RASTER) THEN BEGIN
        ;将结果添加到Data Manager中，并显示
        DataColl.Add, Task.OUTPUT_RASTER
        IF display_results THEN $
          Layer = View.CreateLayer(Task.OUTPUT_RASTER)
        PRINT, '  ✓ 颜色分片分类完成: ', FILE_BASENAME(outfile)
      ENDIF ELSE BEGIN
        errMsgs = [errMsgs, file +' --- 颜色分片分类失败（输出结果无效）']
      ENDELSE
      
      ; 关闭ndvi（如果它不是原始输入raster）
      IF OBJ_VALID(ndvi) THEN BEGIN
        IF ndvi NE raster THEN BEGIN
          ndvi.Close
        ENDIF
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      errMsgs = [errMsgs, file +' --- 颜色分片分类失败: ' + !ERROR_STATE.MSG]
      ; 关闭ndvi（如果它不是原始输入raster）
      IF OBJ_VALID(ndvi) THEN BEGIN
        IF ndvi NE raster THEN BEGIN
          ndvi.Close
        ENDIF
      ENDIF
    ENDELSE
  ENDFOR

  ;显示错误文件及相应的错误信息
  IF errMsgs NE !NULL THEN BEGIN
    logFile = e.GetTemporaryFilename('log')
    XDISPLAYFILE, logFile, group=e.WIDGET_ID, title='错误信息', $
      text=['Input File --- Error Message', errMsgs], /grow_to_screen, $
      done_button='Exit', height=20, width=120, /modal
  ENDIF
END

