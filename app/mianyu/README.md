# app/mianyu — openvela 应用（主动式哄睡智能体）

「安眠科技 · 主动式哄睡智能体」的 openvela 应用目录。通过 manifest 的 `<linkfile>`
软链到 `packages/demos/contest2026_485_mianyu` 进入编译树，用 `nuttx_add_application`
编成 NuttX 应用。

## 目录

| 路径 | 作用 |
|---|---|
| `mianyu_app_main.c` | 应用入口 = 真机主循环（时间→cron、MIC→入睡判定、事件→淡出/灯光、记忆→落盘），零 SDK 依赖，全走 `hal/mianyu_hal.h` |
| `src/` + `include/` | 平台无关核心层（7 模块），只依赖 math/string/stdint |
| `hal/sf32lb52/` | 真机 HAL 后端（RTC + LittleFS 二进制存储；音频/MIC/LVGL 为 `[TODO 接 SDK]` 接入点） |
| `hal/sim/` | PC 模拟后端（`make app` 在 PC 跑整晚，不进 openvela 编译） |
| `ui/breathe_lvgl.c` | LVGL 呼吸光晕渲染层（CONFIG_LVGL 时编译） |
| `Kconfig` / `CMakeLists.txt` / `Make.defs` / `Makefile` | openvela 构建 |

## 两条验证路径

- **PC 一键自证**（评审 clone 后不用搭 openvela 环境）：仓库根 `make test`（465 断言）、`make app`（整晚闭环）、`make demo`。
- **真机/模拟器**：`repo init` 拉 openvela 工程 → menuconfig 启用 `LVX_USE_DEMO_CONTEST2026_485_MIANYU` + AI Agent + LVGL → `build.sh --cmake` 编译 → 烧录。

详见仓库根 README 与 `docs/真机首启检查清单.md`。
