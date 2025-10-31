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

PRO MEDIA_PLAYER_EVENT,event
  COMPILE_OPT idl2
  ;�ؼ�������¼�
  WIDGET_CONTROL,event.TOP,GET_UVALUE=pState
  
  ;ʵʱ����鿴�ؼ����¼���
  IF event.EVENT_NAME NE '' THEN PRINT,'Media Player ActiveX Event Registered : "'+event.EVENT_NAME+'"'
  ;
  IF STRUPCASE(event.EVENT_NAME) EQ 'MEDIACHANGE' THEN BEGIN
    ;�����Ϣ
    event.ITEM->GETPROPERTY,imageSourceWidth=nCols,imageSourceHeight=nRows,durationString=length
    ;�޸ĳߴ��СΪ�ļ���С
    IF nCols NE 0 AND nRows NE 0 THEN WIDGET_CONTROL,(*pState).WMP,SCR_XSIZE=nCols,SCR_YSIZE=nRows+64
    IF length NE '00:00' THEN BEGIN
      IF STRLEN(length) EQ 5 THEN length='00:'+length
      WIDGET_CONTROL,(*pState).DURATIONTEXT,SET_VALUE=length
    ENDIF
  ENDIF
  ;
  IF STRUPCASE(event.EVENT_NAME) EQ 'PLAYSTATECHANGE' THEN BEGIN
    CASE event.NEWSTATE OF
      1 : BEGIN
        ;���ð�ť״̬
        WIDGET_CONTROL,(*pState).STOPBUT,SENSITIVE=0
        WIDGET_CONTROL,(*pState).PLAYBUT,SENSITIVE=1
        WIDGET_CONTROL,(*pState).PAUSBUT,SENSITIVE=0
      END
      2 : BEGIN
        ;���ð�ť״̬
        WIDGET_CONTROL,(*pState).STOPBUT,SENSITIVE=1
        WIDGET_CONTROL,(*pState).PLAYBUT,SENSITIVE=1
        WIDGET_CONTROL,(*pState).PAUSBUT,SENSITIVE=0
      END
      3 : BEGIN
        ;���ð�ť״̬
        WIDGET_CONTROL,(*pState).STOPBUT,SENSITIVE=1
        WIDGET_CONTROL,(*pState).PLAYBUT,SENSITIVE=0
        WIDGET_CONTROL,(*pState).PAUSBUT,SENSITIVE=1
      END
      ELSE:
    ENDCASE
  ENDIF
  HEAP_FREE,event
END

;------------------------------------------------------------------------------------
PRO USING_ACTIVEX_CLEANUP,widgetID
  COMPILE_OPT idl2
  ;���ٶ���
  WIDGET_CONTROL,widgetID,GET_UVALUE=pState
  ;
  IF PTR_VALID(pState) THEN BEGIN
    ;
    OBJ_DESTROY,(*pState).OCONTROLS
    OBJ_DESTROY,(*pState).OSETTINGS
    OBJ_DESTROY,(*pState).OPLAYER
    PTR_FREE,TEMPORARY(pState)
  ENDIF
END

