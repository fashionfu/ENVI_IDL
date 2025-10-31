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
PRO CREATE_HDF
  ;��ȡ��ǰ�ļ�����Ŀ¼
  curDir = FILE_DIRNAME(ROUTINE_FILEPATH('create_hdf'),$
    /mark_directory)    
  ;����Ҫ��ȡ��jpeg�ļ�
  jpegfile =curDir+'data\idl.jpg'
  ;�ж��ļ��Ƿ���ڣ�����������ʾ��ϢȻ���˳�
  IF ~FILE_TEST(jpegFile) THEN BEGIN
    void = DIALOG_MESSAGE('jpeg�ļ������ڣ�',/Error)
    RETURN
  ENDIF
  ;��ȡjpeg�ļ�
  READ_JPEG, jpegFile,data
  ;��ȡ������Ϣ
  dimensions = SIZE(data,/dimensions)
  ;���������hdf�ļ�
  hdfFile = curDir+'data\example.hdf'
  ;�ļ����Ѿ�������ɾ��
  IF FILE_TEST(hdfFile) THEN FILE_DELETE, hdfFile
  ;����HDF�ļ�
  sd_id=HDF_SD_START(hdfFile,/CREATE)
  ;�������ݼ�'idl.jpg'
  sds_id=HDF_SD_CREATE(sd_id,'idl.jpg', $
    dimensions,/byte)
  ;���������Ϣ
  HDF_SD_SETINFO,sds_id,LABEL=' each pixel value'
  ;д������ÿ��ά���ĺ���
  HDF_SD_DIMSET,HDF_SD_DIMGETID(sds_id,0),$
    NAME='RGB',$
    LABEL='nDimension of the JPEG'
  HDF_SD_DIMSET,HDF_SD_DIMGETID(sds_id,1),$
    NAME='Width',LABEL='Width of the JPEG'
  HDF_SD_DIMSET,HDF_SD_DIMGETID(sds_id,2),$
    NAME='Height',LABEL='Height of the JPEG'
  ;���������Ϣ
  HDF_SD_ADDDATA, sds_id, data
  ;SDS_id��Ӳ������ ���ر�sds
  HDF_SD_ENDACCESS,sds_id
  ;�ر�
  HDF_SD_END,sd_id
END