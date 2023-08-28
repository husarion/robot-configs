#!/usr/bin/python3
import sh
import time
from periphery import GPIO

def exit_bootloader_mode(boot0_pin_number, reset_pin_number):
    boot0_pin = GPIO(boot0_pin_number, "out")
    reset_pin = GPIO(reset_pin_number, "out")
    boot0_pin.write(False)
    reset_pin.write(True)
    time.sleep(0.2)
    reset_pin.write(False)
    time.sleep(0.2)


def main():
    sys_arch = sh.uname('-m')
    print(f"System architecture: {sys_arch}")

    boot0_pin_number = None
    reset_pin_number = None

    if sys_arch.stdout == b'armv7l\n':
        # Setups ThinkerBoard pins
        print("Device: ThinkerBoard\n")
        boot0_pin_number = 164
        reset_pin_number = 184

    elif sys_arch.stdout == b'x86_64\n':
        # Setups UpBoard pins
        print("Device: UpBoard\n")
        boot0_pin_number = 17
        reset_pin_number = 18

    elif sys_arch.stdout == b'aarch64\n':
        # Setups RPi pins
        print("Device: RPi\n")
        boot0_pin_number = 17
        reset_pin_number = 18

    else:
        raise Exception("Unknown device...")

    exit_bootloader_mode(boot0_pin_number, reset_pin_number)


if __name__ == "__main__":
    main()