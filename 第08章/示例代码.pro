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
;-
;�ڰ�������ʾ������
;-

;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [600,400])
;����һ����ʾview
oView = Obj_New('IDLgrView')
;����model����
oModel = Obj_New('IDLgrModel')
;model��ӵ�view
oView.ADD,oModel
;����һ���ı�����
oText = Obj_New('IDLgrText','Using IDL Objects!')
;��Ӷ���model��
oModel.ADD,oText
;window�������view����ͼ8.2��
oWindow.DRAW, oView



;����IDLgrWindow���󣬴�СΪ400*300.
owindow = Obj_new('idlgrwindow', $
  dimensions = [400,300], $
  title ='400*300')
;����IDLgrWindow���󣬴�СΪ200*200������ʾ�����Ͻ�ƫ����Ϊ400*50.
owindow = Obj_new('idlgrwindow', $
  dimension = [200,200], $
  title ='200*200', Location = [400,50])
  
;ʵ����IDLgrWindow����
owindow = Obj_New('idlgrwindow',dimension = [400,300])
;����IDLgrView���󣬱���ɫΪ��ɫ
oView = Obj_New('IDLgrView',color = (bytarr(3)+1)*128)
;������ʾ��ͼ8.4-(a)��
oWindow.DRAW,oView

;����window����
oWindow= Obj_New('IDLgrWindow',retain=2,dimension = [600,400])
;����һ����ʾview
oView = Obj_New('IDLgrView')
;����model����
oModel = Obj_New('IDLgrModel')
;model��ӵ�view
oView.ADD,oModel
;����һ�����߶���
x = findgen(200)/100-1
oSinPlot = Obj_New('IDLgrPlot',x,sin(x*2*!pi))
;��Ӷ���model��
oModel.ADD,oSinPlot
;window�������view����ͼ8.5��
oWindow.DRAW, oView


;����window����
oWindow= Obj_New('IDLgrWindow',retain=2,dimension = [400,300])
;����һ����ʾview����ɫ����
oView = Obj_New('IDLgrView', $
  color =[128,128,128], $
  viewPlane_Rect = [-100,-100,400,400])
;����oWindow����Ⱦ������oView
oWindow.SETPROPERTY, Graphics_tree = oView
;window������Ⱦ��ʾ��ͼ8.7-(1)��
oWindow.DRAW

;����model����
oModel = Obj_New('IDLgrModel')
;model��ӵ�view
oView.ADD,oModel
;����һ��ͼ��200*200
oImage = Obj_New('IDLgrImage',DIST(200))
;��Ӷ���model��
oModel.ADD,oImage
;window������Ⱦ��ʾ��ͼ8.7-(2)��
oWindow.DRAW

oView.SETPROPERTY,dimensions = [200,150]
;window����������ɶԱȲ鿴�кβ�ͬ��
;oWindow.Erase
;window������Ⱦ��ʾ��ͼ8.7-(3)��
oWindow.DRAW
oView.SETPROPERTY,location = [100,100]
;window�������
;oWindow.Erase
;window������Ⱦ��ʾ��ͼ8.7-(4)��
oWindow.DRAW


;����window����
oWindow= Obj_New('IDLgrWindow',retain=2,dimension = [400,300])
;����һ����ʾview
oView = Obj_New('IDLgrView')
;����oWindow����Ⱦ������oView
oWindow.SETPROPERTY, Graphics_tree = oView
;����model����
oModel = Obj_New('IDLgrModel')
;model��ӵ�view
oView.ADD,oModel
;����һ��ͼ��200*200
oImage = Obj_New('IDLgrImage',DIST(200))
;��Ӷ���model��
oModel.ADD,oImage
;window������Ⱦ��ʾ��ͼ8.9-(1)����ʱViewPortĬ��ֵ��Ϊ[0,0,1,1]
oWindow.DRAW
;����View��ViewPort��Χ[0,0,200,200]������ʾ������ԭͼһ�¡�
oView.SETPROPERTY, viewPlane_Rect = [0,0,200,200]
;window������Ⱦ��ʾ��ͼ8.9-(2)
oWindow.DRAW
;����View��ViewPort��Χ[-100,-100,400,400]
oView.SETPROPERTY, viewPlane_Rect = [-100,-100,400,400]
;window������Ⱦ��ʾ��ͼ8.9-(3)
oWindow.DRAW
;����View��ViewPort��Χ[100,100,200,200]
oView.SETPROPERTY, viewPlane_Rect = [100,100,200,200]
;window������Ⱦ��ʾ��ͼ8.9-(4)
oWindow.DRAW


