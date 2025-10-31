#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
最终版ENVI IDL帮助文档生成器
整合所有ENVI和遥感相关的函数并提供中文注释
"""

import xml.etree.ElementTree as ET
import os
import re
from pathlib import Path
from html.parser import HTMLParser

class HTMLTextExtractor(HTMLParser):
    """提取HTML纯文本"""
    def __init__(self):
        super().__init__()
        self.text = []
        self.in_script = False
        self.in_style = False
        
    def handle_starttag(self, tag, attrs):
        if tag in ['script', 'style']:
            self.in_script = tag == 'script'
            self.in_style = tag == 'style'
    
    def handle_endtag(self, tag):
        if tag in ['script', 'style']:
            self.in_script = False
            self.in_style = False
        if tag in ['p', 'div', 'br']:
            self.text.append('\n')
    
    def handle_data(self, data):
        if not self.in_script and not self.in_style and data.strip():
            self.text.append(' ' + data.strip())
    
    def get_text(self):
        text = ''.join(self.text)
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'\n\s*\n+', '\n\n', text)
        return text.strip()

def get_chinese_description(func_name):
    """获取函数的中文描述"""
    descriptions = {
        'BinaryGTThresholdRaster': '创建二值栅格，大于阈值的像元为1，其他为0',
        'BinaryLTThresholdRaster': '创建反向二值栅格，小于阈值的像元为1',
        'BinaryAutomaticThresholdRaster': '使用自动阈值算法创建二值栅格',
        'BinaryMorphologicalFilter': '对二值栅格进行形态学滤波（膨胀、腐蚀等）',
        'ColorSliceClassification': '色彩切片分类：通过阈值范围对影像进行彩色分类',
        'ClassificationAggregation': '分类聚合：合并相似的小斑块',
        'ClassificationClumping': '分类聚类：连接相邻相似像元',
        'ClassificationSieving': '分类筛选：去除孤立小斑块',
        'PercentThresholdClassification': '百分比阈值分类',
        'AnomalyDetection': '异常检测：发现与背景差异大的像元',
        'TargetDetection': '目标检测：识别特定目标',
        'ChangeDetection': '变化检测',
        'ImageChangeDetection': '影像变化检测',
        'GrayscaleMorphologicalFilter': '灰度形态学滤波',
        'SobelFilter': 'Sobel边缘检测滤波器',
        'LowPassKernel': '低通滤波核',
        'HighPassKernel': '高通滤波核',
        'LowPassFilter': '低通滤波器：平滑影像，去除噪声',
        'HighPassFilter': '高通滤波器：增强边缘和细节',
        'MedianFilter': '中值滤波器：去噪且保留边缘',
        'EnhancedLeeAdaptiveFilter': '增强Lee自适应滤波器：雷达影像去噪',
        'KuanAdaptiveFilter': 'Kuan自适应滤波器',
        'EnhancedFrostAdaptiveFilter': '增强Frost自适应滤波器',
        'GammaAdaptiveFilter': 'Gamma自适应滤波器',
        'SpectralIndex': '光谱指数：计算各种植被、水体、建筑等指数',
        'SubsetRaster': '提取栅格子集：裁剪指定区域',
        'GeographicSubsetRaster': '地理子集：按地理范围提取',
        'MosaicRaster': '栅格镶嵌：拼接多幅影像',
        'BuildMosaicRaster': '构建镶嵌栅格',
        'ReprojectRaster': '重投影：转换坐标系',
        'ResampleRaster': '重采样：改变影像分辨率',
        'LinearPercentStretch': '线性百分比拉伸：增强对比度',
        'LinearRangeStretch': '线性范围拉伸',
        'OptimizedLinearStretch': '优化线性拉伸：自动优化参数',
        'GaussianStretch': '高斯拉伸：基于高斯分布的拉伸',
        'EqualizationStretch': '均衡化拉伸：直方图均衡化',
        'LogStretch': '对数拉伸',
        'LowClipRaster': '低值裁剪',
        'HighClipRaster': '高值裁剪',
        'PanSharpening': '全色锐化：融合高分辨率全色影像与多光谱影像',
        'NNDiffusePanSharpening': 'NN扩散全色锐化',
        'PCPanSharpening': '主成分全色锐化',
        'ForwardPCATransform': '前向主成分变换：降维和去噪',
        'InversePCATransform': '反向主成分变换：重建原始影像',
        'ForwardMNFTransform': '前向最小噪声分数变换',
        'InverseMNFTransform': '反向最小噪声分数变换',
        'IHSTransform': 'IHS色彩空间变换',
        'RGBToHSIRaster': 'RGB到HSI色彩空间转换',
        'ForwardTasseledCapTransform': '前向缨帽变换',
        'CreatePointCloud': '创建点云对象',
        'ColorPointCloud': '点云着色：使用栅格数据为点云着色',
        'GroundFilterPointCloud': '地面滤波：从点云中提取地面点',
        'ClassifyGroundPoints': '分类地面点',
        'GenerateDigitalElevationModel': '生成数字高程模型(DEM)',
        'GenerateDigitalSurfaceModel': '生成数字表面模型(DSM)',
        'GenerateCanopyHeightModel': '生成冠层高度模型(CHM)',
        'ASCIIToVector': 'ASCII转矢量：导入文本坐标数据',
        'GeoPackageToShapefile': 'GeoPackage转Shapefile',
        'ReprojectVector': '矢量重投影',
        'BufferZone': '缓冲区：生成矢量缓冲区',
        'ASCIIToROI': 'ASCII转感兴趣区域',
        'ClassificationToPixelROI': '分类转像素ROI',
        'ImageThresholdToROI': '影像阈值转ROI：从阈值影像生成ROI',
        'BuildRasterSeries': '构建栅格时间序列',
        'VideoToRasterSeries': '视频转栅格序列',
        'BuildLayerStack': '构建图层堆叠',
        'CastRaster': '栅格数据类型转换',
        'ConvertInterleave': '转换交叠方式(BIP/BIL/BSQ)',
        'ConvertPixelToMapCoordinates': '像素坐标转地图坐标',
        'ConvertMapToPixelCoordinates': '地图坐标转像素坐标',
        'ConvertMapToGeographicCoordinates': '地图坐标转经纬度',
        'ConvertGeographicToMapCoordinates': '经纬度转地图坐标',
        'DarkSubtractionCorrection': '暗减法校正：扣除暗电流',
        'FlatFieldCorrection': '平场校正：校正影像不均匀性',
        'GenerateMaskFromVector': '从矢量生成掩膜',
        'EditRasterMetadata': '编辑栅格元数据',
        'ExportRasterToENVI': '导出为ENVI格式',
        'ExportRasterToPNG': '导出为PNG格式',
        'ExportRasterToTIF': '导出为TIFF格式',
        'QueryAllTasks': '查询所有可用任务',
        'QuerySensorModels': '查询传感器模型',
        'GenerateGCPsFromReferenceImage': '从参考影像生成控制点',
        'GenerateGCPsFromTiePoints': '从连接点生成控制点',
        'GenerateTiePointsByCrossCorrelation': '交叉相关法生成连接点',
        'ImageToImageRegistration': '影像配准：对两幅影像进行配准',
        'ImageIntersection': '影像交集：求两个栅格的交集',
        'GenerateContourLines': '生成等值线',
        'RadarBackscatter': '雷达后向散射系数计算',
        'FXSegmentation': 'FX分割：影像分割算法',
        'MixtureTunedMatchedFilter': '混合调谐匹配滤波器：光谱匹配',
        'SpectralAdaptiveCoherenceEstimator': '光谱自适应相干估计器',
        'ForwardOrthorectify': '前向正射校正',
        'InverseOrthorectify': '反向正射校正',
        'ApplyRPCProjection': '应用RPC投影',
        'GetSpectrumFromLibrary': '从光谱库获取光谱曲线',
        'AddSpectrumToLibrary': '添加光谱曲线到光谱库',
        'GetColorSlices': '获取颜色切片',
        'GetColorTable': '获取颜色表',
        'PixelStatistics': '像素统计：计算统计信息',
        'BuildGridDefinitionFromRaster': '从栅格构建网格定义',
        'TopographicShading': '地形阴影：计算地形阴影',
        'VegetationSuppression': '植被抑制',
    }
    
    for key, desc in descriptions.items():
        if key in func_name:
            return desc
    return None

def read_html_content(file_path):
    """读取HTML并提取内容"""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        body_match = re.search(r'<body[^>]*>(.*?)</body>', content, re.DOTALL | re.IGNORECASE)
        if not body_match:
            return None
        
        body_content = body_match.group(1)
        
        title_match = re.search(r'<h1[^>]*>(.*?)</h1>', body_content, re.DOTALL | re.IGNORECASE)
        title = title_match.group(1) if title_match else ""
        title = re.sub(r'<[^>]+>', '', title).strip()
        
        p_matches = re.findall(r'<p[^>]*>(.*?)</p>', body_content, re.DOTALL | re.IGNORECASE)
        description = ""
        for p in p_matches[:2]:
            p_clean = re.sub(r'<[^>]+>', '', p).strip()
            if p_clean and len(p_clean) > 20 and not p_clean.startswith('This'):
                description += p_clean + "\n"
                break
        
        code_pattern = r'<p class="Code">(.*?)</p>'
        code_matches = re.findall(code_pattern, body_content, re.DOTALL | re.IGNORECASE)
        example_code = ""
        if code_matches:
            example_code = '\n'.join([re.sub(r'<[^>]+>', '', code).strip() for code in code_matches[:15]])
        
        return {
            'title': title,
            'description': description,
            'example_code': example_code
        }
    except:
        return None

def parse_envi_catalog():
    """解析catalog文件"""
    catalog_path = 'envi_catalog.xml'
    tree = ET.parse(catalog_path)
    root = tree.getroot()
    
    functions = []
    for routine in root.findall('.//ROUTINE'):
        name = routine.get('name', '')
        link = routine.get('link', '')
        syntax = routine.find('.//SYNTAX')
        syntax_text = syntax.get('name', '') if syntax is not None else ''
        
        if 'ENVI' in name or name.startswith('ENVI'):
            functions.append({
                'name': name,
                'link': link,
                'syntax': syntax_text
            })
    
    return functions

def get_section_name(cat_key):
    """获取章节名称"""
    names = {
        '预处理': '一、影像预处理',
        '增强': '二、影像增强',
        '变换': '三、影像变换',
        '滤波': '四、影像滤波',
        '分类': '五、分类与检测',
        '光谱': '六、光谱分析',
        '几何': '七、几何处理',
        '点云': '八、点云与三维',
        '矢量': '九、矢量处理',
        '其他': '十、其他工具'
    }
    return names.get(cat_key, cat_key)

def generate_final_markdown():
    """生成最终的markdown文档"""
    
    print("读取catalog文件...")
    functions = parse_envi_catalog()
    print(f"找到 {len(functions)} 个ENVI函数")
    
    md_content = """# ENVI IDL 遥感图像处理函数中文参考手册

