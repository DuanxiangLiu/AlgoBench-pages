# AlgoBench CLI

> 通过命令行快速打开 AlgoBench 网页并加载 CSV 数据，无需手动粘贴。

## 安装

### 下载单文件（推荐，内网/无网可用）

从公开仓库下载 [`algobench-cli.js`](./algobench-cli.js)（单文件，无任何依赖）：

```bash
# 方式 1：curl 下载
curl -O https://raw.githubusercontent.com/DuanxiangLiu/AlgoBench-pages/main/algobench-cli.js

# 方式 2：git clone 公开仓库后直接用
git clone https://github.com/DuanxiangLiu/AlgoBench-pages.git
cd AlgoBench-pages
node algobench-cli.js --version
```

要求：Node.js >= 20.19.0（无需 npm install，文件已打包所有依赖）

使用方式（任选其一）：

```bash
node algobench-cli.js open data.csv              # 直接用 node 运行
chmod +x algobench-cli.js && ./algobench-cli.js open data.csv   # 加可执行权限
alias algobench="node $(pwd)/algobench-cli.js"   # 设别名后可像命令一样用
```

> 本文档示例统一用 `node algobench-cli.js`，设了别名后可简写为 `algobench`。

### 数据分析命令（可选）

`analyze`/`stats`/`quality`/`diagnose`/`validate` 透传到 Python SDK，需额外安装：

```bash
pip install algobench-sdk
```

`open`/`share` 命令无需 Python，纯 JS 实现。

## 内网分发

部署内网服务（见 [DEPLOYMENT.md](./DEPLOYMENT.md)）后，团队成员无需互联网即可使用 CLI 和 Python SDK。

### CLI（单文件，无需联网）

`algobench-cli.js` 是自包含单文件，所有依赖（含 pako）已打包。同事拿到这个文件就能用，无需 npm install。

分发方式任选其一：

- IM / U 盘 / 共享文件夹直接传文件
- 内网 git 服务器 clone 公开仓库
- 内网 HTTP 下载：`curl -O http://内网IP:8000/algobench-cli.js`（部署目录即公开仓库根目录）

前提：同事机器装了 Node.js >= 20.19.0（无 Node 时去 <https://nodejs.org/> 下载 LTS 版）。

```bash
# 同事拿到文件后直接用
node algobench-cli.js open data.csv --server http://内网IP:8000
```

### Python SDK（需 pip 安装）

`analyze`/`stats`/`quality`/`diagnose`/`validate` 命令依赖 Python SDK，内网无网场景有三种方式：

**方式 1：离线 wheel（推荐，一次性准备）**

```bash
# 有网机器上下载 wheel 及其依赖
pip download algobench-sdk -d ./algobench-wheels

# 拷贝 algobench-wheels 目录到内网机器后安装
pip install --no-index --find-links ./algobench-wheels algobench-sdk
```

**方式 2：内网 PyPI 镜像（devpi / bandersnatch）**

```bash
pip install algobench-sdk -i http://内网PyPI/simple --trusted-host 内网PyPI
```

**方式 3：源码安装（从公开仓库）**

```bash
# 拷贝 python/ 目录到内网后
cd python && pip install -e .
```

> `open`/`share` 命令无需 Python，纯 JS 实现，不受影响。

## 命令一览

```bash
node algobench-cli.js <command> [files...] [options]
node algobench-cli.js <file.csv>                  # 简写：等价于 open
```

### 浏览器交互（JS 实现，无需 Python）

| 命令 | 作用 |
| ---- | ---- |
| `open` | 打开浏览器加载数据，自动还原到 AlgoBench 界面（多文件 = 多个独立数据集 tab） |
| `share` | 生成分享 URL，输出到 stdout 或 `--output` 文件 |
| `merge` | 合并多个 CSV（增加算法或增加 Case），生成单个对比 dataset |

```bash
node algobench-cli.js open <files...> [--baseline X] [--compare Y] [--server URL] [--name NAME] [--browser B]
node algobench-cli.js share <files...> [--baseline X] [--compare Y] [--output FILE] [--name NAME]
node algobench-cli.js merge <f1.csv> <f2.csv> [...] [--mode algorithm|case] [--algos n1,n2,...]
                              [--server URL] [--name NAME] [--output FILE] [--browser B]
```

### 数据分析（透传 Python SDK）

| 命令 | 作用 |
| ---- | ---- |
| `analyze` | 完整分析（解析→统计→决策） |
| `stats` | 单指标统计 |
| `quality` | 数据质量检查 |
| `diagnose` | 数据诊断 |
| `validate` | CSV 格式验证 |

