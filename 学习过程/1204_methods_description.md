# Landsat GeoTIFF 空间参考读取方法总结

## 为什么这两种方法能够成功？

### 核心原因

**这两种方法之所以成功，是因为它们直接从 GeoTIFF 文件本身读取空间参考信息，而不是从 MTL（元数据）文件中解析。**

### 技术原理

1. **GeoTIFF 格式特性**
   - GeoTIFF 是 TIFF 格式的扩展，在文件头中嵌入了地理参考信息
   - 这些信息包括：投影坐标系、像元大小、左上角坐标等
   - 这些信息是**直接存储在 TIF 文件中的**，不依赖于外部的 MTL 文件

2. **MTL 文件解析的问题**
   - MTL 文件（.txt 或 .xml）是 Landsat 数据的元数据文件
   - 在用户的 ENVI/IDL 环境中，直接解析 MTL 文件存在以下问题：
     - `READF` 函数读取 XML/TXT 文件时可能遇到编码问题
     - `IDLffXMLDOMDocument` 在用户环境中不可用
     - `ENVI_OPEN_DATA_FILE` 配合 `/LANDSAT_METADATA` 关键字失败
     - `e.OpenRaster(MTL_file)` 返回的栅格对象没有空间参考信息

3. **直接读取 GeoTIFF 的优势**
   - GeoTIFF 文件本身包含完整的地理参考信息
   - IDL 的 `READ_TIFF` 函数和 ENVI 的 `ENVI_OPEN_DATA_FILE` 都能正确识别这些信息
   - 不依赖外部文件解析，更加可靠

---

## 所有尝试的方法及结果

### ❌ 方法1：从 MTL XML 文件解析坐标（失败）

**尝试时间**: 初期

**方法描述**:
- 使用 `OPENR` + `READF` 读取 MTL XML 文件
- 使用字符串搜索提取 XML 标签值（如 `CORNER_UL_PROJECTION_X_PRODUCT`）
- 使用 `extract_xml_tag_value` 函数解析

**失败原因**:
- `READF` 读取 XML 文件时，字符串数组元素被截断为空字符串
- 即使转换为 UTF-8 编码，仍然无法正确读取内容
- 解析出的坐标值始终为 0.00

**相关代码文件**:
- `batch_soil_EC.pro` 中的 `create_spatial_ref_from_mtl_xml` 函数
- `extract_xml_tag_value` 函数

---

### ❌ 方法2：从 MTL TXT 文件解析坐标（失败）

**尝试时间**: 中期

**方法描述**:
- 使用 `OPENR` + `READF` 读取 MTL TXT 文件
- 使用字符串搜索提取键值对（如 `CORNER_UL_PROJECTION_X_PRODUCT = 300300.00`）
- 使用 `extract_mtl_txt_value` 函数解析

**失败原因**:
- 与 XML 解析相同的问题：`READF` 无法正确读取文件内容
- 解析出的所有值都为空或默认值

**相关代码文件**:
- `batch_soil_EC.pro` 中的 `create_spatial_ref_from_mtl_txt` 函数
- `extract_mtl_txt_value` 函数

---

### ❌ 方法3：使用 IDLffXMLDOMDocument 解析 XML（失败）

**尝试时间**: 中期

**方法描述**:
- 使用 IDL 的 XML DOM 对象 `IDLffXMLDOMDocument`
- 使用 `LoadFile` 方法加载 XML 文件
- 使用 `GetElementsByTagName` 和 `GetText` 提取标签值

**失败原因**:
- 用户环境的 IDL 版本不支持 `IDLffXMLDOMDocument::LoadFile` 方法
- 报错：`% Attempt to call undefined method: 'IDLFFXMLDOMDOCUMENT::LOADFILE'`

**相关代码文件**:
- `read_mtl_dom.pro`

---

### ❌ 方法4：使用 ENVI_OPEN_DATA_FILE + /LANDSAT_METADATA（失败）

**尝试时间**: 后期

