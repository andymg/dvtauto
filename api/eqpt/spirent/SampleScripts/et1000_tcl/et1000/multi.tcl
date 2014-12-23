# MULTI.TCL
# ET1000 program that sets up a 14 byte VFD, sets up a 12 byte matching trigger
# sets up counter strucuture with Multi Function counter set on Port B to count
# received triggers, then transmits TX_NUM packets one at a time, then displays 
# the number of packets captured, displays the captured frames and the counter data.
#
# The user can change the trigger values, background fill, VFD position etc.
#
# This program will not run on a SMB1000 or SMB2000.  ET1000 only.
#
############################################################################## 

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
     set retval [ETSocketLink $ipaddr 16385]  
     if {$retval < 0 } {
	puts "Unable to connect to $ipaddr. Please try again."
	exit
	}
}

set PACKET_LENGTH 60
set TX_NUM 10
set TRIGGER_BYTES 6
set TRIGGER_BITS 48
set CRC 4
set DISPLAY_FRAMES 3

LIBCMD ETDataLength $PACKET_LENGTH

#Set background to all AA so we know the default state.
LIBCMD ETDataPattern $ETDP_5555

#tranmit on Port A
LIBCMD ETSetSel $ETSELA

################################################
# Offset is bits from the start of the packet
# Range is the length also in bits. Note this 
# is not the same as SMB1000/2000
#
# This will match a MAC Destination
# of 00 00 00 00 00 00
# which will be the first packet transmitted only
# See VFD setup below which will generate a MAC
# Destination pattern of 00 00 00 00 00 00 for the
# first packet only.
################################################
struct_new trigger TriggerStructure
  set trigger(Offset) 00
  set trigger(Range) $TRIGGER_BITS
  for {set i 0} {$i < $TRIGGER_BYTES} {incr i} {
	set trigger(Pattern.$i) 0
  }

LIBCMD ETReceiveTrigger trigger
LIBCMD ETMFCounter $MFPORT_B $ETMF_RXTRIG_COUNT

############################################
#set up counter structure
############################################
struct_new count CountStructure

############################################
#set up capture buffer and Capture Strucuture
############################################
struct_new capdata Int*[expr $PACKET_LENGTH + $CRC]

struct_new cs CaptureStructure
  set cs(Filter) $CAPTURE_ANY
  set cs(Port) $PORT_B
  set cs(BufferMode) $BUFFER_ONESHOT
  set cs(TimeTag) $TIME_TAG_OFF
  set cs(Mode) $CAPTURE_ENTIRE_PACKET

LIBCMD ETCaptureParams cs
#################################################
# Set up VFD
# On first pass we set all bytes to zero
# Then we statically set the #0 through #3 elements
# to 0 1 2 3 (so you can see the byte order in the
# capture)
# For a 14 byte field this will generate a first
# VFD of  00 00 00 00 00 00 00 00 00 00 03 02 01 00
#
# Note that the elements count from right to left
#
# Finally we set #8 element to increment by 2 and
# the #2 element to increment by 1
#   Packet Pattern (first three packets)
#  00 00 00 00 00 00 00 00 00 00 00 03 02 01 00 55 55 55
#  00 00 00 00 00 02 00 00 00 00 00 03 03 01 00 55 55 55
#  00 00 00 00 00 04 00 00 00 00 00 03 04 01 00 55 55 55
######################################################
if {[ETGetVFDRun] > 0} {
  LIBCMD ETVFDRun $ETVFD_DISABLE
}

struct_new VFD VFDStructure
after 2000
	for {set x 0} { $x < 14 } {incr x} {
		set VFD(Start.$x) 0
	}
		  set VFD(Start.3) 3
		  set VFD(Start.2) 2
	set VFD(Start.1) 1
	set VFD(Start.0) 0
	set VFD(Increment.8) 2
	set VFD(Increment.2) 1
	set VFD(Range) 14
	set VFD(Offset) 0
LIBCMD ETVFDParams VFD

LIBCMD ETVFDRun $ETVFD_ENABLE

###########################################
# turn off Burst Mode and start Capture
###########################################
LIBCMD ETBurst $ETBURST_OFF 10
LIBCMD ETCaptureRun

###########################################
# Send TX_NUM of packets one at a time
###########################################
for {set i 0} {$i < $TX_NUM} {incr i} {
LIBCMD ETRun $ETSTEP
}

################################################
# Stop capture and wait a second
################################################
set cs(Mode) $CAPTURE_OFF
after 1000

################################################
#Get and display the number of packets captured
################################################
set MAX_PACKETS [ETGetCapturePacketCount]
puts "Captured $MAX_PACKETS Packets"

################################################
# Get Captured Packets and display one at a time
# with formatting
# ETGetCapturePacket gets the packet itself
# (number of packet is current counter number
################################################
for {set i 0} {$i < $MAX_PACKETS} { incr i} {
	LIBCMD ETGetCapturePacket $i capdata [expr $PACKET_LENGTH + $CRC]
		  puts ""
#        puts "---------"
		  puts "Packet $i"
		  puts "---------"
		  for {set j 0} {$j < [expr $PACKET_LENGTH + $CRC]} {incr j} {
					 if {[expr $j % 16] == 0} {                      ;# if divisible by 16
								puts ""                                 ;# start a new line with
								puts -nonewline [format "%4i:   " $j]   ;# the byte number
					 }
					 puts -nonewline " "                              ;#space in front
					 puts -nonewline [format "%02X" $capdata($j.i)]           ;# 2 digits leading 0
		  }
		  puts ""
		  if {[expr $i % $DISPLAY_FRAMES] == 0 } {                 ;#stop scrolling
				 puts ""
				 puts "Press ENTER key to continue"
				 gets stdin response
			}

}
#####################################################
# Get Counter data from ET1000 and display for user
#####################################################
LIBCMD ETGetCounters count
puts ""
puts "************************************************************"
puts " 		ET1000 Counter Data Summary"
puts "------------------------------------------------------------"
puts "   		Port A		Port B"
puts "------------------------------------------------------------"
puts "Tx Packets 	  $count(TXAEvent)		  $count(TXBEvent)"
puts "Rx Packets 	  $count(RXAEvent) 		  $count(RXBEvent)"
puts "Rx Trigger 			  $count(MFBEvent)"
puts "************************************************************"
unset VFD
unset cs
unset capdata
unset count
unset trigger

ETUnLink