> **说明**: 本文档整合了ENVI/IDL帮助文档中所有与遥感图像处理相关的函数，并提供中文说明和解析。

## 目录

- [一、影像预处理](#一影像预处理)
- [二、影像增强](#二影像增强)
- [三、影像变换](#三影像变换)
- [四、影像滤波](#四影像滤波)
- [五、分类与检测](#五分类与检测)
- [六、光谱分析](#六光谱分析)
- [七、几何处理](#七几何处理)
- [八、点云与三维](#八点云与三维)
- [九、矢量处理](#九矢量处理)
- [十、其他工具](#十其他工具)

---

"""

    help_dir = Path('online_help/Subsystems/envi/Content/ExtendCustomize')
    
    # 分类函数
    categories = {
        '预处理': [],
        '增强': [],
        '变换': [],
        '滤波': [],
        '分类': [],
        '光谱': [],
        '几何': [],
        '点云': [],
        '矢量': [],
        '其他': []
    }
    
    for func in functions:
        name = func['name']
        if 'CORRECT' in name or 'ApplyGainOffset' in name or 'DarkSubtract' in name:
            categories['预处理'].append(func)
        elif 'STRETCH' in name or 'Stretch' in name or 'CLIP' in name or 'Clip' in name or 'STRETCH' in name:
            categories['增强'].append(func)
        elif 'TRANSFORM' in name or 'Transform' in name or 'PCA' in name or 'MNF' in name or 'IHS' in name or 'Tasseled' in name:
            categories['变换'].append(func)
        elif 'FILTER' in name or 'Filter' in name or 'KERNEL' in name or 'MORPHOLOGICAL' in name:
            categories['滤波'].append(func)
        elif 'CLASSIFICATION' in name or 'CLASSIFY' in name or 'CLASS' in name or 'CLUMP' in name or 'SIEV' in name:
            categories['分类'].append(func)
        elif 'DETECT' in name or 'Detection' in name or 'TARGET' in name or 'Anomaly' in name:
            categories['分类'].append(func)
        elif 'SPECTRAL' in name or 'INDEX' in name or 'SPECTRUM' in name or 'Library' in name:
            categories['光谱'].append(func)
        elif 'RESAMPLE' in name or 'RESIZE' in name or 'MOSAIC' in name or 'REPROJECT' in name or 'SUBSET' in name or 'SUB' in name:
            categories['几何'].append(func)
        elif 'POINTCLOUD' in name or 'PointCloud' in name or 'LiDAR' in name or 'DEM' in name or 'DSM' in name or 'CHM' in name:
            categories['点云'].append(func)
        elif 'VECTOR' in name or 'Vector' in name or 'SHAPEFILE' in name or 'ASCII' in name or 'ROI' in name:
            categories['矢量'].append(func)
        else:
            categories['其他'].append(func)
    
    # 生成各章节内容
    category_descs = {
        '预处理': '影像预处理：辐射校正、几何校正、暗电流校正等',
        '增强': '影像增强：拉伸、裁剪、对比度调整等',
        '变换': '影像变换：PCA、MNF、IHS、缨帽变换等',
        '滤波': '影像滤波：空间滤波、形态学操作等',
        '分类': '分类与检测：监督分类、非监督分类、目标检测等',
        '光谱': '光谱分析：光谱指数、光谱库、光谱匹配等',
        '几何': '几何处理：重采样、重投影、镶嵌、裁剪等',
        '点云': '点云处理：LiDAR点云处理、DEM生成等',
        '矢量': '矢量处理：矢量转换、缓冲区、ROI等',
        '其他': '其他工具：元数据、导出、统计等'
    }
    
    for cat_key, cat_desc in category_descs.items():
        md_content += f"## {get_section_name(cat_key)}\n\n"
        md_content += f"**简介**: {category_descs[cat_key]}\n\n"
        
        func_list = categories[cat_key]
        count = 0
        for func in func_list[:100]:  # 限制每类最多100个
            name = func['name']
            chinese_desc = get_chinese_description(name)
            
            md_content += f"### {name}\n\n"
            
            if chinese_desc:
                md_content += f"**中文说明**: {chinese_desc}\n\n"
            
            if func['syntax']:
                md_content += f"**语法**: `{func['syntax']}`\n\n"
            
            # 尝试读取HTML内容
            if func['link']:
                html_path = help_dir / func['link']
                if not html_path.exists():
                    html_path = Path('online_help/Subsystems/envi/Content/ExtendCustomize/ENVITasks') / func['link']
                
                if html_path.exists():
                    content = read_html_content(html_path)
                    if content and content.get('description'):
                        desc = content['description'][:300]
                        md_content += f"**功能描述**: {desc}\n\n"
                    if content and content.get('example_code'):
                        md_content += "**使用示例**:\n\n```idl\n"
                        md_content += content['example_code'][:1000]
                        md_content += "\n```\n\n"
            
            md_content += "---\n\n"
            count += 1
            if count >= 50:  # 每类最多50个
                break
        
        md_content += "\n"
    
    md_content += """
## 附录：使用指南

### 基本使用模式

```idl
; 启动ENVI
e = ENVI()

; 打开栅格数据
raster = e.OpenRaster('input.dat')

; 创建任务
task = ENVITask('TaskName')
task.INPUT_RASTER = raster

; 执行任务
task.Execute

; 获取结果
result = task.OUTPUT_RASTER

; 添加到数据管理器
e.Data.Add, result

; 显示结果
view = e.GetView()
layer = view.CreateLayer(result)
```

### 常用概念

- **栅格(Raster)**: ENVI中影像的基本数据类型
- **任务(Task)**: ENVI 5.x的编程接口，用于执行各种操作
- **虚拟栅格(Virtual Raster)**: 不实际写入磁盘的栅格对象
- **ROI**: 感兴趣区域，用于采样和分析
- **交叠方式(Interleave)**: BIP/BIL/BSQ三种存储方式
- **重采样**: 改变影像的空间分辨率
- **重投影**: 改变影像的坐标系

### 版本信息

本文档基于 **ENVI 5.6** 版本帮助文档生成。

### 版权说明

© 1988-2020 Harris Geospatial Solutions, Inc. All Rights Reserved.

---

**注**: 本文档由自动脚本生成，部分内容可能需要参考官方文档。
"""
    
    return md_content

def main():
    print("生成ENVI IDL帮助文档...")
    md_content = generate_final_markdown()
    
    output_file = 'envi_idl_help.md'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(md_content)
    
    print(f"文档已生成: {output_file}")
    print("完成!")

if __name__ == '__main__':
    main()

