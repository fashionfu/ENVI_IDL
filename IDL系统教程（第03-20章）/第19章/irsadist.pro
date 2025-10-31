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
; *******************************************************
; This routine is an example of how to create a custom
; spectral analyst function. Move this file to the save_add
; directory of the ENVI installation tree. Add an entry to the
; useradd.txt file to allow selection of this method from
; the Spectral Analyst routine. Set the weight for this
; routine greater than zero and select Apply.  The library spectra
; are then ranked according to the score returned from this
; method.
;
; For more information see the ENVI Programmer's Guide.
; *******************************************************
; Copyright (c) 1995-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
; *******************************************************
PRO IRSADIST_FUNC_SETUP, wl, spec_lib, handles, num_spec=num_spec
; No initialization is necessary
END

FUNCTION IRSADIST_FUNC, wl, ref, spec_lib, handles, num_spec=num_spec,$
    scale_vals=scale_vals
  ; Compute the distance compared to each library member
  result = DBLARR(num_spec)
  FOR i=0L, num_spec-1 DO $
    result[i] = SQRT(TOTAL((spec_lib[*,i]-ref)^2, /double))
    
  ; scale the result from zero to one
  dmax = MAX(result, min=dmin)
  RETURN, (1d - ((result - dmin) / (dmax - dmin))) / scale_vals[1]
END
