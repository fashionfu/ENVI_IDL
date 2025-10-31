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
;��������
PRO ImgSHow::CLEANUP
  IF OBJ_VALID(self.OIMAGE) THEN OBJ_DESTROY, self.OIMAGE
END
;�޸������С��
PRO ImgSHow::ChangeDrawSize,width,height
  IF N_ELEMENTS(width) THEN BEGIN
    self.OWINDOW.GETPROPERTY, graphics_tree = oView
    oView.GETPROPERTY,ViewPlane_Rect = viewP,dimensions = dims
    oriWL = viewP[2:3]
    viewP[2:3] =viewP[2:3]*[width,height]/dims
    viewP[0:1]+=(oriWL-viewP[2:3])/2
    oView.SETPROPERTY,dimension = [width,height],viewPlane_Rect= viewP
    self.OWINDOW.DRAW
  ENDIF
END

;ͼ����
PRO ImgSHow::process,type = type
  CASE type OF
    ;��ֵƽ��
    'Smooth':BEGIN
    data = *(self.ORIDATA)
    FOR i=0,2 DO data[i,*,*] = SMOOTH(REFORM(data[i,*,*]), 5, /EDGE_TRUNCATE)
    self.OIMAGE.SETPROPERTY, data = data
  END
  'CANNY': BEGIN
    data = *(self.ORIDATA)
    FOR i=0,2 DO data[i,*,*] = 255*CANNY(REFORM(data[i,*,*]),HIGH = .8, LOW = .8, SIGMA = .6)
    self.OIMAGE.SETPROPERTY, data = data
  END
  ELSE:
ENDCASE
self.OWINDOW.DRAW
END
;��������
PRO ImgSHow::GetProperty, initFlag = initFlag
  initFlag= self.INITFLAG
END

;��������
PRO ImgSHow::SetProperty, mouseType = mouseType
  self.MOUSETYPE= mouseType
END

;������ʱ���¼�
PRO ImgSHow::WheelEvents,wType,xPos,yPos
  COMPILE_OPT idl2
    
  self.OWINDOW.GETPROPERTY, dimensions = winDims,graphics_tree = oView
  oView.GETPROPERTY, viewPlane_Rect = viewRect  
  IF wType GT 0 THEN rate = 0.8 ELSE rate = 1.125
  
  oriDis =[xPos,yPos]*viewRect[2:3]/winDims
  viewRect[0:1]+=(1-rate)*oriDis
  viewRect[2:3]= viewRect[2:3]*rate
  ;
  oView.SETPROPERTY, viewPlane_Rect = viewRect
  self.OWINDOW.DRAW
END
;�����ʱ���¼�
PRO ImgSHow::MousePress,xpos,ypos  
  self.MOUSELOC[0:1] = [xPos,yPos]
END
;��굯��ʱ�Ĳ���
PRO ImgSHow::MouseRelease,xpos,ypos
  
  curLoc = [xPos,yPos]
  self.OWINDOW.GETPROPERTY, dimensions = winDims,graphics_tree = oView
  oView.GETPROPERTY, viewPlane_Rect = viewRect  
  self.OWINDOW.DRAW
END

PRO ImgSHow::MouseMotion,xpos,ypos
  ;
  curLoc = [xPos,yPos]
  ;
  self.OWINDOW.GETPROPERTY, dimensions = winDims,graphics_tree = oView
  oView.GETPROPERTY, viewPlane_Rect = viewRect
  
  ;��Ļƫ����
  offset = curLoc- self.MOUSELOC
  ;��Ӧƫ����
  viewRect[0:1]-=offset*viewRect[2:3]/WinDims
  oView.SETPROPERTY, viewPlane_Rect = viewRect
  self.OWINDOW.DRAW
  ;
  self.MOUSELOC = curLoc
  
END
;��ʼ��ͼ����ʾ��ע��XY����ͬ�����任
PRO ImgSHow::originalShow
  ;
  self.OWINDOW.GETPROPERTY, dimensions = windowDims,graphics_tree = oView
  imageDims = self.IMAGEDIMS
  ;
  imgRate = FLOAT(imageDims[0])/imageDims[1]
  viewRate = FLOAT(windowDims[0])/windowDims[1]
  ;
  IF imgRate GT viewRate THEN BEGIN
    viewWidth = imageDims[0]
    viewHeight = imageDims[0]/viewRate
    viewPlant_rect = [0, -(viewHeight-imageDims[1])/2,viewWidth,viewHeight]    
  ENDIF ELSE BEGIN
    viewHeight = imageDims[1]
    viewwidth = imageDims[1]*ViewRate
    viewPlant_rect = [-(viewwidth-imageDims[0])/2,0,viewWidth,viewHeight]    
  ENDELSE
  oView.SETPROPERTY, viewPlane_Rect = viewPlant_rect,dimensions = WindowDims
  self.OWINDOW.DRAW
