;+
; :Description:
;    �Եر��¶ȷ���Ϊ������ʾ�����������դ���ENVITask����������
;
; :Author: duhj@geoscene.cn
;
; :Date: 2018-3-15 13:46:25
;-

; 辅助函数：从XML文件中提取标签值
FUNCTION extract_xml_tag_value, xmlLines, tagName, defaultValue
  COMPILE_OPT IDL2
  tagStartTag = '<' + tagName + '>'
  tagEndTag = '</' + tagName + '>'
  tagStartLen = STRLEN(tagStartTag)
  FOR i=0, N_ELEMENTS(xmlLines)-1 DO BEGIN
    line = xmlLines[i]
    lineUpper = STRUPCASE(line)
    tagPos = STRPOS(lineUpper, STRUPCASE(tagStartTag))
    IF tagPos GE 0 THEN BEGIN
      tagStart = tagPos + tagStartLen
      tagEnd = STRPOS(lineUpper, STRUPCASE(tagEndTag))
      IF tagEnd GT tagStart THEN BEGIN
        valueStr = STRMID(line, tagStart, tagEnd - tagStart)
        valueStr = STRTRIM(valueStr, 2)
        RETURN, valueStr
      ENDIF
    ENDIF
  ENDFOR
  RETURN, defaultValue
END

; 辅助函数：从MTL TXT文件读取键值对
FUNCTION extract_mtl_txt_value, txtLines, keyName, defaultValue
  COMPILE_OPT IDL2
  keyPattern = keyName + ' ='
  FOR i=0, N_ELEMENTS(txtLines)-1 DO BEGIN
    line = STRTRIM(txtLines[i], 2)
    lineUpper = STRUPCASE(line)
    keyPos = STRPOS(lineUpper, STRUPCASE(keyPattern))
    IF keyPos GE 0 THEN BEGIN
      valueStart = keyPos + STRLEN(keyPattern)
      valueStr = STRMID(line, valueStart)
      valueStr = STRTRIM(valueStr, 2)
      ; 移除可能的引号
      IF (STRMID(valueStr, 0, 1) EQ '"') AND (STRMID(valueStr, STRLEN(valueStr)-1, 1) EQ '"') THEN BEGIN
        valueStr = STRMID(valueStr, 1, STRLEN(valueStr)-2)
      ENDIF
      RETURN, valueStr
    ENDIF
  ENDFOR
  RETURN, defaultValue
END

