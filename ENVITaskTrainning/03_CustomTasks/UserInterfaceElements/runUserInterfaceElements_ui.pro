PRO runUserInterfaceElements_ui
  COMPILE_OPT IDL2, HIDDEN
  e = ENVI()

  ; Run the custom task
  taskFile = FILEPATH('UserInterfaceElements.task', root_dir=ROUTINE_DIR())
  Task = ENVITask(taskFile)

  ;µ¯³ö½çÃæ
  dynamicUI = e.UI.SelectTaskParameters(Task)
  IF (dynamicUI NE 'OK') THEN RETURN
  Task.Execute
END