END
;������ʾͼ����ϵ
PRO ImgSHow::CreateDrawImage
  oView = OBJ_NEW('IDLgrView',color = [255,255,255])
  self.OWINDOW.SETPROPERTY, graphics_tree = oView
  
  queryStatus = QUERY_IMAGE(self.INFILE, imageInfo)
  IF queryStatus EQ 0 THEN BEGIN
    self.INITFLAG= 0
    RETURN
  ENDIF  
  self.IMAGEDIMS = imageInfo.DIMENSIONS
  data = READ_IMAGE(self.INFILE)
  self.ORIDATA = PTR_NEW(data,/no_Copy)
  ;
  IF imageInfo.CHANNELS EQ 1 THEN BEGIN
    self.RGBTYPE =0
    self.OIMAGE = OBJ_NEW('IDLgrImage',*(self.ORIDATA) )
  ENDIF ELSE BEGIN
    self.RGBTYPE =1
    self.OIMAGE = OBJ_NEW('IDLgrImage',*(self.ORIDATA) ,INTERLEAVE =0)
  ENDELSE
  ;������ɫ���Σ���ʼ��Ϊ����
  self.ORECT = OBJ_NEW('IDLgrPolygon', $
    style =1,$
    thick=1,$
    color = [230,0,0],/hide)    
  oModel = OBJ_NEW('IDLgrModel')  
  oModel.ADD, [self.OIMAGE,self.ORECT]
  oView.ADD,oModel
  self.ORIGINALSHOW
  self.INITFLAG= 1
END
;���ʼ������
FUNCTION ImgSHow::INIT,drawID
  ;
  routinefile = ROUTINE_FILEPATH('IMGSHOW__DEFINE')  
  ;READ_JPEG,
  self.INFILE = FILE_DIRNAME(routinefile)+'\can_tmr.jpg'
  ;�����drawID
  WIDGET_CONTROL, drawID, get_Value = oWindow
  self.OWINDOW = oWindow
  ;����CreateImage����������ʾͼ��
  self.CREATEDRAWIMAGE
  self.OWINDOW.DRAW
  RETURN, self.INITFLAG
END
;�����ඨ��
PRO IMGSHOW__DEFINE
  struct = {ImgSHow, $
    initFlag  : 0b, $
    mouseType : 0B, $;���״̬��0-Ĭ��,1-ƽ��,2-�Ŵ�,3-��С��
    mouseLoc : FLTARR(2), $
    infile: '' , $
    rgbType : 0, $
    imageDims : LONARR(2), $
    oriData  : PTR_NEW(), $
    oWindow : OBJ_NEW(), $
    oImage  : OBJ_NEW(), $
    oRect   : OBJ_NEW(), $
    DrawID: 0L $
    }
END
PRO ImgProcess_event,ev
  Widget_Control,ev.top,Get_UValue = pState
  case Widget_info(ev.id,/uName) of
  'smooth':(*pState).oFile.process,type ='Smooth'
  'edge':(*pState).oFile.process,type ='CANNY'
  else:
  endcase
end
PRO ImgProcess
  ;
  wTlb = WIDGET_BASE(mbar = mbar)
  wFile = Widget_Button(mBar,value= '�ļ�',/menu)
  wProcess = Widget_Button(mBar,value= 'ͼ����',/menu)
  wSmooth = Widget_Button(wProcess,value= 'ƽ��',uname ='smooth')
  wSmooth = Widget_Button(wProcess,value= '��Ե���',uname ='edge')
  wDraw = WIDGET_DRAW(wtlb,$
    xSize = 800,$
    ySize = 600, $
    retain=0,$
    graphics_level = 2)
  WIDGET_CONTROL, wTlb,/real  
  oFile = OBJ_NEW('ImgSHow', $
    wDraw)
    Widget_Control,wTlb,Set_UValue = Ptr_New({oFile:oFile},/no_copy)
  xManager,  'ImgProcess',wTlb,/no_block    
END





