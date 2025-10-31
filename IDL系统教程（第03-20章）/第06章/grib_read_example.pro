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
;GRIB���ݵĶ�ȡ����ʾ������
;ע�⣬IDL����Ͱ汾��8.1
PRO  GRIB_Read_Example, HEADER=header
  compile_opt idl2
  ;IDL�汾�ж�
  curversion = FLOAT(!Version.RELEASE)
  IF curversion LT 8.1 THEN BEGIN
    void = DIALOG_MESSAGE('��ǰIDL�汾����8.1',/infor)
    RETURN
  ENDIF
  ;ѡ��Grib�ļ�
  filename = DIALOG_PICKFILE(title ='ѡ��Grib����')
  ;��grib�ļ����ָ��
  f = GRIB_OPEN(filename)
  ;��������ָ��
  data = PTRARR(GRIB_COUNT(filename))
  ;���������header�����ʼ������
  IF(ARG_PRESENT(header)) THEN header = MAKE_ARRAY(GRIB_COUNT(filename), /OBJ)
  ;��grib�ļ��л�ȡgrib���
  h = GRIB_NEW_FROM_FILE(f)
  ;��ʼ����������
  i=0
  ;ѭ����ȡ
  WHILE(h NE !NULL) DO BEGIN
  
    ;��ȡֵ����
    values = GRIB_GET_VALUES(h)
    data[i] = PTR_NEW(values)
    ;����Ҫ��ȡheader�����ζ�ȡ
    IF (ARG_PRESENT(header)) THEN BEGIN
      kiter = GRIB_KEYS_ITERATOR_NEW(h, /COMPUTED)
      header[i] = LIST()
      res = GRIB_KEYS_ITERATOR_NEXT(kiter)
      WHILE (res EQ 1) DO BEGIN
        key = GRIB_KEYS_ITERATOR_GET_NAME(kiter)
        IF (STRCMP(key, 'values', /FOLD_CASE) EQ 0) THEN BEGIN
          IF (GRIB_GET_SIZE(h, key) GT 1) THEN $
            val = GRIB_GET_ARRAY(h, key)ELSE val = GRIB_GET(h, key)
          IF (STRCMP(key, '7777', /FOLD_CASE) EQ 1) THEN key = 'end_section'
          key_value = CREATE_STRUCT(key, val)
          header[i].ADD, key_value
        ENDIF
        res = GRIB_KEYS_ITERATOR_NEXT(kiter)
      ENDWHILE
      GRIB_KEYS_ITERATOR_DELETE, kiter
    ENDIF
    
    GRIB_RELEASE, h
    h = GRIB_NEW_FROM_FILE(f)
    i++
  ENDWHILE
  ;�ر�Grib�ļ�ָ��
  GRIB_CLOSE, f
  ;�鿴��ȡ��������Ϣ
  HELP, data
END

