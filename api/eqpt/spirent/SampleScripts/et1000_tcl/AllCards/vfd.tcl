########################################################################################################
#VFD.TCL                                                                                               #
#                                                                                                      #
# This script that demonstrates VFD usage by:                                                          #
#                                                                                                      #
# - Sets up VFD1 to overlay the MAC Destination area with a broadcast pattern (FF FF FF FF FF FF),     #                     #                                                                                                      # 
# - Sets VFD2 to overlay the MAC Source area with an incrementing pattern starting with                #
#   00 11 22 33 44 55.                                                                                 #
# - Sets up VFD3 to create a repeating cycle of different Ethertypes.                                  #                     #                                                                                                      #
# NOTE: This script works on the following cards:                                                      #
#       - 10 Mbps                                                                                      #
#       - SX-72XX/74XX                                                                                 #
#       - L3-67xx                                                                                      #
#       - ML-7710                                                                                      #
#       - ML-5710                                                                                      #
#       - LAN-6100                                                                                     #
#       - LAN-6101A                                                                                    #
#       - GX-1405(B)                                                                                   #
#       - GX-1420(B)                                                                                   #
#       - LAN-6200A                                                                                    #
#       - LAN-3300A/3301A/3302A                                                                        #
#       - LAN-3310A/3311A                                                                              #
#       - LAN-3306A                                                                                    #
#       - LAN-332xA                                                                                    #
#       - LAN-3710A                                                                                    #
#       - XLW-372xA                                                                                    #
#                                                                                                      #
########################################################################################################


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


set iHub 0
set iSlot 8
set iPort 0

set iHub2 0
set iSlot2 8
set iPort2 1

set NUM_FRAMES 20
set DATA_LENGTH 60
set VFD_LENGTH 6

puts "Starting VFD.TCL..."

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

#Sets up the card to transmit a single burst of NUM_FRAMES packets,
#each DATA_LENGTH long (plus four byte CRC). With defaults this 
#means a single burst of twenty, 60-byte packets.
puts "Setup transmit parameters"
LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort

LIBCMD HTBurstCount $NUM_FRAMES $iHub $iSlot $iPort

LIBCMD HTDataLength $DATA_LENGTH $iHub $iSlot $iPort

########################################################################################################
# Fill in background data                                                                              #
#                                                                                                      #
# - Since the default fill is all 0, the background is filled with some other                          #
#   pattern, so that we can see that your program is writing to the card,                              #
#   and to be able to see the length of your fill pattern.                                             #
# - This sets the entire 60 byte packet length to all A's.                                             #
# - Anything that is not overlaid with a VFD will be an A.                                             #
# - If a VFD overlays an area with 0's instead of the intended pattern, you know                       #
#   that the VFD is working, but there may be a problem with the structure holding                     #
#   your data.                                                                                         #
########################################################################################################
struct_new filldata Int*$DATA_LENGTH
for {set i 0} {$i < $DATA_LENGTH} {incr i} {
	set filldata($i.i) 0xAA
}
LIBCMD HTFillPattern $DATA_LENGTH filldata $iHub $iSlot $iPort
unset filldata

########################################################################################################
# Fill in VFD1 data:                                                                                   #
#                                                                                                      #
# - Configuration $HVFD_STATIC means the same VFD will be over-laid onto every packet.                 #
# - In this case:                                                                                      #
#   - A loop is used to fill the structure vfd1Data with all FF (broadcast).                           #
#   - The Range value is set to 6.                                                                     #
#   - VFD 1 and 2 have a maximum length of 6 bytes.                                                    #
#   - The offset of 0 bits (note that Offset is in bits - all other parameters are in bytes).          #
#   - An Offset of zero bits with a Range of 6 bytes means this VFD will overlay the MAC Destination   #
#     area of the packet as follows (XX indicates non-VFD bytes in packet):                            #
#     FF FF FF FF FF FF XX XX XX XX XX XX etc.                                                         #
########################################################################################################

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
LIBCMD HTVFD $HVFD_1 vfdstruct $iHub $iSlot $iPort
unset vfd1Data

