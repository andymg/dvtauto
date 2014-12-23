###########################################################################################
# L3_TCP.tcl                                                                         #
#                                                                                         #
# - Sets up a single stream on each of two cards.                                         #
# - Card iSlot is connected to a router port 10.1.1.1 and has a stream IP of 10.1.1.10    #
#   and a MAC address of 00 00 00 00 00 01.                                               #
# - Card iSlot2 is connected to a router port of 10.2.1.1 with a stream IP of 10.2.1.10   #
#   with a MAC address of 00 00 00 00 00 02.                                              #
#                                                                                         #
# - We set the router port (gateway) IP in the stream so we don't need to set             #
#   the L3 address parameters.                                                            #
#                                                                                         #
# - We arp for the router MAC then transmit a single burst from card 1 to card 2          #
#   and display the capture data.                                                         #
#                                                                                         #
# NOTE: This script works on the following cards:                                         #
#       - ML-7710                                                                         #
#       - LAN-6101A                                                                       #
#                                                                                         #]
###########################################################################################

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

set iHub2 0
set iSlot2 1
set iPort2 0


set burstCount 5
set dataLength 60


##################   PROCEDURES  ##############################


#####################################################################
# Wait_for_input                                                    #
# Pause routine that allows user to view error messages             #
#####################################################################

proc wait_for_input {} {

   puts "Press ENTER to continue"
   gets stdin response
   return $response
}

# reset_capture   start capture
proc reset_capture { H S P } {

global NS_CAPTURE_SETUP NS_CAPTURE_START

# Capture set up
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $H $S $P
unset cap

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $H $S $P

}

proc display_count {H S P} {

   struct_new cs HTCountStructure

   # do a priming read and wait 1/2 second
   HTGetCounters cs $H $S $P
   after 500

   # wait while we are still sending or receiving packets
   while { ($cs(RcvPktRate) !=0) || ($cs(TmtPktRate) !=0) } {
           after 100
           LIBCMD HTGetCounters cs  $H $S $P
    } 

    # wait another 1/2 second and take final read
    after 500
    LIBCMD HTGetCounters cs  $H $S $P

    puts "--------------------------------------"
    puts "	   Test Results"
    puts "--------------------------------------"
    puts "    	        Card [expr $S + 1]	"
    puts "--------------------------------------"
    puts "Tx Packets 	$cs(TmtPkt)		"
    puts "Rx Packets 	$cs(RcvPkt)		"
    puts "Collisions	$cs(Collision)		"
    puts "Recvd Trigger	$cs(RcvTrig)		"
    puts "CRC Errors	$cs(CRC)		"
    puts "--------------------------------------"
    puts "Oversize 	$cs(Oversize) 		"
    puts "Undersize	$cs(Undersize) 		"
    puts "--------------------------------------"
}


proc display_capture {H S P {output stdout} } {

   # Stop capture
   LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $H $S $P

   struct_new CapCount NSCaptureCountInfo
   LIBCMD HTGetStructure $::NS_CAPTURE_COUNT_INFO 0 0 0 CapCount 0 $H $S $P
   if {$CapCount(ulCount) < 1} {
        puts $output "No packets captured on card [expr $S + 1]"
   } else {
            puts $output "Displaying $CapCount(ulCount) packets captured on card [expr $S + 1]"

            struct_new CapData NSCaptureDataInfo

            for {set i 0} {$i < $CapCount(ulCount)} {incr i} {
                  set CapData(ulFrameIndex)      $i
                  LIBCMD HTGetStructure $::NS_CAPTURE_DATA_INFO 0 0 0 CapData 0 $H $S $P
                  puts $output ""   
                  puts $output "---------"
                  puts $output "FRAME $i"
                  puts $output "---------"
                  for {set j 0} {$j < $CapData(ulRetrievedLength)} {incr j} {
                        if {[expr $j % 16] == 0} {
                             puts $output ""
                             puts -nonewline $output [format "%4i:   " $j]
                  }

                  puts -nonewline $output " [format "%02X" $CapData(ucData.$j._ubyte_)]"    
                   
             }

             puts $output "\n"

             if {$output == "stdout"} {
                  puts "Press ENTER key to continue, Q to quit"
                  gets stdin response

             if {$response == "Q" || $response == "q"} {
	          break
	     }
          }
      }
   }
   unset CapCount 
   unset CapData 
}


