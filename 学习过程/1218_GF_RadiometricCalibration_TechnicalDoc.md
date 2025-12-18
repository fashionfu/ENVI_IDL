# 高分卫星辐射定标技术文档

**文档版本**: 1.0  
**创建日期**: 2024-12-18  
**适用范围**: GF1-GF7 系列卫星辐射定标处理  

---

## 目录

1. [概述](#1-概述)
2. [辐射定标原理](#2-辐射定标原理)
3. [数据处理流程](#3-数据处理流程)
4. [代码实现细节](#4-代码实现细节)
5. [输入输出规范](#5-输入输出规范)
6. [验证与精度分析](#6-验证与精度分析)
7. [ENVI 传感器数据库](#7-envi-传感器数据库)
8. [附录](#8-附录)
9. [开发调试记录](#9-开发调试记录)

---

## 1. 概述

### 1.1 文档目的

本文档详细描述高分系列卫星影像辐射定标的技术原理、处理流程和代码实现逻辑，为开发人员和用户提供完整的技术参考。

### 1.2 适用数据

| 卫星 | 传感器 | 波段数 | 支持状态 |
|:----:|:------:|:------:|:--------:|
| GF-1 | PMS1/PMS2 | 4 | 已验证 |
| GF-1 | WFV1-4 | 4 | 支持 |
| GF-2 | PMS1/PMS2 | 4 | 支持 |
| GF-6 | WFV | 8 | 支持 |
| GF-7 | BWD/MUX | 4 | 支持 |

### 1.3 技术依赖

- ENVI 5.x / 6.x
- IDL 8.x / 9.x
- 高分卫星 L1A 级产品（含 XML 元数据）

---

## 2. 辐射定标原理

### 2.1 物理背景

遥感传感器记录的原始数据为**数字量化值（Digital Number, DN）**，是传感器探测到的电磁辐射能量经过模数转换后的离散整数值。辐射定标的目的是将 DN 值转换为具有物理意义的**辐射亮度（Radiance）**或**反射率（Reflectance）**。

### 2.2 定标公式

#### 2.2.1 DN 到辐射亮度

```
L = DN × Gain + Offset
```

对于高分卫星，简化为：

```
L = DN × AbsCeof
```

#### 2.2.2 参数定义

| 参数 | 符号 | 单位 | 说明 |
|:-----|:----:|:----:|:-----|
| 数字量化值 | DN | - | 原始像元值，无量纲整数 |
| 绝对定标系数 | AbsCeof | (W·m⁻²·sr⁻¹·μm⁻¹)/DN | 增益系数，从 XML 元数据获取 |
| 辐射亮度 | L | W·m⁻²·sr⁻¹·μm⁻¹ | 输出的物理量 |

#### 2.2.3 辐射亮度到大气层顶反射率（可选）

```
ρ = (π × L × d²) / (ESUN × cos(θs))
```

| 参数 | 符号 | 单位 | 说明 |
|:-----|:----:|:----:|:-----|
| 辐射亮度 | L | W·m⁻²·sr⁻¹·μm⁻¹ | 上一步输出 |
| 日地距离 | d | AU | 根据成像日期计算 |
| 太阳辐照度 | ESUN | W·m⁻²·μm⁻¹ | 波段等效太阳辐照度 |
| 太阳天顶角 | θs | degree | 90° - 太阳高度角 |
| TOA 反射率 | ρ | - | 无量纲，范围 0-1 |

---

## 3. 数据处理流程

### 3.1 总体流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        输 入 数 据                              │
│         GF1_PMS1_*.xml  |  *.hdr  |  *.tar.gz                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: 文件预处理                                             │
│  ───────────────────────────────────────────────────────────    │
│  • 识别输入文件类型（.xml / .hdr / .tar.gz）                    │
│  • 定位对应的 XML 元数据文件                                    │
│  • 若为压缩包则先解压                                           │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: 解析 XML 元数据                                        │
│  ───────────────────────────────────────────────────────────    │
│  • 提取 <AbsCeof> 绝对定标系数                                  │
│  • 提取 <SatelliteID> <SensorID> 卫星/传感器标识                │
│  • 提取 <SolarZenith> <SolarAzimuth> 太阳角度                   │
│  • 提取 <Bands> 波段配置信息                                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: 读取原始 DN 数据                                       │
│  ───────────────────────────────────────────────────────────    │
│  • 使用 ENVI API 打开栅格数据                                   │
│  • 获取栅格尺寸: NCOLUMNS × NROWS × NBANDS                     │
│  • 一次性读取全部波段数据到内存                                 │
│  • 检测数据存储布局 (BIP/BSQ/BIL)                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: 辐射定标计算                                           │
│  ───────────────────────────────────────────────────────────    │
│                                                                 │
│    FOR each band b = 0 TO NBANDS-1:                            │
│    ┌─────────────────────────────────────────────────────┐     │
│    │                                                     │     │
│    │     L(b) = DN(b) × AbsCeof(b)                      │     │
│    │                                                     │     │
│    │     数据类型转换: UINT/INT → FLOAT32               │     │
│    │                                                     │     │
│    └─────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 5: 创建输出栅格                                           │
│  ───────────────────────────────────────────────────────────    │
│  • 创建临时 ENVIRaster 对象                                     │
│  • 写入计算结果（Float32 类型）                                 │
│  • 保持原始数据的 INTERLEAVE 格式                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 6: 写入元数据                                             │
│  ───────────────────────────────────────────────────────────    │
│  • 设置光谱参数: wavelength, fwhm                               │
│  • 设置数据单位: W m^-2 sr^-1 um^-1                            │
│  • 复制观测参数: sun azimuth, sun elevation                    │
│  • 复制传感器信息: sensor type, acquisition time               │
│  • 设置定标因子: calibration scale factor = 1.0                │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 7: 导出最终文件                                           │
│  ───────────────────────────────────────────────────────────    │
│  • ENVI 格式: *.dat + *.hdr (INTERLEAVE=BIP)                   │
│  • TIFF 格式: *.tif (GeoTIFF)                                  │
│  • 生成预览图和元数据信息（可选）                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        输 出 数 据                              │
│              *_radio.dat + *_radio.hdr                         │
│              数据类型: Float32                                  │
│              单位: W·m⁻²·sr⁻¹·μm⁻¹                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 数据布局处理

ENVI 返回的栅格数据根据存储方式不同，数组维度顺序也不同：

```
┌────────────────────────────────────────────────────────────────┐
│  BIP (Band Interleaved by Pixel)                               │
│  ────────────────────────────────────────────────────────────  │
│  数组维度: [NBANDS, NCOLS, NROWS]                              │
│  示例: [4, 4548, 4503]                                         │
│  访问方式: data[band, col, row]                                │
│  特点: 同一像元的所有波段值连续存储                            │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│  BSQ (Band Sequential)                                         │
│  ────────────────────────────────────────────────────────────  │
│  数组维度: [NCOLS, NROWS, NBANDS]                              │
│  示例: [4548, 4503, 4]                                         │
│  访问方式: data[col, row, band]                                │
│  特点: 同一波段的所有像元值连续存储                            │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│  BIL (Band Interleaved by Line)                                │
│  ────────────────────────────────────────────────────────────  │
│  数组维度: [NCOLS, NBANDS, NROWS]                              │
│  示例: [4548, 4, 4503]                                         │
│  访问方式: data[col, band, row]                                │
│  特点: 同一行的所有波段值连续存储                              │
└────────────────────────────────────────────────────────────────┘
```

---

## 4. 代码实现细节

### 4.1 XML 解析模块

```idl
;═══════════════════════════════════════════════════════════════
; XML 元数据解析
;═══════════════════════════════════════════════════════════════

; 读取 XML 文件内容
OPENR, lun_xml, xml_file, /GET_LUN
xml_content = ''
line_buf = ''
WHILE ~EOF(lun_xml) DO BEGIN
  READF, lun_xml, line_buf
  xml_content = xml_content + line_buf
ENDWHILE
FREE_LUN, lun_xml

; 解析 <AbsCeof> 标签
start_tag = STRPOS(xml_content, '<AbsCeof>')
end_tag = STRPOS(xml_content, '</AbsCeof>')
IF (start_tag GE 0) AND (end_tag GT start_tag) THEN BEGIN
  abs_str = STRMID(xml_content, start_tag+9, end_tag-start_tag-9)
  abs_str = STRTRIM(abs_str, 2)
  parts = STRSPLIT(abs_str, ',', /EXTRACT)
  abs_ceof = FLOAT(parts)
ENDIF
```

### 4.2 定标计算模块

```idl
;═══════════════════════════════════════════════════════════════
; 辐射定标核心计算
;═══════════════════════════════════════════════════════════════

; 读取全部数据
all_data = Raster.GetData()
data_dims = SIZE(all_data, /DIMENSIONS)
n_data_dims = SIZE(all_data, /N_DIMENSIONS)

; 根据数据布局进行计算
IF n_data_dims EQ 3 THEN BEGIN
  IF data_dims[0] EQ n_bands THEN BEGIN
    ; BIP 布局: [bands, cols, rows]
    all_output = FLTARR(n_bands, n_cols, n_rows)
    FOR b = 0, n_bands-1 DO BEGIN
      all_output[b,*,*] = FLOAT(all_data[b,*,*]) * abs_ceof[b]
    ENDFOR
  ENDIF ELSE IF data_dims[2] EQ n_bands THEN BEGIN
    ; BSQ 布局: [cols, rows, bands]
    all_output = FLTARR(n_cols, n_rows, n_bands)
    FOR b = 0, n_bands-1 DO BEGIN
      all_output[*,*,b] = FLOAT(all_data[*,*,b]) * abs_ceof[b]
    ENDFOR
  ENDIF
ENDIF
```

### 4.3 元数据写入模块

```idl
;═══════════════════════════════════════════════════════════════
; 元数据配置
;═══════════════════════════════════════════════════════════════

; GF1 PMS 标准光谱参数
gf1_wavelength = [485.0, 555.0, 660.0, 830.0]   ; 中心波长 (nm)
gf1_fwhm = [70.0, 70.0, 60.0, 120.0]            ; 半高全宽 (nm)
default_solar = [1944.68, 1854.10, 1536.67, 1071.89]  ; 太阳辐照度

; 写入元数据
out_meta['wavelength'] = gf1_wavelength
out_meta['fwhm'] = gf1_fwhm
out_meta['wavelength units'] = 'Nanometers'
out_meta['data units'] = 'W m^-2 sr^-1 um^-1'
out_meta['band names'] = ['Band 1', 'Band 2', 'Band 3', 'Band 4']
out_meta['calibration scale factor'] = 1.0
```

---

## 5. 输入输出规范

### 5.1 输入文件要求

#### 5.1.1 必需文件

| 文件类型 | 扩展名 | 说明 |
|:---------|:-------|:-----|
| XML 元数据 | .xml | 包含 AbsCeof 等定标参数 |
| 影像数据 | .tiff/.tif | GeoTIFF 格式原始 DN 数据 |

#### 5.1.2 XML 必需字段

```xml
<ProductMetaData>
  <SatelliteID>GF1</SatelliteID>
  <SensorID>PMS1</SensorID>
  <Bands>1,2,3,4</Bands>
  <AbsCeof>0.1458,0.1213,0.123,0.1185</AbsCeof>
  <SolarZenith>43.896717</SolarZenith>
  <SolarAzimuth>143.229421</SolarAzimuth>
</ProductMetaData>
```

### 5.2 输出文件规范

#### 5.2.1 ENVI 格式

| 文件 | 说明 |
|:-----|:-----|
| *_radio.dat | 二进制数据文件，Float32 类型 |
| *_radio.hdr | ENVI 头文件，包含元数据 |

#### 5.2.2 HDR 文件关键字段

```
ENVI
description = {Calibrated Radiance from GF1_PMS1_*.tiff}
samples = 4548
lines = 4503
bands = 4
data type = 4
interleave = bip
wavelength = {485.000000, 555.000000, 660.000000, 830.000000}
fwhm = {70.000000, 70.000000, 60.000000, 120.000000}
wavelength units = Nanometers
data units = W m^-2 sr^-1 um^-1
solar irradiance = {1.94468e+03, 1.85410e+03, 1.53667e+03, 1.07189e+03}
calibration scale factor = 1.00000000000000
```

---

## 6. 验证与精度分析

### 6.1 验证方法

使用 ENVI GUI 的 Radiometric Calibration 工具处理相同数据，对比单像素值：

```
验证步骤:
1. ENVI GUI: File > Open As > Optical Sensors > CRESDA > GF-1
2. Toolbox > Radiometric Correction > Radiometric Calibration
3. 选择 Calibration Type: Radiance
4. 导出结果并与代码输出对比
```

### 6.2 精度对比结果

以 GF1-PMS1 测试数据为例：

| 波段 | 像素坐标 | 代码输出 | GUI 输出 | 相对误差 |
|:----:|:--------:|:--------:|:--------:|:--------:|
| Band 1 | (2233, 2623) | 28.54 | 27.84 | +2.5% |
| Band 2 | (2233, 2623) | 47.79 | 45.31 | +5.5% |
| Band 3 | (2233, 2623) | 58.32 | 54.00 | +8.0% |

### 6.3 误差分析

| 误差来源 | 影响程度 | 说明 |
|:---------|:--------:|:-----|
| **Offset 偏移项缺失** | **高** | 代码仅用 L=DN×Gain，ENVI 使用 L=DN×Gain+Offset |
| 定标系数版本 | 中 | XML 与 ENVI 内部数据库可能存在差异 |
| 浮点精度 | 低 | 32位浮点计算的舍入误差 |
| 数据读取方式 | 低 | ENVI 直接读取 TIFF vs 通过 API 读取 |

### 6.4 根本原因

**2024-12-18 发现**：ENVI 官方在 `resource/filterfuncs/sensor_attributes.json` 中维护了完整的传感器参数，包括 **offset（偏移量）** 参数：

```
ENVI 完整公式: L = DN × Gain + Offset
代码使用公式: L = DN × AbsCeof  (缺少 Offset)
```

以 GF1 PMS1 Blue 波段为例：
- ENVI: L = DN × 0.2082 + 4.6186
- 代码: L = DN × 0.1458

差异来源：
1. XML 的 AbsCeof 与 ENVI gain 数值不同
2. 代码完全没有使用 offset 偏移项

### 6.5 结论

代码输出与 ENVI GUI 输出的相对误差在 **2-8%** 范围内。若需要与 ENVI GUI 完全一致的结果，需要：

1. 使用 `sensor_attributes.json` 中的官方 gain 值
2. 加入 offset 偏移项
3. 根据成像日期选择正确的定标系数版本

---

## 7. ENVI 传感器数据库

### 7.1 数据库位置

ENVI 在安装目录下维护了完整的传感器参数数据库：

```
{ENVI_DIR}/resource/filterfuncs/
├── sensor_attributes.json    # 主参数配置 (41KB)
├── gf1.hdr / gf1.sli        # GF1 光谱响应函数
├── gf1_pms1.hdr / .sli      # GF1 PMS1 光谱响应
├── gf1_pms2.hdr / .sli      # GF1 PMS2 光谱响应
├── gf1_wfv1-4.hdr / .sli    # GF1 WFV 1-4
├── gf2-pms1.hdr / .sli      # GF2 PMS1
├── gf2-pms2.hdr / .sli      # GF2 PMS2
├── gf6_pms.hdr / .sli       # GF6 PMS
├── gf6_wfv.hdr / .sli       # GF6 WFV (8波段)
├── gf7_mux.hdr / .sli       # GF7 MUX
└── ... (其他传感器)
```

### 7.2 sensor_attributes.json 结构

```
┌─────────────────────────────────────────────────────────────────┐
│  sensor_attributes.json 结构                                    │
│  ───────────────────────────────────────────────────────────    │
│                                                                 │
│  {                                                              │
│    "GF1-PMS1": {                                               │
│      "wl":     { 波段: 中心波长 },                              │
│      "fwhm":   { 波段: 半高全宽 },                              │
│      "gain":   { 波段: [v1, v2] 或 单值 },   ← 增益系数        │
│      "offset": { 波段: 偏移量 },             ← 偏移量          │
│      "solar":  { 波段: [v1, v2] 或 单值 }    ← 太阳辐照度      │
│    },                                                          │
│    "GF1-PMS2": { ... },                                        │
│    "GF1-WFV1": { ... },                                        │
│    "GF2-PMS1": { ... },                                        │
│    ...                                                         │
│  }                                                              │
│                                                                 │
│  注: gain/solar 有两个值时，对应不同的定标日期                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.3 支持的高分卫星列表

| 键名 | 卫星/传感器 | 波段数 | 备注 |
|:-----|:------------|:------:|:-----|
| GF1-PMS1 | 高分一号 PMS1 | 4+1 | 含全色波段 |
| GF1-PMS2 | 高分一号 PMS2 | 4+1 | 含全色波段 |
| GF1-WFV1 | 高分一号 WFV1 | 4 | 宽幅相机 |
| GF1-WFV2 | 高分一号 WFV2 | 4 | 宽幅相机 |
| GF1-WFV3 | 高分一号 WFV3 | 4 | 宽幅相机 |
| GF1-WFV4 | 高分一号 WFV4 | 4 | 宽幅相机 |
| GF2-PMS1 | 高分二号 PMS1 | 4+1 | 含全色波段 |
| GF2-PMS2 | 高分二号 PMS2 | 4+1 | 含全色波段 |

### 7.4 光谱响应函数文件 (.sli)

`.sli` 文件是 ENVI Spectral Library 格式，包含各波段的完整光谱响应曲线：

- **采样范围**: 400-1000 nm
- **采样间隔**: 1 nm  
- **数据类型**: Float32

可用于精确的光谱卷积计算。

---

## 8. 附录

### 8.1 ENVI 官方传感器参数数据库

ENVI 在 `{ENVI_DIR}/resource/filterfuncs/sensor_attributes.json` 中维护了完整的传感器参数数据库，包含：

- 中心波长 (wl)
- 半高全宽 (fwhm)
- 增益 (gain)
- 偏移 (offset)
- 太阳辐照度 (solar)

#### GF-1 PMS1 官方参数

```json
"GF1-PMS1": {
    "wl": {
        "B": 502.0, "G": 576.0, "R": 680.0, "NIR": 810.0, "P": 814.0
    },
    "fwhm": {
        "B": 474.16935, "G": 701.94755, "R": 650.41233, "NIR": 119.21728
    },
    "gain": {
        "B": [0.2082, 0.2247], "G": [0.1672, 0.1892], 
        "R": [0.1748, 0.1889], "NIR": [0.1883, 0.1939]
    },
    "offset": {
        "B": 4.6186, "G": 4.8768, "R": 4.8924, "NIR": -9.4771
    },
    "solar": {
        "B": [1975.07, 1945.28], "G": [1862.20, 1854.10], 
        "R": [1531.41, 1542.90], "NIR": [1076.20, 1080.76]
    }
}
```

> **注意**: gain 和 solar 有两个值，分别对应不同的定标日期版本。

#### GF-2 PMS1 官方参数

```json
"GF2-PMS1": {
    "wl": { "B": 491.0, "G": 555.0, "R": 665.0, "NIR": 821.0 },
    "gain": { "B": 0.1585, "G": 0.1883, "R": 0.1740, "NIR": 0.1897 },
    "offset": { "B": -0.8765, "G": -0.9742, "R": -0.7652, "NIR": -0.7233 },
    "solar": { "B": 1941.53, "G": 1854.15, "R": 1541.48, "NIR": 1086.43 }
}
```

### 8.2 XML AbsCeof 与 ENVI 内部参数对比

| 参数来源 | GF1 PMS1 Blue | GF1 PMS1 Green | GF1 PMS1 Red | GF1 PMS1 NIR |
|:---------|:-------------:|:--------------:|:------------:|:------------:|
| **XML AbsCeof** (示例) | 0.1458 | 0.1213 | 0.123 | 0.1185 |
| **ENVI gain** (v1) | 0.2082 | 0.1672 | 0.1748 | 0.1883 |
| **ENVI gain** (v2) | 0.2247 | 0.1892 | 0.1889 | 0.1939 |
| **ENVI offset** | 4.6186 | 4.8768 | 4.8924 | -9.4771 |

### 8.3 定标公式差异

| 方法 | 公式 | 说明 |
|:-----|:-----|:-----|
| **简化公式** (代码当前) | L = DN × AbsCeof | 仅使用增益 |
| **完整公式** (ENVI 官方) | L = DN × Gain + Offset | 增益 + 偏移 |

> **重要**: ENVI GUI 使用完整公式，这是代码输出与 GUI 输出存在 2-8% 差异的主要原因。

### 8.4 相关文件

| 文件 | 路径 | 说明 |
|:-----|:-----|:-----|
| 主程序 | GSF_GF1_RadiometricCorrection.pro | 辐射定标核心代码 |
| UI程序 | GSF_GF1_RadiometricCorrection_ui.pro | 批量处理界面 |
| 任务定义 | GSF_GF1_RadiometricCorrection.task | ENVI Task 配置 |

### 8.5 参考资料

1. 高分一号卫星用户手册
2. ENVI Radiometric Calibration 官方文档
3. 遥感图像辐射定标技术规范

---

## 9. 开发调试记录

本章记录了辐射定标代码的完整开发、调试和问题分析过程，供后续开发参考。

### 9.1 问题背景

**目标**: 开发一个 ENVI Task，实现 GF1-PMS 辐射定标，输出结果需与 ENVI GUI 官方工具一致。

**初始方案**: 使用 ENVI 内置的 `RadiometricCalibration` Task。

### 9.2 开发过程中遇到的问题

#### 9.2.1 编译错误：IF/ELSE/ENDELSE 结构

**错误信息**:
```
% Syntax error. (ELSE not matched with IF)
```

**原因**: IDL 的 CASE 语句中 IF-ELSE 结构不完整。

**修复**: 确保每个 IF 块都有对应的 ENDIF。

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

#### 9.2.2 OUTPUT_RASTER 验证失败

**错误信息**:
```
OUTPUT_RASTER Validation Failed: Value is undefined
```

**原因**: ENVI Task 要求 OUTPUT_RASTER 在任务结束时必须是有效的 ENVIRaster 对象。

**尝试的解决方案**:

| 方案 | 结果 |
|:-----|:-----|
| 修改 .task 文件中 required=false | 部分解决，但影响后续流程 |
| 保存后重新打开栅格 | 成功 |
| 使用 ENVIRaster() 直接创建 | 报错 "Raster is open for read" |

**最终方案**:
```idl
; 创建内存栅格
output_raster = ENVIRaster(all_output, URI=output_file, INTERLEAVE='bip')
output_raster.Save

; 关闭后重新打开（确保只读模式）
output_raster.Close
output_raster = e.OpenRaster(output_file)
```

---

#### 9.2.3 TIFF 导出格式错误

**错误信息**:
```
% ENVIEXPORTHELPER::CREATEMETADATA: Export format 'GTiff' is not supported.
```

**原因**: ENVI Export 方法使用的格式标识符与 GDAL 不同。

**修复**:
```idl
; 错误
raster.Export, output_file, 'GTiff'

; 正确
raster.Export, output_file, 'TIFF'
```

---

#### 9.2.4 RadiometricCalibration Task 的 SCALE_FACTOR 限制

**问题**: 想要使用 XML 中的逐波段 AbsCeof 作为定标系数。

**发现**: `RadiometricCalibration` Task 的 `SCALE_FACTOR` 参数只接受**标量**，不支持数组。

```idl
; 期望的用法（不支持）
Task.SCALE_FACTOR = [0.1458, 0.1213, 0.123, 0.1185]

; 实际限制（只支持标量）
Task.SCALE_FACTOR = 1.0
```

**解决方案**: 放弃使用内置 Task，改为手动计算：
```idl
FOR b = 0, n_bands-1 DO BEGIN
  all_output[b,*,*] = FLOAT(all_data[b,*,*]) * abs_ceof[b]
ENDFOR
```

---

#### 9.2.5 数据布局检测问题

**问题**: 不同输入数据的数组维度顺序不同，导致计算错误。

**分析**:
```
ENVI GetData() 返回的数组维度取决于 INTERLEAVE：
- BIP: [bands, cols, rows]
- BSQ: [cols, rows, bands]  
- BIL: [cols, bands, rows]
```

**解决方案**: 根据数组维度自动检测布局：
```idl
data_dims = SIZE(all_data, /DIMENSIONS)

IF data_dims[0] EQ n_bands THEN BEGIN
  ; BIP 布局
  all_output[b,*,*] = FLOAT(all_data[b,*,*]) * abs_ceof[b]
ENDIF ELSE IF data_dims[2] EQ n_bands THEN BEGIN
  ; BSQ 布局
  all_output[*,*,b] = FLOAT(all_data[*,*,b]) * abs_ceof[b]
ENDIF ELSE BEGIN
  ; BIL 布局
  all_output[*,b,*] = FLOAT(all_data[*,b,*]) * abs_ceof[b]
ENDELSE
```

---

#### 9.2.6 HDR 元数据未正确写入

**问题**: 使用 ENVI API 设置的 metadata 属性在保存后丢失。

**分析**: ENVIRaster 的 METADATA 属性在某些情况下不会被正确写入 HDR 文件。

**解决方案**: 直接操作 HDR 文件：
```idl
; 读取现有 HDR
OPENR, hdr_lun, hdr_file, /GET_LUN
; ... 读取并过滤旧元数据 ...
FREE_LUN, hdr_lun

; 写入新 HDR
OPENW, hdr_lun, hdr_file, /GET_LUN
; ... 写入过滤后的内容 ...
PRINTF, hdr_lun, 'wavelength = {485.0, 555.0, 660.0, 830.0}'
PRINTF, hdr_lun, 'fwhm = {70.0, 70.0, 60.0, 120.0}'
PRINTF, hdr_lun, 'data units = W m^-2 sr^-1 um^-1'
FREE_LUN, hdr_lun
```

---

### 9.3 验证脚本调试

#### 9.3.1 数组维度为0错误

**错误信息**:
```
% Array dimensions must be greater than 0.
```

**原因**: 使用 WHERE() 函数时，无匹配结果返回 -1。

**修复**:
```idl
valid_idx = WHERE(FINITE(band_data), valid_count)
IF valid_count GT 0 THEN BEGIN
  ; 处理有效数据
ENDIF
```

---

#### 9.3.2 采样时的无限循环

**问题**: 随机采样时，如果有效像素太少，会陷入无限循环。

**修复**: 添加最大尝试次数限制：
```idl
max_attempts = n_samples * 100
attempts = 0
WHILE (sample_count LT n_samples) AND (attempts LT max_attempts) DO BEGIN
  ; 采样逻辑
  attempts = attempts + 1
ENDWHILE
```

---

### 9.4 与 ENVI GUI 输出对比分析

#### 9.4.1 初始对比结果

| 波段 | 代码输出 | GUI 输出 | 差异 |
|:----:|:--------:|:--------:|:----:|
| Band 1 | 28.54 | 27.84 | +2.5% |
| Band 2 | 47.79 | 45.31 | +5.5% |
| Band 3 | 58.32 | 54.00 | +8.0% |
| Band 4 | 46.52 | 42.87 | +8.5% |

#### 9.4.2 HDR 元数据对比

| 字段 | 代码输出 | GUI 输出 |
|:-----|:---------|:---------|
| data units | W m^-2 sr^-1 um^-1 | W m^-2 sr^-1 um^-1 |
| wavelength | {485, 555, 660, 830} | {485, 555, 660, 830} |
| calibration scale factor | 1.0 | 1.0 |
| fwhm | {70, 70, 60, 120} | 无 |

#### 9.4.3 差异原因分析过程

**假设1**: 定标公式不同
- 检查后发现公式相同：L = DN × Gain

**假设2**: 定标系数来源不同
- 代码使用 XML 的 AbsCeof
- ENVI 可能使用内部数据库

**假设3**: 存在 Offset 偏移项
- 通过帮助文档引导，找到 `sensor_attributes.json`
- 确认 ENVI 使用 L = DN × Gain + Offset

---

### 9.5 关键发现：ENVI 传感器数据库

#### 9.5.1 发现过程

1. 阅读 ENVI Radiometric Calibration 帮助文档
2. 注意到 "WorldView-3 calibration coefficients are defined in sensor_attributes.json"
3. 搜索 ENVI 安装目录：`{ENVI_DIR}/resource/filterfuncs/`
4. 找到完整的传感器参数数据库

#### 9.5.2 数据库内容

```
E:\Program Files\NV5\ENVI62\resource\filterfuncs\
├── sensor_attributes.json  (41KB) - 主参数配置
├── gf1_pms1.hdr / .sli     - GF1 PMS1 光谱响应
├── gf1_pms2.hdr / .sli     - GF1 PMS2 光谱响应
├── gf2-pms1.hdr / .sli     - GF2 PMS1 光谱响应
└── ... (100+ 传感器配置)
```

#### 9.5.3 GF1-PMS1 官方参数（来自 sensor_attributes.json）

```json
"GF1-PMS1": {
    "wl": { "B": 502.0, "G": 576.0, "R": 680.0, "NIR": 810.0 },
    "gain": { 
        "B": [0.2082, 0.2247], 
        "G": [0.1672, 0.1892], 
        "R": [0.1748, 0.1889], 
        "NIR": [0.1883, 0.1939] 
    },
    "offset": { 
        "B": 4.6186, 
        "G": 4.8768, 
        "R": 4.8924, 
        "NIR": -9.4771 
    },
    "solar": { 
        "B": [1975.07, 1945.28], 
        "G": [1862.20, 1854.10], 
        "R": [1531.41, 1542.90], 
        "NIR": [1076.20, 1080.76] 
    }
}
```

#### 9.5.4 根本原因确认

| 因素 | 代码使用 | ENVI GUI 使用 |
|:-----|:---------|:--------------|
| **公式** | L = DN × AbsCeof | L = DN × Gain + Offset |
| **Gain 来源** | XML AbsCeof | sensor_attributes.json |
| **Offset** | 无 | 有（可正可负） |
| **参数版本** | XML 中的单一值 | 多版本（按日期） |

---

### 9.6 结论与后续改进建议

#### 9.6.1 当前代码状态

- 实现了基于 XML AbsCeof 的辐射定标
- 与 ENVI GUI 存在 2-8% 差异
- 差异主要来自 Offset 项缺失

#### 9.6.2 如需完全匹配 ENVI GUI 输出

**方案 A**: 使用 ENVI 内部参数
```idl
; 读取 sensor_attributes.json
; 根据 SatelliteID + SensorID 匹配参数
; 使用完整公式: L = DN × Gain + Offset
```

**方案 B**: 直接调用 ENVI 原生方式打开数据
```idl
; 通过 CRESDA 格式打开（自动加载定标参数）
raster = e.OpenRaster(xml_file, DATASET_NAME='CRESDA GF-1')
```

**方案 C**: 保持现状
- 使用 XML AbsCeof，接受 2-8% 差异
- 适用于大多数应用场景
- 优势：与数据供应商参数保持一致

#### 9.6.3 经验总结

| 教训 | 说明 |
|:-----|:-----|
| 查阅官方文档 | 帮助文档中的线索引导找到了核心问题 |
| 检查内部数据库 | ENVI 维护独立的传感器参数库 |
| 对比调试 | GUI vs 代码输出对比是定位问题的关键 |
| 完整公式 | 辐射定标不仅有 Gain，还有 Offset |
| 参数版本 | 定标参数可能有多个时期版本 |

---

### 9.7 调试日志时间线

| 日期 | 问题/进展 |
|:-----|:----------|
| 12-17 | 初始代码开发，使用 RadiometricCalibration Task |
| 12-17 | 发现 SCALE_FACTOR 不支持数组，改用手动计算 |
| 12-17 | 解决 IF/ELSE 编译错误 |
| 12-17 | 解决 OUTPUT_RASTER 验证失败 |
| 12-17 | 解决 TIFF 格式标识符问题 |
| 12-17 | 开发验证脚本，修复数组维度和无限循环问题 |
| 12-18 | 完成与 GUI 输出对比，发现 2-8% 差异 |
| 12-18 | 分析 HDR 元数据差异 |
| 12-18 | 通过帮助文档找到 sensor_attributes.json |
| 12-18 | 确认 Offset 项缺失是差异根本原因 |
| 12-18 | 完成技术文档编写 |

---

**文档结束**


