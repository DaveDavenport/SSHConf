SOURCE=sshconf.vala sshconf-editor.vala
PROGRAM=sshconf
VALAC=valac

$(PROGRAM): $(SOURCE) | Makefile
	$(VALAC) -g --pkg=gtk+-3.0 --pkg=gee-1.0 $^


