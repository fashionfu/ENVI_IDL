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
PRO WIDGET_TAB_EXAMPLE_event, ev
  ;
  uName = WIDGET_INFO(ev.id,/uname)
  ;�����������tab���
  IF uname EQ 'tab' THEN BEGIN
    WIDGET_CONTROL, ev.top,get_uvalue = pState
    ;����label��ֵ
    WIDGET_CONTROL,(*pState).show,set_value = ' ��ǰ�ǣ���'+STRTRIM(ev.Tab+1,2)+'��Tab����'
  ENDIF
END
;TAB�����ʾ
PRO WIDGET_TAB_EXAMPLE
  ;
  tlb = WIDGET_BASE(title='Widget_Tab', $
    /Column, /BASE_ALIGN_TOP, $
    xOffset = 200, $
    yOffset = 200)
  WIDGET_CONTROL,tlb,/Realize
  ;tab�������
  wt = WIDGET_TAB(tlb,uname = 'tab')
  ;��ʾ��ǩ
  show = WIDGET_LABEL(tlb,xsize = 200)
  w1 = WIDGET_BASE(wt, $
    title ='��һ��' , $
    xSize = 200, $
    ySize = 20  )
  wb = WIDGET_BUTTON(w1, $
    value ='tab1')    
  w2 = WIDGET_BASE(wt, $
    title ='�ڶ���'  )
  wb = WIDGET_BUTTON(w2, $
    value ='tab2')
  w3 = WIDGET_BASE(wt, $
    title ='������'  )
  wb = WIDGET_BUTTON(w3, $
    value ='tab3')
  ;
  WIDGET_CONTROL, tlb, set_uvalue = PTR_NEW({show: show},/no_copy)
  XMANAGER, 'WIDGET_TAB_EXAMPLE',tlb,/no_block
END