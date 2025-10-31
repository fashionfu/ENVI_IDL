;+
;         ��IDL������ơ�
; --���ݿ��ٿ��ӻ���ENVI���ο��������̣�
;
; ʾ��Դ����
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;
;-
;
;test image_save
;
;2007-11-3 Write By DYQ
;
;___________________________Event__________________________________
;
PRO TEST_IMAGESAVE_EVENT,ev

  COMPILE_OPT StrictArr
  
  ;Copy From HuXZ ,learning... ^_^
  CATCH, ErrorNumber
  IF (ErrorNumber NE 0) THEN BEGIN
    CATCH, /Cancel
    HELP, /Last_Message, Output = LastError
    v = DIALOG_MESSAGE(LastError)
    RETURN
  ENDIF
  ;Copy From HuXZ ,learning... ^_^
  
  WIDGET_CONTROL, ev.ID, Get_UValue = UValue
  WIDGET_CONTROL, ev.TOP, Get_uValue = pState
  
  CASE UVALUE OF
    'save':   IF ev.SELECT EQ 2 THEN tmp = IMAGE_SAVE((*pState).OVIEW)
    'cancel': IF ev.SELECT EQ 2 THEN BEGIN
      ;Obj_Destroy,[(*pState).oView,(*pState).oModel]
      PTR_FREE,pState
      WIDGET_CONTROL,ev.TOP,/Destroy
      
    ENDIF
  ELSE :
ENDCASE
END
;
;___________________________Main___________________________________
;
PRO TEST_IMAGESAVE

  COMPILE_OPT StrictArr
  ON_ERROR, 2
  
  CD, Current = rootDir
  
  ;Create The Base
  IF FLOAT(!VERSION.RELEASE) GE 6.4 THEN $
    tlb = WIDGET_BASE(Title = '���Դ洢ͼ�� '       , $
    bitmap = RootDir+               $
    '\Resource\system\system.bmp' , $
    Map = 0,  /Column            ) $
  ELSE $
    tlb = WIDGET_BASE(Title = '���Դ洢ͼ�� '       , $
    Map = 0,  /Column           )
    
  dB = WIDGET_BASE(TLB, /col,/Frame)
  draw = WIDGET_DRAW(db, Graphics_Level = 2       , $
    XSize = 400                 , $
    YSize = 400                 , $
    Retain = 2              )
  cB = WIDGET_BASE(TLB, /Row,/Align_Center )
  
  imageFiles = rootDir+['\resource\button\save.png', $
    '\resource\button\cancel.png']
  uValue = ['save','cancel']
  toolTips = ['����Ϊͼ��','�ر�������']
  FOR i=0, N_ELEMENTS(imageFiles)-1 DO BEGIN
    img = Read_Png(imageFiles[i])
    NiceButton = CW_NICEBUTTON(cB              , $ ; �ϼ�Base
      BarImage = img             , $
      UValue = uValue[i]         , $ ; ������������ʶ���
      Timer = .1                 , $  �����ٶ�
    ToolTip = toolTips[i]      , $
      Status_Normal = 1          , $ ; ��ͨ״̬����ʾ����
      TypeStyle = 2              , $ ; ����ʾͼƬ
      GroudStyle = 13            $ ; ˮ���̱���
      ) ;
  ENDFOR
  
  WIDGET_CONTROL, tlb, /Realize
  WIDGET_CONTROL, Draw, Get_Value = oWindow
  
  ; Create a view.
  oView = OBJ_NEW('IDLgrView'                 , $
    color=[60,60,60]            , $
    Dimension = [400,400]       , $
    
    VIEWPLANE_RECT=[-1,-1,2,2])
    
  ; Create a model.
  oModel = OBJ_NEW('IDLgrModel' )
  oView->ADD, oModel
  
  ; Create objects
  MESH_OBJ, 3, verts, verts_conn              , $
    REPLICATE(0.25, 48, 64), P4=0.5
  oCylinder = OBJ_NEW('IDLgrPolygon'          , $
    Data = verts           , $
    Color = [200,200,0]    , $
    Polygons =verts_conn  )
  MESH_OBJ, 6, verts, verts_conn              , $
    [[0.75,0.0,0.25],[0.5,0.0,0.75]], $
    P1=16, P2=[0.5, 0.0, 0.0]
  oCone = OBJ_NEW('IDLgrPolygon'              , $
    Data = verts               , $
    Color = [200,0,0]          , $
    Polygons =verts_conn )
    
  ; Add the objects to the model.
  oModel->ADD, [oCylinder,oCone]
  
  ; Rotate model to standard view.
  oModel->ROTATE,[1,0,0], -90
  oModel->ROTATE,[0,1,0], 30
  oModel->ROTATE,[1,0,0], 30
  
  ; Draw the view.
  oWindow->DRAW, oView
  
  ; Center The Widget -Copy From HuXZ,^_^
  ScreenSize = GET_SCREEN_SIZE()
  Geom = WIDGET_INFO(TLB, /Geometry)
  WIDGET_CONTROL, TLB, XOffset = (ScreenSize[0] - Geom.SCR_XSIZE)/2., $
    YOffset = (ScreenSize[1] - Geom.SCR_YSIZE)/2.
  ;
  state = {oView: oView ,oModel:oModel}
  pState = PTR_NEW(state)
  WIDGET_CONTROL, tlb,Set_uValue = pState, Map =1
  
  XMANAGER, 'Test_ImageSave', TLB, /No_Block
END



