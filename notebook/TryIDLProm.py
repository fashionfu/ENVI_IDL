"""
==========================================
IDL遥感影像处理基础代码
==========================================
本文件包含了从IDL中书写代码进行遥感影像处理的四个主要步骤：
1. 开启遥感影像
2. 辐射定标
3. 大气校正
4. 正射校正

以下代码基于ENVI二次开发培训素材包中的代码示例总结而来。

==========================================
文档内容总结
==========================================
本素材包包含以下主要内容：

1. ENVI Service Engine平台介绍与开发技术
2. ENVI Task开发：包括VirtualRaster、ENVITasks、CustomTasks等
3. ENVI二次开发常用功能：
   - ENVI开启/关闭：startENVI.pro, endENVI.pro
   - 辐射定标：cal_calibration.pro（使用gainoff_doit）
   - 大气校正：cal_quac.pro（使用envi_quac_doit）
   - 正射校正：GSF_RPCOrthorectification.pro（使用RPCOrthorectification Task）
   - 影像融合、镶嵌、裁剪、分类等功能

4. IDL基础语法和功能示例
5. ENVI扩展开发示例

==========================================
基础IDL代码（以下为IDL代码，放在注释中）
==========================================
"""

# ==========================================
# 步骤1：开启遥感影像
# ==========================================
"""
PRO Example_OpenRaster
  ; 初始化ENVI环境
  COMPILE_OPT idl2
  
  ; 方法1：使用ENVI对象（推荐方式，ENVI 5.x）
  e = ENVI()                    ; 无头模式（无GUI界面）
  ; e = ENVI(/HEADLESS)        ; 无头模式
  ; e = ENVI(/CURRENT)         ; 使用当前ENVI实例
  
  ; 打开遥感影像文件
  input_file = 'C:\data\image.dat'  ; 输入文件路径
  raster = e.OpenRaster(input_file)
  
  ; 获取影像信息
  PRINT, '影像行数: ', raster.NROWS
  PRINT, '影像列数: ', raster.NCOLUMNS
  PRINT, '波段数: ', raster.NBANDS
  
  ; 方法2：使用传统ENVI函数（ENVI Classic）
  ; ENVI_OPEN_FILE, input_file, r_fid=fid
  ; ENVI_FILE_QUERY, fid, dims=dims, nb=nb, nl=nl, ns=ns
  
END
"""

# ==========================================
# 步骤2：辐射定标
# ==========================================
"""
PRO Example_RadiometricCalibration
  COMPILE_OPT idl2
  e = ENVI()
  
  ; 打开输入影像
  input_file = 'C:\data\image.dat'
  raster = e.OpenRaster(input_file)
  
  ; 方法1：使用ENVITask（推荐方式，ENVI 5.x）
  ; 将DN值转换为辐射亮度值（Radiance）
  Task = ENVITASK('RadiometricCalibration')
  Task.INPUT_RASTER = raster
  Task.CALIBRATION_TYPE = 'Radiance'  ; 或 'Reflectance'
  Task.OUTPUT_DATA_TYPE = 'Double'
  Task.OUTPUT_RASTER_URI = 'C:\data\calibrated_radiance.dat'
  Task.Execute
  calibrated_raster = Task.OUTPUT_RASTER
  
  ; 方法2：使用ENVICalibrateRaster（虚拟栅格，不立即生成文件）
  ; calibrated_raster = ENVICalibrateRaster(raster, calibration='Radiance')
  
  ; 方法3：使用ENVI_DOIT进行增益偏移校正
  ; ENVI_OPEN_FILE, input_file, r_fid=fid
  ; ENVI_FILE_QUERY, fid, dims=dims, nb=nb
  ; 
  ; ; 定义增益和偏移值（每个波段对应一个值）
  ; ; gainOffset格式：[[gain1, gain2, ...], [offset1, offset2, ...]]
  ; gainOffset = [[2.0, 2.0, 2.0], [1.0, 1.0, 1.0]]  ; 示例值
  ; pos = LINDGEN(nb)  ; 所有波段
  ; 
  ; ENVI_DOIT, 'gainoff_doit', $
  ;   fid=fid, $
  ;   pos=pos, $
  ;   dims=dims, $
  ;   out_name='C:\data\calibrated.dat', $
  ;   gain=1./gainOffset[*,0], $  ; 增益（取倒数）
  ;   offset=gainOffset[*,1], $  ; 偏移
  ;   r_fid=r_fid, $
  ;   in_memory=0, $
  ;   OUT_DT = 4  ; 输出数据类型：4=Float
  
  PRINT, '辐射定标完成'
  
END
"""

