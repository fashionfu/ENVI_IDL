PRO test_ENVIUI_SelectTaskParameters
  ;启动ENVI
  COMPILE_OPT idl2
  e = ENVI()
  
  ;打开栅格
  mssfile = FILEPATH('qb_boulder_msi', subdirectory=['data'], root_dir=e.ROOT_DIR)
  mss_raster = e.OpenRaster(mssfile)
  panfile = FILEPATH('qb_boulder_pan', subdirectory=['data'], root_dir=e.ROOT_DIR)
  pan_raster = e.OpenRaster(panfile)

  ;初始化ENVITask
  task = ENVITask('NNDiffusePanSharpening')

  ;弹出ENVITask界面，交互式设置参数
  result = e.UI.SelectTaskParameters(task)
  IF result NE 'OK' THEN RETURN

  ;执行ENVITask
  task.Execute

  ;获取处理结果
  output_raster = task.OUTPUT_RASTER

  ;添加结果到Data Manager并加载显示
  e.DATA.Add, output_raster
  view = e.GetView()
  layer = view.CreateLayer(output_raster)
END