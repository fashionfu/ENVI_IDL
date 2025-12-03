# Landsat数据空间参考坐标系添加与图像镶嵌完整指南

## 目录
1. [概述](#概述)
2. [Landsat数据空间参考坐标系添加方法](#landsat数据空间参考坐标系添加方法)
3. [ENVI格式(.dat)保存的必要性](#envi格式dat保存的必要性)
4. [空间参考信息保存的正确方法](#空间参考信息保存的正确方法)
5. [图像镶嵌操作指南](#图像镶嵌操作指南)
6. [常见问题与解决方案](#常见问题与解决方案)

---

## 概述
![影像镶嵌结果](https://github.com/fashionfu/ENVI_IDL/blob/main/%E5%AD%A6%E4%B9%A0%E8%BF%87%E7%A8%8B/1206_%E9%95%B6%E5%B5%8C%E7%BB%93%E6%9E%9C.png)

本工具集用于处理Landsat Level 2 (L2)数据，主要包括：
- **1206_batch_soil_EC.pro**: 批量计算土壤电导率EC，并确保输出文件包含正确的空间参考信息
- **1206_mosaic_rasters.pro**: 图像镶嵌工具，支持不同投影系统的自动重投影
- **1206_read_geotiff_spatial_ref.pro**: 从GeoTIFF文件读取空间参考信息的工具

**核心原则**: 所有输出文件必须使用ENVI格式(.dat)保存，以确保空间参考坐标系信息被正确保留。

---

## Landsat数据空间参考坐标系添加方法

### 1. 问题背景

Landsat L2数据在处理过程中，从MTL文件打开的Surface Reflectance数据可能缺少空间参考信息。传统的MTL XML/TXT解析方法在某些环境下可能失败（编码问题、API不支持等）。

### 2. 解决方案：从GeoTIFF文件直接读取

**核心思路**: 不再依赖MTL文件解析，而是直接从Landsat L2数据包中的GeoTIFF波段文件（`*_SR_B3.TIF`或`*_SR_B4.TIF`）读取空间参考信息。

### 3. 两种读取方法

#### 方法1: 使用 `ENVI_OPEN_DATA_FILE` + `/TIFF` 关键字（优先方法）

```idl
ENVI_OPEN_DATA_FILE, geotiffFile, /TIFF, R_FID=fid
IF fid NE -1 THEN BEGIN
  ; 获取投影信息
  ENVI_FILE_QUERY, fid, coord_sys=coordSys
  ; 获取像元大小和坐标
  ENVI_GET_MAP_INFO, fid, map_info=mapInfo
  ; 从mapInfo中提取信息
  pixelSize = mapInfo.PS[0]
  ulX = mapInfo.MC[2]  ; 左上角X坐标
  ulY = mapInfo.MC[3]  ; 左上角Y坐标
  utmZone = mapInfo.ZONE
  datum = mapInfo.DATUM
ENDIF
```

**优点**:
- 直接使用ENVI API，兼容性好
- 读取速度快
- 自动解析投影参数

#### 方法2: 使用 `READ_TIFF` + `GEOTIFF` 参数（备用方法）

```idl
img = READ_TIFF(geotiffFile, GEOTIFF=GeoKeys, SUB_RECT=[0, 0, 1, 1])
IF N_ELEMENTS(GeoKeys) GT 0 THEN BEGIN
  ; 提取像元大小
  pixelScale = GeoKeys.MODELPIXELSCALETAG
  pixelSize = pixelScale[0]
  
  ; 提取左上角坐标
  tiePoint = GeoKeys.MODELTIEPOINTTAG
  ulX = tiePoint[3]
  ulY = tiePoint[4]
  
  ; 提取UTM Zone（从字符串解析）
  citation = GeoKeys.GTCITATIONGEOKEY
  ; 解析UTM Zone...
ENDIF
```

**优点**:
- 直接读取GeoTIFF元数据
- 不依赖ENVI API
- 可以获取完整的GeoTIFF标签信息

### 4. 创建MAP_INFO结构

读取到空间参考信息后，使用`ENVI_MAP_INFO_CREATE`创建MAP_INFO结构：

```idl
mapInfo = ENVI_MAP_INFO_CREATE( $
  /UTM, $
  ZONE=utmZone, $
  /NORTH, $
  DATUM='WGS-84', $
  MC=[0.0, 0.0, ulX, ulY], $  ; [x, y, mapX, mapY]
  PS=[pixelSize, pixelSize] $  ; 像元大小
)
```

### 5. 将空间参考应用到Raster对象

```idl
; 创建ENVIStandardRasterSpatialRef对象
spatialRef = ENVIStandardRasterSpatialRef(COORD_SYS_STR=coordSysStr, $
  PIXEL_SIZE=[pixelSize, -pixelSize], $
  TIE_POINT_PIXEL=[0.0, 0.0], $
  TIE_POINT_MAP=[ulX, ulY])

; 应用到raster
raster.SPATIALREF = spatialRef
```

---

## ENVI格式(.dat)保存的必要性

### 1. 为什么必须使用ENVI格式？

**TIFF格式的问题**:
- ENVI的`raster.Export`方法在导出TIFF格式时，**无法可靠地保存空间参考信息**
- 即使使用`ENVITask('RasterExport')`，TIFF格式的空间参考信息也可能丢失
- TIFF格式的空间参考信息存储在GeoTIFF标签中，但ENVI的导出机制可能不完整

**ENVI格式的优势**:
- ENVI格式(.dat + .hdr)可以完整保存所有空间参考信息
- 使用`ENVI_SETUP_HEAD`函数可以直接写入MAP_INFO到文件头
- 空间参考信息存储在.hdr文件中，格式稳定可靠

### 2. 空间参考信息丢失的后果

如果空间参考信息丢失：
- 影像无法正确显示在地理坐标系中
- 无法进行地理配准
- 无法与其他地理数据进行叠加分析
- 镶嵌操作会失败（提示"No standard map projection"）

---

## 空间参考信息保存的正确方法

### 核心策略：临时文件 + ENVI_SETUP_HEAD

为了确保空间参考信息被正确保存，采用以下两步法：

1. **先导出到临时ENVI文件**
2. **使用ENVI_SETUP_HEAD写入空间参考信息到文件头**
3. **从临时文件导出到最终ENVI格式**

### 方法1: 直接Export（最简单）

```idl
; 步骤1: 导出到临时ENVI文件
tempFile = e.GetTemporaryFilename('dat')
ec_raster.Export, tempFile, 'ENVI'
WAIT, 0.5

; 步骤2: 使用ENVI_SETUP_HEAD设置空间参考
ENVI_OPEN_FILE, tempFile, r_fid=fid
IF fid GE 0 THEN BEGIN
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=nb, data_type=dt, interleave=interleave
  ENVI_SETUP_HEAD, $
    FNAME=tempFile, $
    NS=ns, NL=nl, NB=nb, DATA_TYPE=dt, INTERLEAVE=interleave, $
    MAP_INFO=exportMapInfo, /WRITE, /OPEN
  ENVI_FILE_MNG, id=fid, /REMOVE
ENDIF

; 步骤3: 从临时文件导出到最终文件
tempRaster = e.OpenRaster(tempFile)
tempRaster.Export, outfile, 'ENVI'

; 步骤4: 再次使用ENVI_SETUP_HEAD确保空间参考写入
ENVI_OPEN_FILE, outfile, r_fid=fidFinal
IF fidFinal GE 0 THEN BEGIN
  ENVI_FILE_QUERY, fidFinal, ns=nsFinal, nl=nlFinal, nb=nbFinal, $
    data_type=dtFinal, interleave=interleaveFinal
  ENVI_SETUP_HEAD, $
    FNAME=outfile, $
    NS=nsFinal, NL=nlFinal, NB=nbFinal, DATA_TYPE=dtFinal, $
    INTERLEAVE=interleaveFinal, $
    MAP_INFO=exportMapInfo, /WRITE, /OPEN
  ENVI_FILE_MNG, id=fidFinal, /REMOVE
ENDIF
```

### 方法2: 使用GetTemporaryFilename（容错）

如果方法1失败，使用ENVI的GetTemporaryFilename方法：

```idl
tempFile = e.GetTemporaryFilename('dat')
ec_raster.Export, tempFile, 'ENVI'
; ... 后续步骤同方法1
```

### 方法3: 使用RasterExport任务（如果可用）

```idl
exportTask = ENVITask('RasterExport')
exportTask.INPUT_RASTER = ec_raster
exportTask.OUTPUT_RASTER_URI = tempFile
exportTask.FORMAT = 'ENVI'
exportTask.Execute
; ... 后续步骤同方法1
```

**注意**: 某些ENVI版本可能不支持`RasterExport`任务，需要检查。

### 方法4: 使用ExportRasterToENVI任务（备用）

```idl
exportTask2 = ENVITask('ExportRasterToENVI')
exportTask2.INPUT_RASTER = ec_raster
exportTask2.OUTPUT_RASTER_URI = tempFile
exportTask2.Execute
; ... 后续步骤同方法1
```

### 完整容错流程

在实际代码中，应该按顺序尝试所有方法，直到成功：

```idl
exportSuccess = 0

; 尝试方法1
IF exportSuccess EQ 0 THEN BEGIN
  ; 方法1代码...
  IF 成功 THEN exportSuccess = 1
ENDIF

; 尝试方法2
IF exportSuccess EQ 0 THEN BEGIN
  ; 方法2代码...
  IF 成功 THEN exportSuccess = 1
ENDIF

; 尝试方法3
IF exportSuccess EQ 0 THEN BEGIN
  ; 方法3代码...
  IF 成功 THEN exportSuccess = 1
ENDIF

; 尝试方法4
IF exportSuccess EQ 0 THEN BEGIN
  ; 方法4代码...
  IF 成功 THEN exportSuccess = 1
ENDIF

; 如果所有方法都失败
IF exportSuccess EQ 0 THEN BEGIN
  PRINT, '错误: 所有导出方法都失败'
  RETURN
ENDIF
```

### 关键要点

1. **必须使用ENVI格式**: 所有导出都使用`'ENVI'`格式，不使用`'TIFF'`或`'GTiff'`
2. **必须使用ENVI_SETUP_HEAD**: 这是确保空间参考信息写入文件头的关键步骤
3. **双重验证**: 在临时文件和最终文件都使用ENVI_SETUP_HEAD
4. **验证空间参考**: 导出后重新打开文件，验证SPATIALREF对象是否存在

---

## 图像镶嵌操作指南

### 1. 功能概述

`1206_mosaic_rasters.pro`提供了完整的图像镶嵌功能，包括：
- 自动检测和处理不同投影系统
- 自动补充缺失的空间参考信息
- 统一data ignore value，避免黑边问题
- 支持多文件批量镶嵌

### 2. 输入文件要求

**支持的格式**:
- ENVI格式: `.dat` + `.hdr`
- TIFF格式: `.tif`（但镶嵌后输出仍为ENVI格式）

**空间参考要求**:
- **理想情况**: 所有输入文件都包含有效的空间参考信息
- **容错处理**: 如果文件缺少空间参考，程序会自动尝试从同目录下的`*_SR_B3.TIF`或`*_SR_B4.TIF`文件读取

### 3. 操作步骤

#### 步骤1: 选择输入文件
```
运行程序后，选择要镶嵌的影像文件（可多选）
支持的文件格式: .dat, .tif, .TIF, .DAT
```

#### 步骤2: 选择输出目录
```
选择输出目录，程序会自动生成输出文件名
输出格式固定为ENVI格式(.dat)
```

#### 步骤3: 自动处理空间参考
程序会自动：
1. 检查每个输入文件是否有空间参考信息
2. 如果缺少，尝试从同目录下的GeoTIFF文件读取
3. 如果仍然失败，提示错误并退出

#### 步骤4: 投影系统检查与重投影
程序会：
1. 比较所有输入文件的投影系统
2. 如果投影系统不同，自动将后续文件重投影到第一个文件的投影系统
3. 使用`ENVIReprojectRaster`进行重投影

```idl
; 检查投影系统
projections = LIST()
FOR i=0, rasters.Count()-1 DO BEGIN
  raster = rasters[i]
  spatialRef = raster.SPATIALREF
  coordSysStr = spatialRef.COORD_SYS_STR
  projections.Add, coordSysStr
ENDFOR

; 如果投影不同，重投影
IF projections[0] NE projections[i] THEN BEGIN
  reprojectRaster = ENVIReprojectRaster(raster, $
    TARGET_SPATIAL_REF=rasters[0].SPATIALREF)
  rasters[i] = reprojectRaster
ENDIF
```

#### 步骤5: 统一data ignore value
程序会：
1. 检测所有输入文件的data ignore value
2. 如果不同，使用第一个检测到的值
3. 如果都没有，使用默认值`0.1`（对应EC计算中的b系数，即背景/黑边值）
4. 为所有输入raster设置统一的data ignore value

```idl
; 检测data ignore value
commonIgnoreValue = !NULL
FOR i=0, rasters.Count()-1 DO BEGIN
  IF raster.METADATA.HasTag('data ignore value') THEN BEGIN
    ignoreValue = raster.METADATA['data ignore value']
    IF commonIgnoreValue EQ !NULL THEN BEGIN
      commonIgnoreValue = ignoreValue[0]
    ENDIF
  ENDIF
ENDFOR

; 如果没有检测到，使用默认值
IF commonIgnoreValue EQ !NULL THEN BEGIN
  commonIgnoreValue = 0.1
ENDIF

; 为所有raster设置
FOR i=0, rasters.Count()-1 DO BEGIN
  raster.METADATA.AddItem, 'data ignore value', commonIgnoreValue
  raster.WriteMetadata
ENDFOR
```

#### 步骤6: 执行镶嵌
使用`ENVIMosaicRaster`进行镶嵌：

```idl
mosaicRaster = ENVIMosaicRaster(rasters, $
  METHOD='First', $  ; 重叠区域使用第一个raster的值
  BACKGROUND=commonIgnoreValue $  ; 背景值
)
```

#### 步骤7: 保存结果
保存为ENVI格式，并使用ENVI_SETUP_HEAD确保空间参考和data ignore value写入：

```idl
; 导出为ENVI格式
mosaicRaster.Export, outfile, 'ENVI'

; 使用ENVI_SETUP_HEAD写入空间参考和data ignore value
ENVI_OPEN_FILE, outfile, r_fid=fid
IF fid GE 0 THEN BEGIN
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl, nb=nb, data_type=dt, interleave=interleave
  ENVI_SETUP_HEAD, $
    FNAME=outfile, $
    NS=ns, NL=nl, NB=nb, DATA_TYPE=dt, INTERLEAVE=interleave, $
    MAP_INFO=mapInfo, $
    DATA_IGNORE_VALUE=commonIgnoreValue, $
    /WRITE, /OPEN
  ENVI_FILE_MNG, id=fid, /REMOVE
ENDIF
```

### 4. 输出格式要求

**输出格式**: 固定为ENVI格式（`.dat` + `.hdr`）

**原因**:
- 确保空间参考信息被完整保存
- 确保data ignore value被正确写入
- TIFF格式在ENVI中可能丢失这些信息

### 5. 注意事项

1. **空间参考必须存在**: 所有输入文件必须有有效的空间参考信息，否则镶嵌会失败
2. **投影系统可以不同**: 程序会自动重投影，但会增加处理时间
3. **data ignore value统一**: 程序会自动统一，避免黑边问题
4. **文件大小**: 镶嵌后的文件可能很大，确保有足够的磁盘空间
5. **处理时间**: 重投影和镶嵌大文件可能需要较长时间

---

## 常见问题与解决方案

### Q1: 为什么输出文件缺少空间参考信息？

**原因**:
- 使用了TIFF格式导出（TIFF格式在ENVI中可能丢失空间参考）
- 没有使用ENVI_SETUP_HEAD写入空间参考信息
- 临时文件导出失败，但程序继续执行

**解决方案**:
1. 确保使用ENVI格式（.dat）导出
2. 使用临时文件方法，并在临时文件和最终文件都使用ENVI_SETUP_HEAD
3. 验证导出后的文件是否包含空间参考信息

### Q2: 镶嵌时提示"No standard map projection"

**原因**:
- 输入文件缺少空间参考信息
- 空间参考信息格式不正确

**解决方案**:
1. 检查输入文件是否有空间参考信息
2. 如果缺少，确保同目录下有对应的`*_SR_B3.TIF`或`*_SR_B4.TIF`文件
3. 使用`1206_read_geotiff_spatial_ref.pro`工具检查GeoTIFF文件的空间参考信息

### Q3: 镶嵌结果有黑边覆盖

**原因**:
- data ignore value没有统一
- 背景值没有被正确识别

**解决方案**:
1. 确保所有输入文件都有data ignore value设置
2. 如果使用EC计算结果，默认data ignore value为`0.1`
3. 程序会自动统一data ignore value，但需要确保输入文件有正确的设置

### Q4: 重投影失败

**原因**:
- 投影系统信息不完整
- ENVI版本不支持某些投影系统

**解决方案**:
1. 检查输入文件的投影系统信息是否完整
2. 尝试手动重投影后再进行镶嵌
3. 确保所有文件使用相同的投影系统（避免重投影）

### Q5: 导出速度慢

**原因**:
- 文件很大
- 使用了多次临时文件操作

**解决方案**:
1. 这是正常现象，大文件需要时间
2. 可以优化代码，减少不必要的临时文件操作
3. 考虑分批处理，而不是一次性处理所有文件

### Q6: 如何验证空间参考信息是否正确？

**方法1: 使用代码验证**
```idl
raster = e.OpenRaster('output.dat')
spatialRef = raster.SPATIALREF
IF OBJ_VALID(spatialRef) THEN BEGIN
  PRINT, '空间参考信息存在'
  PRINT, '投影系统: ', spatialRef.COORD_SYS_STR
  PRINT, '像元大小: ', spatialRef.PIXEL_SIZE
  PRINT, '左上角坐标: ', spatialRef.TIE_POINT_MAP
ENDIF ELSE BEGIN
  PRINT, '警告: 缺少空间参考信息'
ENDELSE
```

**方法2: 在ENVI中查看**
- 打开文件后，在Layer Manager中查看文件属性
- 检查是否有投影信息
- 检查坐标是否正确

**方法3: 使用read_geotiff_spatial_ref工具**
```idl
.read_geotiff_spatial_ref
; 选择输出文件，检查空间参考信息
```

---

## 总结

### 关键要点

1. **空间参考读取**: 从GeoTIFF文件（SR_B3/SR_B4）直接读取，不依赖MTL文件解析
2. **保存格式**: 必须使用ENVI格式（.dat），TIFF格式可能丢失空间参考信息
3. **保存方法**: 使用临时文件 + ENVI_SETUP_HEAD双重确保空间参考信息写入
4. **镶嵌要求**: 所有输入文件必须有空间参考信息，程序会自动处理不同投影系统和data ignore value

### 最佳实践

1. **处理前检查**: 使用`1206_read_geotiff_spatial_ref.pro`检查源数据的空间参考信息
2. **处理中验证**: 在每个关键步骤后验证空间参考信息是否存在
3. **处理后确认**: 打开输出文件，确认空间参考信息正确
4. **格式统一**: 所有中间和最终文件都使用ENVI格式

### 文件说明

- **1206_batch_soil_EC.pro**: 主处理程序，计算EC并确保空间参考信息保存
- **1206_mosaic_rasters.pro**: 镶嵌程序，支持自动重投影和空间参考补充
- **1206_read_geotiff_spatial_ref.pro**: 工具程序，用于检查和验证空间参考信息
- **1206_README_使用说明.txt**: 基本使用说明

---

**版本**: 1.0  
**更新日期**: 2024-12  
**适用ENVI版本**: ENVI 5.0及以上  
**适用IDL版本**: IDL 8.0及以上




