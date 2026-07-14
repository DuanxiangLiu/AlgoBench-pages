# AlgoBench Python SDK

AlgoBench 的 Python SDK，提供 Python 库接口和命令行工具，用于算法基准测试的统计分析和决策评估。

## 安装

```bash
pip install algobench-sdk
```

要求 Python >= 3.10。

## 命令行使用

Python SDK 作为库使用，通过 `python -m algobench` 调用各子命令：

```bash
# 完整分析（推荐）
python -m algobench analyze data.csv -b Baseline -c New -m HPWL,runtime

# 单指标统计
python -m algobench stats data.csv -b Baseline -c New -m HPWL

# 数据质量检查
python -m algobench quality data.csv

# 数据诊断
python -m algobench diagnose data.csv

# CSV 格式验证
python -m algobench validate data.csv
```

> **统一入口**：也可用 AlgoBench 单文件 CLI（`node algobench-cli.js <子命令>`）统一调用。
> `analyze` / `stats` / `quality` / `diagnose` / `validate` 会自动透传到 Python SDK；
> `open` / `share` 由 CLI 直接处理（复用前端编码逻辑，无需 Python）。详见 [CLI 文档](./CLI.md)。

### 分析标准

```bash
# 探索模式（灵敏度高）
python -m algobench analyze data.csv -b V1 -c V2 -m HPWL --criteria exploratory

# 严格模式（用于发布决策）
python -m algobench analyze data.csv -b V1 -c V2 -m HPWL --criteria strict

# JSON 输出（适合脚本/AI 调用）
python -m algobench analyze data.csv -b V1 -c V2 -m HPWL -f json
```

## Python 库使用

```python
from algobench import analyze

result = analyze("data.csv", baseline="V1", compare="V2", metrics=["HPWL"])

# 决策结果
print(result.decision.status)    # "yes" / "watch" / "no" / "insufficient"
print(result.decision.label)     # "建议上线" / "观察期" / "不建议上线" / "数据不足"
print(result.decision.reason)    # 决策原因

# 统计结果
stats = result.statistics["HPWL"]
print(stats.mean_imp)            # 平均改进率 (%)
print(stats.p_value)             # p 值
print(stats.effect_size.d)       # Cohen's d
print(stats.ci_lower, stats.ci_upper)  # 95% 置信区间

# 评估详情
print(result.evaluation.risk_level)       # "low" / "medium" / "high"
print(result.evaluation.confidence_level) # "low" / "medium" / "high"
```

### AI Agent 调用示例

```python
import subprocess
import json

def run_analysis(csv_path, baseline, compare, metrics):
    """AI Agent 通过 CLI 调用 AlgoBench 分析。"""
    cmd = [
        "python", "-m", "algobench", "analyze", csv_path,
        "-b", baseline,
        "-c", compare,
        "-m", ",".join(metrics),
        "-f", "json"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"分析失败: {result.stderr}")
    return json.loads(result.stdout)

# 使用
analysis = run_analysis("data.csv", "V1", "V2", ["HPWL", "runtime"])
print(analysis["decision"]["status"])
print(analysis["decision"]["label"])
```

## CSV 数据格式

```csv
Case,Baseline/HPWL,New/HPWL,Baseline/runtime,New/runtime
case1,1200,1100,50,45
case2,800,750,30,28
```

| 列类型 | 格式 | 示例 |
|--------|------|------|
| 用例列 | `Case`、`Benchmark`、`Test` 等 | `case1` |
| 指标列 | `算法名/指标名` | `V1/HPWL` |
| 元数据列 | `#` 前缀 | `#Size` |
| 参数列 | `p_` 前缀 | `p_mode` |

## 决策引擎

SDK 的核心价值在于完整的决策流水线：

1. **智能检验选择**：自动根据数据特征选择 t 检验 / Wilcoxon / 符号检验
2. **多指标 FDR 校正**：Benjamini-Hochberg 校正避免多重比较问题
3. **五维度评估**：显著性、效应量、置信区间、均值改进、退化率

## 许可证

AGPL-3.0-only
