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
;�¼���Ӧ����
PRO CW_FIELD_EXAMPLE_EVENT, event
END
;CW_FIELD�����ʾ
PRO CW_FIELD_EXAMPLE
  ;����tlb
  base = WIDGET_BASE($
    title ='CW_Field', $
    /COLUMN)
  ;����cw_field�����ֻ����������
  field = CW_FIELD(base, $
    TITLE = "���룺", $
    /FRAME, $
    /integer)
  ;��ʾ
  WIDGET_CONTROL, base, /REALIZE
  
  ;��Ӧ�¼�����
  XMANAGER, 'CW_FIELD_EXAMPLE', base, GROUP_LEADER = GROUP, /NO_BLOCK
  
END