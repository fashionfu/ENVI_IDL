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

## 🎯 核心示例

### 示例1：虚拟栅格与全色锐化

```idl
PRO test_VirtualRaster
  COMPILE_OPT idl2
  e = ENVI()
  
  ; 打开全色和多光谱影像
  highRaster = e.OpenRaster('pan.dat')
  lowRaster = e.OpenRaster('mss.dat')
  
  ; 全色锐化（虚拟栅格）
  fusedRaster = ENVINNDiffusePanSharpeningRaster(lowRaster, highRaster)
  
  ; 导出结果
  fusedRaster.Export, 'output.tif', 'TIFF'
END
```

📖 详细教程：[IDL虚拟栅格与全色锐化处理流程详解](笔记详情/IDL虚拟栅格与全色锐化处理流程详解.md)

### 示例2：自定义Task开发

```idl
PRO MyCustomTask, $
  INPUT_RASTER=input_raster, $
  OUTPUT_RASTER_URI=output_uri
  
  COMPILE_OPT idl2
  e = ENVI(/CURRENT)
  
  ; 自定义算法实现
  ; ...
  
  ; 保存结果
  output_raster.Save
END
```

📂 完整示例：`ENVITaskTrainning/03_CustomTasks/`

### 示例3：批处理框架

```idl
PRO batch_processing
  e = ENVI(/HEADLESS)
  
  ; 遍历所有文件
  files = FILE_SEARCH('*.dat')
  FOREACH file, files DO BEGIN
    ; 处理单个文件
    process_image, file
  ENDFOREACH
  
  e.Close
END
```

📂 完整示例：`ENVITaskTrainning/05_BatchProcessing/`

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