;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,300])
;����һ����ʾview������zClip��֪zֵ�� [-1,1]֮����Ա�����
oView = Obj_New('IDLgrView', $
  zClip = [1,-1],$
  eye = 5, $
  viewPlane_Rect = [0,0,300,300])
;����oWindow����Ⱦ������oView
oWindow.SETPROPERTY, Graphics_tree = oView
;����model����
oModel = Obj_New('IDLgrModel')
;model��ӵ�view
oView.ADD,oModel
;����һ���������飬ע��Z����߶Ⱦ�Ϊ0.5
polyData = [[50,50,0.5],[50,150,0.5],[150,150,0.5],[150,50,0.5]]
;����һ��ɫ����
oRedPoly = Obj_New('IDLgrPolygon', polydata, color = [255,0,0])
;�޸ĸ����ݣ�ʹ��x��y���������100��z��������1���߶Ⱦ�Ϊ1.5
polyData[0,*] +=100
polyData[1,*] +=100
polyData[2,*] +=1
;����һ��ɫ����
oBluePoly = Obj_New('IDLgrPolygon', polydata, $
  color = [0,255,0])
;��Ӷ���model��
oModel.ADD,[oRedPoly,oBluePoly]
;window������Ⱦ��ʾ��ͼ8.13-(1)����
oWindow.DRAW
;����view����z������ӷ�ΧΪ[-1,2]
oView.SETPROPERTY,zClip = [2,-1]
;window������Ⱦ��ʾ��ͼ8.13-(2)����
oWindow.DRAW

;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [600,400])
;����scene����
oScene = Obj_New('IDLgrScene')
;�½�view,��СΪ�����ķ�֮һ��λ�����½ǣ���Ϊǳ��ɫ, unitsΪ3����һ������
oView1= Obj_New('IDLgrView', $
  location = [0,0.5], dimension = [0.5,0.5], $
  color = [100,100,100],units = 3)
;�½�view,��СΪ�����ķ�֮һ��λ�����½ǣ���Ϊ��ɫ
oView2= Obj_New('IDLgrView', $
  location=[0.5,0], dimension=[0.5,0.5],$
  color = [255,0,0],units=3)
;���oView��oView2���󵽳���oScene��
oScene.ADD,[oView1,oView2]
;window������Ⱦscene���󣬼����Ƴ�����ͼ8.14��
oWindow.DRAW,oScene


;��ʼ����ʾ����,��СΪ400*400����
oWindow = Obj_New('IDLgrWindow',dimension =[400,400],retain = 2)
;����View������ʾ��Χ([-1,-1,2,2]),��ʾ���½�Ϊ[-1,-1]���Ͻ�Ϊ[1,1]
oView = Obj_New('IDLgrView',viewPlane_Rect = [-1,-1,2,2])
;������ʾ����ͼ8.16-(a)
oWindow.DRAW,oView
;�������½���[-1,-1]���߳�Ϊ1�ĺ�ɫ�����Ρ�
oPolygon = Obj_New('IDLgrPolygon',[[-1,-1],[-1,0],[0,0],[0,-1]],$
  color =[255,0,0])
;������ʾ��ϵ���
oModel = Obj_New('IDLgrModel')
oModel.ADD,oPolygon
oView.ADD,oModel
;������ʾ����ͼ8.16-(b)
oWindow.DRAW,oView
;ƽ��ͼ�Σ�X��Y�����ƶ�0.5��Z���򲻶�
oModel.TRANSLATE,0.5,0.5,0
;������ʾ����ͼ8.16-(c)
oWindow.DRAW,oView
;��תͼ�Σ���Z��˳ʱ��45
oModel.ROTATE,[0,0,1],45
;������ʾ����ͼ8.16-(d)
oWindow.DRAW,oView
;����ͼ�Σ�X��Y������Ϊ0.5��Z���򲻱�
oModel.SCALE,0.5,0.5,1
;������ʾ����ͼ8.16-(e)
oWindow.DRAW,oView
;�ָ�����ʼ״̬
oModel.RESET
;������ʾ����ͼ8.16-(f)
oWindow.DRAW,oView

