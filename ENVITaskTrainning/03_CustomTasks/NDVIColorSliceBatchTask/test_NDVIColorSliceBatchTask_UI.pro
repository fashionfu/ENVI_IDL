PRO test_NDVIColorSliceBatchTask_UI
  COMPILE_OPT idl2
  e=envi()
  ;
  UI = e.UI
  taskfile = FILEPATH('NDVIColorSliceBatchTask.task', $
    root_dir=FILE_DIRNAME(ROUTINE_FILEPATH()))

  task = ENVITask(taskfile)
  result = UI.SelectTaskParameters(task)
  IF result NE 'OK' THEN return
  ;
  task.execute

END