;------------------------------------------------------------------------------------
PRO USING_ACTIVEX_EVENT,event
  COMPILE_OPT idl2
  
  WIDGET_CONTROL,event.TOP,GET_UVALUE=pState
  
  (*pState).OSETTINGS->GETPROPERTY,MUTE=mute,VOLUME=volume
  
  IF SIZE(mute,/TYPE) EQ 1 THEN BEGIN
    IF mute NE (*pState).MUTEFLAG THEN BEGIN
      IF mute EQ 0 THEN WIDGET_CONTROL,(*pState).MUTEBUT,SET_VALUE='���� )))'
      IF mute EQ 1 THEN WIDGET_CONTROL,(*pState).MUTEBUT,SET_VALUE='����    '
      (*pState).MUTEFLAG=mute
    ENDIF
  ENDIF
  WIDGET_CONTROL,(*pState).VOLSLIDER,GET_VALUE=currVolValue
  IF volume NE currVolValue THEN WIDGET_CONTROL,(*pState).VOLSLIDER,SET_VALUE=volume
  ;
  uName = WIDGET_INFO(event.ID,/uName)
  
  CASE uName OF
    ;��
    'open': BEGIN
      file=DIALOG_PICKFILE(title='ѡ��ý���ļ�',$
        filter=['*.ASF','*.AVI','*.CDA',$
        '*.MP2','*.MP3','*.MPA','*.MPE','*.MPEG','*.MPG','*.WAV','*.WM','*.WMA','*.WMV'],$
        get_path=path)
      ;
      IF file EQ '' THEN RETURN
      (*pState).OPLAYER->SETPROPERTY,URL=file
      WIDGET_CONTROL,(*pState).FILETEXT,SET_VALUE=file
      ;���ð�ť״̬
      WIDGET_CONTROL,(*pState).CONTROLSBASE,SENSITIVE=1
      WIDGET_CONTROL,(*pState).STOPBUT,SENSITIVE=1
      WIDGET_CONTROL,(*pState).PLAYBUT,SENSITIVE=0
      WIDGET_CONTROL,(*pState).PAUSBUT,SENSITIVE=1
      (*pState).OCONTROLS->PLAY
    END
    ;����
    'play': BEGIN
      (*pState).OCONTROLS->PLAY
      ;���ð�ť״̬
      WIDGET_CONTROL,(*pState).STOPBUT,SENSITIVE=1
      WIDGET_CONTROL,(*pState).PLAYBUT,SENSITIVE=0
      WIDGET_CONTROL,(*pState).PAUSBUT,SENSITIVE=1
    END
    ;��ͣ
    'pause': BEGIN
      (*pState).OCONTROLS->PAUSE
      ;���ð�ť״̬
      WIDGET_CONTROL,(*pState).STOPBUT,SENSITIVE=1
      WIDGET_CONTROL,(*pState).PLAYBUT,SENSITIVE=1
      WIDGET_CONTROL,(*pState).PAUSBUT,SENSITIVE=0
    END
    ;ֹͣ
    'stop': BEGIN
      (*pState).OCONTROLS->STOP
      ;���ð�ť״̬
      WIDGET_CONTROL,(*pState).STOPBUT,SENSITIVE=0
      WIDGET_CONTROL,(*pState).PLAYBUT,SENSITIVE=1
      WIDGET_CONTROL,(*pState).PAUSBUT,SENSITIVE=0
    END
    ;����
    'mute': BEGIN
      IF (*pState).MUTEFLAG EQ 0 THEN BEGIN
        WIDGET_CONTROL,(*pState).MUTEBUT,SET_VALUE='����'
        ;���ð�ť״̬
        (*pState).OSETTINGS->SETPROPERTY,MUTE=1B
        (*pState).MUTEFLAG=1B
      ENDIF ELSE BEGIN
        WIDGET_CONTROL,(*pState).MUTEBUT,SET_VALUE='����'
        ;
        (*pState).OSETTINGS->SETPROPERTY,MUTE=0B
        (*pState).MUTEFLAG=0B
      ENDELSE
    END
    ;����
    'vol': BEGIN
      (*pState).OSETTINGS->SETPROPERTY,VOLUME=event.VALUE
      WIDGET_CONTROL,(*pState).VOLSLIDER,SET_VALUE=event.VALUE
    END
    ;����
    'balance': BEGIN
      (*pState).OSETTINGS->SETPROPERTY,BALANCE=event.VALUE
    END
    'about': BEGIN
      msg = DIALOG_MESSAGE('ϵͳ�������İ汾�ǣ�'+(*pState).VERSION+STRING(13B)+ $
        'Author: DYQ ' +STRING(13B)+  $
        'E-mail: sdlcdyq@sina.com',/INFORMATION)
    END
    'exit': BEGIN
      ;
      WIDGET_CONTROL, event.TOP,/Destroy
    END
    ELSE: PRINT,uName
  ENDCASE
  
