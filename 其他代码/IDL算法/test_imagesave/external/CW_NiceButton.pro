;+------------------------------------------------------------------------------------------
; This is a procedural interface for setting the
; current range of a range_slider object, called during
; WIDGET_CONTROL, SET_VALUE on the top base.  This
; is not presently implemented.
;
; @Param
;	ID {in}{required}{type=long}
;		The widget ID of the top base of the compound widget.
; @Param
;	Value
;
; @History
;	February 2003 : Jim Pendleton Research Systems, Inc.
;   October  2007 : Huxz, Insititute of Space and Earth Infomation Science, The Chinese University of Hong Kong
;-------------------------------------------------------------------------------------------
Pro NiceButton_Set_Value, ID, Value

	Compile_Opt StrictArr

	On_Error, 2

	UValueBase = Widget_Info(ID, Find_by_UName = 'UValueBase')

	Widget_Control, UValueBase, Get_UValue = oNiceButton

	oNiceButton->SetProperty, Value = Value
End
;+------------------------------------------------------------------------------------------
; This is a procedural interface for retrieving the
; current range of a range_slider object, via
; WIDGET_CONTROL, GET_VALUE on the top base.  This
; is not presently implemented.
;
; @Param
;	ID {in}{required}{type=long}
;		The widget ID of the top base of the compound widget.
;
; @Returns
;	The return value is a
;
; @History
;	February 2003 : Jim Pendleton, Research Systems, Inc.
;   October  2007 : Huxz, Insititute of Space and Earth Infomation Science, The Chinese University of Hong Kong
;-------------------------------------------------------------------------------------------
Function NiceButton_Get_Value, ID

	Compile_Opt StrictArr

	On_Error, 2

	UValueBase = Widget_Info(ID, Find_by_UName = 'UValueBase')

	Widget_Control, UValueBase, Get_UValue = oNiceButton

	oNiceButton->GetProperty, Value = Value

	Return, Value
End
;+------------------------------------------------------------------------------------------
; This is a procedural interface for creating
; a nice_button object widget.
;
;	TLB = Widget_Base(Title = 'Panic Button', /Column)
;	NiceButton = CW_NiceButton(TLB, $
;		UName = UName, $
;		UValue = UValue, $
;		Scr_Size = Size, $
;		Timer = Timer)</pre>
;
;	The event structure returned by this compound widget is
;	the standard {WIDGET_BUTTON} structure, with the Select
;	field given one of three values.<pre>
;	  Select = 0 : The mouse moved off the button after a press but before a release
;	  Select = 1 : The mouse was pressed and released on the button
;	  Select = 2 : The mouse has been pressed but not released </pre>
;
; @Param
;	Parent {in}{required}{type=long}
;		The ID of the parent WIDGET_BASE to contain the nice_button
;		compound widget.
;
; @Keyword
;	oNiceButton {out}{optional}{type=TwoDDraw object reference}
;		Set this keyword to a named variable to receive the
;		object reference to the nice_button object.
; @Keyword
;	Scr_Size {in}{optional}{type=long}{default=100}
;		A single value, indicating the height and width of the panic
;		button image, in pixels.
; @Keyword
;	UValue {in}{optional}{type=any}{default=none}
;		Set this keyword to any user-supplied user value to be associated
;		with the compound widget's top base.
; @Keyword
;	UName {in}{optional}{type=string}{default=none}
;		Set this keyword to any user-supplied name string to be applied to the
;		compound widget's top base.
; @Keyword
;	Timer {in}{optional}{type=float}{default=0.10}
;		Set this keyword to a scalar floating point value to indicate the
;		time between color changes when pulsing the button image.
;
; @Returns
;	The return value is the ID of the widget base containing
;	the GUI elements of the nice_button.  The function will
;	return -1 if the object creation fails.
;
; @History
;	February 2003 : Jim Pendleton, Research Systems, Inc.
;   October  2007 : Huxz, Insititute of Space and Earth Infomation Science, The Chinese University of Hong Kong
;-------------------------------------------------------------------------------------------
Function CW_NiceButton, Parent, $ ; �����ϼ�Base
						Name = Name, $ ; ��ʾ����
						BarImage = BarImage, $ ; ��ʾͼ��Ư����
						oNiceButton = oNiceButton, $ ; �����϶���
						Scr_Size = Scr_Size, $ ; ���������С��[X Y]
						UName = UName, $ ; ����ʶ���
						UValue = UValue, $ ; �������
						Timer = Timer, $ ; ���붯���ٶ�, ͬʱҲ�������������ı�ǡ����û������Timer����������
						GroudStyle = GroudStyle, $ ; ������ѡ��3��,ϵͳ�ṩ
						TypeStyle = TypeStyle, $ ; ����ѡ��5��
						Status_Normal = Status_Normal, $ ; ��ͨ״̬, ѡ��Ҫ��Ҫ����
						TextColor = TextColor, $  ; ������ɫ
						ToolTip = ToolTip ;
	Compile_Opt StrictArr ;

	On_Error, 2

	oNiceButton = Obj_New('Nice_Button', $ ;
							Parent, $ ; �����ϼ�Base
							ID, $ ; �����������Base
							Scr_Size = Scr_Size, $ ;������������С[X Y]
							Name=Name, $
							BarImage = BarImage, $ ; ��ʾͼ��Ư����
							UName = UName, $ ;����ʶ�����
							UValue = UValue, $ ;�������
							Timer = Timer, $ ;���붯���ٶ�
							GroudStyle = GroudStyle, $ ; ������ѡ��3��,ϵͳ�ṩ
							TypeStyle = TypeStyle, $ ; ����ѡ��5��
							Status_Normal = Status_Normal, $; ��ͨ״̬, ѡ��Ҫ��Ҫ����
							TextColor = TextColor, $ ; ������ɫ
							ToolTip = ToolTip $;
							)

	Return, Obj_Valid(oNiceButton) ? ID : -1 ; �����ʼ���ɹ���������������Base�����򷵻�-1
End