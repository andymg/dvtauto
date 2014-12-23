# unloadlibx.tcl
#
# unloads library extensions
#########################################
namespace delete libx
namespace delete l3x
unset __LIBX_TCL__
puts "LibX unloaded"

