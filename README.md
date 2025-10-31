# ENVI/IDL 遥感开发培训素材包

<div align="center">

[![IDL](https://img.shields.io/badge/IDL-8.x-blue.svg)](https://www.l3harrisgeospatial.com/)
[![ENVI](https://img.shields.io/badge/ENVI-5.x-green.svg)](https://www.l3harrisgeospatial.com/)
[![License](https://img.shields.io/badge/License-Educational-orange.svg)](LICENSE)

**完整的ENVI Service Engine (ESE) 服务开发培训资料**

[中文文档](README.md) | [学习指南](笔记详情/1031.md) | [问题反馈](https://github.com/fashionfu/ENVI_IDL/issues)

</div>

---

## 📚 项目简介

本项目是一套完整的 **IDL/ENVI 遥感影像处理与开发培训素材包**，涵盖从IDL基础语法到ENVI二次开发、企业级服务开发的全流程内容。适合：

- 🎓 **遥感专业学生** - 系统学习IDL编程和ENVI应用
- 👨‍💻 **IDL新手开发者** - 从零开始掌握IDL/ENVI开发
- 🚀 **遥感工程师** - 提升技能，开发专业应用
- 🏢 **企业开发团队** - 学习ESE服务化开发

---

## ✨ 主要特色

- ✅ **系统完整**：从基础到进阶，12-18周完整学习路径
- ✅ **理论实践结合**：6套PPT理论 + 200+代码实例
- ✅ **注重实战**：包含8个自定义Task、多个完整项目案例
- ✅ **企业级应用**：涵盖批处理、服务化开发、ENVI Server部署
- ✅ **中文教程**：详细的中文注释和学习文档

---

## 📖 内容结构

```
ENVI_IDL/
├── 📊 PPT教程（6个）
│   ├── 1-ENVI Service Engine 平台介绍
│   ├── 2-ENVI 开发技术
│   ├── 3-自定义 ENVITask
│   ├── 4-ESE 服务开发
│   ├── 5-ENVI Modeler
│   └── 6-ENVI Server
│
├── 💻 ENVITaskTrainning - ENVI开发实战
│   ├── 00_IDLBasic/ - IDL基础入门
│   ├── 01_VirtualRaster/ - 虚拟栅格技术 ⭐
│   ├── 02_ENVITasks/ - ENVI任务开发（16个示例）⭐⭐
│   ├── 03_CustomTasks/ - 自定义Task开发（8个项目）⭐⭐⭐
│   ├── 04_ENVIExtensions/ - ENVI扩展开发
│   ├── 05_BatchProcessing/ - 批处理框架
│   ├── 06_ENVIAppStore/ - 应用商店示例
│   └── 07_GSFTasks/ - GSF服务开发 ⭐⭐⭐
│
├── 📝 第03-20章 - IDL系统教程
│   ├── 第03章 - IDL入门
│   ├── 第05章 - 流程控制
│   ├── 第06章 - 文件I/O
│   ├── 第07-10章 - 数据可视化
│   ├── 第11-12章 - GUI开发
│   ├── 第13-16章 - 高级主题
│   ├── 第17章 - IDL与其他语言交互
│   └── 第18-20章 - ENVI集成开发
│
├── 🛠️ 其他代码 - 实用代码库
│   ├── ENVI二次开发/ - 常用功能封装（9个）
│   ├── IDL功能/ - 实用工具（23个）
│   ├── IDL可视化/ - 可视化示例（72个）
│   └── IDL算法/ - 算法实现（25个）
│
└── 📄 笔记详情 - 学习文档
    ├── 1031.md - 完整学习指南 ⭐⭐⭐
    └── IDL虚拟栅格与全色锐化处理流程详解.md
```

---

## 🚀 快速开始

### 环境要求

- **IDL 8.x** 或更高版本
- **ENVI 5.x** 或更高版本（推荐 5.3+）
- **操作系统**：Windows / Linux / macOS
- **Git**（用于克隆仓库）

### 安装步骤

```bash
# 1. 克隆仓库
git clone https://github.com/fashionfu/ENVI_IDL.git

# 2. 进入目录
cd ENVI_IDL

# 3. 查看学习指南
# 打开 笔记详情/1031.md
```

### 开始学习

1. **阅读学习指南**：`笔记详情/1031.md` - 完整的学习路径规划
2. **从基础开始**：`ENVITaskTrainning/00_IDLBasic/` - IDL基础代码
3. **实战练习**：`ENVITaskTrainning/01_VirtualRaster/` - 虚拟栅格技术
4. **进阶开发**：`ENVITaskTrainning/03_CustomTasks/` - 自定义Task开发

---

## 📚 学习路径

### 推荐学习顺序

```
第1-2周：IDL基础
  └─ 第03章 + 第05章 + ENVITaskTrainning/00_IDLBasic/

第3-4周：ENVI基础
  └─ PPT 1-2 + ENVITaskTrainning/01_VirtualRaster/

第5-7周：ENVI任务开发
  └─ PPT 3 + ENVITaskTrainning/02_ENVITasks/ + 03_CustomTasks/

第8-10周：高级应用
  └─ PPT 4-6 + ENVITaskTrainning/05_BatchProcessing/ + 07_GSFTasks/

第11周+：项目实战
  └─ 选择实际项目进行开发
```

详细学习路径请参考：[学习指南](笔记详情/1031.md)

---

## 🎯 核心示例详解

本节提供三个核心应用场景的完整代码示例，每个示例都包含详细的逐行讲解，帮助您快速理解IDL/ENVI开发的核心技术。

---

### 示例1：虚拟栅格与全色锐化 ⭐⭐⭐

#### 代码示例

```idl
PRO test_VirtualRaster
  ; 程序说明：演示虚拟栅格技术在全色锐化中的应用
  ; 功能：将低分辨率多光谱影像与高分辨率全色影像融合
  ; 优势：不产生中间文件，内存高效，处理快速
  
  COMPILE_OPT idl2
  
  ; 初始化ENVI环境
  e = ENVI()
  view = e.GetView()
  
  ; 打开全色影像（高分辨率，单波段）
  highFile = FILEPATH('qb_boulder_pan', Subdir=['data'], Root_Dir=e.ROOT_DIR)
  highRaster = e.OpenRaster(highFile)
  PRINT, '全色影像分辨率: ', highRaster.NROWS, 'x', highRaster.NCOLUMNS
  
  ; 打开多光谱影像（低分辨率，多波段）
  lowFile = FILEPATH('qb_boulder_msi', Subdir=['data'], Root_Dir=e.ROOT_DIR)
  lowRaster = e.OpenRaster(lowFile)
  PRINT, '多光谱影像分辨率: ', lowRaster.NROWS, 'x', lowRaster.NCOLUMNS
  PRINT, '波段数: ', lowRaster.NBANDS
  
  ; 显示原始多光谱影像
  lowLayer = view.CreateLayer(lowRaster)
  view.Zoom, 1, /full_extent
  
  ; 空间裁剪（创建虚拟栅格，不产生文件）
  lowSubRaster = ENVISubsetRaster(lowRaster, sub_rect=[100,100,924,924])
  PRINT, '裁剪区域: 825x825像素'
  
  ; 全色锐化（虚拟栅格，延迟计算）
  ; NNDiffuse算法：保持光谱特性，提高空间分辨率
  fusedRaster = ENVINNDiffusePanSharpeningRaster(lowSubRaster, highRaster)
  
  ; 显示融合结果（不拉伸）
  fusedLayer = view.CreateLayer(fusedRaster)
  fusedLayer.QUICK_STRETCH = 'no stretch'
  
  ; 线性百分比拉伸增强（裁剪2%异常值）
  stretchRaster = ENVILinearPercentStretchRaster(fusedRaster, percent=2.0)
  
  ; 波段重组为RGB真彩色
  rgbRaster = ENVISubsetRaster(stretchRaster, bands=[2,1,0])
  
  ; 导出为TIFF格式（此时才真正计算并写入）
  output_file = 'F:\output\pansharpened_rgb.tif'
  rgbRaster.Export, output_file, 'TIFF'
  
  PRINT, '处理完成！输出文件: ', output_file
  PRINT, '融合影像特点: 高分辨率 + 彩色信息'
END
```

#### 技术要点讲解

**1. 虚拟栅格核心优势**
- **延迟计算**：所有处理步骤（裁剪、融合、拉伸）都不立即执行
- **链式操作**：多个处理步骤串联，仅在Export时一次性计算
- **内存高效**：不产生中间文件，节省磁盘空间和I/O时间

**2. 全色锐化原理**
- **空间信息**来自全色影像（高分辨率，如0.6米）
- **光谱信息**来自多光谱影像（低分辨率，如2.4米）
- **融合结果**：既有高分辨率细节，又有丰富的色彩信息

**3. NNDiffuse算法特点**
- 基于最近邻扩散算法
- 保持光谱特性优于其他算法
- 适用于城市区域和复杂地物

**4. 处理流程**
```
多光谱影像 → 空间裁剪 → 全色锐化 → 拉伸增强 → 波段重组 → 导出TIFF
   (虚拟)      (虚拟)      (虚拟)      (虚拟)      (虚拟)      (实际计算)
```

**5. 扩展应用**

更换融合算法：
```idl
; Gram-Schmidt全色锐化（光谱保真度更高）
fusedRaster = ENVIGramSchmidtSpectralSharpeningRaster(lowRaster, highRaster)

; PC Spectral全色锐化
fusedRaster = ENVIPCSpectralSharpeningRaster(lowRaster, highRaster)
```

调整拉伸效果：
```idl
; 更强的对比度增强（裁剪5%）
stretchRaster = ENVILinearPercentStretchRaster(fusedRaster, percent=5.0)

; 标准差拉伸
stretchRaster = ENVIStdDevStretchRaster(fusedRaster, num_stddev=2.0)
```

📖 **完整详解教程**：[IDL虚拟栅格与全色锐化处理流程详解](notebook/IDL虚拟栅格与全色锐化处理流程详解.md)

📂 **完整代码**：`ENVITaskTrainning/01_VirtualRaster/test_VirtualRaster.pro`

---

### 示例2：自定义Task开发 ⭐⭐⭐

#### 代码示例

```idl
PRO VFCTask, $
  INPUT_RASTER=input_raster, $        ; 输入栅格（必选）
  OUTPUT_RASTER_URI=output_uri, $     ; 输出文件路径（必选）
  OUTPUT_RASTER=output_raster          ; 输出栅格对象（可选）
  
  ; 功能：计算植被覆盖度（Vegetation Fractional Cover）
  ; 算法：基于NDVI的像元二分模型
  ; 公式：VFC = (NDVI - NDVIsoil) / (NDVIveg - NDVIsoil)
  
  COMPILE_OPT idl2
  e = ENVI(/CURRENT)
  
  ; ========== 步骤1：参数验证 ==========
  IF ~ISA(input_raster, 'ENVIRaster') THEN BEGIN
    MESSAGE, 'INPUT_RASTER必须是ENVIRaster对象'
  ENDIF
  
  IF input_raster.NBANDS LT 2 THEN BEGIN
    MESSAGE, '输入影像至少需要2个波段（红波段和近红外波段）'
  ENDIF
  
  ; ========== 步骤2：计算NDVI（虚拟栅格） ==========
  ; NDVI = (NIR - Red) / (NIR + Red)
  ndvi_raster = ENVISpectralIndexRaster(input_raster, 'Normalized Difference Vegetation Index')
  PRINT, 'NDVI计算完成（虚拟栅格）'
  
  ; ========== 步骤3：确定NDVI阈值 ==========
  ; 方法1：使用固定阈值
  ndvi_soil = 0.05    ; 裸土NDVI
  ndvi_veg = 0.70     ; 纯植被NDVI
  
  ; 方法2：使用统计值（更准确）
  ; stats = ndvi_raster.ComputeStatistics()
  ; ndvi_soil = stats.MIN
  ; ndvi_veg = stats.MAX
  
  ; ========== 步骤4：计算植被覆盖度（虚拟栅格） ==========
  ; 构建波段运算表达式
  vfc_expression = STRING(ndvi_soil, ndvi_veg, $
    FORMAT='("(b1 - %f) / (%f - %f)")')
  
  ; 使用波段运算创建VFC虚拟栅格
  vfc_raster = ENVIPixelwiseBandMathRaster(ndvi_raster, vfc_expression)
  PRINT, 'VFC表达式: ', vfc_expression
  
  ; ========== 步骤5：限制VFC范围在[0,1] ==========
  ; 小于0的设为0，大于1的设为1
  clip_expression = '(b1 < 0) * 0 + (b1 > 1) * 1 + (b1 GE 0 AND b1 LE 1) * b1'
  vfc_clipped = ENVIPixelwiseBandMathRaster(vfc_raster, clip_expression)
  
  ; ========== 步骤6：导出结果 ==========
  IF ~KEYWORD_SET(output_uri) THEN BEGIN
    output_uri = e.GetTemporaryFilename()
  ENDIF
  
  ; 实际计算并保存（此时才真正执行所有计算）
  vfc_clipped.Export, output_uri, 'ENVI'
  
  ; 打开保存的文件作为输出
  output_raster = e.OpenRaster(output_uri)
  
  ; 添加元数据
  output_raster.METADATA.AddItem, 'Description', 'Vegetation Fractional Cover'
  output_raster.METADATA.AddItem, 'Algorithm', 'Pixel Dichotomy Model'
  output_raster.METADATA.AddItem, 'NDVI_Soil', STRING(ndvi_soil)
  output_raster.METADATA.AddItem, 'NDVI_Veg', STRING(ndvi_veg)
  output_raster.Save
  
  PRINT, '植被覆盖度计算完成！'
  PRINT, '输出文件: ', output_uri
  PRINT, 'VFC范围: 0-1 (0=无植被, 1=完全覆盖)'
END
```

#### 技术要点讲解

**1. Task开发规范**
- **参数定义**：使用关键字参数，清晰的输入输出
- **错误处理**：参数验证，避免运行时错误
- **元数据**：添加处理信息，便于追溯

**2. 算法实现策略**
- **虚拟栅格**：中间过程使用虚拟栅格，提高效率
- **表达式计算**：使用字符串表达式，灵活性强
- **范围限制**：确保输出值在合理范围内

**3. NDVI到VFC转换**
- **像元二分模型**：假设像元由植被和土壤组成
- **VFC = (NDVI - NDVIsoil) / (NDVIveg - NDVIsoil)**
- **阈值选择**：可使用固定值或统计值

**4. Task文件配置**

创建配套的 `.task` 文件（JSON格式）：
```json
{
  "name": "VFCTask",
  "display_name": "植被覆盖度计算",
  "description": "基于NDVI的植被覆盖度计算",
  "parameters": [
    {
      "name": "INPUT_RASTER",
      "display_name": "输入影像",
      "type": "ENVIRaster",
      "required": true
    },
    {
      "name": "OUTPUT_RASTER_URI",
      "display_name": "输出文件",
      "type": "ENVIURI",
      "required": true
    }
  ]
}
```

**5. 扩展应用**

添加自适应阈值：
```idl
; 使用百分位数自动确定阈值
stats = ndvi_raster.ComputeStatistics()
hist = ndvi_raster.ComputeHistogram()
ndvi_soil = stats.MIN + (stats.MAX - stats.MIN) * 0.05  ; 5%分位
ndvi_veg = stats.MIN + (stats.MAX - stats.MIN) * 0.95   ; 95%分位
```

添加质量控制：
```idl
; 计算VFC的不确定性
uncertainty = ABS(ndvi_veg - ndvi_soil) / (ndvi_veg + ndvi_soil)
PRINT, 'VFC计算不确定性: ', uncertainty
```

📂 **完整示例**：`ENVITaskTrainning/03_CustomTasks/VFCTask/`

📖 **Task开发教程**：PPT 3 - 自定义ENVITask

---

### 示例3：批处理框架 ⭐⭐

#### 代码示例

```idl
PRO batch_ndvi_processing
  ; 程序说明：批量处理多个影像文件，计算NDVI并导出
  ; 应用场景：时间序列分析、大批量数据处理
  ; 特点：无人值守、自动化、日志记录
  
  COMPILE_OPT idl2
  
  ; ========== 步骤1：环境初始化 ==========
  ; 使用无头模式（不显示GUI）
  e = ENVI(/HEADLESS)
  PRINT, '批处理开始时间: ', SYSTIME()
  
  ; ========== 步骤2：配置输入输出路径 ==========
  input_dir = 'F:\data\input\'
  output_dir = 'F:\data\output\'
  
  ; 创建输出目录（如果不存在）
  IF ~FILE_TEST(output_dir, /DIRECTORY) THEN BEGIN
    FILE_MKDIR, output_dir
  ENDIF
  
  ; ========== 步骤3：搜索所有待处理文件 ==========
  ; 支持多种格式：.dat, .tif, .img
  pattern = input_dir + '*.dat'
  files = FILE_SEARCH(pattern, COUNT=file_count)
  
  IF file_count EQ 0 THEN BEGIN
    PRINT, '未找到待处理文件！'
    e.Close
    RETURN
  ENDIF
  
  PRINT, '找到 ', file_count, ' 个文件待处理'
  
  ; ========== 步骤4：初始化日志和统计 ==========
  log_file = output_dir + 'batch_process_log_' + $
    STRMID(SYSTIME(), 4, 20) + '.txt'
  OPENW, log_lun, log_file, /GET_LUN
  PRINTF, log_lun, '批处理日志'
  PRINTF, log_lun, '开始时间: ' + SYSTIME()
  PRINTF, log_lun, '文件总数: ' + STRING(file_count)
  PRINTF, log_lun, STRING(REPLICATE('-', 60))
  
  success_count = 0
  fail_count = 0
  
  ; ========== 步骤5：循环处理每个文件 ==========
  FOREACH file, files, idx DO BEGIN
    TIC  ; 开始计时
    
    ; 显示进度
    PRINT, FORMAT='(%"\r处理进度: [%d/%d] %s")', $
      idx+1, file_count, FILE_BASENAME(file)
    
    ; 错误处理
    CATCH, error_status
    IF error_status NE 0 THEN BEGIN
      PRINT, '  ✗ 处理失败: ', !ERROR_STATE.MSG
      PRINTF, log_lun, FILE_BASENAME(file) + ' - 失败: ' + !ERROR_STATE.MSG
      fail_count++
      CATCH, /CANCEL
      CONTINUE
    ENDIF
    
    ; 打开影像
    raster = e.OpenRaster(file)
    
    ; 检查波段数
    IF raster.NBANDS LT 2 THEN BEGIN
      MESSAGE, '波段数不足，需要至少2个波段'
    ENDIF
    
    ; 计算NDVI（虚拟栅格）
    ndvi_raster = ENVISpectralIndexRaster(raster, 'Normalized Difference Vegetation Index')
    
    ; 生成输出文件名
    base_name = FILE_BASENAME(file, '.dat')
    output_file = output_dir + base_name + '_NDVI.tif'
    
    ; 导出NDVI结果
    ndvi_raster.Export, output_file, 'TIFF'
    
    ; 计算统计信息
    stats = ndvi_raster.ComputeStatistics()
    
    ; 记录成功
    time_elapsed = TOC()
    success_count++
    
    log_info = STRING(FILE_BASENAME(file), output_file, $
      stats.MIN, stats.MAX, stats.MEAN, time_elapsed, $
      FORMAT='(%"%s -> %s | Min:%.3f Max:%.3f Mean:%.3f | 用时:%.2fs")')
    PRINTF, log_lun, log_info
    
    ; 清理内存
    raster.Close
    ndvi_raster.Close
    
  ENDFOREACH
  
  ; ========== 步骤6：输出统计摘要 ==========
  PRINT, ''
  PRINT, STRING(REPLICATE('=', 60))
  PRINT, '批处理完成！'
  PRINT, '成功: ', success_count, ' 个'
  PRINT, '失败: ', fail_count, ' 个'
  PRINT, '总计: ', file_count, ' 个'
  PRINT, '日志文件: ', log_file
  PRINT, STRING(REPLICATE('=', 60))
  
  ; 写入日志摘要
  PRINTF, log_lun, STRING(REPLICATE('-', 60))
  PRINTF, log_lun, '处理摘要:'
  PRINTF, log_lun, '成功: ' + STRING(success_count)
  PRINTF, log_lun, '失败: ' + STRING(fail_count)
  PRINTF, log_lun, '结束时间: ' + SYSTIME()
  
  ; 关闭日志文件
  FREE_LUN, log_lun
  
  ; 关闭ENVI
  e.Close
END
```

#### 技术要点讲解

**1. 批处理框架设计**
- **无头模式**：`ENVI(/HEADLESS)` - 不显示GUI，提高效率
- **文件搜索**：`FILE_SEARCH()` - 支持通配符和递归搜索
- **循环处理**：`FOREACH` - 现代化的循环语法

**2. 错误处理机制**
```idl
CATCH, error_status
IF error_status NE 0 THEN BEGIN
  ; 记录错误
  ; 继续处理下一个文件
  CONTINUE
ENDIF
```
- 单个文件失败不影响整体流程
- 错误信息记录到日志

**3. 进度监控**
- **实时显示**：`PRINT, FORMAT='(%"\r...")'` - 同行刷新
- **计时功能**：`TIC/TOC` - 测量处理时间
- **日志记录**：详细的处理信息

**4. 内存管理**
```idl
; 处理完及时关闭，释放内存
raster.Close
ndvi_raster.Close
```

**5. 扩展功能**

添加并行处理：
```idl
; 使用IDL桥接实现多线程
oBridge = OBJ_NEW('IDL_IDLBridge')
oBridge->Execute, "process_single_file, '" + file + "'"
```

添加邮件通知：
```idl
; 处理完成后发送邮件
send_email, 'admin@example.com', '批处理完成', log_content
```

输出到数据库：
```idl
; 将统计结果写入数据库
oDatabase = OBJ_NEW('IDLdbDatabase', 'results.db')
oDatabase->Insert, stats
```

**6. 实际应用场景**
- **时间序列分析**：批量处理多时相卫星影像
- **大区域处理**：分块处理大范围遥感数据
- **业务系统**：定时自动处理新数据
- **云平台服务**：ENVI Server后台处理

📂 **完整示例**：`ENVITaskTrainning/05_BatchProcessing/test_NDVI_ColorSlice_Batch.pro`

📖 **批处理教程**：`ENVITaskTrainning/05_BatchProcessing/` 包含多个实战案例

---

### 🔧 三个示例的对比

| 特性 | 示例1：虚拟栅格 | 示例2：自定义Task | 示例3：批处理 |
|------|----------------|------------------|--------------|
| **难度** | ⭐⭐ 中等 | ⭐⭐⭐ 较高 | ⭐⭐ 中等 |
| **应用场景** | 单幅影像处理 | 算法封装复用 | 批量自动化 |
| **核心技术** | 虚拟栅格链式操作 | Task开发规范 | 循环+异常处理 |
| **输出形式** | 处理结果文件 | 可复用组件 | 批量结果+日志 |
| **适用对象** | 交互式分析 | 工具开发者 | 生产环境 |

---

### 🎓 学习建议

**学习顺序：**
1. **先掌握示例1**：理解虚拟栅格的核心思想
2. **再学习示例3**：掌握批处理框架设计
3. **最后攻克示例2**：学习Task开发的完整流程

**实践项目：**
- 基于示例1：开发影像增强工具
- 基于示例2：开发水体提取Task
- 基于示例3：开发时间序列分析系统

**进阶方向：**
- 结合三个示例：开发企业级遥感处理平台
- 示例1+2：将虚拟栅格算法封装为Task
- 示例2+3：将Task应用于批处理框架

---

## 🛠️ 常用功能代码库

### ENVI二次开发常用函数

| 功能 | 文件 | 说明 |
|------|------|------|
| **ENVI初始化** | `startENVI.pro` | 启动ENVI环境 |
| **辐射定标** | `cal_calibration.pro` | 增益偏移校正 |
| **大气校正** | `cal_quac.pro` | QUAC快速大气校正 |
| **影像融合** | `cal_sharpen.pro` | 4种融合算法 |
| **影像镶嵌** | `cal_mosaic.pro` | 自动镶嵌 |
| **影像裁剪** | `cal_subset.pro` | 空间/光谱裁剪 |
| **影像分类** | `cal_class.pro` | 8种分类算法 |
| **特征提取** | `cal_Fx.pro` | 常用指数计算 |

📂 位置：`其他代码/ENVI二次开发/`

---

## 📊 项目统计

- **代码文件**：200+ 个 `.pro` 文件
- **示例数据**：50+ 个示例数据集
- **自定义Task**：8个完整项目
- **PPT教程**：6套理论课程
- **学习文档**：详细的中文文档和注释

---

## 🎓 实战项目

### 入门级项目
1. **遥感影像查看器** - GUI开发入门

### 进阶级项目
2. **NDVI时间序列分析工具** - 批处理与统计
3. **水体变化监测系统** - 专题提取与变化检测

### 高级项目
4. **自定义分类算法Task** - Task开发完整流程
5. **遥感影像预处理服务** - 服务化开发

### 企业级项目
6. **在线遥感云服务平台** - ENVI Server应用

详细项目说明：[学习指南 - 实践项目推荐](笔记详情/1031.md#实践项目推荐)

---

## 📖 文档资源

### 核心文档

- 📘 [完整学习指南](笔记详情/1031.md) - 12-18周学习路径规划
- 📗 [虚拟栅格详解](笔记详情/IDL虚拟栅格与全色锐化处理流程详解.md) - 虚拟栅格技术深度讲解
- 📙 [GitHub推送指南](笔记详情/GitHub推送指南.md) - 代码提交与管理

### 在线资源

- 🌐 **官方文档**：https://www.l3harrisgeospatial.com/docs/
- 💬 **社区论坛**：https://www.l3harrisgeospatial.com/Support/Forums
- 📺 **视频教程**：https://www.youtube.com/c/L3HarrisGeospatial
- 📚 **GitHub资源**：https://github.com/topics/idl

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

### 如何贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m '添加某个很棒的功能'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 贡献类型

- 🐛 报告Bug
- 💡 提出新功能建议
- 📝 改进文档
- 💻 提交代码
- 🌍 翻译文档

---

## 📜 许可证

本项目仅用于**教育和学习目的**。

- ✅ 可以用于个人学习
- ✅ 可以用于教学培训
- ✅ 可以修改和分享
- ❌ 不得用于商业用途

**版权说明：**
- 部分代码示例来自ENVI官方示例
- PPT课件版权归原作者所有
- 如有版权问题，请联系删除

---

## ⚠️ 注意事项

1. **数据文件**：由于GitHub文件大小限制，部分大型数据文件未包含在仓库中
2. **软件要求**：需要有效的IDL/ENVI许可证才能运行代码
3. **学习建议**：建议按照学习指南的顺序循序渐进
4. **问题反馈**：遇到问题请在Issues中提出

---

## 🌟 Star History

如果这个项目对你有帮助，请给个 ⭐️ Star 支持一下！

---

## 📞 联系方式

- **GitHub Issues**：[提交问题](https://github.com/fashionfu/ENVI_IDL/issues)
- **Email**：通过GitHub个人资料联系

---

## 🙏 致谢

感谢以下资源和社区：

- [L3Harris Geospatial](https://www.l3harrisgeospatial.com/) - ENVI/IDL官方
- ENVI中文社区
- 所有贡献者和学习者

---

## 📈 更新日志

### v1.0.0 (2024-10-31)
- ✨ 初始发布
- 📚 包含完整培训素材
- 📖 添加学习指南和详细文档
- 💻 200+ 代码示例
- 🎯 8个自定义Task项目

---

<div align="center">

**⭐️ 如果对你有帮助，请给个Star！⭐️**

Made with ❤️ for ENVI/IDL learners

[返回顶部](#enviidl-遥感开发培训素材包)

</div>

