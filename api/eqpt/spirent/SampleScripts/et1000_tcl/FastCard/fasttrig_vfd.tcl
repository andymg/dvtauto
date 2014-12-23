#############################################################################
# FastTrig&VFD.tcl                                                          #
#                                                                           #
# - Shows how to set up VFDs and trigger on a particular pattern            #
# - Gets the counter data and displays it.                                  #
# NOTE: This script works on the following cards:                           #
#       - SX-72XX / 74XX                                                    #
#       - ML-7710                                                           #
#       - L3-67XX                                                           #
#       - LAN-6100                                                          #
#       - LAN-6101A                                                         #
#       - LAN-3300A / 3301A                                                 #
#       - GX-1420B                                                          #
#       - TokenRing                                                         #
#                                                                           #
#############################################################################


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
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 0
set iPort2 1

set VFD_LENGTH 6
set DATA_LENGTH 98
set BURST_SIZE 25

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# RESET THE CARDS 
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2

#Pause for 1 second
after 1000

# Set a group
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2
LIBCMD HGSetSpeed $SPEED_10MHZ
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $BURST_SIZE $iHub $iSlot $iPort

###################################################################################################
# Fill in background data                                                                         #
#                                                                                                 #
# - Since the default fill is all 0, it's a good idea to fill the background with some other      #
#   pattern, so you can instantly see that your program is writing to the card,                   #
#   and to be able to see the length of your fill pattern.                                        #
# - This sets the entire 60 byte packet length to all A's.                                        #
# - Anything that is not overlaid with a VFD will be A.                                           #
# - If a VFD overlays an area with 0's instead of the intended pattern, you know that the VFD     #
#   is working, but there may be a problem with the structure holding your data.                  #
###################################################################################################

struct_new filldata Int*$DATA_LENGTH

for {set i 0} {$i < $DATA_LENGTH} {incr i} {
      set filldata($i.i) 0xAA
}

#Set the background pattern
LIBCMD HTFillPattern $DATA_LENGTH filldata $iHub $iSlot $iPort

#Unset the structure
unset filldata

######################################################################################################
# Fill in VFD1 data                                                                                  #
#                                                                                                    #
# - Configuration $HVFD_STATIC means the same VFD will be over laid onto every packet.  In this case #
#   we use a loop to fill the structure vfd1Data with all FF (broadcast).                            #
# - The Range value is set to 6.  VFD 1 and 2 have a maximum length of 6 bytes.                      #
# - The offset of 0 bits (note that Offset is in bits - all other parameters are in bytes).          #
# - An Offset of zero bits with a Range of 6 bytes means this VFD will overlay the MAC Destination   #
#   area of the packet as follows (XX indicates non-VFD bytes in packet):                            #
#   FF FF FF FF FF FF XX XX XX XX XX XX etc.                                                         #
######################################################################################################

puts "Setup VFD1"

struct_new vfdstruct HTVFDStructure
set vfdstruct(Configuration) $HVFD_STATIC
set vfdstruct(Range) $VFD_LENGTH
set vfdstruct(Offset) 0

struct_new vfd1Data Int*$VFD_LENGTH
for {set iCount 0} {$iCount < $VFD_LENGTH} {incr iCount} {
      set vfd1Data($iCount.i) 0xFF
}

set vfdstruct(Data) vfd1Data
set vfdstruct(DataCount) 0

#Set VFD_1
LIBCMD HTVFD $HVFD_1 vfdstruct $iHub $iSlot $iPort

#Unset the structure
unset vfd1Data

##############################################################################################################
# Fill in VFD2 data                                                                                          #
#                                                                                                            #
# - Sets up assigning the value to each individual byte.                                                     #
# - Setting Configuration to $HVFD_INCR and DataCount to 10 means the LSB will increment through a cycle     #
#   of 10 and then repeat.                                                                                   #
# - Range is 6 bytes with an Offset of 48 bits, so this VFD will overlay the MAC Source area of the packet.  #
# - VFD 1 and 2 are in reverse order so the VFD pattern in the first four packets will look like this        #
#   (XX indicates non-VFD bytes in packet):                                                                  #
#                                                                                                            #
#    XX XX XX XX XX XX 00 11 22 33 44 55 XX XX XX XX etc.                                                    #
#    XX XX XX XX XX XX 00 11 22 33 44 56 XX XX XX XX etc.                                                    #
#    XX XX XX XX XX XX 00 11 22 33 44 57 XX XX XX XX etc.                                                    #
#    XX XX XX XX XX XX 00 11 22 33 44 58 XX XX XX XX etc.                                                    #
#                                                                                                            #
# - HTVFD is followed by $HFVD_2 to indicate VFD2, and points to the vfdstruct structure that holds the      #
#   configuration settings.                                                                                  #
##############################################################################################################

puts "Setup VFD2"

set vfdstruct(Configuration) $HVFD_INCR
set vfdstruct(Range) $VFD_LENGTH
set vfdstruct(Offset) 48

struct_new vfd2Data Int*$VFD_LENGTH
	set vfd2Data(0.i) 0x55
	set vfd2Data(1.i) 0x44
	set vfd2Data(2.i) 0x33
	set vfd2Data(3.i) 0x22
	set vfd2Data(4.i) 0x11
	set vfd2Data(5.i) 0x00

