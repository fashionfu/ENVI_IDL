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
;ENVI���в˵�����Ӳ˵�ʾ��
PRO MY_PROCESS_DEFINE_BUTTONS, buttonInfo
  COMPILE_OPT IDL2
  ;��Basic Tools�µ�һ��Preprocessing������New Tools�Ĳ˵�
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'New Tools', $
    /MENU, REF_VALUE = 'Preprocessing', REF_INDEX = 0, $
    POSITION = 'last'
  ;���²˵�New Tools������Ӳ˵�Tool 1
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Tool 1', $
    UVALUE = 'tool 1', EVENT_PRO = 'my_process_event', $
    REF_VALUE = 'New Tools'    
END
;
;;ENVI���˵���Ӳ˵�ʾ��
;PRO MY_PROCESS_DEFINE_BUTTONS, buttonInfo
;  COMPILE_OPT IDL2
;  ;�����˵�Basic Tools�ĺ�����Ӳ˵�"My Menu"
;  ENVI_DEFINE_MENU_BUTTON, buttonInfo, $
;    value = 'My Menu', /menu, $
;    ref_value = 'Basic Tools', $
;    /sibling, position = 'after'
;
;  ;��My Menu�˵������Ӳ˵�option1���¼���Ӧ����Ϊmy_process
;  ENVI_DEFINE_MENU_BUTTON, buttonInfo, $
;    value = 'Option 1', uvalue = 'option 1', $
;    event_pro = 'my_process', $
;    ref_value = 'My Menu', position = 'last'
;
;  ;��My Menu�˵������Ӳ˵�option2���¼���Ӧ����Ϊmy_process
;  ENVI_DEFINE_MENU_BUTTON, buttonInfo, $
;    value = 'Option 2', uvalue = 'option 2', $
;    event_pro = 'my_process', $
;    ref_value = 'My Menu', position = 'last'
;
;  ;��My Menu�˵������Ӳ˵�option3����ʾ�ָ��ߣ��¼���Ӧ����Ϊmy_process
;  ENVI_DEFINE_MENU_BUTTON, buttonInfo, $
;    value = 'Option 3', uvalue = 'option 3', $
;    event_pro = 'my_process_event', $
;    ref_value = 'My Menu', position = 'last', $
;    /separator
;END


;ENVI������չ����
PRO MY_PROCESS,event
  COMPILE_OPT IDL2
  ;
  ENVI_SELECT,title='��ѡ��һ���ļ�',fid=in_fid
  IF(in_fid EQ -1) THEN RETURN
  ENVI_FILE_QUERY,in_fid,ns=ns,nl=nl,nb=nb,fname=fname
  tmp = DIALOG_MESSAGE(fname,/info)
END

