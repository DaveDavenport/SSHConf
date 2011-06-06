##
# build:
# 	make
#
# Install to custom location.
# 	type: PREFIX=/usr/local/ make install
#
# Uninstall:
#   type:  PREFIX=/usr/local/ make uninstall
##


EMPTY=

SOURCE=sshconf.vala sshconf-editor.vala sshconf-entry.vala sshconf-entry-model.vala
ifeq ($(PREFIX),$(EMPTY))
PREFIX=~/.local/
endif
PROGRAM=sshconf
VALAC=valac

##
# Check dependency
##

HAS_GTK3=$(shell pkg-config --modversion gtk+-3.0)
ifeq ($(HAS_GTK3), $(EMPTY))
    $(error gtk3 not found)
else
    $(info Found gtk+-3.0:  $(HAS_GTK3))
endif

HAS_GEE=$(shell pkg-config --modversion gee-1.0)
ifeq ($(HAS_GEE), $(EMPTY))
    $(error libgee not found)
else
    $(info Found gee:       $(HAS_GEE))
endif


##
# Build program
##
$(PROGRAM): $(SOURCE) | Makefile
	$(info == Build $@)
	@$(VALAC) -g --pkg=gtk+-3.0 --pkg=gee-1.0 $^

##
# install
##
install: $(PROGRAM)
	$(info == Install to $(PREFIX))
	@install $^ $(PREFIX)/bin/$^

##
# clean
##
clean:
	$(info == Clean)
	@rm -f $(PROGRAM) *.c

##
# uninstall
##
uninstall: $(PROGRAM)
	$(info == Uninstall from $(PREFIX))
	@rm -f $(PREFIX)/bin/$^

##
# build source
##
source: $(SOURCE) | Makefile
	$(info == Build source)
	@$(VALAC) -C -g --pkg=gtk+-3.0 --pkg=gee-1.0 $^
