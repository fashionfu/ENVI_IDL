# GitHub推送指南

## 📋 目录
1. [前期准备](#前期准备)
2. [使用批处理脚本（推荐）](#使用批处理脚本推荐)
3. [手动推送步骤](#手动推送步骤)
4. [GitHub认证配置](#github认证配置)
5. [常见问题解决](#常见问题解决)

---

## 🔧 前期准备

### 1. 确保Git已安装

打开命令提示符或PowerShell，输入：
```bash
git --version
```

如果显示版本号（如 `git version 2.x.x`），说明已安装。

**如果未安装：**
- 下载地址：https://git-scm.com/download/win
- 安装时建议全部使用默认选项

### 2. 创建GitHub账号

如果还没有GitHub账号：
- 访问：https://github.com/
- 点击 "Sign up" 注册

### 3. 配置GitHub认证

**重要提示：** 从2021年8月13日起，GitHub不再支持密码认证，必须使用个人访问令牌（PAT）。

---

## 🚀 使用批处理脚本（推荐）

### 步骤1：运行脚本

1. 找到文件：`笔记详情/git_push.bat`
2. **双击运行**该批处理文件
3. 按照屏幕提示操作

### 步骤2：脚本执行流程

脚本会自动完成以下操作：

```
✓ [步骤1] 初始化Git仓库（如果未初始化）
✓ [步骤2] 配置Git用户信息
   - 会提示输入用户名和邮箱（如果未配置）
✓ [步骤3] 创建.gitignore文件
   - 自动排除大文件和临时文件
✓ [步骤4] 添加远程仓库
   - 自动配置：https://github.com/fashionfu/ENVI_IDL.git
✓ [步骤5] 添加所有文件
✓ [步骤6] 显示Git状态
✓ [步骤7] 提交更改
   - 可以输入自定义提交信息
✓ [步骤8] 推送到GitHub
   - 需要GitHub认证
```

### 步骤3：GitHub认证

当脚本执行到推送步骤时，会要求输入认证信息：

**方法1：使用个人访问令牌（PAT）- 推荐**
- 用户名：输入您的GitHub用户名（如：`fashionfu`）
- 密码：输入个人访问令牌（PAT），不是GitHub密码！

**方法2：使用GitHub Desktop或Git Credential Manager**
- 如果已配置，会自动认证

---

## 📝 手动推送步骤

如果不使用批处理脚本，可以手动执行以下步骤：

### 1. 打开命令提示符

```bash
# 切换到项目目录
cd "F:\02_MeteorologyWork\02_正式\2025-10月正式工作\2022南方实验室培训\2022ESE服务开发培训素材包"
```

### 2. 初始化Git仓库

```bash
# 如果还不是git仓库，执行：
git init
```

### 3. 配置用户信息

```bash
# 配置用户名
git config user.name "你的名字"

# 配置邮箱
git config user.email "your.email@example.com"
```

### 4. 创建.gitignore文件

创建一个名为 `.gitignore` 的文件，内容如下：

```gitignore
# IDL/ENVI 项目忽略文件

# 临时文件
*.tmp
*.temp
*.bak
*~

# IDL编译文件
*.sav

# ENVI临时文件
*.enp

# 大文件（数据文件）
*.dat
*.img
*.hdf
*.tif
*.tiff
*.jp2

# 压缩包
*.zip
*.rar
*.7z

# 系统文件
Thumbs.db
.DS_Store
desktop.ini

# IDE配置
.vscode/
.idea/

# 输出目录
output/
results/
temp/
```

### 5. 添加远程仓库

```bash
git remote add origin https://github.com/fashionfu/ENVI_IDL.git
```

### 6. 添加文件并提交

```bash
# 添加所有文件
git add .

# 查看状态
git status

# 提交
git commit -m "添加ENVI/IDL培训素材和学习指南"
```

### 7. 推送到GitHub

```bash
# 设置主分支为main
git branch -M main

# 推送
git push -u origin main
```

---

## 🔐 GitHub认证配置

### 创建个人访问令牌（PAT）

#### 步骤1：登录GitHub

访问：https://github.com/

#### 步骤2：进入设置

1. 点击右上角头像
2. 选择 **Settings**

#### 步骤3：生成令牌

1. 在左侧菜单找到 **Developer settings**（最底部）
2. 点击 **Personal access tokens** → **Tokens (classic)**
3. 点击 **Generate new token** → **Generate new token (classic)**

#### 步骤4：配置令牌

填写以下信息：

- **Note（描述）**: `ENVI_IDL_Project`（或任何你喜欢的名字）
- **Expiration（过期时间）**: 建议选择 `90 days` 或 `No expiration`
- **Select scopes（权限）**: 勾选以下选项：
  - ✅ **repo**（完整仓库访问权限）- 这个最重要！
    - ✅ repo:status
    - ✅ repo_deployment
    - ✅ public_repo
    - ✅ repo:invite
    - ✅ security_events

#### 步骤5：保存令牌

1. 点击底部的 **Generate token**
2. **重要！** 复制生成的令牌（形如：`ghp_xxxxxxxxxxxxxxxxxxxx`）
3. **妥善保存！** 令牌只显示一次，离开页面后将无法再次查看

#### 步骤6：使用令牌

在推送时：
```
Username: fashionfu
Password: ghp_xxxxxxxxxxxxxxxxxxxx（粘贴你的令牌）
```

**注意：** 密码位置输入的是令牌，不是GitHub账号密码！

---

### 配置Git Credential Manager（可选）

为了避免每次都输入令牌，可以配置凭据管理器：

```bash
# Windows系统
git config --global credential.helper manager

# 第一次推送时输入令牌后，会自动保存
```

---

## ❓ 常见问题解决

### 问题1：推送被拒绝（rejected）

**错误信息：**
```
! [rejected] main -> main (fetch first)
error: failed to push some refs
```

**原因：** 远程仓库有本地没有的提交

**解决方法：**
```bash
# 先拉取远程更改
git pull origin main --allow-unrelated-histories

# 如果有冲突，解决后再推送
git push -u origin main
```

---

### 问题2：认证失败

**错误信息：**
```
remote: Support for password authentication was removed
fatal: Authentication failed
```

**原因：** 使用了GitHub密码而不是个人访问令牌

**解决方法：**
- 按照上面的步骤创建PAT
- 使用PAT代替密码

---

### 问题3：文件太大

**错误信息：**
```
remote: error: File xxx is 100.00 MB; this exceeds GitHub's file size limit
```

**原因：** GitHub单个文件限制为100MB

**解决方法：**

1. **方法1：使用.gitignore排除大文件**
   ```bash
   # 编辑.gitignore，添加大文件模式
   *.dat
   *.img
   *.hdf
   
   # 如果已经add了，需要从暂存区移除
   git rm --cached 大文件路径
   git commit -m "移除大文件"
   ```

2. **方法2：使用Git LFS**
   ```bash
   # 安装Git LFS
   git lfs install
   
   # 跟踪大文件类型
   git lfs track "*.dat"
   git lfs track "*.img"
   
   # 提交并推送
   git add .gitattributes
   git add .
   git commit -m "使用Git LFS管理大文件"
   git push
   ```

3. **方法3：不提交数据文件**（推荐）
   - 数据文件通常不适合放在Git中
   - 只提交代码和文档
   - 数据文件可以单独分享（网盘等）

---

### 问题4：中文文件名乱码

**解决方法：**
```bash
# 配置Git正确显示中文
git config --global core.quotepath false
```

---

### 问题5：推送速度慢

**原因：** 网络连接GitHub服务器较慢

**解决方法：**

1. **使用GitHub加速镜像**
   ```bash
   # 修改远程仓库URL（使用镜像）
   git remote set-url origin https://gitclone.com/github.com/fashionfu/ENVI_IDL.git
   ```

2. **配置代理（如果有）**
   ```bash
   # HTTP代理
   git config --global http.proxy http://127.0.0.1:7890
   git config --global https.proxy https://127.0.0.1:7890
   
   # 取消代理
   git config --global --unset http.proxy
   git config --global --unset https.proxy
   ```

---

### 问题6：权限被拒绝（Permission denied）

**错误信息：**
```
remote: Permission to fashionfu/ENVI_IDL.git denied
```

**原因：** 
- 没有该仓库的写权限
- 或者使用了错误的账号

**解决方法：**
1. 确认您是仓库的所有者或协作者
2. 检查使用的是否是正确的GitHub账号
3. 重新生成并使用新的PAT

---

## 📊 推送后验证

推送成功后，访问仓库查看：

**仓库地址：** https://github.com/fashionfu/ENVI_IDL

应该能看到：
- ✅ 所有代码文件
- ✅ 文档文件（.md）
- ✅ 学习指南
- ✅ 提交历史

---

## 🎯 最佳实践建议

### 1. 文件组织

```
ENVI_IDL/
├── README.md                    # 项目说明
├── .gitignore                   # 忽略文件配置
├── 笔记详情/                    # 学习笔记
│   ├── 1031.md                 # 学习指南
│   └── IDL虚拟栅格与全色锐化处理流程详解.md
├── ENVITaskTrainning/           # ENVI任务训练代码
├── 其他代码/                    # 实用代码库
├── 第03-20章/                   # 系统教程代码
└── PPT/（可选）                 # 如果要包含PPT文件
```

### 2. 不要提交的内容

- ❌ 大型数据文件（.dat, .img, .hdf等）
- ❌ 压缩包（.zip, .rar）
- ❌ 临时文件（.tmp, .bak）
- ❌ 编译文件（.sav, .exe, .dll）
- ❌ 个人配置文件

### 3. 应该提交的内容

- ✅ 源代码（.pro文件）
- ✅ 文档（.md, .txt）
- ✅ 配置文件（.task, .style）
- ✅ 小型示例数据（< 1MB）
- ✅ README和说明文档

### 4. 提交信息规范

使用清晰的提交信息：

```bash
# 好的提交信息
git commit -m "添加虚拟栅格处理示例代码"
git commit -m "更新学习指南，增加Q&A章节"
git commit -m "修复NDVI计算中的除零错误"

# 不好的提交信息
git commit -m "update"
git commit -m "修改"
git commit -m "111"
```

---

## 📚 后续维护

### 日常更新流程

```bash
# 1. 修改代码或文档

# 2. 查看修改
git status
git diff

# 3. 添加修改
git add .

# 4. 提交
git commit -m "描述你的修改"

# 5. 推送
git push
```

### 查看历史

```bash
# 查看提交历史
git log

# 查看简洁历史
git log --oneline

# 查看图形化历史
git log --graph --oneline --all
```

---

## 🆘 获取帮助

如果遇到问题：

1. **Git官方文档**：https://git-scm.com/doc
2. **GitHub文档**：https://docs.github.com/
3. **Git教程**：https://www.liaoxuefeng.com/wiki/896043488029600
4. **GitHub社区**：https://github.community/

---

## ✅ 检查清单

推送前确认：

- [ ] Git已安装并配置
- [ ] GitHub账号已创建
- [ ] 个人访问令牌（PAT）已生成
- [ ] .gitignore已配置（排除大文件）
- [ ] 远程仓库URL正确
- [ ] 有仓库的写权限
- [ ] 网络连接正常

推送后确认：

- [ ] GitHub仓库中可以看到文件
- [ ] 文件结构完整
- [ ] README显示正常
- [ ] 提交历史正确

---

## 📞 联系方式

如果有问题，可以通过以下方式获取帮助：

- **GitHub Issues**：在仓库中创建Issue
- **Email**：联系仓库所有者

---

**祝推送顺利！** 🎉

*最后更新：2024年10月31日*

