@echo off
REM 简易Git推送脚本
echo ========================================
echo 开始Git推送...
echo ========================================

REM 切换到上级目录（素材包根目录）
cd ..

echo.
echo [1/8] 初始化Git仓库...
git init
if errorlevel 1 echo 仓库已存在或初始化失败

echo.
echo [2/8] 配置Git用户信息...
git config user.name "fashionfu"
git config user.email "fashionfu@example.com"

echo.
echo [3/8] 创建.gitignore文件...
if not exist .gitignore (
echo # IDL/ENVI 忽略文件 > .gitignore
echo *.tmp >> .gitignore
echo *.sav >> .gitignore
echo *.enp >> .gitignore
echo *.dat >> .gitignore
echo *.img >> .gitignore
echo *.hdf >> .gitignore
echo *.tif >> .gitignore
echo *.tiff >> .gitignore
echo *.jp2 >> .gitignore
echo *.zip >> .gitignore
echo *.rar >> .gitignore
echo output/ >> .gitignore
)

echo.
echo [4/8] 添加远程仓库...
git remote remove origin 2>nul
git remote add origin https://github.com/fashionfu/ENVI_IDL.git

echo.
echo [5/8] 添加文件...
git add .

echo.
echo [6/8] 查看状态...
git status

echo.
echo [7/8] 提交更改...
git commit -m "添加ENVI/IDL培训素材和学习指南"

echo.
echo [8/8] 推送到GitHub...
echo 注意：需要输入GitHub用户名和个人访问令牌(PAT)
git branch -M main
git push -u origin main

echo.
if errorlevel 0 (
    echo ========================================
    echo 推送成功！
    echo 访问: https://github.com/fashionfu/ENVI_IDL
    echo ========================================
) else (
    echo ========================================
    echo 推送失败，请检查：
    echo 1. GitHub个人访问令牌是否正确
    echo 2. 网络连接是否正常
    echo ========================================
)

pause

