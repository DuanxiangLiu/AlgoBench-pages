#!/bin/bash
# AlgoBench 本地服务脚本
# 用法:
#   ./start.sh [端口]        前台运行（默认）
#   ./start.sh start [端口]  后台运行
#   ./start.sh stop          停止服务
#   ./start.sh status        查看状态

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.algobench.pid"
LOG_FILE="$SCRIPT_DIR/.algobench.log"
DEFAULT_PORT=8000

get_local_ip() {
    if command -v hostname &> /dev/null; then
        hostname -I 2>/dev/null | awk '{print $1}' | head -1
    elif command -v ipconfig &> /dev/null; then
        ipconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}'
    else
        echo "localhost"
    fi
}

check_python() {
    if command -v python3 &> /dev/null; then
        echo "python3"
    elif command -v python &> /dev/null; then
        echo "python"
    else
        return 1
    fi
}

is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && ps -p "$pid" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

get_port_from_pid() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && ps -p "$pid" > /dev/null 2>&1; then
            local port
            port=$(netstat -tlnp 2>/dev/null | grep "$pid/python" | awk '{print $4}' | grep -oE '[0-9]+$' | head -1)
            if [[ -n "$port" ]]; then
                echo "$port"
                return 0
            fi
        fi
    fi
    echo "$DEFAULT_PORT"
}

do_start() {
    local port="${1:-$DEFAULT_PORT}"
    local daemon="${2:-false}"

    if is_running; then
        local running_port
        running_port=$(get_port_from_pid)
        echo "❌ 服务已在运行中 (PID: $(cat "$PID_FILE"), 端口: $running_port)"
        echo "   使用 './start.sh stop' 停止服务"
        exit 1
    fi

    local python_cmd
    python_cmd=$(check_python)
    if [[ -z "$python_cmd" ]]; then
        echo "❌ 错误: 未找到 Python，请先安装 Python 3"
        exit 1
    fi

    if lsof -i :$port > /dev/null 2>&1; then
        echo "❌ 错误: 端口 $port 已被占用"
        echo ""
        echo "占用进程信息："
        lsof -i :$port 2>/dev/null | head -20
        echo ""
        local pids
        pids=$(lsof -i :$port -t 2>/dev/null | sort -u | tr '\n' ' ')
        if [[ -n "$pids" ]]; then
            echo "建议执行以下命令终止占用进程："
            echo "  kill $pids"
            echo "（若无法终止，强制执行：kill -9 $pids）"
        else
            echo "提示：使用 'lsof -i :$port' 查看占用进程（可能是其他用户的进程，需 sudo）"
            echo "  sudo lsof -i :$port"
        fi
        exit 1
    fi

    echo "=========================================="
    echo "  AlgoBench 本地服务"
    echo "=========================================="
    echo ""
    echo "✓ Python: $($python_cmd --version 2>&1 | head -1)"
    echo "✓ 端口: $port"

    local local_ip
    local_ip=$(get_local_ip)

    echo ""
    echo "访问地址:"
    echo "  本机: http://localhost:$port"
    if [[ "$local_ip" != "localhost" && -n "$local_ip" ]]; then
        echo "  局域网: http://$local_ip:$port"
    fi

    cd "$SCRIPT_DIR"

    local server_script="$SCRIPT_DIR/server.py"

    if [[ ! -f "$server_script" ]]; then
        echo "❌ 错误: 找不到服务器脚本 $server_script"
        exit 1
    fi

    echo ""
    echo "✓ 日志文件：$LOG_FILE"

    local startup_timestamp
    startup_timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # 添加分隔线和启动信息（追加模式）
    echo "" >> "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"
    echo "[$startup_timestamp] [INFO] === AlgoBench Service Starting ===" >> "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"
    echo "[$startup_timestamp] [INFO] Python: $($python_cmd --version 2>&1 | head -1)" >> "$LOG_FILE"
    echo "[$startup_timestamp] [INFO] Port: $port" >> "$LOG_FILE"

    local mode_text
    if [[ "$daemon" == "true" ]]; then
        mode_text="daemon"
    else
        mode_text="foreground"
    fi
    echo "[$startup_timestamp] [INFO] Mode: $mode_text" >> "$LOG_FILE"

    if [[ "$daemon" == "true" ]]; then
        echo "✓ 后台模式运行"
        echo ""
        echo "管理命令:"
        echo "  ./start.sh status  # 查看状态"
        echo "  ./start.sh stop    # 停止服务"
        echo "=========================================="

        nohup $python_cmd "$server_script" $port >> "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"

        sleep 1
        if is_running; then
            echo "✓ 服务启动成功 (PID: $(cat "$PID_FILE"))"
            startup_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            echo "[$startup_timestamp] [INFO] Service started successfully (PID: $(cat "$PID_FILE"))" >> "$LOG_FILE"
            echo "=========================================" >> "$LOG_FILE"
        else
            echo "❌ 服务启动失败，请查看日志：$LOG_FILE"
            startup_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            echo "[$startup_timestamp] [ERROR] Service failed to start" >> "$LOG_FILE"
            echo "=========================================" >> "$LOG_FILE"
            exit 1
        fi
    else
        echo "按 Ctrl+C 停止服务"
        echo "=========================================="
        echo ""
        $python_cmd "$server_script" $port 2>&1 | tee -a "$LOG_FILE"
    fi
}

