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
;�¼���Ӧ����δд�κδ���
PRO WIDGET_TEXT_EXAMPLE_EVENT, event
END

PRO WIDGET_TEXT_EXAMPLE
  ;����tlb��������
  base = WIDGET_BASE(/COLUMN)
  ;�����ɱ༭���ı���
  text1 = WIDGET_TEXT(base, $
    VALUE = ' �ɱ༭�ı���', $
    /EDITABLE, $
    YSIZE = 4)
  ;�������ɱ༭�ı���
  text2 = WIDGET_TEXT(base, $
    VALUE = ' ���ɱ༭�ı���', $
    YSIZE = 2, $
    /FRAME)
  ;��ʾ���
  WIDGET_CONTROL, base, /REALIZE
  ;�ȴ�1��
  WAIT,1
  ;�����������
  WIDGET_CONTROL, text1,set_value ='�ı�������'
  ;��Ӧ�¼�
  XMANAGER, 'WIDGET_TEXT_EXAMPLE', base, GROUP_LEADER = GROUP, /NO_BLOCK
  
END