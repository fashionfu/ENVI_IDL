@echo off
chcp 65001 >nul
echo ======================================
echo Git 仓库初始化和推送脚本
echo ======================================
echo.

REM 切换到当前目录的上级目录（素材包根目录）
cd /d "%~dp0\.."

echo 当前目录: %CD%
echo.

REM 检查是否已经是git仓库
git status >nul 2>&1
if %errorlevel% neq 0 (
    echo [步骤1] 初始化Git仓库...
    git init
    echo Git仓库初始化完成！
    echo.
) else (
    echo [步骤1] Git仓库已存在，跳过初始化
    echo.
)

REM 配置Git用户信息（如果未配置）
echo [步骤2] 配置Git用户信息...
git config user.name >nul 2>&1
if %errorlevel% neq 0 (
    set /p username="请输入您的Git用户名: "
    git config user.name "!username!"
)
git config user.email >nul 2>&1
if %errorlevel% neq 0 (
    set /p email="请输入您的Git邮箱: "
    git config user.email "!email!"
)
echo Git用户配置完成！
echo.

REM 创建.gitignore文件（如果不存在）
if not exist .gitignore (
    echo [步骤3] 创建.gitignore文件...
    (
        echo # IDL/ENVI 项目忽略文件
        echo.
        echo # 临时文件
        echo *.tmp
        echo *.temp
        echo *.bak
        echo *~
        echo.
        echo # IDL编译文件
        echo *.sav
        echo.
        echo # ENVI临时文件
        echo *.enp
        echo.
        echo # 大文件（数据文件）
        echo *.dat
        echo *.img
        echo *.hdf
        echo *.tif
        echo *.tiff
        echo *.jp2
        echo.
        echo # 压缩包
        echo *.zip
        echo *.rar
        echo *.7z
        echo.
        echo # 系统文件
        echo Thumbs.db
        echo .DS_Store
        echo desktop.ini
        echo.
        echo # IDE配置
        echo .vscode/
        echo .idea/
        echo.
        echo # 输出目录
        echo output/
        echo results/
        echo temp/
    ) > .gitignore
    echo .gitignore文件已创建！
    echo.
) else (
    echo [步骤3] .gitignore文件已存在
    echo.
)

REM 添加远程仓库
echo [步骤4] 配置远程仓库...
git remote get-url origin >nul 2>&1
if %errorlevel% neq 0 (
    git remote add origin https://github.com/fashionfu/ENVI_IDL.git
    echo 远程仓库已添加: https://github.com/fashionfu/ENVI_IDL.git
) else (
    echo 远程仓库已存在，更新URL...
    git remote set-url origin https://github.com/fashionfu/ENVI_IDL.git
)
echo.

REM 添加所有文件
echo [步骤5] 添加文件到Git...
git add .
echo 文件添加完成！
echo.

REM 显示状态
echo [步骤6] 当前Git状态:
git status
echo.

REM 提交
echo [步骤7] 提交更改...
set /p commit_msg="请输入提交信息 (直接回车使用默认信息): "
if "%commit_msg%"=="" (
    set commit_msg=添加ENVI/IDL培训素材和学习指南
)
git commit -m "%commit_msg%"
echo 提交完成！
echo.

REM 推送到GitHub
echo [步骤8] 推送到GitHub...
echo.
echo 注意：首次推送可能需要输入GitHub用户名和密码或个人访问令牌（PAT）
echo 如果您还没有配置GitHub认证，请按照提示操作
echo.
pause

git branch -M main
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ======================================
    echo 成功！代码已推送到GitHub仓库
    echo 仓库地址: https://github.com/fashionfu/ENVI_IDL
    echo ======================================
) else (
    echo.
    echo ======================================
    echo 推送失败！可能的原因：
    echo 1. 未配置GitHub认证（需要个人访问令牌PAT）
    echo 2. 网络连接问题
    echo 3. 仓库权限问题
    echo.
    echo 请检查错误信息并重试
    echo ======================================
)

echo.
pause