;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,300])
;����IDLgrView����
oView= Obj_New('IDLgrView')
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;������ʾ��ϵ���
oView.ADD,oModel
x = [-.5,.5]
y = [-.5,.5]
;����Idlgrpolyline����
oPolyline = Obj_New('IDLgrPolyline',x,y)
oModel.ADD,oPolyline
;������ʾ����ͼ8.17-(a)
oWIndow.DRAW,oView
;���߶��������ɫ���޸�
oPolyline.SETPROPERTY,color =[255,0,0]
;������ʾ����ͼ8.17-(b)
oWIndow.DRAW,oView
;�޸��ߴ�Ϊ5
oPolyline.SETPROPERTY,thick = 5
;������ʾ����ͼ8.17-(c)
oWIndow.DRAW,oView
;����һ�������ݶ�
data = fltarr(2,4)
data[0,*]= [-.5,-.5,.5,.5]
data[1,*]= [-.5,.5,.5,-.5]
;��ֵ
oPolyline.SETPROPERTY,data = data
;������ʾ����ͼ8.17-(d)
oWIndow.DRAW,oView
;����ͼ�����ӹ�ϵ
polylines = [4,0,1,3,2]
oPolyline.SETPROPERTY,polylines = polylines
;������ʾ����ͼ8.17-(e)
oWIndow.DRAW,oView
;���������ӹ�ϵ
polylines = [5,0,1,2,3,0]
oPolyline.SETPROPERTY,polylines = polylines
;������ʾ����ͼ8.17-(f)
oWIndow.DRAW,oView
;X�����ӹ�ϵ
polylines = [2,0,2,2,1,3]
oPolyline.SETPROPERTY,polylines = polylines
;������ʾ����ͼ8.17-(g)
oWIndow.DRAW,oView
;������+�Խ������ӹ�ϵ
polylines = [5,0,1,2,3,0,2,0,2,2,1,3]
oPolyline.SETPROPERTY,polylines = polylines
;������ʾ����ͼ8.17-(h)
oWIndow.DRAW,oView

;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,400])
;����IDLgrView����
oView= Obj_New('IDLgrView')
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;����IDLgrPolyline����
oPolyline = Obj_New('IDLgrPolyline')
oPolygon = Obj_New('IDLgrPolygon')
;������ʾ��ϵ���
oView.ADD,oModel
oModel.ADD,[oPolyline,oPolygon]
;����һ�������ݶ�
data = fltarr(2,4)
data[0,*]= [-.5,-.5,-.1,-.1]
data[1,*]= [-.5,-.1,-.1,-.5]
;�����߶���Ϊ��ɫ��ֵΪdata
oPolyline.SETPROPERTY,color =[255,0,0],data = data
;���ö���ζ���Ϊ��ɫ��ֵΪdata��X��Y����ƫ��0.5
oPolygon.SETPROPERTY,color =[0,0,255],data = data+0.5
;������ʾ��ͼ8.20��
oWIndow.DRAW,oView

;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,400])
;����IDLgrView����
oView= Obj_New('IDLgrView')
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;����IDLgrPolygon����
oPolygon = Obj_New('IDLgrPolygon')
;������ʾ��ϵ���
oView.ADD,oModel
oModel.ADD,oPolygon
;����һ������
data = fltarr(2,4)
data[0,*]= [-.5,-.5,.5,.5]
data[1,*]= [-.5,.5,.5,-.5]
;���ö���ζ���Ϊ��ɫ��ֵΪdata
oPolygon.SETPROPERTY,color =[0,0,255],data = data
;������ʾ����ͼ8.21-(a)
oWIndow.DRAW,oView
;������ʽ����
oPattern = Obj_New('IDLgrPattern',1)
;���ö������ʽ���
oPolygon.SETPROPERTY, fill_pattern= oPattern
;������ʾ����ͼ8.21-(b)
oWIndow.DRAW,oView
;��ȡ�����ļ�,ע�������ļ�·��
read_jpeg,'c:\data\tree.jpg',imgData,/true
;�����������
oImage = Obj_New('IDLgrImage',imgData,BLEND_FUNCTION =[3,4])
;ΪIDLgrPolygon����ֵ�����������������ʽ������Ҫ��Ҫ�����ʽ.
oPolygon.SETPROPERTY, Texture_map = oImage,fill_pattern= Obj_New(),$
  Texture_Coord = [[0,0], [0,1], [1,1], [1,0]],color = [255,255,255]
