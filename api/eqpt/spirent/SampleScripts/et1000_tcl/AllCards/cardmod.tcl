###############################################################################################
# CardMod.tcl                                                                                 #
#                                                                                             #
# This program, probes a SmartBits stack and                                                  #
#                                                                                             #
# Displays:                                                                                   #
# - The IP Address of the chassis linked.                                                     #
# - Maximum numer of Slots in the chassis.                                                    #
# - The HUB, SLOT, PORT of the card present.                                                  #
# - The Card Number defined in the "et1000.tcl" file.                                         #
# - The Card Model associated with the card number.                                           #
# - Changes port mapping mode from compatible mode to native mode                             #
# - Either mode may however be used with any SmartBits chassis                                #
#                                                                                             #
# NOTE: This script works on the following cards:                                             #
#       - ALL Cards                                                                           #
#                                                                                             #
###############################################################################################

#Load the et1000.tcl file
if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/et1000.tcl"
} else {
      set libPath "../../../../include/et1000.tcl"
}


#If it is not loaded, try to source it at the default path
if { ! [info exists __ET1000_TCL__] } {
     if {[file exists $libPath]} {
	  source $libPath
     } else {   
	       
      # Enter the location of the "et1000.tcl" file or enter "Q" or "q" to quit
      while {1} {
	 
		  puts "Could not find the file '$libPath'."
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
     set retval [ETSocketLink $ipaddr 16385]  
     if {$retval < 0 } {
	puts "Unable to connect to $ipaddr. Please try again."
	exit
	}
}

#Change port mapping mode to native mode
LIBCMD NSSetPortMappingMode $PORT_MAPPING_NATIVE


#Variable to display the Card Model 
set model ""

#Get the maximum number of slots in the chassis linked
set MAX_SLOTS [NSGetNumSlots 0]

#Display the maximum number of slots in the chassis, with the IP Address
puts "-------------------------------------------------------"
puts "MAXSLOTS: $MAX_SLOTS, in SmarBits chassis $ipaddr"
puts "-------------------------------------------------------"

#Display the card number and model of each card present in the chassis
for {set iSlot 0} {$iSlot < $MAX_SLOTS} {incr iSlot} {
      
	    set number [LIBCMD HTGetCardModel model 0 $iSlot 0]
	    puts "HUB: 0 SLOT: $iSlot PORT: 0:"
	    puts "Card Number: $number"
	    puts "Card Model: $model"
	    puts "-------------------------------------------------------"
    }


#UnLinks from the chassis
puts "UnLinking from the chassis now"
ETUnLink
puts ""
puts "DONE!"
