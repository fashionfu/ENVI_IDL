PRO test_SavitzkyGolayFilterTask_UI

  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)

  taskfile = FILE_DIRNAME(ROUTINE_FILEPATH())+$
    '\test_SavitzkyGolayFilterTask.task'
  Task = ENVITask(taskfile)
  Result = e.UI.SelectTaskParameters(Task)
  ;
  IF Result NE 'OK' THEN return

  Task.Execute

  ;�����ʾ���
  IF Task.DISPLAY_RESULT EQ 1 THEN BEGIN
    view = e.GetView()
    layer = view.CreateLayer(Task.OUTPUT_RASTER)
  ENDIF
END