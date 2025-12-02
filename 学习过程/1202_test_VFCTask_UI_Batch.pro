PRO test1202_VFCTask_UI_Batch

  ;+
  ; :Description:
  ;    批量处理VFC任务，结合UI界面选择文件和参数设置
  ;    用户可以通过UI选择多个输入文件，设置参数，然后批量处理
  ;
  ; :Author: Generated for test_1202VFCTask
  ;-
  
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  PRINT, '=========================================='
  PRINT, 'VFC批量处理工具'
  PRINT, '=========================================='
  PRINT, ''
  
  ;步骤1：选择多个输入文件
  PRINT, '步骤1：选择输入文件（可多选）...'
  files = ENVI_PICKFILE(TITLE='请选择要处理的栅格文件（可多选）', $
    /MULTIPLE_FILES, $
    FILTER=['*.tif', '*.dat', '*.img', '*.*'])
  
  IF (files[0] EQ '') OR (N_ELEMENTS(files) EQ 0) THEN BEGIN
    PRINT, '未选择文件，退出。'
    RETURN
  ENDIF
  
  n_files = N_ELEMENTS(files)
  PRINT, '已选择 ', n_files, ' 个文件'
  PRINT, ''
  
  ;步骤2：选择输出目录和格式
  PRINT, '步骤2：选择输出目录和格式...'
  outdir = ENVI_PICKFILE(/OUTPUT, /DIRECTORY, TITLE='请选择输出目录')
  IF outdir EQ '' THEN BEGIN
    PRINT, '未选择输出目录，退出。'
    RETURN
  ENDIF
  PRINT, '输出目录: ', outdir
  PRINT, ''
  
  ;选择输出格式（使用简单的对话框，避免中文编码问题）
  PRINT, '请选择输出格式：'
  PRINT, '  点击"Yes" = TIFF格式 (.tif)'
  PRINT, '  点击"No"  = ENVI格式 (.dat)'
  PRINT, ''
  format_choice = FIX(DIALOG_MESSAGE('Select Output Format:' + STRING(10B) + STRING(10B) + $
    'Click "Yes" for TIFF format (.tif)' + STRING(10B) + $
    'Click "No"  for ENVI format (.dat)', $
    TITLE='Output Format', $
    /QUESTION))
  
  IF format_choice EQ 0 THEN BEGIN
    ; 用户点击"Yes" = TIFF格式
    output_format = '.tif'
    PRINT, '已选择: TIFF格式 (.tif)'
  ENDIF ELSE BEGIN
    ; 用户点击"No" = ENVI格式
    output_format = '.dat'
    PRINT, '已选择: ENVI格式 (.dat)'
  ENDELSE
  PRINT, ''
  
  ;步骤3：通过UI设置参数（使用一个示例文件来初始化Task）
  PRINT, '步骤3：设置处理参数...'
  taskfile = FILEPATH('test_1202VFCTask.task', root_dir=ROUTINE_DIR())
  Task = ENVITask(taskfile)
  
  ;使用第一个文件作为示例，让用户设置参数
  sample_raster = e.OpenRaster(files[0])
  Task.INPUT_RASTER = sample_raster
  
  ;弹出UI界面让用户设置参数
  result = e.UI.SelectTaskParameters(Task)
  IF result NE 'OK' THEN BEGIN
    PRINT, '用户取消操作，退出。'
    sample_raster.Close
    RETURN
  ENDIF
  
  ;获取用户设置的参数
  min_ndvi = Task.MINIMUM_NDVI
  max_ndvi = Task.MAXIMUM_NDVI
  
  PRINT, '参数设置:'
  PRINT, '  最小NDVI: ', min_ndvi
  PRINT, '  最大NDVI: ', max_ndvi
  PRINT, ''
  
  sample_raster.Close
  
  ;步骤4：批量处理所有文件
  PRINT, '步骤4：开始批量处理...'
  PRINT, '=========================================='
  
  DataColl = e.DATA  ; Data Manager
  errMsgs = !NULL    ; 记录错误信息
  success_count = 0
  
  FOR i=0, n_files-1 DO BEGIN
    file = files[i]
    PRINT, '处理文件 ', i+1, '/', n_files, ': ', FILE_BASENAME(file)
    
    ;错误捕获
    Catch, errorStatus
    IF (errorStatus NE 0) THEN BEGIN
      Catch, /CANCEL
      errMsg = FILE_BASENAME(file) + ' --- ' + !ERROR_STATE.MSG
      errMsgs = [errMsgs, errMsg]
      PRINT, '  ❌ 错误: ', !ERROR_STATE.MSG
      MESSAGE, /RESET
      CONTINUE
    ENDIF
    
    ;打开输入文件
    raster = e.OpenRaster(file)
    
    ;创建Task实例
    Task = ENVITask(taskfile)
    Task.INPUT_RASTER = raster
    Task.MINIMUM_NDVI = min_ndvi
    Task.MAXIMUM_NDVI = max_ndvi
    
    ;生成输出文件名
    basename = FILE_BASENAME(file, STRMID(file, STRPOS(file, '.', /REVERSE_SEARCH)))
    IF output_format EQ '.tif' THEN BEGIN
      outfile = FILEPATH(basename + '_VFC.tif', root_dir=outdir)
    ENDIF ELSE BEGIN
      outfile = FILEPATH(basename + '_VFC.dat', root_dir=outdir)
    ENDELSE
    
    ;删除已存在的输出文件（包括.dat, .tif, .hdr文件）
    IF FILE_TEST(outfile) THEN BEGIN
      PRINT, '  检测到已存在的输出文件，正在删除...'
      FILE_DELETE, outfile, /QUIET, /ALLOW_NONEXISTENT
      
      ;删除相关的.hdr头文件（如果是ENVI格式）
      IF output_format EQ '.dat' THEN BEGIN
        hdr_file = FILE_DIRNAME(outfile) + PATH_SEP() + FILE_BASENAME(outfile, '.dat') + '.hdr'
        IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
      ENDIF
      
      ;同时删除可能存在的其他格式文件（如果之前处理过不同格式）
      alt_ext = (output_format EQ '.tif') ? '.dat' : '.tif'
      alt_file = FILE_DIRNAME(outfile) + PATH_SEP() + FILE_BASENAME(outfile, output_format) + alt_ext
      IF FILE_TEST(alt_file) THEN BEGIN
        FILE_DELETE, alt_file, /QUIET, /ALLOW_NONEXISTENT
        ;删除对应的.hdr文件
        IF alt_ext EQ '.dat' THEN BEGIN
          alt_hdr = FILE_DIRNAME(alt_file) + PATH_SEP() + FILE_BASENAME(alt_file, '.dat') + '.hdr'
          IF FILE_TEST(alt_hdr) THEN FILE_DELETE, alt_hdr, /QUIET, /ALLOW_NONEXISTENT
        ENDIF
      ENDIF
    ENDIF
    
    Task.OUTPUT_RASTER_URI = outfile
    Task.Execute
    
    ;添加到Data Manager
    DataColl.Add, Task.OUTPUT_RASTER
    
    raster.Close
    success_count = success_count + 1
    PRINT, '  ✅ 完成: ', FILE_BASENAME(outfile)
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
  
END

