########################################################################################################
# GroupCount.tcl                                                                                       #
#                                                                                                      #
# This program sets a group of two cards (slot 1 and 2).                                               #
# - Uses HGIs HubSlotPortInGroup to test card membership.                                              #
# - An array of counter structures is created to:                                                      #
#   - Hold the group counter data,                                                                     #
#   - Draw a simple report and                                                                         #
#   - Fill in the counter data.                                                                        #
#                                                                                                      #
# NOTE: This sample code does not work for ATM and WAN cards                                           #
# NOTE: This script works on the following cards:                                                      #
#       - 10 Mbps                                                                                      #
#       - SX-72XX/74XX                                                                                 #
#       - L3-67XX                                                                                      #
#       - ML-7710                                                                                      #
#       - ML-5710                                                                                      #
#       - LAN-6100                                                                                     #
#       - LAN-6101A                                                                                    #
#       - GX-1405(B)                                                                                   #
#       - GX-1420 A/B                                                                                  #
#       - LAN-6200A                                                                                    #
#       - LAN-6201A/B                                                                                  #
#       - LAN-3300A/3301A/3302A                                                                        #
#       - LAN-3310A/3311A                                                                              #
#       - LAN-3306A                                                                                    #
#       - LAN-332xA                                                                                    #
#       - LAN-3710A                                                                                    #
#       - XLW-372xA                                                                                    #
#       - POS-6500/6502                                                                                #
#       - POS-3505As/3504As                                                                            #
#       - TokenRing                                                                                    #             
#                                                                                                      #
########################################################################################################       


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
     set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]
     if {$retval < 0 } {
	puts "Unable to connect to $ipaddr. Please try again."
	exit
	}
}



#Set the default settings for the Hub, Slot and Port
set iHub 0
set iPort 0

set iSlot 0
set iSlot2 1

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub $iSlot2

#Get the Maximum number of slots	
set MAX_SLOTS [NSGetNumSlots $iHub]

puts "--------------------------------------------------------------------"
puts "Maximum number of slots in this chassis: $MAX_SLOTS "


LIBCMD HGSetGroup ""

LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub $iSlot2 $iPort

#Sets it to the deafult values
LIBCMD HGResetPort $RESET_FULL

#Get the group membership info
puts "--------------------------------------------------------------------"
puts "Getting group membership info:"
for { set i 0 } { $i < $MAX_SLOTS } { incr i } {
      
       #Get the number of slots in the chassis
       set retval [HGIsHubSlotPortInGroup $iHub $i $iPort] 
       
       #Check for group membership
       switch -glob -- $retval {
    
            -17     { 
                      #If the card is present in the slot, but is being used by someone else
                      puts "Card is not available: Hub: $iHub Slot: $i Port: $iPort"
             }
  
             0      { 
                      #If the card is not added in the group
                      puts "Card not in the group: Hub: $iHub Slot: $i Port: $iPort"
             }
             
            -*      { 
                      #If the function itself fails
                      puts "--------------------------------------------------------------------"
                      puts "This Function has Failed"}

            default { 
                      #If the card has been added in the group
                      puts "Card in the group: Hub: $iHub Slot: $i Port: $iPort"
           
                     
               }
         }
 }        


# Clear counters in group with HGClearPort
LIBCMD HGClearPort

LIBCMD HGStart
after 5000	

#Stop transmitting packets		
LIBCMD HGStop				
puts "Done!"

#####################################################################################
# Counters                                                                          #
#                                                                                   #
# - An array of two structures of type HTCountStructure is created                  #
# - HGGetCounters is called to retireve data from cards                             #
# - Pause for a second to allow for download time                                   #
# - Display the results                                                             #
# - Add 1 to $iSlot and $iSlot2 to match the slot number on the chassis             #
#                                                                                   #
#####################################################################################

struct_new cs HTCountStructure*2

LIBCMD HGGetCounters cs
while {$cs(0.TmtPktRate) !=0 } {
        

        #Pause for 1 second
        after 1000
        LIBCMD HGGetCounters cs
 }

        #Pause for 1 second before displaying test results to allow for download time
        after 1000

        #Display test results
        puts "--------------------------------------------------------------------"
        puts "			Test Results"
        puts "--------------------------------------------------------------------"
        puts "                   Card [expr $iSlot + 1]                   Card [expr $iSlot2 +1]"
        puts "--------------------------------------------------------------------"
        set line [format "Tx Packets     %10d          |    %10d" $cs(0.TmtPkt)\
                 $cs(1.TmtPkt)]
        puts $line
        #puts "Tx Packets        $cs(0.TmtPkt)		|       $cs(1.TmtPkt)"
        set line [format "Rx Packets     %10d          |    %10d" $cs(0.RcvPkt)\
                 $cs(1.RcvPkt)]
        puts $line
        #puts "Rx Packets 	$cs(0.RcvPkt)		|	$cs(1.RcvPkt)"
        set line [format "Collisions     %10d          |    %10d" $cs(0.Collision)\
                 $cs(1.Collision)]
        puts $line
        #puts "Collisions	$cs(0.Collision)		|	$cs(1.Collision)"
        set line [format "Recvd Trigger  %10d          |    %10d" $cs(0.RcvTrig)\
                 $cs(1.RcvTrig)]
        puts $line
        #puts "Recvd Trigger	$cs(0.RcvTrig)		|	$cs(1.RcvTrig)"
        set line [format "CRC Errors     %10d          |    %10d" $cs(0.CRC)\
                 $cs(1.CRC)]
        puts $line
        #puts "CRC Errors	$cs(0.CRC)		|  	$cs(1.CRC)"
        puts "--------------------------------------------------------------------"

      
      


#Unset the structure 
unset cs


#UnLink from the chassis
puts "--------------------------------------------------------------------"
puts "UnLinking from the Chassis now"
LIBCMD NSUnLink
