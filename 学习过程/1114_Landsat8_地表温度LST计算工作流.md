# Landsat 8 地表温度（LST）计算工作流

## 结果展示

### 温度反演结果图

下图展示了使用本程序对Landsat 8数据进行地表温度反演的结果。图中不同颜色代表不同的地表温度值，红色区域表示高温区域，蓝色区域表示低温区域。

![Landsat 8 地表温度反演结果](https://github.com/fashionfu/ENVI_IDL/blob/main/%E5%AD%A6%E4%B9%A0%E8%BF%87%E7%A8%8B/1114_%E6%B8%A9%E5%BA%A6%E5%8F%8D%E6%BC%94.png)

**图1：Landsat 8 地表温度（LST）反演结果**

#### 结果说明

- **数据源**：Landsat 8 Level 1数据
- **处理区域**：基于Landsat 8多光谱和热红外波段数据
- **温度范围**：图中显示的地表温度范围通常在0-50°C之间（具体范围取决于研究区域和季节）
- **颜色映射**：
  - 🔴 **红色/橙色区域**：高温区域，可能为城市建成区、裸地或工业区
  - 🟡 **黄色区域**：中等温度区域，可能为农田、稀疏植被区
  - 🟢 **绿色区域**：较低温度区域，可能为水体、茂密植被区
  - 🔵 **蓝色区域**：低温区域，通常为水体或阴影区域

#### 应用价值

地表温度反演结果可用于以下应用：

1. **城市热岛效应研究**：识别城市中的高温区域，分析热岛分布特征
2. **环境监测**：监测地表温度变化，评估环境质量
3. **农业应用**：分析农田温度分布，辅助作物生长监测
4. **水资源管理**：识别水体温度分布，辅助水资源评估
5. **气候变化研究**：长期监测地表温度变化趋势

#### 技术特点

- ✅ 采用单窗算法，考虑了地表发射率和大气影响
- ✅ 自动处理空间参考，确保结果具有地理坐标信息
- ✅ 基于ENVITask工作流，处理效率高
- ✅ 支持Landsat 8和Landsat 9数据格式

---

## 功能概述

本程序实现了基于Landsat 8数据的**地表温度（Land Surface Temperature, LST）**计算工作流，采用**单窗算法（Single Window Algorithm）**，使用ENVITask进行栅格数据处理。

### 主要功能
- **自动检测数据级别**：支持自动识别Landsat Level 1和Level 2数据
  - 从多个文件检测：ANG.txt、MTL.json、MTL.txt、MTL.xml
  - 通过GROUP、PROCESSING_LEVEL、DATA_TYPE等字段判断
  - 支持文件名/路径备用判断方法
- **Level 1数据处理**：
  - 从Landsat 8 MTL文件读取多光谱和热红外数据
  - 计算NDVI（归一化植被指数）
  - 计算植被覆盖度
  - 计算地表发射率
  - 热红外波段辐射定标
  - 计算黑体温度
  - 计算最终地表温度（单位：摄氏度）
- **Level 2数据处理**：
  - 直接处理Level 2 ST（Surface Temperature）产品
  - 使用USGS标准缩放因子（0.00341802）和偏移量（149.0）转换温度
  - 支持从STB10 TIF文件直接读取数据（使用READ_TIFF）
  - 从GeoTIFF元数据继承MAP_INFO空间参考
  - 自动跳过多光谱数据打开（仅处理ST产品时）
- **Data Ignore Value设置**：
  - 自动设置输出结果的data ignore value = -999到ENVI头文件
  - 确保在设置空间参考后，data ignore value仍然存在
  - 同时写入元数据和ENVI头文件

### 算法原理

本程序使用的单窗算法基于以下公式：

1. **NDVI计算**：
   ```
   NDVI = (NIR - Red) / (NIR + Red)
   ```

2. **植被覆盖度（FVC）计算**：
   ```
   FVC = (NDVI - 0.05) / (0.7 - 0.05)  (当 0.05 ≤ NDVI ≤ 0.7)
   FVC = 1  (当 NDVI > 0.7)
   FVC = 0  (当 NDVI < 0.05)
   ```

3. **地表发射率（ε）计算**：
   ```
   ε = 0.004 × FVC + 0.986
   ```

4. **黑体温度（Tb）计算**：
   ```
   Tb = (Lλ - Lu - τ × (1 - ε) × Ld) / (τ × ε)
   ```
   其中：
   - Lλ：热红外波段辐射值
   - Lu：上行辐射（0.75 W/m²/sr/μm）
   - Ld：下行辐射（1.29 W/m²/sr/μm）
   - τ：大气透过率（0.9）
   - ε：地表发射率

5. **地表温度（LST）计算**（Level 1数据）：
   ```
   LST = K2 / ln(K1 / Tb + 1) - 273.15
   ```
   其中：
   - K1、K2：热红外波段定标常数（从MTL文件元数据读取）

6. **Level 2 ST产品温度转换**：
   ```
   Temperature(K) = DN × 0.00341802 + 149.0
   LST(°C) = Temperature(K) - 273.15
   ```
   其中：
   - DN：STB10 TIF文件中的原始DN值（通常为几万）
   - 0.00341802：USGS标准缩放因子
   - 149.0：USGS标准偏移量
   - 对于DN值为0的像元，设置为-999（data ignore value）

## 代码结构

### 辅助函数

#### 1. `extract_xml_tag_value`
- **功能**：从XML文件中提取指定标签的值
- **参数**：
  - `xmlLines`：XML文件行数组
  - `tagName`：标签名称
  - `defaultValue`：默认值
- **返回值**：提取的标签值（字符串）

#### 2. `extract_mtl_txt_value`
- **功能**：从MTL TXT文件中提取键值对
- **参数**：
  - `txtLines`：TXT文件行数组
  - `keyName`：键名
  - `defaultValue`：默认值
- **返回值**：提取的键值（字符串）
- **说明**：支持格式如 `KEY = VALUE` 的键值对

#### 3. `create_spatial_ref_from_mtl_txt`
- **功能**：从MTL TXT文件读取投影参数并创建空间参考
- **参数**：
  - `mtlTxtFile`：MTL TXT文件路径
  - `nColumns`：影像列数
  - `nRows`：影像行数
- **返回值**：MAP_INFO结构体（空间参考信息）
- **读取的参数**：
  - `UTM_ZONE`：UTM投影带
  - `DATUM`：基准面（如WGS84）
  - `CORNER_UL_PROJECTION_X_PRODUCT`：左上角投影坐标X
  - `CORNER_UL_PROJECTION_Y_PRODUCT`：左上角投影坐标Y
  - `GRID_CELL_SIZE_REFLECTIVE`：像元大小（米）

#### 4. `create_spatial_ref_from_mtl_xml`
- **功能**：从MTL XML文件读取投影参数并创建空间参考
- **参数**：同`create_spatial_ref_from_mtl_txt`
- **返回值**：MAP_INFO结构体
- **说明**：适用于Landsat 9等有XML格式MTL文件的数据

#### 5. `detect_landsat_level`
- **功能**：自动检测Landsat数据级别（Level 1或Level 2）
- **参数**：
  - `mtl_file`：MTL文件路径
- **返回值**：1表示L2，0表示L1，-1表示无法确定
- **检测方法**（按优先级）：
  1. 从MTL TXT文件读取GROUP、PROCESSING_LEVEL、DATA_TYPE
  2. 从MTL XML文件读取PROCESSING_LEVEL和标签结构
  3. 从MTL JSON文件读取PROCESSING_LEVEL
  4. 检查ANG.txt文件是否存在（L2特有）
  5. 从文件名/路径判断（备用方法）

#### 6. `set_spatial_ref_to_raster`
- **功能**：为raster对象设置空间参考信息
- **参数**：
  - `inputRaster`：输入raster对象
  - `mapInfo`：MAP_INFO结构体
- **返回值**：添加了空间参考的raster对象
- **处理流程**：
  1. 导出raster到临时ENVI文件
  2. 读取现有的data ignore value（如果有）
  3. 使用`ENVI_SETUP_HEAD`设置MAP_INFO和data ignore value
  4. 重新打开raster并返回

#### 7. `set_data_ignore_value_to_raster`
- **功能**：为raster对象设置data ignore value到ENVI头文件
- **参数**：
  - `inputRaster`：输入raster对象
  - `ignoreValue`：忽略值（通常为-999）
- **返回值**：设置了data ignore value的raster对象
- **处理流程**：
  1. 设置到元数据
  2. 导出raster到临时ENVI文件
  3. 使用`ENVI_SETUP_HEAD`设置DATA_IGNORE_VALUE到文件头
  4. 重新打开raster并返回

### 主程序流程

#### 步骤0：数据级别检测
```idl
; 自动检测Landsat数据级别
levelResult = detect_landsat_level(mtl_file)
IF levelResult EQ 1 THEN BEGIN
  isLevel2 = 1
  PRINT, '✓ 检测到Level 2数据，将使用特殊处理方式'
ENDIF ELSE IF levelResult EQ 0 THEN BEGIN
  isLevel2 = 0
  PRINT, '✓ 检测到Level 1数据，将使用标准处理方式'
ENDIF
```

#### 步骤1：数据准备（Level 1数据）
```idl
; 打开多光谱和热红外数据
mss_raster = e.OpenRaster(mtl_file, DATASET_NAME='Multispectral')
the_raster = e.OpenRaster(mtl_file, DATASET_NAME='Thermal')

; 提取热红外定标常数K1和K2
k1 = (the_raster.METADATA['THERMAL K1'])[0]
k2 = (the_raster.METADATA['THERMAL K2'])[0]
```

#### 步骤1'：Level 2 ST产品处理
```idl
; 直接查找并打开STB10 TIF文件
stb10File = FILE_SEARCH(mtlDir, '*_ST_B10.TIF')
stb10_data = READ_TIFF(stb10File[0], GEOTIFF=geo_struct)

; 从GeoTIFF继承MAP_INFO
IF N_ELEMENTS(geo_struct) GT 0 THEN BEGIN
  mapInfoFromGeo = geo_struct.MAP_INFO
  st_raster = ENVIRaster(stb10_data, URI=temp_stb10, MAP_INFO=mapInfoFromGeo)
ENDIF

; 使用USGS标准公式转换温度
scaleFactor = 0.00341802
addOffset = 149.0
lstExpr = '(b1 ne 0)*((b1*' + scaleFactor + '+' + addOffset + ')-273.15)+(b1 eq 0)*(-999)'
Task = ENVITask('PixelwiseBandMathRaster')
Task.INPUT_RASTER = stb10_raster
Task.EXPRESSION = lstExpr
Task.Execute

; 设置data ignore value = -999
lstResultRaster = set_data_ignore_value_to_raster(Task.OUTPUT_RASTER, -999)
```

#### 步骤2：多光谱数据处理流程
```idl
; NDVI计算
ndvi_raster = ENVISpectralIndexRaster(mss_raster, 'ndvi')

; 植被覆盖度计算
veg_exp = '(b1 GT 0.7)*1+(b1 LT 0.05)*0+(b1 GE 0.05 AND b1 LE 0.7)*((b1-0.05)/(0.7-0.05))'
veg_raster = ENVIPixelwiseBandMathRaster(ndvi_raster, veg_exp)

; 地表发射率计算
ratio_exp = '0.004*b1+0.986'
ratio_raster = ENVIPixelwiseBandMathRaster(veg_raster, ratio_exp)
```

#### 步骤3：热红外数据处理流程
```idl
; 提取Band 10
b10_raster = ENVISubsetRaster(the_raster, bands=[0])

; 辐射定标（转换为辐射值）
b10rad_raster = ENVICalibrateRaster(b10_raster, calibration='Radiance')

; 移除K1和K2元数据（避免后续计算冲突）
b10rad_raster.METADATA.RemoveItem, 'THERMAL K1'
b10rad_raster.METADATA.RemoveItem, 'THERMAL K2'
```

#### 步骤4：空间参考处理
这是本程序的关键改进点，解决了"Input raster must have a spatial reference"错误：

1. **检查空间参考**：
   - 按优先级检查：`mss_raster` > `the_raster` > `b10rad_raster`
   - 找到第一个有空间参考的raster作为`gridDefRaster`

2. **从MTL文件读取空间参考**（如果所有raster都没有空间参考）：
   - 优先从MTL.txt文件读取（Landsat 8通常只有TXT文件）
   - 如果失败，尝试从MTL.xml文件读取（Landsat 9可能有XML文件）
   - 创建MAP_INFO结构体
   - 为`mss_raster`添加空间参考

3. **为堆叠raster添加空间参考**：
   - 检查`ratio_raster`和`b10rad_raster`是否有空间参考
   - 如果没有，使用相同的mapInfo为它们添加空间参考

#### 步骤5：数据堆叠和黑体温度计算
```idl
; 创建grid definition
gridTask = ENVITask('BuildGridDefinitionFromRaster')
gridTask.INPUT_RASTER = gridDefRaster
gridTask.Execute

; 堆叠地表发射率和热红外辐射数据
ls_raster = ENVILayerStackRaster([ratio_raster, b10rad_raster], $
  grid_definition=gridTask.OUTPUT_GRIDDEFINITION)

; 计算黑体温度
; 公式：(b2-0.75-0.9*(1-b1)*1.29)/(0.9*b1)
; b1：地表发射率
; b2：Band10辐射值
black_exp = '(b2-0.75-0.9*(1-b1)*1.29)/(0.9*b1)'
black_raster = ENVIPixelwiseBandMathRaster(ls_raster, black_exp)
```

#### 步骤6：地表温度计算
```idl
; 计算最终地表温度
; 公式：K2/ln(K1/b1+1)-273.15
Task = ENVITask('PixelwiseBandMathRaster')
Task.INPUT_RASTER = black_raster
Task.EXPRESSION = k2+'/alog('+k1+'/b1+1)-273.15'
Task.Execute
```

#### 步骤7：Data Ignore Value设置
```idl
; 设置data ignore value = -999到ENVI头文件
IF Task.OUTPUT_RASTER.METADATA.HasTag('data ignore value') THEN BEGIN
  Task.OUTPUT_RASTER.METADATA.UpdateItem, 'data ignore value', -999
ENDIF ELSE BEGIN
  Task.OUTPUT_RASTER.METADATA.AddItem, 'data ignore value', -999
ENDELSE
Task.OUTPUT_RASTER.WriteMetadata

; 使用辅助函数写入ENVI头文件
lstResultRaster = set_data_ignore_value_to_raster(Task.OUTPUT_RASTER, -999)

; 如果设置了空间参考，确保data ignore value仍然存在
IF (mapInfo NE !NULL) AND OBJ_VALID(lstResultRaster) THEN BEGIN
  lst_with_sr = set_spatial_ref_to_raster(lstResultRaster, mapInfo)
  ; 检查并重新设置data ignore value（如果丢失）
  IF ~lst_with_sr.METADATA.HasTag('data ignore value') THEN BEGIN
    lst_with_sr = set_data_ignore_value_to_raster(lst_with_sr, -999)
  ENDIF
ENDIF
```

#### 步骤8：结果显示
```idl
; 添加到Data Manager
DataColl = e.DATA
DataColl.Add, Task.OUTPUT_RASTER

; 显示结果
View1 = e.GetView()
Layer1 = View1.CreateLayer(Task.OUTPUT_RASTER)
```

## 关键技术点

### 1. 空间参考处理
- **问题**：某些ENVI处理函数（如`ENVIPixelwiseBandMathRaster`）可能不保留空间参考信息
- **解决方案**：
  - 从MTL文件（TXT或XML）读取投影参数
  - 使用`ENVI_MAP_INFO_CREATE`创建MAP_INFO结构体
  - 通过导出-修改-重新打开的方式为raster添加空间参考

### 2. 数据堆叠对齐
- **问题**：不同处理步骤产生的raster可能尺寸或空间参考不一致
- **解决方案**：
  - 使用`BuildGridDefinitionFromRaster`创建统一的grid definition
  - 使用`ENVILayerStackRaster`的`grid_definition`参数确保对齐

### 3. 热红外定标常数
- K1和K2从热红外raster的元数据中读取
- 在辐射定标后需要移除这些元数据，避免后续计算冲突

### 4. 大气参数（Level 1数据）
本程序使用固定的大气参数：
- 大气透过率（τ）：0.9
- 上行辐射（Lu）：0.75 W/m²/sr/μm
- 下行辐射（Ld）：1.29 W/m²/sr/μm

**注意**：这些是默认值，实际应用中可能需要根据具体的大气条件调整。

### 5. Level 2 ST产品处理
- **数据格式**：STB10 TIF文件存储的是DN值（通常为几万），不是直接的温度值
- **转换公式**：使用USGS标准缩放因子和偏移量
  - 缩放因子：0.00341802
  - 偏移量：149.0
- **空间参考**：优先从GeoTIFF元数据继承MAP_INFO，如果缺失则从MTL XML/TXT文件读取

### 6. Data Ignore Value处理
- **设置位置**：同时写入元数据和ENVI头文件
- **值**：-999（用于标记无效像元，如DN值为0的像元）
- **保护机制**：在设置空间参考后，自动检查并重新设置data ignore value（如果丢失）

## 输入要求

### 数据格式
- **Landsat 8 Level 1数据**（包含MTL文件）
  - **必需的数据集**：
    - `Multispectral`：多光谱数据（用于NDVI计算）
    - `Thermal`：热红外数据（Band 10，用于温度计算）
- **Landsat 8 Level 2数据**（包含MTL文件和ST产品）
  - **必需的数据集**：
    - `ST_B10`或`*_ST_B10.TIF`：地表温度产品Band 10（可直接处理）
  - **可选的数据集**：
    - `Multispectral`：多光谱数据（Level 2数据处理ST产品时可跳过）

### MTL文件要求
- **Level 1数据**：MTL.txt文件必须包含以下投影参数：
  - `UTM_ZONE`：UTM投影带
  - `DATUM`：基准面（如WGS84）
  - `CORNER_UL_PROJECTION_X_PRODUCT`：左上角投影坐标X
  - `CORNER_UL_PROJECTION_Y_PRODUCT`：左上角投影坐标Y
  - `GRID_CELL_SIZE_REFLECTIVE`：像元大小
- **Level 2数据**：支持多种MTL文件格式：
  - `MTL.txt`：TXT格式元数据
  - `MTL.xml`：XML格式元数据（优先使用，包含完整四角坐标）
  - `MTL.json`：JSON格式元数据
  - `ANG.txt`：角度系数文件（Level 2特有）
- **空间参考参数**（Level 2数据）：
  - 优先从GeoTIFF元数据读取MAP_INFO
  - 如果缺失，从MTL XML/TXT文件读取四角投影坐标：
    - `CORNER_UL_PROJECTION_X_PRODUCT`、`CORNER_UL_PROJECTION_Y_PRODUCT`
    - `CORNER_UR_PROJECTION_X_PRODUCT`、`CORNER_UR_PROJECTION_Y_PRODUCT`
    - `CORNER_LL_PROJECTION_X_PRODUCT`、`CORNER_LL_PROJECTION_Y_PRODUCT`
    - `CORNER_LR_PROJECTION_X_PRODUCT`、`CORNER_LR_PROJECTION_Y_PRODUCT`

## 输出结果

- **最终输出**：地表温度栅格（单位：摄氏度）
  - **Data Ignore Value**：-999（已写入ENVI头文件）
  - **空间参考**：已自动设置（从GeoTIFF或MTL文件读取）
- **中间结果**（虚拟栅格，不保存）：
  - **Level 1数据**：
    - NDVI栅格
    - 植被覆盖度栅格
    - 地表发射率栅格
    - 热红外辐射值栅格
    - 黑体温度栅格
  - **Level 2数据**：
    - STB10原始DN值栅格

## 使用示例

### Level 1数据处理
```idl
; 修改MTL文件路径（Level 1数据）
mtl_file = 'E:\1021WaterData\201\0-原始数据\LC81240382017118LGN00\LC81240382017118LGN00_MTL.txt'

; 运行程序
test_Landsat8_LST_workflow
```

### Level 2数据处理
```idl
; 修改MTL文件路径（Level 2数据）
mtl_file = 'E:\1021WaterData\LC09\LC08_L2SP_123033_20240424_20240430_02_T1\LC08_L2SP_123033_20240424_20240430_02_T1_MTL.txt'

; 运行程序（自动检测为Level 2数据并处理ST产品）
test_Landsat8_LST_workflow
```

## 注意事项

1. **空间参考**：
   - Level 1数据：如果数据缺少空间参考，程序会自动从MTL文件读取并添加
   - Level 2数据：优先从GeoTIFF元数据继承MAP_INFO，如果缺失则从MTL XML/TXT文件读取四角坐标
2. **Data Ignore Value**：
   - 输出结果的data ignore value = -999已自动写入ENVI头文件
   - 在设置空间参考后，程序会自动检查并确保data ignore value仍然存在
3. **Level 2数据处理**：
   - Level 2数据如果只处理ST产品，会自动跳过打开多光谱数据
   - STB10 TIF文件存储的是DN值（几万），不是直接的温度值，需要使用USGS标准公式转换
4. **临时文件**：程序会在`E:\1027IDL\ENVITaskTrainning\Temp`目录创建临时文件
5. **处理时间**：大型影像的处理可能需要较长时间
6. **内存使用**：确保有足够的内存处理大型栅格数据

## 算法参考

本程序使用的单窗算法基于以下研究：
- 单窗算法（Single Window Algorithm）用于Landsat热红外数据的地表温度反演
- 考虑了地表发射率、大气透过率和大气辐射的影响

## 代码改进历史

### 主要改进点

#### v2.0（2024）
1. **空间参考处理**：
   - 添加了从MTL TXT/XML文件读取空间参考的功能
   - 实现了自动为缺少空间参考的raster添加空间参考
   - 解决了`BuildGridDefinitionFromRaster`和`ENVILayerStackRaster`的空间参考要求

2. **容错处理**：
   - 支持Landsat 8（MTL.txt）和Landsat 9（MTL.xml）两种格式
   - 多种方法尝试导出raster和设置空间参考

3. **代码结构**：
   - 参考了`landsat9_spectral_indices.pro`和`landsat9_classification.pro`的最佳实践
   - 使用辅助函数提高代码复用性

#### v3.0（2025）
1. **数据级别自动检测**：
   - 新增`detect_landsat_level`函数，支持从多个文件自动检测数据级别
   - 支持从ANG.txt、MTL.json、MTL.txt、MTL.xml中检测
   - 通过GROUP、PROCESSING_LEVEL、DATA_TYPE等字段判断
   - 支持文件名/路径备用判断方法

2. **Level 2数据处理支持**：
   - 支持直接处理Level 2 ST（Surface Temperature）产品
   - 使用USGS标准缩放因子（0.00341802）和偏移量（149.0）转换温度
   - 支持从STB10 TIF文件直接读取数据（使用READ_TIFF）
   - 从GeoTIFF元数据继承MAP_INFO空间参考
   - 自动跳过多光谱数据打开（仅处理ST产品时）

3. **Data Ignore Value设置**：
   - 新增`set_data_ignore_value_to_raster`函数
   - 自动设置输出结果的data ignore value = -999到ENVI头文件
   - 确保在设置空间参考后，data ignore value仍然存在
   - 同时写入元数据和ENVI头文件

4. **空间参考处理增强**：
   - 改进了`extract_xml_tag_value`函数，更好地处理XML标签解析（支持缩进、空格、自闭合标签等）
   - 改进了`create_spatial_ref_from_mtl_xml`函数，读取四角投影坐标并计算像元大小
   - 在设置空间参考后，自动检查并重新设置data ignore value（如果丢失）
   - 改进了`set_spatial_ref_to_raster`函数，保留现有的data ignore value

## 相关文件

- `landsat9_spectral_indices.pro`：光谱指数计算（参考了空间参考处理方法）
- `landsat9_classification.pro`：分类处理（参考了空间参考处理方法）
- `test1110_finalndvi.pro`：NDVI计算示例

## 作者信息

- **原始作者**：duhj@geoscene.cn
- **原始日期**：2018-3-15
- **改进日期**：
  - 2024：添加空间参考处理功能
  - 2025：添加Level 2数据处理、Data Ignore Value设置、数据级别自动检测等功能

## 版本历史

- **v1.0**（2018-3-15）：初始版本，基本LST计算功能
- **v2.0**（2024）：添加空间参考自动处理功能，支持从MTL文件读取投影参数
- **v3.0**（2025）：
  - 新增数据级别自动检测功能（支持Level 1和Level 2）
  - 支持Level 2 ST产品直接处理（使用USGS标准公式）
  - 新增Data Ignore Value自动设置功能（-999）
  - 增强空间参考处理（支持从GeoTIFF继承、读取四角坐标）
  - 改进XML标签解析功能


