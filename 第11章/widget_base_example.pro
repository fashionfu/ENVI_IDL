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
PRO WIDGET_BASE_EXAMPLE
  ;������߼�base(Top Level Base = tlb)
  tlb = WIDGET_BASE(xsize =200,ysize =200,title ='widget_base')
  ;��ʾ
  WIDGET_CONTROL,tlb,/realize
  ;ʹ��floating�ؼ��ִ�����������
  fbase = WIDGET_BASE(GROUP_LEADER =tlb, $
    xsize =200,ysize =200,$
    xOffset =200, $
    yOffset =200, $
    /floating,$
    title ='floating')
  ;��ʾ
  WIDGET_CONTROL,fbase,/realize
  ;ʹ��modal�ؼ��ִ���ģʽ����
  mbase = WIDGET_BASE(GROUP_LEADER =tlb, $
    xsize =200,ysize =200, $
    xOffset =400, $
    yOffset =200, $
    /modal,$
    title ='modal')
  ;��ʾ
  WIDGET_CONTROL,mbase,/realize
  ;����tlb_frame_attrΪ1�Ĵ���
  ttlb = WIDGET_BASE(xsize =200,ysize =200, $
    title ='TLB_FRAME_ATTR=1', $
    xOffset =000, $
    yOffset =400, $
    TLB_FRAME_ATTR = 1)
  ;��ʾ
  WIDGET_CONTROL,ttlb,/realize
  ;����tlb_frame_attrΪ2�Ĵ���
  ttlb2 = WIDGET_BASE(xsize =200,ysize =200, $
    title ='TLB_FRAME_ATTR=2', $
    xOffset =200, $
    yOffset =400, $
    TLB_FRAME_ATTR = 2)
  ;��ʾ
  WIDGET_CONTROL,ttlb2,/realize
  ;����tlb_frame_attrΪ9�Ĵ���
  ttlb3 = WIDGET_BASE(xsize =200,ysize =200, $
    title ='TLB_FRAME_ATTR=9,1+8', $
    xOffset =400, $
    yOffset =400, $
    TLB_FRAME_ATTR = 9)
  ;��ʾ
  WIDGET_CONTROL,ttlb3,/realize
  ;����tlb_frame_attrΪ4�Ĵ���
  ttlb4 = WIDGET_BASE(xsize =200,ysize =200, $
    title ='TLB_FRAME_ATTR=4', $
    xOffset =600, $
    yOffset =400, $
    TLB_FRAME_ATTR = 4)
  ;��ʾ
  WIDGET_CONTROL,ttlb4,/realize
  ;����tlb_frame_attrΪ8�Ĵ���
  ttlb8 = WIDGET_BASE(xsize =200,ysize =200, $
    title ='TLB_FRAME_ATTR=8', $
    xOffset =800, $
    yOffset =400, $
    TLB_FRAME_ATTR = 8)
  ;��ʾ
  WIDGET_CONTROL,ttlb8,/realize
  ;����tlb_frame_attrΪ16�Ĵ���
  ttlb16 = WIDGET_BASE(xsize =200,ysize =200, $
    title ='TLB_FRAME_ATTR=16', $
    xOffset =1000, $
    yOffset =400, $
    TLB_FRAME_ATTR = 16)
  ;��ʾ
  WIDGET_CONTROL,ttlb16,/realize
END