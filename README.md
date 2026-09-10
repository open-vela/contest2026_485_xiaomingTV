# 安眠科技 · 主动式哄睡智能体

> 2026 首届 openvela AI 硬件开发者大赛 · 队伍 `xiaomingTV`（编号 485）
> 赛道：AI 硬件产品创新 ｜ 目标硬件：思澈 SF32LB52-DevKit-LCD

## 一、作品简介

**一台不用你开口、到点主动哄你睡的 AI 硬件。** 普通音箱你问才答，它在 22:30 自己
开口引导、在你入睡时自己安静——这是 openvela ai_agent「主动任务」能力的完整落地。

| 场景 | 它做什么 | 主动类型 |
|---|---|---|
| 22:30 睡前 | cron 到点自动播棕噪 + 呼吸引导灯（4-7-8） | 定时主动 |
| 躺下后 | MIC 呼吸节律检测，判定入睡潜伏期 | 阈值主动 |
| 入睡瞬间 | 声音/灯光 20s 平滑淡出到零，零播报 | 事件主动 |
| 半夜醒来 | 极低音量安抚 + 微光，不亮屏不追问 | 事件主动 |
| 清晨 | 晨光渐亮 + 昨晚回顾（≤3 条） | 定时主动 |

核心差异：**主动式**。产品解决三个结构性缺陷——手机助眠要「找手机→解锁→点屏」（蓝光
抑制褪黑素）、全靠用户主动发起（入睡困难人群最缺主动发起的意愿）、播完即止（感知不到
入睡/夜醒）。

技术亮点：无 DSP 的时域入睡判定（100ms 帧 RMS 包络 + 30s 窗归一化自相关 + 迟滞状态机）、
无 IMU 的纯 MIC 夜醒检测（呼吸节律塌缩）、端侧实时合成白/粉/棕噪（Flash 占用 0KB）、
dB 域线性淡出（感知匀速 + 精确归零）、180 天睡眠记忆 + best_aid 偏好学习。

> 合规：本作品是睡前放松陪伴，**非医疗器械**，不提供睡眠障碍诊断/治疗建议。音频全部
> 算法生成/CC0，无版权风险。

## 二、选题方向

**AI 硬件产品创新**（主）：基于 openvela + ai_agent 的床头主动式哄睡硬件，落地
**图形**（LVGL 呼吸节律 UI）、**AI**（ai_agent 主动任务 + 3 个自定义 Skill）、
**多媒体**（端侧噪声合成）三项核心能力。

**新硬件平台适配**（拟补勾）：在思澈 SF32LB52 上启用 ai_agent、打通音频录放链路，
以 PR 提交板级配置到 `vendor_sifli`。

## 三、目录结构

| 路径 | 作用 |
|---|---|
| `app/mianyu/` | openvela 应用（真机主循环 + 平台无关核心层 + HAL 双后端 + 构建文件），经 manifest `<linkfile>` 软链进编译树 |
| `skills/` | 3 个哄睡 Skill（sleep-onset / night-wake / sleep-review），运行时 push 到 `/data/agent/skills/` |
| `tests/` | 六模块单元测试（465 断言，PC 直接跑） |
| `demo/night_demo.c` | 自包含单文件整晚演示 |
| `docs/` | 测试记录表、系统框图与数据流图、真机首启检查清单 |
| `Makefile` | PC 端一键验证入口（make test / app / demo / report） |
| `logs/` | AI Coding 日志（JSONL） |
| `contest2026_485_xiaomingTV.xml` | 本仓 manifest（含 `<linkfile>` 映射） |

## 四、运行方式

### PC 一键自证（评审 clone 后无需搭 openvela 环境）

核心层是**平台无关纯 C**，只依赖 `math/string/stdint`，在普通电脑上即可复现：

```bash
cd contest2026_485_xiaomingTV
make test    # 六模块 465 项单元测试全绿
make app     # HAL 接入版真机主循环：22:30 哄睡 → 入睡淡出 → 夜醒安抚 → 晨唤简报
make demo    # 自包含单文件整晚演示
make report  # 逐模块断言统计
```

`make app` 输出关键时间线（无任何用户指令，全由 cron + 传感器事件驱动）：

```
[22:05:00] 设备就绪，等待睡前时刻
[22:30:00] ★ 睡前流程启动：棕噪 70% + 呼吸引导灯
[22:30:33] 入睡（潜伏 34 秒）→ 20s 淡出 + 灯灭
[01:30:25] ★ 夜醒安抚：极低音量棕噪 20% + 微光
[07:00:00] ★ 晨唤：一晚记录落盘 + 简报（夜醒 1 次 · 最快手段棕噪）
```

### openvela 编译 + 真机（完整步骤见 `docs/真机首启检查清单.md`）

```bash
repo init -u https://github.com/open-vela/contest2026_485_xiaomingTV \
  -b dev-ai-contest-2026 -m contest2026_485_xiaomingTV.xml
repo sync -c -j8
# 进入 openvela 工作区根目录（本仓的上一级）
./build.sh <board-config-path> --cmake menuconfig
#   → 启用 LVX_USE_DEMO_CONTEST2026_485_MIANYU + AI Agent + LVGL
./build.sh <board-config-path> --cmake -j4
# 烧录到 SF32LB52-DevKit-LCD → 串口验证三项：音频录放 / MIC 实采 / AMOLED 暗光
```

## 五、AI Coding 使用说明

本作品全程 AI 辅助开发：需求拆解、方案设计（入睡判定算法选型、端/云职责划分）、编码、
测试（465 断言由单测驱动）、文档（技术报告/README）各环节均与 AI 协作。AI 对效率的提升
体现在：测试先行逼出 4 个产品级 bug（跨午夜晚睡漏检、音量淡出反弹、cron 月份死循环、
大栈溢出隐患），均有回归测试锁定。完整对话日志见 `logs/`。
