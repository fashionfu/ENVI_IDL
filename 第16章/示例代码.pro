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
;IDL�Դ���dicom�ļ�
dicomFile = FILEPATH('mr_knee.dcm',SUBDIR=['examples','data'])
;��ѯ�ļ�������Ϣ
result = QUERY_DICOM(dicomFile,infor)
;������ʾ���ڣ�ͼ16. 9��
WINDOW,0,xsize = infor.DIMENSIONS[0],ysize = infor.DIMENSIONS[1]
TVSCL,READ_DICOM(dicomFile)


END