# ==========================================
# 步骤3：大气校正
# ==========================================
"""
PRO Example_AtmosphericCorrection
  COMPILE_OPT idl2
  e = ENVI()
  
  ; 打开输入影像（通常为辐射定标后的影像）
  input_file = 'C:\data\calibrated_radiance.dat'
  raster = e.OpenRaster(input_file)
  
  ; 方法1：使用ENVIQUACRaster（快速大气校正，推荐方式）
  ; 适用于没有精确大气参数的快速处理
  sensor_type = 'Landsat TM/ETM/OLI'  ; 根据传感器类型设置
  quac_raster = ENVIQUACRaster(raster, sensor=sensor_type)
  
  ; 保存结果
  output_file = 'C:\data\atmospheric_corrected.dat'
  quac_raster.EXPORT, output_file, 'ENVI'
  
  ; 方法2：使用ENVI_DOIT进行QUAC大气校正
  ; ENVI_OPEN_FILE, input_file, r_fid=fid
  ; ENVI_FILE_QUERY, fid, dims=dims, nb=nb, sensor_type=sensor_type
  ; 
  ; ; 获取传感器类型
  ; sensor = envi_sensor_type(sensor_type)
  ; pos = LINDGEN(nb)  ; 所有波段
  ; 
  ; ; 执行快速大气校正
  ; ENVI_DOIT, 'envi_quac_doit', $
  ;   fid=fid, $
  ;   pos=pos, $
  ;   dims=dims, $
  ;   quac_sensor=sensor, $
  ;   out_name='C:\data\quac_output.dat', $
  ;   r_fid=r_fid
  
  ; 方法3：使用FLAASH大气校正（需要ENVI扩展，参数更复杂）
  ; Task = ENVITASK('AtmosphericCorrection')
  ; Task.INPUT_RASTER = raster
  ; Task.SENSOR_TYPE = 'Landsat'
  ; Task.ATMOSPHERIC_MODEL = 'Mid-Latitude Summer'
  ; Task.AEROSOL_MODEL = 'Urban'
  ; Task.AEROSOL_RETRIEVAL = 'None'
  ; Task.Execute
  
  PRINT, '大气校正完成'
  
END
"""

# ==========================================
# 步骤4：正射校正
# ==========================================
"""
PRO Example_Orthorectification
  COMPILE_OPT idl2
  e = ENVI()
  
  ; 打开输入影像
  input_file = 'C:\data\image.dat'
  raster = e.OpenRaster(input_file)
  
  ; 打开DEM文件（正射校正需要高程数据）
  dem_file = 'C:\data\dem.dat'
  ; 如果没有DEM，可以使用ENVI自带的全球DEM
  ; dem_file = FILEPATH('GMTED2010.jp2', root_dir=e.ROOT_DIR, subdirectory='data')
  dem_raster = e.OpenRaster(dem_file)
  
  ; 方法1：使用ENVITask进行RPC正射校正（推荐方式）
  ; 适用于有RPC参数的卫星影像（如GF1、GF2、WorldView等）
  Task = ENVITASK('RPCOrthorectification')
  Task.INPUT_RASTER = raster
  Task.DEM_RASTER = dem_raster
  Task.DEM_IS_HEIGHT_ABOVE_ELLIPSOID = 0  ; 0=椭球面以上高度，1=海拔高度
  Task.OUTPUT_PIXEL_SIZE = [8.0, 8.0]     ; 输出像元大小（米）
  Task.RESAMPLING = 'Bilinear'            ; 重采样方法：'Nearest Neighbor', 'Bilinear', 'Cubic Convolution'
  Task.GRID_SPACING = 10                    ; 网格间距
  Task.OUTPUT_RASTER_URI = 'C:\data\orthorectified.dat'
  Task.Execute
  ortho_raster = Task.OUTPUT_RASTER
  
  ; 方法2：使用参考影像进行正射校正（带控制点）
  ; Task = ENVITASK('RPCOrthorectificationUsingReferenceImage')
  ; Task.INPUT_RASTER = raster
  ; Task.INPUT_DEM_RASTER = dem_raster
  ; Task.INPUT_REFERENCE_RASTER = reference_raster  ; 参考影像
  ; Task.REQUESTED_NUMBER_OF_GCPS = 1000            ; 请求的控制点数量
  ; Task.OUTPUT_PIXEL_SIZE = [8.0, 8.0]
  ; Task.RESAMPLING = 'Bilinear'
  ; Task.Execute
  
  PRINT, '正射校正完成'
  
END
"""

