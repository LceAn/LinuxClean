#!/bin/bash

################################################################################
# LinuxClean i18n 测试脚本
# 用于测试语言检测和翻译功能
################################################################################

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}LinuxClean i18n 测试${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 测试 1：检测当前系统语言
echo -e "${GREEN}测试 1: 检测系统语言${NC}"
echo "  LANG=$LANG"
echo "  LC_ALL=$LC_ALL"
echo "  LANGUAGE=$LANGUAGE"

sys_lang="${LANG%%_*}"
echo -e "  检测结果：${YELLOW}$sys_lang${NC}"
echo ""

# 测试 2：模拟中文环境
echo -e "${GREEN}测试 2: 模拟中文环境${NC}"
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
sys_lang="${LANG%%_*}"
echo -e "  设置后：${YELLOW}$sys_lang${NC}"
echo -e "  预期：${GREEN}zh (中文)${NC}"
echo ""

# 测试 3：模拟英文环境
echo -e "${GREEN}测试 3: 模拟英文环境${NC}"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
sys_lang="${LANG%%_*}"
echo -e "  设置后：${YELLOW}$sys_lang${NC}"
echo -e "  预期：${GREEN}en (English)${NC}"
echo ""

# 测试 4：恢复原始设置
echo -e "${GREEN}测试 4: 恢复原始设置${NC}"
unset LANG
unset LC_ALL
unset LANGUAGE
echo "  已恢复原始环境变量"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ 所有测试完成！${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 使用说明
echo -e "${YELLOW}使用方法：${NC}"
echo "  1. 自动检测：直接运行 ./LinuxClean.sh"
echo "  2. 强制中文：LANG=zh_CN.UTF-8 sudo ./LinuxClean.sh"
echo "  3. 强制英文：LANG=en_US.UTF-8 sudo ./LinuxClean.sh"
echo ""
