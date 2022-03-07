PYTHON_PWM_VERSION = master
PYTHON_PWM_SITE = $(call github,scottellis,pwmpy,$(PYTHON_PWM_VERSION))

define PYTHON_PWM_BUILD_CMDS
    mkdir -p $(TARGET_DIR)/kivyapp
    cp $(BUILD_DIR)/python-pwm-master/pwm.py $(TARGET_DIR)/kivyapp/pwm.py
endef

$(eval $(generic-package))
