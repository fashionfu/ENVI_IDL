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
;�¼�����
PRO WIDGET_TABLE_EXAMPLE_EVENT,ev
  ;��ȡ�����uname
  uName = WIDGET_INFO(ev.id,/uName)
  
  
  ;�������������Ӧ�¼�
  IF uName EQ 'table1' THEN BEGIN
    ;
    IF ev.type EQ 4 THEN BEGIN
      IF ev.sel_left NE -1 THEN BEGIN
        tmp  = DIALOG_MESSAGE('ѡ�е����Ͻ����к�:'+STRTRIM(ev.sel_top,2)+STRTRIM(ev.sel_Left,2) $
          +'���½����к�:'+STRTRIM(ev.sel_bottom,2)+STRTRIM(ev.sel_right,2),/infor)
      ENDIF
    ENDIF
  ENDIF
  IF uName EQ 'showInfo1' THEN BEGIN
    ;����Widget_info�����table1��ID
    tableID = WIDGET_INFO(ev.top,  $
      Find_By_UName='table1')
    IF tableID NE 0 THEN BEGIN
      ;��ȡ����ֵ
      WIDGET_CONTROL,tableID, get_Value = sValue
      PRINT,sValue
      ;Ĭ�Ϸ��ض�������
      PRINT,'��ǰѡ��',WIDGET_INFO(tableID,/TABLE_SELECT )
    ENDIF
  ENDIF
  IF uName EQ 'showInfo2' THEN BEGIN
    ;����Widget_info�����table1��ID
    tableID = WIDGET_INFO(ev.top,  $
      Find_By_UName='table2')    ;
    IF tableID NE 0 THEN BEGIN
      WIDGET_CONTROL,tableID, get_Value = sValue
      PRINT,'��ǰѡ��',WIDGET_INFO(tableID,/TABLE_SELECT )
    ENDIF
  ENDIF
END
;��������ʾ
PRO WIDGET_TABLE_EXAMPLE
  ;����tlb
  tlb = WIDGET_BASE(title='Widget_Table��ʾ', $
    /Column, $
    uname='wtlb' )
  ;��������������Ӧ�����¼�
  table1 = WIDGET_TABLE(tlb, $
    uName  = 'table1', $
    xsize = 4, ysize = 6, $
    /All_Events)
  ;����һ����ť
  showInfo = WIDGET_BUTTON(tlb, $
    value ='�鿴��1', $
    uName  = 'showInfo1')
  ;�������������ɱ༭�ɾ���ѡ��
  table2 = WIDGET_TABLE(tlb, $
    /DISJOINT_SELECTION, $
    /Editable,$
    COLUMN_LABELS = '��'+STRTRIM(INDGEN(5),2), $
    xsize = 3, ysize = 3, $
    uName  = 'table2')
  ;����һ����ť
  showInfo = WIDGET_BUTTON(tlb, $
    value ='�鿴��2', $
    uName  = 'showInfo2')
  ;��ʾ
  WIDGET_CONTROL,tlb,/realize
  ;������ݸ���ֵ
  WIDGET_CONTROL, table2, set_value = INDGEN(3,3)
  ;
  XMANAGER,'WIDGET_TABLE_EXAMPLE',tlb,/no_block
END