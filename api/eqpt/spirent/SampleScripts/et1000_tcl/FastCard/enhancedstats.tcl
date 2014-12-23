######################################################################################
# EnhancedStats.tcl                                                                  #
#                                                                                    #
# - Uses HTGetCardModel to ensure a FastCard is selected then does a bitwise AND to  #
#   see if the FAST7410_STATUS_LINK (0x0000200h) is set.                             #
#                                                                                    #
# NOTE: This script works on the following cards:                                    #
#       - SX-72XX / SX-74XX                                                          #
#       - ML-7710                                                                    #
#       - ML-5710                                                                    #
#       - L3-67XX                                                                    #
#       - LAN-6100                                                                   #
#       - LAN-6101A                                                                  #
#       - LAN-3302A                                                                  #
#       - LAN-3306A                                                                  #
#                                                                                    #
######################################################################################


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

#Set the default variables
set iHub 0
set iSlot 9
set iPort 0

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

set cardname ""
LIBCMD HTGetCardModel cardname $iHub $iSlot $iPort
puts "$cardname"
switch $cardname {
    SX-7210 -
    SX-7410 -
    SX-7410B -
    ML-7710  {
        struct_new stats ULong
        LIBCMD HTGetEnhancedStatus stats $iHub $iSlot $iPort
        puts [format %X $stats(ul)]
        if {[ expr $FAST7410_STATUS_LINK & $stats(ul) ] == 0} {
            puts "Card is not linked"
        } else {
            puts "Card is linked"
        }
        unset stats
    }
    LAN-6100A/3100A -
    LAN-3302A -
    LAN-3306A  {
        struct_new stats ULong
        LIBCMD HTGetEnhancedStatus stats $iHub $iSlot $iPort
        puts [format %X $stats(ul)]
        if {[ expr $GIG_STATUS_LINK & $stats(ul) ] == 0} {
            puts "Card is not linked"
        } else {
            puts "Card is linked"
        }
        unset stats
    }
    default  {puts "$cardname is either not a fastcard or is not checked"}
}

#UnLink from the chassis
LIBCMD NSUnLink
