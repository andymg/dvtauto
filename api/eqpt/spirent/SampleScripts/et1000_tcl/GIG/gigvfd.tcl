###########################################################################################
# GIGVFD.tcl                                                                              #
#                                                                                         #
# - Basic start, transmit, capture and display for Gb Ethernet cards                      #
#                                                                                         #
# NOTE: This script works on the following cards:                                         #
#       - GX-1405(B)                                                                      #
#       - GX-1420(B)                                                                      #
#       - LAN-6200                                                                        #
#       - LAN-6201                                                                        #
#                                                                                         #
###########################################################################################


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


###############################################################
#                                                             #
# C2I - Converts a character and returns its integer value    #
#                                                             #
# argument: ucItem - The character whose integer value will   #
#                     be returned                             #
#                                                             #
###############################################################

proc C2I {ucItem} {
	            set iItem 0
	            set ucMin [format %c 0x00]
	            set ucMax [format %c 0xFF]

	            if {$ucItem == $ucMin} {
		         set iItem 0
	            } elseif {$ucItem == $ucMax} {
		               set iItem 255
	            } else {
		             scan $ucItem %c iItem
	            }

	            return $iItem
}
################# END C2I #################################

#Set the default variables
set iHub    0
set iSlot   0
set iPort   0

set iHub2   0
set iSlot2  0
set iPort2  1

set NUM_FRAMES 5
set DATA_LENGTH 100

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# setup transmit
struct_new gt GIGTransmit
set gt(uiMainLength) $DATA_LENGTH
set gt(ucPreambleByteLength) [format %c 8]
set gt(ucFramesPerCarrier) [format %c 1]
set gt(ulGap) 9600
set gt(ucMainRandomBackground) [format %c 0]
set gt(ucBG1RandomBackground) [format %c 0]
set gt(ucBG2RandomBackground) [format %c 0]
set gt(ucSS1RandomBackground) [format %c 0]
set gt(ucSS2RandomBackground) [format %c 0]
set gt(ucMainCRCError) [format %c 0]
set gt(ucBG1CRCError) [format %c 0]
set gt(ucBG2CRCError) [format %c 0]
set gt(ucSS1CRCError) [format %c 0]
set gt(ucSS2CRCError) [format %c 0]
set gt(ucJabberCount) [format %c 0]
set gt(ucLoopback) [format %c 0]
set gt(ulBG1Frequency) 0
set gt(ulBG2Frequency) 0
set gt(uiBG1Length) 0
set gt(uiBG2Length) 0
set gt(uiSS1Length) 0
set gt(uiSS2Length) 0
set gt(uiLinkConfiguration) $GIG_AFN_FULL_DUPLEX

##############################################################################
# VFD1                                                                       #
# - Starts at 00 00 11 22 11 22 and increments up with a cycle count of four #
# - Overwrites MAC Destination area                                          #
##############################################################################

set gt(uiVFD1Offset) 0
set gt(iVFD1Range) 6
set gt(ucVFD1Mode) [format %c $GIG_VFD_INCREMENT]
set gt(ulVFD1CycleCount) 4
set gt(ucVFD1Data.0.uc) [format %c 0x00]
set gt(ucVFD1Data.1.uc) [format %c 0x00]
set gt(ucVFD1Data.2.uc) [format %c 0x11]
set gt(ucVFD1Data.3.uc) [format %c 0x22]
set gt(ucVFD1Data.4.uc) [format %c 0x11]
set gt(ucVFD1Data.5.uc) [format %c 0x22]

##############################################################################
# VFD2                                                                       #
# - Overwrites MAC Source area with AA BB CC DD EE FF and decrements down    #
##############################################################################

set gt(uiVFD2Offset) 48
set gt(iVFD2Range) 6
set gt(ucVFD2Mode) [format %c $GIG_VFD_DECREMENT]
set gt(ulVFD2CycleCount) 4
set gt(ucVFD2Data.0.uc) [format %c 0x00]
set gt(ucVFD2Data.1.uc) [format %c 0x00]
set gt(ucVFD2Data.2.uc) [format %c 0x33]
set gt(ucVFD2Data.3.uc) [format %c 0x44]
set gt(ucVFD2Data.4.uc) [format %c 0x33]
set gt(ucVFD2Data.5.uc) [format %c 0x44]

#############################################################################
# VFD3                                                                      #
# - 8 bytes with a count of 3                                               #
# - 3 different 8 byte patterns from the VFD Data                           #
#############################################################################

set gt(uiVFD3Offset) 96
set gt(uiVFD3Range) 8
set gt(ulVFD3Count) 3
set gt(ucVFD3Mode) [format %c $GIG_VFD3_ON]
set gt(ucMainBG1Mode) [format %c 0]
set gt(ulBurstCount) $NUM_FRAMES
set gt(ulMultiburstCount) 0
set gt(ulInterBurstGap) 0
set gt(ucTransmitMode) [format %c 1]
set gt(ucEchoMode) [format %c 0]
set gt(ucPeriodicGap) 0
set gt(ucCountRcverrOrOvrsz) [format %c 0]
set gt(ucGapByBitTimesOrByRate) [format %c 0]
set gt(ucRandomLengthEnable) [format %c 0]
set gt(uiVFD1BlockCount) 1
set gt(uiVFD2BlockCount) 1
set gt(uiVFD3BlockCount) 1

