# Contest 2026 team 485 mianyu - active sleep aid
#
# 核心层（src/*.c + include/*.h）是平台无关纯 C，只依赖 <math.h>/<string.h>/<stdint.h>。
# 上真机链接 hal/sf32lb52（RTC + LittleFS 存储）；PC 验证用仓库根 Makefile 的 make test。
if(CONFIG_LVX_USE_DEMO_CONTEST2026_485_MIANYU)

  set(MIANYU_SRCS
      mianyu_app_main.c
      src/mianyu_noise_gen.c
      src/mianyu_sleep_detect.c
      src/mianyu_fade.c
      src/mianyu_schedule.c
      src/mianyu_sleep_memory.c
      src/mianyu_breathe.c
      hal/sf32lb52/mianyu_hal_vela.c)

  # 图形能力落地：LVGL 呼吸光晕（依赖 CONFIG_LVGL 才编译）
  if(CONFIG_LVGL)
    list(APPEND MIANYU_SRCS ui/breathe_lvgl.c)
  endif()

  nuttx_add_application(
    NAME mianyu
    SRCS ${MIANYU_SRCS}
    INCLUDE_DIRECTORIES include hal
    STACKSIZE 24576)

endif()
