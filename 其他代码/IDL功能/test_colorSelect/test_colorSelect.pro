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
;2007-7-19 By DYQ
;
PRO TEST_COLORSELECT_EVENT,ev
  compile_opt idl2
  
  CASE WIDGET_INFO(ev.ID,/uName) OF
    'cubic':  BEGIN
      thisColor = Dialog_Pickcolor(dialog_parent=ev.TOP, $
        init_color=[255,0,0], cancel=cancel, $
        title='ѡ����ɫ')
      IF ~CANCEL THEN PRINT,thisColor
    ;print,'ok'
    END
    'david': BEGIN
      colorName = PickColorName('white', Group_Leader=ev.TOP, $
        Cancel=cancelled)
      IF cancelled  NE 0 THEN Color = FSC_Color(colorName, /Triple)
      
    END
    'cancel': BEGIN
    
      WIDGET_CONTROL,ev.TOP,/Destroy
    END
  ENDCASE
  
END



PRO TEST_COLORSELECT

  tlb = WIDGET_BASE(title = '������ɫѡȡ',/Row   )
  
  wBtn = WIDGET_BUTTON(tlb,value = '��������ɫѡȡ',uName = 'cubic')
  ;
  wBtn = WIDGET_BUTTON(tlb,value = 'david��ɫѡȡ',uName = 'david')
  wBtn = WIDGET_BUTTON(tlb,value = '�˳�',uName = 'cancel')  
  
  WIDGET_CONTROL,tlb,/Realize
  ;
  centerTlb,tlb
  
  XMANAGER,'test_colorSelect',tlb,/No_Block
END


