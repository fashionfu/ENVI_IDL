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
;�աաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաա�
;
;�¼�����
;
PRO AdTool::HandleEvent, event

  COMPILE_OPT IDL2
  
  oSystem = self.OSYSTEM
  oManager = oSystem.OMANAGER
  
  uName = WIDGET_INFO(event.ID, /UName)
  
  CASE uName OF
    'AdTool::suitSCR' : BEGIN
      oManager->CONFIGVIEWRANGE
      oManager->REFRESHDRAW
      (oManager.ODRAW).OWINDOW->DRAW
    END
    'AdTool::suitImg' : BEGIN
      oManager->CONFIGVIEWRANGE,/Image
      oManager->REFRESHDRAW
      (oManager.ODRAW).OWINDOW->DRAW
    END
    ;����ͼ����ʾ
    'AdTool::image' : BEGIN
      filters = [['*.jpg;*.jpeg', '*.tif;*.tiff', '*.png', '*.*'], $
      ['JPEG', 'TIFF', 'Bitmap', 'All files']]
      
      file = DIALOG_PICKFILE(filter =filters,$
        path =oSystem.ROOTDIR )
      IF file EQ '' THEN RETURN;
      item = oManager->GET(/All   , $
        ISA = 'ADIMAGELAYER')
      item->SHOWIMAGE, fileName = file
      oManager.MOUSESTATUS = 'hand'
    END
    'AdTool::point' : BEGIN
      oManager.MOUSESTATUS = 'annotate'
      oManager.ANNOTATESTATUS[0] = 'point'
    END
    
    'AdTool::save' : BEGIN
      currProject.OVIEW->GETPROPERTY, dimensions=oriDims,location=oriLoc
      temp = Image_Save(currProject.OVIEW);����oview
      currProject.OVIEW->SETPROPERTY, dimensions=oriDims, location=oriLoc
    END
    
    ELSE:
  ENDCASE
END

;�աաաաաաաաաաաաաաաաաաաաաաաաաաաաաաա�-
;
;����������
;
PRO AdTool::Create

  COMPILE_OPT IDL2
  
  self.TBASE = WIDGET_BASE(self.PARENT    , $
    /Row                    , $
    /Base_Align_Center      , $
    Space = 0               , $
    XPad  = 0               , $
    YPad  = 0                )
    
  WIDGET_CONTROL, /Realize, self.TBASE
  
  bitmaps = (self.OSYSTEM).ROOTDIR+'\'+   $
    ['image.bmp','suitScr.bmp','suitImg.bmp','measure.bmp']
    
  uNames = 'AdTool::'+['image','suitSCR','suitImg','point']
  toolTips = ['����ͼ��','�ʺ���Ļ','�ʺ�ͼ��','���']
  
  FOR i=0, N_ELEMENTS(bitmaps)-1 DO BEGIN
    self.WBUTTONS[i] = WIDGET_BUTTON( $
      self.TBASE                  , $
      Value = bitmaps[i]          , $
      /Bitmap                     , $
      ToolTip = toolTips[i]       , $
      UName = uNames[i]             )
  ENDFOR
  
END

;�աաաաաաաաաաաաաաաաաաաաաաաաաաաաաաա�-
;
;����
;
PRO AdTool::CLEANUP

  COMPILE_OPT IDL2
  
END

;�աաաաաաաաաաաաաաաաաաաաաաաաաաաաաաա�-
;
;��ʼ��
;
FUNCTION AdTool::INIT, OSystem = oSystem, parent = parent

  COMPILE_OPT IDL2
  
  self.OSYSTEM = oSystem
  
  self.PARENT = parent;oSystem.tlb
  
  DEVICE, Get_Screen_Size = screenSize
  self.GEOM = [screenSize[0], 36]
  
  self.ROOTDIR = oSystem.ROOTDIR
  
  self->CREATE
  
  geom = WIDGET_INFO(self.TBASE, /Geometry)
  self.GEOM = [geom.SCR_XSIZE, geom.SCR_YSIZE]
  
  RETURN, 1
END

;�աաաաաաաաաաաաաաաաաաաաաաաաաաաաաաա�-
;
;����
;
PRO ADTOOL__DEFINE

  COMPILE_OPT IDL2
  
  void = {AdTool                       , $
    ;�̳еĸ���
  
    ;ϵͳ����
    parent          :  0              , $
    tBase          :   0           , $
    geom          :    [0, 0]          , $
    rootDir          : ''            , $
    wButtons            :   LONARR(10)          , $
    
    ;ϵͳ����
    oSystem          : OBJ_NEW()       $
    }
    
END