do_stop() {
    if ! is_running; then
        echo "服务未运行"
        rm -f "$PID_FILE" 2>/dev/null
        exit 0
    fi

    local pid
    pid=$(cat "$PID_FILE")

    echo "正在停止服务 (PID: $pid)..."
    kill "$pid" 2>/dev/null || true

    local count=0
    while ps -p "$pid" > /dev/null 2>&1 && [[ $count -lt 10 ]]; do
        sleep 1
        count=$((count + 1))
    done

    if ps -p "$pid" > /dev/null 2>&1; then
        echo "强制停止..."
        kill -9 "$pid" 2>/dev/null || true
    fi

    rm -f "$PID_FILE"
    echo "✓ 服务已停止"
}

do_status() {
    echo "=========================================="
    echo "  AlgoBench 服务状态"
    echo "=========================================="

    if is_running; then
        local pid
        pid=$(cat "$PID_FILE")
        local port
        port=$(get_port_from_pid)
        local local_ip
        local_ip=$(get_local_ip)

        echo "状态: ✓ 运行中"
        echo "PID: $pid"
        echo "端口: $port"
        echo ""
        echo "访问地址:"
        echo "  本机: http://localhost:$port"
        if [[ "$local_ip" != "localhost" && -n "$local_ip" ]]; then
            echo "  局域网: http://$local_ip:$port"
        fi
        echo ""
        echo "日志文件: $LOG_FILE"
    else
        echo "状态: 未运行"
        rm -f "$PID_FILE" 2>/dev/null
    fi
    echo "=========================================="
}

show_usage() {
    echo "AlgoBench 本地服务脚本"
    echo ""
    echo "用法:"
    echo "  ./start.sh [端口]        前台运行（默认端口 $DEFAULT_PORT）"
    echo "  ./start.sh start [端口]  后台运行"
    echo "  ./start.sh stop          停止服务"
    echo "  ./start.sh status        查看状态"
    echo ""
    echo "示例:"
    echo "  ./start.sh              # 前台运行，端口 $DEFAULT_PORT"
    echo "  ./start.sh 9000         # 前台运行，端口 9000"
    echo "  ./start.sh start        # 后台运行，端口 $DEFAULT_PORT"
    echo "  ./start.sh start 9000   # 后台运行，端口 9000"
    echo "  ./start.sh stop         # 停止服务"
    echo "  ./start.sh status       # 查看状态"
}

case "${1:-}" in
    start)
        do_start "${2:-$DEFAULT_PORT}" "true"
        ;;
    stop)
        do_stop
        ;;
    status)
        do_status
        ;;
    -h|--help|help)
        show_usage
        ;;
    "")
        do_start "$DEFAULT_PORT" "false"
        ;;
    *)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            do_start "$1" "false"
        else
            echo "未知命令: $1"
            show_usage
            exit 1
        fi
        ;;
esac
