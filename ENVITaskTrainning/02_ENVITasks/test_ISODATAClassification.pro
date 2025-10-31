PRO test_ISODATAClassification
  COMPILE_OPT idl2
  
  ;����ENVI
  e = ENVI()

  ;��դ��
  file = FILEPATH('qb_boulder_msi', subdirectory=['data'], root_dir=e.ROOT_DIR)
  raster = e.OpenRaster(file)

  ;��ʼ��ENVITask�����Ե��� task.parameterNames() ��ȡ���в���
  task = ENVITask('ISODATAClassification')

  ;����ENVITask����
  task.INPUT_RASTER = raster
  task.NUMBER_OF_CLASSES = 5
  task.ITERATIONS = 1 ;��������Ϊ1����ʡ��ʾʱ��
  ;�������·�����������ã����������ʱĿ¼���ڹر�ENVIʱ���Զ����
  ;task.OUTPUT_RASTER_URI = 'C:\temp\isodata.dat'

  ;ִ��ENVITask
  task.Execute

  ;��ȡ������
  output_raster = task.OUTPUT_RASTER

  ;��ӽ����Data Manager��������ʾ
  e.DATA.Add, output_raster
  view = e.GetView()
  layer = view.CreateLayer(output_raster)
END