; 辅助函数：从MTL TXT文件读取投影参数并创建空间参考
FUNCTION create_spatial_ref_from_mtl_txt, mtlTxtFile, nColumns, nRows
  COMPILE_OPT IDL2
  IF ~FILE_TEST(mtlTxtFile) THEN BEGIN
    PRINT, '  错误: MTL TXT文件不存在: ' + mtlTxtFile
    RETURN, !NULL
  ENDIF
  CATCH, errOpen
  IF errOpen EQ 0 THEN BEGIN
    OPENR, lun, mtlTxtFile, /GET_LUN
    txtLines = STRARR(2000)
    lineCount = 0
    WHILE ~EOF(lun) && lineCount LT 2000 DO BEGIN
      READF, lun, txtLines[lineCount]
      lineCount++
    ENDWHILE
    CLOSE, lun
    FREE_LUN, lun
    txtLines = txtLines[0:lineCount-1]
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 无法打开MTL TXT文件: ' + mtlTxtFile
    RETURN, !NULL
  ENDELSE
  utmZone = 50
  datum = 'WGS84'
  pixelSize = 30.0
  ulX = 225900.0
  ulY = 2833200.0
  datumStr = extract_mtl_txt_value(txtLines, 'DATUM', 'WGS84')
  IF STRMATCH(datumStr, '*WGS84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE IF STRMATCH(datumStr, '*WGS-84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE BEGIN
    datum = datumStr
  ENDELSE
  zoneStr = extract_mtl_txt_value(txtLines, 'UTM_ZONE', '50')
  utmZone = FIX(STRTRIM(zoneStr, 2))
  ulXStr = extract_mtl_txt_value(txtLines, 'CORNER_UL_PROJECTION_X_PRODUCT', '225900.0')
  IF STRLEN(ulXStr) GT 0 THEN ulX = FLOAT(STRTRIM(ulXStr, 2))
  ulYStr = extract_mtl_txt_value(txtLines, 'CORNER_UL_PROJECTION_Y_PRODUCT', '2833200.0')
  IF STRLEN(ulYStr) GT 0 THEN ulY = FLOAT(STRTRIM(ulYStr, 2))
  psStr = extract_mtl_txt_value(txtLines, 'GRID_CELL_SIZE_REFLECTIVE', '30.0')
  IF STRLEN(psStr) GT 0 THEN pixelSize = FLOAT(STRTRIM(psStr, 2))
  PRINT, '  正在创建MAP_INFO结构体...'
  mapInfo = !NULL
  CATCH, errMapInfo
  IF errMapInfo EQ 0 THEN BEGIN
    mapInfo = ENVI_MAP_INFO_CREATE( $
      /UTM, $
      ZONE=utmZone, $
      /NORTH, $
      DATUM=datum, $
      MC=[0.0, 0.0, ulX, ulY], $
      PS=[pixelSize, pixelSize] $
    )
    CATCH, /CANCEL
    IF mapInfo EQ !NULL THEN BEGIN
      PRINT, '  错误: ENVI_MAP_INFO_CREATE返回!NULL'
      RETURN, !NULL
    ENDIF
    nElements = N_ELEMENTS(mapInfo)
    IF nElements EQ 0 THEN BEGIN
      PRINT, '  错误: ENVI_MAP_INFO_CREATE返回空结构体'
      RETURN, !NULL
    ENDIF
    PRINT, '  ✓ MAP_INFO结构体创建成功'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 创建MAP_INFO时发生异常: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  RETURN, mapInfo
END

; 辅助函数：从MTL XML文件读取投影参数并创建空间参考
FUNCTION create_spatial_ref_from_mtl_xml, mtlXmlFile, nColumns, nRows
  COMPILE_OPT IDL2
  IF ~FILE_TEST(mtlXmlFile) THEN BEGIN
    PRINT, '  错误: MTL XML文件不存在: ' + mtlXmlFile
    RETURN, !NULL
  ENDIF
  CATCH, errOpen
  IF errOpen EQ 0 THEN BEGIN
    OPENR, lun, mtlXmlFile, /GET_LUN
    xmlLines = STRARR(1000)
    lineCount = 0
    WHILE ~EOF(lun) && lineCount LT 1000 DO BEGIN
      READF, lun, xmlLines[lineCount]
      lineCount++
    ENDWHILE
    CLOSE, lun
    FREE_LUN, lun
    xmlLines = xmlLines[0:lineCount-1]
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 无法打开MTL XML文件: ' + mtlXmlFile
    RETURN, !NULL
  ENDELSE
  utmZone = 50
  datum = 'WGS84'
  pixelSize = 30.0
  ulX = 225900.0
  ulY = 2833200.0
  datumStr = extract_xml_tag_value(xmlLines, 'DATUM', 'WGS84')
  IF STRMATCH(datumStr, '*WGS84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE IF STRMATCH(datumStr, '*WGS-84*') THEN BEGIN
    datum = 'WGS84'
  ENDIF ELSE BEGIN
    datum = datumStr
  ENDELSE
  zoneStr = extract_xml_tag_value(xmlLines, 'UTM_ZONE', '50')
  utmZone = FIX(STRTRIM(zoneStr, 2))
  ulXStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_PROJECTION_X_PRODUCT', '225900.0')
  IF STRLEN(ulXStr) GT 0 THEN ulX = FLOAT(STRTRIM(ulXStr, 2))
  ulYStr = extract_xml_tag_value(xmlLines, 'CORNER_UL_PROJECTION_Y_PRODUCT', '2833200.0')
  IF STRLEN(ulYStr) GT 0 THEN ulY = FLOAT(STRTRIM(ulYStr, 2))
  psStr = extract_xml_tag_value(xmlLines, 'GRID_CELL_SIZE_REFLECTIVE', '30.0')
  IF STRLEN(psStr) GT 0 THEN pixelSize = FLOAT(STRTRIM(psStr, 2))
  PRINT, '  正在创建MAP_INFO结构体...'
  mapInfo = !NULL
  CATCH, errMapInfo
  IF errMapInfo EQ 0 THEN BEGIN
    mapInfo = ENVI_MAP_INFO_CREATE( $
      /UTM, $
      ZONE=utmZone, $
      /NORTH, $
      DATUM=datum, $
      MC=[0.0, 0.0, ulX, ulY], $
      PS=[pixelSize, pixelSize] $
    )
    CATCH, /CANCEL
    IF mapInfo EQ !NULL THEN BEGIN
      PRINT, '  错误: ENVI_MAP_INFO_CREATE返回!NULL'
      RETURN, !NULL
    ENDIF
    nElements = N_ELEMENTS(mapInfo)
    IF nElements EQ 0 THEN BEGIN
      PRINT, '  错误: ENVI_MAP_INFO_CREATE返回空结构体'
      RETURN, !NULL
    ENDIF
    PRINT, '  ✓ MAP_INFO结构体创建成功'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 创建MAP_INFO时发生异常: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  RETURN, mapInfo
END

; 辅助函数：为raster设置空间参考
FUNCTION set_spatial_ref_to_raster, inputRaster, mapInfo
  COMPILE_OPT IDL2
  e = ENVI(/CURRENT)
  IF ~OBJ_VALID(inputRaster) THEN BEGIN
    PRINT, '  错误: inputRaster对象无效'
    RETURN, !NULL
  ENDIF
  PRINT, '  正在导出raster到临时文件...'
  tempDirLocal = 'E:\1027IDL\ENVITaskTrainning\Temp'
  IF ~FILE_TEST(tempDirLocal, /DIRECTORY) THEN FILE_MKDIR, tempDirLocal
  tempBaseName = 'temp_raster_' + STRING(SYSTIME(/JULIAN), FORMAT='(F15.8)') + '.dat'
  tempFile = tempDirLocal + PATH_SEP() + tempBaseName
  IF FILE_TEST(tempFile) THEN FILE_DELETE, tempFile, /QUIET
  hdrFile = FILE_DIRNAME(tempFile) + PATH_SEP() + FILE_BASENAME(tempFile, '.dat') + '.hdr'
  IF FILE_TEST(hdrFile) THEN FILE_DELETE, hdrFile, /QUIET
  exportSuccess = 0
  CATCH, errExport
  IF errExport EQ 0 THEN BEGIN
    inputRaster.Export, tempFile, 'ENVI'
    WAIT, 0.5
    IF FILE_TEST(tempFile) THEN exportSuccess = 1
    CATCH, /CANCEL
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
  ENDELSE
  IF exportSuccess EQ 0 THEN BEGIN
    tempFile = e.GetTemporaryFilename('dat')
    CATCH, errExport2
    IF errExport2 EQ 0 THEN BEGIN
      inputRaster.Export, tempFile, 'ENVI'
      WAIT, 0.5
      IF FILE_TEST(tempFile) THEN exportSuccess = 1
      CATCH, /CANCEL
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  IF exportSuccess EQ 0 THEN BEGIN
    PRINT, '  错误: 导出raster失败'
    RETURN, !NULL
  ENDIF
  PRINT, '  正在设置空间参考信息到文件头...'
  CATCH, errSetup
  IF errSetup EQ 0 THEN BEGIN
    ENVI_OPEN_FILE, tempFile, r_fid=fid
    ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=nb, data_type=dt, interleave=interleave
    ENVI_SETUP_HEAD, $
      FNAME=tempFile, $
      NS=ns, $
      NL=nl, $
      NB=nb, $
      DATA_TYPE=dt, $
      INTERLEAVE=interleave, $
      MAP_INFO=mapInfo, $
      /WRITE, /OPEN
    ENVI_FILE_MNG, id=fid, /REMOVE
    CATCH, /CANCEL
    PRINT, '  ✓ 空间参考信息已写入文件头'
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
    PRINT, '  错误: 设置空间参考时发生错误: ' + !ERROR_STATE.MSG
    RETURN, !NULL
  ENDELSE
  outputRaster = e.OpenRaster(tempFile)
  IF OBJ_VALID(outputRaster) THEN BEGIN
    PRINT, '  ✓ 成功重新打开raster'
  ENDIF ELSE BEGIN
    PRINT, '  错误: 重新打开raster失败'
    RETURN, !NULL
  ENDELSE
  RETURN, outputRaster
END

PRO test_Landsat8_LST_workflow
  COMPILE_OPT idl2
  e=envi()
  ;
  mtl_file = 'E:\1021WaterData\201\0-原始数据\LC81240382017118LGN00\LC81240382017118LGN00_MTL.txt'

  ;�򿪶���׺��Ⱥ���ͼ��
  mss_raster = e.OpenRaster(mtl_file, DATASET_NAME='Multispectral')
  the_raster = e.OpenRaster(mtl_file, DATASET_NAME='Thermal')

  ;��ȡK1��K2
  k1 = (the_raster.METADATA['THERMAL K1'])[0] & k1=STRTRIM(k1,2)
  k2 = (the_raster.METADATA['THERMAL K2'])[0] & k2=STRTRIM(k2,2)

  tic
  ;��������̣�QUAC>NDVI>ֲ�����Ƕ�>�ر�ȷ�����
  ;  quac_raster = ENVIQUACRaster(mss_raster, sensor='Landsat TM/ETM/OLI')
  ndvi_raster = ENVISpectralIndexRaster(mss_raster, 'ndvi')
  veg_exp = '(b1 GT 0.7)*1+(b1 LT 0.05)*0+(b1 GE 0.05 AND b1 LE 0.7)*((b1-0.05)/(0.7-0.05))'
  veg_raster = ENVIPixelwiseBandMathRaster(ndvi_raster, veg_exp)
  ratio_exp = '0.004*b1+0.986'
  ratio_raster = ENVIPixelwiseBandMathRaster(veg_raster, ratio_exp)

  ;�Ⱥ������̣����βü�>���䶨��
  b10_raster = ENVISubsetRaster(the_raster, bands=[0])
  b10rad_raster = ENVICalibrateRaster(b10_raster, calibration='Radiance')

  ;��Ҫ�Ƴ�b10rad_raster��K1��K2Ԫ���ݣ������ڲ������ʱ�ᱨ��
  b10rad_raster.METADATA.RemoveItem, 'THERMAL K1'
  b10rad_raster.METADATA.RemoveItem, 'THERMAL K2'

  ;����õ�ͬ�¶��µĺ����������ͼ��
  ;(b2-0.75-0.9*(1-b1)*1.29)/(0.9*b1)
  ;b1���ر�ȷ�����ͼ��
  ;b2��Band10��������ͼ��
  ;�������b1��b2���������
  ; 参考landsat9_spectral_indices.pro的做法，找到有空间参考的raster来创建grid definition
  gridDefRaster = !NULL
  ; 按优先级检查：mss_raster > the_raster > b10rad_raster
  CATCH, errCheckSR1
  IF errCheckSR1 EQ 0 THEN BEGIN
    tempSR = mss_raster.SPATIALREF
    CATCH, /CANCEL
    IF OBJ_VALID(tempSR) THEN BEGIN
      gridDefRaster = mss_raster
    ENDIF
  ENDIF ELSE BEGIN
    CATCH, /CANCEL
  ENDELSE
  
  IF ~OBJ_VALID(gridDefRaster) THEN BEGIN
    CATCH, errCheckSR2
    IF errCheckSR2 EQ 0 THEN BEGIN
      tempSR = the_raster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(tempSR) THEN BEGIN
        gridDefRaster = the_raster
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  
  IF ~OBJ_VALID(gridDefRaster) THEN BEGIN
    CATCH, errCheckSR3
    IF errCheckSR3 EQ 0 THEN BEGIN
      tempSR = b10rad_raster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(tempSR) THEN BEGIN
        gridDefRaster = b10rad_raster
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  
  ; 如果所有raster都没有空间参考，从MTL文件读取并添加空间参考
  IF ~OBJ_VALID(gridDefRaster) THEN BEGIN
    PRINT, '检测到所有raster都没有空间参考，正在从MTL文件读取并添加空间参考...'
    mapInfo = !NULL
    
    ; 方法1：先尝试从MTL.txt文件读取（Landsat 8通常只有TXT文件）
    IF FILE_TEST(mtl_file) THEN BEGIN
      PRINT, '尝试从MTL TXT文件读取空间参考: ' + FILE_BASENAME(mtl_file)
      mapInfo = create_spatial_ref_from_mtl_txt(mtl_file, mss_raster.NCOLUMNS, mss_raster.NROWS)
      IF mapInfo NE !NULL THEN BEGIN
        PRINT, '✓ 成功从MTL TXT文件创建空间参考信息'
      ENDIF
    ENDIF
    
    ; 方法2：如果TXT文件失败，尝试从MTL XML文件读取（Landsat 9可能有XML文件）
    IF mapInfo EQ !NULL THEN BEGIN
      mtlXmlFile = FILE_DIRNAME(mtl_file) + PATH_SEP() + FILE_BASENAME(mtl_file, '.txt') + '.xml'
      IF ~FILE_TEST(mtlXmlFile) THEN BEGIN
        mtlXmlFile = FILE_DIRNAME(mtl_file) + PATH_SEP() + FILE_BASENAME(mtl_file, '_MTL.txt') + '_MTL.xml'
      ENDIF
      IF FILE_TEST(mtlXmlFile) THEN BEGIN
        PRINT, '尝试从MTL XML文件读取空间参考: ' + FILE_BASENAME(mtlXmlFile)
        mapInfo = create_spatial_ref_from_mtl_xml(mtlXmlFile, mss_raster.NCOLUMNS, mss_raster.NROWS)
        IF mapInfo NE !NULL THEN BEGIN
          PRINT, '✓ 成功从MTL XML文件创建空间参考信息'
        ENDIF
      ENDIF
    ENDIF
    
    ; 如果成功创建了空间参考，为mss_raster添加空间参考
    IF mapInfo NE !NULL THEN BEGIN
      ; 保存mapInfo以便后续使用
      mapInfoForStack = mapInfo
      mss_raster_with_sr = set_spatial_ref_to_raster(mss_raster, mapInfo)
      IF OBJ_VALID(mss_raster_with_sr) THEN BEGIN
        ; 关闭原始raster，使用新的raster
        mss_raster.Close
        mss_raster = mss_raster_with_sr
        gridDefRaster = mss_raster
        PRINT, '✓ 成功为mss_raster添加空间参考信息'
      ENDIF ELSE BEGIN
        PRINT, '警告: 为mss_raster添加空间参考失败，将使用原始raster'
        gridDefRaster = mss_raster
      ENDELSE
    ENDIF ELSE BEGIN
      PRINT, '错误: 无法从MTL文件创建空间参考信息'
      PRINT, '  请检查MTL文件是否存在且包含投影参数'
      gridDefRaster = mss_raster
    ENDELSE
  ENDIF
  
  ; 如果gridDefRaster有空间参考但mapInfoForStack为空，重新读取
  IF (mapInfoForStack EQ !NULL) AND OBJ_VALID(gridDefRaster) THEN BEGIN
    spatialRef = !NULL
    CATCH, errGetSR
    IF errGetSR EQ 0 THEN BEGIN
      spatialRef = gridDefRaster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(spatialRef) THEN BEGIN
        ; 如果gridDefRaster有空间参考，从MTL文件重新读取mapInfo
        IF FILE_TEST(mtl_file) THEN BEGIN
          mapInfoForStack = create_spatial_ref_from_mtl_txt(mtl_file, gridDefRaster.NCOLUMNS, gridDefRaster.NROWS)
        ENDIF
      ENDIF
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
  ENDIF
  
  gridTask = ENVITask('BuildGridDefinitionFromRaster')
  gridTask.INPUT_RASTER = gridDefRaster
  gridTask.Execute
  
  ; 在堆叠之前，确保ratio_raster和b10rad_raster也有空间参考
  
  ; 如果成功获取了mapInfo，为缺少空间参考的raster添加空间参考
  IF mapInfoForStack NE !NULL THEN BEGIN
    ; 检查ratio_raster是否有空间参考
    ratioHasSR = 0
    CATCH, errCheckRatioSR
    IF errCheckRatioSR EQ 0 THEN BEGIN
      tempSR = ratio_raster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(tempSR) THEN ratioHasSR = 1
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
    
    IF ratioHasSR EQ 0 THEN BEGIN
      PRINT, '检测到ratio_raster缺少空间参考，正在添加...'
      ratio_raster_with_sr = set_spatial_ref_to_raster(ratio_raster, mapInfoForStack)
      IF OBJ_VALID(ratio_raster_with_sr) THEN BEGIN
        ratio_raster.Close
        ratio_raster = ratio_raster_with_sr
        PRINT, '✓ 成功为ratio_raster添加空间参考信息'
      ENDIF
    ENDIF
    
    ; 检查b10rad_raster是否有空间参考
    b10radHasSR = 0
    CATCH, errCheckB10radSR
    IF errCheckB10radSR EQ 0 THEN BEGIN
      tempSR = b10rad_raster.SPATIALREF
      CATCH, /CANCEL
      IF OBJ_VALID(tempSR) THEN b10radHasSR = 1
    ENDIF ELSE BEGIN
      CATCH, /CANCEL
    ENDELSE
    
    IF b10radHasSR EQ 0 THEN BEGIN
      PRINT, '检测到b10rad_raster缺少空间参考，正在添加...'
      b10rad_raster_with_sr = set_spatial_ref_to_raster(b10rad_raster, mapInfoForStack)
      IF OBJ_VALID(b10rad_raster_with_sr) THEN BEGIN
        b10rad_raster.Close
        b10rad_raster = b10rad_raster_with_sr
        PRINT, '✓ 成功为b10rad_raster添加空间参考信息'
      ENDIF
    ENDIF
  ENDIF
  
  ls_raster = ENVILayerStackRaster([ratio_raster, b10rad_raster], $
    grid_definition=gridTask.OUTPUT_GRIDDEFINITION)
  black_exp = '(b2-0.75-0.9*(1-b1)*1.29)/(0.9*b1)'
  black_raster = ENVIPixelwiseBandMathRaster(ls_raster, black_exp)

  ;����ر��¶�
  ;(1321.08)/alog(774.89/b1+1)-273
  Task = ENVITask('PixelwiseBandMathRaster')
  Task.INPUT_RASTER = black_raster
  Task.EXPRESSION = k2+'/alog('+k1+'/b1+1)-273.15'
  Task.Execute
  toc

  ;�����ӵ�Data Manager
  DataColl = e.DATA
  DataColl.Add, Task.OUTPUT_RASTER
  ;��ʾ���
  View1 = e.GetView()
  Layer1 = View1.CreateLayer(Task.OUTPUT_RASTER)
END
