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

;����������ʾ������
;-
;
 ;������ɫģʽ
 DEVICE, decomposed =0
 ;����IDLĿ¼�µ�jpg�ļ�·��
 file = FILEPATH('r_seeberi.jpg', $
   SUBDIRECTORY = ['examples', 'data'])
 ;����Grayscale�ؼ��ֶ�ȡ�Ҷ�ͼ��
 READ_JPEG, file, image, /GRAYSCALE
 ;�鿴ͼ����Ϣ
 HELP,image
 ;������ͼ���Сһ�µ���ʾ���ڣ�IDΪ1
 WINDOW,1,xsize = 280,ysize =195
 ;��ʾͼ��ͼ7.1��
 TV,image
 ;������ɫ��13��IDLϵͳ�Դ���
 LOADCT,13
 ;��ʾͼ��ͼ7.2��.
 TV,image
 ;����loadct
 LOADCT
 ;����ʾͼ��ͼ7.4��
 tv,image
 
 ;����XLoadCT���棨ͼ7.5��
 XLOADCT
 ;��ʾͼ��ͼ7.6��
 tv,image
 
 ;��������13����ɫ��RGB���ձ�������rgb
 LOADCT,13,rgb_table = rgb
 ;�鿴����rgb����Ϣ
 help,rgb
 
 ;������ɫ���R��G��B����
 R = BYTSCL(SIN(FINDGEN(256)))
 G = BYTSCL(COS(FINDGEN(256)))
 B = BINDGEN(256)
 ;�����Զ����RGB����
 TVLCT, R, G, B
 ;��ʾͼ��ͼ7.7��
 tv,image
 
 
 ;����Ϊ41����ɫ�����������޸ģ����������Զ�����
 MODIFYCT, 41, 'Sin And Cos', r,g,b
 ;����XLoadCT���鿴�޸ĵ���ɫ��ͼ7.8��
 XLOADCT
 
 
 ;����ϵͳ����ֵ
 oriBkcolor = !p.BACKGROUND
 !p.BACKGROUND = !p.COLOR
 !p.COLOR = oriBKcolor
 ;����һ��������������
 xdata = findgen(200)/10
 ;����600*200�Ĵ���
 WINDOW,xsize = 600,ysize = 200
 ;���ߺ�ɫ��ʾ����ɫ������ͼ7.9��
 PLOT,xData,sin(xData)
 ;�ָ�ϵͳ������ֵ
 !p.COLOR = !p.BACKGROUND
 !p.BACKGROUND = oriBkcolor
 
 
 
 ;������ɫת��ģʽ
 Device,decomposed = 1
 ;����һ��������������
 xdata = findgen(200)/10
 ;����600*200�Ĵ���
 WINDOW,xsize = 600,ysize = 200
 ;������ɫ��ʾ����ɫ������ͼ7.10��
 PLOT,xData,sin(xData),color=16711680L,background = 16777215L
 
 
 ;����600*200�Ĵ���
 WINDOW,xsize = 600,ysize = 200
 ; ����һ��������������
 xdata = findgen(200)/10
 ;Ĭ�ϲ����������ߣ�ͼ7.11��
 PLOT,xData,sin(xData)
 ;�ڴ����ķ�֮һ�����½ǲ��ֻ�ͼ��ͼ7.12��
 PLOT,xData,sin(xData),position = [0,0,0.5,0.5]
 ;��ʾ����Ϊ�����ķ�֮һ�����½ǲ���
 !p.REGION = [0,0,0.5,0.5]
 ;��ͼ��ͼ7.13��
 PLOT,xData,sin(xData)
 
 ;����ǰϵͳ����ֵ��ֵ������sysFont
 sysFont = !p.FONT
 ;��������ģʽΪʸ������
 !p.FONT =-1
 ;������С600*200���صĴ���
 WINDOW,1,xsize =600,ysize =200
 ;����һ��������������
 xdata = findgen(200)/10
 ;Ĭ�ϲ�����������
 PLOT,xData,sin(xData),title = '!12sin plot',xtitle ='!3x axis'
 ;���ĵ�����ַ�����Center Point����ͼ7.14��
 xyouts,0.5,0.5,'!13Center Point',/normal,charsize =2
 ;�ָ�ϵͳ���������ֵ
 !p.FONT = sysFont
 
 
 
 ;����һ��������������
 xdata = findgen(200)/10
 ;������С400*150���صĴ���
 WINDOW,1,xsize =400,ysize =150
 ;�������ߣ���������Ϊ���ֻ���ʾ���루ͼ7.15-(1)��
 PLOT,xData,sin(xData),title = '��������'
 ;����ǰϵͳ����ֵ��ֵ������sysFont
 sysFont = !p.FONT
 ;ʹ��ϵͳ����
 !p.FONT = 0
 ;��������Ϊ�����塱��ȷ�����õ�����ϵͳ�д��ڡ�
 Device, Set_Font='����'
 ;�������ߣ�ͼ7.15-(2)��
 PLOT,xData,sin(xData),title = '��������'
 ;��������Ϊ�����塱����СΪ12���ء�
 Device, Set_Font='����*12'
 ;�������ߣ�ͼ7.15-(3)��
 PLOT,xData,sin(xData),title = '��������'
 ;��������Ϊ���壬��СΪ16���أ�����б��(ITALTC)����ʾ�»���(UNDERLINE)��
 Device, Set_Font='����*ITALIC*UNDERLINE*16'
 ;�������ߣ�ͼ7.15-(4)��
 PLOT,xData,sin(xData),title = '��������'
 ;�ָ�ϵͳ���������ֵ
 !p.FONT = sysFont
 
 
 ;������С400*150���صĴ���
 WINDOW,1,xsize =400,ysize =150
 ;����һ��������������
 xdata = findgen(200)/10
 ;����ǰϵͳ����ֵ��ֵ������sysFont
 sysFont = !p.FONT
 ;ʹ��TrueType����
 !p.FONT =1
 ;����Helvetica���岢�Ӵ֡���б
 DEVICE, SET_FONT='Helvetica Bold Italic', /TT_FONT
 ;�������ߣ�ͼ7.16-(1)��
 PLOT,xData,sin(xData),title = 'sin Plot'
 ;����Courier������б������Ϊ[10,12]���ش�С
 DEVICE, SET_FONT='Courier Italic', /TT_FONT, $
   SET_CHARACTER_SIZE=[10,12]
 ;�������ߣ�ͼ7.16-(2)��
 PLOT,xData,sin(xData),title = 'sin Plot'
 ;�ָ�ϵͳ���������ֵ
 !p.FONT = sysFont
 
 
 ;���õ���TrueType���塰beijing2008��
 device, set_font ='beijing2008',/tt_font
 ;������СΪ900*200����ʾ����
 WINDOW,1,xsize = 900,ysize =200
 ;�����豸��������½�[0,0]����ʾ��ǰTrueType����(font=1)
 ;��ʾ����Ϊ��012abc����ͼ7.17��
 xyouts,0,0,'012abc',charsize=20,/device,font=1
 
 
 
 ;�鿴ϵͳ��ǰ��ʾ���ڡ�
 print,!d.WINDOW
 ;����IDΪ8����СΪ400*300�Ĵ��ڣ�ͼ7.18��
 WINDOW,8,xsize = 400,ysize =300
 ;���ϵͳ������8���´����Ĵ��ڡ�
 
 
 ;���δ���������ʾ���ڣ�ͼ7.19��
 WINDOW,1,xsize = 300,ysize =200
 WINDOW,2,xsize = 300,ysize =200
 ;������ɫת��ģʽ
 Device,decomposed = 1
 ;���ƺ�ɫ���ߣ���ʾ����󴴽��ġ�2�������С�
 PLOT,(findgen(20)/10)^3,color = 255L
 ;��¶��1������
 wset,1
 ;������ɫ���ߣ�ͼ7.20��
 PLOT,(findgen(20)/10)^3,color = 16711680L
 ;ɾ��������ʾ����
 wdelete,1,2
 
 
 ;������СΪ800*600�Ĵ���
 WINDOW,0,xsize =800,ysize=600
 ;���ö�ͼ��ʾ��2��2��
 !p.MULTI = [4,2,2,0,0]
 ;����0-19��������������
 data = FINDGEN(20)
 ;�������ݻ�ͼ����ͼ7.21��һ��ͼ��
 PLOT,data
 ;�������Һ�����ͼ����ͼ7.21�ڶ���ͼ��
 PLOT, SIN(data/3), COS(data/6)
 ;ʹ��polar�ؼ��ֻ��Ƽ���ͼ����ͼ7.21������ͼ��
 PLOT, data, data, /POLAR, TITLE = 'Polar'
 ;�������ߣ�������ʾ������x��y����⣬��ͼ7.21�е��ĸ�ͼ��
 PLOT, SIN(data/10), PSYM=4, XTITLE='X ', YTITLE='Y
 ;�ָ���ͼ���Ʋ���
 !p.MULTI = 0
 
 ;������������
 SOCKEYE=[463, 459, 437, 433, 431, 433, 431, 428, 430, 431, 430]
 YEAR = [1967, 1970, INDGEN(9) + 1975]
 ;����������˿������ߣ�ͼ7.28����ע��Title��xTitle��yTitle��ʹ�á�
 PLOT, YEAR, SOCKEYE, TITLE='Sockeye Population', XTITLE='Year', YTITLE='Fish (thousands)'
 
 
 ;������СΪ800*600�Ĵ���
 WINDOW,0,xsize =800,ysize=600
 ;���ö�ͼ��ʾ��2��2��
 !p.MULTI = [4,2,2,0,0]
 ;�������ݣ�ydataΪxdata������ֵ
 xdata = findgen(200)/10+3
 ydata = sin(xdata)
 ;ֱ�ӻ������ߣ���ͼ7.23�ĵ�һ��ͼ��
 PLOT,xdata,ydata
 ; ����x����ʾ���Ϊ1����ͼ7.23�ĵڶ���ͼ��
 PLOT,xdata,ydata,/xstyle
 ;����y����ʾ���Ϊ4����ͼ7.23�ĵ�����ͼ��
 PLOT,xdata,ydata,/xstyle,ystyle=4
 ;����y����ʾ���Ϊ8����ͼ7.23�ĵ��ĸ�ͼ��
 PLOT,xdata,ydata,/xstyle,ystyle=8
 ;�ָ���ͼ���Ʋ���
 !p.MULTI = 0
 
 
 ;������СΪ800*600�Ĵ���
 WINDOW,0,xsize =800,ysize=600
 ;���ö�ͼ��ʾ��2��2��
 !p.MULTI = [4,2,2,0,0]
 ;�������ݣ�ydataΪxdata������ֵ
 xdata = findgen(20)/4
 ydata = sin(xdata)
 ;ֱ�ӻ����������ߣ���ͼ7.24�ĵ�һ��ͼ��
 PLOT,xdata,ydata
 ;�������ߵ㷽ʽ��ʾ����ͼ7.24�ĵڶ���ͼ��
 PLOT,xdata,ydata,psym = 3
 ;�������ߵ㷽ʽ��ʾ����ͼ7.24�ĵ�����ͼ��
 PLOT,xdata,ydata,psym = 4
 ;�������ߵ㷽ʽ��ʾ����ͼ7.24�ĵ��ĸ�ͼ��
 PLOT,xdata,ydata,psym = 10
 ;�ָ���ͼ���Ʋ���
 !p.MULTI = 0
 
 
 ;������СΪ800*600�Ĵ���
 WINDOW,0,xsize =800,ysize=600
 ;���ö�ͼ��ʾ��2��2��
 !p.MULTI = [4,2,2,0,0]
 ;����200*200�����飬��tv,data�鿴���ݷֲ�
 data = DIST(200)
 ;ֱ�ӻ������ݵ�ֵ�ߣ���ͼ7.26�ĵ�һ��ͼ��
 CONTOUR,data
 ;���õ�ֵ��Ϊ10������䣬��ʾע�ǣ���ͼ7.26�ĵڶ���ͼ��
 CONTOUR,data,NLEVELS =10, /FOLLOW
 ;����һ�������������
 A = RANDOMU(seed, 5, 6)
 ;��ֵ��ǰ����ƽ������
 B = MIN_CURVE_SURF(A)
 ;����5����ֵ�߼�ɽ�ų����ߣ���ͼ7.26�ĵ�����ͼ��
 CONTOUR, B, NLEVELS=5, /DOWNHILL
 ;����IDL����Ķ�����ɫ���ձ�
 TEK_COLOR
 ;5�������ʾ�����ò�ͬ��ɫ����ͼ7.26�ĵ��ĸ�ͼ��
 CONTOUR, B, /FILL, NLEVELS=5, C_COLOR=INDGEN(5)*180
 ;�ָ���ͼ���Ʋ���
 !p.MULTI = 0
 
 
 
 ;����50�������
 x = RANDOMN(seed, 50)
 y = RANDOMN(seed, 50)
 ;����XY���ʽֵZ
 Z = EXP(-(x^2 + y^2))
 ;������ɢ������Delaunay������
 TRIANGULATE, X, Y, tri
 ;������СΪ400*300�Ĵ���
 WINDOW,0,xsize =400,ysize =300
 ; ���Ƶ�ֵ�ߣ�ͼ7.33��
 CONTOUR, Z, X, Y, TRIANGULATION = tri
 
 ;�����������
 SEED = 20 & DATA = RANDOMU(SEED, 6, 8)
 ;���ö�ͼ��ʾģʽ
 !P.MULTI=[0,2,1]
 ;������СΪ800*400�Ĵ���
 WINDOW,0,xsize =800,ysize =400
 ;���Ƶ�ֵ�ߣ����õ�ֵ����ֵ����ͼ7.28.
 CONTOUR, LEVEL=[0.2, 0.5, 0.8], C_LABELS=[1, 1, 1], $
   C_CHARSIZE = 1.25, DATA
 ;���Ƶ�ֵ�ߣ�������ʾ��ע���ݣ�ͼ7.28��
 CONTOUR, LEVEL=[0.2, 0.5, 0.8], C_LABELS=[1, 1, 1], $
   C_ANNOTATION = ["Low", "Medium", "High"], $
   C_CHARSIZE = 1.25, DATA
 ;�ָ���ͼ��ʾ���Ʋ���
 !P.MULTI=0
 
 
 ;������ɫ��14
 DEVICE, DECOMPOSED=0
 LOADCT,14
 ;���ݳ����������켰�ز���
 RESTORE, FILEPATH('marbells.dat', SUBDIR=['examples','data'])
 X = 326.850 + .030 * FINDGEN(72)
 Y = 4318.500 + .030 * FINDGEN(92)
 image = BYTSCL(elev, MIN=2658, MAX=4241)
 new = REBIN(elev, 350/5, 450/5)
 ;����ͼ�����λ�ã�!X.window-��ͼ����һ�����꣬!D.x_Vsize��ͼ��С
 PX = !X.WINDOW * !D.X_VSIZE
 PY = !Y.WINDOW * !D.Y_VSIZE
 ;������ʾ����ͼ�����سߴ�.
 SX = PX[1] - PX[0] + 1
 SY = PY[1] - PY[0] + 1
 ;������СΪ800*400�Ĵ���
 WINDOW,0,xsize =800,ysize =400
 ;�����½�����ݼ����ͼ�����λ����ʾͼ��.
 TVSCL, CONGRID(image, SX, SY), PX[0], PY[0]
 ;���Ƶ�ֵ�ߣ�NoErase�ؼ��ֿ��Ʋ�����ԭդ��ͼ��ͼ7.29��
 ;Ҳ�ɲο�image_cont�����������Դ�룬��ֱ�ӵ��ã�
 CONTOUR, new, X, Y, LEVELS = 2750 + FINDGEN(6) * 250., $
   XSTYLE = 1, YSTYLE = 1, YMARGIN = 5, MAX_VALUE = 5000, $
   C_LINESTYLE = [1, 0], $
   C_THICK = [1, 1, 1, 1, 1, 3], $
   TITLE = 'Maroon Bells Region', $
   SUBTITLE = '250 meter contours', $
   XTITLE = 'UTM Coordinates (KM)', $
   /NoErase
 ;�ָ���ɫ��ʾ����
 DEVICE, DECOMPOSED=1
 
 
 ;��ʾ����37
 number_samples = 37
 ;��TimeGen���������������У���ʼ����ΪJulday��ʽ
 date_time = TIMEGEN(number_samples, UNITS = 'Seconds', $
   START = JULDAY(3, 30, 2000, 14, 59, 30))
 ;�Ƕ���������
 angle = 10.*FINDGEN(number_samples)
 ;�����¶�����
 temperature = BYTSCL(SIN(10.*!DTOR* $
   FINDGEN(number_samples)) # COS(!DTOR*angle))
 ;������ɫ��5
 DEVICE, DECOMPOSED = 0
 LOADCT, 5
 ;����LABEL_DATE�����������ڱ�עֵ
 date_label = LABEL_DATE(DATE_FORMAT = $
   ['%I:%S', '%H', '%D %M, %Y'])
 ;������СΪ800*400�Ĵ���
 WINDOW,0,xsize =800,ysize =400
 ;�������ݻ��Ƶ�ֵ�ߡ���ʾ��ע
 CONTOUR, temperature, angle, date_time, $
   LEVELS = BYTSCL(INDGEN(8)), /XSTYLE, /YSTYLE, $
   C_COLORS = BYTSCL(INDGEN(8)), /FILL, $
   ;ע�������⣬�ַ����м��!C�ỻ����ʾ.
   TITLE = 'Measured Temperature!C(degrees Celsius)', $
   XTITLE = 'Angle (degrees)', $
   YTITLE = 'Time (seconds)', $
   POSITION = [0.25, 0.2, 0.9, 0.85], $
   YTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE', 'LABEL_DATE'], $
   YTICKUNITS = ['Time', 'Hour', 'Day'], $
   YTICKINTERVAL = 5, $
   YTICKLAYOUT = 2
 ;�ڸղ���ʾ���������ӻ��Ƶ�ֵ�ߣ�ͼ7.30��
 CONTOUR, temperature, angle, date_time, /OVERPLOT, $
   LEVELS = BYTSCL(INDGEN(8))
 ;�ָ���ɫ��ʾ����
 DEVICE, DECOMPOSED=1
 
 
 
 ;����512*256��С����ʾ����
 WINDOW,0,xsize = 512,ysize = 256
 ;����256*256������
 D = DIST(256)
 ;ԭ���ݻ��ƣ�ͼ������ڴ��ڵ����½ǡ�
 TV, D
 ;������ʾ��0��ʾͼ����ʾ�ڵ�һ������λ�á�
 TVSCL, D,1
 
 ;����512*256��С����ʾ����
 WINDOW,0,xsize = 512,ysize = 300
 ;��[128,22]��λ�û��ƣ���������ʾͼ��ͼ7.31��
 tv,DIST(256),128,22
 
 
 
 
 ;����IDL��װĿ¼example\dataĿ¼�µ�rose.jpg�ļ�ȫ·��
 file = FILEPATH('rose.jpg', $
   SUBDIRECTORY = ['examples', 'data'])
 ;����READ_IMAGE������ȡ�ļ�
 image = READ_IMAGE(file)
 ;�鿴ͼƬ��Ϣ
 HELP,image
 ;����400*300��С����ʾ����
 WINDOW,0,xsize=400,ysize =300
 ;��ͼ���ʽ����[3,m,n],��trueȡ1����дΪ/true��ʽ��ͼ7.33��
 TV,image,81,75,/true
 ;QUERY_IMAGE������ѯ�ļ���Ϣ
 queryStatus = QUERY_IMAGE(file, imageInfo)
 ;��ȡ���ݵ�ά����С
 imageDims = SIZE(image, /DIMENSIONS)
 ;��ѯ�����Ľ��
 imagesize = imageinfo.DIMENSIONS
 ;�����ж��㷨������true��ֵ
 trueValue= WHERE((imageDims NE imageSize[0]) AND (imageDims NE imageSize[1])) + 1
 ;�鿴������.
 print,trueValue
 1
 
 ;������СΪ800*600�Ĵ���
 WINDOW,0,xsize =800,ysize=600
 ;���ö�ͼ��ʾ��2��2��
 !p.MULTI = [4,2,2,0,0]
 D = DIST(30)
 ;ֱ�ӻ����������棬��ͼ7.34�ĵ�һ��ͼ��
 SURFACE, D
 ;������zת60������x��ת35�㣬��ͼ7.34�ĵڶ���ͼ��
 SURFACE, d,   Az=60,  Ax=35
 ;��ӡ�ȹ�ߡ������棬��ͼ7.34�ĵ�����ͼ��
 SURFACE, D, SKIRT=0.0, TITLE = 'Surface Plot'
 ;��Ӱ������ƣ���ͼ7.34�ĵ��ĸ�ͼ��
 SHADE_SURF, D, TITLE = 'Shaded Surface'
 
 
 
 DEVICE, DECOMPOSED=1
 ;�����������ļ�·��.
 file = Filepath('head.dat', SUBDIRECTORY = ['examples', 'data'])
 ;��ȡ�����ݵ�volume����
 volume = READ_BINARY(file, DATA_DIMS = [80, 100, 57])
 ;�ز���ΪС����
 smallVol = CONGRID(volume, 40, 50, 27)
 ;XVOLUME����ʽ��ʾ���ݣ�ͼ7.35��
 XVOLUME, smallVol, /INTERPOLATE
 ;����200*100����ʾ���ڣ�ͼ7.36��
 WINDOW,0,xsize =200,ysize =100
 ;���ö�ͼ��ʾ��2��2��
 !p.MULTI = [2,1,2,0,0]
 ;�ض���λ��Ƭ������Ϊ��Ƭ��С�����ĵ����ꡢ��XYZ��ĽǶ�.
 slice = EXTRACT_SLICE(volume,40,40, 40,50,28, 30,0,0)
 ;��ʾ�����Ƭ.
 TV,slice ,0
 ;��ʾ��ֱ��Ƭ.
 TV,volume[23,*,*],1
 ;����Slicer3���н���ʽ������ע������Ϊָ�루ͼ7.37��
 SLICER3,Ptr_New(volume,/No_Copy)
 
 ;����MERCATORͶӰ
 MAP_SET, /MERCATOR
 ;��ȡ��ǰͶӰ���Ƽ�������Ϣ
 MAP_PROJ_INFO, /CURRENT, NAME=name, AZIMUTHAL=az, $
      CYLINDRICAL=cyl, CIRCLE=cir
 ;���
 print,name,az,cyl,cir
 Mercator       0       1       0
 ;����Goodes HomolosineͶӰ
 sMap = MAP_PROJ_INIT('Goodes Homolosine')
 ;ʹ�ø�ͶӰ����ֵ��ϵͳ����!MAP���ɡ�
 !Map = sMap
 ;��ȡ��ǰͶӰ����
 MAP_PROJ_INFO, /CURRENT, NAME=name
 ;���
 print,name
 GoodesHomolosine
 
 DEVICE, DECOMPOSED=0
 ;����ϵͳ�Զ�����ɫ��
 TEK_COLOR
 ;������ɫ���ƶ�Ӧ����ֵ
 black=0 & white=1 & red=2
 green=3 & dk_blue=4 & lt_blue=5
 ;����MERCATORͶӰ�������հ���ʾ���ڡ�
 MAP_SET, /MERCATOR
 ;Ĭ����ʾMAP_CONTINENTSѡ��
 MAP_CONTINENTS
 ;������ʾ��½�߽���䣬���ɫΪ��ɫ
 MAP_CONTINENTS, /FILL_CONTINENTS, COLOR=white
 ;������ʾ������������ɫ����Ϊǳ��ɫlt_blue
 MAP_CONTINENTS, /RIVERS, COLOR=lt_blue
 ;������ʾ���ұ߽��ߣ��ߴ�Ϊ2����ɫΪ��ɫ
 MAP_CONTINENTS, /COUNTRIES, COLOR=red, MLINETHICK=2
 ;���Ӿ�γ������
 MAP_GRID
 
 ;����ϵͳExampleĿ¼�µ�avhrr.img�ļ���
 file = FILEPATH( 'avhrr.png', SUBDIRECTORY=['examples','data'] )
 ;��ȡ���ݵ������������ݣ��ֱ���ڱ���r��g��b�С�
 data = READ_PNG( file, r, g, b )
 ;���ݽ����ز�������
 red0 = REBIN( r[data], 360, 180 )
 green0 = REBIN( g[data], 360, 180)
 blue0 = REBIN( b[data], 360, 180 )
 ;����iImage������������ʾ�ز���������������������
 IIMAGE, RED=red0, GREEN=green0, BLUE=blue0, $
   DIMENSIONS=[500,600], VIEW_GRID=[1,3]
 ;����ͶӰInterrupted Goode
 sMap = MAP_PROJ_INIT('Interrupted Goode')
 ;�Ե�һ������red0����ͶӰת���������Ĥ�����ļ�mask��
 ;  �ѿ������귶Χuvrange��X��Y������ת����Ӧ��ϵxIndex��yIndex��
 red1 = MAP_PROJ_IMAGE( red0, MAP_STRUCTURE=sMap, MASK=mask, $
   UVRANGE=uvrange, XINDEX=xindex, YINDEX=yindex )
 ;����xIndex��yIndexת���ڶ�������green0�͵���������blue0.
 green1 = MAP_PROJ_IMAGE( green0, XINDEX=xindex, YINDEX=yindex )
 blue1 = MAP_PROJ_IMAGE( blue0, XINDEX=xindex, YINDEX=yindex )
 ;����iImage��ʾת�����ͼ���ļ�����ʾ�������м�λ��
 IIMAGE, RED=red1, GREEN=green1, BLUE=blue1, ALPHA=mask*255b, $
       /VIEW_NEXT
 ;�����µ�MollweideͶӰ
 mapStruct = MAP_PROJ_INIT( 'Mollweide', /GCTP )
 ;���������ƽ��и������ε�ͶӰת��.
 red2 = MAP_PROJ_IMAGE( red1, uvrange, IMAGE_STRUCTURE=sMap, $
   MAP_STRUCTURE=mapStruct, MASK=mask, $
   XINDEX=xindex2, YINDEX=yindex2 )
 green2 = MAP_PROJ_IMAGE( green1, XINDEX=xindex2, YINDEX=yindex2 )
 blue2 = MAP_PROJ_IMAGE( blue1, XINDEX=xindex2, YINDEX=yindex2 )
 ;����iImage��ʾת�����ͼ���ļ�����ʾ���������·�
 IIMAGE, RED=red2, GREEN=green2, BLUE=blue2, ALPHA=mask*255b, $
       /VIEW_NEXT

 ;����ϵͳ����ֵ
 oriBkcolor = !p.BACKGROUND
 !p.BACKGROUND = !p.COLOR
 !p.COLOR = oriBKcolor