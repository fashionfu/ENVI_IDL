PRO test_ENVIUI_SelectTaskParameters
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

  ;����ENVITask���棬����ʽ���ò���
  result = e.UI.SelectTaskParameters(task)
  IF result NE 'OK' THEN RETURN

  ;ִ��ENVITask
  task.Execute

  ;��ȡ������
  output_raster = task.OUTPUT_RASTER

  ;��ӽ����Data Manager��������ʾ
  e.DATA.Add, output_raster
  view = e.GetView()
  layer = view.CreateLayer(output_raster)
END