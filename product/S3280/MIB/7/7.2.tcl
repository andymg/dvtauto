
#!/bin/tcl

#Filename: 7.1.tcl
#History:
#        12/12/2013- Miles,Created
#
#Copyright(c): Transition Networks, Inc.2013

#Notes: the target of following test cases is test lldp port mode function ,which include 
#Disable,Enable,Txonly,Rxonly.


source ./init.tcl

#dut1 port4 connected dut2 port4
set port1 $::dutp3
set port2 $::dutp4
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
puts "++++(please make sure dut1 port $port1 connected dut2 port $port2)+++++"
puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#.1 LLDP port mode ENABLE test
setToFactoryDefault $dut1
setToFactoryDefault $dut2
lldp::settxInterval  $dut1 8
lldp::settxInterval  $dut2 8
lldp::setlldpportmode $dut1 $port2 TXANDRX
lldp::setlldpportmode $dut2 $port2 TXANDRX
after 10000
lldp::settxInterval  $dut1 8
lldp::settxInterval  $dut2 8
lldp::settxHold $dut1 10
lldp::settxHold $dut2 10
set txInterval [lldp::gettxInterval $dut1]
after $txInterval
set dut1RemchaID [lldp::walkRemChassisID $dut1]
set dut2RemchaID [lldp::walkRemChassisID $dut2]
set dut1macadd [string toupper [getDutMacAddr $dut1]]
set dut2macadd [string toupper [getDutMacAddr $dut2]]
set TX  [string equal $dut2RemchaID $dut1macadd]
set RX [string equal $dut1RemchaID $dut2macadd] 
if { $TX== 1  &&  $RX == 1 } {
    passed  portmodeENABLE "lldp port mode ENABLE test  successed"
} elseif { $TX == 1   &&   $RX == 0 } {
    failed portmodeENABLE  "In ENABLE mode ,DUT only could send lldp packets"
} elseif { $RX == 1  &&  $TX == 0 } {
  failed portmodeENABLE  "In ENABLE mode ,DUT only could receive lldp packets"
} else  {
    failed portmodeENABLE  "In ENABLE mode ,DUT can not send and receive lldp packets"
}

#.2 LLDP port mode DISABLE test
setToFactoryDefault $dut1
setToFactoryDefault $dut2
lldp::settxInterval  $dut1 8
lldp::settxInterval  $dut2 8
lldp::setlldpportmode $dut1 $port2 DISABLE
lldp::setlldpportmode $dut2 $port2 TXANDRX
after 10000
lldp::settxInterval  $dut1 8
lldp::settxInterval  $dut2 8
lldp::settxHold $dut1 10
lldp::settxHold $dut2 10
set txInterval [lldp::gettxInterval $dut1]
after $txInterval
set dut1RemchaID [lldp::walkRemChassisID $dut1]
set dut2RemchaID [lldp::walkRemChassisID $dut2]
set dut1macadd [string toupper [getDutMacAddr $dut1]]
set dut2macadd [string toupper [getDutMacAddr $dut2]]
set TX  [string equal $dut2RemchaID $dut1macadd]
set RX [string equal $dut1RemchaID $dut2macadd] 
if { $TX== 0  &&  $RX == 0 } {
    passed  portmodeDISABLE "lldp port mode DISABLE test  successed"
} elseif { $TX == 1   &&   $RX == 0 } {
    failed portmodeDISABLE  "In DISABLE mode ,DUT  could send lldp packets"
} elseif { $RX == 1  &&  $TX == 0 } {
  failed portmodeDISABLE  "In DISABLE mode ,DUT could receive lldp packets"
} else  {
    failed portmodeDISABLE  "In DISABLE mode ,DUT could send and receive lldp packets"
}

#.3 LLDP port mode TXONLY test
setToFactoryDefault $dut1
setToFactoryDefault $dut2
lldp::settxInterval  $dut1 8
lldp::settxInterval  $dut2 8
lldp::setlldpportmode $dut1 $port2 TXONLY
lldp::setlldpportmode $dut2 $port2 TXANDRX
after 10000
lldp::settxInterval  $dut1 8
lldp::settxInterval  $dut2 8
lldp::settxHold $dut1 10
lldp::settxHold $dut2 10
set txInterval [lldp::gettxInterval $dut1]
after $txInterval
set dut1RemchaID [lldp::walkRemChassisID $dut1]
set dut2RemchaID [lldp::walkRemChassisID $dut2]
set dut1macadd [string toupper [getDutMacAddr $dut1]]
set dut2macadd [string toupper [getDutMacAddr $dut2]]
set TX  [string equal $dut2RemchaID $dut1macadd]
set RX [string equal $dut1RemchaID $dut2macadd] 
if { $TX== 1  &&  $RX == 0 } {
    passed  portmodeTXONLY "lldp port mode TXONLY test  successed"
} elseif { $TX == 1   &&   $RX == 1 } {
    failed portmodeTXONLY  "In TXONLY mode ,DUT  could send and receive lldp packets"
} elseif { $RX == 1  &&  $TX == 0 } {
  failed portmodeTXONLY  "In TXONLY mode ,DUT could receive lldp packets,but can not send lldp packets"
} else  {
    failed portmodeTXONLY  "In TXONLY mode ,DUT can not send and receive lldp packets"
}
#.4 LLDP port mode RXONLY test
setToFactoryDefault $dut1
setToFactoryDefault $dut2
lldp::settxInterval  $dut1 8
lldp::settxInterval  $dut2 8
lldp::setlldpportmode $dut1 $port2 RXONLY
lldp::setlldpportmode $dut2 $port2 TXANDRX
after 10000
lldp::settxInterval  $dut1 8
lldp::settxInterval  $dut2 8
lldp::settxHold $dut1 10
lldp::settxHold $dut2 10
set txInterval [lldp::gettxInterval $dut1]
after $txInterval
set dut1RemchaID [lldp::walkRemChassisID $dut1]
set dut2RemchaID [lldp::walkRemChassisID $dut2]
set dut1macadd [string toupper [getDutMacAddr $dut1]]
set dut2macadd [string toupper [getDutMacAddr $dut2]]
set TX  [string equal $dut2RemchaID $dut1macadd]
set RX [string equal $dut1RemchaID $dut2macadd] 
if { $RX== 1  &&  $TX == 0 } {
    passed  portmodeRXONLY "lldp port mode RXONLY test  successed"
} elseif { $RX == 1   &&   $TX == 1 } {
    failed portmodeRXONLY  "In RXONLY mode ,DUT  could send and receive lldp packets"
} elseif { $TX == 1  &&  $RX == 0 } {
  failed portmodeRXONLY  "In RXONLY mode ,DUT could send lldp packets,but can not receive lldp packets"
} else  {
    failed portmodeRXONLY  "In RXONLY mode ,DUT can not send and receive lldp packets"
}
