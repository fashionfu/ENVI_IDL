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
;
;��������¼���Ӧ����
;
PRO WIDGET_CREATE_EXAMPLE_EVENT, event
  ;�鿴event�¼��ṹ��
  HELP,event,/Structure
  ;��ô����¼������ID
  PRINT,'uName:', WIDGET_INFO(event.ID,/uName)
  ;��ô����¼���uValue��value
  WIDGET_CONTROL, event.ID, get_Value = curValue, get_UValue = curUValue
  PRINT,'value:',curValue
  PRINT,'UValue:',curUValue
END
;
;��������¼���Ӧʾ��
;  :���洴��
;
PRO WIDGET_CREATE_EXAMPLE
  ;�������涥��base,��СΪ200*200
  ;column���ʾ���ӽ����������
  tlb = WIDGET_BASE(/COLUMN, $
    xsize = 200, ysize = 200)
  ;������ť1����ǩΪClose
  button1 = WIDGET_BUTTON(tlb, $
    value='Close',$
    xoffset = 100, $
    uValue = 'button1 uvalue', $
    uname = 'close')
  ;������ť2����ǩΪInformation
  button2 = WIDGET_BUTTON(tlb, $
    value='Pop MSG',$
    uvalue = FINDGEN(4,4), $
    xoffset = 100, $
    uname = 'infor')
  ;�����ʾ�������ƶ���base���ɣ�������ʾ
  WIDGET_CONTROL, tlb, /REALIZE
  ;�鿴���ID
  PRINT,'tlb:',tlb
  PRINT,'button1:',button1
  PRINT,'button2:',button2
  ;����������Ӧ����
  XMANAGER, 'Widget_Create_Example', tlb,/NO_Block
END