```bash
node algobench-cli.js analyze <file> [--baseline X] [--compare Y] [--metrics a,b] [--criteria standard] [--format json|table]
node algobench-cli.js stats <file> --metric NAME [--baseline X] [--compare Y] [--format json|table]
node algobench-cli.js quality <file> [--format json|table]
node algobench-cli.js diagnose <file> [--format json|table]
node algobench-cli.js validate <file> [--format json|table]
```

### 通用

```bash
node algobench-cli.js --help          # 显示帮助
node algobench-cli.js --version       # 显示版本
node algobench-cli.js <command> -h    # 子命令帮助
```

## 选项说明

| 选项 | 说明 | 默认值 |
| ---- | ---- | ---- |
| `--baseline`, `-b` | 基线算法名（对照版本，改进率的分母） | 从文件名推断 |
| `--compare`, `-c` | 对比算法名（新版本，要验证的） | 从文件名推断 |
| `--server` | AlgoBench 网页服务地址，CLI 会把数据拼成 `#share=` 附到该 URL 后打开 | `$ALGOBENCH_SERVER` 或 `http://localhost:8000` |
| `--name`, `-n` | 分享数据集在界面里显示的名称 | 文件名拼接（多文件用 ` vs `） |
| `--output`, `-o` | 输出到文件（`share` 输出 URL；`merge --output` 输出合并 CSV） | stdout |
| `--browser` | 指定浏览器名称或可执行文件路径（仅 `open`/`merge`） | 系统默认浏览器 |
| `--mode` | 合并模式：`algorithm`（外连接+前缀）或 `case`（行堆叠），仅 `merge` | `algorithm` |
| `--algos` | 每个文件对应的算法名，逗号分隔（仅 `merge --mode algorithm`） | 从文件名推断 |
| `--metrics`, `-m` | 指标列表，逗号分隔（仅 `analyze`） | 全部 |
| `--criteria` | 分析标准（仅 `analyze`） | `standard` |
| `--format`, `-f` | 输出格式 `json`/`table` | 命令相关 |

### baseline 与 compare 的含义

- **`--baseline`（基线）**：对照版本，通常是旧算法或昨天的结果。改进率 = `(compare - baseline) / baseline`
- **`--compare`（对比）**：要验证的新版本，通常是新算法或今天的结果

示例：`--baseline V1 --compare V2` 表示"V2 相对 V1 改进了多少"。CLI 文档里的 `X`/`Y` 只是占位符，`X` 代表填入基线算法名，`Y` 代表填入对比算法名。

### `--browser` 指定浏览器

`open` 和 `merge` 默认用系统默认浏览器打开 URL。通过 `--browser` 可以指定用某个浏览器打开，支持三种写法：

| 写法 | 示例 | 说明 |
| ---- | ---- | ---- |
| 浏览器名称 | `--browser chrome` | 调用系统命令（需在 PATH 中） |
| 应用名（macOS） | `--browser "Google Chrome"` | 配合 `open -a` 调用 |
| 可执行文件路径 | `--browser /usr/bin/google-chrome` | 直接调用该路径的可执行文件 |

各平台行为差异：

| 平台 | 默认命令 | 指定 `--browser` 后 |
| ---- | -------- | ------------------- |
| macOS | `open "<url>"` | `open -a "<browser>" "<url>"` |
| Windows | `start "" "<url>"` | `start "" "<browser>" "<url>"` |
| Linux | `xdg-open "<url>"` | `"<browser>" "<url>"`（直接调用） |

示例：

```bash
# macOS：用 Chrome 打开
node algobench-cli.js open data.csv --browser "Google Chrome"

# Linux：用 firefox 打开
node algobench-cli.js merge y.csv t.csv --browser firefox

# 跨平台：用可执行文件路径（最稳）
node algobench-cli.js open data.csv --browser /usr/bin/google-chrome
```

> **注意**：浏览器名需在系统 PATH 中可被识别，否则请用完整路径。指定不存在/未安装的浏览器会报错，CLI 会输出 URL 让用户手动访问。

## 环境变量

| 变量 | 说明 | 默认值 |
| ---- | ---- | ---- |
| `ALGOBENCH_SERVER` | 默认服务地址 | `http://localhost:8000` |

## merge 命令详解

`merge` 把多个 CSV 合并成一个数据集，支持两种模式：

- **增加算法**（`--mode algorithm`，默认）：按 Case 外连接，每个文件的指标列加 `算法/` 前缀
- **增加 Case**（`--mode case`）：行堆叠，要求所有文件表头一致

### 合并模式

