PRO test_IDLffShape

  file = FILEPATH('qb_boulder_msi_vectors.shp', $
    root_dir=FILE_DIRNAME(!dir), subdirectory='data')

  ;初始化对象
  oshp = OBJ_NEW('IDLffShape', file)

  ;获取属性
  oshp.GetProperty, n_entities=num_ent, $
    entity_type=ent_type

  ;打印属性
  PRINT, 'Number of Entities: ', num_ent
  PRINT, 'Entity Type: ', ent_type

  ;销毁对象
  OBJ_DESTROY, oshp
END