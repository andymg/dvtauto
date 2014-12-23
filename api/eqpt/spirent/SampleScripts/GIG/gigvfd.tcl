################################################################################
# GIGVFD.tcl                                                                   #
#                                                                              #
# - Basic start, transmit, capture and display for Gb Ethernet cards           #
#                                                                              #
# NOTE: This script works on the following cards:                              #
#       - GX-1405(B)                                                           #
#       - GX-1420(B)                                                           #
#       - LAN-6200A                                                            #
#       - LAN-6201A                                                            #
#                                                                              #
################################################################################

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
LIBCMD HTSetStructure $GIG_STRUC_TX 0 0 0 - 0 $iHub $iSlot $iPort \
	-ulGap 9600 -ucFramesPerCarrier 1 -ulBurstCount $NUM_FRAMES \
        -ucTransmitMode $GIG_SINGLE_BURST_MODE \
	-iVFD1Range 6 -ucVFD1Mode $GIG_VFD_INCREMENT -ulVFD1CycleCount 4 \
	-uiVFD1BlockCount 1 \
	-ucVFD1Data {0x00 0x00 0x11 0x22 0x11 0x22 0 0} \
	-iVFD2Range 6 -ucVFD2Mode $GIG_VFD_INCREMENT -ulVFD2CycleCount 4 \
	-uiVFD2BlockCount 1 \
	-ucVFD2Data {0x00 0x00 0x33 0x44 0x33 0x44 0 0} \
	-uiVFD3Offset 96 -uiVFD3Range 8 -ulVFD3Count 3 \
	-ucVFD3Mode $GIG_VFD3_ON \
	-uiVFD3BlockCount 1

###########################################################
# fill in background data                                 #
# Everything that isn't a VFD will be 5A                  #
###########################################################

struct_new filldata UChar*$DATA_LENGTH

for {set i 0} {$i < $DATA_LENGTH} {incr i} {
      set filldata($i) 0x5A
}

LIBCMD HTSetStructure $GIG_STRUC_FILL_PATTERN 0 0 0 filldata $DATA_LENGTH \
	$iHub $iSlot $iPort

unset filldata

# fill in VFD3 data
struct_new vfd3Data UChar*24

set vfd3Data() {0x08 0x00 0x11 0x11 0x11 0x11 0x11 0x11 0x81 0x37 0x22 0x22 \
	0x22 0x22 0x22 0x22 0x08 0x06 0x33 0x33 0x33 0x33 0x33 0x33}

LIBCMD HTSetStructure $GIG_STRUC_VFD3 0 0 0 vfd3Data 0 $iHub $iSlot $iPort

unset vfd3Data

# start capture -- capture all packets
LIBCMD HTSetStructure $GIG_STRUC_CAPTURE_SETUP 0 0 0 - 0 $iHub2 \
	$iSlot2 $iPort2 \
	-ucStartStop 1

# send data
after 2000
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

# stop capture
LIBCMD HTSetStructure $GIG_STRUC_CAPTURE_SETUP 0 0 0 - 0 $iHub2 \
	$iSlot2 $iPort2 \
	-ucStartStop 0

# get capture count
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
      LIBCMD HTGetStructure $GIG_STRUC_CAP_DATA_INFO 0 0 0 CapData 0 $iHub2\
                              $iSlot2 $iPort2
      for {set j 0} {$j < [expr $DATA_LENGTH + 4]} {incr j} {
            if {[expr $j % 16] == 0} {
                 puts ""
                 puts -nonewline [format "%4i:   " $j]
            }

            puts -nonewline " [format "%02X" $CapData(ucData.$j)]"
      }

      puts ""
      puts "Press ENTER to continue"
      gets stdin response
}


# Unset the structures
unset CapCount
unset CapData

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
