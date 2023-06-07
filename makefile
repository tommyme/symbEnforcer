SYMB_ENFORCER_DIR = $(shell ls ~/Library/Developer/Xcode/DerivedData | grep symbEnforcer)
.PHONY: install


install:
	test -n "${SYMB_ENFORCER_DIR}" || (echo "Error cannot find the symbEnforcer directory in DerivedData"; exit 1)
	sudo cp ~/Library/Developer/Xcode/DerivedData/${SYMB_ENFORCER_DIR}/Build/Products/Debug/symbEnforcer /usr/local/bin/