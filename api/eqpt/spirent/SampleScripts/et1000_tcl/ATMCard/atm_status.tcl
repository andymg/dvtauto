#ATM_Status.tcl
#
# Demo program that checks the status and LED state
# of an ATM Card with HTGetEnhancedStatus and HTGetLED
# function calls
#
# * ATM LED definitions
#define ATM_LED_STATUS_TX			0x0002
#define ATM_LED_STATUS_ALARM_RED		0x0004
#define ATM_LED_STATUS_ALARM_YELLOW		0x000C
#define ATM_LED_STATUS_TRIG			0x0008
#define ATM_LED_STATUS_LOS			0x0010
#define ATM_LED_STATUS_RX			0x0020
#
#/* LED protocol state information */
#define ATM_LED_STATE_MASK			0xFF00
#define ATM_LED_STATE_PHY_DOWN			0x0000
#define ATM_LED_STATE_PHY_UP			0x0100
#define ATM_LED_STATE_ILMI_UP			0x0200
#define ATM_LED_STATE_ILMI_AND_SAAL_UP		0x0300
#define ATM_LED_STATE_SAAL_UP			0x0400
#
##########################################################
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

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

set status ""
HTGetEnhancedStatus status $iHub $iSlot $iPort
puts "Card State [format %X $status]"


#UnLink from the chassis
LIBCMD NSUnLink

