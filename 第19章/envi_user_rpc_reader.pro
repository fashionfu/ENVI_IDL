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

FUNCTION ENVI_USER_RPC_READER, FID=fileID, FNAME=filename, $
    _EXTRA=extra
  COMPILE_OPT STRICTARR
  
  ;���û��RPC�ļ����򷵻�-1,��ȡRPC�ļ��ɹ��򷵻�RPCs�Ľṹ��
  IF (N_ELEMENTS(filename) EQ 0) THEN BEGIN
    IF (N_ELEMENTS(fileID) EQ 0) THEN RETURN, -1
    ENVI_FILE_QUERY, fileID, FNAME = filename
    filename = filename + '.rpc'
  ENDIF
  ;����RPC�ṹ��.
  rpcCoeffs = get_rpc_coefficient_structure()
  ; �ҵ�RPC �ļ����򿪶�ȡ�� .rpc �ļ���ͼ�������ļ���ͬһĿ¼
  IF (~FILE_TEST(filename)) THEN RETURN, -1
  OPENR, unit, filename, /GET_LUN
  value = ''
  ;��ȡRPC�ṹ�帳ֵ
  FOR index = 0, 4 DO BEGIN
    READF, unit, value
    rpcCoeffs.OFFSETS[index] = DOUBLE(value)
  ENDFOR
  FOR index = 0, 4 DO BEGIN
    READF, unit, value
    rpcCoeffs.SCALES[index] = DOUBLE(value)
  ENDFOR
  FOR INDEX = 0, 19 DO BEGIN
    READF, unit, value
    rpcCoeffs.LINE_NUM_COEFF[index] = DOUBLE(value)
  ENDFOR
  FOR INDEX = 0, 19 DO BEGIN
    READF, unit, value
    rpcCoeffs.LINE_DEN_COEFF[index] = DOUBLE(value)
  ENDFOR
  FOR INDEX = 0, 19 DO BEGIN
    READF, unit, value
    rpcCoeffs.SAMP_NUM_COEFF[index] = DOUBLE(value)
  ENDFOR
  FOR INDEX = 0, 19 DO BEGIN
    READF, unit, value
    rpcCoeffs.SAMP_DEN_COEFF[index] = DOUBLE(value)
  ENDFOR
  READF,unit,value
  rpcCoeffs.P_OFF = DOUBLE(value)
  READF,unit,value
  rpcCoeffs.L_OFF = DOUBLE(value)
  ;�ļ��ر�.
  FREE_LUN, unit
  ;����RPC�ṹ��
  RETURN, rpcCoeffs
END
