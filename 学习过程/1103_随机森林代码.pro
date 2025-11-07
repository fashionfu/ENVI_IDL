PRO test1103_water_rf_extraction

  COMPILE_OPT idl2
  e=ENVI()

  print, '========================================='
  print, '开始随机森林监督分类水体提取'
  print, '========================================='

  ;============================================
  ; 打开影像和ROI
  ;============================================
  file = 'E:\1021WaterData\GF6_PMS_E108.6_N32.8_20230313_L1A1420301264_1022result\GF6_PMS_E108.6_N32.8_20230313_L1A1420301264-MUX_envi62_radio_flaash_rpcortho.dat'
  
  IF ~FILE_TEST(file) THEN BEGIN
    print, '错误：找不到输入影像文件：' + file
    RETURN
  ENDIF
  
  input_raster = e.OpenRaster(file)

  roi_file = 'E:\1021WaterData\GF6_PMS_E108.6_N32.8_20230313_L1A1420301264_1022result\1024waterTry.xml'
  
  IF ~FILE_TEST(roi_file) THEN BEGIN
    print, '错误：找不到训练样本文件：' + roi_file
    RETURN
  ENDIF
  
  rois = e.OpenROI(roi_file)
  print, '✓ 成功加载训练样本：' + roi_file
  print, '  ROI数量：' + STRTRIM(N_ELEMENTS(rois), 2)

  ;============================================
  ; 随机森林分类（直接使用ROI！）
  ;============================================
  print, '正在进行随机森林分类（这可能需要几分钟）...'
  
  ; 定义输出路径
  output_dir = 'E:\1021WaterData\GF6_PMS_E108.6_N32.8_20230313_L1A1420301264_1022result\1107'
  
  ; 确保输出目录存在
  IF ~FILE_TEST(output_dir, /DIRECTORY) THEN BEGIN
    FILE_MKDIR, output_dir
    print, '✓ 创建输出目录：' + output_dir
  ENDIF
  
  rf_output_uri = output_dir + PATH_SEP() + 'water_rf_classified.dat'
  
  ; 删除已存在的文件
  IF FILE_TEST(rf_output_uri) THEN BEGIN
    FILE_DELETE, rf_output_uri, /QUIET, /ALLOW_NONEXISTENT
    hdr_file = FILE_DIRNAME(rf_output_uri) + PATH_SEP() + FILE_BASENAME(rf_output_uri, '.dat') + '.hdr'
    IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
  ENDIF
  
  RFTask = ENVITask('RandomForestClassification')
  RFTask.input_raster = input_raster      ; 小写
  RFTask.input_rois = rois                ; 小写
  RFTask.numberOfTrees = 100              ; 驼峰命名！
  RFTask.output_raster_uri = rf_output_uri
  RFTask.Execute
  
  classified_raster = RFTask.output_raster
  print, '✓ 随机森林分类完成'
  print, '  分类结果已保存：' + rf_output_uri
  
  ; 为初始分类结果设置元数据（以便正确显示颜色）
  tempRaster = e.OpenRaster(rf_output_uri)
  ; 注意：classes应该等于class lookup的长度（3），而不是实际类别数（2）
  IF ~tempRaster.METADATA.HasTag('classes') THEN tempRaster.METADATA.AddItem, 'classes', 3 ELSE tempRaster.METADATA.UpdateItem, 'classes', 3
  IF ~tempRaster.METADATA.HasTag('class names') THEN tempRaster.METADATA.AddItem, 'class names', ['Unclassified', 'Non-Water', 'Water'] ELSE tempRaster.METADATA.UpdateItem, 'class names', ['Unclassified', 'Non-Water', 'Water']
  IF ~tempRaster.METADATA.HasTag('class lookup') THEN tempRaster.METADATA.AddItem, 'class lookup', [[0,0,0], [128,128,128], [0,255,128]] ELSE tempRaster.METADATA.UpdateItem, 'class lookup', [[0,0,0], [128,128,128], [0,255,128]]
  tempRaster.WriteMetadata
  tempRaster.Close
  tempRaster = !NULL  ; 明确释放引用

  ;============================================
  ; 后处理 - 分类平滑
  ;============================================
  print, '正在进行分类平滑处理...'
  
  smoothSize = 3
  smooth_output_uri = output_dir + PATH_SEP() + 'water_rf_smooth.dat'
  
  ; 删除已存在的文件（包括所有相关文件）
  IF FILE_TEST(smooth_output_uri) THEN BEGIN
    print, '  删除已存在的平滑结果文件...'
    FILE_DELETE, smooth_output_uri, /QUIET, /ALLOW_NONEXISTENT
    hdr_file = FILE_DIRNAME(smooth_output_uri) + PATH_SEP() + FILE_BASENAME(smooth_output_uri, '.dat') + '.hdr'
    IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
    ; 等待文件系统更新
    WAIT, 0.1
  ENDIF
  
  ; 再次确认文件不存在
  IF FILE_TEST(smooth_output_uri) THEN BEGIN
    print, '  警告：文件删除失败，尝试强制删除...'
    FILE_DELETE, smooth_output_uri, /FORCE
    WAIT, 0.1
  ENDIF
  
  SmoothTask = ENVITASK('ClassificationSmoothing')
  SmoothTask.INPUT_RASTER = classified_raster
  SmoothTask.KERNEL_SIZE = smoothSize
  SmoothTask.OUTPUT_RASTER_URI = smooth_output_uri
  SmoothTask.EXECUTE
  
  print, '✓ 分类平滑完成'
  print, '  平滑结果已保存：' + smooth_output_uri
  
  ; 为平滑结果设置元数据
  tempRaster = e.OpenRaster(smooth_output_uri)
  ; 注意：classes应该等于class lookup的长度（3），而不是实际类别数（2）
  IF ~tempRaster.METADATA.HasTag('classes') THEN tempRaster.METADATA.AddItem, 'classes', 3 ELSE tempRaster.METADATA.UpdateItem, 'classes', 3
  IF ~tempRaster.METADATA.HasTag('class names') THEN tempRaster.METADATA.AddItem, 'class names', ['Unclassified', 'Non-Water', 'Water'] ELSE tempRaster.METADATA.UpdateItem, 'class names', ['Unclassified', 'Non-Water', 'Water']
  IF ~tempRaster.METADATA.HasTag('class lookup') THEN tempRaster.METADATA.AddItem, 'class lookup', [[0,0,0], [128,128,128], [0,255,128]] ELSE tempRaster.METADATA.UpdateItem, 'class lookup', [[0,0,0], [128,128,128], [0,255,128]]
  tempRaster.WriteMetadata
  tempRaster.Close
  tempRaster = !NULL  ; 明确释放引用

  ;============================================
  ; 后处理 - 去除孤立像元
  ;============================================
  print, '正在去除孤立像元...'
  
  sieving_output_uri = output_dir + PATH_SEP() + 'water_rf_sieved.dat'
  
  ; 删除已存在的文件（包括所有相关文件）
  IF FILE_TEST(sieving_output_uri) THEN BEGIN
    print, '  删除已存在的去噪结果文件...'
    FILE_DELETE, sieving_output_uri, /QUIET, /ALLOW_NONEXISTENT
    hdr_file = FILE_DIRNAME(sieving_output_uri) + PATH_SEP() + FILE_BASENAME(sieving_output_uri, '.dat') + '.hdr'
    IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
    WAIT, 0.1
  ENDIF
  
  ; 再次确认文件不存在
  IF FILE_TEST(sieving_output_uri) THEN BEGIN
    print, '  警告：文件删除失败，尝试强制删除...'
    FILE_DELETE, sieving_output_uri, /FORCE
    WAIT, 0.1
  ENDIF
  
  ; 重新打开平滑结果文件，因为之前的对象可能已失效
  smooth_raster = e.OpenRaster(smooth_output_uri)
  
  SievingTask = ENVITASK('ClassificationSieving')
  SievingTask.INPUT_RASTER = smooth_raster
  SievingTask.MINIMUM_SIZE = 9
  SievingTask.OUTPUT_RASTER_URI = sieving_output_uri
  SievingTask.EXECUTE
  
  ; 关闭smooth_raster，释放资源
  smooth_raster.Close
  smooth_raster = !NULL
  
  print, '✓ 孤立像元去除完成'
  print, '  去噪结果已保存：' + sieving_output_uri
  
  ; 为去噪结果设置元数据
  tempRaster = e.OpenRaster(sieving_output_uri)
  ; 注意：classes应该等于class lookup的长度（3），而不是实际类别数（2）
  IF ~tempRaster.METADATA.HasTag('classes') THEN tempRaster.METADATA.AddItem, 'classes', 3 ELSE tempRaster.METADATA.UpdateItem, 'classes', 3
  IF ~tempRaster.METADATA.HasTag('class names') THEN tempRaster.METADATA.AddItem, 'class names', ['Unclassified', 'Non-Water', 'Water'] ELSE tempRaster.METADATA.UpdateItem, 'class names', ['Unclassified', 'Non-Water', 'Water']
  IF ~tempRaster.METADATA.HasTag('class lookup') THEN tempRaster.METADATA.AddItem, 'class lookup', [[0,0,0], [128,128,128], [0,255,128]] ELSE tempRaster.METADATA.UpdateItem, 'class lookup', [[0,0,0], [128,128,128], [0,255,128]]
  tempRaster.WriteMetadata
  tempRaster.Close
  tempRaster = !NULL  ; 明确释放引用

  ;============================================
  ; 后处理 - 去除小斑块
  ;============================================
  print, '正在进行分类聚合，去除小斑块...'
  
  minArea = 0.5
  output_raster_uri = output_dir + PATH_SEP() + 'water_rf_result.dat'
  
  ; 删除已存在的文件（包括所有相关文件）
  IF FILE_TEST(output_raster_uri) THEN BEGIN
    print, '  检测到已存在的输出文件，正在删除...'
    FILE_DELETE, output_raster_uri, /QUIET, /ALLOW_NONEXISTENT
    hdr_file = FILE_DIRNAME(output_raster_uri) + PATH_SEP() + FILE_BASENAME(output_raster_uri, '.dat') + '.hdr'
    IF FILE_TEST(hdr_file) THEN FILE_DELETE, hdr_file, /QUIET, /ALLOW_NONEXISTENT
    WAIT, 0.1
  ENDIF
  
  ; 再次确认文件不存在
  IF FILE_TEST(output_raster_uri) THEN BEGIN
    print, '  警告：文件删除失败，尝试强制删除...'
    FILE_DELETE, output_raster_uri, /FORCE
    WAIT, 0.1
  ENDIF
  
  ; 重新打开去噪结果文件，因为之前的对象可能已失效
  sieved_raster = e.OpenRaster(sieving_output_uri)
  
  AggregationTask = ENVITASK('ClassificationAggregation')
  ref = input_raster.SPATIALREF
  aggregateSize = ref EQ !NULL ? 25 : minArea*1000000/PRODUCT(ref.PIXEL_SIZE)
  ; 确保最小尺寸至少为5个像素
  aggregateSize = aggregateSize > 5 ? aggregateSize : 5
  AggregationTask.INPUT_RASTER = sieved_raster
  AggregationTask.MINIMUM_SIZE = aggregateSize
  AggregationTask.OUTPUT_RASTER_URI = output_raster_uri
  AggregationTask.EXECUTE
  
  ; 关闭sieved_raster，释放资源
  sieved_raster.Close
  sieved_raster = !NULL
  
  print, '✓ 分类聚合完成'

  ;============================================
  ; 更新元数据
  ;============================================
  print, '正在更新元数据...'
  
  waterRaster = e.OpenRaster(output_raster_uri)
  
  ; 注意：RandomForest分类输出值是1和2，不是0和1
  ; 因此需要3个颜色（索引0,1,2）来正确映射
  ; 索引0：占位（值0不存在）
  ; 索引1：对应值1（Non-Water）
  ; 索引2：对应值2（Water）
  ; classes应该等于class lookup的长度（3），而不是实际类别数（2）
  
  IF ~waterRaster.METADATA.HasTag('classes') THEN BEGIN
    waterRaster.METADATA.AddItem, 'classes', 3
  ENDIF ELSE BEGIN
    waterRaster.METADATA.UpdateItem, 'classes', 3
  ENDELSE
  
  ; 设置类别名称 - 需要3个元素（对应索引0,1,2）
  IF ~waterRaster.METADATA.HasTag('class names') THEN BEGIN
    waterRaster.METADATA.AddItem, 'class names', ['Unclassified', 'Non-Water', 'Water']
  ENDIF ELSE BEGIN
    waterRaster.METADATA.UpdateItem, 'class names', ['Unclassified', 'Non-Water', 'Water']
  ENDELSE
  
  ; 设置颜色查找表 - 需要3个颜色（对应索引0,1,2）
  ; 索引0：[0,0,0] 黑色（占位，值0不存在）
  ; 索引1：[128,128,128] 灰色（对应值1=Non-Water）
  ; 索引2：[0,255,128] 青色（对应值2=Water）
  IF ~waterRaster.METADATA.HasTag('class lookup') THEN BEGIN
    waterRaster.METADATA.AddItem, 'class lookup', [[0,0,0], [128,128,128], [0,255,128]]
  ENDIF ELSE BEGIN
    waterRaster.METADATA.UpdateItem, 'class lookup', [[0,0,0], [128,128,128], [0,255,128]]
  ENDELSE
  
  IF ~waterRaster.METADATA.HasTag('data ignore value') THEN BEGIN
    waterRaster.METADATA.AddItem, 'data ignore value', 0
  ENDIF ELSE BEGIN
    waterRaster.METADATA.UpdateItem, 'data ignore value', 0
  ENDELSE
  
  waterRaster.WriteMetadata
  
  print, '✓ 元数据更新完成'

  ;============================================
  ; 添加到Data Manager
  ;============================================
  e.DATA.Add, waterRaster
  print, '✓ 结果已添加到Data Manager'

  ;============================================
  ; 转换为Shapefile矢量
  ;============================================
  print, '正在转换为Shapefile矢量...'
  
  output_vector_uri = output_dir + PATH_SEP() + 'water_rf_result.shp'
  
  IF FILE_TEST(output_vector_uri) THEN BEGIN
    base_name = FILE_DIRNAME(output_vector_uri) + PATH_SEP() + FILE_BASENAME(output_vector_uri, '.shp')
    FILE_DELETE, base_name + '.shp', /QUIET, /ALLOW_NONEXISTENT
    FILE_DELETE, base_name + '.shx', /QUIET, /ALLOW_NONEXISTENT
    FILE_DELETE, base_name + '.dbf', /QUIET, /ALLOW_NONEXISTENT
    FILE_DELETE, base_name + '.prj', /QUIET, /ALLOW_NONEXISTENT
  ENDIF
  
  waterRaster.Close
  waterRaster = e.OpenRaster(output_raster_uri)
  
  FinalVectorTask = ENVITASK('ClassificationToShapefile')
  FinalVectorTask.INPUT_RASTER = waterRaster
  FinalVectorTask.EXPORT_CLASSES = ['Water']
  FinalVectorTask.OUTPUT_VECTOR_URI = output_vector_uri
  FinalVectorTask.EXECUTE
  
  e.DATA.Add, FinalVectorTask.OUTPUT_VECTOR
  print, '✓ 矢量转换完成'

  ;============================================
  ; 完成提示
  ;============================================
  print, ''
  print, '========================================='
  print, '✓✓✓ 随机森林水体提取完成！ ✓✓✓'
  print, '========================================='
  print, '训练样本：' + roi_file
  print, '输出目录：' + output_dir
  print, '  1. 初始分类结果：' + rf_output_uri
  print, '  2. 平滑后结果：' + smooth_output_uri
  print, '  3. 去噪后结果：' + sieving_output_uri
  print, '  4. 最终分类结果：' + output_raster_uri
  print, '  5. 矢量结果：' + output_vector_uri
  print, '========================================='
  print, ''
  print, '随机森林通常比最大似然效果更好！'
  print, '如需进一步优化，可增加训练样本的多样性。'
  print, '========================================='

END
