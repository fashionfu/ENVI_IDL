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
PRO WIDGET_SLIDER_EXAMPLE_EVENT,event
  ;�鿴��ǰѡ��ֵ
  PRINT,event.value
END
;�����������ʾ
PRO WIDGET_SLIDER_EXAMPLE
  tlb = WIDGET_BASE($
    /column, $
    title ='test_slider')
  WIDGET_CONTROL,tlb,/realize
  ;��������������ΧΪ [0,100]���޸Ĳ���Ϊ2
  wSlider = WIDGET_SLIDER(tlb, $
    MAXIMUM = 100,$
    MINIMUM =0,$
    xsize = 400, $
    scroll =2 )
  ;��Ӧ�¼�
  XMANAGER,'WIDGET_SLIDER_EXAMPLE',tlb,/no_block
END

