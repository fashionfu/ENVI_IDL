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
;�աաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաա�
;
PRO _MainSystem_Event, event

    COMPILE_OPT IDL2

    tlbUName = Widget_Info(event.top, /UName)


    CASE tlbUName OF
       'wBase' : BEGIN
         Widget_Control, event.top, Get_UValue = oSystem

         oSystem->HandleEvent, event
       END
       'annotate' : BEGIN
         Widget_Control, event.top, Get_UValue = oDGAnnotate

         oDGAnnotate->HandleEvent, event
       END
    ELSE :
    ENDCASE

END
