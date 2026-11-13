CC      = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy

SDK_DIR ?= $(HOME)/frdm-kl46z-sdk

CFLAGS  = -mcpu=cortex-m0plus -mthumb -O0 -g -DCPU_MKL46Z256VLL4 \
          -Iincludes -Ihello_world -Iled_blinky \
          -I$(SDK_DIR)/devices/MKL46Z4 \
          -I$(SDK_DIR)/devices/MKL46Z4/drivers \
          -I$(SDK_DIR)/devices/MKL46Z4/utilities \
          -I$(SDK_DIR)/devices/MKL46Z4/utilities/io \
          -I$(SDK_DIR)/devices/MKL46Z4/utilities/log \
          -I$(SDK_DIR)/devices/MKL46Z4/utilities/str \
          -I$(SDK_DIR)/boards/frdmkl46z
LDFLAGS = -T link.ld -nostartfiles -specs=nosys.specs

SDK_SRCS = $(SDK_DIR)/devices/MKL46Z4/system_MKL46Z4.c \
           $(SDK_DIR)/devices/MKL46Z4/drivers/fsl_common.c \
           $(SDK_DIR)/devices/MKL46Z4/drivers/fsl_clock.c \
           $(SDK_DIR)/devices/MKL46Z4/drivers/fsl_gpio.c \
           $(SDK_DIR)/devices/MKL46Z4/drivers/fsl_lpsci.c \
           $(SDK_DIR)/devices/MKL46Z4/drivers/fsl_smc.c \
           $(SDK_DIR)/devices/MKL46Z4/drivers/fsl_uart.c \
           $(SDK_DIR)/devices/MKL46Z4/drivers/fsl_ftfx_cache.c \
           $(SDK_DIR)/devices/MKL46Z4/utilities/fsl_debug_console.c \
           $(SDK_DIR)/devices/MKL46Z4/utilities/io/fsl_io.c \
           $(SDK_DIR)/devices/MKL46Z4/utilities/log/fsl_log.c \
           $(SDK_DIR)/devices/MKL46Z4/utilities/str/fsl_str.c

COMMON_SRCS = startup.c $(SDK_SRCS)

LED_SRCS = led_blinky/led_blinky.c \
           led_blinky/board.c \
           led_blinky/clock_config.c \
           led_blinky/pin_mux.c \
           $(COMMON_SRCS)

HELLO_SRCS = hello_world/hello_world.c \
             hello_world/board.c \
             hello_world/clock_config.c \
             hello_world/pin_mux.c \
             $(COMMON_SRCS)

.PHONY: all clean flash_led flash_hello

all: led_blinky.bin hello_world.bin

led_blinky.elf: $(LED_SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

led_blinky.bin: led_blinky.elf
	$(OBJCOPY) -O binary $< $@

hello_world.elf: $(HELLO_SRCS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

hello_world.bin: hello_world.elf
	$(OBJCOPY) -O binary $< $@

flash_led: led_blinky.bin
	openocd -f openocd.cfg -c "program led_blinky.elf verify reset exit"

flash_hello: hello_world.bin
	openocd -f openocd.cfg -c "program hello_world.elf verify reset exit"

clean:
	rm -f *.elf *.bin *.o
