PRO test_IDLffShape

  file = FILEPATH('qb_boulder_msi_vectors.shp', $
    root_dir=FILE_DIRNAME(!dir), subdirectory='data')

  ;��ʼ������
  oshp = OBJ_NEW('IDLffShape', file)

  ;��ȡ����
  oshp.GetProperty, n_entities=num_ent, $
    entity_type=ent_type

  ;��ӡ����
  PRINT, 'Number of Entities: ', num_ent
  PRINT, 'Entity Type: ', ent_type

  ;���ٶ���
  OBJ_DESTROY, oshp
END