| 模式 | `--mode` 值 | 适用场景 | 合并方式 |
| ---- | ----------- | -------- | -------- |
| 增加算法 | `algorithm`（默认） | 昨天 vs 今天、V1 vs V2 vs V3 | 按 Case 外连接，指标列加 `算法/` 前缀 |
| 增加 Case | `case` | 合并同结构的多份测试数据 | 行堆叠，要求表头一致 |

### 列名识别规则

| 列类型 | 识别规则 | 合并行为 |
| ------ | -------- | -------- |
| Case 列 | 第一列 | 外连接主键（algorithm 模式）或要求一致（case 模式） |
| 参数列 | `p_` 前缀 | 共享，不加算法前缀、不重复（值冲突取第一个文件） |
| 元数据列 | `#` 前缀 | 共享，不加算法前缀、不重复 |
| 已含前缀指标 | `算法/指标` 格式 | 保留原列名 |
| 纯指标名 | 无 `/` | 加 `${algoName}/` 前缀（用 `--algos` 或文件名） |

### 与 open 的区别

| 命令 | 多文件行为 | 生成 dataset 数 |
| ---- | ---------- | --------------- |
| `open a.csv b.csv` | 每个文件一个独立 tab | 2 个（多 tab） |
| `merge a.csv b.csv` | 合并成一个对比 CSV | 1 个（含 `algo1/指标, algo2/指标` 列） |

`open` 适合「多个数据集并列查看」，`merge` 适合「多份独立数据需要做对比统计或合并行数」。

### 命令选项

