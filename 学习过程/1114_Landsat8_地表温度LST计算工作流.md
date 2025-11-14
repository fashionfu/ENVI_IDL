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
- 从Landsat 8 MTL文件读取多光谱和热红外数据
- 计算NDVI（归一化植被指数）
- 计算植被覆盖度
- 计算地表发射率
- 热红外波段辐射定标
- 计算黑体温度
- 计算最终地表温度（单位：摄氏度）

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

5. **地表温度（LST）计算**：
   ```
   LST = K2 / ln(K1 / Tb + 1) - 273.15
   ```
   其中：
   - K1、K2：热红外波段定标常数（从MTL文件元数据读取）

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

#### 5. `set_spatial_ref_to_raster`
- **功能**：为raster对象设置空间参考信息
- **参数**：
  - `inputRaster`：输入raster对象
  - `mapInfo`：MAP_INFO结构体
- **返回值**：添加了空间参考的raster对象
- **处理流程**：
  1. 导出raster到临时ENVI文件
  2. 使用`ENVI_SETUP_HEAD`设置MAP_INFO
  3. 重新打开raster并返回

### 主程序流程

#### 步骤1：数据准备
```idl
; 打开多光谱和热红外数据
mss_raster = e.OpenRaster(mtl_file, DATASET_NAME='Multispectral')
the_raster = e.OpenRaster(mtl_file, DATASET_NAME='Thermal')

; 提取热红外定标常数K1和K2
k1 = (the_raster.METADATA['THERMAL K1'])[0]
k2 = (the_raster.METADATA['THERMAL K2'])[0]
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

#### 步骤7：结果显示
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

### 4. 大气参数
本程序使用固定的大气参数：
- 大气透过率（τ）：0.9
- 上行辐射（Lu）：0.75 W/m²/sr/μm
- 下行辐射（Ld）：1.29 W/m²/sr/μm

**注意**：这些是默认值，实际应用中可能需要根据具体的大气条件调整。

## 输入要求

### 数据格式
- **Landsat 8 Level 1数据**（包含MTL文件）
- **必需的数据集**：
  - `Multispectral`：多光谱数据（用于NDVI计算）
  - `Thermal`：热红外数据（Band 10，用于温度计算）

### MTL文件要求
- MTL文件必须包含以下投影参数：
  - `UTM_ZONE`：UTM投影带
  - `DATUM`：基准面（如WGS84）
  - `CORNER_UL_PROJECTION_X_PRODUCT`：左上角投影坐标X
  - `CORNER_UL_PROJECTION_Y_PRODUCT`：左上角投影坐标Y
  - `GRID_CELL_SIZE_REFLECTIVE`：像元大小

## 输出结果

- **最终输出**：地表温度栅格（单位：摄氏度）
- **中间结果**（虚拟栅格，不保存）：
  - NDVI栅格
  - 植被覆盖度栅格
  - 地表发射率栅格
  - 热红外辐射值栅格
  - 黑体温度栅格

## 使用示例

```idl
; 修改MTL文件路径
mtl_file = 'E:\1021WaterData\201\0-原始数据\LC81240382017118LGN00\LC81240382017118LGN00_MTL.txt'

; 运行程序
test_Landsat8_LST_workflow
```

## 注意事项

1. **空间参考**：如果数据缺少空间参考，程序会自动从MTL文件读取并添加
2. **临时文件**：程序会在`E:\1027IDL\ENVITaskTrainning\Temp`目录创建临时文件
3. **处理时间**：大型影像的处理可能需要较长时间
4. **内存使用**：确保有足够的内存处理大型栅格数据

## 算法参考

本程序使用的单窗算法基于以下研究：
- 单窗算法（Single Window Algorithm）用于Landsat热红外数据的地表温度反演
- 考虑了地表发射率、大气透过率和大气辐射的影响

## 代码改进历史

### 主要改进点
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

## 相关文件

- `landsat9_spectral_indices.pro`：光谱指数计算（参考了空间参考处理方法）
- `landsat9_classification.pro`：分类处理（参考了空间参考处理方法）
- `test1110_finalndvi.pro`：NDVI计算示例

## 作者信息

- **原始作者**：duhj@geoscene.cn
- **原始日期**：2018-3-15
- **改进日期**：2025（添加空间参考处理功能）


