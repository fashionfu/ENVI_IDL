PRO test_ENVILandsat8LSTTask_UI
  COMPILE_OPT idl2
  e=envi()
  ;
  UI = e.UI
  taskfile = FILEPATH('ENVILandsat8LSTTask.task', $
    root_dir=FILE_DIRNAME(ROUTINE_FILEPATH()))

  task = ENVITask(taskfile)
  result = UI.SelectTaskParameters(task)
  IF result NE 'OK' THEN return
  ;
  task.execute

  data = e.DATA
  data.add, task.OUTPUT_RASTER

  view = e.getview()
  layer = view.Createlayer(task.OUTPUT_RASTER)
END