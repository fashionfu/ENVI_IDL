;+
;  ��IDL������ơ�
;   -���ݿ��ӻ���ENVI���ο���
;        
; ʾ������
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;-
  ;��ȡ����
 world = READ_PNG(FILEPATH('avhrr.png', $
  SUBDIRECTORY = ['examples', 'data']), R,G,B)
 ;������ʾģʽ
 DEVICE, DECOMPOSED = 0, RETAIN = 2
 ;Ĭ�ϵ���ɫ��
 TVLCT, R, G, B
 ;���ͼ��Ĵ�С
 worldSize = SIZE(world, /DIMENSIONS)
 ;����ͬ�ȴ�С�Ĵ���
 WINDOW, 0, XSIZE = worldSize[0], YSIZE = worldSize[1]
 ;��ʾͼ�񣬼�ͼ12.1.
 TV, world
 ;�ü���������
 africa = world [312:475, 103:264]
 ;�����ü�����ͬ��С�Ĵ���
 WINDOW, 2, XSIZE =(475-312 + 1), YSIZE =(264-103 + 1)
 ;��ʾ�ü���ͼ�񣬼�ͼ12.1��
 TV, africa
 
  ;������������.
 earth = READ_PNG (FILEPATH ('avhrr.png', $
  SUBDIRECTORY = ['examples', 'data']), R, G, B)
 ;����ͼ�����ɫ�����ð�ɫ�����ɫ�����һ����
 TVLCT, R, G, B
 maxColor = !D.TABLE_SIZE - 1
 TVLCT, 255, 255, 255, maxColor
 ;������ʾ�豸����
 DEVICE, DECOMPOSED = 0, RETAIN = 2
 ;��ȡͼ���ԭʼ��С
 earthSize = SIZE(earth, /DIMENSIONS)
 ;������ʾ����
 WINDOW, 0, XSIZE = earthSize[0] + 20, $
  YSIZE = earthSize[1] + 40
 ;��ʾͼ�񣬼�ͼ12.4��
 TV, earth
 ;����Ҫ�����С��������
 paddedEarth = REPLICATE(BYTE(maxColor), earthSize[0] + 20, $
  earthSize[1] + 40)
 ;��ԭͼ��copy����������.
 paddedEarth [10,10] = earth
 ;��ʾͼ��ͼ12.5��
 TV, paddedEarth
 ;��ʾ����.
 x = (earthSize[0]/2) + 10
 y = earthSize[1] + 15
 XYOUTS, x, y, 'World Map', ALIGNMENT = 0.5, COLOR = 0, $
  /DEVICE
 
  ;����ԭʼ����
 file = FILEPATH('shifted_endocell.png', $
  SUBDIRECTORY = ['examples','data'])
 image = READ_PNG(file, R, G, B)
 ;����ͼ����ɫ��
 DEVICE, DECOMPOSED = 0, RETAIN = 2
 TVLCT, R, G, B
 ;��ȡͼ��ߴ�
 imageSize = SIZE(image, /DIMENSIONS)
 ;������ʾ����
 WINDOW, 0, XSIZE = imageSize[0], YSIZE = imageSize[1], $
  TITLE = 'Original Image'  
 ;��ʾͼ��,��ͼ12.7-(a)
 TV, image
 ;ƽ��ͼ��.
 image = SHIFT(image, -imageSize[0]/4, -imageSize[1]/3)
 ;��ʾƽ�ƺ���.
 WINDOW, 1, XSIZE = imageSize[0], YSIZE = imageSize[1], $
  TITLE = 'Shifted Image'
 ;��ͼ12.7-(b)
 TV, image
 
 
  ; �������ݲ���ȡ���ݴ�С.
 image = READ_DICOM (FILEPATH('mr_knee.dcm', $
  SUBDIRECTORY = ['examples', 'data']))
 imgSize = SIZE (image, /DIMENSIONS)
 DEVICE, DECOMPOSED = 0, RETAIN = 2
 LOADCT, 0
 ;ˮƽ��תͼ��.
 flipHorzImg = REVERSE(image, 1)
 ;��ֱ��תͼ��.
 flipVertImg = REVERSE(image, 2)
 ;������ʾ����
 WINDOW, 0, XSIZE = 2*imgSize[0], YSIZE = 2*imgSize[1], $
  TITLE = 'Original (Top) & Flipped Images (Bottom)'
 erase,color = !p.color
 ;��ʾԭͼ��ͼ12.8��
 TV, image, 0
 ;��ʾ����ת��ͼ��ͼ12.8��
 TV, flipHorzImg, 2
 TV, flipVertImg, 3
 
  ;��ȡ�ļ�
 file = FILEPATH('galaxy.dat', SUBDIRECTORY = ['examples', 'data'])
 image = READ_BINARY(file, DATA_DIMS = [256, 256])
 ;������ʾ����.
 DEVICE, DECOMPOSED = 0, RETAIN = 2
 LOADCT, 4
 ;������ʾ���ڣ���ʾͼ�񣬼�ͼ12.9-(a)
 WINDOW, 0, XSIZE = 256, YSIZE = 256
 TVSCL, image
 ;��ͼ�����270����ʱ����ת.
 rotateImg = ROTATE(image, 3)
 ;��������ʾ���ڣ���ʾͼ�񣬼�ͼ12.9-(b)
 WINDOW, 1, XSIZE = 256, YSIZE = 256
 TVSCL, rotateImg
 
 
 ;��ȡ����
 file = FILEPATH('m51.dat', SUBDIRECTORY = ['examples', 'data'])
 image = READ_BINARY(file, DATA_DIMS = [340, 440])
 ;������ʾ����..
 DEVICE, DECOMPOSED = 0, RETAIN = 2
 LOADCT, 0
 ;������ʾ���ڣ���ʾͼ��ͼ12.10-1��
 WINDOW, 0, XSIZE = 340, YSIZE = 440
 TVSCL, image
 ; 33����תͼ����С����֮һ�ұ���ֵ����Ϊ127
 arbitraryImg = ROT(image, 33, .5, /INTERP, MISSING = 127)
 ;��������ʾ���ڣ���ʾͼ��ͼ12.10-2��
 WINDOW, 1, XSIZE = 340, YSIZE = 440
 TVSCL, arbitraryImg
 
 
  ;����ͼ���ļ�·��.
 imageFile = FILEPATH('elev_t.jpg', SUBDIRECTORY = ['examples', 'data'])
 ;��ȡͼ���ļ�.
 READ_JPEG, imageFile, image
 ;����DEM�ļ�·��.
 demFile = FILEPATH('elevbin.dat', SUBDIRECTORY = ['examples', 'data'])
 ;��ȡ����.
 dem = READ_BINARY(demFile, DATA_DIMS = [64, 64])
 dem = CONGRID(dem, 128, 128, /INTERP)
 ;��ʼ����ʾ.
 DEVICE, DECOMPOSED = 0, RETAIN = 2
 ;������ʾ���ڣ�ͼ12.11-(a)��
 WINDOW, 0, TITLE = 'Elevation Data',$
  XSIZE = 400, YSIZE =300
  erase,color = !p.color
 SHADE_SURF, dem
 ;��ʼ����ʾ������ϵ.
 oModel = OBJ_NEW('IDLgrModel')
 oView = OBJ_NEW('IDLgrView')
 oWindow = OBJ_NEW('IDLgrWindow', RETAIN = 2, $
  COLOR_MODEL = 0 , $
  DIMENSION =[400,300])
 oSurface = OBJ_NEW('IDLgrSurface', dem, STYLE = 2)
 oImage = OBJ_NEW('IDLgrImage', image, $
  INTERLEAVE = 0, /INTERPOLATE)
 ; �����һ����ʾ���������ڸ�������ƽ��-0.5���Ӷ�ʹͼ�����.
 ; ��ʾ����Ĭ������Ϊ[-1,-1], [1, 1].
 oSurface . GetProperty, XRANGE = xr, $
  YRANGE = yr, ZRANGE = zr
 xs = NORM_COORD(xr)
 xs[0] = xs[0] - 0.5
 ys = NORM_COORD(yr)
 ys[0] = ys[0] - 0.5
 zs = NORM_COORD(zr)
 zs[0] = zs[0] - 0.5
 oSurface . SetProperty, XCOORD_CONV = xs, $
  YCOORD_CONV = ys, ZCOORD = zs
 ; ����������������.
 oSurface . SetProperty, TEXTURE_MAP = oImage, $
  COLOR = [255, 255, 255]
 ; ����������ϵ����oModel��ӵ�oView.
 oModel.Add, oSurface
 oView.Add, oModel
 ; Ϊ�˵õ����õ���ʾЧ������ת��model.
 oModel.ROTATE, [1, 0, 0], -90
 oModel.ROTATE, [0, 1, 0], 30
 oModel.ROTATE, [1, 0, 0], 30
 ;����oView(ͼ12.11-(b))
 oWindow.Draw, oView
 ;����XOBJVIEW�鿴����ͼ12.11-(c)��
 XOBJVIEW, oModel, /BLOCK, SCALE = 1
 
  ; ���������ļ�·��.
 file = FILEPATH('worldelv.dat', $
  SUBDIRECTORY = ['examples', 'data'])
 ; ��ȡ����.
 image = READ_BINARY(file, DATA_DIMS = [360, 360])
 ; ��ʼ����ɫ��������������ɫΪ��ɫ.
 DEVICE, DECOMPOSED = 0
 LOADCT, 33
 TVLCT, 255, 255, 255, !D.TABLE_SIZE - 1
 ; ������ʾ������ʾԭͼ��ͼ12.12-(a)��
 WINDOW, 0, XSIZE = 360, YSIZE = 360
 TVSCL, image
 ; ����Mesh_obj��������һ���뾶Ϊ0.25������.
 MESH_OBJ, 4, vertices, polygons, REPLICATE(0.25, 360, 360), $
  /CLOSED
 ; ������ʾ���壬������ʾ��Χ�뷽ʽ��ͼ12.12-(b)��.
 WINDOW, 2, XSIZE = 512, YSIZE = 512
 ; ����3D��ʾ��ϵͳ����
 SCALE3, XRANGE = [-0.25,0.25], YRANGE = [-0.25,0.25], $
  ZRANGE = [-0.25,0.25], AX = 0, AZ = -90
 ; ���ó����ƹ���Ⱦλ��.
 SET_SHADING, LIGHT = [-0.5, 0.5, 2.0]
 !P.BACKGROUND = !P.COLOR
 ; ��ά��ʽ�����Ѿ�ӳ������ĵ���.
 TVSCL, POLYSHADE(vertices, polygons, SHADES = image, /T3D)
 ;�ָ�ϵͳ����ΪĬ��ֵ
 !P.BACKGROUND = 0
 
 
  ; ���������ļ�·��.
 file = FILEPATH('worldelv.dat', $
  SUBDIRECTORY = ['examples', 'data'])
 ; ��ȡ����.
 image = READ_BINARY(file, DATA_DIMS = [360, 360])
 ; ����Mesh_obj��������һ���뾶Ϊ0.25������.
 MESH_OBJ, 4, vertices, polygons, $
  REPLICATE(0.25, 101, 101)
 ; ����һ��model������������ʾ����.
 oModel = OBJ_NEW('IDLgrModel')
 ; ����image�������ɫ���������ʾͼ�����ɫ��.
 oPalette = OBJ_NEW('IDLgrPalette')
 oPalette.LOADCT, 33
 oPalette.SetRGB, 255,255,255,255
 oImage = OBJ_NEW('IDLgrImage', image, $
  PALETTE = oPalette)
 ; ��������ӳ������.
 vector = FINDGEN(101)/100.
 texure_coordinates = FLTARR(2, 101, 101)
 texure_coordinates[0, *, *] = vector # REPLICATE(1., 101)
 texure_coordinates[1, *, *] = REPLICATE(1., 101) # vector
 ; ����polygon����.
 oPolygons = OBJ_NEW('IDLgrPolygon', SHADING = 1, $
  DATA = vertices, POLYGONS = polygons, $
  COLOR = [255,255,255], $
  TEXTURE_COORD = texure_coordinates, $
  TEXTURE_MAP = oImage, /TEXTURE_INTERP)
 ; ���polygon����model��. ע�⣺
 ; object�Ѿ�����������ͼ����������ӳ���ϵ.
 oModel.ADD, oPolygons
 ; ��תoModel��һ�����ʵĽǶ�.
 oModel.ROTATE, [1, 0, 0], -90
 oModel.ROTATE, [0, 1, 0], -90
 ; ��ʾoModel��ͼ12.13��
 XOBJVIEW, oModel, /BLOCK
 
 
 
  ;���������ļ�·��.
 file = FILEPATH('worldelv.dat', $
  SUBDIRECTORY = ['examples', 'data'])
 ;��ʼ�������ļ���С.
 imageSize = [360, 360]
 ;�����Ʒ�ʽ��ȡ�ļ�
 image = READ_BINARY(file, DATA_DIMS = imageSize)
 ;��ʼ����ʾ.
 DEVICE, DECOMPOSED = 0
 LOADCT, 38
 ;������ʾ���ڲ�����Demͼ��ͼ12.14��
 WINDOW, 0, XSIZE = imageSize[0], YSIZE = imageSize[1], $
  TITLE = 'World Elevation'
 TV, image
 ;�������ɺ�����Ĥ����.
 oceanMask = image LT 125
 ;��Ĥ����Ӧ����Demͼ����.
 maskedImage = image*oceanMask
 ;������ʾ���ڲ���ʾ��Ĥ�ļ���Dem��Ĥ�����ͼ12.15��
 WINDOW, 1, XSIZE = 2*imageSize[0], YSIZE = imageSize[1], $
  TITLE = 'Oceans Mask (left) and Resulting Image (right)'
 TVSCL, oceanMask, 0
 TV, maskedImage, 1
 ;����½�ص���Ĥ����.
 landMask = image GE 125
 ;��Ĥ����Ӧ����Demͼ����.
 maskedImage = image*landMask
 ;������ʾ���ڲ���ʾ��Ĥ�ļ���Dem��Ĥ�����ͼ12.16��
 WINDOW, 2, XSIZE = 2*imageSize[0], YSIZE = imageSize[1], $
  TITLE = 'Land Mask (left) and Resulting Image (right)'
 TVSCL, landMask, 0
 TV, maskedImage, 1
 
 
  ;�򿪲���ȡ�ļ�.
 mapFile = FILEPATH('afrpolitsm.png', $
   SUBDIRECTORY = ['examples', 'data'])
 mapImg = READ_PNG(mapFile, mapR, mapG, mapB)
 ;������ɫ�����.
 mapPalette = OBJ_NEW('IDLgrPalette', mapR, mapG, mapB)
 ;��½�ط����ļ�����ȡ.
 landFile = FILEPATH('africavlc.png', $
   SUBDIRECTORY = ['examples', 'data'])
 landImg = READ_PNG (landFile, landR, landG, landB)
 landImgDims = SIZE(landImg, /Dimensions)
 ;����4ͨ���߱�͸���ȵ���ʾ����.
 alphaLand = BYTARR(4, landImgDims[0], landImgDims[1])
 ;��ǰ������ͨ���ֱ�Ϊԭ����RGB����
 alphaLand[0, *, *] = landR[landImg]
 alphaLand[1, *, *] = landG[landImg]
 alphaLand[2, *, *] = landB[landImg]
 ;����������Ĥ�ļ�����ֵ����ʾ����
 mask = (landImg GT 0)
 alphaLand [3, *, *] = mask*255B
 ;������ʾ���ݶ���.
 oAlphaLand = OBJ_NEW('IDLgrImage', alphaLand, $
   DIMENSIONS=[600, 600], BLEND_FUNCTION=[3,4], $
   ALPHA_CHANNEL=0.35)
 ;������ͼ����.
 oMapImg = OBJ_NEW('IDLgrImage', mapImg, $
   DIMENSIONS=[600, 600], PALETTE=mapPalette)
 ;������ʾ������ϵ�ṹ.
 oWindow = OBJ_NEW('IDLgrWindow', $
   DIMENSIONS=[600, 600], RETAIN=2, $
   TITLE='Overlay of Land Cover Transparency')
 viewRect = [0, 0, 600, 600]
 oView = OBJ_NEW('IDLgrView', VIEWPLANE_RECT=viewRect)
 oModel = OBJ_NEW('IDLgrModel')
 oModel.Add, oMapImg
 oView.Add, oModel
 ;������ʾ��ͼ12.17-(a)��
 oWindow.Draw, oView
 ;�����ʾ����
 oModel.Add, oAlphaLand
 ;������ʾ��ͼ12.17-(b)��
 oWindow.Draw, oView
 ;���ٶ���.
 OBJ_DESTROY, [oView, oMapImg, oAlphaLand, mapPalette]
 
 
 
  ;�򿪲���ȡ�����ļ�.
 roseFile = FILEPATH('rose.jpg', $
   SUBDIRECTORY = ['examples', 'data'])
 READ_JPEG,roseFile,roseImg
 ;��ȡ�ļ���Ϣ
 dims = size(roseImg,/Dimension)
 ;������ʾ���ڲ���ʾԭʼͼ�񣬼�ͼ12.18-(a)
 Window,0,xsize = dims[1],ysize = dims[2],title='ԭʼͼ��'
 tv,roseImg,/true
 ;���ÿ��Ƶ��
 Xo = [0.25,0.75,0.75,0.25]
 Yo = [0.75,0.75,0.25,0.25]
 Xi = Xo+[1,-1,-1,1]*1.0/8
 Yi = Yo+[-1,-1,1,1]*1.0/8
 ;ͨ�����Ƶ�������ʽУ��ת������
 POLYWARP, Xo*dims[1], Yo*dims[2], Xi*dims[1], Yi*dims[2], 1, KX, KY 
 ;У����һ���������� 
 tempImg = POLY_2D(Reform(roseImg[0,*,*]), KX, KY)
 ;����У�������ļ���Ϣ����������У������ļ�
 warpDims = Size(tempImg,/Dimension)
 warpType = Size(tempImg,/Type)
 WarpImg = Make_Array(3,warpDims[0],warpDims[1],type = warpType)
 ;����������У��
 warpImg[0,*,*] = tempImg
 warpImg[1,*,*] = POLY_2D(Reform(roseImg[1,*,*]), KX, KY)
 warpImg[2,*,*] = POLY_2D(Reform(roseImg[2,*,*]), KX, KY)
 ;������ʾ���ڲ���ʾУ����ͼ�񣬼�ͼ12.18-(b)
 Window,1,xsize =warpDims[0],ysize = warpDims[1],title='У����ͼ��'
 tv,warpImg,/True
 
 
  ;��ʾ��ϵ.
 DEVICE, DECOMPOSED = 0, RETAIN = 2
 LOADCT, 0
 ;��ȡ�����ļ�.
 kneeImg = READ_DICOM(FILEPATH('mr_knee.dcm',$
  SUBDIRECTORY = ['examples','data']))
 ;��ȡ�ļ��Ĵ�С��Ϣ
 dims = SIZE(kneeImg, /DIMENSIONS)
 ;��ת�������ļ�
 kneeImg = ROTATE(BYTSCL(kneeImg), 2)
 ;����XROI���ܣ����ѡ�����ιɹ�Ϊ����Ȥ�������ڱ���femurROIout��.
 ;����Ȥ�Ĵ�С��ͳ����Ϣ�ֱ���ڱ���femurGeom��femurStats�С�
 ;��ͼ12.19-(a)
 XROI, kneeImg, REGIONS_OUT = femurROIout, $
  ROI_GEOMETRY = femurGeom, STATISTICS = femurStats, /BLOCK
 ;����XROI���ܣ����ѡ�������ֹ�Ϊ����Ȥ�������ڱ���tibiaROIout��.
 ;��ͼ12.19-(b)
 XROI, kneeImg, REGIONS_OUT = tibiaROIout, $
  ROI_GEOMETRY = tibiaGeom, STATISTICS = tibiaStats, /BLOCK
 ;����������ʾԭͼ����ͼ12.19-(c)
 WINDOW, 0, XSIZE = dims[0], YSIZE = dims[1]
 TVSCL, kneeImg
 ;������ɫ������ѡ���ROI����.
 LOADCT, 12
 DRAW_ROI, femurROIout, /LINE_FILL, COLOR = 80, SPACING = 0.1, $
  ORIENTATION = 315, /DEVICE
 DRAW_ROI, tibiaROIout, /LINE_FILL, COLOR = 42, SPACING = 0.1, $
  ORIENTATION = 30, /DEVICE
 ;����鿴����Ȥ������Ϣ.
 PRINT, '�ɹ����򼸺κ�ͳ����Ϣ'
 PRINT, '    ��� =', femurGeom.area, $
  '    �ܳ� = ', femurGeom.perimeter, $
  '    ������ =',  femurStats.count
 PRINT, ' '
 PRINT, '�ֹ����򼸺κ�ͳ����Ϣ'
 PRINT, '    ��� =', tibiaGeom.area, $
  '    �ܳ� = ', tibiaGeom.perimeter, $
  '    ������ =', tibiaStats.count
 ;���ٶ���.
 OBJ_DESTROY, [femurROIout, tibiaROIout]
 
 
 
 end