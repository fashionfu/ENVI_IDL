PRO test_ENVIUI_RunTask
  ;����ENVI
  COMPILE_OPT idl2
  e = ENVI()
  
  ;��դ��
  mssfile = FILEPATH('qb_boulder_msi', subdirectory=['data'], root_dir=e.ROOT_DIR)
  mss_raster = e.OpenRaster(mssfile)
  panfile = FILEPATH('qb_boulder_pan', subdirectory=['data'], root_dir=e.ROOT_DIR)
  pan_raster = e.OpenRaster(panfile)

  ;��ʼ��ENVITask
  task = ENVITask('NNDiffusePanSharpening')
  
  ;����ENVITask���棬���йܺ�������
  e.UI.RunTask, task
  
END