# Landsat L2 水体提取批量处理工具

## 功能说明

本工具用于批量处理 Landsat L2 级别数据，自动提取水体信息。

### 主要功能

1. **批量处理**: 自动遍历指定文件夹，查找所有 Landsat L2 MTL 文件（XML 或 TXT 格式）
2. **自动空间参考处理**: 如果数据缺少空间参考信息，自动从 GeoTIFF 文件（SR_B3 或 SR_B4）读取并设置
3. **水体提取**: 使用 MNDWI（改进归一化差异水体指数）进行水体提取
4. **结果输出**: 同时输出分类栅格和矢量 Shapefile

## 使用方法

### 版本说明

本工具提供两个版本：

1. **命令行版本** (`batch_water_extraction.pro`)
   - 使用默认参数
   - 适合快速批量处理

2. **UI界面版本** (`batch_water_extraction_UI.pro`) **推荐**
   - 通过图形界面设置参数
   - 可以预览和调整参数
   - 适合需要精确控制参数的情况

### 步骤1：准备数据

确保您的 Landsat L2 数据文件夹结构如下：
```
输入文件夹/
  ├── Landsat数据文件夹1/
  │   ├── *_MTL.xml (或 *_MTL.txt)
  │   ├── *_SR_B1.TIF
  │   ├── *_SR_B2.TIF
  │   ├── *_SR_B3.TIF
  │   ├── *_SR_B4.TIF
  │   └── ... (其他波段文件)
  ├── Landsat数据文件夹2/
  │   └── ...
  └── ...
```

### 步骤2：运行程序

#### 方法一：UI界面版本（推荐）

在 IDL 中运行：
```idl
batch_water_extraction_UI
```

#### 方法二：命令行版本

在 IDL 中运行：
```idl
batch_water_extraction
```

### 步骤3：按提示操作

#### UI界面版本操作流程：

1. **选择输入文件夹**: 选择包含多个 Landsat L2 数据文件夹的父目录
2. **选择输出目录**: 选择结果保存位置
3. **选择输出格式**: 
   - 点击 "Yes" = TIFF 格式 (.tif)
   - 点击 "No" = ENVI 格式 (.dat)
4. **设置参数（UI界面）**: 
   - 程序会自动打开第一个文件作为示例
   - 弹出参数设置界面，可以设置：
     - **Apply QUAC**: 是否应用QUAC大气校正
     - **Threshold Value**: MNDWI阈值
     - **Smooth Size**: 分类平滑核大小
     - **Minimum Area**: 最小水体面积（km²）
   - 点击 "OK" 确认参数设置

#### 命令行版本操作流程：

1. **选择输入文件夹**: 选择包含多个 Landsat L2 数据文件夹的父目录
2. **选择输出目录**: 选择结果保存位置
3. **选择输出格式**: 
   - 点击 "Yes" = TIFF 格式 (.tif)
   - 点击 "No" = ENVI 格式 (.dat)
4. **使用默认参数**: 程序使用预设的默认参数

### 步骤4：等待处理完成

程序会自动：
- 搜索所有 MTL 文件（XML 或 TXT 格式）
- 打开 Surface Reflectance 数据
- 检查并补充空间参考信息（如需要）
- 执行水体提取
- 保存结果文件

## 输出文件

每个处理的数据会生成两个输出文件：

1. **栅格文件**: `*_Water.tif` 或 `*_Water.dat`
   - 分类栅格，包含背景和水体两类
   - 水体类别用红色显示

2. **矢量文件**: `*_Water.shp`
   - Shapefile 格式的水体边界
   - 仅包含水体类别

## 参数说明

### 默认参数

- **是否应用QUAC**: 否（0）
- **阈值**: 0.0
- **平滑大小**: 5
- **最小面积**: 0.05 km²

### 修改参数

如需修改参数，请编辑 `batch_water_extraction.pro` 文件中的以下变量：

```idl
Apply_QUAC = 0        ; 是否应用QUAC大气校正
thresholdValue = 0.0  ; MNDWI阈值
smoothSize = 5        ; 分类平滑核大小
minArea = 0.05        ; 最小水体面积（km²）
```

## 技术说明

### 水体提取流程

1. **计算MNDWI**: 使用改进归一化差异水体指数
2. **阈值分割**: 根据阈值将MNDWI影像分为水体和非水体
3. **分类平滑**: 使用形态学操作去除噪声
4. **分类聚合**: 去除小于最小面积的水体斑块
5. **栅格转矢量**: 将分类结果转换为矢量格式

### 空间参考处理

- 优先检查 raster 是否已有空间参考信息
- 如果缺少，从同目录下的 SR_B3 或 SR_B4 GeoTIFF 文件读取
- 使用 `create_map_info_from_geotiff` 函数创建 MAP_INFO 结构
- 通过临时文件方式为 raster 设置空间参考

## 依赖文件

本程序依赖以下文件（均已包含在当前目录中）：

1. **test_ENVIWaterExtractionTask.pro**: 水体提取核心任务，程序会自动编译
2. **spatial_ref_utils.pro**: 空间参考处理工具函数
   - `create_map_info_from_geotiff`: 从 GeoTIFF 文件创建空间参考信息
   - `set_spatial_ref_to_raster`: 为 raster 设置空间参考信息
   - `search_files_recursive`: 递归搜索文件函数

## 编译说明

在运行程序前，建议先编译所有依赖文件：

```idl
.compile -v 'D:\IDL\test_1205_WaterExtractionBatch\test_ENVIWaterExtractionTask.pro'
.compile -v 'D:\IDL\test_1205_WaterExtractionBatch\spatial_ref_utils.pro'
.compile -v 'D:\IDL\test_1205_WaterExtractionBatch\batch_water_extraction.pro'
.compile -v 'D:\IDL\test_1205_WaterExtractionBatch\batch_water_extraction_UI.pro'
```

或者直接运行程序，程序会在运行时自动尝试编译依赖文件。

## 注意事项

1. **数据格式**: 仅支持 Landsat L2 Surface Reflectance 数据
2. **波段要求**: 至少需要 4 个波段（用于计算 MNDWI）
3. **空间参考**: 如果数据缺少空间参考且无法从 GeoTIFF 读取，该数据将被跳过
4. **文件命名**: 输出文件名基于 MTL 文件名，特殊字符会被替换为下划线
5. **处理时间**: 批量处理可能需要较长时间，请耐心等待
6. **文件位置**: 所有依赖文件应在同一目录下，程序会自动查找并编译

## 错误处理

程序会自动记录处理失败的文件和错误信息，并在最后统一显示。

常见错误：
- **无法打开Surface Reflectance数据**: 检查 MTL 文件是否正确
- **缺少空间参考信息**: 确保同目录下有 SR_B3 或 SR_B4 文件
- **波段数不足**: 确保数据包含足够的波段

## 版本信息

- **版本**: 1.0
- **日期**: 2024-12
- **作者**: Auto

