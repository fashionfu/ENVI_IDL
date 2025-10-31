#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
解析ENVI IDL帮助文档，生成中文说明文档
"""

import xml.etree.ElementTree as ET
import os
import re
from html.parser import HTMLParser
from pathlib import Path

class HTMLTextExtractor(HTMLParser):
    """提取HTML中的纯文本内容"""
    def __init__(self):
        super().__init__()
        self.text = []
        self.in_code = False
        self.in_script = False
        self.in_style = False
        self.current_tag = None
        
    def handle_starttag(self, tag, attrs):
        self.current_tag = tag
        if tag in ['code', 'pre', 'tt']:
            self.in_code = True
        elif tag in ['script', 'style']:
            if tag == 'script':
                self.in_script = True
            else:
                self.in_style = True
    
    def handle_endtag(self, tag):
        if tag in ['code', 'pre', 'tt']:
            self.in_code = False
        elif tag in ['script', 'style']:
            self.in_script = False
            self.in_style = False
        if tag == 'p':
            self.text.append('\n\n')
        elif tag in ['br', 'div', 'h1', 'h2', 'h3']:
            self.text.append('\n')
        self.current_tag = None
    
    def handle_data(self, data):
        if not self.in_script and not self.in_style:
            if self.in_code or self.current_tag == 'h1' or self.current_tag == 'h2' or self.current_tag == 'h3':
                self.text.append(data.strip())
            elif data.strip():
                self.text.append(' ' + data.strip())
    
    def get_text(self):
        text = ''.join(self.text)
        # 清理多余的空白
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'\n\s*\n+', '\n\n', text)
        return text.strip()

def read_html_content(file_path):
    """读取HTML文件并提取主要内容"""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
        # 提取主要内容部分（在body标签内）
        body_match = re.search(r'<body[^>]*>(.*?)</body>', content, re.DOTALL | re.IGNORECASE)
        if not body_match:
            return None
            
        body_content = body_match.group(1)
        
        # 提取标题
        title_match = re.search(r'<h1[^>]*>(.*?)</h1>', body_content, re.DOTALL | re.IGNORECASE)
        title = title_match.group(1) if title_match else ""
        title = re.sub(r'<[^>]+>', '', title).strip()
        
        # 提取描述段落
        p_matches = re.findall(r'<p[^>]*>(.*?)</p>', body_content, re.DOTALL | re.IGNORECASE)
        description = ""
        for p in p_matches[:3]:  # 只取前3个段落
            p_clean = re.sub(r'<[^>]+>', '', p).strip()
            if p_clean and len(p_clean) > 20:
                description += p_clean + "\n"
        
        # 提取代码示例
        code_pattern = r'<p class="Code">(.*?)</p>'
        code_matches = re.findall(code_pattern, body_content, re.DOTALL | re.IGNORECASE)
        example_code = ""
        if code_matches:
            example_code = '\n'.join([re.sub(r'<[^>]+>', '', code).strip() for code in code_matches])
        
        # 提取属性列表
        properties = {}
        prop_pattern = r'<h3 class="Property">.*?<a[^>]*>(.*?)</a>.*?</h3>.*?<p>(.*?)</p>'
        prop_matches = re.findall(prop_pattern, body_content, re.DOTALL | re.IGNORECASE)
        for prop_name, prop_desc in prop_matches:
            prop_name = re.sub(r'<[^>]+>', '', prop_name).strip()
            prop_desc = re.sub(r'<[^>]+>', '', prop_desc).strip()
            if prop_name and prop_desc:
                properties[prop_name] = prop_desc
        
        return {
            'title': title,
            'description': description,
            'example_code': example_code,
            'properties': properties
        }
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return None

def parse_envi_catalog():
    """解析envi_catalog.xml文件"""
    catalog_path = 'envi_catalog.xml'
    
    if not os.path.exists(catalog_path):
        print(f"错误: 找不到文件 {catalog_path}")
        return None
    
    tree = ET.parse(catalog_path)
    root = tree.getroot()
    
    functions = []
    classes = []
    
    for routine in root.findall('.//ROUTINE'):
        name = routine.get('name', '')
        link = routine.get('link', '')
        syntax = routine.find('.//SYNTAX')
        syntax_text = syntax.get('name', '') if syntax is not None else ''
        
        if 'ENVI' in name or 'IMAGE' in name or 'RASTER' in name or 'SPECTRAL' in name:
            functions.append({
                'name': name,
                'link': link,
                'syntax': syntax_text
            })
    
    for cls in root.findall('.//CLASS'):
        name = cls.get('name', '')
        link = cls.get('link', '')
        
        if 'ENVI' in name:
            properties = []
            for prop in cls.findall('.//PROPERTY'):
                prop_name = prop.get('name', '')
                properties.append(prop_name)
            
            classes.append({
                'name': name,
                'link': link,
                'properties': properties
            })
    
    return {'functions': functions, 'classes': classes}

def generate_markdown(catalog_data):
    """生成Markdown格式的文档"""
    
    md_content = """# ENVI IDL 遥感图像处理函数参考手册

