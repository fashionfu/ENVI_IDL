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
;�աաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաա�
;
PRO _MainSystem_Cleanup, tlb

    COMPILE_OPT IDL2

    tlbUName = Widget_Info(tlb, /UName)

    CASE tlbUName OF
       'wBase' : BEGIN
         Widget_Control, tlb, Get_UValue = oSystem

         IF N_Elements(oSystem) EQ 0 THEN Heap_GC ELSE Obj_Destroy, oSystem
       END
    ELSE :
    ENDCASE

END