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
;PRO my_widget_event, event
;  WIDGET_CONTROL, event.TOP, GET_UVALUE=state, /NO_COPY
;  Event-handling code goes here
;  WIDGET_CONTROL, event.TOP, SET_UVALUE=state, /NO_COPY
;END
;
;PRO my_widget_event, event
;  WIDGET_CONTROL, event.TOP, GET_UVALUE=pState
;  Event-handling code goes here, accessing the state
;  structure via the retrieved pointer.
;END
;�¼���Ӧ����
PRO BUTTONEVENT,event
  HELP,event
END
;���洴������
PRO MY_WIDGET
  tlb = WIDGET_BASE()
  button = WIDGET_BUTTON(tlb,$
    value ='OK', $
    event_pro = 'buttonEvent')
  ;������������
  WIDGET_CONTROL,tlb,/Realize
  XMANAGER,'my_widget',tlb,/no_Block
END