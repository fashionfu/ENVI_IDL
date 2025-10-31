; ENVI Extension code. Called when the toolbox item is chosen.
PRO test_ENVIWaterExtractionTask_UI

  ; Set compile options
  COMPILE_OPT IDL2
  e = ENVI()

  taskfile=FILE_DIRNAME(ROUTINE_FILEPATH())+$
    '\test_ENVIWaterExtractionTask.task'
  task = ENVITask(taskfile)
  ui=e.UI
  r=ui.SelectTaskParameters(task)

  IF r NE 'OK' THEN return
  task.Execute

  ;ÏÔÊ¾½á¹û
  view = e.GetView()
  layer = view.Createlayer(task.OUTPUT_RASTER, error=err)
  dataCol = e.DATA
  dataCol.Add, task.OUTPUT_VECTOR, error=err
  layer = view.Createlayer(task.OUTPUT_VECTOR, error=err)
END