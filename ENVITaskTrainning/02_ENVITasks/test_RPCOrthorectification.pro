PRO test_RPCOrthorectification
  COMPILE_OPT idl2
  e = ENVI()
  
  ;输入文件
  input_file = 'C:\01-高分一号PMS数据\GF1_PMS2_E104.0_N36.0_20140724_L1A0000284766-MSS2.xml'
  input_raster = e.OpenRaster(input_file)
  
  ;打开DEM
  dem_file = FILEPATH('GMTED2010.jp2', root_dir=e.ROOT_DIR, subdirectory='data')
  dem_raster = e.OpenRaster(dem_file)
  
  ;正射校正
  Task = ENVITask('RPCOrthorectification')
  Task.INPUT_RASTER = input_raster
  Task.DEM_RASTER = dem_raster
  Task.OUTPUT_PIXEL_SIZE = [8,8]
  Task.Execute
  
  DataColl = e.DATA
  DataColl.Add, Task.OUTPUT_RASTER
  
  View = e.GetView()
  Layer = View.CreateLayer(Task.OUTPUT_RASTER)
END