# ==========================================
# 完整工作流程示例
# ==========================================
"""
PRO CompleteWorkflow
  ; 完整的遥感影像处理流程：开启影像 -> 辐射定标 -> 大气校正 -> 正射校正
  COMPILE_OPT idl2
  
  ; 初始化ENVI
  e = ENVI()
  
  ; ========== 步骤1：开启遥感影像 ==========
  input_file = 'C:\data\raw_image.dat'
  raster = e.OpenRaster(input_file)
  PRINT, '已打开影像文件: ', input_file
  
  ; ========== 步骤2：辐射定标 ==========
  ; 将DN值转换为辐射亮度值
  Task_RadCal = ENVITASK('RadiometricCalibration')
  Task_RadCal.INPUT_RASTER = raster
  Task_RadCal.CALIBRATION_TYPE = 'Radiance'
  Task_RadCal.OUTPUT_DATA_TYPE = 'Double'
  Task_RadCal.OUTPUT_RASTER_URI = e.GetTemporaryFilename()
  Task_RadCal.Execute
  radiance_raster = Task_RadCal.OUTPUT_RASTER
  PRINT, '辐射定标完成'
  
  ; ========== 步骤3：大气校正 ==========
  ; 快速大气校正
  sensor_type = 'Landsat TM/ETM/OLI'  ; 根据实际传感器类型修改
  quac_raster = ENVIQUACRaster(radiance_raster, sensor=sensor_type)
  PRINT, '大气校正完成'
  
  ; ========== 步骤4：正射校正 ==========
  ; 打开DEM
  dem_file = FILEPATH('GMTED2010.jp2', root_dir=e.ROOT_DIR, subdirectory='data')
  dem_raster = e.OpenRaster(dem_file)
  
  ; 执行正射校正
  Task_Ortho = ENVITASK('RPCOrthorectification')
  Task_Ortho.INPUT_RASTER = quac_raster
  Task_Ortho.DEM_RASTER = dem_raster
  Task_Ortho.DEM_IS_HEIGHT_ABOVE_ELLIPSOID = 0
  Task_Ortho.OUTPUT_PIXEL_SIZE = [8.0, 8.0]
  Task_Ortho.RESAMPLING = 'Bilinear'
  Task_Ortho.GRID_SPACING = 10
  Task_Ortho.OUTPUT_RASTER_URI = 'C:\data\final_output.dat'
  Task_Ortho.Execute
  final_raster = Task_Ortho.OUTPUT_RASTER
  PRINT, '正射校正完成'
  
  ; 显示结果
  View = e.GetView()
  Layer = View.CreateLayer(final_raster)
  View.Zoom, 1, /full_extent
  
  ; 清理临时文件
  Task_RadCal.OUTPUT_RASTER.Close
  radiance_raster.Close
  
  PRINT, '处理流程完成！'
  
END
"""

# ==========================================
# 辅助函数：ENVI初始化与关闭
# ==========================================
"""
; ENVI初始化（无GUI模式）
PRO StartENVI, showProcess=showProcess
  COMPILE_OPT idl2
  ENVI, /restore_base_save_files
  ENVI_BATCH_INIT, NO_STATUS_WINDOW = 1 - KEYWORD_SET(showProcess)
END

; ENVI关闭
PRO EndENVI
  ENVI_BATCH_EXIT
END
"""

# ==========================================
# 注意事项
# ==========================================
"""
重要提示：
1. ENVI 5.x版本推荐使用ENVITask和ENVIRaster对象进行编程
2. ENVI Classic版本使用ENVI_DOIT和文件ID（FID）方式
3. 辐射定标需要知道传感器的增益和偏移参数
4. 大气校正中QUAC方法快速但精度较低，FLAASH方法精度高但需要更多参数
5. 正射校正需要DEM数据，RPC正射校正适用于有RPC参数的卫星影像
6. 处理大文件时注意内存管理，及时关闭不需要的栅格对象
7. 所有文件路径需要根据实际情况修改
8. 传感器类型需要根据实际数据源设置（如Landsat、GF1、GF2等）
"""

