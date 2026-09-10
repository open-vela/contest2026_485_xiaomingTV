# 安眠科技 · 核心算法层 PC 端验证构建（无需任何硬件/RTOS/openvela）
#
# 核心层（app/mianyu/src + app/mianyu/include）是【平台无关纯 C】，只依赖
# <math.h>/<string.h>/<stdint.h>。因此可在任意 PC 上一键验证，也便于评审
# 「clone 专属仓 → make test」复现。openvela 编译走 app/mianyu/ 的 CMakeLists，
# 与本 Makefile 互不干扰（本 Makefile 只用于 PC 单元测试/演示）。
#
# 常用目标：
#   make test     编译并运行全部单元测试（评审看这个）
#   make app      编译并运行「真机主循环」PC 镜像（链接 hal/sim，跑整晚）
#   make demo     自包含单文件整晚演示
#   make clean    清理产物
#   make report   打印逐套件断言统计

CC      ?= cc
CSTD    ?= -std=c11
CFLAGS  ?= -O2 -Wall -Wextra -Wshadow -I$(INC_DIR) $(CSTD)
LDLIBS  ?= -lm

SRC_DIR  := app/mianyu/src
INC_DIR  := app/mianyu/include
HAL_DIR  := app/mianyu/hal
TEST_DIR := tests
BUILD    := build

# 核心算法模块（新增模块时在此登记，会自动被 test 目标拾取）
MODULES  := noise_gen sleep_detect fade schedule sleep_memory breathe

SRCS     := $(addprefix $(SRC_DIR)/mianyu_,$(addsuffix .c,$(MODULES)))
TESTS    := $(addprefix $(BUILD)/test_,$(MODULES))

.PHONY: all test demo app clean report
all: test

# ---- 自包含单文件整晚演示 ----
$(BUILD)/night_demo: demo/night_demo.c $(SRCS) | $(BUILD)
	@$(CC) $(CFLAGS) -o $@ demo/night_demo.c $(SRCS) $(LDLIBS)

demo: $(BUILD)/night_demo
	@echo "=================================================="
	@echo " 安眠科技 · 整晚闭环演示"
	@echo "=================================================="
	@$(BUILD)/night_demo

# ---- HAL 接入版「真机主循环」（PC 模拟器） ----
# app/mianyu/mianyu_app_main.c 是真正的真机主循环，时间/MIC/音频/存储全走
# hal/mianyu_hal.h；此处链接 hal/sim 后端在 PC 上跑。上真机换 hal/sf32lb52。
APP_CFLAGS := $(CFLAGS) -I$(HAL_DIR)
APP_SRCS   := $(SRCS) app/mianyu/mianyu_app_main.c $(HAL_DIR)/sim/mianyu_hal_sim.c

$(BUILD)/mianyu_app: $(APP_SRCS) | $(BUILD)
	@$(CC) $(APP_CFLAGS) -o $@ $(APP_SRCS) $(LDLIBS)

app: $(BUILD)/mianyu_app
	@echo "=================================================="
	@echo " 安眠科技 · 真机主循环（HAL 接入版，PC 模拟器）"
	@echo "=================================================="
	@$(BUILD)/mianyu_app

# 每个测试可执行文件 = 对应测试源 + 对应模块源（一对一，互不依赖）
$(BUILD)/test_%: $(TEST_DIR)/test_%.c $(SRC_DIR)/mianyu_%.c | $(BUILD)
	@$(CC) $(CFLAGS) -o $@ $< $(SRC_DIR)/mianyu_$*.c $(LDLIBS)

$(BUILD):
	@mkdir -p $(BUILD)

# 跑全部测试：任一失败则整体非零退出（CI 可直接用）。
# 每个测试包一层【不依赖 timeout 命令】的超时保护（shell 后台进程 + kill）。
# 判据口径：只认程序打印的权威行 `MY_RESULT: pass=N fail=M`。
TIMEOUT_S := 30
SHELL     := /bin/sh

test: $(TESTS)
	@echo "=================================================="
	@echo " 安眠科技 · 核心算法层单元测试"
	@echo "=================================================="
	@pass=0; fail=0; lim=$$(( $(TIMEOUT_S) * 10 )); \
	for t in $(MODULES); do \
	  echo ""; echo ">>> $$t"; \
	  $(BUILD)/test_$$t > $(BUILD)/$$t.log 2>&1 & \
	  tpid=$$!; i=0; \
	  while kill -0 $$tpid 2>/dev/null; do \
	    if [ $$i -ge $$lim ]; then kill -9 $$tpid 2>/dev/null; echo "__TIMEOUT__" >> $(BUILD)/$$t.log; break; fi; \
	    sleep 0.1; i=$$((i+1)); \
	  done; \
	  wait $$tpid 2>/dev/null; \
	  if grep -q __TIMEOUT__ $(BUILD)/$$t.log 2>/dev/null; then \
	    echo "    TIMEOUT — 超过 $(TIMEOUT_S)s，疑似死循环；日志：$(BUILD)/$$t.log"; \
	    fail=$$((fail+1)); \
	  elif grep -qE '^MY_RESULT: pass=[0-9]+ fail=0$$' $(BUILD)/$$t.log; then \
	    grep -E '^MY_RESULT: ' $(BUILD)/$$t.log | tail -n 1 | sed 's/^/    /'; \
	    pass=$$((pass+1)); \
	  elif grep -qE '^MY_RESULT: ' $(BUILD)/$$t.log; then \
	    echo "    FAILED — 完整日志：$(BUILD)/$$t.log"; \
	    grep -E '^MY_RESULT: ' $(BUILD)/$$t.log | tail -n 1 | sed 's/^/    /'; \
	    grep -E '\[FAIL\]' $(BUILD)/$$t.log | head -n 20 | sed 's/^/    /'; \
	    fail=$$((fail+1)); \
	  else \
	    echo "    NO_RESULT — 未打印 MY_RESULT 行；日志：$(BUILD)/$$t.log"; \
	    tail -n 10 $(BUILD)/$$t.log | sed 's/^/    /'; \
	    fail=$$((fail+1)); \
	  fi; \
	done; \
	echo ""; echo "=================================================="; \
	echo " 套件： $$pass 通过 / $$fail 失败"; \
	echo "=================================================="; \
	test $$fail -eq 0

# 打印各套件断言统计（从 MY_RESULT 权威行取值）
report: test
	@echo ""
	@echo "断言统计（逐套件，取自各程序的 MY_RESULT 权威行）："
	@total_p=0; total_f=0; \
	for t in $(MODULES); do \
	  line=$$(grep -E '^MY_RESULT: ' $(BUILD)/$$t.log | tail -n 1); \
	  p=$$(echo "$$line" | sed -n 's/^MY_RESULT: pass=\([0-9]*\) fail=.*/\1/p'); \
	  f=$$(echo "$$line" | sed -n 's/^MY_RESULT: pass=[0-9]* fail=\([0-9]*\)/\1/p'); \
	  p=$${p:-0}; f=$${f:-0}; \
	  printf "  %-14s %3d PASS / %3d FAIL\n" $$t $$p $$f; \
	  total_p=$$((total_p+p)); total_f=$$((total_f+f)); \
	done; \
	echo "  ------------------------------"; \
	printf "  %-14s %3d PASS / %3d FAIL\n" "合计" $$total_p $$total_f

clean:
	@rm -rf $(BUILD)
	@echo "已清理 $(BUILD)/"