本文档整合了ENVI/IDL帮助文档中所有与遥感图像处理相关的函数和算法说明。

## 目录

- [一、ENVI基础函数](#一envi基础函数)
- [二、栅格处理函数](#二栅格处理函数)
- [三、光谱处理函数](#三光谱处理函数)
- [四、分类与检测函数](#四分类与检测函数)
- [五、ENVITask任务函数](#五envitask任务函数)
- [六、ENVI类与方法](#六envi类与方法)

---

"""

    # 组织函数分类
    categories = {
        '基础': [],
        '栅格': [],
        '光谱': [],
        '分类': [],
        '检测': [],
        '滤波': [],
        '几何': [],
        '变换': []
    }
    
    for func in catalog_data['functions']:
        name = func['name']
        # 根据名称分类
        if 'CLASSIFICATION' in name or 'CLASS' in name:
            categories['分类'].append(func)
        elif 'DETECTION' in name or 'DETECT' in name:
            categories['检测'].append(func)
        elif 'FILTER' in name or 'KERNEL' in name or 'MORPHOLOGICAL' in name:
            categories['滤波'].append(func)
        elif 'SPECTRAL' in name or 'INDEX' in name:
            categories['光谱'].append(func)
        elif 'RASTER' in name or 'IMAGE' in name:
            categories['栅格'].append(func)
        elif 'RESAMPLE' in name or 'SUBSET' in name or 'MOSAIC' in name:
            categories['几何'].append(func)
        elif 'TRANSFORM' in name or 'STRETCH' in name or 'STRETCH' in name:
            categories['变换'].append(func)
        else:
            categories['基础'].append(func)
    
    # 生成文档内容
    help_dir = Path('online_help/Subsystems/envi/Content/ExtendCustomize')
    
    # 一、ENVI基础函数
    md_content += "## 一、ENVI基础函数\n\n"
    for func in categories['基础'][:50]:  # 限制数量
        name = func['name']
        md_content += f"### {name}\n\n"
        md_content += f"**语法**: `{func['syntax']}`\n\n"
        
        # 尝试读取HTML文档
        html_link = func['link']
        html_path = help_dir / html_link if help_dir.exists() else None
        if html_path and html_path.exists():
            content = read_html_content(html_path)
            if content:
                md_content += f"**说明**: {content['description']}\n\n"
                if content['example_code']:
                    md_content += "**示例代码**:\n\n```idl\n"
                    md_content += content['example_code'][:500]
                    md_content += "\n```\n\n"
        
        md_content += "---\n\n"
    
    # 二、栅格处理函数
    md_content += "## 二、栅格处理函数\n\n"
    for func in categories['栅格'][:100]:
        name = func['name']
        md_content += f"### {name}\n\n"
        md_content += f"**语法**: `{func['syntax']}`\n\n"
        
        html_link = func['link']
        html_path = help_dir / html_link if help_dir.exists() else None
        if html_path and html_path.exists():
            content = read_html_content(html_path)
            if content:
                md_content += f"**说明**: {content['description']}\n\n"
                if content['properties']:
                    md_content += "**主要属性**:\n\n"
                    for prop_name, prop_desc in list(content['properties'].items())[:5]:
                        md_content += f"- **{prop_name}**: {prop_desc[:100]}\n"
                    md_content += "\n"
        
        md_content += "---\n\n"
    
    # 三、光谱处理函数
    md_content += "## 三、光谱处理函数\n\n"
    for func in categories['光谱'][:80]:
        name = func['name']
        md_content += f"### {name}\n\n"
        md_content += f"**语法**: `{func['syntax']}`\n\n"
        
        html_link = func['link']
        html_path = help_dir / html_link if help_dir.exists() else None
        if html_path and html_path.exists():
            content = read_html_content(html_path)
            if content:
                md_content += f"**说明**: {content['description']}\n\n"
        
        md_content += "---\n\n"
    
    # 四、分类与检测函数
    md_content += "## 四、分类与检测函数\n\n"
    for func in categories['分类'] + categories['检测']:
        name = func['name']
        md_content += f"### {name}\n\n"
        md_content += f"**语法**: `{func['syntax']}`\n\n"
        
        html_link = func['link']
        html_path = help_dir / html_link if help_dir.exists() else None
        if html_path and html_path.exists():
            content = read_html_content(html_path)
            if content:
                md_content += f"**说明**: {content['description']}\n\n"
        
        md_content += "---\n\n"
    
    # 五、ENVITask任务函数
    md_content += "## 五、ENVITask任务函数\n\n"
    md_content += "ENVITask是ENVI 5.x引入的新的编程接口，用于执行各种图像处理任务。\n\n"
    
    task_files = list((help_dir / 'ENVITasks').glob('ENVI*.htm'))
    for task_file in sorted(task_files)[:150]:
        content = read_html_content(task_file)
        if content and content['title']:
            md_content += f"### {content['title']}\n\n"
            if content['description']:
                md_content += f"**功能说明**: {content['description'][:300]}\n\n"
            if content['example_code']:
                md_content += "**使用示例**:\n\n```idl\n"
                md_content += content['example_code'][:800]
                md_content += "\n```\n\n"
            md_content += "---\n\n"
    
    md_content += """
## 附录

### 使用说明

1. **函数参数**: 大部分函数使用关键字参数，如 `INPUT_RASTER`, `OUTPUT_RASTER` 等
2. **返回值**: 函数通常返回处理后的栅格对象或任务对象
3. **虚拟栅格**: 使用 `*` 作为输出URI可创建虚拟栅格，不写入磁盘
4. **批量处理**: 可以使用数组或循环结构进行批量处理

### 常用模式

```idl
; 启动ENVI
e = ENVI()

; 打开栅格
raster = e.OpenRaster('input.dat')

; 创建任务
task = ENVITask('TaskName')
task.INPUT_RASTER = raster
task.Execute

; 添加输出
e.Data.Add, task.OUTPUT_RASTER

; 显示结果
view = e.GetView()
layer = view.CreateLayer(task.OUTPUT_RASTER)
```

### 版本信息

本文档基于ENVI 5.6版本帮助文档生成。

---

**注意**: 本文档为自动生成，部分内容可能不完整。建议结合官方帮助文档使用。
"""
    
    return md_content

def main():
    print("开始解析ENVI帮助文档...")
    
    # 解析catalog文件
    print("解析envi_catalog.xml...")
    catalog_data = parse_envi_catalog()
    
    if not catalog_data:
        print("错误: 无法解析catalog文件")
        return
    
    print(f"找到 {len(catalog_data['functions'])} 个函数")
    print(f"找到 {len(catalog_data['classes'])} 个类")
    
    # 生成Markdown文档
    print("生成Markdown文档...")
    md_content = generate_markdown(catalog_data)
    
    # 写入文件
    output_file = 'envi_idl_help.md'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(md_content)
    
    print(f"文档已生成: {output_file}")
    print("完成!")

if __name__ == '__main__':
    main()