END
;------------------------------------------------------------------------------------
;+
; NAME:
;       MEDIA_PLAYER_9_ACTIVEX
;
; PURPOSE:
;       The purpose of this program is to provide an example of the ability
;       to embed an ActiveX control for the Windows Media Player into an
;       IDL program using COM technology.
;
; CATEGORY:
;       COM, ActiveX, Visualization, Widgets
;
; CALLING SEQUENCE:
;       MEDIA_PLAYER_9_ACTIVEX
;
; INPUT PARAMETERS:
;       None.
;
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;       None.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       This program will change the current working directory if a file is
;       opened or created.
;
; RESTRICTIONS:
;       This program is supported in IDL version 5.6 and newer on Windows-NT
;       platforms only.  The Windows Media Player 9 Series must be installed
;       on the computer before this program will work properly.
;
; DISCLAIMER:
;       This procedure is provided "as is" and is not supported or maintained
;       by Research Systems, Inc..
;
; MODIFICATION HISTORY:
;       Written by: AEB, 9/02.
;
; Modified BY Dongyq 2011��3��
;     E-Mail: sdlcdyq@sina.com
;
;-
PRO USING_ACTIVEX
  COMPILE_OPT idl2
  ;���洴��
  tlb=WIDGET_BASE(TITLE='IDL Using Windows Media Player ActiveX',$
    /ROW,$
    MBAR=menuBar, $
    tlb_Frame_attr = 1)
  fileMenu=WIDGET_BUTTON(menuBar,VALUE='�ļ�',/MENU)
  fileBttn1=WIDGET_BUTTON(fileMenu,VALUE='��',uName = 'open')
  fileBttn2=WIDGET_BUTTON(fileMenu,VALUE='�˳�',uName = 'exit')
  helpMenu=WIDGET_BUTTON(menuBar,VALUE='����',/MENU)
  helpBttn1=WIDGET_BUTTON(helpMenu,VALUE='����',uName = 'about')
  idlBase=WIDGET_BASE(tlb,/FRAME,/COLUMN,/ALIGN_CENTER)
  wmpBase=WIDGET_BASE(tlb,/FRAME,/COLUMN,/ALIGN_CENTER)
  wmpLabel=WIDGET_LABEL(wmpBase,VALUE='WINDOWS MEDIA PLAYER')
  ;ActiveX-init ;���Ʋ���
  fileBase=WIDGET_BASE(idlBase,/ROW)
  fileLabel=WIDGET_LABEL(fileBase,VALUE='�ļ���')
  fileText=WIDGET_TEXT(fileBase,XSIZE=30,YSIZE=1)
  fileOpen = WIDGET_BUTTON(filebase, value='��',uname = 'open')
  ;
  durationBase=WIDGET_BASE(idlBase,/ROW,/ALIGN_CENTER)
  durationLabel=WIDGET_LABEL(durationBase,VALUE='ʱ�� (HH:MM:SS) = ')
  durationText=WIDGET_TEXT(durationBase,XSIZE=8,YSIZE=1)
  settingsBase=WIDGET_BASE(idlBase,/FRAME,/ROW,/ALIGN_CENTER)
  volBase=WIDGET_BASE(settingsBase,/ROW,/ALIGN_CENTER,/FRAME)
  volLabel=WIDGET_LABEL(volBase,VALUE='����')
  volSliderBase=WIDGET_BASE(volBase,/COLUMN,/ALIGN_CENTER)
  volMaxLabel=WIDGET_LABEL(volSliderBase,VALUE='MAX')
  volSlider=WIDGET_SLIDER(volSliderBase, $
    MINIMUM=0,MAXIMUM=100,/VERTICAL,$
    /SUPPRESS_VALUE,$
    uName = 'vol')
    
  volMinLabel=WIDGET_LABEL(volSliderBase,VALUE='MIN')
  spacer=WIDGET_LABEL(volBase,VALUE=' ')
  balBase=WIDGET_BASE(settingsBase,/COLUMN,/ALIGN_CENTER,/FRAME)
  balLabel=WIDGET_LABEL(balBase,VALUE='����')
  balSliderBase=WIDGET_BASE(balBase,/ROW,/ALIGN_CENTER)
  balLeftLabel=WIDGET_LABEL(balSliderBase,VALUE='L ')
  balSlider=WIDGET_SLIDER(balSliderBase,MINIMUM=-100,MAXIMUM=100,$
    /SUPPRESS_VALUE,$
    uName ='balance')
  balRightLabel=WIDGET_LABEL(balSliderBase,VALUE=' R')
  spacer=WIDGET_LABEL(balBase,VALUE=' ')
  
  cBase=WIDGET_BASE(idlBase,/FRAME,/COLUMN,/ALIGN_CENTER)
  wmpLabel=WIDGET_LABEL(cBase,VALUE='IDL���Ʋ���')
  
  controlsBase=WIDGET_BASE(cBase,/ROW,SENSITIVE=0,/ALIGN_CENTER)
  stopBut=WIDGET_BUTTON(controlsBase,VALUE='�� ֹͣ', $
    uname = 'stop',/FRAME,SENSITIVE=0)
  playBut=WIDGET_BUTTON(controlsBase,VALUE='>> ����', $
    uName = 'play',/FRAME)
  pausBut=WIDGET_BUTTON(controlsBase,VALUE='|| ��ͣ', $
    uName = 'pause', /FRAME,SENSITIVE=0)
    
  muteBut=WIDGET_BUTTON(controlsBase,VALUE='���� )))', $
    uName = 'mute',/FRAME)
  ;
  WIDGET_CONTROL,tlb,/REALIZE
  ;Init �ؼ�
  wmp=WIDGET_ACTIVEX(wmpBase,'{6BF52A52-394A-11D3-B153-00C04F79FAA6}',$
    SCR_XSIZE=600,SCR_YSIZE=598,$
    EVENT_PRO='media_player_event')
  ;
  WIDGET_CONTROL,wmp,GET_VALUE=oPlayer
  
  ;��ÿؼ�������
  oPlayer->GETPROPERTY,CONTROLS=oControls,SETTINGS=oSettings,VERSIONINFO=version
  oSettings->GETPROPERTY,VOLUME=volume,BALANCE=balance
  
  WIDGET_CONTROL,volSlider,SET_VALUE=volume
  WIDGET_CONTROL,balSlider,SET_VALUE=balance
  ;��ʼ��:
  WIDGET_CONTROL,tlb,TIMER=0.5
  ;�����ṹ��
  pState=PTR_NEW({oPlayer:oPlayer, $
    oControls:oControls, $
    oSettings:oSettings,$
    version:STRTRIM(version,2),$
    tlb:tlb, $
    wmp:wmp, $
    volSlider:volSlider,$
    controlsBase:controlsBase, $
    muteFlag:0B, $
    muteBut:muteBut, $
    durationText:durationText,$
    stopBut:stopBut, $
    playBut:playBut, $
    pausBut:pausBut, $
    fileText:fileText} )
    
  WIDGET_CONTROL,tlb,SET_UVALUE=pState
  ;��ȡ��ǰ��������Ŀ¼
  current_path = FILE_DIRNAME(ROUTINE_FILEPATH("USING_ACTIVEX"))
  
  ;Ĭ�ϲ����ļ�
  IF FILE_TEST(current_path+'\clock.avi') THEN BEGIN
  
    oPlayer->SETPROPERTY,URL=current_path+'\clock.avi'
    WIDGET_CONTROL,fileText,SET_VALUE=current_path+'\clock.avi'
    ;���ð�ť״̬
    WIDGET_CONTROL,controlsBase,SENSITIVE=1
    WIDGET_CONTROL,stopBut,SENSITIVE=1
    WIDGET_CONTROL,playBut,SENSITIVE=0
    WIDGET_CONTROL,pausBut,SENSITIVE=1
    oControls->PLAY
  ENDIF
  XMANAGER,'Using_ActiveX',tlb,CLEANUP='Using_ActiveX_cleanup'
  
END