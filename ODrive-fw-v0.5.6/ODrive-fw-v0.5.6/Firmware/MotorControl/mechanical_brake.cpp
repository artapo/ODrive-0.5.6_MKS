#include <odrive_main.h>

bool MechanicalBrake::is_enabled() const {
    return odrv.config_.gpio_modes[config_.gpio_num] == ODriveIntf::GPIO_MODE_MECH_BRAKE;
}

void MechanicalBrake::engage() {
    if (is_enabled()) {
        get_gpio(config_.gpio_num).write(config_.is_active_low ? 0 : 1);
        released_ = false;
    }
}

void MechanicalBrake::release() {
    if (is_enabled()) {
        get_gpio(config_.gpio_num).write(config_.is_active_low ? 1 : 0);
        released_ = true;
    }
}

// Called from the axis thread only (Motor::arm callers), so blocking here is fine.
bool MechanicalBrake::release_and_wait() {
    if (!is_enabled()) {
        return false;
    }
    release();
    osDelay(std::max(config_.release_delay_ms, kMinReleaseDelayMs));
    return true;
}

// Called from the axis thread on entering idle; the motor is already disarmed.
void MechanicalBrake::wait_and_engage() {
    if (released_) {
        osDelay(std::min(config_.engage_delay_ms, kMaxEngageDelayMs));
    }
    engage();
}