;������ʾ����ͼ8.21-(c)
oWIndow.DRAW,oView
;�����������꣬��ʱ�����������ʾͼ����X��Y�����������Ρ�
Texture_Coord = [[0,0], [0,2], [2,2], [2,0]]
oPolygon.SETPROPERTY,Texture_Coord = Texture_Coord
;������ʾ����ͼ8.21-(d)
oWIndow.DRAW,oView

;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,300])
;����IDLgrView����
oView= Obj_New('IDLgrView')
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;����IDLgrPolygon����
oPolygon = Obj_New('IDLgrPolygon')
;������ʾ��ϵ���
oView.ADD,oModel
oModel.ADD,oPolygon
;����һ�������
data = fltarr(2,8)
data[0,*]= [-.75,.75,.75,.25,.25,-.25,-.25,-.75]
data[1,*]= [-.75,-.75,.75,.75,0,0,.75,.75]
;���ö���ζ���Ϊ��ɫ��ֵΪdata
oPolygon.SETPROPERTY,color =[0,0,255],data = data
;������ʾ����ͼ8.22-(a)
oWIndow.DRAW,oView
;����IDLgrTessellator����
oTessellator = Obj_New('IDLgrTessellator')
;��Ӷ���ζ���
oTessellator.ADDPOLYGON,data
;��������ת��Ϊ�����εĶ�������ӹ�ϵ
tmp = oTessellator.TESSELLATE(vert,poly)
;���ö���ζ���Ķ������ݺ����ӹ�ϵ
oPolygon.SETPROPERTY,data = vert, polygons = poly
;������ʾ����ͼ8.22-(b)
oWIndow.DRAW,oView



;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,300])
;����IDLgrView����
oView= Obj_New('IDLgrView')
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;������ʾ��ϵ���
oView.ADD,oModel
oWindow.SETPROPERTY,graphics_tree = oView
oText = Obj_New('IDLgrText','Hello IDL!',Alignment = 0.5)
;��Ӷ���model��
oModel.ADD,oText
;������ʾ����ͼ8.23-(a)
oWIndow.DRAW
;�޸�������ɫΪ��ɫ
oText.SETPROPERTY, color=[255,0,0]
;������ʾ����ͼ8.23-(b)
oWIndow.DRAW
oText.SETPROPERTY, strings = ['IDL','ENVI']
;������ʾ����ͼ8.23-(c)
oWindow.DRAW,oView
oText.SETPROPERTY, location = [[0,0],[.5,.5]]
;������ʾ����ͼ8.23-(d)
oWindow.DRAW
;baseline�����ֵĻ�׼�����ɶ�ά����ά��ʸ����ɡ�
oText.SETPROPERTY, BASELINE =[1,1]
;������ʾ����ͼ8.23-(e)
oWIndow.DRAW
;char_dimensionָ��������ռ�Ĵ�С
oText.SETPROPERTY,baseline=[1,0],updir =[0,1], CHAR_DIMENSION = [.5,.5]
;������ʾ����ͼ8.23-(f)
oWIndow.DRAW
;VERTICAL_ALIGNMENT��ָ������y�����λ�ã�0�����ֵײ�������׼�棨Ĭ�ϣ�
; 1�����ֶ���������׼�档
oText.SETPROPERTY, VERTICAL_ALIGNMENT=1
;������ʾ����ͼ8.23-(g)
oWIndow.DRAW
;DRAW_CURSOR���������м��Ƿ��й��
;Selection_start����ѡ��ʼ�ַ�����
;Selection_length����ѡ���ַ����ȡ�
oText.SETPROPERTY,draw_cursor =1, SELECTION_START=1, SELECTION_LENGTH =2
;������ʾ����ͼ8.23-(h)
oWIndow.DRAW



