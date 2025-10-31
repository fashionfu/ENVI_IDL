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
;�ھ���ʾ������
;-

;�������Ҳ�����������
theory = SIN(2.0*FINDGEN(200)*!PI/25.0)*EXP(-0.02*FINDGEN(200))
;���߿��ӻ�
plot = PLOT(theory, "r4D-", TITLE="Sine Wave")

;���õ�ͼ��ʾ����
ant_map = MAP('STEREOGRAPHIC', $
  Limit = [10,80,50,130], $
  CENTER_LATITUDE=30, $
  CENTER_LONGITUDE=105, $
  title ='Map Example',$
  FILL_COLOR='Light Blue')
;��ʾ��½�߽磬���ñ�����ɫ
mc = MAPCONTINENTS(/COUNTRIES, FILL_COLOR='beige')
;��ʾ����
rivers = MAPCONTINENTS(/RIVERS, COLOR='blue')

;��ȡDem����
dem = READ_BINARY(FILE_WHICH('elevbin.dat'), data_dims=[64,64])
;��ʾDem
c1 = CONTOUR(dem, $
  RGB_TABLE=30, $
  /FILL, $
  PLANAR=0, $
  TITLE='L.A. Basin and Santa Monica Mountains')
;�����ɫ����ͼ9.2��
cbar = COLORBAR(TARGET=c1,ORIENTATION=1, POSITION=[0.9, 0.2, 0.95, 0.75])


;�������Ҳ�����������
theory = SIN(2.0*FINDGEN(200)*!PI/25.0)*EXP(-0.02*FINDGEN(200))
;���߿��ӻ���ͼ9.1��
plot = PLOT(theory, "r4D-", TITLE="Sine Wave")

;������������x�����ƶ�20��ͼ9.3��
PLOT.TRANSLATE,20,0,0,/data
;�ָ���ʼ����ʾ��ͼ9.1��
PLOT.TRANSLATE,/reset
;�޸�x�������ߴ�Ϊ4
PLOT.XTHICK =4
;�޸�y����ı���ɫΪ��ɫ
PLOT.YTEXT_COLOR = 'red'

;����Ϊ��ɫ��ͼ9.4��
PLOT.COLOR='blue'

;�޸�x�������ߴ�Ϊ4
PLOT.XTHICK =4
;�޸�y����ı���ɫΪ��ɫ
PLOT.YTEXT_COLOR = 'red'

;����title����Ϊ�����ı��⡱
PLOT.TITLE='���ı���'
;��Ĭ����ʾ����Ϊ���룬����Ҫ�޸�����
;����ǰtitle��ֵ��oTitle����
oTitle = PLOT.TITLE
;�޸�title������Ϊ��youyuan������Բ����
;�������Ƹ��ݵ�ǰ������а�װ������Ϊ׼��ͼ9.7��
oTitle.FONT_NAME = 'youyuan'


; �ڻ�ͼ��������λ��([0.5,0.5]�Ĺ�һ������)���һ��ɫ����(��r��)ע��
oText = TEXT(0.5,0.5,'abc','r')
;����ɫ
oText.FILL_COLOR='y'
;�޸�����Ϊtimes new roman
oText.FONT_NAME ='times new roman'
;���ֱ�ע�Ӵ֣�ͼ9.8��
oText.FONT_STYLE = 'Bold'


; ���м�(0.5)ƫ��(0.3)λ����ʾ��ѧ����
oMathText1 = TEXT(0.5,0.3,'$a_n^2$','b')
; ���м�(0.5)ƫ��(0.7)λ����ʾϣ����ĸ����ѧ���ţ�ͼ9.9��
oMathText2 = TEXT(0.5,0.7,'$\alpha\beta a_{b_m}e^{x^2}$','b')

; ����һ��������
plot = PLOT(SIN(FINDGEN(200)/10))
; �����߶��ĸ�ת�۵��x����
xdata = [0,50,100,150]
; ����y����
ydata = [-0.5,-1,0,0.5]
; ���ƺ�ɫ�߶Σ�ע��data�ؼ��ֱ�ʾxy�����Ϊ�������ꡣ
pline = POLYLINE(xData,yData,'r',/data)
; ���Ƽ�ͷ�߶Σ���һ�����꣬��ʾ��ͷ�����ɫ���ߴ�Ϊ2��ͼ9.10��
pline1 = POLYLINE([0.3,0.7],[0.6,0.5],/normal,color = !color.GOLD,thick =2)


; ����һ��������
plot = PLOT(SIN(FINDGEN(200)/10))
arrow1 = ARROW([0,0], [0.5,0.5], ARROW_STYLE=1, $
  COLOR=!COLOR.CHARTREUSE, THICK=3,target = plot)
  
;arrow2 = ARROW([400,365], [375,79], /DATA, ARROW_STYLE=2, $
;
;   COLOR=!COLOR.GOLD, THICK=3, FILL_BACKGROUND=0)
  
;������ʾһ��ͼ��
im = IMAGE(FILEPATH('muscle.jpg', $
  SUBDIRECTORY=['examples','data']), $
  TITLE='Muscle Cell Abnormality')
;���Ƽ�ͷ
arrow1 = ARROW([125,252], [233,55], /DATA, ARROW_STYLE=1, $
  COLOR=!COLOR.CHARTREUSE, THICK=3)
