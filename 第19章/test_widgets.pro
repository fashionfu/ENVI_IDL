;+
;         ��IDL������ơ�
; --���ݿ��ٿ��ӻ���ENVI���ο��������̣�
;
; ʾ��Դ����
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;
;-

PRO test_widgets, event
  COMPILE_OPT STRICTARR
  TLB = WIDGET_AUTO_BASE(title='ENVI�������ʾ��')
  p1 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=2, $
    prompt='�����һ��������', uvalue='p1')
  p2 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=2, $
    prompt='����ڶ���������', uvalue='p2')
  operation = WIDGET_TOGGLE(tlb, /auto_manage, default=0, $
    list=['��', '��'], prompt='����', $
    uvalue='operation')
  result=AUTO_WID_MNG(TLB)
  IF (result.accept EQ 0) THEN RETURN
  IF (result.operation EQ 0) THEN $
    ENVI_INFO_WID, STRTRIM(result.p1 + result.p2) ELSE $
    ENVI_INFO_WID, STRTRIM(result.p1 * result.p2)
END
