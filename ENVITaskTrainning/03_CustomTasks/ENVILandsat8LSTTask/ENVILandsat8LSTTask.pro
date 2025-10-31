PRO ENVILandsat8LSTTask, $
  MSS_RASTER=MSS_RASTER, $
  THE_RASTER=THE_RASTER, $
  Transmission=Transmission, $
  upwelling_RADIANCE=upwelling_RADIANCE, $
  downwelling_RADIANCE=downwelling_RADIANCE, $
  OUTPUT_Raster=OUTPUT_Raster, $
  OUTPUT_URI=OUTPUT_URI
  
  COMPILE_OPT idl2
  e=envi()

  ;获取K1、K2
  k1 = (the_raster.METADATA['THERMAL K1'])[0] & k1=STRTRIM(k1,2)
  k2 = (the_raster.METADATA['THERMAL K2'])[0] & k2=STRTRIM(k2,2)

  ;多光谱流程：QUAC>NDVI>植被覆盖度>地表比辐射率
  ;  quac_raster = ENVIQUACRaster(mss_raster, sensor='Landsat TM/ETM/OLI')
  ndvi_raster = ENVISpectralIndexRaster(mss_raster, 'ndvi')
  veg_exp = '(b1 GT 0.7)*1+(b1 LT 0.05)*0+(b1 GE 0.05 AND b1 LE 0.7)*((b1-0.05)/(0.7-0.05))'
  veg_raster = ENVIPixelwiseBandMathRaster(ndvi_raster, veg_exp)
  ratio_exp = '0.004*b1+0.986'
  ratio_raster = ENVIPixelwiseBandMathRaster(veg_raster, ratio_exp)

  ;热红外流程：波段裁剪>辐射定标
  b10_raster = ENVISubsetRaster(the_raster, bands=[0])
  b10rad_raster = ENVICalibrateRaster(b10_raster, calibration='Radiance')

  ;需要移除b10rad_raster的K1、K2元数据，否则在波段组合时会报错
  b10rad_raster.METADATA.RemoveItem, 'THERMAL K1'
  b10rad_raster.METADATA.RemoveItem, 'THERMAL K2'

  ;计算得到同温度下的黑体辐射亮度图像
  ;(b2-0.75-0.9*(1-b1)*1.29)/(0.9*b1)
  ;b1：地表比辐射率图像
  ;b2：Band10辐射亮度图像
  ;将所需的b1和b2做波段组合
  gridTask = ENVITask('BuildGridDefinitionFromRaster')
  gridTask.INPUT_RASTER = ratio_raster
  gridTask.Execute
  ls_raster = ENVILayerStackRaster([ratio_raster, b10rad_raster], $
    grid_definition=gridTask.OUTPUT_GRIDDEFINITION)
  ;大气剖面参数转换为字符串，加入公式中
  t = STRTRIM(Transmission,2)       ;0.9
  up = STRTRIM(upwelling_RADIANCE,2) ;0.75
  down = STRTRIM(downwelling_RADIANCE,2);1.29
  black_exp = '(b2-'+up+'-'+t+'*(1-b1)*'+down+')/('+t+'*b1)'
  black_raster = ENVIPixelwiseBandMathRaster(ls_raster, black_exp)

  ;计算地表温度
  ;(1321.08)/alog(774.89/b1+1)-273
  Task = ENVITask('PixelwiseBandMathRaster')
  Task.INPUT_RASTER = black_raster
  Task.EXPRESSION = k2+'/alog('+k1+'/b1+1)-273.15'
  Task.OUTPUT_RASTER_URI = e.GetTemporaryFilename()
  Task.Execute
  output_raster = Task.OUTPUT_RASTER
END