;Band average atmospheric TRANSMISSION:  0.90
;Effective bandpass upwelling RADIANCE:  0.75 W/m^2/sr/um
;Effective bandpass downwelling RADIANCE:  1.28 W/m^2/sr/um
;
; Add the extension to the toolbox. Called automatically on ENVI startup.
PRO ENVI_Landsat8_LST_extensions_init

  ; Set compile options
  COMPILE_OPT IDL2

  ; Get ENVI session
  e = ENVI(/CURRENT)

  ; Add the extension to a subfolder
  e.AddExtension, 'Landsat 8 LST', 'ENVI_Landsat8_LST', PATH=''
END

; ENVI Extension code. Called when the toolbox item is chosen.
PRO ENVI_Landsat8_LST

  ; Set compile options
  COMPILE_OPT IDL2

  ; General error handler
  CATCH, err
  IF (err NE 0) THEN BEGIN
    CATCH, /CANCEL
    IF OBJ_VALID(e) THEN $
      e.ReportError, 'ERROR: ' + !ERROR_STATE.MSG
    MESSAGE, /RESET
    RETURN
  ENDIF

  ;Get ENVI session
  e = ENVI(/CURRENT)

  ;******************************************
  ; Insert your ENVI Extension code here...
  ;******************************************
  ;
  mtlFile = ENVI_PICKFILE(TITLE='Please select the Landsat 8 MTL file', FILTER='*_MTL.txt')
  IF ~FILE_TEST(mtlFile) THEN RETURN
  SPAWN, 'start iexplore "http://atmcorr.gsfc.nasa.gov/"', /HIDE
  ;
  Rasters = e.OpenRaster(mtlFile)
  MulRaster = Rasters[0]

  ;获取元数据信息
  time = MulRaster.TIME
  time = time.ACQUISITION
  time = StrSplit(time, '-T:',/extract)
  Year = time[0]
  Month = time[1]
  Day = time[2]
  GMThour = time[3]
  Minute = time[4]

  ;中心点经纬度信息
  spatialRef1 = MulRaster.SPATIALREF
  File1X = MulRaster.NCOLUMNS/2
  File1Y = MulRaster.NROWS/2
  spatialRef1.ConvertFileToMap, File1X, File1Y, MapX, MapY
  spatialRef1.ConvertMapToLonLat, MapX, MapY, LonD, LatD
  Lon = STRING(LonD, FORMAT='(F7.3)')
  Lat = STRING(LatD, FORMAT='(F6.3)')

  lonLat = ' Use interpolated atmospheric profile for given lat/long'

  ;模型
  monthD = FIX(Month)
  latD = ABS(latD)
  IF (latD GE 70) OR $
    (latD GE 60 AND latD LT 70 AND monthD GE 1 AND monthD LE 6) OR $
    (latD GE 60 AND latD LT 70 AND monthD GE 11) OR $
    (latD GE 50 AND latD LT 60 AND monthD GE 1 AND monthD LE 4) THEN $
    model = ' Use mid-latitude winter standard atmosphere for upper atmospheric profile' $
  ELSE $
    model = ' Use mid-latitude summer standard atmosphere for upper atmospheric profile'

  curve = ' Use Landsat-8 TIRS Band 10 spectral response curve'


  InfoStr = ["Don't Close this Dialog!", $
    ' ', $
    "Please enter the following parameters into 'Atmospheric Correction Parameter Calculator'.", $
    '------------------------------------------------------------------------', $
    'Year : ' + Year + '             Month : '+ Month + '        Day : '      + Day,     $
    'GMT Hour : ' + GMThour + '        Minute : '   + Minute, $
    '------------------------------------------------------------------------', $
    'Latitude : ' + Lat + '      Longitude : ' + Lon,   $
    STRING(BYTE([161,241])) + lonLat, $
    '------------------------------------------------------------------------', $
    STRING(BYTE([161,241])) + model, $
    '------------------------------------------------------------------------', $
    STRING(BYTE([161,241])) + curve, $
    '------------------------------------------------------------------------',  $
    'Email: fill in your email address.', $
    '------------------------------------------------------------------------',  $
    "Press the 'Calculate' button.", $
    'Then you will get the output summary.             o(∩_∩)o~']

  !NULL = DIALOG_MESSAGE(InfoStr, /INFORMATION, $
    TITLE='Atmospheric Correction Parameter Calculator')

  ;
  Task = ENVITASK('landsat8lst')
  Task.INPUTURI = mtlFile
  ok = e.UI.SelectTaskParameters(Task)

  IF ok NE 'OK' THEN RETURN
  ;
  Task.Execute
  
  ;密度分割
  
END
