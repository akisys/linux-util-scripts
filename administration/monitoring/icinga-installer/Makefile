SCRIPT_FILE=setup.sh
SCRIPT_SRC=setup.in

EXTRACTOR_FILE=decomp.sh
EXTRACTOR_SRC=decomp.in

DATA_FILE=deploy.tgz
DATA_FOLDERS=configs\
			scripts\
			binaries
INSTALLER_PAYLOAD= payload.tgz
INSTALLER_FILE= icinga_setup.bin

SUMCMD=/usr/bin/sum $(PWD)/$(INSTALLER_PAYLOAD)

.PHONY: clean clean-up pack-archive

all: build-installer clean-up
	 
build-installer: init
	@echo -n "Building installer ... "
	@cat $(EXTRACTOR_FILE) $(INSTALLER_PAYLOAD) > $(INSTALLER_FILE)
	@chmod 755 $(INSTALLER_FILE)
	@echo "Done!"

init: prepare-installer; @echo -n "Preparing requirements ... "
	@echo "Done!"

prepare-installer: prepare-payload
	@sed "s/\[\[SCRIPT_LINES\]\]/$(shell grep -n "END_OF_SCRIPT" $(EXTRACTOR_SRC) | cut -d: -f1)/g" $(EXTRACTOR_SRC)>$(EXTRACTOR_FILE)
	@sed -i "s/\[\[FIRST_SUM\]\]/$(word 1,$(shell $(SUMCMD)))/g" $(EXTRACTOR_FILE)
	@sed -i "s/\[\[SECOND_SUM\]\]/$(word 2,$(shell $(SUMCMD)))/g" $(EXTRACTOR_FILE)

prepare-payload: prepare-setup
	@tar czvf $(PWD)/$(INSTALLER_PAYLOAD) $(SCRIPT_FILE) $(DATA_FILE)

prepare-setup: prepare-data
	@sed "s/\[\[DEPLOYMENT\]\]/$(DATA_FILE)/g" $(SCRIPT_SRC)>$(SCRIPT_FILE)
	@chmod +x $(SCRIPT_FILE)

prepare-data:
	@tar czvf $(PWD)/$(DATA_FILE) $(DATA_FOLDERS)

distclean: clean clean-up

clean:
	@rm -f $(INSTALLER_FILE)

clean-up:
	@echo -n "Cleaning up ... "
	@rm -f $(SCRIPT_FILE)
	@rm -f $(DATA_FILE)
	@rm -f $(INSTALLER_PAYLOAD)
	@rm -f $(EXTRACTOR_FILE)
	@echo "Done!"
