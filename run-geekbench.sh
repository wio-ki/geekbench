#!/bin/bash
# Geekbench 跑分脚本。
# 提供 Geekbench 6 和 Geekbench 5 两个选项。

# --- 变量定义 ---
# 默认下载链接
GEEKBENCH_6_URL="https://cdn.geekbench.com/Geekbench-6.4.0-Linux.tar.gz"
GEEKBENCH_5_URL="https://cdn.geekbench.com/Geekbench-5.5.1-Linux.tar.gz"
LOG_FILE="geekbench_$(date +%Y%m%d%H%M%S).log"
GEEKBENCH_URL="" # 用于存储最终使用的下载链接
GEEKBENCH_BIN="" # 用于存储最终的可执行文件名称
TAR_FILE=""
DIR_NAME=""

# --- 函数定义 ---
# 检查命令是否存在的函数
check_command() {
    # 检查 /usr/bin/curl 文件是否存在，而不是依赖 PATH
    if [ ! -f /usr/bin/"$1" ]
    then
        echo "错误：命令 '$1' 未安装。请安装后重试。"
        exit 1
    fi
}

# --- 脚本主体 ---

# 1. 检查必要的依赖
echo "正在检查所需的工具..."
check_command curl
check_command tar
check_command wget

# 2. 获取并确认下载链接和可执行文件
echo "----------------------------------------------------"
echo "请选择你的跑分版本："
echo "1) Geekbench 6.4.0 (回车默认)"
echo "2) Geekbench 5.5.1"
echo "----------------------------------------------------"

read -p "请输入你的选择 (回车默认选择1): " choice
echo

# 检查输入是否为空，如果是则默认选择 1
if [ -z "$choice" ]; then
    choice=1
fi

case "$choice" in
    1)
        GEEKBENCH_URL="$GEEKBENCH_6_URL"
        GEEKBENCH_BIN="geekbench6"
        echo "已选择 Geekbench 6: $GEEKBENCH_URL"
        ;;
    2)
        GEEKBENCH_URL="$GEEKBENCH_5_URL"
        GEEKBENCH_BIN="geekbench5"
        echo "已选择 Geekbench 5: $GEEKBENCH_URL"
        ;;
    *)
        echo "无效的选择，脚本终止。"
        exit 1
        ;;
esac

TAR_FILE=$(basename "$GEEKBENCH_URL")
DIR_NAME=$(basename "$TAR_FILE" .tar.gz)

# 3. 下载并解压文件
if [ -f "$TAR_FILE" ]; then
    echo "压缩包 '$TAR_FILE' 已存在，跳过下载。"
else
    echo "正在下载文件..."
    wget -q "$GEEKBENCH_URL"
    if [ $? -ne 0 ]; then
        echo "错误：下载失败，请检查链接或网络连接。" >&2
        exit 1
    fi
fi

if [ -d "$DIR_NAME" ]; then
    echo "解压目录 '$DIR_NAME' 已存在，跳过解压。"
else
    echo "正在解压文件..."
    tar -xzvf "$TAR_FILE"
    if [ $? -ne 0 ]; then
        echo "错误：解压失败，请检查文件是否损坏或链接是否正确。" >&2
        exit 1
    fi
fi

# 4. 运行基准测试
echo "正在运行 Geekbench CPU 基准测试..."
cd "$DIR_NAME" || exit 1
./"$GEEKBENCH_BIN" | tee "../$LOG_FILE"

echo "CPU 基准测试已完成，结果已保存到日志文件：$LOG_FILE"

# 5. 可选清理 (回车默认清理)
echo
read -p "是否要清理下载的压缩包和解压目录 (回车默认清理, 'n'保留)? " -r REPLY
echo
if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
    cd ..
    rm -rf "$DIR_NAME"
    rm -f "$TAR_FILE"
    echo "文件已清理。"
else
    echo "文件已保留。"
fi
