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
PRO READ_MODIS
  ;��ȡ��ǰ�ļ�����Ŀ¼
  curDir = FILE_DIRNAME(ROUTINE_FILEPATH('READ_MODIS'),$
    /mark_directory)
    
  ;����Ҫ��ȡ��modis�ļ�
  modisFile = curDir+$
    'data\MOD021KM.A2002248.0345.005.2007348121959.hdf'
  ;�ж��ļ��Ƿ���ڣ�����������ʾ��ϢȻ���˳�
  IF ~FILE_TEST(modisFile) THEN BEGIN
    void = DIALOG_MESSAGE('modis�ļ������ڣ�',/Error)
    RETURN
  ENDIF
  ;��hdf�ļ�����ȡSD_ID
  sd_id=HDF_SD_START(modisFile)
  
  ;��ȡγ����������ID����ȡ
  lat_SD_index = HDF_SD_NAMETOINDEX(sd_id,'Latitude')
  ;ֱ�Ӷ�λ������ID
  sds_id=HDF_SD_SELECT(sd_id,lat_SD_index)
  ;��ȡ�����ݼ�����Ϣ
  HDF_SD_GETINFO,sds_id,name=n,ndims=r,$
    type=t,natts=nats,$
    hdf_type=h,unit=u
  ;���γ�����ݵĵ�λ
  PRINT,u
  
  ;��ȡ���ݼ�����
  HDF_SD_GETDATA,sds_id,data
  ;hdf_sds��ȡ����
  HDF_SD_ENDACCESS,sds_id
  
  ;��ȡ������������ID����ȡ
  lat_SD_index = HDF_SD_NAMETOINDEX(sd_id,'Longitude')
  ;ֱ�Ӷ�λ������ID
  sds_id=HDF_SD_SELECT(sd_id,lat_SD_index)
  ;��ȡ�����ݼ�����Ϣ
  HDF_SD_GETINFO,sds_id,name=n,ndims=r,$
    type=t,natts=nats,$
    hdf_type=h,unit=u
    
  ;��ȡ���ݼ�����
  HDF_SD_GETDATA,sds_id,data
  ;hdf_sds��ȡ����
  HDF_SD_ENDACCESS,sds_id
  
  ;��ȡ��������������ID����ȡ
  RefSB_SD_index = HDF_SD_NAMETOINDEX(sd_id,'EV_1KM_RefSB')
  ;ֱ�Ӷ�λ������ID
  sds_id=HDF_SD_SELECT(sd_id,RefSB_SD_index)
  ;��ȡ�����ݼ�����Ϣ
  HDF_SD_GETINFO,sds_id,name=n,ndims=r,$
    type=t,natts=nats,$
    hdf_type=h,unit=u
  ;��ȡ���ݼ�����
  HDF_SD_GETDATA,sds_id,data
  ;hdf_sds��ȡ����
  HDF_SD_ENDACCESS,sds_id
  
  ;sd_id�ر�
  HDF_SD_END,sd_id
  ;���ɫ��ʽ��ʾ
  HELP,data
END