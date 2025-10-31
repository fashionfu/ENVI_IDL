PRO test_ModisAerosolRetrieval
  COMPILE_OPT idl2
  e=envi()
  ;
  input_dir = FILEPATH('modis',root_dir=ROUTINE_DIR(),subdirectory=['data'])
  hdf_files = FILE_SEARCH(input_dir, '*.hdf', count=count, /fold_case)
  IF count EQ 0 THEN RETURN
  ;使用当前目录作为输出路径
  CD, current=output_dir

  ;查找表文件
  lut_file = FILEPATH('LookupTable.dat', root_dir=input_dir)
  lut_raster = e.OpenRaster(lut_file)

  view = e.GetView()

  ;初始化气溶胶反演task，开始批处理
  task = ENVITask('ModisAerosolRetrievalHan')
  FOR i=0, count-1 DO BEGIN
    output_file = FILEPATH(FILE_BASENAME(hdf_files[i],'.hdf',/fold_case)+ $
      '_AOD.dat', root_dir=output_dir)
    ;
    task.input_hdf_file = hdf_files[i]
    task.raster_lut = lut_raster
    task.output_raster_uri = output_file
    task.Execute

    ;显示结果
    IF task.display THEN layer = view.CreateLayer(task.output_raster)
  ENDFOR
END

