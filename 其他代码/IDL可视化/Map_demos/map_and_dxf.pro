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

; DXF�ļ���ȡ����ʾ
PRO MAP_AND_DXF

  DEVICE, decomposed=0
  
  LOADCT, 38
  WINDOW, 1, xsize=800, ysize=600
  
  MAP_SET, 0, 0, 0, /moll, limit=[11.2, -127, 50, -55]
  MAP_CONTINENTS
  
  oDXF = OBJ_NEW('IDLffDXF')
  ok = oDXF->READ(FILE_DIRNAME(ROUTINE_FILEPATH('MAP_AND_DXF'))+'\states.dxf')
  ok = oDXF->GETCONTENTS(7, count=count)
  res = oDXF->GETENTITY(7)
  FOR i=0l, count[0]-1 DO PLOTS, *(res.VERTICES)[i], color=i*10
  
END