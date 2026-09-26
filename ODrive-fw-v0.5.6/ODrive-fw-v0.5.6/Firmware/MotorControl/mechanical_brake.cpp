#include <odrive_main.h>

// docs/specs/xdrive_can.md §7. The brake is a pair of NC relays shorting the motor phases:
// closing them on a switching bridge shorts the phases through the FETs. So the relays only
// close after the motor is disarmed, and only open before PWM starts.

bool MechanicalBrake::is_enabled() const {
    return config_.gpio_num < GPIO_COUNT
        && odrv.config_.gpio_modes[config_.gpio_num] == ODriveIntf::GPIO_MODE_MECH_BRAKE;
}

// osDelay(n) waits n-1..n ms on the 1 kHz tick: the +1 makes the configured delay a minimum.
uint32_t MechanicalBrake::release_delay_ms() const {
    return std::clamp(config_.release_delay_ms, kMinReleaseDelayMs, kMaxReleaseDelayMs) + 1;
}

uint32_t MechanicalBrake::engage_delay_ms() const {
    return std::min(config_.engage_delay_ms, kMaxEngageDelayMs) + 1;
}

void MechanicalBrake::write(bool released) {
    get_gpio(config_.gpio_num).write(released == config_.is_active_low);
    released_ = released;
}

// Thread context only (axis state machine, fibre): disarms first and waits, so the relays
// never close on a switching bridge, whoever asks for the brake.
void MechanicalBrake::engage() {
    if (!is_enabled()) {
        return;
    }
    if (axis_) {
        axis_->motor_.disarm();
    }
    if (released_) {
        osDelay(engage_delay_ms());
    }
    write(false);
}

// Only for contexts that cannot block (stack overflow hook), after the caller has disarmed
// every motor: PWM is already off, the relays may close right away.
void MechanicalBrake::engage_immediately() {
    if (is_enabled()) {
        write(false);
    }
}

// Opening the relays never shorts anything, so this is allowed from fibre too (bench test of
// the relays with the motor idle). The next idle entry or engage() closes them again.
void MechanicalBrake::release() {
    if (is_enabled()) {
        write(true);
    }
}

// Called from the axis thread only (Motor::arm callers), so blocking here is fine.
bool MechanicalBrake::release_and_wait() {
    if (!is_enabled()) {
        return false;
    }
    release();
    osDelay(release_delay_ms());
    return true;
}
