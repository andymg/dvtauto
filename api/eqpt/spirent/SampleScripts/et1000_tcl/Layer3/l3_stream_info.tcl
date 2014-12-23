#########################################################################
#L3_STREAM_INFO.TCL                                                     #
#                                                                       #
# - Sets up 1 IP stream on a L3 Card and then reads back and displays   #
#   the card data on a ML-7710.                                         #
#                                                                       #
# NOTE: This script works on the following cards:                       #
#       - L3-67XX                                                       #
#       - ML-7710                                                       #
#       - ML-5710                                                       #
#       - LAN-6101A                                                     #
#       - LAN-6201A                                                     #
#       - LAN-3300A                                                     #
#       - LAN-3310A                                                     #
#       - POS-6500 / 6502                                               #
#       - POS-3505A / 3504A                                             #
#                                                                       #
#########################################################################


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

#Set the default 
set iHub 0
set iSlot 0
set iPort 0

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

set STREAM 1

###########################################################
# Set up base IP stream with L3_DEFINE_IP_STREAM          #
#                                                         #
# - Numbers are chosen to make the data field locations   #
#   more obvious in the display.                          #
#   Dest MAC is 06 07 05 04 03 02                         #
#   Source MAC is 05 04 03 02 01 00 and so on.            #
###########################################################

#Declare a new structure and set up IP streams on the card
struct_new streamIP StreamIP

set streamIP(ucActive) [format %c 1]
set streamIP(ucProtocolType) [format %c $L3_STREAM_IP]
set streamIP(uiFrameLength) 100
set streamIP(ucRandomLength) [format %c 1]
set streamIP(ucTagField) [format %c 1]
set streamIP(DestinationMAC.0.uc) [format %c 6]
set streamIP(DestinationMAC.1.uc) [format %c 7]
set streamIP(DestinationMAC.2.uc) [format %c 5]
set streamIP(DestinationMAC.3.uc) [format %c 4]
set streamIP(DestinationMAC.4.uc) [format %c 3]
set streamIP(DestinationMAC.5.uc) [format %c 2]
set streamIP(SourceMAC.0.uc) [format %c 5]
set streamIP(SourceMAC.1.uc) [format %c 4]
set streamIP(SourceMAC.2.uc) [format %c 3]
set streamIP(SourceMAC.3.uc) [format %c 2]
set streamIP(SourceMAC.4.uc) [format %c 1]
set streamIP(SourceMAC.5.uc) [format %c 0]
set streamIP(TimeToLive) [format %c 10]
set streamIP(DestinationIP.0.uc) [format %c 0x11]
set streamIP(DestinationIP.1.uc) [format %c 0x22]
set streamIP(DestinationIP.2.uc) [format %c 0x33]
set streamIP(DestinationIP.3.uc) [format %c 0x44]
set streamIP(SourceIP.0.uc) [format %c 0x55]
set streamIP(SourceIP.1.uc) [format %c 0x66]
set streamIP(SourceIP.2.uc) [format %c 0x77]
set streamIP(SourceIP.3.uc) [format %c 0x88]
set streamIP(Netmask.0.uc) [format %c 0xAA]
set streamIP(Netmask.1.uc) [format %c 0xBB]
set streamIP(Netmask.2.uc) [format %c 0xCC]
set streamIP(Netmask.3.uc) [format %c 0]
set streamIP(Gateway.0.uc) [format %c 0xDD]
set streamIP(Gateway.1.uc) [format %c 0xEE]
set streamIP(Gateway.2.uc) [format %c 0xFF]
set streamIP(Gateway.3.uc) [format %c 0x00]
set streamIP(Protocol) [format %c 4]

# Set the stream on the card at $iHub $iSlot $iPort#
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#Unset the structure
unset streamIP

##############################################################################################
# - Check for number of streams using L3_DEFINED_STREAM_COUNT_INFO                           #
# - Only one stream is set up                                                                #
# - There is one non-transmitting stream always on the card used to hold card data so the    #
#   count of transmitting streams will always be one less than the total reported.           #
##############################################################################################

#Declare a new sructure
struct_new CountStream ULong

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 CountStream 0 $iHub $iSlot $iPort
if { $CountStream(ul)  < 2 } {
	puts "No streams on card"
}

#Unset the structure
unset CountStream


# - Set up a SmartBits type structure to hold card configuration data.               
# - All streams use the SmartBits type for the L3_STREAM_INFO command                

struct_new SB StreamSmartBits

# Get stream data for stream 1, count 1    
# Stream 0 is the "hidden" stream         

#Get the stream info
LIBCMD HTGetStructure $L3_STREAM_INFO $STREAM 0 0 SB 0 $iHub $iSlot $iPort

#Display the type of the stream
puts ""
puts "Stream $STREAM"
puts -nonewline " Stream type is "

	switch [ConvertCtoI $SB(ucProtocolType)] {

	0 { puts "SmartBits"}
	2 { puts "IP"}
	3 { puts "IPX"}
	4 { puts "UDP"}
	5 { puts "ARP"}
	8 { puts "TCP"}

	default {puts "unknown"}
	}
#Disply the length of the frame
puts " Frame length is $SB(uiFrameLength) bytes"

# ProtocolHeader area will contain the ENet and IP data fields.
puts ""
puts "-----------------------------------------"
puts "       Protocol Data     "
puts "-----------------------------------------"
for {set i 0} {$i < 64} {incr i} {
      if { [expr $i % 16] == 0 } {
	   puts ""
      }

      set MyByte [ConvertCtoI $SB(ProtocolHeader.$i.uc)]
      puts -nonewline " [format %02X  $MyByte] "
}

puts ""

#Unset the structure
unset SB

#UnLink from the chassis
puts "Unlinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"