set vfdstruct(Data) vfd2Data
set vfdstruct(DataCount) 10

#Set VFD_2
LIBCMD HTVFD $HVFD_2 vfdstruct $iHub $iSlot $iPort

#Unset the structure
unset vfd2Data

#######################################################################################################################
# Fill in VFD3 data                                                                                                   #
#                                                                                                                     #
# - VFD3 is used to overlay the type field.                                                                           #
# - Configuration is set to $HVFD_ENABLED (Configuration options are different for VFD 1 and 2 and VFD 3).            #
# - Range of 2 means that we will lay down a 2 byte long VFD in each packet.                                          #
# - Combined with an Offset of 96 bits means it will overlay the EtherType field.                                     #
# - The vfd3Data structure has six elements.                                                                          #
# - Setting the DataCount to 3 means we are calling for three VFDs to be created from the vfd3Data area.              #
#   - Note that DataCount which functions as a cycle counter in VFD1 and VFD2, has a different function in VFD3.      #
#   - In VFD3 DataCount specifies the size of the VFD3 data to divide up.                                             #
#     - For example, if Range was set to 24 and DataCount was set to 96, you would have a cycle of four               #
#       different 24 byte packets. There are no errors if these are not divided exactly.  You could, for example      #
#       have a Range of 10 with a vfd3Data structure of 1000 elements. Setting DataCount 100 would generate 10        #
#       different packets.  Setting it to 50 would result in 5 different packets.  Setting is to 5 would create       #
#       10 byte VFDs with the first five bytes of the vfd3Data area repeated in each VFD.                             #
# - In this example, this setup will generate a repeating pattern of three VFD3 overlaying the Ethertype area         #
#   emulating a cycle of an IP packet (0800) followed by an SNMP packet (814C), followed by a Novell packet (8137)    #
#   and then repeating.                                                                                               #
# - VFD3 is in opposite order compared to VFD1 and VFD2.                                                              #
# - First four packets will look like this (XX indicates non-VFD bytes in packet):                                    #
#                                                                                                                     #
#   XX XX XX XX XX XX XX XX XX XX XX XX 08 00 XX XX etc                                                               #
#   XX XX XX XX XX XX XX XX XX XX XX XX 81 4C XX XX etc                                                               #
#   XX XX XX XX XX XX XX XX XX XX XX XX 81 37 XX XX etc                                                               #
#   XX XX XX XX XX XX XX XX XX XX XX XX 08 00 XX XX etc                                                               #
#                                                                                                                     #
# - HTVFD is followed by $HFVD_3 to indicate VFD3 and points to the vfdstruct structure that holds the                #
#   configuration settings.                                                                                           #
#######################################################################################################################

puts "Setup VFD3"

set vfdstruct(Configuration) $HVFD_ENABLED
set vfdstruct(Range) 2
set vfdstruct(Offset) 96

struct_new vfd3Data Int*6
	set vfd3Data(0.i) 0x08
	set vfd3Data(1.i) 0x00
	set vfd3Data(2.i) 0x81
	set vfd3Data(3.i) 0x4C
	set vfd3Data(4.i) 0x81
	set vfd3Data(5.i) 0x37

set vfdstruct(Data) vfd3Data
set vfdstruct(DataCount) 6

#Set VFD_3 on the card
HTVFD $HVFD_3 vfdstruct $iHub $iSlot $iPort

#Unset the structure
unset vfd3Data
unset vfdstruct



##############################################################################################################################
# Set trigger                                                                                                                #
#                                                                                                                            #
# - Setting offset to 96 bits and setting the Range to 2 will trigger on the two byte Ethertype                              #
# - Note that the LSB of the trigger is always Pattern.0, so this combination will trigger whenever the first two bytes      #
#   are 81 37 (IPX).                                                                                                         #
# - Since VFD3 is set to cycle through three Ethertypes 0800, 814C and 8137 we will trigger on every 3rd packet transmitted. #
##############################################################################################################################

struct_new MyTrigger HTTriggerStructure

set MyTrigger(Offset) 96
set MyTrigger(Range) 2
set MyTrigger(Pattern.0) 0x37
set MyTrigger(Pattern.1) 0x81

LIBCMD HGTrigger $HTTRIGGER_1 $HTTRIGGER_ON MyTrigger

#Unset Mytrigger
unset MyTrigger

# Transmit Data from card 1 to card 2
HTRun $HTRUN $iHub $iSlot $iPort

# Allow time for the packets to be transmitted
after 1000

# Get and display counter data and create an array of counter structures

struct_new cs HTCountStructure*2

# Do a priming read then wait until transmission rate is zero.  Keep taking readings every 0.1 seconds.
LIBCMD HGGetCounters cs

while {$cs(0.TmtPktRate) != 0} {
        LIBCMD HGGetCounters cs
        after 100 
}

puts "     *****************************************************"
puts "                          COUNTER DATA"
puts "     *****************************************************"
puts "     Card $iSlot Tx Pkts $cs(0.TmtPkt)"
puts "         			Card $iSlot2 Rx Pkts 	   $cs(1.RcvPkt)"
puts "	       			Card $iSlot2 Rx Triggers $cs(1.RcvTrig)"
puts "     *****************************************************" 
puts ""
puts ""
puts ""

#Unset the structure
unset cs

#UnLink from the chassis 
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"