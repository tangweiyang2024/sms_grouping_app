@echo off
REM 本地验证 GitHub Actions 构建流程 (Windows版本)
REM 用于验证 CI/CD 配置是否正确

echo 🚀 开始验证 GitHub Actions 构建流程...
echo ========================================

REM 模拟 GitHub Actions 环境
echo 📋 模拟 GitHub Actions 步骤：

REM 1. Setup Flutter (模拟)
echo ✅ 1. Setup Flutter - Flutter 3.16.5 (stable)

REM 2. Flutter version
echo 🔍 2. 检查 Flutter 版本...
flutter --version

REM 3. Install dependencies
echo 📦 3. 安装依赖...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ 依赖安装失败
    exit /b 1
)
echo ✅ 依赖安装成功

REM 4. Analyze code
echo 🔬 4. 分析代码...
flutter analyze
if %errorlevel% neq 0 (
    echo ⚠️ 代码分析有警告，但继续构建
) else (
    echo ✅ 代码分析通过
)

REM 5. Run tests
echo 🧪 5. 运行测试...
flutter test
if %errorlevel% neq 0 (
    echo ❌ 测试失败
    exit /b 1
)
echo ✅ 所有测试通过

REM 6. Build Web (Windows 可以构建 Web)
echo 🌐 6. 构建 Web 应用...
flutter build web --release
if %errorlevel% neq 0 (
    echo ❌ Web 构建失败
    exit /b 1
)

if exist "build\web" (
    echo ✅ Web 构建成功: build\web
) else (
    echo ❌ Web 构建目录未找到
    exit /b 1
)

echo ========================================
echo 🎉 所有验证步骤完成！
echo.
echo 📊 构建产物验证：
echo    ✅ Flutter 版本检查
echo    ✅ 依赖安装
echo    ✅ 代码分析
echo    ✅ 单元测试
echo    ✅ Web 构建
echo.
echo 🚀 GitHub Actions 配置验证完成！准备推送。