PRO Landsat8LST_Task, inputURI=inputURI,      $
  Transmission=Transmission,                  $
  upwelling_RADIANCE=upwelling_RADIANCE,      $
  downwelling_RADIANCE=downwelling_RADIANCE,  $
  OUTPUT_RASTER_URI=outputURI

  COMPILE_OPT IDL2, hidden
  e=ENVI(/current)

  ;打开LC8 MTL.txt文件
  Rasters = e.OpenRaster(inputURI)

  MulRaster = Rasters[0]
  TIRRaster = Rasters[3]

  K1_CONSTANT = (TIRRaster.METADATA['THERMAL K1'])[0]
  K2_CONSTANT = (TIRRaster.METADATA['THERMAL K2'])[0]

  PRINT, K1_CONSTANT, K2_CONSTANT

  ;第10波段（热红外）定标为辐射亮度值
  Task = ENVITASK('RadiometricCalibration')
  Task.INPUT_RASTER = ENVISUBSETRASTER(TIRRaster, Bands=[0])
  Task.OUTPUT_DATA_TYPE = 'Double'
  Task.Execute
  tirFile = Task.OUTPUT_RASTER_URI
  Task.OUTPUT_RASTER.Close
  ;重新打开热红外定标结果
  ENVI_OPEN_FILE, tirFile, r_fid=tirFid

  redFid = ENVIRASTERTOFID(ENVISUBSETRASTER(MulRaster, Bands=[3]))
  nirFid = ENVIRASTERTOFID(ENVISUBSETRASTER(MulRaster, Bands=[4]))
  ;
  t_fid = [redFid,nirFid,tirFid]
  PRINT, t_fid
  pos = [0,0,0]
  exp = 'LST_Formula(b1,b2,b3,'+ $
    STRCOMPRESS(STRJOIN([Transmission,upwelling_RADIANCE,downwelling_RADIANCE,$
    K1_CONSTANT,K2_CONSTANT],','),/REMOVE_ALL)+')'

  ENVI_FILE_QUERY, tirFid, dims=dims, fname=tirFile
  ENVI_DOIT, 'math_doit',          $
    fid=t_fid, pos=pos, dims=dims, $
    exp=exp, out_name=outputURI,   $
    r_fid=r_fid

  ;删除定标结果
  ENVI_FILE_MNG, id=tirFid, /REMOVE, /DELETE

  OUTPUT_RASTER = ENVIFIDTORASTER(r_fid)
END


FUNCTION LST_Formula,red,nir,b10,t,up,down,k1,k2
  ;计算NDVI
  ndvi=(FLOAT(nir)-red)/(FLOAT(nir)+red)
  ;计算植被覆盖度
  Pv = (ndvi GT 0.05 AND ndvi LT 0.7)*((ndvi-0.05)/(0.7-0.05))+$
    (ndvi LE 0.05)*0 + (ndvi GE 0.7)*1
  ;计算地表比辐射率
  DBBFSL = 0.004*Pv+0.986
  ;计算同温度下黑体辐射亮度
  BsT=(b10-up-t*(1-DBBFSL)*down)/(t*DBBFSL)
  ;计算地表温度
  Temperature = (K2)/ALOG(K1/BsT+1)-273.15
  RETURN, Temperature
END