#!/bin/bash
# Geekbench 6 CPU 跑分。
# 默认使用固定链接或手动输入链接。

# --- 变量定义 ---
# 默认下载链接
DEFAULT_GEEKBENCH_URL="https://cdn.geekbench.com/Geekbench-6.4.0-Linux.tar.gz"
LOG_FILE="geekbench_$(date +%Y%m%d%H%M%S).log"
GEEKBENCH_URL="" # 用于存储最终使用的下载链接
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

# 2. 获取并确认下载链接
echo "----------------------------------------------------"
echo "请选择你的下载方式："
echo "1) 默认使用 Geekbench 6.4.0 "
echo "2) 手动输入最新版下载链接（请从官网获取：https://www.geekbench.com/download/linux/）"
echo "----------------------------------------------------"

read -p "请输入你的选择 (回车默认选择1): " choice
echo

# 检查输入是否为空，如果是则默认选择 1
if [ -z "$choice" ]; then
    choice=1
fi

case "$choice" in
    1)
        GEEKBENCH_URL="$DEFAULT_GEEKBENCH_URL"
        echo "已选择默认链接：$GEEKBENCH_URL"
        ;;
    2)
        while [ -z "$GEEKBENCH_URL" ] || [ -n "$GEEKBENCH_URL" ] && ! wget -q --spider "$GEEKBENCH_URL"; do
            if [ -z "$GEEKBENCH_URL" ]; then
                read -p "请输入最新版下载链接： " GEEKBENCH_URL
            else
                echo "错误：你提供的链接无法访问，请检查后重试。" >&2
                read -p "请输入新的下载链接： " GEEKBENCH_URL
            fi
        done
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
./geekbench6 | tee "../$LOG_FILE"

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
