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
PRO VECTOR_CREATE_SHAPEFILE

  ;����ʸ���ļ�����ʵ�����Ͳ��ձ�����
  mynewshape=OBJ_NEW('IDLffShape', 'c:\temp\cities.shp', ENTITY_TYPE=1)
    
  ;���������Ϣ
  mynewshape->ADDATTRIBUTE, 'CITY_NAME', 7, 25, $
    PRECISION=0
  mynewshape->ADDATTRIBUTE, 'STAT_NAME', 7, 25, $
    PRECISION=0
    
  ;����ʵ��ṹ��
  entNew = {IDL_SHAPE_ENTITY}
  
  ;����ʵ��ṹ���Աֵ
  entNew.SHAPE_TYPE = 1
  entNew.ISHAPE = 1458
  entNew.BOUNDS[0] = -104.87270
  entNew.BOUNDS[1] = 39.768040
  entNew.BOUNDS[2] = 0.00000000
  entNew.BOUNDS[3] = 0.00000000
  entNew.BOUNDS[4] = -104.87270
  entNew.BOUNDS[5] = 39.768040
  entNew.BOUNDS[6] = 0.00000000
  entNew.BOUNDS[7] = 0.00000000
  entNew.N_VERTICES = 1 
  
  ;��ȡ��������Խṹ��
  attrNew = mynewshape ->GETATTRIBUTES(/ATTRIBUTE_STRUCTURE)
  
  ;�Խṹ���Ա��ֵ
  attrNew.ATTRIBUTE_0 = 'Denver'
  attrNew.ATTRIBUTE_1 = 'Colorado'
  
  ;���ʵ�嵽shape������
  mynewshape -> PutEntity, entNew
  
  ;���ʵ�����Ե�shape������
  mynewshape -> SetAttributes, 0, attrNew
  
  ;�ر�shape����
  OBJ_DESTROY, mynewshape
  
END