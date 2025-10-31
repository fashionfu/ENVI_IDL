PRO test_VirtualRaster
  COMPILE_OPT idl2
  e = ENVI()
  view = e.GetView()

  ;ȫɫ�Ͷ��������
  highFile = FILEPATH('qb_boulder_pan', $
    Subdir=['data'], Root_Dir=e.ROOT_DIR)
  lowFile = FILEPATH('qb_boulder_msi',  $
    Subdir=['data'], Root_Dir=e.ROOT_DIR)

  ;��դ��ͼ��
  highRaster = e.OpenRaster(highFile)
  lowRaster = e.OpenRaster(lowFile)

  ;��ʾԭʼ���������
  lowLayer = View.CreateLayer(lowRaster)
  View.Zoom, 1, /full_extent

  ;��ԭʼ���ݽ��пռ�ü�
  lowSubRaster = ENVISubsetRaster(lowRaster, sub_rect=[100,100,924,924])
  ;�Բü���������NNDiffuseͼ���ں�
  NNDRaster = ENVINNDiffusePanSharpeningRaster(lowSubRaster,highRaster)
  ;��ʾ�ںϽ������������ʾ
  nndLayer = View.CreateLayer(NNDRaster)
  nndLayer.QUICK_STRETCH = 'no stretch'
  ;
  ;���ںϽ���������죬����ʾ�����ͼ��
  stretchRaster = ENVILinearPercentStretchRaster(NNDRaster, percent=2.0)
  stretchLayer = View.CreateLayer(stretchRaster)
  stretchlayer.QUICK_STRETCH = 'No Stretch'
  ;
  rgbRaster = ENVISubsetRaster(stretchRaster, bands=[2,1,0])
  rgbFile = e.GetTemporaryFilename('tif')
  rgbRaster.Export, rgbFile, 'tiff'
  PRINT, rgbFile
  SPAWN, rgbFile, /hide
END
