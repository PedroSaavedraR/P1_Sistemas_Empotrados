CC      = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy

CFLAGS  = -mcpu=cortex-m0plus -mthumb -O0 -g -Iincludes -Ihello_world -Iled_blinky
LDFLAGS = -T link.ld -nostartfiles

COMMON_SRCS = startup.c

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
