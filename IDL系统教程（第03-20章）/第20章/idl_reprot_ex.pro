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
PRO IDL_Reprot_Ex

  tlb = WIDGET_BASE(xsize = 400,ysize =300)
  WIDGET_CONTROL,tlb,/real
  ;
  ;IDL��iTools�Դ�������
  prsbar = IDLITWDPROGRESSBAR(GROUP_LEADER = tlb,title ='����',CANCEL=cancelIn)
  FOR i=0,99 DO BEGIN
    ;�ж��Ƿ���ȡ��
    IF WIDGET_INFO(prsbar,/valid) THEN  BEGIN
      IDLITWDPROGRESSBAR_SETVALUE,prsbar,i
    ENDIF ELSE BEGIN
      tmp = DIALOG_MESSAGE('�����ȡ��,��ǰ����λ��'+STRING(i)+'%',/info)
      BREAK
    ENDELSE
    ;�ȴ�0.1��
    WAIT,0.1
  ENDFOR
  Widget_Control,tlb,/destroy
  
END