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
PRO WIDGET_DropLIST_EXAMPLE_event,event
  ;��������б�ѡ������
  print,event.index
end
;���Խ��������ʾ
PRO WIDGET_DropLIST_EXAMPLE
  tlb = WIDGET_BASE($
    xsize = 200, $
    ysize = 200, $
    /column, $   
    title ='test_droplist')
  WIDGET_CONTROL,tlb,/realize
  ;
  listvalue =['�б�1','�б�2','�б�3','�б�4']
  wlist = Widget_Droplist(tlb,value = listvalue,$
    scr_ysize=20,$
    UNITS =2,$
    ysize = 20)  
  ;
  xmanager,'WIDGET_DropLIST_EXAMPLE',tlb,/no_block
END