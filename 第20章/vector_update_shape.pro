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
PRO VECTOR_UPDATE_SHAPE

  ;ʸ���ļ�����
  mynewshape=OBJ_NEW('IDLffShape', 'c:\temp\cities.shp', /UPDATE)
  
  ;����ʵ��ṹ��
  entNew = {IDL_SHAPE_ENTITY}
  
  ;����ʵ��ṹ���Աֵ
  entNew.SHAPE_TYPE = 1
  entNew.ISHAPE = 200
  entNew.BOUNDS[0] = -666.25100
  entNew.BOUNDS[1] = 40.026878
  entNew.BOUNDS[2] = 0.00000000
  entNew.BOUNDS[3] = 0.00000000
  entNew.BOUNDS[4] = -105.25100
  entNew.BOUNDS[5] = 40.026878
  entNew.BOUNDS[6] = 0.00000000
  entNew.BOUNDS[7] = 0.00000000
  entNew.N_VERTICES = 1
  
  ;��ȡ��������Խṹ��
  attrNew = myshape ->GETATTRIBUTES(/ATTRIBUTE_STRUCTURE)
  
  ;�Խṹ���Ա��ֵ
  attrNew.ATTRIBUTE_0 = 'Boulder'
  attrNew.ATTRIBUTE_1 = 'Colorado'
  
  ;���ʵ�嵽shape������
  myshape -> PutEntity, entNew
  
  ;���ʵ�����Ե�shape������
  myshape -> SetAttributes, 0, attrNew
  
  ;�ر�shape����
  OBJ_DESTROY, myshape
  
END