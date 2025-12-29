# GF1 辐射定标与 FLAASH 大气校正兼容性技术报告

## 文档信息
- **文档标题**: GF1 辐射定标与 FLAASH 大气校正兼容性技术报告
- **创建日期**: 2025-12-29
- **适用范围**: GF1-PMS 系列卫星数据辐射定标和大气校正
- **相关模块**: 
  - `GSF_GF1_RadiometricCorrection`（辐射定标）
  - `GSF_GF1_FLAASH_AtmosphericCorrection`（大气校正）

---

## 执行摘要

本报告记录了 GF1 辐射定标工具与 FLAASH 大气校正工具兼容性问题的完整排查和解决过程。通过系统性的对比验证，发现并修复了多个关键问题，最终实现了与官方工具完全一致的大气校正结果（像素值差异为 0）。

### 核心发现
1. **栅格对象类型**：FLAASH 要求特定的栅格对象类型（使用 `ApplyGainOffset` Task 创建）
2. **元数据位置**：关键元数据（如 `sun azimuth`）需要同时写入 HDR 文件和栅格对象的 METADATA 属性
3. **参数一致性**：FWHM、calibration scale factor、input_scale 等参数必须与官方工具完全一致

---

## 目录

1. [问题背景](#1-问题背景)
2. [问题排查过程](#2-问题排查过程)
3. [关键技术发现](#3-关键技术发现)
4. [最终解决方案](#4-最终解决方案)
5. [验证结果](#5-验证结果)
6. [技术要点总结](#6-技术要点总结)
7. [代码示例](#7-代码示例)

---

## 1. 问题背景

### 1.1 初始问题

在使用自定义辐射定标工具处理 GF1-PMS 数据后，尝试进行 FLAASH 大气校正时，遇到以下错误：

```
ERROR: Task execution failed: Object reference type required in this context: REF.
```

同时，官方辐射定标工具的输出可以正常进行 FLAASH 大气校正，说明问题出在自定义辐射定标工具的输出格式或元数据上。

### 1.2 验证方法

通过对比验证确定问题环节：
1. **辐射定标对比**：官方工具 vs 自定义工具
2. **元数据对比**：HDR 文件参数差异分析
3. **像素值对比**：随机采样 100 个像素进行数值比较

验证结果：
- 辐射定标像素值完全一致（平均差异 < 0.000001）✓
- 问题出在大气校正环节 ✗

---

## 2. 问题排查过程

### 2.1 第一阶段：FLAASH 任务执行失败

#### 问题表现
```
ERROR: Task execution failed: Object reference type required in this context: REF.
```

#### 排查方向
1. 检查 FLAASH 必需参数是否正确设置
2. 检查参数类型是否正确（对象 vs 标量）

#### 初步尝试（未成功）
- ❌ 手动设置 `ACQUISITION_TIME`、`SENSOR_ALTITUDE`、`INPUT_SCALE`
- ❌ 尝试不设置某些参数，让 FLAASH 自动读取
- ❌ 调整元数据标签名和格式

### 2.2 第二阶段：坐标系统元数据错误

#### 问题表现
使用官方 FLAASH GUI 工具处理自定义辐射定标结果时：
```
FLAASH Easy-To-Use [NEW]
Illegal variable attribute: COORD SYS STR.
```

#### 问题原因
辐射定标输出的 HDR 文件中包含了格式不正确的坐标系统元数据，FLAASH 无法解析。

#### 解决方案
在重写 HDR 文件时，过滤掉所有坐标系统相关字段：

```idl
;过滤坐标系统相关字段（避免"Illegal variable attribute: COORD SYS STR"错误）
STRPOS(line_lower, 'coord sys str') LT 0 AND $
STRPOS(line_lower, 'coordinate system string') LT 0 AND $
STRPOS(line_lower, 'coord sys code') LT 0 AND $
STRPOS(line_lower, 'map info') LT 0 AND $
STRPOS(line_lower, 'projection') LT 0 AND $
STRPOS(line_lower, 'datum') LT 0 AND $
STRPOS(line_lower, 'geo points') LT 0
```

**结果**：✓ 错误消失，FLAASH 可以执行，但输出结果异常

### 2.3 第三阶段：栅格对象类型不兼容

#### 问题表现
FLAASH 可以执行，但仍报错 "Object reference type required"，或输出结果异常。

#### 关键发现
对比官方工具和自定义工具的处理流程：
- **官方工具**：使用 `RadiometricCalibration` Task 创建输出栅格
- **自定义工具（初始）**：手动计算数据并创建 `ENVIRaster` 对象

根据 ENVI 官方文档：
> "Note: Use ENVIApplyGainOffsetTask to apply custom gains and offsets to a raster that will be input to a custom calibration routine."

#### 解决方案
**使用 `ApplyGainOffset` Task 创建输出栅格**，而不是手动创建 ENVIRaster：

```idl
;创建 ApplyGainOffset Task
GainOffsetTask = ENVITask('ApplyGainOffset')
GainOffsetTask.INPUT_RASTER = Raster
GainOffsetTask.GAIN = gain_arr        ; 每个波段的增益数组
GainOffsetTask.OFFSET = offset_arr    ; 每个波段的偏移数组
GainOffsetTask.OUTPUT_RASTER_URI = output_file
GainOffsetTask.Execute
output_raster = GainOffsetTask.OUTPUT_RASTER
```

**效果**：
- ✓ FLAASH 可以正常执行
- ✓ 栅格对象类型与官方工具兼容
- ✗ 输出结果仍有差异

### 2.4 第四阶段：元数据参数不一致

#### 问题表现
FLAASH 输出值范围异常，与官方工具差异很大：
- 官方：485-5337（正常反射率范围）
- 自定义：-31368 到 31653（异常，有负值）

#### 元数据对比发现的差异

| 参数 | 官方值 | 自定义值（初始） | 影响 |
|------|--------|-----------------|------|
| `sun azimuth` | 143.229 | 0.0 | ❌ 大气路径计算错误 |
| `FWHM` | [474.17, 701.95, 650.41, 119.22] | [70.0, 70.0, 60.0, 120.0] | ❌ 光谱响应函数不同 |
| `calibration scale factor` | 1.0 | 0.1（或 1.0） | ❌ 影响 input_scale 计算 |
| `input_scale`（FLAASH 计算） | 10.0 | 1.0 | ❌ 数据缩放错误 |

#### 解决步骤

**步骤1：修复 sun azimuth = 0 问题**

虽然 HDR 文件中写入了 `sun azimuth = 143.229`，但 FLAASH 输出仍显示 0.0。

**原因**：FLAASH 从栅格对象的 `METADATA` 属性读取元数据，而不仅仅是 HDR 文件。

**解决方案**：同时写入 HDR 文件和栅格对象的 METADATA：

```idl
;保存元数据变量（在 ApplyGainOffset Task 之前）
saved_sun_azimuth = sun_azimuth
saved_sun_elevation = sun_elevation
; ... 其他变量

;执行 ApplyGainOffset Task
GainOffsetTask.Execute
output_raster = GainOffsetTask.OUTPUT_RASTER

;恢复元数据变量
sun_azimuth = saved_sun_azimuth
sun_elevation = saved_sun_elevation
; ... 其他变量

;写入到栅格对象的 METADATA（FLAASH 会读取）
IF output_raster.METADATA.HasTag('sun azimuth') THEN BEGIN
  output_raster.METADATA.UpdateItem, 'sun azimuth', sun_azimuth
ENDIF ELSE BEGIN
  output_raster.METADATA.AddItem, 'sun azimuth', sun_azimuth
ENDELSE
output_raster.WriteMetadata
```

**步骤2：修复 FWHM 值**

使用官方 GUI 实际输出的 FWHM 值（虽然看起来不标准，但为了完全兼容）：

```idl
;使用官方 GUI 的 FWHM 值
gf1_fwhm = [474.169350, 701.947550, 650.412330, 119.217280]
```

**步骤3：修复 calibration scale factor**

对比发现官方辐射定标输出的 `calibration scale factor = 1.0`（不是 0.1）：

```idl
PRINTF, hdr_lun, 'calibration scale factor = 1.00000000000000'
```

**步骤4：手动设置 INPUT_SCALE = 10.0**

虽然 `calibration scale factor = 1.0`，但官方 FLAASH 使用 `input_scale = 10.0`。

**原因**：官方工具有特殊的 input_scale 计算逻辑，我们无法复现。

**解决方案**：直接手动设置 `INPUT_SCALE = 10.0`（与官方一致）：

```idl
;设置 Input Scale（固定值，与官方工具一致）
final_input_scale = 10.0
PRINT, 'DEBUG: Using fixed INPUT_SCALE = 10.0 (matches official tool)'

Task.INPUT_SCALE = final_input_scale
```

---

## 3. 关键技术发现

### 3.1 FLAASH 对输入栅格的要求

#### 栅格对象类型
FLAASH 需要特定类型的栅格对象，不能使用手动创建的 `ENVIRaster`。

✓ **正确方法**：
- 使用 `RadiometricCalibration` Task（官方传感器）
- 使用 `ApplyGainOffset` Task（自定义 Gain 和 Offset）
- 使用 `ENVIGainOffsetRaster` 虚拟栅格

✗ **错误方法**：
- 手动计算数据并创建 `ENVIRaster(data, URI=file)`

#### 元数据位置
关键元数据（如 `sun azimuth`、`sun elevation`）需要存在于两个位置：
1. **HDR 文件**：用于文件存储和人工查看
2. **栅格对象的 METADATA 属性**：FLAASH 从这里读取

```idl
;写入 HDR 文件
PRINTF, hdr_lun, 'sun azimuth = ' + STRING(sun_azimuth)

;写入栅格对象 METADATA
IF output_raster.METADATA.HasTag('sun azimuth') THEN BEGIN
  output_raster.METADATA.UpdateItem, 'sun azimuth', sun_azimuth
ENDIF ELSE BEGIN
  output_raster.METADATA.AddItem, 'sun azimuth', sun_azimuth
ENDELSE
output_raster.WriteMetadata
```

### 3.2 FLAASH 参数设置要点

#### 必需参数

| 参数 | 类型 | 说明 | 设置方式 |
|------|------|------|---------|
| `INPUT_RASTER` | ENVIRaster | 辐射亮度栅格 | 使用 ApplyGainOffset Task 创建 |
| `ACQUISITION_TIME` | ENVITime | 采集时间（GMT） | 从字符串创建 ENVITime 对象 |
| `SENSOR_TYPE` | String | 传感器类型 | "GF1 PMS1" 或 "GF1 PMS2" |
| `PIXEL_SIZE` | Double | 像素大小（米） | 从 XML 读取或使用默认值 8.0 |
| `SENSOR_ALTITUDE` | Double | 传感器高度（公里） | 从 XML 读取或使用默认值 645.0 |
| `INPUT_SCALE` | Double | 输入缩放因子 | **固定值 10.0**（关键！） |
| `AEROSOL_MODEL` | String | 气溶胶模型 | "High-Visibility Rural" 等 |
| `DEFAULT_VISIBILITY` | Double | 默认能见度（公里） | 用户设置，默认 40.0 |

#### INPUT_SCALE 计算逻辑

**官方工具**：
- 辐射定标：`calibration scale factor = 1.0`
- FLAASH：自动计算 `input_scale = 10.0`

**自定义工具（最终方案）**：
- 辐射定标：`calibration scale factor = 1.0`
- FLAASH：**手动设置** `input_scale = 10.0`

> **重要**：虽然 `calibration scale factor = 1.0`，但 FLAASH 的 `input_scale` 必须手动设置为 10.0，否则输出值会出现数量级错误。

### 3.3 关键元数据参数

#### sun azimuth（太阳方位角）
- **重要性**：❗❗❗ 极高（影响大气路径长度和散射计算）
- **单位**：度（0-360）
- **来源**：XML 文件的 `<SolarAzimuth>` 标签
- **写入位置**：HDR 文件 + 栅格对象 METADATA
- **示例值**：143.229

#### sun elevation（太阳高度角）
- **重要性**：❗❗ 高（影响大气路径长度）
- **单位**：度（0-90）
- **来源**：从太阳天顶角计算（`sun_elevation = 90 - solar_zenith`）
- **注意**：官方 GUI 可能直接使用天顶角作为 "sun elevation"（不正确但需兼容）
- **示例值**：43.8967（天顶角）或 46.1033（高度角）

#### FWHM（半峰全宽）
- **重要性**：❗ 中等（影响光谱响应函数）
- **单位**：纳米（nm）
- **官方值**：`[474.169350, 701.947550, 650.412330, 119.217280]`
- **标准值**：`[70.0, 70.0, 60.0, 120.0]`
- **使用建议**：使用官方值确保完全兼容

#### calibration scale factor
- **重要性**：❗❗ 高（影响 FLAASH 的 input_scale 计算）
- **官方值**：1.0
- **说明**：虽然官方使用 `SCALE_FACTOR=0.1` 进行辐射定标，但最终 HDR 中是 1.0

---

## 4. 最终解决方案

### 4.1 辐射定标模块修改

#### 修改1：使用 ApplyGainOffset Task

**位置**：`GSF_GF1_RadiometricCorrection.pro` 第 1226-1311 行

**修改前**：
```idl
;手动计算辐射亮度
all_output = FLOAT(all_data) * gain_arr + offset_arr

;手动创建 ENVIRaster
output_raster = ENVIRaster(all_output, URI=output_file, INTERLEAVE='bip')
output_raster.Save
```

**修改后**：
```idl
;保存元数据变量
saved_sun_azimuth = sun_azimuth
saved_solar_zenith = solar_zenith
; ... 其他变量

;使用 ApplyGainOffset Task
GainOffsetTask = ENVITask('ApplyGainOffset')
GainOffsetTask.INPUT_RASTER = Raster
GainOffsetTask.GAIN = gain_arr
GainOffsetTask.OFFSET = offset_arr
GainOffsetTask.OUTPUT_RASTER_URI = output_file
GainOffsetTask.Execute
output_raster = GainOffsetTask.OUTPUT_RASTER

;恢复元数据变量
sun_azimuth = saved_sun_azimuth
solar_zenith = saved_solar_zenith
; ... 其他变量
```

**效果**：
- ✓ 栅格对象类型与官方工具兼容
- ✓ FLAASH 可以正常处理

#### 修改2：设置关键元数据到 METADATA 属性

**位置**：`GSF_GF1_RadiometricCorrection.pro` 第 1620-1671 行

```idl
;设置 sun azimuth 到 METADATA（FLAASH 需要）
IF output_raster.METADATA.HasTag('sun azimuth') THEN BEGIN
  output_raster.METADATA.UpdateItem, 'sun azimuth', saved_sun_azimuth
ENDIF ELSE BEGIN
  output_raster.METADATA.AddItem, 'sun azimuth', saved_sun_azimuth
ENDELSE
output_raster.WriteMetadata

;设置 sun elevation 到 METADATA
IF output_raster.METADATA.HasTag('sun elevation') THEN BEGIN
  output_raster.METADATA.UpdateItem, 'sun elevation', saved_sun_elevation
ENDIF ELSE BEGIN
  output_raster.METADATA.AddItem, 'sun elevation', saved_sun_elevation
ENDELSE
output_raster.WriteMetadata
```

**效果**：
- ✓ FLAASH 可以从栅格对象读取 sun azimuth
- ✓ 大气校正计算使用正确的几何参数

#### 修改3：使用官方 FWHM 值

**位置**：`GSF_GF1_RadiometricCorrection.pro` 第 1370 行

```idl
;使用官方 GUI 的 FWHM 值
gf1_fwhm = [474.169350, 701.947550, 650.412330, 119.217280]
```

#### 修改4：设置 calibration scale factor = 1.0

**位置**：`GSF_GF1_RadiometricCorrection.pro` 第 1438-1445 行

```idl
PRINTF, hdr_lun, 'calibration scale factor = 1.00000000000000'
```

### 4.2 FLAASH 模块修改

#### 修改1：手动设置 INPUT_SCALE = 10.0

**位置**：`GSF_GF1_FLAASH_AtmosphericCorrection.pro` 第 1188-1207 行

**修改前**：
```idl
;从 calibration scale factor 自动计算 input_scale
final_input_scale = 1.0 / cal_scale_factor  ; 结果 = 1.0
```

**修改后**：
```idl
;直接手动设置 INPUT_SCALE=10.0，与官方工具一致
final_input_scale = 10.0
PRINT, 'DEBUG: Using fixed INPUT_SCALE = 10.0 (matches official tool)'
```

**原因**：
- 官方工具有特殊的 input_scale 计算逻辑
- 虽然 `calibration scale factor = 1.0`，但 FLAASH 使用 `input_scale = 10.0`
- 自动计算无法复现官方逻辑，直接使用固定值

#### 修改2：设置所有必需参数

确保所有 NewFLAASHEasyToUse 文档要求的参数都正确设置：

```idl
;设置 ACQUISITION_TIME（ENVITime 对象）
Task.ACQUISITION_TIME = acquisition_time_obj

;设置 SENSOR_ALTITUDE（Double）
Task.SENSOR_ALTITUDE = sensor_altitude_value

;设置 PIXEL_SIZE（Double）
Task.PIXEL_SIZE = pixel_size_value

;设置 INPUT_SCALE（Double，固定值 10.0）
Task.INPUT_SCALE = 10.0

;设置 DEFAULT_VISIBILITY（Double）
Task.DEFAULT_VISIBILITY = visibility
```

---

## 5. 验证结果

### 5.1 辐射定标验证

**测试点**：(2205, 2410)

| 工具 | Band 1 | Band 2 | Band 3 |
|------|--------|--------|--------|
| 官方 | 76.674400 | 97.395599 | 114.047501 |
| 自定义 | 76.674400 | 97.395599 | 114.047501 |
| 差异 | 0.0 | 0.0 | 0.0 |

**统计结果**：
- 平均差异：1.2207E-06（浮点精度误差）
- 最大差异：7.6294E-06
- **结论**：✓ 辐射定标结果完全一致

### 5.2 FLAASH 大气校正验证（修复后）

**随机采样 100 个像素**：

| 指标 | 结果 |
|------|------|
| 对比像素数 | 100 |
| 平均差异 | **0.0000E+00** |
| 最大差异 | **0.0000E+00** |
| **结论** | **✓ 结果基本一致（平均差异 < 0.001）** |

**所有100个采样点的值都完全相同！**

### 5.3 元数据对比（修复后）

#### 关键参数

| 参数 | 状态 | 备注 |
|------|------|------|
| acquisition time | ✓ 相同 | 2024-02-13T02:59:42Z |
| sensor type | ✓ 相同 | GF-1 |
| data units | ✓ 相同 | W m^-2 sr^-1 um^-1 |
| **sun azimuth** | **✓ 相同** | **143.229**（已修复） |
| sun elevation | ⚠ 不同 | 43.8967 vs 46.1033（天顶角 vs 高度角） |
| cloud cover | ✓ 相同 | 1.0 |
| calibration scale factor | ✓ 相同 | 1.0 |
| solar irradiance | ✓ 相同 | [1945.28, 1854.10, 1542.90, 1080.76] |
| wavelength | ✓ 相同 | [502.0, 576.0, 680.0, 810.0] |
| FWHM | ✓ 相同 | [474.169, 701.948, 650.412, 119.217] |

#### FLAASH 设置（flaash setting）

两个工具的 FLAASH 参数完全一致：

```json
{
  "sensor_type": "Multispectral",
  "input_scale": 10.0,              // ✓ 相同
  "output_scale": 10000,
  "sensor_altitude": 645.0,
  "date_time": "2024-02-13T02:59:42Z",
  "default_visibility": 40.0,
  "ifov": 0.012402941774305874,
  "modtran_atm": "Tropical Atmosphere",
  "modtran_aer": "High-Visibility Rural",
  "use_aerosol": "Disabled"
}
```

### 5.4 输出值范围对比

**修复后**：

| 工具 | Band 1 | Band 2 | Band 3 | Band 4 |
|------|--------|--------|--------|--------|
| 官方 | 485-4230 | 585-4286 | 1297-5337 | - |
| 自定义 | 485-4230 | 585-4286 | 1297-5337 | - |

**完全一致！** ✓

---

## 6. 技术要点总结

### 6.1 使用 ApplyGainOffset Task 的优势

#### 为什么不能手动创建 ENVIRaster？

FLAASH（以及其他 ENVI 高级任务）期望特定类型的栅格对象，这些对象：
1. 包含正确的内部元数据结构
2. 具有特定的对象属性和方法
3. 与 ENVI Task 框架兼容

手动创建的 `ENVIRaster` 虽然可以正常显示和保存，但缺少 FLAASH 需要的内部结构，导致 "Object reference type required" 错误。

#### ApplyGainOffset Task 的工作原理

```idl
;公式：Output = Input * GAIN + OFFSET
GainOffsetTask = ENVITask('ApplyGainOffset')
GainOffsetTask.GAIN = [0.2247, 0.1892, 0.1889, 0.1939]    ; 每个波段
GainOffsetTask.OFFSET = [4.6186, 4.8768, 4.8924, -9.4771] ; 每个波段
GainOffsetTask.Execute
```

**优点**：
- ✓ 创建的栅格对象与官方工具兼容
- ✓ 自动处理元数据继承
- ✓ 支持数组形式的 Gain 和 Offset
- ✓ 可被 FLAASH 正常处理

### 6.2 元数据双重写入机制

#### 为什么需要双重写入？

FLAASH 从**栅格对象的 METADATA 属性**读取关键参数（如 `sun azimuth`），而不仅仅是 HDR 文件。

#### 实现方法

```idl
;步骤1：写入 HDR 文件（用于文件存储）
PRINTF, hdr_lun, 'sun azimuth = ' + STRING(sun_azimuth, FORMAT='(F15.12)')
PRINTF, hdr_lun, 'sun elevation = ' + STRING(sun_elevation, FORMAT='(F10.6)')

;步骤2：写入栅格对象 METADATA（FLAASH 读取）
IF output_raster.METADATA.HasTag('sun azimuth') THEN BEGIN
  output_raster.METADATA.UpdateItem, 'sun azimuth', sun_azimuth
ENDIF ELSE BEGIN
  output_raster.METADATA.AddItem, 'sun azimuth', sun_azimuth
ENDELSE

IF output_raster.METADATA.HasTag('sun elevation') THEN BEGIN
  output_raster.METADATA.UpdateItem, 'sun elevation', sun_elevation
ENDIF ELSE BEGIN
  output_raster.METADATA.AddItem, 'sun elevation', sun_elevation
ENDELSE

output_raster.WriteMetadata  ; 保存到栅格对象
```

### 6.3 变量作用域保护

#### 问题

使用 `ApplyGainOffset` Task 后重新打开文件，某些变量可能丢失：

```idl
;ApplyGainOffset Task 执行
GainOffsetTask.Execute

;重新打开文件
output_raster.Close
output_raster = e.OpenRaster(output_file)

;此时 sun_azimuth 等变量可能已经丢失或被重置
```

#### 解决方案

在 Task 执行前保存变量，执行后恢复：

```idl
;保存（在 ApplyGainOffset Task 之前）
saved_sun_azimuth = sun_azimuth
saved_solar_zenith = solar_zenith
saved_sun_elevation = sun_elevation
saved_satellite_azimuth = satellite_azimuth
saved_satellite_zenith = satellite_zenith
saved_cloud_cover = cloud_cover
saved_acquisition_time = acquisition_time
saved_pixel_size = pixel_size
saved_sensor_altitude = sensor_altitude

;执行 Task
GainOffsetTask.Execute

;恢复（在写入 HDR 之前）
sun_azimuth = saved_sun_azimuth
solar_zenith = saved_solar_zenith
; ... 恢复其他变量
```

### 6.4 INPUT_SCALE 的特殊处理

#### 官方工具的 input_scale 计算逻辑

通过对比发现，官方工具的 `input_scale` 计算不是简单的数学公式，而是复杂的内部逻辑：

| calibration scale factor | 官方 input_scale | 简单计算（1/csf） |
|-------------------------|-----------------|------------------|
| 1.0 | 10.0 | 1.0 |
| 0.1 | 10.0（推测） | 10.0 |

**结论**：官方工具可能使用固定值或基于传感器类型的查找表，而不是计算公式。

#### 最终方案

**直接使用固定值 10.0**：

```idl
;设置 Input Scale（固定值，与官方工具一致）
final_input_scale = 10.0
Task.INPUT_SCALE = final_input_scale
```

**理由**：
1. 官方工具使用 `input_scale = 10.0`（经验证）
2. 自动计算逻辑无法复现官方行为
3. 使用固定值确保与官方工具完全一致

---

## 7. 代码示例

### 7.1 完整的辐射定标流程（关键代码）

```idl
PRO GSF_GF1_RadiometricCorrection, $
  input_file=input_file, $
  output_file=output_file, $
  output_format=output_format

  COMPILE_OPT idl2
  e = ENVI(/HEADLESS)

  ;========== 步骤1：解析 XML 获取元数据 ==========
  ;解析太阳方位角
  sun_azimuth = 0.0
  start_tag = STRPOS(xml_content, '<SolarAzimuth>')
  end_tag = STRPOS(xml_content, '</SolarAzimuth>')
  IF (start_tag GE 0) AND (end_tag GT start_tag) THEN BEGIN
    az_str = STRMID(xml_content, start_tag+14, end_tag-start_tag-14)
    sun_azimuth = FLOAT(STRTRIM(az_str, 2))
  ENDIF

  ;解析太阳天顶角并计算高度角
  solar_zenith = 0.0
  start_tag = STRPOS(xml_content, '<SolarZenith>')
  end_tag = STRPOS(xml_content, '</SolarZenith>')
  IF (start_tag GE 0) AND (end_tag GT start_tag) THEN BEGIN
    zenith_str = STRMID(xml_content, start_tag+13, end_tag-start_tag-13)
    solar_zenith = FLOAT(STRTRIM(zenith_str, 2))
    sun_elevation = 90.0 - solar_zenith  ;计算高度角
  ENDIF

  ;========== 步骤2：获取定标参数 ==========
  ;从 sensor_attributes.json 获取 Gain 和 Offset
  gain_arr = [0.2247, 0.1892, 0.1889, 0.1939]    ;GF1-PMS1
  offset_arr = [4.6186, 4.8768, 4.8924, -9.4771] ;GF1-PMS1

  ;========== 步骤3：保存元数据变量 ==========
  saved_sun_azimuth = sun_azimuth
  saved_solar_zenith = solar_zenith
  saved_sun_elevation = sun_elevation
  saved_acquisition_time = acquisition_time
  saved_pixel_size = pixel_size
  saved_sensor_altitude = sensor_altitude

  ;========== 步骤4：使用 ApplyGainOffset Task 创建输出 ==========
  GainOffsetTask = ENVITask('ApplyGainOffset')
  GainOffsetTask.INPUT_RASTER = Raster
  GainOffsetTask.GAIN = gain_arr
  GainOffsetTask.OFFSET = offset_arr
  GainOffsetTask.OUTPUT_RASTER_URI = output_file
  GainOffsetTask.Execute
  output_raster = GainOffsetTask.OUTPUT_RASTER

  ;重新打开以确保元数据可写
  IF FILE_TEST(output_file) THEN BEGIN
    output_raster.Close
    output_raster = e.OpenRaster(output_file)
  ENDIF

  ;========== 步骤5：恢复元数据变量 ==========
  sun_azimuth = saved_sun_azimuth
  solar_zenith = saved_solar_zenith
  sun_elevation = saved_sun_elevation
  acquisition_time = saved_acquisition_time
  pixel_size = saved_pixel_size
  sensor_altitude = saved_sensor_altitude

  ;========== 步骤6：写入 HDR 文件元数据 ==========
  ;...（省略 HDR 文件读取和过滤代码）

  ;写入关键元数据
  PRINTF, hdr_lun, 'wavelength = {502.0, 576.0, 680.0, 810.0}'
  PRINTF, hdr_lun, 'fwhm = {474.169350, 701.947550, 650.412330, 119.217280}'
  PRINTF, hdr_lun, 'wavelength units = Nanometers'
  PRINTF, hdr_lun, 'data units = W m^-2 sr^-1 um^-1'
  PRINTF, hdr_lun, 'calibration scale factor = 1.00000000000000'
  PRINTF, hdr_lun, 'sun azimuth = ' + STRING(sun_azimuth, FORMAT='(F15.12)')
  PRINTF, hdr_lun, 'sun elevation = ' + STRING(solar_zenith, FORMAT='(F10.6)')
  PRINTF, hdr_lun, 'acquisition time = ' + acquisition_time
  PRINTF, hdr_lun, 'pixel size = ' + STRING(pixel_size, FORMAT='(F10.6)')
  PRINTF, hdr_lun, 'sensor altitude = ' + STRING(sensor_altitude, FORMAT='(F10.6)')
  PRINTF, hdr_lun, 'solar irradiance = {1945.28, 1854.10, 1542.90, 1080.76}'

  FREE_LUN, hdr_lun

  ;========== 步骤7：写入栅格对象 METADATA ==========
  ;设置 sun azimuth（FLAASH 需要）
  IF output_raster.METADATA.HasTag('sun azimuth') THEN BEGIN
    output_raster.METADATA.UpdateItem, 'sun azimuth', saved_sun_azimuth
  ENDIF ELSE BEGIN
    output_raster.METADATA.AddItem, 'sun azimuth', saved_sun_azimuth
  ENDELSE

  ;设置 sun elevation（FLAASH 需要）
  IF output_raster.METADATA.HasTag('sun elevation') THEN BEGIN
    output_raster.METADATA.UpdateItem, 'sun elevation', saved_sun_elevation
  ENDIF ELSE BEGIN
    output_raster.METADATA.AddItem, 'sun elevation', saved_sun_elevation
  ENDELSE

  ;保存 METADATA
  output_raster.WriteMetadata

  PRINT, '✓ 辐射定标完成，输出与官方工具兼容'

END
```

### 7.2 FLAASH 大气校正流程（关键代码）

```idl
PRO GSF_GF1_FLAASH_AtmosphericCorrection, $
  input_file=input_file, $
  output_file=output_file, $
  visibility=visibility, $
  aerosol_model=aerosol_model

  COMPILE_OPT idl2
  e = ENVI(/HEADLESS)

  ;========== 步骤1：打开辐射定标输出 ==========
  RadianceRaster = e.OpenRaster(input_file)

  ;========== 步骤2：创建 FLAASH Task ==========
  Task = ENVITask('NewFLAASHEasyToUse')
  Task.INPUT_RASTER = RadianceRaster

  ;========== 步骤3：设置 ACQUISITION_TIME ==========
  ;从元数据读取时间字符串
  acquisition_time_str = RadianceRaster.METADATA['acquisition time']
  
  ;创建 ENVITime 对象
  acquisition_time_obj = ENVITime(acquisition=acquisition_time_str)
  Task.ACQUISITION_TIME = acquisition_time_obj

  ;========== 步骤4：设置其他必需参数 ==========
  Task.SENSOR_TYPE = 'GF1 PMS1'
  Task.PIXEL_SIZE = 8.0
  Task.SENSOR_ALTITUDE = 645.0
  
  ;========== 步骤5：设置 INPUT_SCALE（固定值 10.0） ==========
  Task.INPUT_SCALE = 10.0
  PRINT, 'DEBUG: Using fixed INPUT_SCALE = 10.0 (matches official tool)'

  ;========== 步骤6：设置气溶胶参数 ==========
  Task.AEROSOL_MODEL = 'High-Visibility Rural'
  Task.DEFAULT_VISIBILITY = 40.0

  ;========== 步骤7：设置输出路径 ==========
  Task.OUTPUT_RASTER_URI = output_file

  ;========== 步骤8：执行 FLAASH ==========
  Task.Execute
  OUTPUT_RASTER = Task.OUTPUT_RASTER

  PRINT, '✓ FLAASH 大气校正完成'

END
```

---

## 8. 问题排查检查清单

### 8.1 辐射定标输出检查

- [ ] 使用 `ApplyGainOffset` Task 创建输出（不是手动创建 ENVIRaster）
- [ ] HDR 文件包含以下元数据：
  - [ ] `wavelength = {502.0, 576.0, 680.0, 810.0}`
  - [ ] `fwhm = {474.169350, 701.947550, 650.412330, 119.217280}`
  - [ ] `data units = W m^-2 sr^-1 um^-1`
  - [ ] `calibration scale factor = 1.0`
  - [ ] `sun azimuth = 143.229...`（实际值，不是 0）
  - [ ] `sun elevation = 43.8967...`
  - [ ] `acquisition time = 2024-02-13T02:59:42Z`（ISO 格式）
  - [ ] `pixel size = 8.0`
  - [ ] `sensor altitude = 645.0`
  - [ ] `solar irradiance = {1945.28, 1854.10, 1542.90, 1080.76}`
- [ ] 栅格对象 METADATA 包含：
  - [ ] `sun azimuth`（使用 AddItem/UpdateItem 设置）
  - [ ] `sun elevation`（使用 AddItem/UpdateItem 设置）
- [ ] HDR 文件不包含坐标系统字段（`coord sys str`, `map info` 等）

### 8.2 FLAASH 参数检查

- [ ] `INPUT_RASTER`：使用 `ApplyGainOffset` Task 创建的栅格
- [ ] `ACQUISITION_TIME`：有效的 ENVITime 对象
- [ ] `SENSOR_TYPE`："GF1 PMS1" 或 "GF1 PMS2"
- [ ] `PIXEL_SIZE`：8.0（单位：米）
- [ ] `SENSOR_ALTITUDE`：645.0（单位：公里）
- [ ] `INPUT_SCALE`：**固定值 10.0**（不要自动计算）
- [ ] `AEROSOL_MODEL`："High-Visibility Rural" 等
- [ ] `DEFAULT_VISIBILITY`：40.0（或用户设置值）

### 8.3 输出验证检查

- [ ] FLAASH 执行成功（无错误）
- [ ] 输出文件存在（`.dat` 和 `.hdr`）
- [ ] 输出值范围正常：485-5337（反射率 * 10000）
- [ ] 元数据对比：sun azimuth 不是 0
- [ ] 像素值对比：平均差异 < 0.001

---

## 9. 常见问题与解决

### Q1: FLAASH 报错 "Object reference type required"

**原因**：使用手动创建的 ENVIRaster，对象类型不兼容。

**解决**：改用 `ApplyGainOffset` Task 创建输出栅格。

### Q2: FLAASH 报错 "Illegal variable attribute: COORD SYS STR"

**原因**：HDR 文件包含格式不正确的坐标系统元数据。

**解决**：在重写 HDR 时过滤掉所有坐标系统相关字段。

### Q3: FLAASH 输出值异常（负值或超大值）

**原因**：`INPUT_SCALE` 设置不正确。

**解决**：手动设置 `INPUT_SCALE = 10.0`（不要自动计算）。

### Q4: FLAASH 输出中 sun azimuth = 0

**原因**：sun azimuth 只写入了 HDR 文件，没有写入栅格对象的 METADATA。

**解决**：使用 `METADATA.AddItem/UpdateItem` 将 sun azimuth 写入栅格对象。

### Q5: 辐射定标后变量丢失

**原因**：使用 ApplyGainOffset Task 并重新打开文件后，变量作用域问题。

**解决**：在 Task 执行前保存变量，执行后恢复。

---

## 10. 对比验证脚本使用说明

### 10.1 验证辐射定标结果

```idl
;编译对比脚本
.compile -v 'E:\1027IDL\ENVITaskTrainning\GSFTasks\GSF_GF1_FLAASH_AtmosphericCorrection\Compare_Radiometric_Results.pro'

;对比辐射定标输出
Compare_Radiometric_Results, $
  official_file='E:\path\to\官方_radio.dat', $
  custom_file='E:\path\to\自定义_radio.dat'
```

**预期结果**：平均差异 < 0.001（浮点精度误差）

### 10.2 验证 FLAASH 大气校正结果

```idl
;编译对比脚本
.compile -v 'E:\1027IDL\ENVITaskTrainning\GSFTasks\GSF_GF1_FLAASH_AtmosphericCorrection\Compare_HDR_Files.pro'
.compile -v 'E:\1027IDL\ENVITaskTrainning\GSFTasks\GSF_GF1_FLAASH_AtmosphericCorrection\Compare_Radiometric_Results.pro'

;对比元数据
Compare_HDR_Files, $
  file1_dat='E:\path\to\官方_FLAASH.dat', $
  file2_dat='E:\path\to\自定义_FLAASH.dat'

;对比像素值
Compare_Radiometric_Results, $
  official_file='E:\path\to\官方_FLAASH.dat', $
  custom_file='E:\path\to\自定义_FLAASH.dat'
```

**预期结果**：
- 元数据一致（sun azimuth, calibration scale factor, FWHM 等）
- 像素值完全一致（平均差异 = 0.0）

---

## 11. 性能和效率

### 11.1 ApplyGainOffset Task vs 手动计算

| 方法 | 处理时间 | 内存占用 | FLAASH 兼容性 |
|------|---------|---------|--------------|
| 手动计算 + ENVIRaster | 快 | 高（需加载全部数据） | ✗ 不兼容 |
| ApplyGainOffset Task | 中等 | 中等 | ✓ 完全兼容 |

**结论**：虽然 ApplyGainOffset Task 可能稍慢，但为了 FLAASH 兼容性，必须使用。

### 11.2 元数据写入优化

```idl
;优化：批量写入元数据，减少 WriteMetadata 调用次数
output_raster.METADATA.AddItem, 'sun azimuth', sun_azimuth
output_raster.METADATA.AddItem, 'sun elevation', sun_elevation
;... 添加其他元数据

;一次性保存所有元数据
output_raster.WriteMetadata
```

---

## 12. 参考资料

### 12.1 官方文档

1. **ENVI Radiometric Calibration**
   - 路径：`ENVI > Toolbox > Radiometric Correction > Radiometric Calibration`
   - 公式：`Radiance = DN × Gain + Offset`
   - 单位：`W/(m² * sr * µm)`

2. **NewFLAASHEasyToUse Task**
   - 必需参数：INPUT_RASTER, ACQUISITION_TIME, SENSOR_TYPE, PIXEL_SIZE, SENSOR_ALTITUDE, INPUT_SCALE
   - Input Scale：用于将像素值转换为 `W/(m²/nm/sr)`
   - Initial Visibility：默认能见度（公里）

3. **ApplyGainOffset Task**
   - 用途：应用自定义 Gain 和 Offset
   - 公式：`Output = Input × GAIN + OFFSET`
   - 支持：每个波段不同的 Gain 和 Offset 数组

### 12.2 相关文件

| 文件 | 说明 |
|------|------|
| `GSF_GF1_RadiometricCorrection.pro` | 辐射定标核心代码 |
| `GSF_GF1_FLAASH_AtmosphericCorrection.pro` | FLAASH 大气校正核心代码 |
| `Compare_Radiometric_Results.pro` | 像素值对比脚本 |
| `Compare_HDR_Files.pro` | 元数据对比脚本 |
| `test1127_gf1.pro` | 官方示例代码 |

---

## 13. 版本历史

### v1.0（2025-12-29）
- ✓ 解决 "Object reference type required" 错误
- ✓ 解决 "Illegal variable attribute: COORD SYS STR" 错误
- ✓ 实现与官方工具完全一致的辐射定标输出
- ✓ 实现与官方工具完全一致的 FLAASH 大气校正输出
- ✓ 验证结果：像素值平均差异 = 0.0

### 关键修改

1. **辐射定标模块**：
   - 改用 `ApplyGainOffset` Task 创建输出
   - 添加元数据变量保存/恢复机制
   - 设置 FWHM 为官方值
   - 设置 calibration scale factor = 1.0
   - 将 sun azimuth 写入 METADATA 属性

2. **FLAASH 模块**：
   - 手动设置 `INPUT_SCALE = 10.0`
   - 设置所有必需参数
   - 改进元数据读取逻辑

---

## 14. 结论

通过系统性的对比验证和问题排查，成功实现了自定义辐射定标工具与 FLAASH 大气校正的完全兼容。关键技术要点包括：

1. **使用官方 Task**：使用 `ApplyGainOffset` Task 创建栅格对象，确保与 FLAASH 兼容
2. **双重元数据写入**：关键元数据同时写入 HDR 文件和栅格对象 METADATA
3. **参数完全一致**：FWHM、calibration scale factor、input_scale 等参数与官方工具完全一致
4. **变量作用域保护**：在 Task 执行前后保存/恢复元数据变量

最终验证结果显示，自定义工具的输出与官方工具完全一致（像素值差异为 0），证明所有兼容性问题已完全解决。

---

## 附录 A：错误信息速查表

| 错误信息 | 可能原因 | 解决方案 |
|---------|---------|---------|
| Object reference type required: REF | 栅格对象类型不兼容 | 使用 ApplyGainOffset Task |
| Illegal variable attribute: COORD SYS STR | HDR 包含错误的坐标系统元数据 | 过滤坐标系统相关字段 |
| 输出值异常（负值、超大值） | INPUT_SCALE 设置错误 | 手动设置 INPUT_SCALE = 10.0 |
| sun azimuth = 0 | 元数据只写入 HDR，未写入 METADATA | 使用 METADATA.AddItem 写入 |
| Parameter ... failed validation | 参数类型或值不正确 | 检查参数类型和值范围 |

---

## 附录 B：完整参数对照表

### 辐射定标输出（HDR 文件）

| 参数 | 官方值 | 自定义值（最终） | 状态 |
|------|--------|-----------------|------|
| wavelength | [502, 576, 680, 810] | [502, 576, 680, 810] | ✓ |
| fwhm | [474.17, 701.95, 650.41, 119.22] | [474.17, 701.95, 650.41, 119.22] | ✓ |
| wavelength units | Nanometers | Nanometers | ✓ |
| data units | W m^-2 sr^-1 um^-1 | W m^-2 sr^-1 um^-1 | ✓ |
| calibration scale factor | 1.0 | 1.0 | ✓ |
| sun azimuth | 143.229 | 143.229 | ✓ |
| sun elevation | 43.8967 | 43.8967（或 46.1033） | ⚠ |
| acquisition time | 2024-02-13T02:59:42Z | 2024-02-13T02:59:42Z | ✓ |
| pixel size | 8.0 | 8.0 | ✓ |
| sensor altitude | - | 645.0 | ⚠ |
| solar irradiance | [1945.28, 1854.10, 1542.90, 1080.76] | [1945.28, 1854.10, 1542.90, 1080.76] | ✓ |

### FLAASH 参数（flaash setting）

| 参数 | 官方值 | 自定义值（最终） | 状态 |
|------|--------|-----------------|------|
| sensor_type | Multispectral | Multispectral | ✓ |
| input_scale | 10.0 | 10.0 | ✓ |
| output_scale | 10000 | 10000 | ✓ |
| sensor_altitude | 645.0 | 645.0 | ✓ |
| date_time | 2024-02-13T02:59:42Z | 2024-02-13T02:59:42Z | ✓ |
| default_visibility | 40.0 | 40.0 | ✓ |
| ifov | 0.012402941774305874 | 0.012402941774305874 | ✓ |
| modtran_atm | Tropical Atmosphere | Tropical Atmosphere | ✓ |
| modtran_aer | High-Visibility Rural | High-Visibility Rural | ✓ |
| use_aerosol | Disabled | Disabled | ✓ |

---

## 附录 C：验证流程图

```
┌─────────────────────────────────────────────────────────────┐
│                    GF1 数据处理验证流程                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐
│  原始 XML   │
│   数据      │
└──────┬──────┘
       │
       ├──────────────────────────────────────┐
       │                                      │
       ▼                                      ▼
┌─────────────┐                      ┌─────────────┐
│   官方      │                      │   自定义    │
│ 辐射定标    │                      │ 辐射定标    │
│   工具      │                      │   工具      │
└──────┬──────┘                      └──────┬──────┘
       │                                    │
       │ calibration scale factor = 1.0     │ calibration scale factor = 1.0
       │ sun azimuth = 143.229              │ sun azimuth = 143.229
       │ FWHM = [474.17,...]                │ FWHM = [474.17,...]
       │                                    │
       ▼                                    ▼
┌─────────────┐   像素值对比    ┌─────────────┐
│  官方输出   ├────────────────►│  自定义输出  │
│  _radio.dat │   差异 = 0.0   │  _radio.dat  │
└──────┬──────┘                 └──────┬──────┘
       │                              │
       │ ✓ 辐射定标正确               │ ✓ 辐射定标正确
       │                              │
       ├──────────────────────────────┤
       │                              │
       ▼                              ▼
┌─────────────┐                ┌─────────────┐
│   官方      │                │   自定义    │
│   FLAASH    │                │   FLAASH    │
│  大气校正   │                │  大气校正   │
└──────┬──────┘                └──────┬──────┘
       │                              │
       │ input_scale = 10.0           │ input_scale = 10.0
       │ sun azimuth = 143.229        │ sun azimuth = 143.229
       │ FWHM = [474.17,...]          │ FWHM = [474.17,...]
       │                              │
       ▼                              ▼
┌─────────────┐   像素值对比    ┌─────────────┐
│  官方输出   ├────────────────►│  自定义输出  │
│_FLAASH.dat  │   差异 = 0.0   │_FLAASH.dat   │
└─────────────┘                 └─────────────┘

       ✓ 大气校正完全一致
```

---

## 附录 D：技术演进时间线

| 日期 | 阶段 | 问题 | 解决方案 | 结果 |
|------|------|------|---------|------|
| Day 1 | 初始问题 | Object reference type required | 尝试调整 FLAASH 参数 | ✗ 未解决 |
| Day 2 | 坐标系统错误 | Illegal variable attribute: COORD SYS STR | 过滤坐标系统元数据 | ✓ 部分解决 |
| Day 3 | 栅格类型 | FLAASH 执行失败 | 改用 ApplyGainOffset Task | ✓ FLAASH 可执行 |
| Day 4 | 元数据差异 | 输出值异常、sun azimuth = 0 | 修复 sun azimuth、FWHM、input_scale | ✓ 完全解决 |

---

## 附录 E：关键代码片段索引

### E.1 辐射定标关键代码

| 功能 | 文件 | 行号 | 说明 |
|------|------|------|------|
| XML 解析 | GSF_GF1_RadiometricCorrection.pro | 529-539 | 解析 SolarAzimuth |
| 元数据保存 | GSF_GF1_RadiometricCorrection.pro | 1226-1238 | 保存变量（Task 前） |
| ApplyGainOffset | GSF_GF1_RadiometricCorrection.pro | 1244-1283 | 使用官方 Task |
| 元数据恢复 | GSF_GF1_RadiometricCorrection.pro | 1302-1314 | 恢复变量（Task 后） |
| HDR 写入 | GSF_GF1_RadiometricCorrection.pro | 1357-1616 | 写入所有元数据 |
| METADATA 写入 | GSF_GF1_RadiometricCorrection.pro | 1620-1671 | 写入到栅格对象 |

### E.2 FLAASH 关键代码

| 功能 | 文件 | 行号 | 说明 |
|------|------|------|------|
| 创建 ENVITime | GSF_GF1_FLAASH_AtmosphericCorrection.pro | 907-920 | 从字符串创建 |
| 设置 ACQUISITION_TIME | GSF_GF1_FLAASH_AtmosphericCorrection.pro | 948-987 | 设置到 Task |
| 设置 INPUT_SCALE | GSF_GF1_FLAASH_AtmosphericCorrection.pro | 1188-1207 | 固定值 10.0 |
| 执行 FLAASH | GSF_GF1_FLAASH_AtmosphericCorrection.pro | 1418-1428 | Execute Task |

---

## 总结

本技术报告详细记录了 GF1 辐射定标与 FLAASH 大气校正兼容性问题的完整解决过程。通过使用官方 `ApplyGainOffset` Task、双重元数据写入机制、以及精确匹配官方工具的所有参数，最终实现了与官方工具完全一致的大气校正结果。

这个过程展示了遥感数据处理中工具兼容性的重要性，以及系统性问题排查方法的有效性。对于类似的传感器（GF2-GF7），可以参考本报告的解决方案和技术要点。

---

**文档结束**

---

## 快速参考卡片

### ✓ 成功标志
- FLAASH 执行无错误
- 输出值范围：485-5337（正常反射率 * 10000）
- 像素值对比：平均差异 = 0.0
- 元数据对比：sun azimuth ≠ 0

### ✗ 失败标志
- "Object reference type required" 错误
- 输出值异常（负值、超大值）
- sun azimuth = 0 in FLAASH 输出
- 像素值差异 > 100

### 🔧 关键修复点
1. 使用 `ApplyGainOffset` Task
2. 设置 `INPUT_SCALE = 10.0`（固定值）
3. 写入 `sun azimuth` 到 METADATA
4. 使用官方 FWHM 值
5. 设置 `calibration scale factor = 1.0`