| 选项 | 说明 | 默认值 |
| ---- | ---- | ---- |
| `--mode <algorithm\|case>` | 合并模式 | `algorithm` |
| `--algos <n1,n2,...>` | 每个文件对应的算法名，逗号分隔（仅 `algorithm` 模式） | 从文件名推断（去扩展名） |
| `--server <url>` | AlgoBench 服务地址 | `$ALGOBENCH_SERVER` 或 `http://localhost:8000` |
| `--name <name>` | 分享数据集在界面里显示的名称 | `<algo1> vs <algo2>` |
| `--output <file>` | 输出合并 CSV 到文件（不打开浏览器） | 不指定则打开浏览器 |
| `--browser <name>` | 指定浏览器名称或路径（见 [`--browser` 详解](#-browser-指定浏览器)） | 系统默认浏览器 |
| `--help`, `-h` | 显示 merge 命令帮助 | - |

> **算法名来源**：`--algos` 显式指定 > 文件名推断（去扩展名）。已含 `算法/指标` 前缀的文件无需算法名（`--algos` 可省略）。

### 完整示例

#### 场景 1：对比昨天和今天（algorithm 模式，2 文件，算法名从文件名推断）

`yesterday.csv`：

```csv
Case,HPWL,runtime
case01,1000,50
case02,1200,55
case03,1100,52
```

`today.csv`：

```csv
Case,HPWL,runtime
case01,950,48
case02,1180,52
case04,1300,60
```

运行（默认从文件名推断算法名 `yesterday` / `today`）：

```bash
node algobench-cli.js merge yesterday.csv today.csv
```

或显式指定算法名：

```bash
node algobench-cli.js merge yesterday.csv today.csv --algos 昨天,今天
```

合并后的 CSV（自动生成，用户看不到）：

```csv
Case,昨天/HPWL,昨天/runtime,今天/HPWL,今天/runtime
case01,1000,50,950,48
case02,1200,55,1180,52
case03,1100,52,,           ← today.csv 没有 case03，自动填空
case04,,,1300,60           ← yesterday.csv 没有 case04，自动填空
```

CLI 输出统计：

```
✓ 已合并 2 个文件: yesterday.csv + today.csv
  模式: 增加算法（Case 外连接 + 算法名前缀）
  算法: 昨天, 今天
  Case 列: Case
  行: 4
  列: 5 (Case + 0 共享 + 4 指标)
✓ 正在打开浏览器...
✓ 完成。如未自动打开，请访问: http://localhost:8000#share=...
```

浏览器加载后，前端自动识别 `昨天` 和 `今天` 两个算法，可直接进行改进率/置信区间/显著性检验。

#### 场景 2：3 个算法对比（algorithm 模式，3 文件 + `--algos`）

```bash
node algobench-cli.js merge v1.csv v2.csv v3.csv --algos V1,V2,V3
```

合并后表头：`Case,V1/HPWL,V2/HPWL,V3/HPWL,...`，前端识别 3 个算法。

#### 场景 3：合并同结构 CSV 增加 Case（`--mode case`）

`batch1.csv`：

```csv
Case,HPWL
case01,1000
case02,1100
```

`batch2.csv`：

```csv
Case,HPWL
case03,1300
case04,1400
```

运行：

```bash
node algobench-cli.js merge batch1.csv batch2.csv --mode case
```

合并后（行堆叠）：

```csv
Case,HPWL
case01,1000
case02,1100
case03,1300
case04,1400
```

适合「多份同结构测试数据合并增加用例数」的场景。要求所有文件表头完全一致。

#### 场景 4：输出合并 CSV 到文件（不打开浏览器，适合脚本/CI）

```bash
node algobench-cli.js merge a.csv b.csv --algos AlgoA,AlgoB --output merged.csv
# 合并后的 CSV 写入 merged.csv，不打开浏览器
```

#### 场景 5：已含「算法/指标」前缀的文件直接合并

```bash
node algobench-cli.js merge prefixed_a.csv prefixed_b.csv
# 列名已是 "AlgoA/HPWL" 格式，--algos 可省略
```

#### 指定浏览器打开（避免和已开的浏览器混淆）

```bash
# 用 Chrome 打开合并后的对比数据
node algobench-cli.js merge yesterday.csv today.csv --algos 昨天,今天 --browser chrome

# macOS：用 Safari 打开
node algobench-cli.js open data.csv --browser "Safari"
```

### 共享列（p_ / # 前缀）

algorithm 模式下，参数列（`p_` 前缀）和元数据列（`#` 前缀）被视为**共享列**：

- 不加算法前缀（保持原列名）
- 跨文件去重（同名列只出现一次）
- 值冲突时取第一个文件的值

示例：

```csv
# a.csv                       # b.csv
Case,p_level,#note,HPWL       Case,p_level,#note,HPWL
c1,fast,old,1000              c1,slow,new,950
```

合并后（`--algos A,B`）：

```csv
Case,p_level,#note,A/HPWL,B/HPWL
c1,fast,old,1000,950
```

`p_level` 和 `#note` 只出现一次，值取 a.csv 的（`fast` / `old`）。

### 智能去重（algorithm 模式）

当多个文件含相同的 `算法/指标` 前缀列时（如文件 A 和文件 B 都有 `AlgoX/HPWL`），合并会自动去重：

| 情况 | 行为 |
| ---- | ---- |
| 列名相同 + 值相同 | 静默合并为一个列 |
| 列名相同 + 值不同 | 取第一个文件的值，发出 `DUPLICATE_METRIC_VALUE_CONFLICT` 警告 |

`--algos` 指定的算法名与文件内已有的前缀同名时（如 `--algos AlgoX` 且文件含 `AlgoX/HPWL`），裸指标列加前缀后也会触发去重。

CLI 输出示例（去重时显示 `去重:` 统计行）：

```
✓ 已合并 2 个文件: a.csv + b.csv
  模式: 增加算法（Case 外连接 + 算法名前缀）
  算法: a, b
  Case 列: Case
  行: 3
  列: 3 (Case + 0 共享 + 2 指标)
  去重: 1 个重复指标列（值冲突 0 处）
```

### 注意事项

- **文件数至少 2 个**：少了会报错
- **第一列必须是 Case 列**（行标识符），不能是数值指标
- **每个 CSV 至少 2 列**（Case + 至少 1 个指标）
- **algorithm 模式下列名不要包含 `/`**：合并后会变成 `<算法>/<原列名>`，原列名含 `/` 会产生多层路径（如 `昨天/V1/HPWL`），前端可能解析异常
- **case 模式要求所有文件表头完全一致**：列名、列数、顺序都要相同
- **行数不一致用外连接**（algorithm 模式）：保留所有 Case，缺失填空，前端统计时会自动跳过空值

### 常见错误

| 错误信息 | 原因 | 解决 |
| -------- | ---- | ---- |
| `merge 命令需要至少 2 个 CSV 文件` | 文件数 < 2 | 检查命令行参数 |
| `--algos 数量 (X) 与文件数 (Y) 不一致` | 算法名数量不匹配 | 调整 `--algos` 或文件数 |
| `--mode 必须为 algorithm 或 case` | `--mode` 值非法 | 使用 `algorithm` 或 `case` |
| `CSV X 解析失败或为空` | 文件为空或格式错误 | 检查文件内容 |
| `CSV X 至少需要 2 列` | CSV 只有 1 列 | 确认有 Case + 指标列 |
| `表头与第一个文件不一致` | case 模式表头不一致 | 统一表头或改用 algorithm 模式 |
| `算法名重复` | `--algos` 中有重复名称 | 修改算法名 |
| `分享链接过长` | 数据量太大 | 用 `--output` 输出 CSV 文件 |
| `列 "X" 在多个文件中重复出现` | 跨文件含相同 `算法/指标` 列 | 已自动去重，值冲突取第一个文件 |
| `文件 X 同时含已前缀列和裸指标列` | 单文件 mixed 格式 | 裸列将用 `--algos` 算法名加前缀 |
| `Case 列名 "X" 含 "/"` | Case 列名含 `/`，可能被误识别为指标列 | 改为不含 `/` 的名称 |

## 典型工作流

### 内网部署 + CLI 打开

```bash
# 1. 启动 AlgoBench 服务（内网部署，见 DEPLOYMENT.md）
./start.sh start

# 2. 用 CLI 打开浏览器加载数据
node algobench-cli.js open data.csv

# 3. 多 CSV 合并对比（推荐）
node algobench-cli.js merge yesterday.csv today.csv
# → 算法名从文件名推断（yesterday / today）
# → 浏览器自动打开 http://localhost:8000#share=...
# → 前端识别两个算法，可直接做改进率/置信区间/显著性检验

# 3b. 显式指定算法名（3 个文件对比）
node algobench-cli.js merge v1.csv v2.csv v3.csv --algos V1,V2,V3

# 3c. 合并同结构 CSV 增加 Case 数量
node algobench-cli.js merge batch1.csv batch2.csv --mode case

# 4. 多文件独立查看（不合并，每个文件一个 tab）
node algobench-cli.js open 0627.csv 0628.csv --baseline 0627 --compare 0628
```

### 简写（最常用）

```bash
node algobench-cli.js data.csv          # 等价于 open data.csv
node algobench-cli.js merge y.csv t.csv # 2 文件合并（默认 algorithm 模式，算法名从文件名推断）
node algobench-cli.js merge b1.csv b2.csv --mode case  # 行堆叠增加 Case
```

### 生成分享链接（不打开浏览器）

```bash
# 输出到 stdout
node algobench-cli.js share data.csv

# 写入文件
node algobench-cli.js share data.csv --output url.txt

# 管道复制到剪贴板（macOS）
node algobench-cli.js share data.csv | pbcopy
```

### 指向在线 demo

```bash
node algobench-cli.js open data.csv --server https://duanxiangliu.github.io/AlgoBench-pages/
```

### 命令行分析（需要 Python）

```bash
# 完整分析（默认 table 输出）
node algobench-cli.js analyze data.csv --baseline V1 --compare V2

# JSON 输出便于程序处理
node algobench-cli.js analyze data.csv --baseline V1 --compare V2 --format json

# 单指标统计
node algobench-cli.js stats data.csv --metric HPWL --baseline V1 --compare V2
```

## 架构

```
用户
  ↓
node algobench-cli.js（单文件 bundle，含 pako）
  ├─ open/share        → JS 实现（复用 src/utils/shareCodec.js 编码逻辑）
  └─ analyze/stats/... → spawn('python', ['-m', 'algobench', ...])
                          ↓
                        Python SDK (algobench-sdk，作为库)
```

- **JS 命令**：复用前端 `shareCodec.js` 编码逻辑（pako/zlib + base64 + URL hash），保证 CLI 生成的链接能被前端 `useShareRestore` 还原。pako 已打包进单文件，无需额外依赖
- **Python 命令**：透传 `python -m algobench`，复用 numpy/scipy/pandas 科学计算生态
- **构建**：`npm run build:cli`（开发者发布前运行，生成 `pages/algobench-cli.js`）

## 故障排查

### `❌ 此命令需要 Python 环境`

`analyze`/`stats`/`quality`/`diagnose`/`validate` 需要 Python。安装：

```bash
pip install algobench-sdk
```

`open`/`share` 不需要 Python，可以独立使用。

### `❌ 无法打开浏览器`

手动访问 CLI 输出的 URL 即可。常见原因：
- Linux 无图形界面（用 `share` 命令获取 URL，本地浏览器打开）
- `xdg-open` 未配置默认浏览器（用 `--browser /path/to/browser` 指定可执行文件路径）
- 指定的浏览器名不在 PATH 中（用完整路径，如 `--browser /usr/bin/google-chrome`）

### `分享链接过长`

URL 超过 200000 字符限制。减少数据量后重试，或使用多个独立链接分享。

### `命令找不到` / `algobench: command not found`

未设别名时不能直接用 `algobench`，请用 `node algobench-cli.js ...`，或参考"安装"章节设别名。

## 相关文档

- [Python SDK 文档](./PYTHON_SDK.md)
- [部署指南](./DEPLOYMENT.md)
- [在线体验](https://duanxiangliu.github.io/AlgoBench-pages/)
