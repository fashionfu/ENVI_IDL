;+
;      ��IDL���Գ�����ơ�
; --���ݿ��ٿ��ӻ���ENVI���ο��������̣�
;
; ʾ��Դ����
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;
;-
;+
;ENVI���ο������ܴ���
;
;Author: DYQ
;�������ۣ�
; http://hi.baidu.com/dyqwrp
; http://bbs.esrichina-bj.cn/ESRI/?fromuid=9806
;������
; ��ʼ��ENVI
;
;���÷�����
;(1) ENVI�Ĵ�������в���ʾ������
; startEnvi
;(2) ENVI�Ĵ����������ʾ������
; startEnvi,/ShowProcess
;-

PRO startENVI, showProcess = showProcess
  compile_opt idl2  
  
  ENVI, /restore_base_save_files
  ENVI_BATCH_INIT, NO_STATUS_WINDOW = 1- keyWord_set(showProcess)
END