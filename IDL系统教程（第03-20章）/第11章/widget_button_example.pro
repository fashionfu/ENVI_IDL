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
PRO WIDGET_BUTTON_EXAMPLE
  ;����base
  tlb = WIDGET_BASE($
    xoffset = 400, $
    yoffset = 400, $
    /column, $
    mbar =mbar,$
    title ='test_button')
  ;�����mBar������Ϊ�˵�
  menu = WIDGET_BUTTON(mbar, value ='�ļ�(&F)')
  fmenu = WIDGET_BUTTON(menu, value ='��')
  ;ʹ��menu�ؼ���
  mMenu = WIDGET_BUTTON(menu, value ='����',/menu)
  tMenu = WIDGET_BUTTON(mMenu, value ='����',/menu)
  ;ʹ��separator�ؼ���
  eMenu = WIDGET_BUTTON(menu, value ='�˳�',/SEPARATOR)
  ;������������base���
  ubase = WIDGET_BASE(tlb,/row)
  dbase = WIDGET_BASE(tlb,/row)
  ;��������������ʾ�İ�ť��ͼ�갴ť
  b = WIDGET_BUTTON(ubase,value = '��ť',tooltip = '������button')
  h = WIDGET_BUTTON(ubase,value = BINDGEN(2,40))
  ;����λͼͼ�갴ť
  bmpfile  = FILEPATH('colorbar.bmp', SUBDIRECTORY=['resource','bitmaps'])
  bit =WIDGET_BUTTON(ubase,value =bmpfile,/bitmap)
  ;����widget_Base�ؼ��ִ�����ѡbutton'
  exbase = WIDGET_BASE(dbase,/EXCLUSIVE,/column)
  eb1 = WIDGET_BUTTON(exbase,value ='��')
  eb2 = WIDGET_BUTTON(exbase,value ='��')
  ;����widget_Base�ؼ��ִ�����ѡ��ť
  nexbase = WIDGET_BASE(dbase,/NONEXCLUSIVE,/column)
  eb1 = WIDGET_BUTTON(nexbase,value ='envi')
  eb2 = WIDGET_BUTTON(nexbase,value ='idl')
  ;��ʾ����
  WIDGET_CONTROL,tlb,/realize
END