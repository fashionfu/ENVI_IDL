;+
; 程序名: batch_ndvi_colorslice_UI.pro
; 功能: NDVI颜色分片批量处理工具（带UI界面）
; 输入: Landsat L2数据文件夹或高分一号数据文件
; 输出: NDVI颜色分片分类结果
; 作者: Auto
; 日期: 2024-12
;-

PRO batch_ndvi_colorslice_UI

  COMPILE_OPT IDL2

  ; 启动ENVI
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(e) THEN e = ENVI()

  PRINT, '=========================================='
  PRINT, 'NDVI颜色分片批量处理工具（UI版）'
  PRINT, '=========================================='
  PRINT, ''

  ; 步骤1：选择数据类型和输入路径
  PRINT, '步骤1：选择数据类型和输入路径...'
  PRINT, '请选择数据类型：'
  PRINT, '  点击"Yes" = Landsat L2数据（文件夹）'
  PRINT, '  点击"No"  = 高分一号数据（单个文件）'
  PRINT, ''
  data_type_msg = 'Select Data Type:' + STRING(10B) + STRING(10B) + $
    'Click "Yes" for Landsat L2 data (folder)' + STRING(10B) + $
    'Click "No"  for GF1 data (single file)'
  data_type_result = DIALOG_MESSAGE(data_type_msg, TITLE='Data Type Selection', /QUESTION)

  input_rasters = !NULL
  IF STRUPCASE(data_type_result) EQ 'YES' THEN BEGIN
    ; Landsat L2数据
    PRINT, '已选择: Landsat L2数据'
    PRINT, '请选择Landsat L2数据文件夹...'
    landsat_dir = 'D:\FTPfiles\guangzhou\2024年\2024年第一季度\LC08_L2SP_129042_20161208_20200905_02_T1'
    
    ; 检查默认路径是否存在
    IF ~FILE_TEST(landsat_dir, /DIRECTORY) THEN BEGIN
      ; 如果默认路径不存在，让用户选择
      landsat_dir = ENVI_PICKFILE(/DIRECTORY, TITLE='请选择Landsat L2数据文件夹')
      IF landsat_dir EQ '' THEN BEGIN
        PRINT, '未选择输入文件夹，退出。'
        RETURN
      ENDIF
    ENDIF
    PRINT, 'Landsat数据目录: ', landsat_dir
    
    ; 查找MTL文件
    PRINT, '正在搜索MTL文件...'
    xml_files = FILE_SEARCH(landsat_dir, '*_MTL.xml', COUNT=xml_count)
    IF xml_count EQ 0 THEN BEGIN
      txt_files = FILE_SEARCH(landsat_dir, '*_MTL.txt', COUNT=txt_count)
      IF txt_count GT 0 THEN BEGIN
        mtl_file = txt_files[0]
      ENDIF ELSE BEGIN
        PRINT, '未找到MTL文件，退出。'
        RETURN
      ENDELSE
    ENDIF ELSE BEGIN
      mtl_file = xml_files[0]
    ENDELSE
    
    ; 打开Surface Reflectance数据
    PRINT, '正在打开Surface Reflectance数据...'
    CATCH, errOpen
    IF errOpen EQ 0 THEN BEGIN
      ; 使用DATASET_NAME参数打开Surface Reflectance数据
      raster = e.OpenRaster(mtl_file, DATASET_NAME='Surface Reflectance')
      CATCH, /CANCEL
      
      ; 处理返回数组的情况
      IF raster NE !NULL THEN BEGIN
        tempSize = SIZE(raster, /N_DIMENSIONS)
        IF tempSize GT 0 THEN raster = raster[0]
      ENDIF
      
      IF OBJ_VALID(raster) THEN BEGIN
        ; 检查是否有波长信息
        hasWavelength = 0
        CATCH, errCheck
        IF errCheck EQ 0 THEN BEGIN
          wavelengths = raster.WAVELENGTH
          CATCH, /CANCEL
          IF wavelengths NE !NULL THEN BEGIN
            IF N_ELEMENTS(wavelengths) GT 0 THEN hasWavelength = 1
          ENDIF
        ENDIF ELSE BEGIN
          CATCH, /CANCEL
        ENDELSE
        
        IF hasWavelength THEN BEGIN
          PRINT, '成功打开Landsat数据，波段数: ', raster.NBANDS, '（包含波长信息）'
        ENDIF ELSE BEGIN
          PRINT, '成功打开Landsat数据，波段数: ', raster.NBANDS
          PRINT, '注意: 数据缺少波长信息，将使用默认波段计算NDVI'
        ENDELSE
        
        input_rasters = [raster]
      ENDIF ELSE BEGIN
        PRINT, '错误: 无法打开Surface Reflectance数据'
        PRINT, '提示: 请确保数据是Landsat L2 Surface Reflectance级别'
        RETURN
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '错误: 打开Landsat数据时发生错误'
      PRINT, '错误信息: ', !ERROR_STATE.MSG
      RETURN
    ENDELSE
    
  ENDIF ELSE BEGIN
    ; 高分一号数据
    PRINT, '已选择: 高分一号数据'
    PRINT, '正在打开高分一号数据文件...'
    gf1_file = 'D:\FTPfiles\guangzhou\2024年\2024年第一季度\GF1原始像元值\GF1_PMS1_E113.3_N22.7_20240213_L1A13282365001_MSS.tif'
    
    ; 检查默认路径是否存在
    IF ~FILE_TEST(gf1_file) THEN BEGIN
      ; 如果默认路径不存在，让用户选择
      gf1_file = ENVI_PICKFILE(TITLE='请选择高分一号数据文件', FILTER='*.tif;*.dat;*.img')
      IF gf1_file EQ '' THEN BEGIN
        PRINT, '未选择输入文件，退出。'
        RETURN
      ENDIF
    ENDIF
    PRINT, '高分一号数据文件: ', gf1_file
    
    ; 打开高分一号数据
    CATCH, errOpen
    IF errOpen EQ 0 THEN BEGIN
      raster = e.OpenRaster(gf1_file)
      CATCH, /CANCEL
      IF OBJ_VALID(raster) THEN BEGIN
        input_rasters = [raster]
        PRINT, '成功打开高分一号数据'
      ENDIF ELSE BEGIN
        PRINT, '错误: 无法打开高分一号数据'
        RETURN
      ENDELSE
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
      PRINT, '错误: 打开高分一号数据时发生错误'
      RETURN
    ENDELSE
  ENDELSE

  IF input_rasters EQ !NULL THEN BEGIN
    PRINT, '错误: 未成功打开任何数据，退出。'
    RETURN
  ENDIF

  PRINT, ''

  ; 步骤2：选择输出目录
  PRINT, '步骤2：选择输出目录...'
  output_dir = 'D:\FTPfiles\guangzhou\2024年\2024年第一季度\GF1处理'
  
  ; 检查默认路径是否存在
  IF ~FILE_TEST(output_dir, /DIRECTORY) THEN BEGIN
    ; 如果默认路径不存在，让用户选择
    output_dir = ENVI_PICKFILE(/OUTPUT, /DIRECTORY, TITLE='请选择输出目录')
    IF output_dir EQ '' THEN BEGIN
      PRINT, '未选择输出目录，退出。'
      RETURN
    ENDIF
  ENDIF
  PRINT, '输出目录: ', output_dir
  PRINT, ''

  ; 步骤3：设置NDVI颜色分片参数（UI界面）
  PRINT, '步骤3：设置NDVI颜色分片参数（UI界面）...'
  taskfile = FILEPATH('NDVIColorSliceBatchTask.task', $
    root_dir=FILE_DIRNAME(ROUTINE_FILEPATH()))
  
  IF ~FILE_TEST(taskfile) THEN BEGIN
    PRINT, '警告: 无法找到任务定义文件，将使用默认参数'
    PRINT, '使用默认参数:'
    PRINT, '  颜色表: CB-Greens'
    PRINT, '  分类数: 5'
    PRINT, '  显示结果: 是'
    PRINT, '  输出扩展名: _ndvi_class.dat'
    PRINT, ''
    
    ; 使用默认参数
    color_table_name = 'CB-Greens'
    number_of_ranges = 5
    display_results = 1
    output_extension = '_ndvi_class.dat'
  ENDIF ELSE BEGIN
    ; 使用UI界面设置参数
    task = ENVITask(taskfile)
    task.INPUT_RASTERS = input_rasters
    task.OUTPUT_DIR = output_dir
    
    result = e.UI.SelectTaskParameters(task)
    IF result NE 'OK' THEN BEGIN
      PRINT, '用户取消操作，退出。'
      RETURN
    ENDIF
    
    color_table_name = task.COLOR_TABLE_NAME
    number_of_ranges = task.NUMBER_OF_RANGES
    display_results = task.DISPLAY_RESULTS
    output_extension = task.OUTPUT_EXTENSION
    
    PRINT, '已设置参数:'
    PRINT, '  颜色表: ', color_table_name
    PRINT, '  分类数: ', number_of_ranges
    PRINT, '  显示结果: ', display_results
    PRINT, '  输出扩展名: ', output_extension
    PRINT, ''
  ENDELSE

  ; 步骤4：执行批量处理
  PRINT, '步骤4：开始批量处理...'
  PRINT, '=========================================='
  
  CATCH, errExecute
  IF errExecute EQ 0 THEN BEGIN
    ; 执行任务
    task = ENVITask(taskfile)
    task.INPUT_RASTERS = input_rasters
    task.COLOR_TABLE_NAME = color_table_name
    task.NUMBER_OF_RANGES = number_of_ranges
    task.DISPLAY_RESULTS = display_results
    task.OUTPUT_EXTENSION = output_extension
    task.OUTPUT_DIR = output_dir
    task.Execute
    
    CATCH, /CANCEL
    PRINT, '批量处理完成！'
    PRINT, '结果已保存到: ', output_dir
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '错误: 批量处理失败'
    PRINT, '错误信息: ', !ERROR_STATE.MSG
  ENDELSE

  PRINT, '=========================================='

END

