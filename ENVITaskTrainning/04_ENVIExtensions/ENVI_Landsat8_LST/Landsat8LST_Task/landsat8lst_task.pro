PRO Landsat8LST_Task, inputURI=inputURI,      $
  Transmission=Transmission,                  $
  upwelling_RADIANCE=upwelling_RADIANCE,      $
  downwelling_RADIANCE=downwelling_RADIANCE,  $
  OUTPUT_RASTER_URI=outputURI

  COMPILE_OPT IDL2, hidden
  e=ENVI(/current)

  ;��LC8 MTL.txt�ļ�
  Rasters = e.OpenRaster(inputURI)

  MulRaster = Rasters[0]
  TIRRaster = Rasters[3]

  K1_CONSTANT = (TIRRaster.METADATA['THERMAL K1'])[0]
  K2_CONSTANT = (TIRRaster.METADATA['THERMAL K2'])[0]

  PRINT, K1_CONSTANT, K2_CONSTANT

  ;��10���Σ��Ⱥ��⣩����Ϊ��������ֵ
  Task = ENVITASK('RadiometricCalibration')
  Task.INPUT_RASTER = ENVISUBSETRASTER(TIRRaster, Bands=[0])
  Task.OUTPUT_DATA_TYPE = 'Double'
  Task.Execute
  tirFile = Task.OUTPUT_RASTER_URI
  Task.OUTPUT_RASTER.Close
  ;���´��Ⱥ��ⶨ����
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

  ;ɾ��������
  ENVI_FILE_MNG, id=tirFid, /REMOVE, /DELETE

  OUTPUT_RASTER = ENVIFIDTORASTER(r_fid)
END


FUNCTION LST_Formula,red,nir,b10,t,up,down,k1,k2
  ;����NDVI
  ndvi=(FLOAT(nir)-red)/(FLOAT(nir)+red)
  ;����ֲ�����Ƕ�
  Pv = (ndvi GT 0.05 AND ndvi LT 0.7)*((ndvi-0.05)/(0.7-0.05))+$
    (ndvi LE 0.05)*0 + (ndvi GE 0.7)*1
  ;����ر�ȷ�����
  DBBFSL = 0.004*Pv+0.986
  ;����ͬ�¶��º����������
  BsT=(b10-up-t*(1-DBBFSL)*down)/(t*DBBFSL)
  ;����ر��¶�
  Temperature = (K2)/ALOG(K1/BsT+1)-273.15
  RETURN, Temperature
END