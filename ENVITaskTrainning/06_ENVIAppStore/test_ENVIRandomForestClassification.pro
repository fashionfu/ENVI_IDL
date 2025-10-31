PRO test_ENVIRandomForestClassification
  COMPILE_OPT idl2
  e=envi()
  ;������������ļ�·��
  input_file = FILEPATH('ag_08_quac.dat', root_dir=ROUTINE_DIR(), subdirectory=['data'])
  roi_file = FILEPATH('08_TrainingSample.xml', root_dir=ROUTINE_DIR(), subdirectory=['data'])
  out_file = e.GetTemporaryFilename()

  ;��դ���ѵ������
  raster = e.OpenRaster(input_file)
  rois = e.OpenROI(roi_file)

  ;���ɭ�ַ���
  task = ENVITask('RandomForestClassification')
  task.input_raster = raster
  task.input_rois = rois
  task.numberOfTrees = 10 ;Ϊ�����̲���ʱ�䣬Ĭ��100
  task.showMsg = 0 ;����ʾ��ʾ�Ի���
  task.display = 0 ;���Զ���ʾ���
  ;task.output_raster_uri = ;������������·�������������ʱ�ļ���
  task.Execute

  ;��Ĥ����
  shp_file = FILEPATH('mask.shp', root_dir=ROUTINE_DIR(), subdirectory=['data','maskshp'])
  ovector = e.OpenVector(shp_file)
  ;���βü�
  sub_raster = ENVISubsetRaster(task.output_raster, sub_rect=ovector.DATA_RANGE, $
    spatialref=ovector.COORD_SYS)
  ;ʸ����Ĥ����
  masktask = ENVITask('VectorMaskRaster')
  masktask.input_raster = sub_raster
  masktask.input_mask_vector = ovector
  masktask.data_ignore_value = 0
  masktask.output_raster_uri = out_file
  masktask.Execute

  ;������Ĥ�����ͼ��
  e.data.add, masktask.output_raster
  view = e.GetView()
  layer = view.CreateLayer(masktask.output_raster)
END