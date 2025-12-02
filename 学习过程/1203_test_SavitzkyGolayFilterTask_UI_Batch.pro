PRO 1203_test_SavitzkyGolayFilterTask_UI_Batch

  ;+
  ; :Description:
  ;    批量处理Savitzky-Golay滤波任务，结合UI界面选择文件和参数设置
  ;    用户可以通过UI选择多个输入文件，设置滤波参数，然后批量处理
  ;
  ; :Author: Generated for test_1203SavitzkyGolayFilterTask
  ;-
  
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  
  PRINT, '=========================================='
  PRINT, 'Savitzky-Golay滤波批量处理工具'
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
  
  ;检查第一个文件名是否包含特殊字符，建议使用ENVI格式
  first_basename = FILE_BASENAME(files[0], STRMID(files[0], STRPOS(files[0], '.', /REVERSE_SEARCH)))
  has_special_chars = 0
  FOR k=0, STRLEN(first_basename)-1 DO BEGIN
    char = STRMID(first_basename, k, 1)
    ;获取字符的ASCII值
    char_bytes = BYTE(char)
    ascii_val = char_bytes[0]
    ;检查是否包含非ASCII字符（中文字符等）
    IF (ascii_val LT 32) OR (ascii_val GT 126) THEN BEGIN
      has_special_chars = 1
      BREAK
    ENDIF
    ;检查是否包含空格
    IF ascii_val EQ 32 THEN BEGIN
      has_special_chars = 1
      BREAK
    ENDIF
  ENDFOR
  
  ;选择输出格式（使用简单的对话框，避免中文编码问题）
  PRINT, '请选择输出格式：'
  PRINT, '  点击"Yes" = TIFF格式 (.tif)'
  PRINT, '  点击"No"  = ENVI格式 (.dat)'
  IF has_special_chars THEN BEGIN
    PRINT, ''
    PRINT, '  注意: 检测到文件名包含特殊字符，建议使用ENVI格式以避免格式识别错误！'
  ENDIF
  PRINT, ''
  format_msg = 'Select Output Format:' + STRING(10B) + STRING(10B) + $
    'Click "Yes" for TIFF format (.tif)' + STRING(10B) + $
    'Click "No"  for ENVI format (.dat)'
  IF has_special_chars THEN BEGIN
    format_msg = format_msg + STRING(10B) + STRING(10B) + $
      'WARNING: Filename contains special characters!' + STRING(10B) + $
      'Recommend using ENVI format (.dat)'
  ENDIF
  format_result = DIALOG_MESSAGE(format_msg, TITLE='Output Format', /QUESTION)
  
  IF STRUPCASE(format_result) EQ 'YES' THEN BEGIN
    ; 用户点击"Yes" = TIFF格式
    output_format = '.tif'
    PRINT, '已选择: TIFF格式 (.tif)'
    IF has_special_chars THEN BEGIN
      PRINT, '  警告: 文件名包含特殊字符，TIFF格式可能出现识别错误，建议使用ENVI格式！'
    ENDIF
  ENDIF ELSE BEGIN
    ; 用户点击"No"或其他 = ENVI格式
    output_format = '.dat'
    PRINT, '已选择: ENVI格式 (.dat)'
  ENDELSE
  PRINT, ''
  
  ;步骤3：通过UI设置参数（使用一个示例文件来初始化Task）
  PRINT, '步骤3：设置滤波参数...'
  taskfile = FILEPATH('1203_test_SavitzkyGolayFilterTask.task', root_dir=ROUTINE_DIR())
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
  nleft = Task.Nleft
  nright = Task.Nright
  order = Task.Order
  degree = Task.Degree
  
  PRINT, '参数设置:'
  PRINT, '  N Left: ', nleft
  PRINT, '  N Right: ', nright
  PRINT, '  Order: ', order
  PRINT, '  Degree: ', degree
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
    
    ;检查原文件名是否包含特殊字符
    orig_basename = FILE_BASENAME(file, STRMID(file, STRPOS(file, '.', /REVERSE_SEARCH)))
    
    ;错误捕获
    Catch, errorStatus
    IF (errorStatus NE 0) THEN BEGIN
      Catch, /CANCEL
      errMsg = FILE_BASENAME(file) + ' --- ' + !ERROR_STATE.MSG
      errMsgs = [errMsgs, errMsg]
      PRINT, '  错误: ', !ERROR_STATE.MSG
      MESSAGE, /RESET
      CONTINUE
    ENDIF
    
    ;打开输入文件
    raster = e.OpenRaster(file)
    
    ;创建Task实例
    Task = ENVITask(taskfile)
    Task.INPUT_RASTER = raster
    Task.Nleft = nleft
    Task.Nright = nright
    Task.Order = order
    Task.Degree = degree
    Task.DISPLAY_RESULT = 0  ; 批量处理时不显示结果
    
    ;生成输出文件名（清理特殊字符和中文字符）
    ;清理文件名：移除或替换可能导致问题的字符
    ;移除中文字符、空格、特殊符号等，只保留字母、数字、下划线和连字符
    clean_basename = ''
    FOR k=0, STRLEN(orig_basename)-1 DO BEGIN
      char = STRMID(orig_basename, k, 1)
      ;检查是否为ASCII字母、数字、下划线或连字符
      char_bytes = BYTE(char)
      ascii_val = char_bytes[0]
      IF ((ascii_val GE 48 AND ascii_val LE 57) OR $  ; 0-9
          (ascii_val GE 65 AND ascii_val LE 90) OR $  ; A-Z
          (ascii_val GE 97 AND ascii_val LE 122) OR $  ; a-z
          (ascii_val EQ 95) OR $                        ; _
          (ascii_val EQ 45)) THEN BEGIN                 ; -
        clean_basename = clean_basename + char
      ENDIF ELSE BEGIN
        ;替换其他字符为下划线（包括空格、中文字符等）
        clean_basename = clean_basename + '_'
      ENDELSE
    ENDFOR
    ;移除连续的下划线
    WHILE STRPOS(clean_basename, '__') NE -1 DO BEGIN
      clean_basename = STRREPLACE(clean_basename, '__', '_')
    ENDWHILE
    ;移除开头和结尾的下划线
    WHILE (STRLEN(clean_basename) GT 0) AND (STRMID(clean_basename, 0, 1) EQ '_') DO BEGIN
      clean_basename = STRMID(clean_basename, 1)
    ENDWHILE
    WHILE (STRLEN(clean_basename) GT 0) AND (STRMID(clean_basename, STRLEN(clean_basename)-1, 1) EQ '_') DO BEGIN
      clean_basename = STRMID(clean_basename, 0, STRLEN(clean_basename)-1)
    ENDWHILE
    ;如果清理后文件名为空，使用默认名称
    IF STRLEN(clean_basename) EQ 0 THEN clean_basename = 'output'
    
    ;限制文件名长度（Windows限制为255字符，但为了安全限制为200字符）
    ;对于TIFF格式，文件名过长可能导致问题
    IF output_format EQ '.tif' THEN BEGIN
      max_len = 200
    ENDIF ELSE BEGIN
      max_len = 200
    ENDELSE
    
    IF STRLEN(clean_basename) GT max_len THEN BEGIN
      clean_basename = STRMID(clean_basename, 0, max_len)
      PRINT, '  注意: 文件名过长，已截断为: ', clean_basename
    ENDIF
    
    ;如果文件名被修改，提示用户
    IF orig_basename NE clean_basename THEN BEGIN
      PRINT, '  注意: 文件名包含特殊字符，已清理为: ', clean_basename
    ENDIF
    
    IF output_format EQ '.tif' THEN BEGIN
      outfile = FILEPATH(clean_basename + '_SG_Filter.tif', root_dir=outdir)
    ENDIF ELSE BEGIN
      outfile = FILEPATH(clean_basename + '_SG_Filter.dat', root_dir=outdir)
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
    
    ;设置输出文件路径
    Task.OUTPUT_RASTER_URI = outfile
    
    ;验证所有必需的参数都已设置
    IF ~ISA(Task.INPUT_RASTER) THEN BEGIN
      PRINT, '  错误: INPUT_RASTER 未设置'
      CONTINUE
    ENDIF
    IF ~ISA(Task.Nleft) THEN BEGIN
      PRINT, '  错误: Nleft 未设置'
      CONTINUE
    ENDIF
    IF ~ISA(Task.Nright) THEN BEGIN
      PRINT, '  错误: Nright 未设置'
      CONTINUE
    ENDIF
    IF ~ISA(Task.Order) THEN BEGIN
      PRINT, '  错误: Order 未设置'
      CONTINUE
    ENDIF
    IF ~ISA(Task.Degree) THEN BEGIN
      PRINT, '  错误: Degree 未设置'
      CONTINUE
    ENDIF
    
    ;执行Task
    Task.Execute
    
    ;添加到Data Manager
    DataColl.Add, Task.OUTPUT_RASTER
    
    raster.Close
    success_count = success_count + 1
    PRINT, '  完成: ', FILE_BASENAME(outfile)
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
