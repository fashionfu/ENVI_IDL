# 高分卫星SAM光谱角分类技术文档

**文档版本**: 1.0  
**创建日期**: 2024-12-18  
**适用范围**: GF1-GF7 系列卫星SAM光谱角分类处理  

---

## 目录

1. [概述](#1-概述)
2. [SAM分类原理](#2-sam分类原理)
3. [数据处理流程](#3-数据处理流程)
4. [代码实现细节](#4-代码实现细节)
5. [输入输出规范](#5-输入输出规范)
6. [端元光谱库](#6-端元光谱库)
7. [验证与精度分析](#7-验证与精度分析)
8. [附录](#8-附录)
9. [开发调试记录](#9-开发调试记录)

---

## 1. 概述

### 1.1 文档目的

本文档详细描述高分系列卫星影像SAM（Spectral Angle Mapper，光谱角制图）分类的技术原理、处理流程和代码实现逻辑，为开发人员和用户提供完整的技术参考。

### 1.2 适用数据

| 卫星 | 传感器 | 波段数 | 支持状态 |
|:----:|:------:|:------:|:--------:|
| GF-1 | PMS1/PMS2 | 4 | 已验证 |
| GF-1 | WFV1-4 | 4 | 支持 |
| GF-2 | PMS1/PMS2 | 4 | 支持 |
| GF-5 | AHSI | 330 | 已验证 |
| GF-6 | WFV | 8 | 支持 |
| GF-7 | BWD/MUX | 4 | 支持 |

### 1.3 技术依赖

- ENVI 5.x / 6.x
- IDL 8.x / 9.x
- 高分卫星预处理数据（辐射定标+大气校正后的反射率数据）
- 端元光谱库文件（.sli格式）

### 1.4 SAM分类特点

- **监督分类方法**：需要预先定义端元光谱库
- **基于光谱形状**：通过计算光谱角（而非光谱距离）进行分类
- **对光照条件不敏感**：光谱角不受光照强度影响，只关注光谱形状
- **适用于高光谱数据**：特别适合多波段/高光谱影像分类

---

## 2. SAM分类原理

### 2.1 物理背景

SAM（Spectral Angle Mapper）是一种基于光谱角度的监督分类方法。它将每个像素的光谱曲线视为多维空间中的向量，通过计算像素光谱向量与端元光谱向量之间的夹角来判断相似性。

### 2.2 光谱角计算公式

对于n维光谱空间中的两个向量（像素光谱和端元光谱），光谱角θ的计算公式为：

```
θ = arccos( (t · r) / (||t|| × ||r||) )
```

其中：
- `t` = 端元光谱向量 `[t₁, t₂, ..., tₙ]`
- `r` = 像素光谱向量 `[r₁, r₂, ..., rₙ]`
- `t · r` = 向量点积 = Σ(tᵢ × rᵢ)
- `||t||` = 端元向量模长 = √(Σtᵢ²)
- `||r||` = 像素向量模长 = √(Σrᵢ²)

### 2.3 分类规则

1. **计算光谱角**：对每个像素，计算其与所有端元光谱的光谱角
2. **选择最小角度**：找到最小光谱角对应的端元
3. **阈值判断**：
   - 如果最小光谱角 ≤ 阈值角度 → 分类为该端元
   - 如果最小光谱角 > 阈值角度 → 分类为"未分类"（Unclassified）

### 2.4 参数定义

| 参数 | 符号 | 单位 | 说明 |
|:-----|:----:|:----:|:-----|
| 光谱角阈值 | θₜₕᵣₑₛₕ | 弧度 | 通常为0.05-0.15（约2.9°-8.6°） |
| 端元光谱 | t | - | 参考光谱库中的标准光谱 |
| 像素光谱 | r | - | 影像中每个像素的光谱值 |
| 分类结果 | C | - | 像素所属的地物类别 |

### 2.5 优势与局限

**优势**：
- 对光照条件不敏感（只关注光谱形状）
- 适用于高光谱数据
- 计算效率高
- 结果直观（角度越小越相似）

**局限**：
- 需要预先定义端元光谱库
- 对噪声敏感
- 不适用于混合像元较多的区域
- 阈值选择需要经验

---

## 3. 数据处理流程

### 3.1 总体流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        输 入 数 据                              │
│        预处理影像 (*.dat)  |  端元光谱库 (*.sli / *.zip)       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: 文件预处理                                             │
│  ───────────────────────────────────────────────────────────    │
│  • 打开输入栅格数据                                             │
│  • 识别端元光谱库文件类型（.sli / .zip / .tar）                │
│  • 若为压缩包则先解压                                           │
│  • 验证栅格波段数与光谱库波长数匹配                             │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: 读取端元光谱库                                         │
│  ───────────────────────────────────────────────────────────    │
│  • 使用ENVISpectralLibrary打开.sli文件                          │
│  • 获取所有端元光谱名称                                         │
│  • 读取每个端元的光谱数据（反射率值）                           │
│  • 提取波长信息（WAVELENGTHS）                                   │
│  • 验证波长与栅格波段匹配                                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: 准备分类参数                                           │
│  ───────────────────────────────────────────────────────────    │
│  • 构建端元光谱矩阵 [n_bands, n_classes]                        │
│  • 生成分类颜色表（class lookup）                                │
│  • 构建分类名称数组（包含'Unclassified'）                        │
│  • 设置光谱角阈值（默认0.1弧度）                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: 执行SAM分类                                            │
│  ───────────────────────────────────────────────────────────    │
│  • 使用ENVITask('SpectralAngleMapperClassification')            │
│  • 输入参数：                                                    │
│    - INPUT_RASTER: 输入栅格                                     │
│    - MEAN: 端元光谱矩阵 [n_bands, n_classes]                    │
│    - THRESHOLD_ANGLE: 光谱角阈值                                │
│    - CLASS_NAMES: 端元名称（不含'Unclassified'）                 │
│  • 执行分类计算                                                  │
│  • 获取分类结果栅格                                             │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 5: 设置分类元数据                                         │
│  ───────────────────────────────────────────────────────────    │
│  • 设置classes: n_classes + 1（包含Unclassified）               │
│  • 设置class names: ['Unclassified', 端元1, 端元2, ...]        │
│  • 设置class lookup: RGB颜色表 [3, n_classes+1]                 │
│  • 写入元数据到栅格文件                                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 6: 分类后处理（可选）                                     │
│  ───────────────────────────────────────────────────────────    │
│  • ClassificationSmoothing: 分类平滑（去除噪声）                │
│    - KERNEL_SIZE: 平滑窗口大小（默认3）                          │
│  • ClassificationAggregation: 分类聚合（去除小斑块）            │
│    - MINIMUM_SIZE: 最小斑块大小（默认9像素）                     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 7: 导出最终结果                                           │
│  ───────────────────────────────────────────────────────────    │
│  • 栅格格式: *_SAMClass.dat + *.hdr                             │
│  • 矢量格式（可选）: *_SAMClass.shp                             │
│  • 生成预览图和元数据信息                                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        输 出 数 据                              │
│              *_SAMClass.dat + *_SAMClass.hdr                    │
│              数据类型: Byte (分类值 0-N)                        │
│              分类值: 0=Unclassified, 1-N=端元类别              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 端元光谱库读取流程

```
┌────────────────────────────────────────────────────────────────┐
│  端元光谱库读取方法选择                                         │
│  ────────────────────────────────────────────────────────────  │
│                                                                 │
│  方法1: ENVI_OPEN_FILE（优先使用）                              │
│  ───────────────────────────────────────────────────────────  │
│  • 一次性读取所有光谱数据                                       │
│  • 返回2D数组: [n_wavelengths, n_spectra]                      │
│  • 效率高，适合多个端元                                         │
│                                                                 │
│  方法2: ENVISpectralLibrary（备用）                            │
│  ───────────────────────────────────────────────────────────  │
│  • 逐个读取每个端元光谱                                         │
│  • 使用GetSpectrumFromLibrary Task                             │
│  • 兼容性好，适合复杂光谱库                                     │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### 3.3 数据维度处理

ENVI SAM分类Task对输入数据维度有严格要求：

```
┌────────────────────────────────────────────────────────────────┐
│  端元光谱矩阵维度转换                                          │
│  ────────────────────────────────────────────────────────────  │
│                                                                 │
│  光谱库原始格式: [n_wavelengths, n_spectra]                    │
│  例如: [320, 2]  (320个波段，2个端元)                          │
│                                                                 │
│  转置为: [n_spectra, n_wavelengths]                            │
│  例如: [2, 320]                                                │
│                                                                 │
│  最终Task格式: [n_bands, n_classes]                            │
│  例如: [320, 2]  (320个波段，2个分类)                          │
│                                                                 │
│  注意: 需要再次转置！                                          │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## 4. 代码实现细节

### 4.1 端元光谱库读取模块

```idl
;═══════════════════════════════════════════════════════════════
; 方法1: 使用ENVI_OPEN_FILE一次性读取所有光谱
;═══════════════════════════════════════════════════════════════

; 打开光谱库文件
ENVI_OPEN_FILE, input_sli, r_fid=sli_fid_all
IF sli_fid_all EQ -1 THEN BEGIN
  PRINT,'错误: 无法打开光谱库文件'
  RETURN
ENDIF

; 获取文件信息
ENVI_FILE_QUERY, sli_fid_all, nb=n_bands_sli, ns=n_spectra_sli

; 读取所有光谱数据（2D数组: [n_wavelengths, n_spectra]）
ENVI_GET_DATA, fid=sli_fid_all, dims=dims, pos=pos, data=spectra_all_data

; 提取波长信息
ENVI_FILE_QUERY, sli_fid_all, wavelength=wavelengths_from_file

; 关闭文件
ENVI_FILE_MQUERY, sli_fid_all, /close
```

### 4.2 光谱数据维度处理

```idl
;═══════════════════════════════════════════════════════════════
; 处理光谱数据维度，确保符合Task要求
;═══════════════════════════════════════════════════════════════

; 原始数据: [n_wavelengths, n_spectra]
spectrum_dims = SIZE(SPECTRUM, /DIMENSIONS)
n_dims = SIZE(SPECTRUM, /N_DIMENSIONS)

; 处理1D数组（单个端元的情况）
IF n_dims EQ 1 THEN BEGIN
  SPECTRUM = REFORM(SPECTRUM, [1, N_ELEMENTS(SPECTRUM)])
  spectrum_dims = SIZE(SPECTRUM, /DIMENSIONS)
ENDIF

; 转置为 [n_spectra, n_wavelengths]
IF spectrum_dims[0] EQ n_wavelengths THEN BEGIN
  SPECTRUM_FOR_DOIT = TRANSPOSE(SPECTRUM)
ENDIF ELSE BEGIN
  SPECTRUM_FOR_DOIT = SPECTRUM
ENDELSE

; 最终转置为 [n_bands, n_classes]（Task要求的格式）
MEAN_FOR_TASK = TRANSPOSE(SPECTRUM_FOR_DOIT)
```

### 4.3 SAM分类执行模块

```idl
;═══════════════════════════════════════════════════════════════
; 使用ENVITask执行SAM分类
;═══════════════════════════════════════════════════════════════

; 创建SAM分类Task
SAMTask = ENVITask('SpectralAngleMapperClassification')

; 设置输入参数
SAMTask.INPUT_RASTER = raster
SAMTask.MEAN = MEAN_FOR_TASK              ; [n_bands, n_classes]
SAMTask.THRESHOLD_ANGLE = spectral_angle  ; 默认0.1弧度
SAMTask.CLASS_NAMES = class_names_for_task ; 只包含端元名称

; 执行分类
SAMTask.Execute

; 获取分类结果
classRaster = SAMTask.OUTPUT_RASTER
```

### 4.4 分类元数据设置模块

```idl
;═══════════════════════════════════════════════════════════════
; 设置分类元数据
;═══════════════════════════════════════════════════════════════

; 分类数量（包含Unclassified）
n_classes = count + 1

; 设置classes元数据
classRaster.METADATA.AddItem, 'classes', n_classes

; 设置class names（包含'Unclassified'）
class_names = ['Unclassified', spectra_names[0:count-1]]
classRaster.METADATA.AddItem, 'class names', class_names

; 设置class lookup（RGB颜色表）
; lookup维度: [3, n_classes+1]
classRaster.METADATA.AddItem, 'class lookup', lookup

; 写入元数据
classRaster.WriteMetadata
```

### 4.5 分类后处理模块

```idl
;═══════════════════════════════════════════════════════════════
; 分类平滑（去除噪声）
;═══════════════════════════════════════════════════════════════

SmoothTask = ENVITask('ClassificationSmoothing')
SmoothTask.INPUT_RASTER = classRaster
SmoothTask.KERNEL_SIZE = smooth_window  ; 默认3
SmoothTask.OUTPUT_RASTER_URI = smooth_tmp_file
SmoothTask.Execute

;═══════════════════════════════════════════════════════════════
; 分类聚合（去除小斑块）
;═══════════════════════════════════════════════════════════════

AggregationTask = ENVITask('ClassificationAggregation')
AggregationTask.INPUT_RASTER = SmoothTask.OUTPUT_RASTER
AggregationTask.MINIMUM_SIZE = aggregation_size  ; 默认9像素
AggregationTask.OUTPUT_RASTER_URI = output_raster_uri
AggregationTask.Execute
```

---

## 5. 输入输出规范

### 5.1 输入文件要求

#### 5.1.1 必需文件

| 文件类型 | 扩展名 | 说明 |
|:---------|:-------|:-----|
| 预处理影像 | .dat | 辐射定标+大气校正后的反射率数据 |
| 端元光谱库 | .sli | ENVI标准光谱库格式 |
| 端元光谱库（压缩） | .zip / .tar | 压缩包格式，程序会自动解压 |

#### 5.1.2 输入影像要求

- **数据类型**: Float32（反射率值，范围0-1或0-100%）
- **波段数**: 必须与端元光谱库的波长数匹配
- **预处理级别**: 建议使用辐射定标+大气校正后的反射率数据
- **数据质量**: 去除云、阴影等异常区域

#### 5.1.3 端元光谱库要求

- **格式**: ENVI标准格式（.sli + .sli.hdr）
- **波长匹配**: 光谱库的波长数组必须与影像波段数一致
- **反射率范围**: 0-1（归一化）或0-100%（百分比）
- **端元数量**: 至少1个，建议3-10个

### 5.2 输出文件规范

#### 5.2.1 ENVI栅格格式

| 文件 | 说明 |
|:-----|:-----|
| *_SAMClass.dat | 二进制数据文件，Byte类型 |
| *_SAMClass.hdr | ENVI头文件，包含分类元数据 |

#### 5.2.2 HDR文件关键字段

```
ENVI
description = {SAM Classification Result}
samples = 2476
lines = 2536
bands = 1
data type = 1
interleave = bip
classes = 3
class names = {Unclassified, Endmember1, Endmember2}
class lookup = {
    0,   0,   0,
  255,   0,   0,
    0, 255,   0
}
```

#### 5.2.3 分类值定义

| 分类值 | 含义 | 说明 |
|:------:|:----:|:-----|
| 0 | Unclassified | 未分类（光谱角超过阈值） |
| 1 | Endmember 1 | 第一个端元类别 |
| 2 | Endmember 2 | 第二个端元类别 |
| ... | ... | ... |
| N | Endmember N | 第N个端元类别 |

#### 5.2.4 矢量格式（可选）

如果`convert_to_vector='YES'`，会生成Shapefile格式的分类结果：

| 文件 | 说明 |
|:-----|:-----|
| *_SAMClass.shp | 矢量数据文件 |
| *_SAMClass.shx | 索引文件 |
| *_SAMClass.dbf | 属性表文件 |
| *_SAMClass.prj | 投影信息文件 |

---

## 6. 端元光谱库

### 6.1 端元光谱库格式

端元光谱库是ENVI标准格式的`.sli`文件，包含：

- **光谱数据**: 每个端元的反射率值数组
- **波长信息**: 对应的波长数组（必须与影像波段匹配）
- **端元名称**: 每个端元的标识名称
- **元数据**: 波长单位、反射率缩放因子等

### 6.2 创建端元光谱库的方法

#### 方法1: 使用ENVI GUI工具（推荐）

1. **打开影像** → 在Layer Manager中双击影像
2. **创建ROI** → 右键影像 → ROI Tool → New Region → 绘制区域 → 命名
3. **提取光谱** → ROI Tool → Statistics → 查看平均光谱
4. **创建光谱库** → Toolbox → Spectral → Spectral Library → Spectral Library Builder
5. **导入ROI** → Import → From ROI → 选择ROI → 命名
6. **保存** → File → Save As → 选择位置和文件名

详细步骤请参考：`如何从影像创建端元光谱库.md`

#### 方法2: 使用IDL代码

```idl
; 打开影像和ROI
e = ENVI(/CURRENT)
raster = e.OpenRaster('your_image.dat')
rois = e.OpenROI('your_rois.xml')

; 获取训练统计信息
statsTask = ENVITask('TrainingClassificationStatistics')
statsTask.INPUT_RASTER = raster
statsTask.INPUT_ROI = rois
statsTask.Execute

; 创建光谱库
specLib = ENVISpectralLibrary()
wavelengths = raster.METADATA['Wavelength']

; 添加每个光谱
FOR i=0, N_ELEMENTS(statsTask.CLASS_NAMES)-1 DO BEGIN
  specLib.AddSpectra, $
    SPECTRUM=statsTask.MEAN[*, i], $
    WAVELENGTHS=wavelengths, $
    NAME=statsTask.CLASS_NAMES[i]
ENDFOR

; 保存光谱库
specLib.Save, 'endmembers.sli'
```

### 6.3 端元选择原则

1. **纯净性**: 选择纯净的地物区域，避免混合像元
2. **代表性**: 每个地物类型选择多个样本区域
3. **典型性**: 选择典型、常见的地物样本
4. **覆盖性**: 覆盖研究区域的主要地物类型
5. **数量**: 建议3-10个端元（根据分类需求）

### 6.4 光谱库验证

在分类前，程序会自动验证：

- ✅ 光谱库波长数与影像波段数匹配
- ✅ 光谱库文件格式正确
- ✅ 端元数量 > 0
- ✅ 反射率值在合理范围内

---

## 7. 验证与精度分析

### 7.1 验证方法

#### 方法1: 目视检查

1. 在ENVI中打开分类结果
2. 叠加原始影像进行对比
3. 检查分类结果是否符合地物分布规律
4. 检查是否存在明显的分类错误

#### 方法2: 混淆矩阵分析

1. 创建验证ROI（真实地物样本）
2. 使用ENVI的Confusion Matrix工具
3. 计算总体精度、Kappa系数等指标

#### 方法3: 与参考数据对比

1. 使用已知的地物分布图作为参考
2. 对比分类结果与参考数据的一致性
3. 计算分类精度指标

### 7.2 精度影响因素

| 因素 | 影响 | 改进方法 |
|:-----|:----:|:---------|
| 端元质量 | 高 | 选择纯净、典型的端元样本 |
| 光谱角阈值 | 中 | 根据数据质量调整阈值（0.05-0.15） |
| 预处理质量 | 高 | 使用辐射定标+大气校正后的数据 |
| 数据噪声 | 中 | 使用分类平滑去除噪声 |
| 混合像元 | 高 | 避免选择混合像元区域作为端元 |

### 7.3 参数调优建议

#### 光谱角阈值（THRESHOLD_ANGLE）

| 阈值范围 | 特点 | 适用场景 |
|:--------:|:----:|:---------|
| 0.05-0.08 | 严格，分类精度高但可能漏分 | 高质量数据，地物类型明确 |
| 0.08-0.12 | 平衡，推荐使用 | 一般质量数据，默认值0.1 |
| 0.12-0.15 | 宽松，分类覆盖率高但可能错分 | 低质量数据，噪声较多 |

#### 平滑窗口（KERNEL_SIZE）

| 窗口大小 | 特点 | 适用场景 |
|:--------:|:----:|:---------|
| 3×3 | 轻微平滑，保留细节 | 高分辨率数据，地物边界清晰 |
| 5×5 | 中等平滑，推荐使用 | 一般分辨率数据，默认值3 |
| 7×7 | 强平滑，可能丢失细节 | 低分辨率数据，噪声较多 |

#### 聚合大小（MINIMUM_SIZE）

| 最小斑块 | 特点 | 适用场景 |
|:--------:|:----:|:---------|
| 5-9像素 | 保留小斑块，细节丰富 | 高分辨率数据，小地物较多 |
| 9-25像素 | 平衡，推荐使用 | 一般分辨率数据，默认值9 |
| 25-50像素 | 去除小斑块，结果平滑 | 低分辨率数据，只关注大地物 |

---

## 8. 附录

### 8.1 ENVI Task API

SAM分类使用以下ENVI Task：

| Task名称 | 功能 | 关键参数 |
|:---------|:----:|:---------|
| SpectralAngleMapperClassification | SAM分类 | INPUT_RASTER, MEAN, THRESHOLD_ANGLE, CLASS_NAMES |
| ClassificationSmoothing | 分类平滑 | INPUT_RASTER, KERNEL_SIZE |
| ClassificationAggregation | 分类聚合 | INPUT_RASTER, MINIMUM_SIZE |
| ClassificationToShapefile | 转矢量 | INPUT_RASTER, EXPORT_CLASSES, OUTPUT_VECTOR_URI |

### 8.2 相关文件

| 文件 | 路径 | 说明 |
|:-----|:-----|:-----|
| 主程序 | GSF_GF1_SAMClassfication.pro | SAM分类核心代码 |
| UI程序 | GSF_GF1_SAMClassfication_ui.pro | 批量处理界面 |
| 任务定义 | GSF_GF1_SAMClassfication.task | ENVI Task配置 |
| 端元创建指南 | 如何从影像创建端元光谱库.md | 端元光谱库创建方法 |
| 端元说明 | 端元光谱库说明.md | 端元光谱库格式说明 |

### 8.3 参考资料

1. ENVI Spectral Angle Mapper 官方文档
2. 遥感图像分类技术规范
3. 高光谱遥感分类方法研究

### 8.4 常见问题

**Q: 分类结果中"Unclassified"像元过多？**  
A: 可能是光谱角阈值设置过小，或端元光谱库不完整。建议：
- 增大光谱角阈值（如0.12-0.15）
- 检查端元光谱库是否覆盖所有主要地物类型
- 检查输入数据质量（是否有云、阴影等）

**Q: 分类结果出现明显的错分？**  
A: 可能是端元选择不当或数据预处理问题。建议：
- 重新选择更纯净、典型的端元样本
- 检查输入数据是否经过辐射定标和大气校正
- 调整光谱角阈值

**Q: 如何提高分类精度？**  
A: 建议：
- 使用高质量的预处理数据（辐射定标+大气校正）
- 选择纯净、典型的端元样本
- 根据数据质量调整光谱角阈值
- 使用分类平滑和聚合去除噪声

**Q: 端元光谱库的波长必须与影像完全匹配吗？**  
A: 是的，波长数组必须与影像波段数一致，否则程序会报错。如果波长不匹配，需要使用ENVI的Spectral Resampling工具进行重采样。

---

## 9. 开发调试记录

本章记录了SAM分类代码的完整开发、调试和问题分析过程，供后续开发参考。

### 9.1 问题背景

**目标**: 开发一个ENVI Task，实现GF1-PMS和GF5-AHSI数据的SAM光谱角分类，支持端元光谱库输入、分类平滑和聚合后处理。

**初始方案**: 使用ENVI内置的`ENVI_DOIT`过程执行SAM分类。

### 9.2 开发过程中遇到的问题

#### 9.2.1 编译错误：IF/ELSE/ENDELSE结构

**错误信息**:
```
% Type of end does not match statement (ENDELSE expected). At: ..., Line 247
```

**原因**: IDL的IF-ELSE结构不完整，缺少ENDIF。

**修复**: 确保每个IF块都有对应的ENDIF。

```idl
; 错误写法
IF condition THEN BEGIN
  ...
ELSE BEGIN
  ...
ENDELSE

; 正确写法
IF condition THEN BEGIN
  ...
ENDIF ELSE BEGIN
  ...
ENDELSE
```

---

#### 9.2.2 端元光谱库读取：1D数组问题

**错误信息**:
```
Attempt to subscript SPECTRUM_DIMS with <LONG (1)> is out of range.
```

**原因**: 当光谱库只有一个端元时，`SPECTRUM`是1D数组`[n_wavelengths]`，无法访问`spectrum_dims[1]`。

**修复**: 检测1D数组并重塑为2D数组。

```idl
; 检测1D数组
n_dims = SIZE(SPECTRUM, /N_DIMENSIONS)
IF n_dims EQ 1 THEN BEGIN
  ; 重塑为2D数组 [1, n_wavelengths]
  SPECTRUM = REFORM(SPECTRUM, [1, N_ELEMENTS(SPECTRUM)])
ENDIF
```

---

#### 9.2.3 ENVI_DOIT输出文件无效

**错误信息**:
```
File: ... Unable to recognize this file as a standard format.
```

**原因**: `ENVI_DOIT`创建的输出文件格式不正确，可能是0字节文件或缺少`.hdr`文件。

**尝试的解决方案**:

| 方案 | 结果 |
|:-----|:-----|
| 手动创建.hdr文件 | 部分解决，但格式仍不正确 |
| 添加文件存在性检查 | 无效，文件存在但格式错误 |
| 使用ENVITask替代 | **成功** |

**最终方案**: 放弃`ENVI_DOIT`，改用`ENVITask('SpectralAngleMapperClassification')`。

```idl
; 旧方法（不可靠）
ENVI_DOIT, 'sam_doit', ..., OUT_NAME=out_name

; 新方法（可靠）
SAMTask = ENVITask('SpectralAngleMapperClassification')
SAMTask.INPUT_RASTER = raster
SAMTask.MEAN = MEAN_FOR_TASK
SAMTask.THRESHOLD_ANGLE = spectral_angle
SAMTask.Execute
classRaster = SAMTask.OUTPUT_RASTER
```

---

#### 9.2.4 MEAN参数维度错误

**错误信息**:
```
TARGET array must have the same number of bands as INPUT_RASTER
```

**原因**: `SpectralAngleMapperClassification` Task的`MEAN`参数要求格式为`[n_bands, n_classes]`，而不是`[n_classes, n_bands]`。

**修复**: 转置`MEAN`参数。

```idl
; 原始格式: [n_classes, n_bands]
SPECTRUM_FOR_DOIT = [n_classes, n_bands]

; Task要求的格式: [n_bands, n_classes]
MEAN_FOR_TASK = TRANSPOSE(SPECTRUM_FOR_DOIT)
```

---

#### 9.2.5 CLASS_NAMES参数错误

**错误信息**:
```
The array should have the same number of elements as classes.
```

**原因**: `CLASS_NAMES`参数应该只包含端元名称（数量等于`MEAN`中的分类数），不应该包含'Unclassified'。

**修复**: 创建只包含端元名称的数组。

```idl
; 错误：包含'Unclassified'
class_names = ['Unclassified', spectra_names[0:count-1]]

; 正确：只包含端元名称
class_names_for_task = spectra_names[0:count-1]
SAMTask.CLASS_NAMES = class_names_for_task
```

---

#### 9.2.6 CLASS_COLORS参数错误

**错误信息**:
```
The array should have the same number of elements as classes.
```

**原因**: `CLASS_COLORS`参数应该只包含端元颜色（数量等于分类数），不应该包含'Unclassified'的颜色。

**修复**: 从完整的`lookup`数组中提取端元颜色。

```idl
; lookup维度: [3, n_classes+1] (包含Unclassified)
; 提取端元颜色: [3, n_classes]
lookup_for_task = lookup[*, 1:count]
SAMTask.CLASS_COLORS = lookup_for_task
```

---

#### 9.2.7 OUTPUT_RASTER无效问题

**错误信息**:
```
SAM分类Task未返回有效的栅格对象
File: ... Unknown dataset.
```

**原因**: 即使`SAMTask.Execute`成功执行，`SAMTask.OUTPUT_RASTER`也可能无效，特别是当设置了`OUTPUT_RASTER_URI`时。

**修复**: 不设置`OUTPUT_RASTER_URI`，让Task自动管理临时输出。

```idl
; 错误：设置OUTPUT_RASTER_URI可能导致输出无效
SAMTask.OUTPUT_RASTER_URI = out_name

; 正确：不设置OUTPUT_RASTER_URI，让Task自动创建
SAMTask = ENVITask('SpectralAngleMapperClassification')
SAMTask.INPUT_RASTER = raster
SAMTask.MEAN = MEAN_FOR_TASK
SAMTask.Execute
classRaster = SAMTask.OUTPUT_RASTER  ; Task自动创建临时文件
```

---

#### 9.2.8 文件删除SPAWN错误

**错误信息**:
```
SPAWN: Error executing spawn command.
```

**原因**: `FILES_DELETE`在某些情况下会触发SPAWN错误，导致程序中断。

**修复**: 将所有`FILES_DELETE`调用包裹在`CATCH`块中。

```idl
; 错误：可能导致SPAWN错误
FILES_DELETE, temp_file

; 正确：使用CATCH处理错误
CATCH, err_delete
IF err_delete EQ 0 THEN BEGIN
  FILES_DELETE, temp_file
  PRINT,'删除临时文件成功'
  CATCH, /CANCEL
ENDIF ELSE BEGIN
  CATCH, /CANCEL
  PRINT,'删除临时文件失败（跳过）: ',!ERROR_STATE.MSG
ENDELSE
```

---

### 9.3 端元光谱库读取优化

#### 9.3.1 问题：逐个读取效率低

**初始实现**: 使用`ENVISpectralLibrary.GetSpectrum()`逐个读取每个端元光谱。

**问题**: 当端元数量较多时，效率低下。

**优化方案**: 使用`ENVI_OPEN_FILE`一次性读取所有光谱数据。

```idl
; 方法1: 一次性读取（高效）
ENVI_OPEN_FILE, input_sli, r_fid=sli_fid_all
ENVI_GET_DATA, fid=sli_fid_all, data=spectra_all_data
; spectra_all_data维度: [n_wavelengths, n_spectra]

; 方法2: 逐个读取（备用）
FOR i=0, n_spectra-1 DO BEGIN
  spectrum = specLib.GetSpectrum(spectra_names[i])
ENDFOR
```

---

#### 9.3.2 问题：波长信息获取

**问题**: 不同格式的光谱库，波长信息存储位置不同。

**解决方案**: 多种方法尝试获取波长信息。

```idl
; 方法1: 从第一个光谱获取
first_spectrum = specLib.GetSpectrum(spectra_names[0])
IF first_spectrum.HasKey('WAVELENGTHS') THEN BEGIN
  wavelengths = first_spectrum['WAVELENGTHS']
ENDIF

; 方法2: 从文件元数据获取
ENVI_FILE_QUERY, sli_fid_all, wavelength=wavelengths_from_meta

; 方法3: 使用索引作为波长（临时方案）
IF wavelengths EQ !NULL THEN BEGIN
  wavelengths = FINDGEN(n_wavelengths) + 1.0
ENDIF
```

---

### 9.4 调试过程中的关键发现

#### 9.4.1 ENVI_DOIT vs ENVITask

| 方法 | 优点 | 缺点 | 结论 |
|:-----|:----:|:----:|:-----|
| ENVI_DOIT | 简单直接 | 输出文件格式不稳定，易出错 | ❌ 不推荐 |
| ENVITask | 稳定可靠，自动管理输出 | 参数格式要求严格 | ✅ **推荐使用** |

#### 9.4.2 参数格式要求

`SpectralAngleMapperClassification` Task对参数格式有严格要求：

| 参数 | 格式 | 说明 |
|:-----|:----:|:-----|
| MEAN | `[n_bands, n_classes]` | 第一个维度必须是波段数 |
| CLASS_NAMES | `[n_classes]` | 只包含端元名称，不含'Unclassified' |
| CLASS_COLORS | `[3, n_classes]` | RGB颜色表，只包含端元颜色 |

#### 9.4.3 元数据设置

分类结果的元数据需要在Task执行后手动设置：

```idl
; Task执行后设置元数据
classRaster.METADATA.AddItem, 'classes', n_classes
classRaster.METADATA.AddItem, 'class names', class_names  ; 包含'Unclassified'
classRaster.METADATA.AddItem, 'class lookup', lookup        ; 包含'Unclassified'颜色
classRaster.WriteMetadata
```

---

### 9.5 调试日志时间线

| 日期 | 问题/进展 |
|:-----|:----------|
| 12-18 | 初始代码开发，使用ENVI_DOIT |
| 12-18 | 发现ENVI_DOIT输出文件格式问题 |
| 12-18 | 修复IF/ELSE编译错误 |
| 12-18 | 修复1D数组维度问题 |
| 12-18 | 修复MEAN参数维度问题 |
| 12-18 | 修复CLASS_NAMES参数问题 |
| 12-18 | 修复CLASS_COLORS参数问题 |
| 12-18 | 修复OUTPUT_RASTER无效问题 |
| 12-18 | 优化端元光谱库读取（ENVI_OPEN_FILE） |
| 12-18 | 添加文件删除错误处理（CATCH） |
| **12-18** | **代码验证通过，SAM分类功能正常** |

---

### 9.6 最终解决方案总结

#### 9.6.1 核心实现

**SAM分类执行**:
```idl
SAMTask = ENVITask('SpectralAngleMapperClassification')
SAMTask.INPUT_RASTER = raster
SAMTask.MEAN = MEAN_FOR_TASK              ; [n_bands, n_classes]
SAMTask.THRESHOLD_ANGLE = spectral_angle  ; 默认0.1
SAMTask.CLASS_NAMES = class_names_for_task ; 只包含端元名称
SAMTask.Execute
classRaster = SAMTask.OUTPUT_RASTER       ; Task自动创建
```

**元数据设置**:
```idl
n_classes = count + 1
classRaster.METADATA.AddItem, 'classes', n_classes
classRaster.METADATA.AddItem, 'class names', class_names  ; 包含'Unclassified'
classRaster.METADATA.AddItem, 'class lookup', lookup      ; 包含'Unclassified'颜色
classRaster.WriteMetadata
```

#### 9.6.2 关键经验总结

| 教训 | 说明 |
|:-----|:-----|
| 使用ENVITask而非ENVI_DOIT | ENVITask更稳定可靠 |
| 注意参数维度要求 | Task对参数格式有严格要求 |
| CLASS_NAMES不含'Unclassified' | Task参数与元数据不同 |
| 不设置OUTPUT_RASTER_URI | 让Task自动管理输出 |
| 错误处理要完善 | 使用CATCH包裹所有可能失败的操作 |
| 端元读取优化 | 使用ENVI_OPEN_FILE一次性读取 |

---

### 9.7 代码更新日志

#### 版本1.0（2024-12-18）

**主要功能**:
- ✅ SAM光谱角分类
- ✅ 端元光谱库读取（支持.sli/.zip/.tar）
- ✅ 分类平滑和聚合后处理
- ✅ 分类结果转矢量（可选）
- ✅ 完整的错误处理和调试信息

**技术实现**:
- 使用`ENVITask('SpectralAngleMapperClassification')`执行分类
- 支持`ENVI_OPEN_FILE`和`ENVISpectralLibrary`两种读取方法
- 自动处理1D/2D数组维度转换
- 完善的元数据设置和文件管理

**已知问题**:
- 无

**后续改进建议**:
- 支持更多光谱库格式
- 添加分类精度评估功能
- 优化大文件处理性能

---

**文档结束**

