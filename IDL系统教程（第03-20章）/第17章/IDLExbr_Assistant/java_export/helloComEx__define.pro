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

;��д����MessageFrom����Ӧ���鴫��
FUNCTION helloComEx::ArrayTest, array
  ;��ȡ�������Ϣ
  type = SIZE(array,/type)
  dims = SIZE(array,/dimension)
  tmp = DIALOG_MESSAGE('������ϢDims[0]��'+STRTRIM(dims[0]),/infor)
  tmp = DIALOG_MESSAGE('������ϢDims[1]��'+STRTRIM(dims[1]),/infor)
  RETURN,array+2
END
;��д����MessageFrom���ַ�������
FUNCTION helloComEx::MessageFrom, input
  ;�������ʱ�б������룬�򵯳���Ϣ
  IF (N_ELEMENTS(input) NE 0) THEN self.MESSAGE = "Hello World from " + input $
  ELSE self.MESSAGE = 'Hello World'
  tmp = DIALOG_MESSAGE(self.MESSAGE,title = 'IDL',/infor)
  ;����tmp
  RETURN, tmp
END
; �������ʼ������.
FUNCTION helloComEx::INIT
  RETURN, 1
END
; �����ඨ�����
PRO HELLOCOMEX__DEFINE
  struct = {helloComEx, $
    message: ' ' }
END