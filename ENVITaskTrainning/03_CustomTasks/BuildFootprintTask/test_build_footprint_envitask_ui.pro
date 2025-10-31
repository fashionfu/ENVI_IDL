PRO test_Build_Footprint_ENVITask_UI
  COMPILE_OPT idl2
  e=envi()
  ;
  UI = e.UI
  taskfile = FILE_DIRNAME(ROUTINE_FILEPATH())+$
    '\test_build_Footprint_envitask.task'
  task = ENVITask(taskfile)
  result = UI.SelectTaskParameters(task)
  IF result NE 'OK' THEN return
  ;
  task.execute
END