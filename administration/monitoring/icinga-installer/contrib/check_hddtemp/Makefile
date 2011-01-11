

BUILD=../build

DEPLOY_SRC=deploy.sh
DEPLOY_BIN=deploy

TARAGET_BIN=check_hddtemp.sh


SUMCMD=/usr/bin/sum payload

.PHONY: all

prepare-payload:
	@gzip -c check_hddtemp.sh > payload

prepare-installer: prepare-payload
	@sed "s/\[\[SCRIPT_LINES\]\]/$(shell grep -n "END_OF_SCRIPT" $(DEPLOY_SRC) | cut -d: -f1)/g" $(DEPLOY_SRC)>$(DEPLOY_BIN)
	@sed -i "s/\[\[FIRST_SUM\]\]/$(word 1,$(shell $(SUMCMD)))/g" $(DEPLOY_BIN)
	@sed -i "s/\[\[SECOND_SUM\]\]/$(word 2,$(shell $(SUMCMD)))/g" $(DEPLOY_BIN)
	@sed -i "s/\[\[TARGET_FILE\]\]/$(TARGET_BIN)/g" $(DEPLOY_BIN)

all: prepare-installer
	@echo -n "Building check_hddtemp.sh installer ... "
	@mkdir -p $(BUILD)
	@cat payload >> deploy
	@chmod +x deploy
	@mv deploy $(BUILD)/deploy-check_hddtemp
	@echo "OK"

clean:
	rm -f deploy
	rm -f payload

distclean: clean
	rm -f $(BUILD)/deploy-check_hddtemp
	rmdir --ignore-fail-on-non-empty $(BUILD)

