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

;
;�Ե���IDLDrawWidget�µ�SetNamedArray��CopyNamedArray�����������˳��������
;
FUNCTION CHANGEARRAYORDER, inArr
  ;
  oDims = SIZE(inArr,/dimension)
  oType = SIZE(inArr,/Type)
  nDims = SIZE(inArr,/N_dim)
  CASE nDims OF
    1:result = inArr
    2: BEGIN
      result = REFORM(inArr, oDims[1],oDims[0])
    END
    3: BEGIN
      result = REFORM(inArr,oDims[2],oDims[1],oDims[0])
    END
    ELSE: BEGIN
      cmdStr = 'result= Reform(inArr'
      FOR idx=nDims-1,0,-1 DO BEGIN
        cmdStr += ',oDims['+STRTRIM(iDx)+']'
      ENDFOR
      void = EXECUTE(cmdStr+')')
    END
  ENDCASE
  
  RETURN,result
END