;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,300])
;����IDLgrView����
oView= Obj_New('IDLgrView')
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;������ʾ��ϵ���
oView.ADD,oModel
oWindow.SETPROPERTY,graphics_tree = oView
;����IDLgrText����
oText = Obj_New('IDLgrText','IDL uses fonts!',font = myFont)
oModel.ADD,oText
;������ʾ����ͼ8.24-(a)
oWIndow.DRAW
;����IDLgrFont����
oFont = OBJ_NEW('IDLgrFont', 'times', SIZE=20)
;ʹ��oFont����
oText.SETPROPERTY, font = oFont
;������ʾ����ͼ8.24-(b)
oWindow.DRAW


;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,200])
; ����IDLgrView����
oView= Obj_New('IDLgrView',viewPlane_Rect=[-10,-1,200,2])
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;������ʾ��ϵ���
oView.ADD,oModel
oWindow.SETPROPERTY,graphics_tree = oView
;���������ᣬ0ΪX�ᣨ1ΪY�ᣬ2ΪZ�ᣩ���ߴ�Ϊ2����ɫ
oAxis = OBJ_NEW('IDLgrAxis',0,range =[0,180], $
  location =[0,-0.5],thick =2, color =[255,0,0])
oModel.ADD,oAxis
;������ʾ����ͼ8.25-(a)
oWindow.DRAW
;10����̶��ߣ��м�5��С�̶��ߣ�tickdir���ƿ̶�����x����
oAxis.SETPROPERTY, major= 10,minor =5, tickdir =1
;������ʾ����ͼ8.25-(b)
oWindow.DRAW
;���ֱ�ע���룬textAlign�ֱ���[ˮƽ������ֱ����]
oAxis.SETPROPERTY, textAlign =[0,1]
;������ʾ����ͼ8.25-(c)
oWindow.DRAW
;���ֱ�ע����
oAxis.SETPROPERTY, textAlign =[1,1]
;������ʾ����ͼ8.25-(d)
oWindow.DRAW
;����X��������⣬��ɫ
oText = OBJ_NEW('IDlgrText','X Axis',color =[0,0,0])
oAxis.SETPROPERTY, title= oText,tickValues = [0,60,120,150,180]
;������ʾ����ͼ8.25-(e)
oWindow.DRAW
;�������������ֻ���
oAxis.SETPROPERTY, TextBaseline=[-1,0,0]
;������ʾ����ͼ8.25-(f)
oWindow.DRAW
;�������������ֻ���
oAxis.SETPROPERTY, TextBaseline=[1,0,0]
;������ʾ����ͼ8.25-(g)
oWindow.DRAW
;�����������ı�����
oTickText = OBJ_NEW('IDLgrText',['A','B','C','D','E'], color = [0,0,255])
;�����ı��ַ���use_text_color�����Ƿ���ʾ���ֶ�����ɫ
oAxis.SETPROPERTY, TextBaseline=[1,0,0],$
  tickText = otickText,/USE_TEXT_COLOR
;������ʾ����ͼ8.25-(h)
oWindow.DRAW


;����window����
oWindow= OBJ_NEW('IDLgrWindow',dimension = [400,300])
;����IDLgrView����
oView= OBJ_NEW('IDLgrView')
;����IDLgrModel����
oModel = OBJ_NEW('IDLgrModel')
;������ʾ��ϵ���
oView.ADD,oModel
oWindow.SETPROPERTY,graphics_tree = oView
;����jpg�ļ���
file = FILEPATH('rose.jpg', SUBDIRECTORY = ['examples', 'data'])
;��ѯͼ����Ϣ
queryStatus = QUERY_IMAGE(file, imageInfo)
imageSize = imageInfo.DIMENSIONS
;��ȡͼ������
image = READ_IMAGE(file)
;����ͼ�����
oImage = Obj_New('IDLgrImage',image)
oModel.ADD,oImage
;������ʾ����Χ
oView.SETPROPERTY,viewPlane_Rect = [0,0,imageSize]
;������ʾ���ڴ�С
oWindow.SETPROPERTY,dimension = imageSize
;������ʾ��ͼ8.26-(a)��
oWindow.DRAW
;����ͼ�����
Obj_Destroy,oImage
;������ʾ����ΪX����Ϊͼ������
oView.SETPROPERTY,viewPlane_Rect = [0,0,imageSize]*[0,0,3,1]
;����R��G��B���λҶ�ͼ��
oRed = Obj_New('IDLgrImage',image[0,*,*])
oGreen = Obj_New('IDLgrImage',image[1,*,*], $
  Location = [imageSize[0],0])
