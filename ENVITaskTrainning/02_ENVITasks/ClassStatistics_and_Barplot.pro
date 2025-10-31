PRO ClassStatistics_and_Barplot, Raster, inClass
  COMPILE_OPT idl2
  e=envi()

  ;  inClass = [3,2,1,5,4]
  ;  ;
  ;  file='D:\2016ENVI��ѵ���زİ�\ENVI��ϰ����\203-Ӧ��ר�⣺������Ԫ����ģ�͵�ֲ�����Ƕȷ���\5-��Ĥ�ļ�\���ظ��Ƿ���ͼ\classimage.dat'
  ;  Raster = e.OpenRaster(file)

  ;���Ϊ��������ϵ����ת��ΪAlbers�����ͶӰ
  IF STRMID(Raster.SPATIALREF.COORD_SYS_STR, 0, 6) EQ 'PROJCS' THEN BEGIN
    coord_sys_str = 'PROJCS["WGS_1984_Albers",GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Albers"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",110.0],PARAMETER["Standard_Parallel_1",25.0],PARAMETER["Standard_Parallel_2",47.0],PARAMETER["Latitude_Of_Origin",12.0],UNIT["Meter",1.0]]'
    coordSys = ENVICoordSys(COORD_SYS_STR=coord_sys_str)
    tmpRaster = ENVIReprojectRaster(Raster,COORD_SYS=CoordSys)
  ENDIF ELSE BEGIN
    tmpRaster = Raster
  ENDELSE


  md = Raster.METADATA

  IF md.HasTag('CLASS NAMES') EQ 0 THEN RETURN

  IF N_ELEMENTS(inClass) EQ 0 THEN inClass = LINDGEN(md['CLASSES'])

  class_names = (md['CLASS NAMES'])[inclass]
  class_lookup = (md['CLASS LOOKUP'])[*,inclass]
  n_classes = N_ELEMENTS(inClass)

  ;ͳ�Ʊ仯���
  HistogramTask = ENVITask('RasterHistogram')
  HistogramTask.INPUT_RASTER = Raster
  HistogramTask.INPUT_MIN = [MIN(inclass)]
  HistogramTask.INPUT_MAX = [MAX(inclass)]
  HistogramTask.INPUT_NBINS = [n_classes]
  HistogramTask.Execute
  counts = (HistogramTask.OUTPUT_COUNTS).ToArray()
  counts = counts[SORT(inClass)]
  pixelArea = PRODUCT(tmpRaster.SPATIALREF.PIXEL_SIZE)/1E6
  areas = counts*pixelArea

  ;�����+���+km^2
  names_areas = class_names + ' (' + $
    STRTRIM(STRING(areas, FORMAT='(D20.2)'),2) + '$km^2$)'

  w = WINDOW(DIMENSIONS = [800,500])
  bs=!NULL
  FOR i=0, n_classes-1 DO BEGIN
    b=barplot([i+1,i+2], [counts[i],0], xrange=[0,n_classes+1], $
      FILL_COLOR=class_lookup[*,i], overplot=(i EQ 0?0:1), $
      NAME=names_areas[i], THICK=3, OUTLINE=0, width=0.5, $
      ytitle = 'Number of Pixels', POSITION=[0.16,0.12,0.86,0.88], $
      FONT_NAME='Microsoft Yahei',/current, MARGIN=[0,0,0,0])
    bs=[bs, b]
  ENDFOR

  ax = b.AXES
  ax[0].TICKNAME = [' ',class_names,' ']
  ax[0].TICKLEN = 0
  ax[2].TICKLEN = 0
  ax[3].HIDE = 1

  b.TITLE = 'Class Statistics'
  b.FONT_SIZE = 14

  l=legend(target=bs, POSITION=[0.95*b.XRANGE[1], 0.95*b.YRANGE[1]], /data, $
    FONT_NAME='Microsoft Yahei', FONT_SIZE=12)



  ;�����ͶӰ����ϵ���ֱ��ʵ�λΪ�ף������ƽ�������Y��
  areaYRange = (b.YRANGE)*areas
  axesY = AXIS('y', target=b, textpos = 1, TITLE='Area ($km^2$)', $
    LOCATION='right', COORD_TRANSFORM = [0,pixelArea], TICKFONT_NAME='Microsoft Yahei')
END