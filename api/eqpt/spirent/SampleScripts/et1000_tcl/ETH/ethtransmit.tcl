####################################################################################################
# ETHTransmit.tcl                                                                                  #
#                                                                                                  #
# This script works on the following cards:                                                        #
# - SX-72XX                                                                                        #
# - SX-74XX                                                                                        #
# - L3_67XX                                                                                        #
# - ML-7710                                                                                        #
# - ML-5710                                                                                        #
# - LAN-6101A                                                                                      #
# - LAN-6100                                                                                       #
#                                                                                                  #
# - Some values like ucSpeed will not accept 0 as a value(will generate a -5 out of range error).  #
# - Be sure to use format command on uc values.  Failure to do so can also cause -5 errors.        #
#                                                                                                  #
####################################################################################################


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

set VFD3DATA_COUNT 40

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

#Declare a structure
struct_new MyETHTransmit ETHTransmit

   set MyETHTransmit(ucTransmitMode) [format %c $MULTI_BURST_MODE]
   set MyETHTransmit(uiDataLength) 60
   set MyETHTransmit(ucDuplexMode) [format %c $HALFDUPLEX_MODE]
   set MyETHTransmit(ucSpeed) [format %c $SPEED_10MHZ]
   set MyETHTransmit(uiCollisionBackoffAggressiveness) 10

   puts "Send 5 bursts of 20 packets.."
   # 5 bursts of 20 packets each
   set MyETHTransmit(ulBurstCount) 20
   set MyETHTransmit(ulMultiBurstCount) 5

   # 9600 $NANO_SCALE is minimum at 10Mbit/S, 
   # 960 would be wire speed at 100Mbit/s
   set MyETHTransmit(ulInterFrameGap) 960
   set MyETHTransmit(uiInterFrameGapScale) $NANO_SCALE

   puts "Gap between bursts is set to 10 mS"
   # gap between bursts is 10 mS
   set MyETHTransmit(ulInterBurstGap) 10
   set MyETHTransmit(uiInterBurstGapScale) $MILLI_SCALE

   # disable random fill and length
   set MyETHTransmit(ucRandomBackground) [format %c 0] 
   set MyETHTransmit(ucRandomLength) [format %c 0]

   # disable all error generation
   set MyETHTransmit(ucCRCErrors) [format %c 0]
   set MyETHTransmit(ucAlignErrors) [format %c 0]
   set MyETHTransmit(ucSymbolErrors) [format %c 0]
   set MyETHTransmit(uiDribbleBits) 0

   puts "Setting up Vfd1"
   # set up VFD1
   set MyETHTransmit(ucVFD1Mode) [format %c $HVFD_INCR]
   set MyETHTransmit(uiVFD1Offset) 0
   set MyETHTransmit(iVFD1Range) 6
   set MyETHTransmit(ucVFD1Pattern.0.uc) [format %c 0x06]
   set MyETHTransmit(ucVFD1Pattern.1.uc) [format %c 0x05]
   set MyETHTransmit(ucVFD1Pattern.2.uc) [format %c 0x04]
   set MyETHTransmit(ucVFD1Pattern.3.uc) [format %c 0x03]
   set MyETHTransmit(ucVFD1Pattern.4.uc) [format %c 0x02]
   set MyETHTransmit(ucVFD1Pattern.5.uc) [format %c 0x01]
   set MyETHTransmit(uiVFD1CycleCount) 10
   set MyETHTransmit(uiVFD1BlockCount) 1

   puts "Setting up Vfd2"
   # set VFD2 - same as VFD1
   set MyETHTransmit(ucVFD2Mode) [format %c $HVFD_STATIC]
   set MyETHTransmit(uiVFD2Offset) 48
   set MyETHTransmit(iVFD2Range) 6
   set MyETHTransmit(ucVFD2Pattern.0.uc) [format %c 0x10]
   set MyETHTransmit(ucVFD2Pattern.1.uc) [format %c 0x20]
   set MyETHTransmit(ucVFD2Pattern.2.uc) [format %c 0x30]
   set MyETHTransmit(ucVFD2Pattern.3.uc) [format %c 0x40]
   set MyETHTransmit(ucVFD2Pattern.4.uc) [format %c 0x50]
   set MyETHTransmit(ucVFD2Pattern.5.uc) [format %c 0x60]
   set MyETHTransmit(uiVFD2CycleCount) 1
   set MyETHTransmit(uiVFD2BlockCount) 1

   ##########################################################################
   # VFD3 - 10 byte range with VFD3_DATACOUNT/10 different patterns         #
   # - At VFD3_DATACOUNT set to 40 this will give four different 10 byte    #
   #   patterns.                                                            #
   # - The first 10 bytes will be 00 01 02 03 04 05 06 07 08 09 in packet 1 #
   #   and the second 10 bytes, 0A 0B 0C 0D 0E 0F 10 11 12 13 in packet 2   #
   #   and so on                                                            #
   ##########################################################################

   puts "Setting up Vfd3"
   set MyETHTransmit(ucVFD3Mode) [format %c $HVFD_ENABLED]
   set MyETHTransmit(uiVFD3Offset) 96
   set MyETHTransmit(uiVFD3Range) 10
   set MyETHTransmit(uiVFD3DataCount) $VFD3DATA_COUNT
   set MyETHTransmit(uiVFD3BlockCount) 1

   puts "Initializing Vfd3 data"
   # intialize VFD3 data 
   for {set i 0} {$i < $VFD3DATA_COUNT} {incr i} {
         set MyETHTransmit(ucVFD3Buffer.$i.uc) [format %c $i]
   }

puts "Settting the data on the card"
#Set on card
LIBCMD HTSetStructure $ETH_TRANSMIT 0 0 0 MyETHTransmit 0 $iHub $iSlot $iPort

#UnSet the structure
unset MyETHTransmit

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