oBlue = Obj_New('IDLgrImage',image[2,*,*], $
  Location = [imageSize[0]*2,0])
;��Ӷ���
oModel.ADD,[oRed, oGreen, oBlue]
;������ʾ���ڴ�С
oWindow.SETPROPERTY,dimension = imageSize*[3,1]
;������ʾ��ͼ8.26-(b)��
oWindow.DRAW
;��������ͼ���λ��
oGreen.SETPROPERTY, Location=imageSize*.5
oBlue.SETPROPERTY, Location=imageSize
;���ô��ڴ�С
oWindow.SETPROPERTY, dimension = imageSize*2
;������ʾ�����С
oView.SETPROPERTY,viewPlane_Rect = [0,0,imageSize]*[0,0,2,2]
;������ʾ��ͼ8.26-(c)��
oWindow.DRAW


;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,300])
; ����IDLgrView����,��ʾ����Ϊ[-100,-50,400,300]
; �ɸ�����ʾЧ������¸ò����ĺ���
oView= Obj_New('IDLgrView', ViewPlane_Rect = [-100,-50,400,300])
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;������ʾ��ϵ���
oView.ADD,oModel
;����������ͼ�����
oImage = Obj_New('IDLgrImage',Bytscl(DIST(200)))
;��Ӷ���Model��
oModel.ADD,oImage
;������ʾ����ͼ8.27-(a)
oWindow.DRAW,oView
;����IDLgrPalette������������Ϊ2��ϵͳ��ɫ��
oPalette = Obj_New('IDLgrPalette')
oPalette.LOADCT,2
;����ͼ����ɫ��
oImage.SETPROPERTY, palette = oPalette
;������ʾ����ͼ8.27-(b)
oWindow.DRAW,oView

;����window����
oWindow= Obj_New('IDLgrWindow',dimension = [400,300])
;����IDLgrView����
oView= Obj_New('IDLgrView')
oView.GETPROPERTY, ViewPlane_Rect = vp
;�鿴vp��ֵ������ΪIDLgrView�����ʼ������

;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;������ʾ��ϵ���
oView.ADD,oModel
;����������ͼ�����
oImage = Obj_New('IDLgrImage',Bytscl(DIST(200)))
;��Ӷ���Model��
oModel.ADD,oImage
;������ʾ����ͼ8.28-(a)
oWindow.DRAW,oView
;��ȡ�����X�����Y��������ݷ�Χ
oImage.GETPROPERTY, XRange = xr, YRange = yr
;���ö���Ĺ�һ��ת��ϵ�������ú���Norm_Coord��⣡
oImage.SETPROPERTY, XCoord_Conv = NORM_COORD(xr), YCoord_Conv = NORM_COORD(yr)
;������ʾ����ͼ8.28-(b)
oWindow.DRAW,oView
;����view����ʾ��Χ��[0,0,1,1]
oView.SETPROPERTY, viewPlane_Rect = [0,0,1,1]
;������ʾ����ͼ8.28-(c)
oWindow.DRAW,oView
polyData = [[0.3,0.3],[0.3,0.7],[0.7,0.7],[0.7,0.3]]
;��Ӿ��ζ�����ɫ����Ϊ��ɫ
oModel.ADD,Obj_New('IDLgrPolygon',polyData,$
  color = [255,0,0])
;������ʾ����ͼ8.28-(d)
oWindow.DRAW,oView

;����400*300�Ľ���
wTlb = Widget_Base(xSize = 400,ysize =300)
;����wDraw���������ͼ�η���Draw����СΪ300*200����������ʾ��
;ע�⣬��ʱ�Ĵ�С�Ͷ�λ�����Ϊʵ�����سߴ硣���豸����ϵ��
wDraw = Widget_Draw(wTlb, $
  Graphics_Level = 2, $
  xSize = 300,ysize = 200,$
  xOffset = 50,yOffset = 50)
