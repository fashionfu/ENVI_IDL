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
;  $Id: //depot/idl/releases/IDL_80/idldir/examples/doc/widgets/tree_widget_example.pro#1 $

;  Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved.
;
; This program is used as an example in the "Widget Application Techniques"
; chapter of the _Building IDL Applications_ manual.
;
; This example creates a simple tree widget. Clicking on a leaf node
; toggles the text of the display to read either 'On' or 'Off'. This
; is not particularly useful, but serves as an example of how you
; might accomplish something more complicated.
;
; Modified By DYQ
;
;-

;�¼���Ӧ����
PRO TREE_WIDGET_EXAMPLE_EVENT, ev

  COMPILE_OPT hidden
  
  ;��ȡ�����UValue
  WIDGET_CONTROL, ev.ID, GET_UVALUE=uName
  
  ;���������д���
  IF (N_ELEMENTS(uName) NE 0) THEN BEGIN
    ;���������Ҷ
    IF (uName EQ 'LEAF') THEN BEGIN
      ;˫��
      IF (ev.CLICKS EQ 2) THEN TWE_TOGGLEVALUE, ev.ID
    ENDIF
    ;������ǰ�ť
    IF (uName EQ 'DONE') THEN WIDGET_CONTROL, ev.TOP, /DESTROY
  ENDIF
  
END

;�޸���Ҷ�ڵ�ֵ
PRO TWE_TOGGLEVALUE, widID
  COMPILE_OPT hidden
  
  ;��ȡ��ǰID��ֵ
  WIDGET_CONTROL, widID, GET_VALUE=curVal
  ;�ַ������
  full_string = STRSPLIT(curVal, ':', /EXTRACT)
  ;�ж��ַ������ݣ���On��Off֮�以��.
  full_string[1] = (full_string[1] EQ ' Off') ? ': On' : ': Off'
  ;�������value
  WIDGET_CONTROL, widID, SET_VALUE=STRJOIN(full_string)
END

;���
PRO WIDGET_TREE_EXAMPLE
  ;��������.
  wTLB = WIDGET_BASE(/COLUMN, TITLE='Widget_Tree Example')
  ; ����tree���.
  wTree = WIDGET_TREE(wTLB)
  ;��������.
  wtRoot = WIDGET_TREE(wTree, VALUE='��', /FOLDER, /EXPANDED)
  ;������Ҷ
  wtLeaf11 = WIDGET_TREE(wtRoot, VALUE='���� 1-1: Off', $
    UVALUE='LEAF')
  wtBranch12 = WIDGET_TREE(wtRoot, VALUE='��֦ 1-2', $
    /FOLDER, /EXPANDED)
  wtLeaf121 = WIDGET_TREE(wtBranch12, VALUE='���� 1-2-1: Off', $
    UVALUE='LEAF')
  wtLeaf122 = WIDGET_TREE(wtBranch12, VALUE='���� 1-2-2: Off', $
    UVALUE='LEAF')
  wtLeaf13 = WIDGET_TREE(wtRoot, VALUE='���� 1-3: Off', $
    UVALUE='LEAF')
  wtLeaf14 = WIDGET_TREE(wtRoot, VALUE='���� 1-4: Off', $
    UVALUE='LEAF')    
  ;������ť.
  wDone = WIDGET_BUTTON(wTLB, VALUE="ȷ��", UVALUE='DONE')  
  ;��ʾ.
  WIDGET_CONTROL, wTLB, /REALIZE
  XMANAGER, 'tree_widget_example', wTLB, /NO_BLOCK
  
END

