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
;+
;Copy from ITTVIS
;
;iImageContour���ߵ��ඨ���ļ�
;Modified By DYQ
;-
FUNCTION ImageContourCanny::INIT, _REF_EXTRA = _extra

  ; �����ʼ��
  IF (~ self->IDLITDATAOPERATION::INIT(NAME='Canny', $
    TYPES=['IDLVECTOR','IDLARRAY2D','IDLARRAY3D'], $
    DESCRIPTION="Canny", _EXTRA = _extra)) THEN $
    RETURN, 0
    
  ;����Ĭ��ֵ
  self._HIGHVALUE = 60
  self._LOWVALUE = 10
  self._SIGMAVALUE = 60
  
  ;ע������
  self->REGISTERPROPERTY, 'HighValue', /FLOAT, $
    DESCRIPTION='Canny High'
    
  self->REGISTERPROPERTY, 'LowValue', /FLOAT, $
    DESCRIPTION='Canny Low.'
    
  self->REGISTERPROPERTY, 'SigmaValue', /FLOAT, $
    DESCRIPTION='Canny Sigma'
  ;��ʾ�������ý���
  self->SETPROPERTYATTRIBUTE, 'SHOW_EXECUTION_UI', HIDE=0
  
  ; keyword parameters to the superclass SetProperty method.
  IF (N_ELEMENTS(_extra) GT 0) THEN $
    self->IMAGECONTOURCANNY::SETPROPERTY, _EXTRA = _extra
    
  RETURN, 1
END

;ִ�й���.
FUNCTION ImageContourCanny::EXECUTE, data

  ;ִ��Canny�㷨������
  data = CANNY(data,HIGH = HighValue, LOW = LowValue, SIGMA = SigmaValue)
  RETURN, 1
  
END

;�������ý�����ʾ
FUNCTION ImageContourCanny::DoExecuteUI

  ;��ȡ��ǰ���ߵ�tool
  oTool = self->GETTOOL()
  IF (~oTool) THEN RETURN, 0
  ;����������Ч
  self->SETPROPERTYATTRIBUTE, $
    ['HighValue', 'LowValue','SigmaValue'], SENSITIVE=1
  result = oTool->DOUISERVICE('PropertySheet', self)
  RETURN, result  
END

;��ȡ���Բ���
PRO ImageContourCanny::GetProperty, $
    HighValue =HighValue, $
    LowValue = LowValue, $
    SigmaValue = SigmaValue, $
    METHOD = method, $
    _REF_EXTRA = _extra
    
  ;���ȡHighValueֵ���򷵻�self._HighValue
  IF ARG_PRESENT(HighValue) THEN  HighValue = self._HIGHVALUE
  ;���ȡLowValueֵ���򷵻�self._LowValue
  IF ARG_PRESENT(LowValue) THEN LowValue = self._LOWVALUE
  ;���ȡSigmaValueֵ���򷵻�self._SigmaValue
  IF ARG_PRESENT(SigmaValue) THEN SigmaValue = self._SIGMAVALUE  
  ;�������
  IF (N_ELEMENTS(_extra) GT 0) THEN $
    self->IDLITDATAOPERATION::GETPROPERTY, _EXTRA = _extra    
END

;�������Բ���
PRO ImageContourCanny::SetProperty, $
    LowValue = LowValue, $
    HighValue = HighValue, $
    SigmaValue = SigmaValue, $
    METHOD = method, $
    _REF_EXTRA = _extra
    
  ;�縳HighValueֵ���򸳸�self._HighValue
  IF N_ELEMENTS(HighValue) THEN $
    IF (HighValue NE 0) THEN self._HIGHVALUE = HighValue
  ;�縳LowValueֵ���򸳸�self._LowValue
  IF N_ELEMENTS(LowValue) THEN $
    IF (LowValue NE 0) THEN self._LOWVALUE = LowValue
  ;�縳SigmaValueֵ���򸳸�self._SigmaValue  
  IF N_ELEMENTS(SigmaValue) THEN $
    IF (SigmaValue NE 0) THEN self._SIGMAVALUE = SigmaValue
    
  ;�������
  IF (N_ELEMENTS(_extra) GT 0) THEN $
    self->IDLITDATAOPERATION::SETPROPERTY, _EXTRA = _extra    
END

;�ඨ��ṹ��
PRO IMAGECONTOURCANNY__DEFINE

  struc = {ImageContourCanny, $
    inherits IDLitDataOperation,   $
    _HighValue: 0d, $
    _LowValue: 0d, $
    _SigmaValue: 0d, $
    _method: 0b $
    }
    
END

