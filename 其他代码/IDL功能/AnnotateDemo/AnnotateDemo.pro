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

;�աաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաաա�
;
;2008-7-25
;Write By DYQ
;
PRO AnnotateDemo
    ;
    COMPILE_OPT idl2
    Device, Get_Screen_Size = screenSize

    Cd, Current = rootDir

    oSystem = Obj_New('mainSystem'  , $
            Title = '��ע��ʾ���'  , $
         RootDir = rootDir            )

END