#Set the card
LIBCMD HTSetStructure $GIG_STRUC_TX 0 0 0 gt 0 $iHub $iSlot $iPort

#Unset the structure
unset gt

#############################################################################
# fill in background data                                                   #
# Everything that isn't a VFD will be 5A                                    #
#############################################################################

struct_new filldata UChar*$DATA_LENGTH

for {set i 0} {$i < $DATA_LENGTH} {incr i} {
      set filldata($i.uc) [format %c 0x5A]
}

#Fill the pattern
LIBCMD HTSetStructure $GIG_STRUC_FILL_PATTERN 0 0 0 filldata $DATA_LENGTH\
                      $iHub $iSlot $iPort

#Unset the structure
unset filldata

# fill in VFD3 data
struct_new vfd3Data UChar*24

set vfd3Data(0.uc) [format %c 0x08]
set vfd3Data(1.uc) [format %c 0x00]
set vfd3Data(2.uc) [format %c 0x11]
set vfd3Data(3.uc) [format %c 0x11]
set vfd3Data(4.uc) [format %c 0x11]
set vfd3Data(5.uc) [format %c 0x11]
set vfd3Data(6.uc) [format %c 0x11]
set vfd3Data(7.uc) [format %c 0x11]
set vfd3Data(8.uc) [format %c 0x81]
set vfd3Data(9.uc) [format %c 0x37]
set vfd3Data(10.uc) [format %c 0x22]
set vfd3Data(11.uc) [format %c 0x22]
set vfd3Data(12.uc) [format %c 0x22]
set vfd3Data(13.uc) [format %c 0x22]
set vfd3Data(14.uc) [format %c 0x22]
set vfd3Data(15.uc) [format %c 0x22]
set vfd3Data(16.uc) [format %c 0x08]
set vfd3Data(17.uc) [format %c 0x06]
set vfd3Data(18.uc) [format %c 0x33]
set vfd3Data(19.uc) [format %c 0x33]
set vfd3Data(20.uc) [format %c 0x33]
set vfd3Data(21.uc) [format %c 0x33]
set vfd3Data(22.uc) [format %c 0x33]
set vfd3Data(23.uc) [format %c 0x33]

#Set the Vfd3Data on the card
LIBCMD HTSetStructure $GIG_STRUC_VFD3 0 0 0 vfd3Data 0 $iHub $iSlot $iPort

#Unset the structure
unset vfd3Data

# Start capture -- capture all packets
struct_new CapSetup GIGCaptureSetup

set CapSetup(ucCRCErrors) [format %c 0]
set CapSetup(ucRxTrigger) [format %c 0]
set CapSetup(ucTxTrigger) [format %c 0]
set CapSetup(ucRCErrors)  [format %c 0]
set CapSetup(ucFilterMode) [format %c 0]
set CapSetup(ucStartStopOnConditionMode) [format %c 0]
set CapSetup(uc64BytesOnly) [format %c 0]
set CapSetup(ucLast64Bytes) [format %c 0]
set CapSetup(ucStartStop) [format %c 1]

#Set the capture parameters on the card
LIBCMD HTSetStructure $GIG_STRUC_CAPTURE_SETUP 0 0 0 CapSetup 0 $iHub2\
                      $iSlot2 $iPort2

# Send data
after 2000
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

# Stop capture
set CapSetup(ucStartStop)       [format %c 0]

#Set the capture parameters on the card
LIBCMD HTSetStructure $GIG_STRUC_CAPTURE_SETUP 0 0 0 CapSetup 0 $iHub2\
                      $iSlot2 $iPort2

# Get capture count
struct_new CapCount GIGCaptureCountInfo
LIBCMD HTGetStructure $GIG_STRUC_CAP_COUNT_INFO 0 0 0 CapCount 0 $iHub2\
                      $iSlot2 $iPort2
puts ""
puts "Count = $CapCount(ulCount)"

# Display captured data
struct_new CapData GIGCaptureDataInfo
for {set i 0} {$i < $CapCount(ulCount)} {incr i} {
      set CapData(ulFrame) $i
      puts ""
      puts "---------"
      puts "FRAME $i"
      puts -nonewline "---------"

      #Get the data info
      LIBCMD HTGetStructure $GIG_STRUC_CAP_DATA_INFO 0 0 0 CapData 0 $iHub2\
                              $iSlot2 $iPort2

      for {set j 0} {$j < [expr $DATA_LENGTH + 4]} {incr j} {
            if {[expr $j % 16] == 0} {
                 puts ""
                 puts -nonewline [format "%4i:   " $j]
      }

      set iData [C2I $CapData(ucData.$j.uc)]
      puts -nonewline " [format "%02X" $iData]"
      }

      puts ""
      puts "Press ENTER to continue"
      gets stdin response
}

# Unset the structure
unset CapSetup
unset CapCount
unset CapData

#UnLinking from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"


