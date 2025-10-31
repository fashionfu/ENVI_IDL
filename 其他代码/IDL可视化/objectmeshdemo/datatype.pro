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
function datatype, value
  ;+
  array = size(value)
  
  type = array(n_elements(array)-2)
  case type of
    0: type = 'undefined'
    1: type = 'byte'
    2: type = 'integer'
    3: type = 'long'
    4: type = 'float'
    5: type = 'double'
    6: type = 'complex'
    7: type = 'string'
    8: type = 'structure'
    9: type = 'DoubleComplex'
    10: type = 'pointer'
    11: type = 'object'
    12: type = 'unsigned integer'
    13: type = 'unsigned longword integer'
    14: type = '64-bit integer'
    15: type = 'unsigned 64-bit integer'
  endcase
  return,type
end