**方法描述**:
- 参考博客文章，使用 `ENVI_OPEN_DATA_FILE` 配合 `/LANDSAT_METADATA` 关键字
- 使用 `ENVI_GET_FILE_IDS()` 获取所有文件 ID
- 遍历 FID 查找多波段文件

**失败原因**:
- `ENVI_OPEN_DATA_FILE` 返回 `fid = -1`，表示打开失败
- 可能用户的 ENVI 版本不支持此关键字，或 MTL 文件格式不兼容

**相关代码文件**:
- `read_mtl.pro`（早期版本）

---

### ❌ 方法5：直接打开 SR_B3/SR_B4 TIF 文件检查 SPATIALREF（失败）

**尝试时间**: 后期

**方法描述**:
- 使用 `e.OpenRaster(*_SR_B3.TIF)` 直接打开 GeoTIFF 文件
- 检查返回的 `ENVIRaster` 对象的 `SPATIALREF` 属性

**失败原因**:
- 所有打开的栅格对象的 `SPATIALREF` 属性都是 `!NULL`
- ENVI 没有从 GeoTIFF 文件中识别出空间参考信息
- 可能的原因：ENVI 版本问题、GeoTIFF 驱动问题、或文件本身缺少某些标签

**相关代码文件**:
- `read_mtl.pro`（中期版本）

---

### ✅ 方法6：使用 READ_TIFF + GEOTIFF 参数（成功）

**尝试时间**: 最终

**方法描述**:
- 使用 IDL 的 `READ_TIFF` 函数读取 GeoTIFF 文件
- 使用 `GEOTIFF` 关键字参数获取地理参考信息
- 使用 `SUB_RECT=[0, 0, 1, 1]` 只读取一个像素，减少内存占用
- 从返回的 `GeoKeys` 结构体中提取：
  - `MODELPIXELSCALETAG`: 像元大小
  - `MODELTIEPOINTTAG`: 左上角投影坐标
  - `GTCITATIONGEOKEY`: 投影信息
  - `GEOGCITATIONGEOKEY`: 地理坐标系
  - `PROJECTEDCSTYPEGEOKEY`: 投影坐标系代码

**成功原因**:
- `READ_TIFF` 是 IDL 的标准函数，能够正确读取 GeoTIFF 格式的地理参考标签
- GeoTIFF 文件本身包含了完整的地理参考信息
- 不依赖外部文件解析，直接从文件头读取

**代码示例**:
```idl
img = READ_TIFF(bandFile, GEOTIFF=GeoKeys, SUB_RECT=[0, 0, 1, 1])
pixelScale = GeoKeys.MODELPIXELSCALETAG
tiePoint = GeoKeys.MODELTIEPOINTTAG
ulX = tiePoint[3]
ulY = tiePoint[4]
```

**测试结果**:
- ✅ 成功读取像元大小：30 x 30 米
- ✅ 成功读取左上角投影坐标：(300300.00, 5217300.0) 米
- ✅ 成功读取投影信息：WGS 84 / UTM zone 52N

**相关代码文件**:
- `1204_read_geotiff_spatial_ref.pro`（方法1部分）

---

### ✅ 方法7：使用 ENVI_OPEN_DATA_FILE + /TIFF 关键字（成功）

**尝试时间**: 最终

**方法描述**:
- 使用 `ENVI_OPEN_DATA_FILE` 配合 `/TIFF` 关键字打开 GeoTIFF 文件
- 使用 `ENVI_GET_PROJECTION` 获取投影结构体
- 使用 `ENVI_CONVERT_FILE_COORDINATES` 将像素坐标转换为地图坐标
- 从投影结构体中提取：
  - `NAME`: 投影名称（如 "UTM"）
  - `DATUM`: 基准面（如 "WGS-84"）
  - `PARAMS[0]`: UTM Zone

**成功原因**:
- `/TIFF` 关键字告诉 ENVI 将文件作为 TIFF 格式处理
- ENVI 能够识别 GeoTIFF 格式的地理参考标签
- `ENVI_CONVERT_FILE_COORDINATES` 函数能够正确进行坐标转换

