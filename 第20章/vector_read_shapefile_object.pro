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
PRO VECTOR_READ_SHAPEFILE_OBJECT
  ;��ȡIDL�Դ���shape�ļ�
  shapeFile = FILEPATH('states.shp', $
    SUBDIR=['examples', 'data'])
  ;������ʾ����
  oShape = OBJ_NEW('IDLffShape', shapeFile)
  ;��ʸ�������л�ȡʵ�����
  oShape->GETPROPERTY, N_Entities = nEntities
  ;����IDLgrModel����
  oModel= OBJ_NEW('IDLgrModel')
  ;��ȡÿ��ʵ�����Ϣ
  FOR i=0, nEntities-1 DO BEGIN
    entitie = oShape->GETENTITY(i)
    ;��ȡʵ������
    IF PTR_VALID(entitie.PARTS) NE 0 THEN BEGIN
      cuts = [*entitie.PARTS, entitie.N_VERTICES]
      ;ÿ��ʵ����ݴ��������
      FOR j=0, entitie.N_PARTS-1 DO BEGIN
        tempLon = (*entitie.VERTICES)[0,cuts[j]:cuts[j+1] - 1]
        tempLat = (*entitie.VERTICES)[1,cuts[j]:cuts[j+1] - 1]
        ;������״����ɫ�����
        opoly = OBJ_NEW('IDLgrPolygon', [tempLon, tempLat], $
          STYLE=1, color=[255,0,0])
        ;��Ӷ���ε�oModel��
        omodel->ADD, opoly
      ENDFOR
    ENDIF
    ;ɾ��ʵ��
    oShape->DESTROYENTITY, entitie
  ENDFOR
  ;����shape����
  OBJ_DESTROY, oShape
  ;�鿴��ʾ
  XOBJVIEW, oModel
END