;������ƣ���ͼ8.29-(a)
Widget_Control, wTlb,/Realize
;���wDraw�����value���˼�IDLgrWindow����
Widget_Control, wDraw,Get_Value = oWindow
; ����IDLgrView����
oView= Obj_New('IDLgrView')
;����IDLgrModel����
oModel = Obj_New('IDLgrModel')
;������ʾ��ϵ���
oView.ADD,oModel
;�����������߶���
oPlot = Obj_New('IDLgrPLot',Sin(findgen(300)/10))
;��Ӷ���Model��
oModel.ADD,oPlot
;������ʾ����ͼ8.29-(b)��ע���ʱ��������ϵ��ƥ�䣡
oWindow.DRAW,oView
;������ʾ��ΧΪ��������ϵ
oView.SETPROPERTY,viewPlane_Rect = [0,-1,300,2]
;������ʾ����ͼ8.29-(c)
oWindow.DRAW,oView
;����IDLgrView�����һ������ϵ����
oView.SETPROPERTY, viewPlane_Rect = [0,0,1,1]
;��ȡͼ�����ݷ�Χ
oPlot.GETPROPERTY, XRange = xr,yRange = yr
;���ö���Ĺ�һ��ת��ϵ��
oPlot.SETPROPERTY, XCoord_Conv = NORM_COORD(xr), $
  YCoord_conv = NORM_COORD(yr)
;������ʾ����ͼ8.29-(d)
oWindow.DRAW,oView

;����window����
oWindow = OBJ_NEW('IDLgrWindow',dimension =[400,400],retain = 2)
;����view������ʾ����Z����Χ���ӽǸ߶ȵȲ���
oView = OBJ_NEW('IDLgrView',viewPlane_Rect =[-1,-1,3,3],zClip = [4,-4],eye = 5)
oModel = OBJ_NEW('IDLgrModel')
;���������
oPoly = OBJ_NEW('IDLgrPolygon')
;���ö�������ϵ�ṹ
oView.ADD,oModel & oModel.ADD,oPoly
;��������
verts = [[0,0,0],[1,0,0],[1,1,0],[0,1,0], $
  [0,0,1],[1,0,1],[1,1,1],[0,1,1]]
;��������˳��
connect =[4, 0,1,2,3, $
  4,0,1,5,4, $
  4,1,2,6,5, $
  4,2,3,7,6, $
  4,3,0,4,7, $
  4, 4,5,6,7]
;���ö���ζ��������ӹ�ϵ��������ʾΪ��
oPoly.SETPROPERTY,data =verts, polygons = connect,style =1
;ѡ��45��
oModel.ROTATE ,[1,1,0],45
;������ʾ��ͼ8.31-(a)��
oWindow.DRAW,oView
;���������嶥����ɫ
vertscolor = [[0,0,0],[1,0,0],[1,1,0],[0,1,0], $
  [0,0,1],[1,0,1],[1,1,0],[0,1,1]]*255
;��������������ʾ������Ⱦ��ʾ��ɫ
oPoly.SETPROPERTY, vert_color = vertsColor,$
  style=2, shading = 1
;������ʾ��ͼ8.31-(b)��
oWindow.DRAW,oView

;����Բ����
oCircle = Obj_New('IDLgrCircle',[0,0])
;ע�⣬�����radiusδ���ã��ʶ���δ�����ɹ���
print,Obj_Valid(oCircle)

;������ȷ�������ô���Բ����
oCircle = Obj_New('IDLgrCircle',[0,0],1.5)
;����GetProperty������ȡԲ�뾶
oCircle.GETPROPERTY,Radius = r
;����鿴
print,r

;Բ�����ඨ��
oCircle = Obj_New('IDLgrCircle')
;��ʾԲ����ͼ8.34-(a)��
oCircle.SHOW
;����Բ�����������ɫ
oCircle.SETPROPERTY,color = [255,0,0]
;��ʾԲ����ͼ8.34-(b)��
oCircle.SHOW
;����Բ�������������Ϊ��
oCircle.SETPROPERTY,style = 1
;��ʾԲ����ͼ8.34-(c)��
oCircle.SHOW
;����Բ�������
oCircle.SETPROPERTY,thick = 5
;��ʾԲ����ͼ8.34-(d)��
oCircle.SHOW
;��ȡԲ������ɫ����
oCircle.GETPROPERTY,color = circleColor
;�����ɫ
print,circleColor
;����Բ����
Obj_Destroy,oCircle
END