.PHONY: test install uninstall clean

INSTALL_DIR ?= $(HOME)/.local/bin
INSTALL_DATA_DIR ?= $(HOME)/.local/share/wp-demo

test:
	@for t in tests/test-*.sh; do echo "--- $$t ---"; bash "$$t"; done

install:
	@mkdir -p $(INSTALL_DIR)
	@mkdir -p $(INSTALL_DATA_DIR)/bin/spell
	@mkdir -p $(INSTALL_DATA_DIR)/lib
	@# Install main bin scripts
	@cp bin/wp bin/wp-search bin/wp-stats bin/wp-undo $(INSTALL_DIR)/
	@# Install spell scripts
	@cp bin/spell/wp-spell $(INSTALL_DATA_DIR)/bin/spell/
	@cp bin/spell/wp-spell-words $(INSTALL_DATA_DIR)/bin/spell/
	@cp bin/spell/wp-spell-lower $(INSTALL_DATA_DIR)/bin/spell/
	@cp bin/spell/wp-spell-unique $(INSTALL_DATA_DIR)/bin/spell/
	@cp bin/spell/wp-spell-mismatch $(INSTALL_DATA_DIR)/bin/spell/
	@# Install lib files
	@cp lib/dictionary.txt $(INSTALL_DATA_DIR)/lib/
	@cp lib/stopwords.txt $(INSTALL_DATA_DIR)/lib/
	@cp lib/wp-common.sh $(INSTALL_DATA_DIR)/lib/
	@# Create wrapper script for wp-spell in INSTALL_DIR
	@printf '#!/usr/bin/env bash\nexec "$$(dirname "$$0")/../share/wp-demo/bin/spell/wp-spell" "$$@"\n' > $(INSTALL_DIR)/wp-spell
	@chmod +x $(INSTALL_DIR)/wp-spell
	@echo "Installed to $(INSTALL_DIR) with data in $(INSTALL_DATA_DIR)"

uninstall:
	@rm -f $(INSTALL_DIR)/wp $(INSTALL_DIR)/wp-search $(INSTALL_DIR)/wp-stats $(INSTALL_DIR)/wp-undo
	@rm -f $(INSTALL_DIR)/wp-spell
	@rm -rf $(INSTALL_DATA_DIR)
	@echo "Uninstalled"

clean:
	@rm -rf session/
