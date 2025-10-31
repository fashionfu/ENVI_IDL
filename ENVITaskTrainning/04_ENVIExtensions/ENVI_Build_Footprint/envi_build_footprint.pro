; Add the extension to the toolbox. Called automatically on ENVI startup.
PRO ENVI_Build_Footprint_extensions_init

  ; Set compile options
  COMPILE_OPT IDL2

  ; Get ENVI session
  e = ENVI(/CURRENT)

  ; Add the extension to a subfolder
  e.AddExtension, 'Build Footprint', 'ENVI_Build_Footprint', PATH=''
END

; ENVI Extension code. Called when the toolbox item is chosen.
PRO ENVI_Build_Footprint

  ; Set compile options
  COMPILE_OPT IDL2

  ; General error handler
  CATCH, err
  IF (err NE 0) THEN BEGIN
    CATCH, /CANCEL
    IF OBJ_VALID(e) THEN $
      e.ReportError, 'ERROR: ' + !ERROR_STATE.MSG
    MESSAGE, /RESET
    RETURN
  ENDIF

  ;Get ENVI session
  e = ENVI(/CURRENT)

  ;******************************************
  ; Insert your ENVI Extension code here...
  ;******************************************

  Task = ENVITask('BuildFootprint')
  UI = e.UI
  result = UI.SelectTaskParameters(Task)
  IF result NE 'OK' THEN return
  Task.Execute

  view = e.GetView()
  layer = view.CreateLayer(Task.OUTPUT_VECTOR)
END