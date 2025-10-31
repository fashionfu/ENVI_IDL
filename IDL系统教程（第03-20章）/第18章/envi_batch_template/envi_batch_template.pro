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
PRO CenterTLB, tlb, x, y, NoCenter=nocenter

  Compile_Opt StrictArr

  geom = Widget_Info(tlb, /Geometry)

  IF N_Elements(x) EQ 0 THEN xc = 0.5 ELSE xc = Float(x[0])
  IF N_Elements(y) EQ 0 THEN yc = 0.5 ELSE yc = 1.0 - Float(y[0])
  center = 1 - Keyword_Set(nocenter)
  ;
  oMonInfo = OBJ_NEW('IDLsysMonitorInfo')
  rects = oMonInfo -> GetRectangles(Exclude_Taskbar=exclude_Taskbar)
  pmi = oMonInfo -> GetPrimaryMonitorIndex()
  OBJ_DESTROY, oMonInfo

  screenSize =rects[[2, 3], pmi]

  ; Get_Screen_Size()
  IF screenSize[0] GT 2000 THEN screenSize[0] = screenSize[0]/2 ; Dual monitors.
  xCenter = screenSize[0] * xc
  yCenter = screenSize[1] * yc

  xHalfSize = geom.Scr_XSize / 2 * center
  yHalfSize = geom.Scr_YSize / 2 * center

  XOffset = 0 > (xCenter - xHalfSize) < (screenSize[0] - geom.Scr_Xsize)
  YOffset = 0 > (yCenter - yHalfSize) < (screenSize[1] - geom.Scr_Ysize)

  Widget_Control, tlb, XOffset=XOffset, YOffset=YOffset
END

;+
;:Description:
;   ENVI���ο�����������ģ��
;   Ĭ��Ϊ���ݸ�ʽת��Ϊtiff��ʽ
; 
; Author: DYQ
;-
;��������
PRO ENVI_BATCH_TEMPLATE_CLEANUP,tlb
  WIDGET_CONTROL,tlb,get_UValue = pState
  PTR_FREE,pState
