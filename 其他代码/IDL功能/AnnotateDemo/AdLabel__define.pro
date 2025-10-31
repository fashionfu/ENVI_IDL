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
;------------------------------------------------------------------------
;
;����
;
PRO AdLabel::RefreshDraw, ratio = ratio
  compile_opt idl2

  oSystem = self.oSystem

  dim = self.dimension*ratio
  self.oPolygon->GetProperty, data = data

  location = [MEAN(data[0,*]),MEAN(data[1,*]),MEAN(data[2,*])]
  ;
  polyData = DblArr(3,4)
  ;
  polyData[2,*] = Location[2]
  ;
  polyData[0,*] = [Location[0]-dim[0], $
                  Location[0]-dim[0], $
                  Location[0]+dim[0], $
                  Location[0]+dim[0] ]
  polyData[1,*] = [Location[1]-dim[0], $
                  Location[1]+dim[0], $
                  Location[1]+dim[0], $
                  Location[1]-dim[0] ]

  self.oPolygon->Setproperty,Data = polyData

END

;-----------------------------------------------------------------
;
;����
;
PRO AdLabel::Cleanup
  compile_opt idl2

  self->IDLgrModel::Cleanup

  obj_destroy, self.oPolygon

END
;
PRO AdLabel::GetProperty, type  = type,location = location , $
    dimension = dimension

    IF Arg_Present(type) NE 0 THEN type = self.type
    IF Arg_Present(dimension) NE 0 THEN dimension = self.dimension
    IF Arg_Present(location) NE 0 THEN BEGIN
        self.oPolygon->GetProperty, data = data
        location = [MEAN(data[0,*]),MEAN(data[1,*]),MEAN(data[2,*])]
    ENDIF
END
;-----------------------------------------------------------------
;
;��ʼ��
;
function AdLabel::Init          , $
    OSystem = oSystem           , $
    oManager = oManager         , $
    Parent = parent             , $
    Location = location         , $
    Color = color               , $
    Data = data                 , $
    Dimension = dimension       , $
    Alpha = alpha               , $
    Type = type                 , $
    Ratio = ratio               , $
    _Extra    = extra
  compile_opt idl2

  if (self->IDLgrModel::Init(_Extra=extra) ne 1) then Return, 0

  self.oSystem = oSystem
  self.oParent = parent
  self.oManager = oManager

  ;����Ĭ��ֵ
  if ~Keyword_Set(color) then color = [255,0,0]
  if ~Keyword_Set(dimension) then dimension =4
  if ~Keyword_Set(thick) then thick = 1
  if ~Keyword_Set(alpha) then alpha = 100.
  if ~Keyword_Set(location) then location = [0.,0.,80.]

  ;����ֵ
  self.color = color
  self.dimension = dimension
  self.alpha = alpha
  self.type = type

  dim = self.dimension*ratio
  polyData = DblArr(3,4)
  ;
  polyData[2,*] = Location[2]
  ;
  polyData[0,*] = [Location[0]-dim[0]   , $
                  Location[0]-dim[0]    , $
                  Location[0]+dim[0]    , $
                  Location[0]+dim[0]      ]
  polyData[1,*] = [Location[1]-dim[0]   , $
                  Location[1]+dim[0]    , $
                  Location[1]+dim[0]    , $
                  Location[1]-dim[0]      ]
  ;
  self.oPolygon = Obj_New('IDLgrPolygon', $
      Data = polyData                   , $
      Alpha_Channel = self.alpha/100    , $
      COLOR = self.color   )

  self->Add, self.oPolygon

  self.oParent->Add, self  ;

  Return, 1
END

;-----------------------------------------------------------------
;
;����
;
PRO AdLabel__Define
  compile_opt idl2

  void = {AdLabel           , $
       ;�̳еĸ���
         inherits IDLgrModel            , $

          ;����
          alpha       :   0.            , $
          color       :   IntArr(3)     , $
          dimension   :   0             , $
          type        : 0               , $

          ;����
          oSystem     :   Obj_New()     , $
          oParent     :   Obj_New()     , $
          oManager    :   Obj_New()     , $
          oPolygon    :   Obj_New()     $
          }
END