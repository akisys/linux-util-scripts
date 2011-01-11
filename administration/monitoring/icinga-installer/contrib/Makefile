

SUBDIRS =\
		 check_hddtemp

.PHONY: all clean distclean
all clean distclean: $(SUBDIRS)

all: TARGET=all
clean: TARGET=clean
distclean: TARGET=distclean


$(SUBDIRS): force
	@ $(MAKE) -s -C $@ $(TARGET)

.PHONY: force
force :
	@mkdir -p build


