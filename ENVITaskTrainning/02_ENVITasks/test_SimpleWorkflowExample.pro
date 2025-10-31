PRO test_SimpleWorkflowExample
  COMPILE_OPT IDL2
  e = ENVI()
  ;��ʼ��������
  workflow = ENVIWorkflow(title='ISODATA Workflow')
  ;����1��QUAC
  step1 = ENVIWorkflowStep(timeline_title='QUAC')
  step1.TASK = ENVITask('QUAC')
  ;����2��ISODATA����
  step2 = ENVIWorkflowStep()
  step2.TASK = ENVITask('ISODATAClassification')
  ;����3�������ƽ������
  step3 = ENVIWorkflowStep()
  step3.TASK = ENVITask('ClassificationSmoothing')
  ;����4�����TIFF��ʽ
  step4 = ENVIWorkflowStep()
  step4.TASK = ENVITask('ExportRasterToTIFF')
  ;��������
  workflow.Connect, step1, 'OUTPUT_RASTER', step2, 'INPUT_RASTER'
  workflow.Connect, step2, 'OUTPUT_RASTER', step3, 'INPUT_RASTER
  workflow.Connect, step3, 'OUTPUT_RASTER', step4, 'INPUT_RASTER'
  ;��ʾ����������
  ENVI.UI.CreateWorkflowDialog, workflow
END