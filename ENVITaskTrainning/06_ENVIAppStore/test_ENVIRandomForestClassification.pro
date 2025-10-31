PRO test_ENVIRandomForestClassification
  COMPILE_OPT idl2
  e=envi()
  ;设置输入输出文件路径
  input_file = FILEPATH('ag_08_quac.dat', root_dir=ROUTINE_DIR(), subdirectory=['data'])
  roi_file = FILEPATH('08_TrainingSample.xml', root_dir=ROUTINE_DIR(), subdirectory=['data'])
  out_file = e.GetTemporaryFilename()

  ;打开栅格和训练样本
  raster = e.OpenRaster(input_file)
  rois = e.OpenROI(roi_file)

  ;随机森林分类
  task = ENVITask('RandomForestClassification')
  task.input_raster = raster
  task.input_rois = rois
  task.numberOfTrees = 10 ;为了缩短测试时间，默认100
  task.showMsg = 0 ;不显示提示对话框
  task.display = 0 ;不自动显示结果
  ;task.output_raster_uri = ;如果不设置输出路径，则输出到临时文件中
  task.Execute

  ;掩膜背景
  shp_file = FILEPATH('mask.shp', root_dir=ROUTINE_DIR(), subdirectory=['data','maskshp'])
  ovector = e.OpenVector(shp_file)
  ;矩形裁剪
  sub_raster = ENVISubsetRaster(task.output_raster, sub_rect=ovector.DATA_RANGE, $
    spatialref=ovector.COORD_SYS)
  ;矢量掩膜背景
  masktask = ENVITask('VectorMaskRaster')
  masktask.input_raster = sub_raster
  masktask.input_mask_vector = ovector
  masktask.data_ignore_value = 0
  masktask.output_raster_uri = out_file
  masktask.Execute

  ;加载掩膜后分类图像
  e.data.add, masktask.output_raster
  view = e.GetView()
  layer = view.CreateLayer(masktask.output_raster)
END