##################   MAIN PROGRAM   ########################

# Reserve and reset cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

LIBCMD HTResetPort $::RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $::RESET_FULL $iHub2 $iSlot2 $iPort2	

# We use the slot numbers of iHub and iHub2 to setup the addresses.  We add
# 1 to the slot numbers to avoid 0's in the addresses.
struct_new streamTCP StreamTCP
        set streamTCP(ucActive) 1
        set streamTCP(ucProtocolType) $STREAM_PROTOCOL_TCP
        set streamTCP(uiFrameLength) $dataLength
        set streamTCP(ucTagField) 1
        set streamTCP(DestinationMAC.0) 0x00
        set streamTCP(DestinationMAC.1) 0x00
        set streamTCP(DestinationMAC.2) 0x00
        set streamTCP(DestinationMAC.3) 0x00
        set streamTCP(DestinationMAC.4) 0x00
        set streamTCP(DestinationMAC.5) [expr $iSlot2 + 1]
	set streamTCP(SourceMAC.0) 0x00
	set streamTCP(SourceMAC.1) 0x00
	set streamTCP(SourceMAC.2) 0x00
	set streamTCP(SourceMAC.3) 0x00
	set streamTCP(SourceMAC.4) 0x00
	set streamTCP(SourceMAC.5) [expr $iSlot + 1]
        set streamTCP(TimeToLive) 64
	set streamTCP(TypeOfService) 0
	set streamTCP(InitialSequenceNumber) 0
        set streamTCP(DestinationIP.0) 10
        set streamTCP(DestinationIP.1) [expr $iSlot2 + 1]
        set streamTCP(DestinationIP.2) 1
        set streamTCP(DestinationIP.3) 10
        set streamTCP(SourceIP.0) 10
        set streamTCP(SourceIP.1) [expr $iSlot + 1] 
        set streamTCP(SourceIP.2) 1
        set streamTCP(SourceIP.3) 10
        set streamTCP(Netmask.0) 255
        set streamTCP(Netmask.1) 255
        set streamTCP(Netmask.2) 255
        set streamTCP(Netmask.3) 0
        set streamTCP(Gateway.0) 10
        set streamTCP(Gateway.1) [expr $iSlot + 1]
        set streamTCP(Gateway.2) 1
        set streamTCP(Gateway.3) 1
	set streamTCP(SourcePort) 112
	set streamTCP(DestPort) 885
	set streamTCP(Window) 20
	set streamTCP(Flags) 0

LIBCMD HTSetStructure $L3_DEFINE_TCP_STREAM 0 0 0 streamTCP 0 $iHub $iSlot $iPort

# reverse source and destination to make a mirror copy for card 2
        set streamTCP(DestinationMAC.5) [expr $iSlot + 1] 
        set streamTCP(SourceMAC.5) [expr $iSlot2 + 1]
        set streamTCP(DestinationIP.1) [expr $iSlot + 1] 
        set streamTCP(SourceIP.1) [expr $iSlot2 + 1]  
        set streamTCP(Gateway.1) [expr $iSlot2 + 1] 
LIBCMD HTSetStructure $L3_DEFINE_TCP_STREAM 0 0 0 streamTCP 0 $iHub2 $iSlot2 $iPort2

unset streamTCP

# Send ARPS from all streams configured
LIBCMD HTSetCommand $L3_START_ARPS 0 0 0 "" $iHub $iSlot $iPort
LIBCMD HTSetCommand $L3_START_ARPS 0 0 0 "" $iHub2 $iSlot2 $iPort2

reset_capture $iHub2 $iSlot2 $iPort2

LIBCMD HTClearPort $iHub $iSlot $iPort
LIBCMD HTClearPort $iHub2 $iSlot2 $iPort2

# set transmission parameters
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $burstCount $iHub $iSlot $iPort
LIBCMD HTRun $HTRUN  $iHub $iSlot $iPort
 

puts "Counts for card [expr $iSlot + 1]"
display_count $iHub $iSlot $iPort
wait_for_input

puts "Counts for card [expr $iSlot2 + 1]"
display_count $iHub2 $iSlot2 $iPort2
wait_for_input

puts "Displaying packets captured on card [expr $iSlot2 + 1]"
display_capture $iHub2 $iSlot2 $iPort2

puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"

