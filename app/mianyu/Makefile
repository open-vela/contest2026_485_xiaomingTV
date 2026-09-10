############################################################################
# Contest 2026 team 485 mianyu - Makefile（传统 NuttX make 路径，openvela 主用 CMake）
############################################################################

include $(APPDIR)/Make.defs

PROGNAME  = mianyu
PRIORITY  = SCHED_PRIORITY_DEFAULT
STACKSIZE = 24576
MODULE    = $(CONFIG_LVX_USE_DEMO_CONTEST2026_485_MIANYU)

MAINSRC = mianyu_app_main.c
CSRCS   = src/mianyu_noise_gen.c src/mianyu_sleep_detect.c src/mianyu_fade.c \
          src/mianyu_schedule.c src/mianyu_sleep_memory.c src/mianyu_breathe.c \
          hal/sf32lb52/mianyu_hal_vela.c

ifeq ($(CONFIG_LVGL),y)
CSRCS += ui/breathe_lvgl.c
endif

include $(APPDIR)/Application.mk
