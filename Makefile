SOURCE=sshconf.vala sshconf-editor.vala sshconf-entry.vala sshconf-entry-model.vala

PROGRAM=sshconf
VALAC=valac

$(PROGRAM): $(SOURCE) | Makefile
	$(VALAC) -g --pkg=gtk+-3.0 --pkg=gee-1.0 $^

source: $(SOURCE) | Makefile
	$(VALAC) -C -g --pkg=gtk+-3.0 --pkg=gee-1.0 $^
