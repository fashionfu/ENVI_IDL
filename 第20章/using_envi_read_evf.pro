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
;��ȡENVI�� EVF�ļ�
;
PRO USING_ENVI_READ_EVF
  COMPILE_OPT IDL2
  ;����EVF�ļ�
  evf_fname = 'c:\temp\sample.evf'
  ;��EVF�ļ�
  evf_id = ENVI_EVF_OPEN(evf_fname)
  ;��ѯEVF�ļ���Ϣ
  ENVI_EVF_INFO, evf_id, num_recs=num_recs, $
    data_type=data_type, projection=projection, $
    layer_name=layer_name
    
  ;�����¼��
  PRINT, 'Number of Records: ',num_recs
  ;���������¼
  FOR i=0,num_recs-1 DO BEGIN
    ;��ȡ��ǰ��¼
    record = ENVI_EVF_READ_RECORD(evf_id, i,type= type)
    ;������¼�����
    PRINT, 'Number of nodes in Record: ' + $
      STRTRIM(i+1,2) + ': ',N_ELEMENTS(record[0,*])
    ;�����¼�������ͣ�1:��;3:����;5:�����;8���
    PRINT,'Record Type: '+STRTRIM(type,2)
  ENDFOR
  ;�ر�EVF�ļ�
  ENVI_EVF_CLOSE, evf_id
  
END

