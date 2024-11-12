#!/bin/sh

# This script is intended to be used on SX1302 CoreCell platform. It performs
# the following actions:
#   - Resets the SX1302 chip and enables the LDOs
#   - Resets the optional SX1261 radio used for LBT/Spectral Scan
#
# Usage examples:
#   sudo ./reset_lgw.sh start
#   sudo ./reset_lgw.sh stop

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# GPIO mapping (adjust according to your hardware)
SX1302_RESET_PIN=23    # SX1302 reset (GPIO23)
SX1302_POWER_EN_PIN=18 # SX1302 power enable (GPIO18)
SX1261_RESET_PIN=22    # SX1261 reset (GPIO22)
AD5338R_RESET_PIN=13   # AD5338R reset (GPIO13)

WAIT_GPIO() {
    sleep 0.1
}

SET_GPIO_PIN() {
    PIN=$1
    VALUE=$2
    DURATION=$3  # in seconds (optional)

    if [ -z "$DURATION" ]; then
        # Set the GPIO pin and exit immediately
        gpioset --mode=exit gpiochip0 $PIN=$VALUE
    else
        # Set the GPIO pin for a specific duration
        USEC=$(awk "BEGIN {printf \"%d\", $DURATION * 1000000}")
        gpioset --mode=time --usec=$USEC gpiochip0 $PIN=$VALUE
    fi
}

reset() {
    echo "CoreCell reset through GPIO$SX1302_RESET_PIN..."
    echo "SX1261 reset through GPIO$SX1261_RESET_PIN..."
    echo "CoreCell power enable through GPIO$SX1302_POWER_EN_PIN..."
    echo "CoreCell ADC reset through GPIO$AD5338R_RESET_PIN..."

    # Power enable
    SET_GPIO_PIN $SX1302_POWER_EN_PIN 1; WAIT_GPIO

    # SX1302 reset sequence
    SET_GPIO_PIN $SX1302_RESET_PIN 1; WAIT_GPIO
    SET_GPIO_PIN $SX1302_RESET_PIN 0; WAIT_GPIO

    # SX1261 reset sequence
    SET_GPIO_PIN $SX1261_RESET_PIN 0; WAIT_GPIO
    SET_GPIO_PIN $SX1261_RESET_PIN 1; WAIT_GPIO

    # AD5338R reset sequence
    SET_GPIO_PIN $AD5338R_RESET_PIN 0; WAIT_GPIO
    SET_GPIO_PIN $AD5338R_RESET_PIN 1; WAIT_GPIO
}

case "$1" in
    start)
        reset
        ;;
    stop)
        reset
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0