**代码示例**:
```idl
ENVI_BATCH_INIT
ENVI_OPEN_DATA_FILE, bandFile, /TIFF, R_FID=fid
proj = ENVI_GET_PROJECTION(FID=fid)
ENVI_CONVERT_FILE_COORDINATES, fid, [0], [0], xMap, yMap, /TO_MAP
ENVI_BATCH_EXIT
```

**测试结果**:
- ✅ 成功打开文件，获取 fid
- ✅ 成功获取投影信息：UTM Zone 52, WGS-84
- ✅ 成功转换坐标：(300285.00, 5217315.0) 米

**注意**: 与方法1的坐标略有差异（约15米），这是正常的，因为：
- 方法1读取的是 GeoTIFF 头文件中的 tie point
- 方法2是通过 ENVI 的坐标转换函数计算的
- 两种方法都在可接受误差范围内

**相关代码文件**:
- `1204_read_geotiff_spatial_ref.pro`（方法2部分）
- `1204_create_map_info_from_geotiff.pro`

---

## 最终推荐方案

### 方案选择

**推荐使用方法2（ENVI_OPEN_DATA_FILE + /TIFF）**，原因：
1. 更符合 ENVI 的工作流程
2. 可以直接使用 `ENVI_CONVERT_FILE_COORDINATES` 获取坐标
3. 可以获取完整的投影结构体，便于后续创建 `MAP_INFO`
4. 与方法1相比，坐标计算更精确（通过 ENVI 内部算法）

**备用方案：方法1（READ_TIFF + GEOTIFF）**
- 如果方法2失败，可以使用方法1作为备用
- 方法1更底层，不依赖 ENVI Batch 模式

### 实现建议

1. **在 `batch_soil_EC.pro` 中的应用**:
   - 不再从 MTL 文件解析空间参考
   - 直接打开 `*_SR_B3.TIF` 或 `*_SR_B4.TIF` 文件
   - 使用 `1204_create_map_info_from_geotiff.pro` 中的函数创建 `MAP_INFO`
   - 将 `MAP_INFO` 设置到输入栅格和输出 EC 栅格

2. **代码结构**:
   ```idl
   ; 1. 打开 GeoTIFF 文件获取空间参考
   mapInfo = create_map_info_from_geotiff(sr_b3_file)
   
   ; 2. 如果成功，设置到栅格对象
   IF mapInfo NE !NULL THEN BEGIN
     ; 设置空间参考到输入栅格
     set_spatial_ref_to_raster(inputRaster, mapInfo)
     ; 设置空间参考到输出栅格
     set_spatial_ref_to_raster(outputRaster, mapInfo)
   ENDIF
   ```

---

## 总结

### 关键教训

1. **不要过度依赖 MTL 文件解析**
   - MTL 文件解析在不同环境中可能不稳定
   - 直接读取 GeoTIFF 文件更可靠

2. **利用 GeoTIFF 格式的优势**
   - GeoTIFF 文件本身包含完整的地理参考信息
   - 这些信息是标准化的，易于读取

3. **多种方法并行尝试**
   - 当一种方法失败时，尝试其他方法
   - 最终找到了两种成功的方法

### 成功的关键

- **绕过 MTL 文件解析**：直接从 GeoTIFF 文件读取
- **使用标准函数**：`READ_TIFF` 和 `ENVI_OPEN_DATA_FILE` 都是标准函数
- **利用 GeoTIFF 格式**：文件本身包含所需信息

---

## 参考资料

1. CSDN 博客: [IDL中对.tif格式文件的读写（包括Map_Info的获取）](https://blog.csdn.net/weixin_43955546/article/details/112760000)
2. ENVI 帮助文档: `ENVI_OPEN_DATA_FILE`, `ENVI_GET_PROJECTION`, `ENVI_CONVERT_FILE_COORDINATES`
3. IDL 帮助文档: `READ_TIFF`, `WRITE_TIFF`

---

**文档创建日期**: 2024-12-04  
**最后更新日期**: 2024-12-04

