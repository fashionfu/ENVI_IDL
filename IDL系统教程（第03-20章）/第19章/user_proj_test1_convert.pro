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

PRO user_proj_test1_convert,x,y,lat,lon,to_map=to_map,projection=p
  IF(KEYWORD_SET(to_map)) THEN BEGIN
    X=lon
    Y=lat
  ENDIF ELSE BEGIN
    Lon=x
    Lat=y
  ENDELSE
END
