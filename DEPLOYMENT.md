# 本地部署指南

> 从 GitHub Pages 一键部署 AlgoBench，支持内网访问

---

## 快速部署

### 1. Clone 公开仓库

```bash
git clone https://github.com/DuanxiangLiu/AlgoBench-pages.git
cd AlgoBench-pages
```

---

### 2. 一键启动

**Linux/Mac（推荐）:**

```bash
# 前台运行（默认端口 8000）
./start.sh

# 指定端口
./start.sh 3000

# 后台运行
./start.sh start
```

**Windows:**

```powershell
# 方法 1: 使用 server.py（推荐，支持路径重写）
python server.py 8000
# 访问 http://localhost:8000/

# 方法 2: 使用标准 HTTP 服务器
python -m http.server 8000
# 访问 http://localhost:8000/AlgoBench-pages/
```

---

### 3. 访问地址

| 启动方式 | 访问地址 | 说明 |
|---------|---------|------|
| `./start.sh` | `http://localhost:8000/` | ✅ 推荐，自动路径重写 |
| `python server.py` | `http://localhost:8000/` | ✅ 支持路径重写 |
| `python -m http.server` | `http://localhost:8000/AlgoBench-pages/` | ⚠️ 需手动加路径 |

---

### 4. 内网访问

启动后，同事可通过以下地址访问：

```
http://<你的IP地址>:8000
```

**查看本机 IP:**

```bash
# Linux/Mac
hostname -I | awk '{print $1}'
```

---

## CLI open 工作流（推荐）

部署好内网服务后，配合单文件 CLI 可以一行命令把 CSV 文件变成浏览器里可分享的分析结果。CLI 无需 npm install，下载即用。

### 1. 获取 CLI

```bash
# 公开仓库里已自带 algobench-cli.js（clone 后直接用）
git clone https://github.com/DuanxiangLiu/AlgoBench-pages.git
cd AlgoBench-pages

# 或单独下载到任意目录
curl -O https://raw.githubusercontent.com/DuanxiangLiu/AlgoBench-pages/main/algobench-cli.js
```

要求：Node.js >= 20.19.0（无需 npm install，文件已打包所有依赖）

### 2. 指向内网服务并打开

```bash
# 显式指定内网服务地址
node algobench-cli.js open data.csv -b V1 -c V2 --server http://192.168.1.100:8000

# 或通过环境变量（适合内网常驻）
export ALGOBENCH_SERVER=http://192.168.1.100:8000
node algobench-cli.js open data.csv -b V1 -c V2
```

CLI 会读取 CSV、生成 `#share=` 链接并自动用默认浏览器打开内网实例，浏览器加载后自动还原数据与分析状态。

### 3. 生成可分享链接（不自动打开浏览器）

```bash
# 链接输出到 stdout，可复制给同事
node algobench-cli.js share data.csv -b V1 -c V2 --server http://192.168.1.100:8000

# 写入文件
node algobench-cli.js share data.csv -b V1 -c V2 -o share_url.txt
```

> 💡 内网部署 + CLI 的组合适合：把分析结果快速发给同事复现、在 CI 中生成报告链接、避免手动粘贴大文件。

详见 [CLI 文档](./CLI.md)。

---

## 服务管理

```bash
# 后台模式
./start.sh start          # 启动后台服务（默认端口 8000）
./start.sh start 3000     # 指定端口启动
./start.sh status         # 查看状态
./start.sh stop           # 停止服务

# 前台模式
./start.sh                # 前台运行（Ctrl+C 停止）
./start.sh 3000           # 指定端口前台运行
```

日志文件：`.algobench.log`（可直接打开查看）

---

## 更新版本

```bash
cd AlgoBench-pages
git pull
```

---

## 常见问题

### Q: start.sh 没有执行权限？

```bash
chmod +x start.sh
```

### Q: 端口被占用？

```bash
lsof -i :8000            # 查看占用端口的进程
./start.sh 3000          # 使用其他端口
```

### Q: 访问时显示空白页？

确保使用 `./start.sh` 启动，或访问正确的子路径 `/AlgoBench-pages/`。

### Q: 同事无法访问？

检查：
1. IP 地址是否正确（使用 `hostname -I | awk '{print $1}'` 查看）
2. 是否在同一局域网
3. 防火墙是否开放端口

**开放防火墙端口：**

```bash
# Ubuntu/Debian
sudo ufw allow 8000/tcp

# CentOS/RHEL
sudo firewall-cmd --add-port=8000/tcp --permanent
sudo firewall-cmd --reload
```

### Q: 如何查看访问日志？

直接打开日志文件 `.algobench.log`，记录了所有 HTTP 请求（时间戳、客户端 IP、响应状态码）。

---

## 安全提示

- Python 的 `http.server` 模块仅适用于开发测试和内网使用
- 不要在服务目录中放置敏感文件
- 不要暴露在公网环境

---

## Python SDK

AlgoBench 还提供了 Python SDK，支持命令行和 Python 库两种方式调用分析算法，适合脚本自动化和 AI Agent 集成。

```bash
pip install algobench-sdk
```

详见 [PYTHON_SDK.md](./PYTHON_SDK.md)。

---

## 相关文档

- [README.md](./README.md) - 项目介绍
- [server.py](./server.py) - HTTP 服务器实现
- [PYTHON_SDK.md](./PYTHON_SDK.md) - Python SDK 使用文档
- [CLI.md](./CLI.md) - 命令行 CLI 使用文档
