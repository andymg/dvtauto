source ./init.tcl

variable self [file normalize [info script]]
set path [file dirname [file nativename $self]]

setToFactoryDefault $::dut
puts "start connect_ixia"

connect_ixia -ipaddr $::ixiaIpAddr -portlist $::ixiaPort1,ixiap1,$::ixiaPort2,ixiap2 $::ixiaPort3,ixiap3,-alias allport -loginname AutoIxia

config_portprop -alias ixiap1 -autonego enable -phymode $phymode
puts $phymode
config_portprop -alias ixiap2 -autonego enable -phymode $phymode
puts $phymode
config_portprop -alias ixiap3 -autonego enable -phymode $phymode
puts $phymode

