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
;ENVI������չ������ʽʾ��
;
PRO ENVI_FUNCTION,event
  COMPILE_OPT idl2
  ;����ENVI���ļ�ѡ��Ի���ѡ��һ���ļ�
  ENVI_SELECT ,  DIMS=dims , FID=fid, /NO_DIMS, POS=pos, TITLE='ѡ��һ���ļ���ע��˲������߱�dimsѡ����'
  ;ѡ�����ж�
  IF fid EQ -1 THEN BEGIN
    ENVI_REPORT_ERROR,'δѡ���ļ���',/warning
    RETURN
  ENDIF
  ;ѡ���ļ�����Ϣ��ѯ
  ENVI_FILE_QUERY,id = fid, fname = fname
  ;�ļ�id���Ƴ�
  ENVI_FILE_MNG,fid,/remove
  HELP,event
END