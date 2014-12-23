#!/bin/sh
#\
exec tclsh "$0" "$@"

#Filename: init.tcl
#Target: load private module from "base" folder and initial public parameters.
#History:
#        11/20/2013- Olivia,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes:

if {catch {source ../base/mef.tcl} err} {
	puts "$err: can't find mef.tcl files, please check"
} 

