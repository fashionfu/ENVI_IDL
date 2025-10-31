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
;iImageContour�����µĿ��ӻ��ඨ���ļ�VisImageContour__define.pro
;Modified By DYQ
;-
FUNCTION VisImageContour::Init, _REF_EXTRA = _extra

   ;��ʼ���̳���
   IF (~self->IDLitVisualization::Init(NAME='VisImageContour', $
      ICON = 'image', _EXTRA = _extra)) THEN RETURN, 0

   ;ע����õĲ���
   self->RegisterParameter, 'IMAGEPIXELS', $
      DESCRIPTION = 'Image Data', /INPUT, $
      TYPES = ['IDLIMAGE', 'IDLIMAGEPIXELS', 'IDLARRAY2D'], /OPTARGET
   self->RegisterParameter, 'PALETTE', $
      DESCRIPTION = 'Palette', /INPUT, /OPTIONAL, $
      TYPES = ['IDLPALETTE','IDLARRAY2D'], /OPTARGET

   ;����ͼ�����͵�ֵ�߶���
   self._oImage = OBJ_NEW('IDLitVisImage', /PRIVATE)
   self->Add, self._oImage, /AGGREGATE
   self._oContour = OBJ_NEW('IDLitVisContour', /PRIVATE)
   self->Add, self._oContour, /AGGREGATE

   ;�ɹ��򷵻�1
   RETURN, 1
END

;�������޸�ʱˢ�¶���
PRO VisImageContour::OnDataChangeUpdate, oSubject, parmName, $
   _REF_EXTRA = _extra

   ; Branch based on the value of the parmName string.
   CASE STRUPCASE(parmName) OF

      ; The method was called with a paramter set as the argument.
      '<PARAMETER SET>': BEGIN
      oParams = oSubject->Get(/ALL, COUNT = nParam, $
         NAME = paramNames)
         FOR i = 0, nParam-1 DO BEGIN
            IF (paramNames[i] EQ '') THEN CONTINUE
            oData = oSubject->GetByName(paramNames[i])
            IF (OBJ_VALID(oData)) THEN $
              self->OnDataChangeUpdate, oData, paramNames[i]
        ENDFOR
      END

      ; The method was called with an image array as the argument.
      'IMAGEPIXELS': BEGIN
      void = self._oImage->SetData(oSubject, $
         PARAMETER_NAME = 'IMAGEPIXELS')
      void = self._oContour->SetData(oSubject, $
         PARAMETER_NAME = 'Z')
      ; Make our contour appear at the top OF the surface.
      IF (oSubject->GetData(zdata)) THEN $
         self._oContour->SetProperty, ZVALUE = MAX(zdata)
      END

      ; The method was called with a palette as the argument.
      'PALETTE': BEGIN
      void = self._oImage->SetData(oSubject, $
         PARAMETER_NAME = 'PALETTE')
      void = self._oContour->SetData(oSubject, $
         PARAMETER_NAME = 'PALETTE')
      END
      ELSE: ; Do nothing
   ENDCASE
END

;ͨ�����ӻ����ߵ�"disconnected"����ʱ���õķ���
PRO VisImageContour::OnDataDisconnect, ParmName
CASE STRUPCASE(parmname) OF
   'IMAGEPIXELS': BEGIN
      self->SetProperty, DATA = 0
      self._oImage->SetProperty, /HIDE
      self._oContour->SetProperty, /HIDE
   END
   'PALETTE': BEGIN
      self._oImage->SetProperty, PALETTE = OBJ_NEW()
      self->SetPropertyAttribute, 'PALETTE', SENSITIVE = 0
   END
   ELSE: 
 ENDCASE

END

;�ඨ���ļ����̳�IDLitVisualization������
;������_oContour��_oImage�����������
PRO VisImageContour__Define
   struct = { VisImageContour, $
      inherits IDLitVisualization, $
      _oContour: OBJ_NEW(), $
      _oImage: OBJ_NEW() $
   }
END

