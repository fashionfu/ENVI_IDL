#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
增强ENVI IDL帮助文档，添加中文注释和解析
"""

import re

def add_chinese_notes(content):
    """为函数添加中文注释"""
    
    # 常见的函数类型和其中文解释
    chinese_notes = {
        'ENVITask': 'ENVI任务对象，用于执行各种图像处理操作',
        'BinaryGTThresholdRaster': '二值化阈值处理：将大于指定阈值的像元设为1，其余设为0',
        'BinaryLTThresholdRaster': '反向二值化阈值处理：将小于指定阈值的像元设为1，其余设为0',
        'Classification': '分类：对影像进行监督或非监督分类',
        'Detection': '检测：目标检测和异常检测',
        'Filter': '滤波：对影像进行空间滤波处理',
        'Morphological': '形态学：数学形态学操作，如膨胀、腐蚀等',
        'SpectralIndex': '光谱指数：计算植被指数、水体指数等',
        'SubsetRaster': '子集提取：从栅格中提取子区域',
        'MosaicRaster': '影像镶嵌：拼接多幅影像',
        'ReprojectRaster': '重投影：改变影像的坐标系统',
        'ResampleRaster': '重采样：改变影像的空间分辨率',
        'StretchRaster': '拉伸：增强影像对比度',
        'PanSharpening': '全色锐化：融合全色和多光谱影像',
        'Extract': '提取：从数据中提取特定信息',
        'Transform': '变换：对影像进行数学变换',
        'PointCloud': '点云：处理LiDAR点云数据',
        'Vector': '矢量：处理矢量数据',
        'ROI': '感兴趣区域：划定和处理感兴趣区域',
        'Raster': '栅格：栅格数据处理',
        'Image': '图像：图像处理',
    }
    
    # 为每个函数添加中文说明
    lines = content.split('\n')
    enhanced_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        enhanced_lines.append(line)
        
        # 如果是函数标题行
        if line.startswith('### ') and 'ENVI' in line:
            func_name = line.replace('### ', '').strip()
            
            # 查找下一个空行
            next_non_empty = i + 1
            while next_non_empty < len(lines) and lines[next_non_empty].strip():
                next_non_empty += 1
            
            # 在函数标题后添加中文说明
            chinese_desc = generate_chinese_description(func_name)
            if chinese_desc and next_non_empty > i + 1:
                # 在第二行插入中文说明
                enhanced_lines.append(f"\n**中文说明**: {chinese_desc}\n")
        
        i += 1
    
    return '\n'.join(enhanced_lines)

def generate_chinese_description(func_name):
    """根据函数名生成中文描述"""
    
    descriptions = {
        'BinaryGTThresholdRaster': '创建二值栅格，大于阈值的像元为1，其他为0',
        'BinaryLTThresholdRaster': '创建反向二值栅格，小于阈值的像元为1，其他为0',
        'BinaryAutomaticThresholdRaster': '使用自动阈值算法创建二值栅格',
        'BinaryMorphologicalFilterTask': '对二值栅格进行形态学滤波',
        'Classification': '影像分类功能',
        'ColorSliceClassification': '色彩切片分类，通过阈值范围进行分类',
        'ClassificationAggregation': '分类聚合，合并小斑块',
        'ClassificationClumping': '分类聚类，连接相邻相似像元',
        'ClassificationSieving': '分类筛选，去除小斑块',
        'AutoChangeThresholdClassification': '自动变化阈值分类',
        'PercentThresholdClassification': '百分比阈值分类',
        'AnomalyDetection': '异常检测',
        'TargetDetection': '目标检测',
        'ChangeDetection': '变化检测',
        'ImageChangeDetection': '影像变化检测',
        'ThematicChangeDetection': '专题变化检测',
        'GrayscaleMorphologicalFilter': '灰度形态学滤波',
        'SobelFilter': 'Sobel边缘检测滤波器',
        'LowPassFilter': '低通滤波器',
        'HighPassFilter': '高通滤波器',
        'GaussFilter': '高斯滤波器',
        'MedianFilter': '中值滤波器',
        'LeeAdaptiveFilter': 'Lee自适应滤波器',
        'EnhancedLeeAdaptiveFilter': '增强Lee自适应滤波器',
        'KuanAdaptiveFilter': 'Kuan自适应滤波器',
        'EnhancedFrostAdaptiveFilter': '增强Frost自适应滤波器',
        'GammaAdaptiveFilter': 'Gamma自适应滤波器',
        'AdditiveLeeAdaptiveFilter': '加性Lee自适应滤波器',
        'AdditiveMultiplicativeLeeAdaptiveFilter': '加性乘性Lee自适应滤波器',
        'SpectralIndex': '光谱指数计算',
        'NDVI': '归一化植被指数',
        'EVI': '增强植被指数',
        'SAVI': '土壤调节植被指数',
        'BSI': '裸土指数',
        'NDWI': '归一化水体指数',
        'MNDWI': '修改归一化水体指数',
        'NDSI': '归一化积雪指数',
        'NDBI': '归一化建筑指数',
        'SubsetRaster': '提取栅格子集',
        'GeographicSubsetRaster': '地理子集提取',
        'ExtractRasterFromFile': '从文件提取栅格',
        'ExtractBandsFromRaster': '提取波段',
        'ExtractROIsFromFile': '从文件提取感兴趣区域',
        'ExtractGeoJSONFromFile': '从文件提取GeoJSON',
        'MosaicRaster': '栅格镶嵌',
        'BuildMosaicRaster': '构建镶嵌栅格',
        'ReprojectRaster': '重投影栅格',
        'ResampleRaster': '重采样栅格',
        'PixelScaleResampleRaster': '像素尺度重采样',
        'MappingResampleRaster': '映射重采样',
        'LinearPercentStretch': '线性百分比拉伸',
        'LinearRangeStretch': '线性范围拉伸',
        'OptimizedLinearStretch': '优化线性拉伸',
        'GaussianStretch': '高斯拉伸',
        'EqualizationStretch': '均衡化拉伸',
        'LogStretch': '对数拉伸',
        'RootStretch': '平方根拉伸',
        'LowClipRaster': '低值裁剪',
        'HighClipRaster': '高值裁剪',
        'PanSharpening': '全色锐化',
        'NNDiffusePanSharpening': 'NN扩散全色锐化',
        'PCPanSharpening': '主成分全色锐化',
        'GramSchmidtPanSharpening': 'Gram-Schmidt全色锐化',
        'Transform': '影像变换',
        'ForwardPCATransform': '前向主成分变换',
        'InversePCATransform': '反向主成分变换',
        'ForwardMNFTransform': '前向最小噪声分数变换',
        'InverseMNFTransform': '反向最小噪声分数变换',
        'IHSTransform': 'IHS色彩空间变换',
        'RGBToHSIRaster': 'RGB到HSI变换',
        'ForwardTasseledCapTransform': '前向缨帽变换',
        'InverseTasseledCapTransform': '反向缨帽变换',
        'PointCloud': '点云处理',
        'CreatePointCloud': '创建点云',
        'ColorPointCloud': '点云着色',
        'GroundFilterPointCloud': '地面滤波',
        'ClassifyGroundPoints': '分类地面点',
        'ClassifyBuildings': '分类建筑物',
        'ClassifyVegetation': '分类植被',
        'GenerateDigitalElevationModel': '生成数字高程模型',
        'GenerateDigitalSurfaceModel': '生成数字表面模型',
        'GenerateCanopyHeightModel': '生成冠层高度模型',
        'Vector': '矢量处理',
        'ASCIIToVector': 'ASCII转矢量',
        'GeoPackageToShapefile': 'GeoPackage转Shapefile',
        'ReprojectVector': '重投影矢量',
        'BufferZone': '缓冲区生成',
        'ROI': '感兴趣区域处理',
        'ASCIIToROI': 'ASCII转ROI',
        'ClassificationToPixelROI': '分类转像素ROI',
        'ImageThresholdToROI': '影像阈值转ROI',
        'FeatureCountToROI': '要素计数转ROI',
        'VectorRecordsToROI': '矢量记录转ROI',
        'VectorRecordsToSeparateROI': '矢量记录转独立ROI',
        'BuildRasterSeries': '构建栅格序列',
        'BuildTimeSeries': '构建时间序列',
        'VideoToRasterSeries': '视频转栅格序列',
        'ExtractRastersFromRasterSeries': '从栅格序列提取栅格',
        'RegridRasterSeriesByIndex': '按索引重网格栅格序列',
        'LayerStackRaster': '图层堆叠',
        'BuildLayerStack': '构建图层堆叠',
        'BuildBandStack': '构建波段堆叠',
        'MetaspatialRaster': '元空间栅格',
        'MetaspectralRaster': '元光谱栅格',
        'BuildMetaspatialRaster': '构建元空间栅格',
        'BuildMetaspectralRaster': '构建元光谱栅格',
        'CastRaster': '栅格类型转换',
        'ConvertInterleave': '转换交叠方式',
        'ConvertPixelToMapCoordinates': '像素坐标转地图坐标',
        'ConvertMapToPixelCoordinates': '地图坐标转像素坐标',
        'ConvertMapToGeographicCoordinates': '地图坐标转地理坐标',
        'ConvertGeographicToMapCoordinates': '地理坐标转地图坐标',
        'CalculateQUACGainOffset': '计算QUAC增益偏移',
        'ApplyGainOffset': '应用增益偏移',
        'DarkSubtractionCorrection': '暗减法校正',
        'FlatFieldCorrection': '平场校正',
        'GenerateMaskFromVector': '从矢量生成掩膜',
        'GenerateThresholdMask': '生成阈值掩膜',
        'GenerateRasterMask': '生成栅格掩膜',
        'EditRasterMetadata': '编辑栅格元数据',
        'ExportRasterToENVI': '导出栅格到ENVI格式',
        'ExportRasterToPNG': '导出栅格到PNG格式',
        'ExportRasterToTIF': '导出栅格到TIF格式',
        'ExportRasterToJPEG': '导出栅格到JPEG格式',
        'ExportRasterToNSIF10': '导出栅格到NSIF10格式',
        'ExportRasterToCADRG': '导出栅格到CADRG格式',
        'ExportRastersToDirectory': '批量导出栅格到目录',
        'QueryAllTasks': '查询所有任务',
        'QueryRaster': '查询栅格信息',
        'QueryROI': '查询ROI信息',
        'QueryVector': '查询矢量信息',
        'QueryPointCloud': '查询点云信息',
        'QuerySensorModels': '查询传感器模型',
        'DownloadOSMVectors': '下载OSM矢量数据',
        'GenerateGCPsFromReferenceImage': '从参考影像生成GCP',
        'GenerateGCPsFromTiePoints': '从连接点生成GCP',
        'GenerateTiePointsByCrossCorrelation': '通过交叉相关生成连接点',
        'GenerateTiePointsByCrossCorrelationWithOrthorectification': '通过交叉相关和正射校正生成连接点',
        'GenerateTiePointsByMutualInformation': '通过互信息生成连接点',
        'ImageToImageRegistration': '影像配准',
        'ImageIntersection': '影像交集',
        'GenerateContourLines': '生成等值线',
        'GenerateGridLines': '生成网格线',
        'CalculateGridDefinitionFromRasterIntersection': '从栅格交集计算网格定义',
        'CalculateGridDefinitionFromRasterUnion': '从栅格并集计算网格定义',
        'BuildGridDefinitionFromRaster': '从栅格构建网格定义',
        'TopographicShading': '地形阴影',
        'TopographicShadingUsingHLS': '使用HLS的地形阴影',
        'VegetationSuppression': '植被抑制',
        'RadarBackscatter': '雷达后向散射',
        'FXSegmentation': 'FX分割',
        'LabelRegions': '标记区域',
        'CalculateRasterThreshold': '计算栅格阈值',
        'MixtureTunedMatchedFilter': '混合调谐匹配滤波器',
        'SpectralAdaptiveCoherenceEstimator': '光谱自适应相干估计器',
        'Sam': '光谱角制图',
        'MatchFilter': '匹配滤波器',
        'ConstrainedEnergyMinimization': '约束能量最小化',
        'PixelStatistics': '像素统计',
        'FeatureCount': '要素计数',
        'ForwardOrthorectify': '前向正射校正',
        'InverseOrthorectify': '反向正射校正',
        'ApplyRPCProjection': '应用RPC投影',
        'GenerateGeoZoneGrid': '生成地理区域网格',
        'DiceRaster': '栅格切块',
        'CreateSubrects': '创建子矩形',
        'GetSpectrumFromLibrary': '从光谱库获取光谱',
        'AddSpectrumToLibrary': '添加光谱到光谱库',
        'GetColorSlices': '获取颜色切片',
        'GetColorTable': '获取颜色表',
        'GenerateFilename': '生成文件名',
        'GenerateIndexArray': '生成索引数组',
        'ExtractColumnFromArray': '从数组提取列',
        'RegridRasterByIndex': '按索引重网格栅格',
        'RegridRasterByIndexToReference': '按索引重网格栅格到参考',
        'RegridRasterByIndexToSensorProjection': '按索引重网格栅格到传感器投影',
        'GeneratePointCloudsByDenseImageMatching': '通过密集影像匹配生成点云',
        'UploadVectorToArcGISPortal': '上传矢量到ArcGIS Portal',
        'RasterStatistics': '栅格统计',
    }
    
    # 查找匹配的描述
    for key, desc in descriptions.items():
        if key in func_name:
            return desc
    
    # 如果没有匹配，返回通用描述
    if 'Task' in func_name:
        return 'ENVI任务对象，用于执行特定的图像处理操作'
    elif 'Raster' in func_name:
        return '栅格处理对象'
    elif 'Vector' in func_name:
        return '矢量处理对象'
    elif 'PointCloud' in func_name:
        return '点云处理对象'
    else:
        return None

def main():
    print("读取现有文档...")
    with open('envi_idl_help.md', 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("添加中文注释...")
    enhanced_content = add_chinese_notes(content)
    
    print("保存增强后的文档...")
    with open('envi_idl_help.md', 'w', encoding='utf-8') as f:
        f.write(enhanced_content)
    
    print("完成!")

if __name__ == '__main__':
    main()

