# ATM_SAAL.tcl
#
# This script establishes with an ATM Switch. In order
# to set up any SVC streams, the SSCOP State must be
# "Data Transfer Ready (10)" and the SAAL State must
# be "Connected (4).
#
#########################################################
#########################################
if  {$tcl_platform(platform) == "windows"} {
   set libPath "../../../../tcl/tclfiles/et1000.tcl"
} else {
   set libPath "../../../../include/et1000.tcl"
}
# if it is not loaded, try to source it at the default path
if { ! [info exists __ET1000_TCL__] } {
   if {[file exists $libPath]} {
      source $libPath
   } else {   
               
      # Enter the location of the "et1000.tcl" file or enter "Q" or "q" to quit
      while {1} {
         
          puts "Could not find the file $libPath."
          puts "Enter the path of et1000.tcl, or q to exit." 
          
          gets stdin libPath
          if {$libPath == "q" || $libPath == "Q"} {
              exit
          } 
          if {[file exists $libPath]} {
	      source $libPath
              break
          } 
       
       } 
   }
}

# If chassis is not currently linked prompt for IP and link  
if {[ETGetLinkStatus] < 0} {
     puts "SmartBits not linked - Enter chassis IP address"
     gets stdin ipaddr
     set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]
     if {$retval < 0 } {
	puts "Unable to connect to $ipaddr. Please try again."
	exit
	}
}


#/* SSCOP states */
#define SSCOP_STATE_IDLE 					1
#define SSCOP_STATE_OUT_CONN_PEND 		2
#define SSCOP_STATE_IN_CONN_PEND 		3
#define SSCOP_STATE_OUT_DISCONN_PEND 	4
#define SSCOP_STATE_OUT_RESYNC_PEND 	5
#define SSCOP_STATE_IN_RESYNC_PEND 		6
#define SSCOP_STATE_OUT_RECOV_PEND 		7
#define SSCOP_STATE_RECOV_RSP_PEND 		8
#define SSCOP_STATE_IN_RECOV_PEND 		9
#define SSCOP_STATE_DATA_XFER_RDY 		10
#define SSCOP_STATE_CC_RESYNC_PEND 		11
#
#/* SAAL states */
#define SAAL_STATE_IDLE 				1
#define SAAL_STATE_CONN_PEND 			2
#define SAAL_STATE_DISCONN_PEND 		3
#define SAAL_STATE_CONNECTED			4
#
###############################################################
set iHub 0
set iSlot 0
set iPort 0

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot


######################## C2I ################################
# converts uc to integer (same as ConvertUCtoI in current
# misc.tcl
#############################################################
proc C2I {ucItem} {
	set iItem 0
	set ucMin [format %c 0x00]
	set ucMax [format %c 0xFF]

	if {$ucItem == $ucMin} {
		set iItem 0
	} elseif {$ucItem == $ucMax} {
		set iItem 255
	} else {
		scan $ucItem %c iItem
	}

	return $iItem
}
##################### END C2I #################################


LIBCMD HTSetCommand $ATM_SAAL_ESTABLISH 0 0 0 0 $iHub $iSlot $iPort

struct_new MyATMSAALInfo ATMSAALInfo

set timeout 10
LIBCMD HTGetStructure $ATM_SAAL_INFO 0 0 0 MyATMSAALInfo 0 $iHub $iSlot $iPort
while { ([C2I $MyATMSAALInfo(ucSaalState)] != $SAAL_STATE_CONNECTED) \
	&& ([C2I $MyATMSAALInfo(ucSscopState)] != $SSCOP_STATE_DATA_XFER_RDY)} {
	after 200
   LIBCMD HTGetStructure $ATM_SAAL_INFO 0 0 0 MyATMSAALInfo 0 $iHub $iSlot $iPort
   incr timeout -1
   if {$timeout < 1} {
	puts "SAAL/SSCOP timeout expired"
   	puts "SAAL state is [C2I $MyATMSAALInfo(ucSaalState)]"
   	puts "SSCOP state is [C2I $MyATMSAALInfo(ucSscopState)]"
	break
	}
}

puts "SAAL state is [C2I $MyATMSAALInfo(ucSaalState)]"
puts "SSCOP state is [C2I $MyATMSAALInfo(ucSscopState)]"
puts ""
puts "VtSendState $MyATMSAALInfo(ulVtSendState)"
puts "VtPollSend $MyATMSAALInfo(ulVtPollSend)"
puts "VtMaxSend $MyATMSAALInfo(ulVtMaxSend)"
puts "VtPollData $MyATMSAALInfo(ulVtPollData)"
puts "VrRxState $MyATMSAALInfo(ulVrRxState)"
puts "VrHighestExpected $MyATMSAALInfo(ulVrHighestExpected)"
puts "VrMaxReceive $MyATMSAALInfo(ulVrMaxReceive)"

unset MyATMSAALInfo

#UnLink from the chassis
LIBCMD NSUnLink


