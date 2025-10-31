;过程
PRO HelloWorld
  ;弹出对话框
  result=DIALOG_MESSAGE('Hello IDL',$
    /information,title='Hi')
  PRINT, result
END