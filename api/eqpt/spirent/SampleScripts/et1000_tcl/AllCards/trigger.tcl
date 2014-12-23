######################################################################################################
# Trigger.tcl                                                                                        #
#                                                                                                    #
# This program:                                                                                      #
#                                                                                                    #
# - Sets a group of two cards (slot 1 and 2)                                                         #
# - Sets up a VFD and a trigger to match.                                                            #
# - An array of counter structures is created to hold the group counter data, then draw a            #
#   simple report and fill in the counter data.                                                      #
#                                                                                                    #
# NOTE:  This sample code does not work with ATM and WAN cards.                                      #
#        This script works on the following cards:                                                   #
#        - 10 Mbps                                                                                   #
#        - SX-72XX/74XX                                                                              #
#        - L3-67XX                                                                                   #
#        - ML-7710                                                                                   #
#        - ML-5710                                                                                   #
#        - LAN-6100                                                                                  #
#        - LAN-6101A                                                                                 #
#        - GX-1405(B)                                                                                #
#        - GX-1420(B)                                                                                #
#        - LAN-6200A                                                                                 #
#        - LAN-3300A/3301A/3302A                                                                     #
#        - LAN-3310A/3311A                                                                           #
#        - LAN-3306A                                                                                 #
#        - LAN-332xA                                                                                 #
#        - LAN-3710A                                                                                 #
#        - XLW-372xA                                                                                 #
#        - TokenRing                                                                                 #
#                                                                                                    #
######################################################################################################

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
set iHub2 0

set iSlot 0
set iSlot2 0

set iPort 0
set iPort2 1

#set CARD_NUM 2
set VFD_LENGTH 6

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

LIBCMD HGSetGroup ""

LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub $iSlot2 $iPort2


# Set up VFD's
# VFD1 and 2 number from Least Significant. 
struct_new vfdstruct HTVFDStructure
set vfdstruct(Configuration) $HVFD_STATIC
set vfdstruct(Range) $VFD_LENGTH
set vfdstruct(Offset) 0

struct_new vfd1Data Int*$VFD_LENGTH
  set vfd1Data(0.i) 0x66
  set vfd1Data(1.i) 0x55
  set vfd1Data(2.i) 0x44
  set vfd1Data(3.i) 0x33
  set vfd1Data(4.i) 0x22
  set vfd1Data(5.i) 0x11

set vfdstruct(Data) vfd1Data
set vfdstruct(DataCount) 0
LIBCMD HGVFD $HVFD_1 vfdstruct
unset vfd1Data

struct_new vfd2Data Int*$VFD_LENGTH
  set vfd2Data(0.i) 0xAA
  set vfd2Data(1.i) 0xBB
  set vfd2Data(2.i) 0xCC
  set vfd2Data(3.i) 0xDD
  set vfd2Data(4.i) 0xEE
  set vfd2Data(5.i) 0xFF

set vfdstruct(Data) vfd2Data
set vfdstruct(DataCount) 0
set vfdstruct(Offset) 48
LIBCMD HGVFD $HVFD_2 vfdstruct

unset vfdstruct
unset vfd2Data


#########################################################################################################
# Set up trigger on Ethernet cards                                                                      #
#                                                                                                       #
# - Offset of 0                                                                                         #
# - Range of 6 will match first 6 bytes of Ethernet packet (Destination MAC).                           #
# - Trigger one sets Pattern.0 66; Pattern.1 55 Pattern.2 44 etc.                                       #
# - This will match a Destination MAC of 11 22 33 44 55 66 (element zero is the least significant byte. #
# - Trigger 2 is set to the opposite direction with the least significat byte(Pattern.0) set to AA.     #
# - Triggers can be set to ON OFF and DEPEND.                                                           #
# - If trigger 1 is set ON and trigger 2 is set to ON it will OR                                        #
# - If trigger 1 is set ON and trigger 2 is set to DEPEND it will AND                                   #
#                                                                                                       #
#########################################################################################################

struct_new ts HTTriggerStructure
     set ts(Offset) 0
     set ts(Range) 6
# Will match 11 22 33 44 55 66
        set ts(Pattern.0) 0x66
        set ts(Pattern.1) 0x55
        set ts(Pattern.2) 0x44
        set ts(Pattern.3) 0x33
        set ts(Pattern.4) 0x22
        set ts(Pattern.5) 0x11

LIBCMD HGTrigger $HTTRIGGER_1 $HTTRIGGER_ON ts

     set ts(Offset) 48
# Will match FF EE DD CC BB AA
        set ts(Pattern.0) 0xAA
        set ts(Pattern.1) 0xBB
        set ts(Pattern.2) 0xCC
        set ts(Pattern.3) 0xDD
        set ts(Pattern.4) 0xEE
        set ts(Pattern.5) 0xFF
LIBCMD HGTrigger $HTTRIGGER_2 $HTTRIGGER_ON ts

unset ts



# Clear counters in group with HTClearPort and transmit for 5 seconds.

HGClearPort
puts "Sending Packets..."
HGStart 
after 5000			
HGStop				
puts "Done!"

###################################################################################################
# Counters                                                                                        #
#                                                                                                 #
# - An array of two structures of type HTCountStructure is created, then HGGetCounters is called  #
#   to retrieve data from cards.                                                                  #
# - We allow one second (after 1000) for download time.                                           #
# - A series of puts statements is used to display the data.                                      #
# - We add 1 to $iSlot and $iSlot2 to match the slot number on the chassis                        #
###################################################################################################

struct_new cs HTCountStructure*2

#Pause for 1 sec
after 1000

LIBCMD HGGetCounters cs

puts "------------------------------------------------------------"
puts "			Test Results"
puts "------------------------------------------------------------"
puts "    	        Card [expr $iSlot + 1]			Card [expr $iSlot2 +1]"
puts "------------------------------------------------------------"
puts "Tx Packets 	$cs(0.TmtPkt)		|	$cs(1.TmtPkt)"
puts "Rx Packets 	$cs(0.RcvPkt)		|	$cs(1.RcvPkt)"
puts "Collisions	$cs(0.Collision)		|	$cs(1.Collision)"
puts "Recvd Trigger	$cs(0.RcvTrig)		|	$cs(1.RcvTrig)"
puts "CRC Errors	$cs(0.CRC)		|  	$cs(1.CRC)"
puts "------------------------------------------------------------"

unset cs

#UnLink from the linked chassis
puts "UnLinking now"
LIBCMD NSUnLink
puts "DONE!"
