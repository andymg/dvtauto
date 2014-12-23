###########################################################################################
# ETVFD_CYCLE.TCL
# 
# This script sets up VFD data and transmits some data.
#
#
###########################################################################################
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

set DATA_LENGTH 128
set VFD_LENGTH 12
set BURST_LENGTH 10
set NUM_BURST 5

# set packet length
LIBCMD ETDataLength $DATA_LENGTH

#set background data pattern to all 5's
LIBCMD ETDataPattern $ETDP_5555

##########################################################################################
# Setup VFDStructure
# Sets up new structure named vfd_data which is VFD_LENGTH (defined as 12 bytes above) long
# starting 48 bits into the packet.
# The for loop initializes the starting pattern to 0B 0A 09 08 07 06 05 04 03 02 01 00
# since position 0 in the VFD is the LSB.
# Afterwards the increment vlaue for the first 3 bytes is set.  The LSB is set to increment
# by 1 for the LSB (00 01 02...) by 2 for the next byte (01 03 05 07...) and by 16 (10 hex)
# for the next byte (02 12 22 32...)
##########################################################################################
struct_new vfd_data VFDStructure
set vfd_data(Offset) 48
set vfd_data(Range) $VFD_LENGTH
for {set i 0} {$i < $VFD_LENGTH} {incr i} {
	 set vfd_data(Start.$i) $i
}
set vfd_data(Increment.0) -1
set vfd_data(Increment.1) 2
set vfd_data(Increment.2) 16

# Send  VFD data to card
LIBCMD ETVFDParams vfd_data

# free structure
unset vfd_data

# Transmit on A, Receive on B
LIBCMD ETSetSel $ETSELA

# Turn VFD on
LIBCMD ETVFDRun $ETVFD_ENABLE

# Turn Burst mode off
LIBCMD ETBurst $ETBURST_OFF $BURST_LENGTH

for { set Count 0 } { $Count < $NUM_BURST } { incr Count } {
  LIBCMD ETRun $ETSTEP
}


ETUnLink






