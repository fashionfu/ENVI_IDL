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
PRO WIDGET_LIST_EXAMPLE_EVENT,ev
;��ȡtlb���û��������uvalue
  WIDGET_CONTROL, ev.top, get_uvalue = pState
  ;��ȡѡ������
  selected = WIDGET_INFO(ev.id,/LIST_SELECT )
  ;���ѡ��ֵ
  PRINT,(*pState).listvalue[selected]  
END
;list���������ʾ
PRO WIDGET_LIST_EXAMPLE
  ;����tlb
  tlb = WIDGET_BASE($
    xsize = 200, $
    /column, $
    title ='test_list')
  WIDGET_CONTROL,tlb,/realize
  ;ʹ��list���
  listvalue = "�б�"+['1','2','3','4']
  wlist = WIDGET_LIST(tlb,value = listvalue,$
    /MULTIPLE, $
    SCR_YSIZE =50)
  WIDGET_CONTROL, tlb,set_uvalue= PTR_NEW({listvalue:listvalue},/no_copy)
  ;�¼���Ӧ����
  XMANAGER,'WIDGET_LIST_EXAMPLE',tlb,/no_block
END