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
PRO WIDGET_LABEL_EXAMPLE
  ;����base
  tlb = WIDGET_BASE(xsize =200,ysize =200,title ='widget_label',/column)
  ;��ʾ����
  WIDGET_CONTROL,tlb,/realize
  ;������ǩ
  label = WIDGET_LABEL(tlb,value = '��ǩ1')
  ;�������б�ǩ
  label = WIDGET_LABEL(tlb,value = '��ǩ����'+STRING(13b)+'�ڶ����ַ���',ysize =40)
  ;��������ǩ
  label = WIDGET_LABEL(tlb,value = '�����',frame = 1)
END