#####################################################################################################
# L3Zero.tcl                                                                                        #
#                                                                                                   #
# - Shows number of streams on target L3 card and prompts user if the streams should be removed.    #
#                                                                                                   #
# - Procedure is useful to check other programs that create groups of                               #
#   L3 streams, so you can be sure you created the number of streams you                            #
#   thought you were creating.                                                                      #
#                                                                                                   #
# - Stream 0 on layer three cards is reserved for internal use so                                   #
#   it can not be eliminated.  It is set by to inactive so it will not                              #
#   transmit.  For this reason, there will always be one stream reported                            #
#   on the target L3 card.  If you want the program to report the number                            #
#   of user available streams on the cards, use expr to subtract one from the result.               #
#   as in                                                                                           #
#	"There are [expr $DefStreams(0.ul) - 1] streams"                                            #
#                                                                                                   #
# NOTE: This script works on the following cards:                                                   #
#       - L3-67XX                                                                                   #
#       - ML-7710                                                                                   #
#       - ML-5710                                                                                   #
#       - LAN-6101A                                                                                 #
#       - LAN-3300A/3301A                                                                           #
#       - LAN-3310A/3311A                                                                           #
#       - POS-3505As/3504As                                                                         #
#                                                                                                   #
#####################################################################################################

# If smartlib.tcl is not loaded, attempt to locate it at the default location.
# The actual location is different on different platforms. 
if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/smartlib.tcl"
} else {
         set libPath "../../../../include/smartlib.tcl"
}
# if "smartlib.tcl" is not loaded, try to source it from the default path
if { ! [info exists __SMARTLIB_TCL__] } {
     if {[file exists $libPath]} {
          source $libPath
} else {   
               
         #Enter the location of the "smartlib.tcl" file or enter "Q" or "q" to quit
         while {1} {
         
                     puts "Could not find the file $libPath."
                     puts "Enter the path of smartlib.tcl, or q to exit." 
          
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

# Reserve the card
LIBCMD HTSlotReserve $iHub $iSlot

struct_new StreamCount  ULong

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort

puts "There are $StreamCount(ul) streams currently on card [expr $iSlot + 1]"
puts "Erase them and switch to traditional mode? (y/n)"
gets stdin response
if {$response == "y"} {
     puts "zeroing stream count"
     LIBCMD HTSetStructure $L3_DEFINE_SMARTBITS_STREAM 0 0 0 NULL 0 $iHub $iSlot $iPort
     LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort
     puts "Current stream count $StreamCount(ul) streams on card $iSlot"
} else {
         puts "Keeping stream count at $StreamCount(ul) streams on card $iSlot"
}

#Unset the structure
unset StreamCount

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"


