# sloadx.tcl
#
# loads slibx extensions
#
# Performs a series of checks:
# 1) Checks Tcl version for 8.0 or higher (required for 
# namespace support)
# 2) Checks that libx.tcl and l3x.tcl are local.  If it is 
# necessary that libx.tcl and l3x.tcl are not local,
# set libx and l3 to the path to the files. 
# 3) If both 1 and 2 are true, it looks for an existing LIBCMD
# proc in memory.  If one is found it is removed (renaming a proc
# "" erases it). 
# 
# After sourcing, it imports the proc names exported by the
# procedures.
###################################################
# Set path to libx files
if {[info exists __SMARTLIB_TCL__] > 0 } {
  set LIBX "slibx.tcl"
  set L3X  "sl3x.tcl"
  puts "Loading LibX for SmartLib.tcl"
} elseif {[info exists __ET1000_TCL__] > 0} {
  set LIBX "libx.tcl"
  set L3X "l3x.tcl"
  puts "Loading LibX for ET1000.tcl"
} else {
  puts "SmartBits programming library not loaded"
}

# Must have at least Tcl 8.0
if { [info tclversion] < 8.0} {
   puts "ERROR libx requires Tcl version 8.0 or higher"
   puts "Press ENTER to abort loading"
   gets stdin response
} else {
   # Can we find the files (are the paths valid?)
   if { [file isfile $LIBX] && [file isfile $L3X] } {
       # if there's already a LIBCMD in memory remove it
       if { [info commands LIBCMD] == "LIBCMD" } {
           rename LIBCMD ""
       }
       source $LIBX
       namespace import libx::*
       source $L3X
       namespace import l3x::*
       puts "LibX loaded"
   } else {
       puts "Files $LIBX and/or $L3X were not found"
       puts "Press ENTER to abort loading"
   }
}


