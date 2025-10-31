PRO test_VirtualRaster
  COMPILE_OPT idl2
  e = ENVI()
  view = e.GetView()

  ;全色和多光谱数据
  highFile = FILEPATH('qb_boulder_pan', $
    Subdir=['data'], Root_Dir=e.ROOT_DIR)
  lowFile = FILEPATH('qb_boulder_msi',  $
    Subdir=['data'], Root_Dir=e.ROOT_DIR)

  ;打开栅格图像
  highRaster = e.OpenRaster(highFile)
  lowRaster = e.OpenRaster(lowFile)

  ;显示原始多光谱数据
  lowLayer = View.CreateLayer(lowRaster)
  View.Zoom, 1, /full_extent

  ;对原始数据进行空间裁剪
  lowSubRaster = ENVISubsetRaster(lowRaster, sub_rect=[100,100,924,924])
  ;对裁剪后结果进行NNDiffuse图像融合
  NNDRaster = ENVINNDiffusePanSharpeningRaster(lowSubRaster,highRaster)
  ;显示融合结果，不拉伸显示
  nndLayer = View.CreateLayer(NNDRaster)
  nndLayer.QUICK_STRETCH = 'no stretch'
  ;
  ;对融合结果进行拉伸，并显示拉伸后图像
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
