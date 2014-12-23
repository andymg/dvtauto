# ATMSonetInfo.tcl
# 
# Retrieves and dsiplays SONET Section / Line / Path error information
#
######################################################################

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

set iHub 0
set iSlot 0
set iPort 0

struct_new MySonetInfo ATMSonetLineInfo

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

puts "Checking sonet line info..."
LIBCMD HTGetStructure $ATM_SONET_INFO 0 0 0 MySonetInfo 0 $iHub $iSlot $iPort
after 3000
  if {$MySonetInfo(uiAlarmCurrent) == 0} {
	puts ""
	puts "		*********************************"
	puts "		*    NO CURRENT SONET ALARMS    *"
	puts "		*********************************"
	puts " "
  } else {
	puts "==============================================================="
  	puts "	    CURRENT ALARMS (Hub [expr $iHub + 1] Slot [expr $iSlot + 1])"
        puts "==============================================================="
		if { $MySonetInfo(uiSectionBip8Rate) != 0 } {
			puts " 		$MySonetInfo(uiSectionBip8Rate) Section BIP 8 Errors per second"
		}
		if { $MySonetInfo(uiLineBip24Rate) != 0 } {
			puts " 		$MySonetInfo(uiLineBip24Rate) Line BIP 24 Errors per second"
		}
		if { $MySonetInfo(uiLineFebeRate) != 0 } {
			puts " 		$MySonetInfo(uiLineFebeRate) Line FEBE Errors per second"
		}
		if { $MySonetInfo(uiPathBip8Rate) != 0 } {
			puts " 		$MySonetInfo(uiPathBip8Rate) Path BIP 8 Errors per second"
		}
		if { $MySonetInfo(uiPathFebeRate) != 0 } {
			puts " 		$MySonetInfo(uiPathFebeRate) Path FEBE Errors per second"
		}
	puts "Press ENTER key to display alarm history (since last counter clear)"
	gets stdin response
	}
############################################
# Print out SONET alarms since last clear: #
############################################
  	puts "==============================================================="
  	puts "	    SONET ALARM HISTORY (Hub [expr $iHub + 1] Slot [expr $iSlot + 1])"
	puts "   	Sonet errors logged since last ATM Counter Clear"
        puts "==============================================================="
        puts "			SECTION ERRORS"
	puts "		--------------------------------"
        puts " 		Section Bip 8 	$MySonetInfo(ulSectionBip8)"
	puts ""
	puts "			LINE ERRORS"
	puts "		--------------------------------"
	puts " 		Line Bip 24	$MySonetInfo(ulLineBip24)"
	puts " 		Line FEBE	$MySonetInfo(ulLineFebe)"
	puts ""
	puts " 			PATH ERRORS"
	puts "		--------------------------------"
	puts " 		Path Bip8	$MySonetInfo(ulPathBip8)"
	puts " 		Path FEBE	$MySonetInfo(ulPathFebe)"
	puts ""


unset MySonetInfo

#UnLink from the chassis
LIBCMD NSUnLink

