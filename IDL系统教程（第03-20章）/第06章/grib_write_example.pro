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
;GRIB���ݵ�д������ʾ������
;ע�⣬IDL����Ͱ汾��8��1
PRO GRIB_WRITE_EXample, filename_in, filename_out, KEY=key, VALUE=value
  ON_ERROR, 2
  ;�ж��Ƿ���ò���
  IF(filename_in EQ !null) THEN MESSAGE, 'File is undefined.'
  IF(filename_out EQ !null) THEN MESSAGE, 'File is undefined.'

  IF(ARG_PRESENT(key) AND ~ ARG_PRESENT(value)) $
    THEN MESSAGE, 'If key is set then value has to be set.'
  IF(ARG_PRESENT(value) AND ~ ARG_PRESENT(key)) $
    THEN MESSAGE, 'If value is set then key has to be set.'
  ;��grib�ļ���ȡָ��
  fin = GRIB_OPEN(filename_in)
  ;��grib�ļ��л�ȡgrib���
  h = GRIB_NEW_FROM_FILE(fin)
  ;������grib��key
  IF (ARG_PRESENT(key)) THEN BEGIN
    IF (ISA(value, /ARRAY)) THEN GRIB_SET_ARRAY, h, key, value $
    ELSE GRIB_SET, h, key, value
  ENDIF
  ;�ļ�����д����Ϣ
  GRIB_WRITE_MESSAGE, filename_out, h
  ;����grid���������ڴ�
  GRIB_RELEASE, h
  ;�ر�grid�ļ�ָ��
  GRIB_CLOSE, fin 
  
END
