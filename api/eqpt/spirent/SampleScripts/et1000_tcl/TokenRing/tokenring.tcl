#########################################################################
#                                                                       #
# TokenRing.tcl                                                         #
#                                                                       #
# Simple Tcl program that illustrates setting Tx parameters             #
# and VFD1 and VFD2 on a Netcom Systems TR-8405 Token Ring Card         #
#                                                                       #
# NOTE: This script works on the following cards:                       #
#       - TokenRing                                                     #
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
     set retval [ETSocketLink $ipaddr 16385]  
     if {$retval < 0 } {
	puts "Unable to connect to $ipaddr. Please try again."
	exit
	}
}

set iHub 0
set iSlot 0
set iPort 0
set VFD_LENGTH 6

#########################################################
# Set up card transmission parameters
# RESET_PARTIAL will reset all parameters without de-inserting
# card from ring.  RESET_ALL will de-insert card and is 
# not recommended for Token Ring.
#########################################################
LIBCMD HTResetPort $RESET_PARTIAL $iHub $iSlot $iPort

# Set TR PRoperties in this structure.....
struct_new MyTRP TokenRingPropertyStructure
 set MyTRP(SpeedSetting) $TR_SPEED_16MBITS
 set MyTRP(EarlyTokenRelease) $TR_TOKEN_DEFAULT
 set MyTRP(DuplexMode) $TR_DUPLEX_HALF
 set MyTRP(DeviceOrMAUMode) $TR_MODE_MAU

#....and then send structure data to TR card
LIBCMD HTSetTokenRingProperty MyTRP $iHub $iSlot $iPort

# free resources
unset MyTRP

###########################################################
# Setup VFDs
###########################################################
# fill in VFD1 data
# Configuration $HVFD_STATIC means the same VFD will be over
# laid onto every packet.  In this case we use a loop to 
# fill the structure vfd1Data with all FF (broadcast).
# The Range value is set to 6.  VFD 1 and 2 have a maximum 
# length of 6 bytes.
# The offset is 16 bits (note that Offset is in bits - all other
# parameters are in bytes).  An Offset of 16 bits with a Range
#  of 6 bytes means this VFD will overlay the MAC Destination
# area of the Token Ring Packet packet as follows - 
# (XX indicates non-VFD bytes in packet ZZ indicates the Access 
# Control and Frame Control Bytes - VFDs will not overwrite these
# bytes):
#  ZZ ZZ FF FF FF FF FF FF XX XX XX XX XX XX etc.
###########################################################
puts "Setup VFD1"

struct_new vfdstruct HTVFDStructure
set vfdstruct(Configuration) $HVFD_STATIC
set vfdstruct(Range) $VFD_LENGTH
set vfdstruct(Offset) 16

struct_new vfd1Data Int*$VFD_LENGTH
for {set iCount 0} {$iCount < $VFD_LENGTH} {incr iCount} {
	set vfd1Data($iCount.i) 0xFF
}

set vfdstruct(Data) vfd1Data
set vfdstruct(DataCount) 0
LIBCMD HTVFD $HVFD_1 vfdstruct $iHub $iSlot $iPort
unset vfd1Data

###########################################################
# fill in VFD2 data
# This one gets set up assigning the value to each individual
# byte.
# Setting Configuration to $HVFD_INCR and DataCount to 10 
# means the LSB will increment through a cycle of 10 and
# then repeat.
# Range is 6 bytes with an Offset of 64 bits, so this VFD
# will overlay the MAC Source area of the Token Ring packet.
# VFD 1 and 2 are in reverse order so the VFD pattern in the 
# first four packets will look like this (XX indicates non-VFD 
# bytes in packet - ZZ indicates the Access Control and Frame
# Control Bytes):
# ZZ ZZ XX XX XX XX XX XX 00 11 22 33 44 55 XX XX XX XX etc.
# ZZ ZZ XX XX XX XX XX XX 00 11 22 33 44 56 XX XX XX XX etc.
# ZZ ZZ XX XX XX XX XX XX 00 11 22 33 44 57 XX XX XX XX etc.
# ZZ ZZ XX XX XX XX XX XX 00 11 22 33 44 58 XX XX XX XX etc.
#
# HTVFD is followed by $HFVD_2 to indicate VFD2 and points
# to the vfdstruct structure that holds the configuration
# settings.
###########################################################
puts "Setup VFD2"

set vfdstruct(Configuration) $HVFD_INCR
set vfdstruct(Range) $VFD_LENGTH
set vfdstruct(Offset) 64

struct_new vfd2Data Int*$VFD_LENGTH
	set vfd2Data(0.i) 0x55
	set vfd2Data(1.i) 0x44
	set vfd2Data(2.i) 0x33
	set vfd2Data(3.i) 0x22
	set vfd2Data(4.i) 0x11
	set vfd2Data(5.i) 0x00

set vfdstruct(Data) vfd2Data
set vfdstruct(DataCount) 10
LIBCMD HTVFD $HVFD_2 vfdstruct $iHub $iSlot $iPort

unset vfd2Data
unset vfdstruct

ETUnLink
