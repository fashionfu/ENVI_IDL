# Landsat 9 光谱指数计算代码运行总结

## 文档信息
- **文档名称**: 1112_Landsat9_spectral_indices.md
- **创建日期**: 2024-12-11
- **代码文件**: `landsat9_spectral_indices.pro`
- **参考代码**: `test1110_finalndvi.pro`

---

## 处理效果对比

### 原有偏移数据

下图展示了**未添加空间参考信息**时，两个时相数据对比产生的严重偏移问题：

![原有偏移数据](https://github.com/fashionfu/ENVI_IDL/raw/main/%E5%AD%A6%E4%B9%A0%E8%BF%87%E7%A8%8B/1112_%E4%B8%A5%E9%87%8D%E5%81%8F%E7%A7%BB%E5%9B%BE.png)

**说明**：由于缺少空间参考信息，2021年和2025年的影像无法按地理坐标精确对齐，导致差值计算结果出现严重偏移，无法正确反映实际的地物变化。

---

### 空间参考处理后的效果

下图展示了**添加空间参考信息后**，使用 `ImageIntersection` 任务按地理坐标精确对齐的对比效果：

![空间参考处理后的效果对比](https://github.com/fashionfu/ENVI_IDL/raw/main/%E5%AD%A6%E4%B9%A0%E8%BF%87%E7%A8%8B/1112_%E7%BB%84%E5%9B%BE.png)

**从左到右依次为**：
1. **严重偏移NDVI差值图**：未添加空间参考时，NDVI差值图出现明显偏移，无法正确反映植被变化
2. **空间参考后NDBI差值图**：添加空间参考后，NDBI差值图能够准确反映建筑指数变化，影像对齐精确
3. **空间参考后NDVI差值图**：添加空间参考后，NDVI差值图能够准确反映植被变化，影像对齐精确

**关键改进**：通过从MTL XML文件读取投影参数并添加空间参考信息，使用 `ImageIntersection` 任务按地理坐标精确对齐两个时相的影像，确保了差值计算的准确性和可靠性。

---

## 数据检索与预处理流程

### 一、数据检索与筛选（USGS Earth Explorer）

在USGS Earth Explorer平台检索特定研究区域的Landsat 9数据时，需要设置以下筛选条件：

1. **日期范围**：根据研究需求设置起始和结束日期，确保覆盖目标时相
2. **云量阈值**：设置最大云量百分比（建议<10%），保证影像质量
3. **数据级别**：选择**L2级（Level-2）**数据，即Surface Reflectance（表面反射率）产品，已进行大气校正，可直接用于定量分析

### 二、数据范围确认与多时相影像查询

1. **查看影像地理范围**
   - 打开下载的Landsat 9数据包中的**MTL XML文件**或**ISON文件**
   - 查看影像的经纬度范围（`CORNER_UL_LAT_PRODUCT`、`CORNER_UL_LON_PRODUCT`等参数）
   - 确认影像覆盖的研究区域范围

2. **查询同位置不同时间过境的卫星影像**
   - 使用已确认的经纬度范围作为搜索条件
   - 在USGS Earth Explorer中设置相同的空间范围
   - 查询不同时间过境的Landsat 9影像
   - 筛选条件：
     - **云量**：选择云量较低的影像（建议<10%）
     - **日期**：根据研究需求选择合适的时间间隔（如年度对比、季度对比等）
     - **数据级别**：统一选择L2级数据，确保数据一致性

### 三、空间参考坐标系处理（关键技术）

Landsat 9的Surface Reflectance数据有时缺少空间参考信息，这是进行精确地理对齐和对比分析的关键步骤：

#### 3.1 从MTL XML文件读取投影参数

- 使用 `create_spatial_ref_from_mtl_xml` 函数解析MTL XML文件
- 提取关键投影参数：
  - **DATUM**（基准面，通常为WGS84）
  - **UTM_ZONE**（UTM投影带）
  - **CORNER_UL_PROJECTION_X_PRODUCT**（左上角投影坐标X）
  - **CORNER_UL_PROJECTION_Y_PRODUCT**（左上角投影坐标Y）
  - **GRID_CELL_SIZE_REFLECTIVE**（像元大小，通常为30米）

#### 3.2 创建MAP_INFO结构体并写入文件头

- 使用 `ENVI_MAP_INFO_CREATE` 函数创建MAP_INFO结构体
- 将空间参考信息写入ENVI格式文件的**.hdr文件头**
- 使用 `ENVI_SETUP_HEAD` 函数直接修改文件头，无需重新导出数据

#### 3.3 导入空间信息到ENVI临时文件（容错机制）

代码实现了**4种导出方法**的容错机制，确保空间参考添加成功：

1. **方法1**：直接使用 `raster.Export` 方法导出到临时文件
2. **方法2**：使用 `e.GetTemporaryFilename('dat')` 获取临时文件路径
3. **方法3**：使用 `RasterExport` 任务导出
4. **方法4**：使用 `ExportRasterToENVI` 任务导出

处理流程：
- 导出raster到临时ENVI文件（.dat + .hdr）
- 使用 `ENVI_SETUP_HEAD` 添加空间参考信息到.hdr文件头
- 重新打开raster对象
- **保留波长信息**：在添加空间参考前保存波长信息，处理完成后恢复

### 四、对比分析流程概述

#### 4.1 光谱指数计算

- **NDVI（归一化植被指数）**：`(NIR - Red) / (NIR + Red)`，用于监测植被覆盖和生长状况
- **NDWI（归一化水体指数）**：`(Green - SWIR1) / (Green + SWIR1)`，用于提取水体信息
- **NDBI（归一化建筑指数）**：`(SWIR1 - NIR) / (SWIR1 + NIR)`，用于识别建筑和城市区域

#### 4.2 多时相对比分析

- **空间参考检查与添加**：自动检查两个时相影像的空间参考信息，缺少时自动添加
- **影像对齐**：使用 `ImageIntersection` 任务按地理坐标精确对齐，消除偏移
- **差值计算**：计算两个时相的光谱指数差值，统计变化信息

---

**关键技术要点**：
- 空间参考信息是进行精确地理对齐和对比分析的基础
- 多层次容错机制确保数据处理的鲁棒性
- 从MTL XML文件读取投影参数并写入.hdr文件头，是处理Landsat 9数据的关键步骤
- 保留波长信息确保后续光谱分析的正确性

## 一、代码成功运行的关键原因

### 1.1 多层次数据打开策略

代码采用了**5种方法**依次尝试打开Landsat 9数据，确保在各种情况下都能成功获取数据：

1. **方法1**: 使用 `DATASET_NAME='Surface Reflectance'` 参数直接打开
   - 优点：最简单直接
   - 缺点：有时只返回4个波段（不完整）

2. **方法2**: 使用 `ExtractRasterFromFile` 任务
   - 优点：更可靠的数据提取方式
   - 适用：方法1失败时使用

3. **方法3**: 使用默认方式打开MTL文件
   - 优点：兼容性最好
   - 适用：前两种方法都失败时使用

4. **方法4**: 为raster添加空间参考信息
   - **关键改进**：即使只有4个波段，也先尝试为整个raster添加空间参考
   - 参考了 `test1110_finalndvi.pro` 的处理方式
   - 使用 `set_spatial_ref_to_raster` 函数

5. **方法5**: 打开单个TIF文件并堆叠
   - 适用：当前面方法只获得4个或更少波段时
   - 打开B1-B5的TIF文件，使用 `ENVILayerStackRaster` 堆叠

### 1.2 空间参考信息处理

#### 问题背景
- Landsat 9的Surface Reflectance数据有时缺少空间参考信息
- 单个TIF文件（SR_B1到SR_B5）通常也没有空间参考

#### 解决方案
1. **从MTL XML文件读取投影参数**
   - 使用 `create_spatial_ref_from_mtl_xml` 函数
   - 解析UTM投影参数、像元大小、左上角坐标等

2. **为raster添加空间参考**
   - 使用 `set_spatial_ref_to_raster` 函数
   - 流程：导出到临时文件 → 使用 `ENVI_SETUP_HEAD` 添加空间参考 → 重新打开

3. **导出方法的改进**
   - 直接导出失败时，使用 `e.GetTemporaryFilename('dat')` 方法
   - 参考了 `test1110_finalndvi.pro` 的实现

### 1.3 波段堆叠处理

#### 关键改进
- 使用 `ENVILayerStackRaster` 函数而不是 `BuildLayerStack` 任务
- 需要先创建 `grid_definition`（使用 `BuildGridDefinitionFromRaster` 任务）
- 要求至少一个raster有空间参考信息

#### 处理流程
1. 为每个TIF文件添加空间参考（使用 `set_spatial_ref_to_raster`）
2. 使用第一个有空间参考的raster创建 `grid_definition`
3. 使用 `ENVILayerStackRaster` 堆叠所有波段

### 1.4 错误处理机制

#### 关键改进
- 如果 `set_spatial_ref_to_raster` 失败，**保留原始raster并继续处理**
- 不再因为空间参考添加失败而中断整个流程
- 即使没有空间参考，也能继续计算光谱指数（只是无法进行精确的地理对齐）

## 二、代码运行流程详解

### 2.1 主程序流程

```
landsat9_spectral_indices (主程序)
├── 处理2021年数据 (process_year_data)
│   ├── 方法1: DATASET_NAME打开
│   ├── 方法2: ExtractRasterFromFile任务
│   ├── 方法3: 默认方式打开
│   ├── 方法4: 添加空间参考
│   ├── 方法5: 打开TIF文件并堆叠（如果需要）
│   ├── 计算NDVI、NDWI、NDBI
│   └── 保存结果
├── 处理2025年数据 (process_year_data)
│   └── (同2021年流程)
└── 对比分析
    ├── NDVI变化分析
    ├── NDWI变化分析
    └── NDBI变化分析
```

### 2.2 数据打开流程（以2021年为例）

#### 步骤1: 尝试方法1
```
e.OpenRaster(mtlFile, DATASET_NAME='Surface Reflectance')
→ 成功打开，但只有4个波段
→ 没有空间参考信息
```

#### 步骤2: 方法4 - 添加空间参考
```
检测到raster没有空间参考
→ 从MTL XML文件读取投影参数
→ 创建MAP_INFO结构体
→ 使用set_spatial_ref_to_raster添加空间参考
  ├── 导出到临时文件（使用e.GetTemporaryFilename）
  ├── 使用ENVI_SETUP_HEAD添加空间参考
  └── 重新打开raster
→ 成功添加空间参考
```

#### 步骤3: 方法5 - 打开TIF文件
```
当前raster只有4个波段
→ 打开B1-B5的TIF文件
→ 为每个TIF文件添加空间参考
→ 使用ENVILayerStackRaster堆叠
→ 成功获得5个波段的raster
```

### 2.3 光谱指数计算流程

#### NDVI计算
```
波段数: 5
Red波段: b3 (索引2)
NIR波段: b4 (索引3)
表达式: (b4 - b3) / (b4 + b3)
→ 使用PixelwiseBandMathRaster任务计算
```

#### NDWI计算
```
使用MNDWI公式
Green波段: b2 (索引1)
SWIR1波段: b5 (索引4)
表达式: (b2 - b5) / (b2 + b5)
→ 使用PixelwiseBandMathRaster任务计算
```

#### NDBI计算
```
SWIR1波段: b5 (索引4)
NIR波段: b4 (索引3)
表达式: (b5 - b4) / (b5 + b4)
→ 使用PixelwiseBandMathRaster任务计算
```

### 2.4 对比分析流程

#### 空间参考检查
```
检查2021年和2025年影像的空间参考
→ 如果缺少，使用add_spatial_ref_to_raster_file添加
```

#### 影像对齐
```
使用ImageIntersection任务
→ 根据空间参考信息按地理坐标对齐
→ 确保两个时相的影像精确对齐
```

#### 差值计算
```
使用ImageBandDifference任务
→ 计算2025 - 2021的差值
→ 保存差值影像
→ 计算统计信息（均值、标准差、最小值、最大值）
```

## 三、关键技术点

### 3.1 set_spatial_ref_to_raster 函数

**功能**: 为raster设置空间参考信息

**处理流程**:
1. 保存原始raster的波长信息（如果存在）
2. 导出raster到临时文件
   - 优先使用固定路径
   - 失败时使用 `e.GetTemporaryFilename('dat')`
3. 使用 `ENVI_SETUP_HEAD` 添加空间参考
4. 重新打开raster
5. 恢复波长信息

**关键代码**:
```idl
; 导出到临时文件
tempFile = e.GetTemporaryFilename('dat')
inputRaster.Export, tempFile, 'ENVI'

; 添加空间参考
ENVI_SETUP_HEAD, FNAME=tempFile, MAP_INFO=mapInfo, /WRITE, /OPEN

; 重新打开
outputRaster = e.OpenRaster(tempFile)
```

### 3.2 ENVILayerStackRaster 函数

**功能**: 堆叠多个raster为一个多波段raster

**要求**:
- 至少一个raster有空间参考信息
- 需要先创建 `grid_definition`

**处理流程**:
```idl
; 创建grid_definition
gridTask = ENVITask('BuildGridDefinitionFromRaster')
gridTask.INPUT_RASTER = gridDefRaster
gridTask.Execute
gridDef = gridTask.OUTPUT_GRIDDEFINITION

; 堆叠
stackedRaster = ENVILayerStackRaster(srRasters, grid_definition=gridDef)
```

### 3.3 create_spatial_ref_from_mtl_xml 函数

**功能**: 从MTL XML文件读取投影参数并创建MAP_INFO

**读取的参数**:
- DATUM (基准面)
- UTM_ZONE (UTM投影带)
- CORNER_UL_PROJECTION_X_PRODUCT (左上角投影坐标X)
- CORNER_UL_PROJECTION_Y_PRODUCT (左上角投影坐标Y)
- GRID_CELL_SIZE_REFLECTIVE (像元大小)

**创建MAP_INFO**:
```idl
mapInfo = ENVI_MAP_INFO_CREATE( $
  /UTM, $
  ZONE=utmZone, $
  /NORTH, $
  DATUM=datum, $
  MC=[0.0, 0.0, ulX, ulY], $
  PS=[pixelSize, pixelSize] $
)
```

## 四、成功运行的关键因素

### 4.1 参考了test1110_finalndvi.pro的实现

1. **数据打开方式**: 使用 `DATASET_NAME='Surface Reflectance'` 参数
2. **空间参考处理**: 使用 `set_spatial_ref_to_raster` 函数
3. **导出方法**: 使用 `e.GetTemporaryFilename` 作为备选方案
4. **错误处理**: 即使空间参考添加失败，也继续处理

### 4.2 多层次容错机制

1. **5种数据打开方法**: 确保在各种情况下都能获取数据
2. **空间参考添加失败处理**: 保留原始raster继续处理
3. **导出方法备选**: 直接导出失败时使用临时文件方法
4. **波段数不足处理**: 打开单个TIF文件并堆叠

### 4.3 正确的函数使用

1. **ENVILayerStackRaster**: 用于堆叠多个raster
2. **BuildGridDefinitionFromRaster**: 创建grid_definition
3. **ImageIntersection**: 按地理坐标对齐影像
4. **ImageBandDifference**: 计算两个时相的差值

## 五、运行结果

### 5.1 2021年数据处理结果
- ✓ 成功打开数据（5个波段）
- ✓ 成功添加空间参考信息
- ✓ 成功计算NDVI、NDWI、NDBI
- ✓ 成功保存结果文件

### 5.2 2025年数据处理结果
- ✓ 成功打开数据（5个波段）
- ✓ 成功添加空间参考信息
- ✓ 成功计算NDVI、NDWI、NDBI
- ✓ 成功保存结果文件

### 5.3 对比分析结果
- ✓ 成功对齐2021年和2025年影像
- ✓ 成功计算NDVI、NDWI、NDBI差值
- ✓ 成功计算NDVI差值统计信息
- ✓ 成功保存所有差值文件

## 六、注意事项

### 6.1 波长信息设置
- 代码会尝试设置Landsat 9标准波长值
- 如果无法确定波段配置，会显示警告但继续处理
- 光谱指数计算不强制需要波长信息（使用波段索引）

### 6.2 空间参考信息
- 如果无法添加空间参考，代码会继续处理
- 没有空间参考时，无法进行精确的地理对齐
- 建议确保MTL XML文件存在且完整

### 6.3 临时文件管理
- 代码会在 `E:\1027IDL\ENVITaskTrainning\Temp` 目录创建临时文件
- 临时文件在程序运行后可能仍然存在，需要定期清理

## 七、代码改进建议

### 7.1 已实现的改进
1. ✓ 参考 `test1110_finalndvi.pro` 的实现方式
2. ✓ 使用 `e.GetTemporaryFilename` 作为导出备选方案
3. ✓ 改进错误处理，即使空间参考添加失败也继续处理
4. ✓ 使用 `ENVILayerStackRaster` 函数堆叠波段

### 7.2 可能的进一步改进
1. 自动清理临时文件
2. 添加更多的错误日志记录
3. 支持更多的光谱指数计算
4. 优化内存使用（及时关闭不需要的raster对象）

## 八、总结

代码成功运行的关键在于：

1. **多层次的数据打开策略**：5种方法确保数据获取成功
2. **正确的空间参考处理**：从MTL XML读取并添加空间参考
3. **合理的错误处理**：即使部分步骤失败，也继续处理
4. **参考成熟代码**：借鉴 `test1110_finalndvi.pro` 的实现方式
5. **正确的函数使用**：使用 `ENVILayerStackRaster` 等正确的函数

通过这些改进，代码能够成功处理Landsat 9数据，计算光谱指数，并进行对比分析。

