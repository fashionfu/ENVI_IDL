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
;IDLDrawWidget����µĲ���IDL��C#�������������
PRO EXCHANGEARR,arr,oriArr= oriArr
  tmp = DIALOG_MESSAGE(STRING(arr),/infor,$
    title ='IDL Show Dialog_Message')
  oriArr = arr
  arr = arr+3
END