END
;�¼���Ӧ����
PRO ENVI_BATCH_TEMPLATE_EVENT,event
  COMPILE_OPT idl2
  WIDGET_CONTROL,event.TOP, get_UValue = pState
  
  ;�ر��¼�
  IF TAG_NAMES(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
    ;
    status = DIALOG_MESSAGE('�ر�?',/Question)
    IF status EQ 'No' THEN RETURN
    ;����ָ��
    ; PTR_FREE, pState
    WIDGET_CONTROL, event.TOP,/Destroy
    RETURN;
  ENDIF
  ;����ϵͳ��uname�����жϵ�������
  uName = WIDGET_INFO(event.ID,/uName)
  ;
  CASE uname OF
    ;���ļ�
    'open': BEGIN
      files = DIALOG_PICKFILE(/MULTIPLE_FILES, $
        title = !SYS_Title+' ���ļ�', $
        path = (*pState).ORIROOT)
      IF N_ELEMENTS(files) EQ 0 THEN RETURN
      ;������ʾ�ļ�
      WIDGET_CONTROL, (*pState).WLIST, set_value = files
      (*pState).INPUTFILES = PTR_NEW(files)
      (*pState).ORIROOT = FILE_DIRNAME(files[0])
      ;���ý���������
      IDLITWDPROGRESSBAR_SETVALUE,(*pState).PRSBAR,0
      
    END
    ;�˳�
    'exit': BEGIN
      status = DIALOG_MESSAGE('�ر�?',$
        title = !SYS_Title, $
        /Question)
      IF status EQ 'No' THEN RETURN
      WIDGET_CONTROL, event.TOP,/Destroy
    END
    ;����
    'about': BEGIN
      void = DIALOG_MESSAGE(!SYS_Title+' V1.0'+STRING(13b)+'��ӭʹ�ã�����������ȥbbs.esrichina-bj.cn��' ,/information)
    END
    ;
    ;·��ѡ��ť
    'filepathsele': BEGIN
      WIDGET_CONTROL, event.ID,get_value = value
      WIDGET_CONTROL,(*pState).WSELE, Sensitive= value
      WIDGET_CONTROL,(*pState).OUTPATH, Sensitive= value
    END
    ;ѡ�����·��
    'selePath' : BEGIN
      outroot = DIALOG_PICKFILE(/dire,title = !SYS_Title)
      WIDGET_CONTROL,(*pState).OUTPATH,set_value = outRoot
    END
    
    ;����ִ��
    'execute': BEGIN
      ;��ȡѡ��ķ���
      WIDGET_CONTROL,(*pState).BGROUP, get_Value = mValue
      IF PTR_VALID((*pState).INPUTFILES) EQ 0 THEN RETURN
      ;��ʼ��ENVI
      ENVI, /restore_base_save_files
      ENVI_BATCH_INIT,/NO_Status_Window
      
      ;��ȡ�ļ���
      files = *((*pState).INPUTFILES)
      per = 100./N_ELEMENTS(files)
      ;�ж��Ƿ���Ҫѡ��·��
      IF mValue NE 0 THEN BEGIN
        ;��������ļ���
        WIDGET_CONTROL, (*pState).OUTPATH,get_value= outfiledir
        IF (outfiledir[0] EQ ' ') THEN  outfiledir = DIALOG_PICKFILE(/dire, title =!SYS_Title+' ���·��')
      ENDIF  ELSE outfiledir = FILE_DIRNAME(files[0])
      
      FOR i=0,N_ELEMENTS(files)-1 DO BEGIN
        ;��������ļ���
        fileName = FILE_BASENAME(files[i])
        pointPos = STRPOS(fileName,'.')
        ;�����ļ����е��λ��
        IF pointPos[0] NE -1 THEN BEGIN
          fileName= STRMID(fileName,0,pointPos)
        ENDIF
        out_name = outfiledir+PATH_SEP()+fileName+'.tiff'
        
        ENVI_OPEN_FILE, files[i], r_fid=fid
        IF (fid EQ -1) THEN BEGIN
          tmp = DIALOG_MESSAGE(files[i]+'�ļ���ȡ����',$
            title = !sys_title, /error)
          CONTINUE
        ENDIF
        ;�ļ���Ϣ
        ENVI_FILE_QUERY, fid, dims=dims, nb=nb,bnames = bnames
        ;����tiff�ļ��������
        ;�������С��3��
        IF nb LE 3 THEN bandList = INDGEN(nb)ELSE $
          bandList = [3,2,1]
        ;����ENVI���ܺ����������
        ENVI_OUTPUT_TO_EXTERNAL_FORMAT,fid = fid,dims = dims, out_name=out_name,pos = bandList, $
          out_bname=bnames[bandlist],/TIFF
        ;������
        ENVI_FILE_MNG, id=fid, /remove
        ;���ý�����
        IDLITWDPROGRESSBAR_SETVALUE,(*pState).PRSBAR,(i+1)*per
      ENDFOR
      void = DIALOG_MESSAGE('������� ',title = !sys_title,/infor)
      ;�ر�ENVI���ο���ģʽ
      ENVI_BATCH_EXIT
    END
    ELSE:
  ENDCASE
END
;
;--------------------------
;ENVI���ο���������ģ��
PRO ENVI_BATCH_TEMPLATE
compile_opt idl2
  ;
  COMPILE_OPT idl2
  ;��ʼ�������С
  sz = [600,400]
  ;����ϵͳ�������ɷ����޸�ϵͳ����
  DEFSYSV,'!SYS_Title','ENVI������ģ��'
  ;��������Ĵ���
  tlb = WIDGET_BASE(MBAR= mBar, $
    /COLUMN , $
    title = !SYS_Title, $
    /Tlb_Kill_Request_Events, $
    tlb_frame_attr = 1, $
    Map = 0)
  ;�����˵�
  fMenu = WIDGET_BUTTON(mBar, value ='�ļ�',/Menu)
  wButton = WIDGET_BUTTON(fMenu,value ='�������ļ�', $
    uName = 'open')
  fExit = WIDGET_BUTTON(fMenu, value = '�˳�', $
    uName = 'exit',/Sep)
  eMenu = WIDGET_BUTTON(mBar,value ='����',/Menu)
  wButton = WIDGET_BUTTON(eMenu,$
    value ='����������', $
    uName = 'execute')
  hMenu =  WIDGET_BUTTON(mBar, value ='����',/Menu)
  hHelp = WIDGET_BUTTON(hmenu, value = '����', $
    uName = 'about',/Sep)
  ;���������base
  wInputBase = WIDGET_BASE(tlb, $
    xSize =sz[0], $
    /Frame, $
    /Align_Center,$
    /Column)
    
    
  wLabel= WIDGET_LABEL(wInputBase, $
    value ='�ļ��б�')
  wList = WIDGET_LIST(wInputBase, $
    YSize = sz[1]/(2*15),$
    XSize = sz[0]/8)
    
  ;���·������
  wLabel= WIDGET_LABEL(tlb, $
    value ='�����������')
    
  ;����������ƽ���
  wSetBase = WIDGET_BASE(tlb, $
    xSize =sz[0], $
    /Row)
  values = ['Դ�ļ�·��', $
    '��ѡ��·��']
  bgroup = CW_BGROUP(wSetBase, values, $
    /ROW, /EXCLUSIVE, $
    /No_Release, $
    SET_VALUE=1, $
    uName = 'filepathsele', $
    /FRAME)
  outPath = WIDGET_TEXT(wSetBase, $
    value =' ', $
    xSize =30, $
    /Editable, $
    uName = 'outroot')
  wSele = WIDGET_BUTTON(wSetBase, $
    value ='ѡ��·��', $
    uName ='selePath')
  ;
  ;ִ�а�ťbase
  wExecuteBase = WIDGET_BASE(tlb,$
    /align_center,$
    /row)
  wButton = WIDGET_BUTTON(wExecuteBase, $
    ysize =40,$
    value ='�������ļ�', $
    uName = 'open')    
  wButton = WIDGET_BUTTON(wExecuteBase,$
    value ='����������', $    
    uName = 'execute')
  ;״̬��������ʾ������
  wStatus = WIDGET_BASE(tlb,/align_right)
  prsbar = IDLITWDPROGRESSBAR( wExecuteBase ,$
    title ='����', $
    CANCEL =0)
  ;�ṹ�崫�ݲ���
  state = {wButton:wButton, $
    tlb : tlb, $
    oriRoot: '', $
    outPath: outPath, $
    wSele : wSele, $
    bgroup : bgroup , $
    inputFiles : PTR_NEW(), $
    prsbar : prsbar , $
    wList : WLIST }
    
  pState = PTR_NEW(state,/no_copy)
  ;�����������
  CENTERTLB,tlb
  ;
  WIDGET_CONTROL, tlb,/Realize,/map,set_uValue = pState
  XMANAGER,'ENVI_Batch_Template',tlb,/No_Block,$
    cleanup ='ENVI_Batch_Template_Cleanup'
END
