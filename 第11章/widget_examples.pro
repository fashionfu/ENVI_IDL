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
;����ر���Ӧ����
PRO WIDGET_EXAMPLES_CLEANUP, tlb
  ;��ȡuValue
  WIDGET_CONTROL,tlb,get_uvalue=pstate
  ;����ָ�룬����Ҫ����
  PTR_FREE, pState
END
;�����¼���Ӧ����
PRO  WIDGET_EXAMPLES_EVENT, event

  ;��ö�base��uvalue���������Ϣָ��ṹ��
  WIDGET_CONTROL,event.TOP,get_uvalue=pstate
  
  CASE TAG_NAMES(event,/STRUCTURE_NAME) OF
    ;�ر��¼�
    'WIDGET_KILL_REQUEST': BEGIN
      ;��ʾ�Ƿ�ر�
      tmp = DIALOG_MESSAGE('ȷ�Ϲرգ�',$
        title ='�ر�ϵͳ',/question)
      IF tmp EQ 'Yes' THEN BEGIN
        ;ע������֮ǰ������ָ��
        WIDGET_CONTROL,event.TOP,get_uValue = pState
        PTR_FREE, pState
        ;���ٽ���
        WIDGET_CONTROL,event.TOP,/destroy
        RETURN
      ENDIF
      RETURN
    END
    ;draw����
    'WIDGET_DRAW': BEGIN
    
      CASE event.TYPE OF
        ;ע�ⲻͬ�����Ͷ�Ӧ�Ĳ�ͬ���¼�
        ;���̺����ȸ����¼��Ľṹ������
        0: BEGIN
          CASE event.PRESS OF
            1: value = '�������'
            2: value = '�м�����'
            4: BEGIN
              value = '�Ҽ�����'
              ;�����Ҽ��˵�
              WIDGET_DISPLAYCONTEXTMENU, event.ID, event.X, $
                event.Y, (*pState).CONTEXTBASE  
            END
            ELSE: PRINT,event.PRESS
          ENDCASE
        END
        1: BEGIN
          CASE event.RELEASE OF
            1: value = '����ͷ�'
            2: value = '�м��ͷ�'
            4: value = '�Ҽ��ͷ�'
            ELSE: PRINT,event.RELEASE
          ENDCASE
        END
        2: value = '����ƶ�'
        7: BEGIN
          IF event.CLICKS GT 0 THEN value='����ǰ��' $
          ELSE value='���ֺ��'
        END
        4:  BEGIN
          value = '��¶�¼�'
          ;������ʾ����Ĵ�С
          drawSize  = WIDGET_INFO((*pState).MYDRAW,/Geom)
          ;��Ӧ����ʾ
          TVSCL,CONGRID(DIST(400),drawSize.XSIZE,drawSize.YSIZE)
        END
        5: value = 'key = ' +STRTRIM(STRING(event.CH),2)
        6: value = 'key = ' +STRTRIM(STRING(event.CH),2)
        ELSE:PRINT,event.TYPE
      ENDCASE
      ;
      WIDGET_CONTROL,(*pstate).TEXT1,set_value= value
    END
    ELSE:
  ENDCASE
  
  ;��ȡ��ǰ�����uName
  uName = WIDGET_INFO(event.ID,/uname)
  ;����˽����ϰ�ť
  IF uName EQ 'button' THEN BEGIN
    tmp = DIALOG_MESSAGE((*pState).TESTSTR,/Infor)
  ENDIF
  ;������Ҽ��˵��еİ�ť
  IF uName EQ 'contexButton1' THEN tmp = DIALOG_MESSAGE('�Ҽ��˵�1',/infor)
  IF uName EQ 'contexButton2' THEN tmp = DIALOG_MESSAGE('�Ҽ��˵�2',/infor)
  ;�޸Ľ����С
  IF uName EQ 'tlb' THEN BEGIN
    ;��ʾ�����С��Ӧ�����С
    drawXSize = event.X -(*pState).DRAWSPACE[0]
    drawYSize = event.Y -(*pState).DRAWSPACE[1]
    ;����tlb��С(�ɺ��ԣ���Draw��������Ѿ������˴�С)
    WIDGET_CONTROL,event.TOP,xSize = event.X,ySize = event.Y
    ;������ʾ����Ĵ�С
    WIDGET_CONTROL,(*pState).MYDRAW,xsize = drawXSize, ySize = drawYSize
    ;��Ӧ����ʾ
    TVSCL,CONGRID(DIST(400),drawXSize,drawYSize)
  ENDIF