##########################################################################################################
# Fill in VFD2 data                                                                                      #
#                                                                                                        #
# - VFD2 data is set up assigning the value to each individual byte.                                     #
# - Setting Configuration to $HVFD_INCR and DataCount to 10 means the LSB will increment through a cycle #
#   of 10 and then repeat.                                                                               #
# - Range is 6 bytes                                                                                     #
# - Offset is 48 bits, so this VFD will overlay the MAC Source area of the packet.                       #
# - VFD 1 and 2 are in reverse order, so the VFD pattern in the first four packets will look as follows  #
#   (XX indicates non-VFD bytes in packet):                                                              #
#   XX XX XX XX XX XX 00 11 22 33 44 55 XX XX XX XX etc.                                                 #
#   XX XX XX XX XX XX 00 11 22 33 44 56 XX XX XX XX etc.                                                 #
#   XX XX XX XX XX XX 00 11 22 33 44 57 XX XX XX XX etc.                                                 #
#   XX XX XX XX XX XX 00 11 22 33 44 58 XX XX XX XX etc.                                                 #
#                                                                                                        #
# - HTVFD is followed by $HFVD_2 to indicate VFD2 and points to the vfdstruct structure that holds the   #
#   configuration settings.                                                                              #
##########################################################################################################

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
LIBCMD HTVFD $HVFD_2 vfdstruct $iHub $iSlot $iPort

unset vfd2Data

############################################################################################################
# Fill in VFD3 data                                                                                        #
#                                                                                                          #
# - VFD3 is used to overlay the type field.                                                                #
# - Configuration is set to $HVFD_ENABLED (Configuration options are different for VFD 1 and 2 and VFD 3). #
# - Range of 2 means we will lay down a 2 byte long VFD in each packet.                                    #
# - Combined with an Offset of 96 bits means it will VFD3 will overlay the EtherType field.                #
# - The vfd3Data structure has six elements.                                                               #
# - Setting the DataCount to 3 means we are calling for three VFDs to be created from the vfd3Data area.   #
#   (Note: tha DataCount which functions as a cycle counter in VFD1 and VFD2, has a different function in  #
#    VFD3.)                                                                                                #
#   - In VFD3 DataCount specifies the size of the VFD3 data to divide up, for example, if Range            #
#     was set to 24 and DataCount was set to 96, you would have a cycle of four                            #
#     different 24 byte packets.                                                                           #
# - This setup will generate a repeating pattern of three VFD3 overlaying the Ethertype area emulating a   #
#   cycle of an IP packet (0800) followed by an SNMP packet (814C), followed by a Novell packet (8137) and #
#   then repeating.                                                                                        #
#   - VFD3 is in opposite order compared to VFD1 and VFD1. First four packets will look as follows         #
#     (XX indicates non-VFD bytes in packet):                                                              #
#      XX XX XX XX XX XX XX XX XX XX XX XX 08 00 XX XX etc                                                 #
#      XX XX XX XX XX XX XX XX XX XX XX XX 81 4C XX XX etc                                                 #
#      XX XX XX XX XX XX XX XX XX XX XX XX 81 37 XX XX etc                                                 #
#      XX XX XX XX XX XX XX XX XX XX XX XX 08 00 XX XX etc                                                 #
# - HTVFD is followed by $HFVD_3 to indicate VFD3 and points to the vfdstruct structure that holds the     #
#   configuration settings.                                                                                #
############################################################################################################

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
LIBCMD HTVFD $HVFD_3 vfdstruct $iHub $iSlot $iPort

unset vfd3Data
unset vfdstruct

struct_new cap  Layer3CaptureSetup
# Start capture
set cap(ulCaptureMode)   $CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $L3_CAPTURE_SETUP 0 0 0 cap 0 $iHub2 $iSlot2 $iPort2
LIBCMD HTSetCommand $L3_CAPTURE_START 0 0 0 0 $iHub2 $iSlot2 $iPort2
puts "Start capture"
unset cap

# send data
puts "Sending data"
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
after 1000

# Stop capture
LIBCMD HTSetCommand $L3_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2
puts "Stop catpure"

struct_new cap_count 	Layer3CaptureCountInfo
struct_new packet    	Layer3CaptureData

# Get capture count 
LIBCMD HTGetStructure $::L3_CAPTURE_COUNT_INFO 0 0 0 cap_count 0 $iHub2\
                $iSlot2 $iPort2
puts "Capture count $cap_count(ulCount)"

# Display capture packets
puts "Display captured packets"
for {set index 0 } {$index < $cap_count(ulCount)} {incr index} {    	
    puts "\nPacket $index\n"
    
    LIBCMD HTGetStructure $L3_CAPTURE_PACKET_DATA_INFO $index 0 0 packet 0 $iHub2 $iSlot2 $iPort2
    puts "Packet Length $packet(uiLength)\n"
    
    # Display the packet
    for {set i 0} {$i < $packet(uiLength)} {incr i} {
        if {!($i % 16) && ($i != 0)} {
        puts ""
    }
        
        set byte $packet(cData.$i._ubyte_)
        puts -nonewline " [format %02X  $byte] "
    }    
    puts ""
    
}  
unset cap_count
unset packet

puts "\n"

#UnLink from the chassis
puts "UnLinking from the chassis now..."
LIBCMD NSUnLink
puts "DONE!"

