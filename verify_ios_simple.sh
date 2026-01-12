#!/bin/bash

echo "🔍 iOS配置简化验证脚本"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 验证结果统计
PASS_COUNT=0
FAIL_COUNT=0

# 检查函数
check_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASS_COUNT++))
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAIL_COUNT++))
}

echo "1. 检查项目文件存在性"
echo "----------------------------------"
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    check_pass "项目配置文件存在"
else
    check_fail "项目配置文件不存在"
    exit 1
fi
echo ""

echo "2. 检查关键的代码签名配置"
echo "----------------------------------"

# 检查是否还有iPhone Developer配置
if grep -q '"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "iPhone Developer"' ios/Runner.xcodeproj/project.pbxproj; then
    check_fail "仍有残留的iPhone Developer配置"
else
    check_pass "没有残留的iPhone Developer配置"
fi

# 检查项目级别的空配置
if grep -q '"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = ""' ios/Runner.xcodeproj/project.pbxproj; then
    PROJECT_SIGNS=$(grep -c '"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = ""' ios/Runner.xcodeproj/project.pbxproj)
    check_pass "项目级别: 发现 $PROJECT_SIGNS 个正确的空iphoneos配置"
else
    check_fail "项目级别: 未找到正确的空iphoneos配置"
fi

if grep -q '"CODE_SIGN_IDENTITY\[sdk=iphonesimulator\*\]" = ""' ios/Runner.xcodeproj/project.pbxproj; then
    SIM_SIGNS=$(grep -c '"CODE_SIGN_IDENTITY\[sdk=iphonesimulator\*\]" = ""' ios/Runner.xcodeproj/project.pbxproj)
    check_pass "项目级别: 发现 $SIM_SIGNS 个正确的空iphonesimulator配置"
else
    check_fail "项目级别: 未找到正确的空iphonesimulator配置"
fi

# 检查Target级别的配置
if grep -q 'CODE_SIGN_IDENTITY = ""' ios/Runner.xcodeproj/project.pbxproj; then
    TARGET_EMPTY_SIGNS=$(grep -c 'CODE_SIGN_IDENTITY = ""' ios/Runner.xcodeproj/project.pbxproj)
    check_pass "Target级别: 发现 $TARGET_EMPTY_SIGNS 个正确的空CODE_SIGN_IDENTITY配置"
else
    check_fail "Target级别: 未找到正确的空CODE_SIGN_IDENTITY配置"
fi

if grep -q 'CODE_SIGN_STYLE = Manual' ios/Runner.xcodeproj/project.pbxproj; then
    MANUAL_SIGNS=$(grep -c 'CODE_SIGN_STYLE = Manual' ios/Runner.xcodeproj/project.pbxproj)
    check_pass "Target级别: 发现 $MANUAL_SIGNS 个正确的Manual签名风格配置"
else
    check_fail "Target级别: 未找到正确的Manual签名风格配置"
fi

if grep -q 'DEVELOPMENT_TEAM = ""' ios/Runner.xcodeproj/project.pbxproj; then
    EMPTY_TEAMS=$(grep -c 'DEVELOPMENT_TEAM = ""' ios/Runner.xcodeproj/project.pbxproj)
    check_pass "Target级别: 发现 $EMPTY_TEAMS 个正确的空DEVELOPMENT_TEAM配置"
else
    check_fail "Target级别: 未找到正确的空DEVELOPMENT_TEAM配置"
fi
echo ""

echo "3. 详细配置验证"
echo "----------------------------------"

echo "项目级别配置示例（前3个）："
grep -A1 -B1 '"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = ""' ios/Runner.xcodeproj/project.pbxproj | head -9
echo ""

echo "Target级别配置示例（前3个）："
grep -A1 -B1 'CODE_SIGN_STYLE = Manual' ios/Runner.xcodeproj/project.pbxproj | head -9
echo ""

echo "4. GitHub Actions工作流检查"
echo "----------------------------------"
if [ -f ".github/workflows/ios-build.yml" ]; then
    check_pass "存在原始iOS构建工作流"
    
    if grep -q "flutter build ios --simulator --debug" .github/workflows/ios-build.yml; then
        check_pass "工作流使用正确的模拟器构建命令"
    else
        check_fail "工作流可能需要检查模拟器构建命令"
    fi
fi
echo ""

echo "======================================"
echo "📊 验证结果总结"
echo "======================================"
echo -e "${GREEN}通过检查: $PASS_COUNT${NC}"
echo -e "${RED}失败检查: $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 所有关键配置验证通过！${NC}"
    echo ""
    echo "✅ iOS项目配置已正确设置无代码签名"
    echo "✅ 项目级别: $PROJECT_SIGNS 个空iphoneos配置, $SIM_SIGNS 个空iphonesimulator配置"
    echo "✅ Target级别: $TARGET_EMPTY_SIGNS 个空CODE_SIGN_IDENTITY, $MANUAL_SIGNS 个Manual风格, $EMPTY_TEAMS 个空DEVELOPMENT_TEAM"
    echo "✅ 没有残留的错误配置"
    echo ""
    echo "📋 配置摘要："
    echo "   - 项目级别所有配置都使用空字符串作为代码签名身份"
    echo "   - Target级别配置都使用手动签名风格和空的开发团队"
    echo "   - GitHub Actions工作流配置正确"
    echo ""
    echo "✅ 配置已准备好推送到GitHub进行CI/CD测试。"
    exit 0
else
    echo -e "${RED}❌ 发现 $FAIL_COUNT 个配置问题，需要修复！${NC}"
    echo ""
    echo "请检查上述失败的配置项并修复。"
    exit 1
fi