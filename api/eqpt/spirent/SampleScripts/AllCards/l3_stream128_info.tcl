#########################################################################
#L3_STREAM128_INFO.TCL                                                  #
#                                                                       #
# - Sets up 1 IPv6 stream on a L3 Card and then reads back and displays #
#   the card data.                                                      #
#                                                                       #
#  This sample script works on all cards that support IPV6(currently    #
#  LAN6101 and all TeraMetric cards.                                    #
#  L3_STREAM_128_INFO command works on all cards                        #
#                                                                       #
#########################################################################
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

set STREAM 1
set DataLength 100

# Reserve the card
LIBCMD HTSlotReserve $iHub $iSlot

#######################################################################
# Set up an IPV6 stream with L3_DEFINE_IPV6_STREAM                    #
#######################################################################


puts "Defining IPv6 stream ..."

#Declare IP stream structure
struct_new streamIPv6 StreamIPv6

#Define IPv6 stream contents
set streamIPv6(ucActive) 1
set streamIPv6(ucProtocolType) $STREAM_PROTOCOL_IPV6
set streamIPv6(uiFrameLength) $DataLength
set streamIPv6(ucTagField) 1

set streamIPv6(DestinationMAC) {1 1 1 1 1 1}
set streamIPv6(SourceMAC) {6 6 6 6 6 6}
set streamIPv6(DestinationIP) {0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA 0xAA}
set streamIPv6(SourceIP) {0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB 0xBB}
set streamIPv6(RouterIP) {0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC 0xCC}
set streamIPv6(ucNextHeader) 60
set streamIPv6(ucTrafficClass) 0
set streamIPv6(ucHopLimit) 64
set streamIPv6(ulFlowLabel) 0
set streamIPv6(ucPayloadLengthError) 0  

LIBCMD HTSetStructure $L3_DEFINE_IPV6_STREAM 0 0 0 streamIPv6 0 $iHub $iSlot $iPort
unset streamIPv6

#######################################################################
# Check for number of streams using L3_DEFINED_STREAM_COUNT_INFO      #
# This sample only sets up only one stream.                           #
# There is one non-transmitting  stream always on the card used to    #
# hold card data so the count of transmitting streams will always be  #
# one less than the total reported.                                   #
#######################################################################

struct_new StreamCount  ULong

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort
if { $StreamCount(ul)  < 2 } {
     puts "No streams on card"
}

 unset StreamCount

#######################################################################
# Use StreamSmartBits128 to readback stream configuration for all     #
# stream types.                                                       #
#######################################################################

struct_new SB128 StreamSmartBits128

#######################################################################
# Get stream data for stream 1 count 1     			      #
# Stream 0 is the "hidden" stream          			      #
#######################################################################

LIBCMD HTGetStructure $L3_STREAM_128_INFO $STREAM 0 0 SB128 0 $iHub $iSlot $iPort

puts ""
puts "Stream $STREAM"

puts -nonewline " Stream type is "
	switch $SB128(ucProtocolType) {
	0 { puts "SmartBits"}
	2 { puts "IP"}
	3 { puts "IPX"}
	4 { puts "UDP"}
	5 { puts "ARP"}
	8 { puts "TCP"}
	10 { puts "TCP_VLAN"}
	15 { puts "FC"}
	16 { puts "IPV6"}
	17 { puts "UDP_IPV6"}
	18 { puts "TCP_IPV6"}
	19 { puts "IPV6_VLAN"}
	20 { puts "UDP_IPV6_VLAN"}
	21 { puts "TCP_IPV6_VLAN"}
	default {puts "unknown"}
	}
puts " Frame length is $SB128(uiFrameLength) bytes"

#######################################################################
# ProtocolHeader area will contain the IP/IPV6 data fields.           #
#######################################################################
puts ""
puts "-----------------------------------------"
puts "       Protocol Data     "
puts "-----------------------------------------"
for {set i 0} {$i < 128} {incr i} {
	if { [expr $i % 16] == 0 } {
		puts ""
	}
	set MyByte $SB128(ProtocolHeader.$i)
	puts -nonewline " [format %02X  $MyByte] "
}
puts ""
unset SB128

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
