PRO test_1202VFCTask,                   $
  input_raster = input_raster, $ ;输入栅格
  minimum_ndvi = minimum_ndvi, $ ;最小NDVI值，默认为0.05
  maximum_ndvi = maximum_ndvi, $ ;最大NDVI值，默认为0.70
  output_uri   = output_uri      ;输出文件

  COMPILE_OPT idl2
  e = ENVI()

  ;计算NDVI
  ndvi_raster = ENVISpectralIndexRaster(input_raster, 'ndvi')

  ;转字符串
  mins = STRTRIM(minimum_ndvi, 2)
  maxs = STRTRIM(maximum_ndvi, 2)

  ;构建VFC计算公式
  vfc_exp = '(b1 gt '+maxs+')*1+(b1 lt '+mins+')*0+(b1 ge '+mins+$
    ' and b1 le '+maxs+')*(b1-'+mins+')/('+maxs+'-'+mins+')'

  ;检查输出文件扩展名，判断是否需要导出为TIFF格式
  output_uri_upper = STRUPCASE(output_uri)
  need_tiff = (STRPOS(output_uri_upper, '.TIF') GE 0) OR (STRPOS(output_uri_upper, '.TIFF') GE 0)
  
  IF need_tiff THEN BEGIN
    ;如果需要TIFF格式，先输出为临时ENVI文件
    temp_output = e.GetTemporaryFilename('dat')
    Task = ENVITask('PixelwiseBandMathRaster')
    Task.INPUT_RASTER = ndvi_raster
    Task.EXPRESSION = vfc_exp
    Task.DATA_IGNORE_VALUE = -999
    Task.OUTPUT_RASTER_URI = temp_output
    Task.Execute
    
    ;将ENVI格式导出为TIFF格式
    output_raster = Task.OUTPUT_RASTER
    output_raster.Export, output_uri, 'TIFF'
    output_raster.Close
  ENDIF ELSE BEGIN
    ;如果不需要TIFF格式，直接输出ENVI格式
    Task = ENVITask('PixelwiseBandMathRaster')
    Task.INPUT_RASTER = ndvi_raster
    Task.EXPRESSION = vfc_exp
    Task.DATA_IGNORE_VALUE = -999
    Task.OUTPUT_RASTER_URI = output_uri
    Task.Execute
  ENDELSE
END