;���Ƽ�ͷ
arrow2 = ARROW([400,365], [375,79], /DATA, ARROW_STYLE=1, $
  COLOR=!COLOR.GOLD, THICK=3, FILL_BACKGROUND=0)
;��ͷ1����ע�ǣ����������壨Win7��Vistaϵͳ��Ϊ'stsong'��
t1 = TEXT(81,242,'��ͷ1', /DATA, TARGET=im, $
  FONT_NAME = 'stsong',$
  COLOR=!COLOR.CHARTREUSE)
;��ͷ2����ע�ǣ������ǿ���
t2 = TEXT(372,387,'��ͷ 2', /DATA, TARGET=im, $
  FONT_NAME = 'stkaiti', $
  COLOR=!COLOR.GOLD)
  
  
  
  
;����һ����������
plot = PLOT(SIN(FINDGEN(200)/10))
;��ɫʵ�߻��ƾ���
poly = POLYGON([0.4,0.4,0.6,0.6],[0.4,0.6,0.6,0.4],'r')
;��������Ϊ������
POLY.LINESTYLE = 2
;�׻�ɫ��� ��ͼ9.12��
POLY.FILL_COLOR = !color.BEIGE


;������������
plot = PLOT(SIN(FINDGEN(200)/10))
;�������ߣ�Ҳ����ֱ����window��������
PLOT.HIDE = 1
;�����ĸ����Σ���ɫ����ɫ����ɫ�ͻ�ɫ���������Ϊ4����
;     ��˳�������µ���˳ʱ�뷽��ͼ9.13��
poly1 = POLYGON([0.2,0.2,0.4,0.4],[0.2,0.4,0.4,0.2],'r')
poly2 = POLYGON([0.2,0.2,0.4,0.4],[0.6,0.8,0.8,0.6],'g')
poly3 = POLYGON([0.6,0.6,0.8,0.8],[0.6,0.8,0.8,0.6],'b')
poly4 = POLYGON([0.6,0.6,0.8,0.8],[0.2,0.4,0.4,0.2],'y')
;�޸ľ���1���ӹ�ϵΪ: 2�������ӣ���һ���͵ڶ����㣩
poly1.CONNECTIVITY = [2,0,1]
;�޸ľ���2���ӹ�ϵΪ��3�������ӣ���һ�����ڶ����͵������㣩
poly2.CONNECTIVITY = [3,0,1,2]
;�޸ľ���3���ӹ�ϵΪ��4�������ӣ���һ�����ڶ������������͵��ĸ��㣩
poly3.CONNECTIVITY = [4,0,1,2,3]
;�޸ľ���4���ӹ�ϵΪ��2�������ӣ���һ���͵������㣩+2�������ӣ��ڶ����͵��ĸ��㣩��ͼ9.14��
poly4.CONNECTIVITY = [2,0,2,2,1,3]


; �����հ���ʾ����
w = WINDOW(WINDOW_TITLE="Plot Window")
; ������Բ���û�ɫ���
elp = ELLIPSE(0.3,0.5,major =0.2,minor=0.1,fill_color ='y')
; ������Բ������ɫ��䲢��ʱ����ת45�㣨ͼ9.15��
elp1 = ELLIPSE(0.7,0.5,major =0.2,minor=0.1,fill_color ='b',THETA = 45)


;�����㷨���ݼ�
theory = SIN(2.0*FINDGEN(201)*!PI/25.0)*EXP(-0.02*FINDGEN(201))
;�㷨���ݼ������ϼ������ģ��۲�ʵ������
observed = theory + RANDOMU(seed,201)*0.4-0.2
;����ģ��۲�����
p1 = PLOT(observed, NAME='Observed')
;�����㷨���ݣ���ɫ�Ӵ֣�
p2 = PLOT(theory, /OVERPLOT, 'r2', NAME='Theory')
;���ͼ����ͼ9.16��
l = LEGEND(TARGET=[p1,p2], POSITION=[140,0.9], /DATA)



;������������
sinewave = SIN(2.0*FINDGEN(200))*EXP(-0.02*FINDGEN(200))
;������������
cosine = COS(2.0*FINDGEN(200))*EXP(-0.02*FINDGEN(200))
;ָ����ʾ�����ɫ����������������
p=PLOT(sinewave, '-r', AXIS_STYLE=1, $
  POSITION=[.075,.075,.90,.90])
;ָ����ʾ������ɫ���������������ߣ�ͼ9.17��
p=PLOT(cosine, '-b', AXIS_STYLE=1, $
  /CURRENT, POSITION=[.60,.60,.90,.90])
  
  
;����200��Ԫ�ص���������
x = FINDGEN(200)
;����3D���ߣ�ͼ9.18��
plot3d = PLOT3D(x *COS(x/10), x*SIN(x/10), x, 'b2d')
;��õ�ǰϵͳĿ¼
CD, current = curdir
;����鿴
PRINT,curdir
;�޸�ϵͳĿ¼Ϊ��c:\temp��
CD, 'c:\temp'
;����Ϊbmp�ļ���300�ķֱ���
PLOT3D.SAVE,'plot3d.bmp',resolution =300




END