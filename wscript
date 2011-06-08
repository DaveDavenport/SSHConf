#!/usr/bin/env python

VERSION = "0.0.1"
VERSION_MAJOR_MINOR =  ".".join(VERSION.split(".")[0:2])
APPNAME = "sshconf"

srcdir = '.'
blddir = 'build'

def set_options(opt):
    opt.tool_options('compiler_cc')
    opt.tool_options('gnu_dirs')

def configure(conf):
    conf.check_tool('compiler_cc vala gnu_dirs')

    conf.check_cfg(package='glib-2.0', uselib_store='GLIB',
            atleast_version='2.28.0', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='gtk+-3.0', uselib_store='GTK+',
            atleast_version='3.0.0', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='gee-1.0', uselib_store='GEE',
            atleast_version='0.6.0', mandatory=True, args='--cflags --libs')

    conf.define('PACKAGE', APPNAME)
    conf.define('PACKAGE_NAME', APPNAME)
    conf.define('PACKAGE_STRING', APPNAME + '-' + VERSION)
    conf.define('PACKAGE_VERSION', APPNAME + '-' + VERSION)

    conf.define('VERSION', VERSION)
    conf.define('VERSION_MAJOR_MINOR', VERSION_MAJOR_MINOR)

def build(bld):
	prog = bld(features='cc cprogram')
	# name of the resulting program
	prog.target = APPNAME
	prog.source = ['sshconf.vala',
				   'sshconf-entry.vala',
				   'sshconf-entry-model.vala',
				   'sshconf-editor.vala']
	# libraries to link against
	prog.uselib = ['GTK+', 'GLIB', 'GEE']
	# Vala packages to use
	prog.packages = ['gtk+-3.0', 'gee-1.0']