END
;
PRO WIDGET_EXAMPLES

  ; ����һ����Base����
  base1 = WIDGET_BASE(TITLE='�������ʾ��', $
    mBar = mBar , $
    uname ='tlb', $
    ;��������
    /COLUMN, $
    
    ;�����ô�Сʱ�����¼�
    /TLB_SIZE_EVENTS,$
    ;�ر�ʱ�����¼�
    /TLB_KILL_REQUEST_EVENTS)
  ;����ϵͳ�˵�
  wFile = WIDGET_BUTTON(mbar,value = '�ļ�(&F)')
  wOpen = WIDGET_BUTTON(wFile, value = '��(&O)')
  wExit  = WIDGET_BUTTON(wFile, value = '�˳�(&E)', $
    ;��ӷָ���
    /Separator)
  ;����һ����ť
  base2=WIDGET_BASE(base1,/row)
  label1=WIDGET_LABEL(base2,$
    value='��ǰ�¼���')
  text1=WIDGET_TEXT(base2, $
    xSize =10)
  button = WIDGET_BUTTON(base2,$
    value ='��ť', $
    uName ='button')
  mydraw=WIDGET_DRAW(base1,$
    retain=0,$
    ;���ô�С
    xsize=400,$
    ysize=400,$
    ;����ʱ�����¼�
    /wheel_events,$
    ;�����ťʱ�����¼�
    /button_events,$
    ;��¶�����ڵ�����ǰ��ʾʱ��ʱ�����¼�
    /expose_events,$
    ;����ƶ�ʱ�����¼�
    /motion_events,$
    ;�����û�ʱ�¼�
    /keyboard_events,$
    ;���������uName�������֡�
    uname='mydraw')
  ;��ʾ
  WIDGET_CONTROL, base1, /REALIZE
  ;�����Ҽ��˵�����
  contextBase = WIDGET_BASE(mydraw, /CONTEXT_MENU)
  ;�Ҽ��˵��в˵�ѡ��
  button1 = WIDGET_BUTTON(contextBase, $
    VALUE='�Ҽ��˵�1', $
    uname = 'contexButton1')    
  button2 = WIDGET_BUTTON(contextBase, $
    VALUE='�Ҽ��˵�2', $
    uname = 'contexButton2')    
    
  ;��ȡϵͳ��ʼ����ɫģʽ
  DEVICE, Get_Decomposed = oriD
  ;��ʾα��ɫͼ��
  DEVICE, decomposed =0
  ;����ϵͳ��ɫ��
  LOADCT,23
  ;��ʾһ��400*400�ķ���ͼ��
  imgData = DIST(400)
  TVSCL,imgData
  
  ;��ȡ����Ĵ�С��Ϣ
  sz = WIDGET_INFO(base1,/geom)
  drawSZ = WIDGET_INFO(myDraw,/geom)
  ;��ʾ������������ı߽���
  drawSpace = [sz.XSIZE,sz.YSIZE] - [drawSZ.XSIZE,drawSZ.YSIZE]
  
  ;�����ṹ�壬�����������ID�Ͳ���
  state={label1:label1,$
    contextBase: contextBase, $
    text1:text1,$
    oriD: oriD, $
    imgData : imgData , $
    drawSpace: drawSpace, $
    testStr  : '��ʼ�ַ���!',$
    mydraw:mydraw}
  ;����ָ��
  pstate=PTR_NEW(state,/no_copy)
  ;��ָ����Ϣ�浽tlb��uvalue�б���
  WIDGET_CONTROL,base1,set_uvalue=pstate
  ;���������¼�
  
  XMANAGER, 'WIDGET_EXAMPLES', base1, $
    cleanup = 'WIDGET_EXAMPLES_CLEANUP',/NO_BLOCK
;Ҳ���������ʽ:ֱ��ָ���¼�����,event_handler ='abc'
    
END

