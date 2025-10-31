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
PRO READ_HDF
  ;��ȡ��ǰ�ļ�����Ŀ¼
  curDir = FILE_DIRNAME(ROUTINE_FILEPATH('READ_HDF'),$
    /mark_directory)
  ;����Ҫ��ȡ��hdf�ļ�
  hdfFile = curDir+'data\example.hdf'
  ;�ж��ļ��Ƿ���ڣ�����������ʾ��ϢȻ���˳�
  IF ~FILE_TEST(hdfFile) THEN BEGIN
    void = DIALOG_MESSAGE('hdf�ļ������ڣ�',/Error)
    RETURN
  ENDIF
  ;��hdf�ļ�����ȡSD_ID
  sd_id=HDF_SD_START(hdfFile)
  ;��ȡ������Ϣ
  HDF_SD_FILEINFO,sd_id,NumSDS,attributes
  ;��ȡ��һ�����ݼ�
  sds_id=HDF_SD_SELECT(sd_id,0)
  ;��ȡ���ݼ�����Ϣ
  HDF_SD_GETINFO,sds_id,NDIMS=NDIMS,LABEL=LABEL,$
    DIMS=DIMS,TYPE=TYPE
  ;��ȡ���ݼ�����
  HDF_SD_GETDATA,sds_id,data
  ;hdf_sds��ȡ����
  HDF_SD_ENDACCESS,sds_id
  ;sd_id�ر�
  HDF_SD_END,sd_id
  ;���ɫ��ʽ��ʾ
  TVSCL, Data,/true
   erase,color = 'ffffff'x
  TVSCL, Data,/true
END