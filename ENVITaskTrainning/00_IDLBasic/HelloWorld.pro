;����
PRO HelloWorld
  ;�����Ի���
  result=DIALOG_MESSAGE('Hello IDL',$
    /information,title='Hi')
  PRINT, result
END