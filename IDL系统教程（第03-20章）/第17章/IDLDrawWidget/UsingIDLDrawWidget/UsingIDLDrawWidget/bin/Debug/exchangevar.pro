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
;IDLDrawWidget����µĲ���IDL��C#�ı�����������
PRO EXCHANGEVAR,var = var
  tmp = DIALOG_MESSAGE(var,/infor, $
    title ='IDL Show Dialog_Message')
  var = StrTrim(var,2)+' com from IDL'
END

