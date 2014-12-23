############################################################
# ATM_ILMI.TCL
#
# This script basically allows an ATM Card to register it's
# 20-byte address with the network device (ATM Switch) that
# it is connected to. After registration is successfully
# completed, it displays the ILMI Status information.
#
############################################################

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

set iHub 0
set iSlot 0
set iPort 0

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot


################### LIBCMD ##################################
# LIBCMD error handler (from misc.tcl)
#############################################################
proc LIBCMD {args} {
	set iResponse [uplevel $args]
	if {$iResponse < 0} {
	   puts "$args :  $iResponse"
	}
}
#################### END LIBCMD #############################
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

###############################################################
#######################   MAIN PROGRAM   ######################
###############################################################
struct_new ILMIParams ATMILMIParams
   set ILMIParams(ulColdStartTimer) $ILMI_DEFAULT_TMR_COLD_START
   set ILMIParams(ulRegTimeoutTimer) $ILMI_DEFAULT_TMR_REG_TIMEOUT
   set ILMIParams(ucESI.0.uc) [format %c 0x00]
   set ILMIParams(ucESI.1.uc) [format %c 0x00]
   set ILMIParams(ucESI.2.uc) [format %c 0x00]
   set ILMIParams(ucESI.3.uc) [format %c 0x00]
   set ILMIParams(ucESI.4.uc) [format %c 0x00]
   set ILMIParams(ucESI.5.uc) [format %c [expr $iSlot +1]]
LIBCMD HTSetStructure $ATM_ILMI 0 0 0 ILMIParams 0 $iHub $iSlot $iPort
unset ILMIParams

struct_new MyILMIInfo ATMILMIInfo

puts "Register ILMI"
LIBCMD HTSetCommand $ATM_ILMI_REGISTER 0 0 0 0 $iHub $iSlot $iPort


#####################################################
# Wait for ILMI state to be 3 (Running)
#
# States are defined in atmitems.h as follows:
# /* UNI Management Entity (UME) states */
# #define ATM_ILMI_UME_INACTIVE		0
# #define ATM_ILMI_UME_DOWN			1
# #define ATM_ILMI_UME_COLD_START	2
# #define ATM_ILMI_UME_RUNNING		3
######################################################

puts "Retrieving ILMI Status info."
LIBCMD HTGetStructure $ATM_ILMI_INFO 0 0 0 MyILMIInfo 0 $iHub $iSlot $iPort


set timeout 10
while { [C2I $MyILMIInfo(ucState)] != 3 } {
	after 200
	LIBCMD HTGetStructure $ATM_ILMI_INFO 0 0 0 MyILMIInfo 0 $iHub $iSlot $iPort
	incr timeout -1
	if {$timeout < 1} {
	puts "ILMI timeout expired"
		puts "ILMI state is [C2I $MyILMIInfo(ucState)]"
	break
	}
}
#################################################################
# If timeout did not expire ILMI state 3 was returned (running)
# We test value of timeout to ensure we didn't timeout if not
# we display the ILMI counts and the ATM address
#################################################################
if { $timeout > 0 } {
	puts ""
	puts "ILMI Statistics\n"
	puts "	ColdStarts $MyILMIInfo(uiColdStarts)"
	puts "	Good Packets $MyILMIInfo(uiGoodPackets)"
	puts "	Bad Packets $MyILMIInfo(uiBadPackets)"
   puts "	Sent Packets $MyILMIInfo(uiSentPackets)"

   puts ""
   puts "-----------------------------------------------------------------"
   puts "	   ATM Address Prefix		|	ESI	    |Sel|"
   puts "-----------------------------------------------------------------"
   for {set i 0} {$i < 13} {incr i} {
      set addr [C2I $MyILMIInfo(RegAddr.ucPrefix.$i.uc)]
      puts -nonewline " [format %02X $addr]"
   }
   puts -nonewline " |"
   for {set i 0} {$i < 6} {incr i} {
      set addr [C2I $MyILMIInfo(RegAddr.ucEsi.$i.uc)]
      puts -nonewline " [format %02X $addr]"
   }
	puts -nonewline " |"
   puts " [C2I $MyILMIInfo(RegAddr.ucSel)] |"
   puts "-----------------------------------------------------------------"
   puts ""
   puts "Deregistering ILMI"
   LIBCMD HTSetCommand $ATM_ILMI_DEREGISTER 0 0 0 "" $iHub $iSlot $iPort
}

unset MyILMIInfo

LIBCMD NSUnLink
