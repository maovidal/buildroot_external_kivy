PYTHON_ADCDACPI_VERSION = master
PYTHON_ADCDACPI_SITE = $(call github,abelectronicsuk,ABElectronics_Python_Libraries,$(PYTHON_ADCDACPI_VERSION))

define PYTHON_ADCDACPI_BUILD_CMDS
    mkdir -p $(TARGET_DIR)/kivyapp
    cp $(BUILD_DIR)/python-adcdacpi-master/ADCDACPi/ADCDACPi.py $(TARGET_DIR)/kivyapp/ADCDACPi.py
endef

$(eval $(generic-package))