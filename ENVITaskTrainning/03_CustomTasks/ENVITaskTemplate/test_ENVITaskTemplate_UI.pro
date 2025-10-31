PRO test_ENVITaskTemplate_UI

  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)

  taskfile = FILE_DIRNAME(ROUTINE_FILEPATH())+$
    '\ENVITaskTemplate.task'
  Task = ENVITask(taskfile)
  Result = e.UI.SelectTaskParameters(Task)
  ;
  IF Result NE 'OK' THEN return

  Task.Execute

  ;如果显示结果
  IF Task.DISPLAY_RESULT EQ 1 THEN BEGIN
    view = e.GetView()
    layer = view.CreateLayer(Task.OUTPUT_RASTER)
  ENDIF
END