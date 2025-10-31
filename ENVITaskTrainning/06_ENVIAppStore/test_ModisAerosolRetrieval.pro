PRO test_ModisAerosolRetrieval
  COMPILE_OPT idl2
  e=envi()
  ;
  input_dir = FILEPATH('modis',root_dir=ROUTINE_DIR(),subdirectory=['data'])
  hdf_files = FILE_SEARCH(input_dir, '*.hdf', count=count, /fold_case)
  IF count EQ 0 THEN RETURN
  ;ʹ�õ�ǰĿ¼��Ϊ���·��
  CD, current=output_dir

  ;���ұ��ļ�
  lut_file = FILEPATH('LookupTable.dat', root_dir=input_dir)
  lut_raster = e.OpenRaster(lut_file)

  view = e.GetView()

  ;��ʼ�����ܽ�����task����ʼ������
  task = ENVITask('ModisAerosolRetrievalHan')
  FOR i=0, count-1 DO BEGIN
    output_file = FILEPATH(FILE_BASENAME(hdf_files[i],'.hdf',/fold_case)+ $
      '_AOD.dat', root_dir=output_dir)
    ;
    task.input_hdf_file = hdf_files[i]
    task.raster_lut = lut_raster
    task.output_raster_uri = output_file
    task.Execute

    ;��ʾ���
    IF task.display THEN layer = view.CreateLayer(task.output_raster)
  ENDFOR
END

