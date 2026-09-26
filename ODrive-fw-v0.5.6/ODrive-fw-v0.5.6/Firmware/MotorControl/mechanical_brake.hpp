#ifndef __MECHANICAL_BRAKE_HPP
#define __MECHANICAL_BRAKE_HPP

#include <autogen/interfaces.hpp>

class MechanicalBrake : public ODriveIntf::MechanicalBrakeIntf  {
   public:
    struct Config_t {
        uint16_t gpio_num = 0;
        bool is_active_low = true;
        // docs/specs/xdrive_can.md §7: the phase-shorting relays must be open before PWM
        // starts, and PWM must be off before they close.
        uint32_t release_delay_ms = 30;  // release -> PWM on; clamped to 20..100
        uint32_t engage_delay_ms = 20;   // disarm -> engage; above 30 is treated as 30

        // custom setters
        MechanicalBrake* parent = nullptr;
        // Engage on the old pin first: otherwise it stays released until reboot.
        void set_gpio_num(uint16_t value) { if (parent) parent->engage(); gpio_num = value; }
    };

    static constexpr uint32_t kMinReleaseDelayMs = 20;
    static constexpr uint32_t kMaxReleaseDelayMs = 100;
    static constexpr uint32_t kMaxEngageDelayMs = 30;

    MechanicalBrake() {}

    MechanicalBrake::Config_t config_;
    Axis* axis_ = nullptr;
    bool released_ = false;  // reported in the CAN heartbeat (motor flags, bit 1)

    bool is_enabled() const;
    void release();
    void engage();              // disarms the motor first; thread context only
    void engage_immediately();  // no disarm, no wait: only after all motors were disarmed
    bool release_and_wait();    // true if a brake is configured (and the delay was waited)

   private:
    uint32_t release_delay_ms() const;
    uint32_t engage_delay_ms() const;
    void write(bool released);
};
#endif // __MECHANICAL_BRAKE_HPP