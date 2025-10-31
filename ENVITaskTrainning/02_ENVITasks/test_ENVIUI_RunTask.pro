PRO test_ENVIUI_RunTask
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
  
  ;弹出ENVITask界面，并托管后续处理
  e.UI.RunTask, task
  
END