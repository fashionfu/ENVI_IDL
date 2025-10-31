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
;��γ��ת�ȷ���
FUNCTION LLTODMS,oxmap
  COMPILE_OPT idl2
  absoxmap = ABS(oxmap)
  degree = FIX(absoxmap)
  minute = FIX((absoxmap-degree)*60)
  second = FIX(((absoxmap-degree)*60-minute)*60)  
  degree = STRTRIM(degree,2)
  minute = STRTRIM(minute,2)
  second = STRTRIM(second,2)
  ;��0����
  IF STRLEN(minute) LT 2 THEN minute = '0'+minute
  IF STRLEN(second) LT 2 THEN second = '0'+second  
  dms = degree+'��'+minute+'��'+second+'��'  
  RETURN, dms  
END
;
;����ƶ�ʱ��λ��������ʾ
;
PRO USER_CURSOR_INFO, dn, xloc, yloc, xstart=xstart, ystart=ystart
  COMPILE_OPT idl2
  COMMON ud_move_2_c, ud_wid, data
  ;
  ;�ж���������Ƿ񴴽�
  IF (N_ELEMENTS(ud_wid) EQ 0) THEN ud_wid = -1L
  IF (WIDGET_INFO(ud_wid, /valid) EQ 0) THEN BEGIN  
    ; �������λ����Ϣ��ʾ����  
    title = '���λ�þ�γ����ʾ'
    ;�������
    ENVI_CENTER,  xoff, yoff
    base = WIDGET_BASE(title=title, xoff=xoff, yoff=yoff, $
      /row, group=envi_main_base(),TLB_FRAME_ATTR = 1)
    sb   = WIDGET_BASE(base, /column, /frame)
    sb1  = WIDGET_BASE(sb, /col)
    lab  = WIDGET_LABEL(sb1, value='�����Ϣ')
    tw   = WIDGET_TEXT(sb1, value='Data display area.', xs=40, ys=5)
    WIDGET_CONTROL,base,/realize 
    data = {tw:tw}
    ud_wid = base    
  ENDIF  
  ;��õ�ǰ�ļ���Ϣ������fid��pos��Color�ȶ���Ϊ������Ϣ
  ENVI_DISP_QUERY, dn, fid=fid, pos=pos, color=color
  ;��ȡmap��Ϣ
  map_info = ENVI_GET_MAP_INFO(fid=fid,UNDEFINED=UNDEFINED)
  iproj = map_info.PROJ
  ;��δ��������ʾ
  IF UNDEFINED THEN BEGIN
    msg = ['Disp #' + STRTRIM(STRING(dn+1),2)+ ' (' + STRTRIM(STRING(LONG(xloc)+1),2) $
      + ',' + STRTRIM(STRING(LONG(yloc)+1),2)+')' , $
      'Projection: δ����']
  ENDIF ELSE BEGIN
    ENVI_CONVERT_FILE_COORDINATES, fid, xloc, yloc, xmap, ymap, /to_map
    ;ʱʱ��ȡ���λ����Ϣ��ת��Ϊ��γ��������ʾ
    oproj = ENVI_PROJ_CREATE(/geographic)
    ENVI_CONVERT_PROJECTION_COORDINATES, $
      xmap, ymap, iproj, $
      oxmap, oymap, oproj	;
    IF oxmap LT 0 THEN xPre ='����' ELSE xPre ='����'
    IF oymap LT 0 THEN yPre ='��γ' ELSE yPre ='��γ'
    xxmap = LLTODMS(oxmap)
    yymap = LLTODMS(oymap)
    msg = ['Disp #' + STRTRIM(STRING(dn+1),2)+ '(' + STRTRIM(LONG(xloc+1),2) $
      + ',' + STRTRIM(LONG(yloc)+1,2)+')' , $
      'Projection: '+iproj.NAME, $
      'LL-1: '+yPre+yymap+','+xPre+xxmap,$
      'LL-2: '+STRTRIM(STRING(oymap,format='(f0.4)'),2)+$
      '��,'+STRTRIM(STRING(oxmap,format='(f0.4)'),2)+'��']
  ENDELSE
  ;�������λ����Ϣ
  WIDGET_CONTROL, data.TW, set_value=msg, /no_copy
END
