##################################################################
# L3_HIST_V2_LAT_PER_STRM.TCL                                    #
#                                                                #
# Displays latency and sequence information                      #
#                                                                #
# NOTE: This script works on the following cards:                #
#       - L3-67XX                                                #
#       - ML-7710                                                #
#       - ML-5710                                                #
#       - LAN-6101A                                              #
#       - LAN-3300 / 3301A                                       #
#       - POS-6500A / 6502                                       #
#       - POS-3305A / 3504A                                      #
#                                                                #
##################################################################

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

set NUM_STREAMS 10

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# Set ranges for latency distribution
set R0 1
set R1 2
set R2 3
set R3 4
set R4 5
set R5 6
set R6 8
set R7 10
set R8 50
set R9 100
set R10 500
set R11 1000
set R12 5000
set R13 10000
set R14 50000
set R15 100000
set DATA_LENGTH 60

#Group the SmartBits Ports
LIBCMD HGSetGroup 1,2

#Set the speed
LIBCMD HGSetSpeed $SPEED_10MHZ

#Set the gap
LIBCMD HGGap 96

#Set to Duplex Mode
LIBCMD HGDuplexMode $HALFDUPLEX_MODE


# Set up IP streams on card
struct_new streamIP StreamIP

set streamIP(ucActive) [format %c 1]
set streamIP(ucProtocolType) [format %c $L3_STREAM_IP]
set streamIP(uiFrameLength) $DATA_LENGTH
set streamIP(ucRandomLength) [format %c 1]
set streamIP(ucTagField) [format %c 1]
set streamIP(DestinationMAC.0.uc) [format %c 0]
set streamIP(DestinationMAC.1.uc) [format %c 0]
set streamIP(DestinationMAC.2.uc) [format %c 0]
set streamIP(DestinationMAC.3.uc) [format %c 0]
set streamIP(DestinationMAC.4.uc) [format %c 1]
set streamIP(DestinationMAC.5.uc) [format %c 0]
set streamIP(SourceMAC.0.uc) [format %c 0]
set streamIP(SourceMAC.1.uc) [format %c 0]
set streamIP(SourceMAC.2.uc) [format %c 0]
set streamIP(SourceMAC.3.uc) [format %c 0]
set streamIP(SourceMAC.4.uc) [format %c 0]
set streamIP(SourceMAC.5.uc) [format %c 1]
set streamIP(TimeToLive) [format %c 10]
set streamIP(DestinationIP.0.uc) [format %c 192]
set streamIP(DestinationIP.1.uc) [format %c 158]
set streamIP(DestinationIP.2.uc) [format %c 100]
set streamIP(DestinationIP.3.uc) [format %c 1]
set streamIP(SourceIP.0.uc) [format %c 192]
set streamIP(SourceIP.1.uc) [format %c 148]
set streamIP(SourceIP.2.uc) [format %c 100]
set streamIP(SourceIP.3.uc) [format %c 1]
set streamIP(Protocol) [format %c 4]

#Set the stream on the card
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#Unset the structure
unset streamIP

#Set up multiple streams by incrementing the SourceMac and the SourceIP
struct_new incrementIP StreamIP
set incrementIP(SourceMAC.5.uc) [format %c 1]
set incrementIP(SourceIP.3.uc) [format %c 1]

#Set up multiple streams on the card
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 [expr $NUM_STREAMS - 1] 0 incrementIP 0 $iHub $iSlot $iPort

#Unset the structure
unset incrementIP

###########################################################################################
# Check for L3 streams.                                                                   #
# - Test will not work if there are no streams transmitting                               #
# - The DEFINED_STREAM_COUNT will return the total stream count (including the first,     #
#   hidden stream, and so we have to adjust the count to show the count of transmitting   #
#   streams.                                                                              #
###########################################################################################

struct_new StreamCount ULong

#Get the stream count info
LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort

#Subtract the hidden stream from the total stream count
set TOTAL_STREAMS [expr $StreamCount(ul) - 1]

#Check to see if there are L3 streams on the card
if {  $TOTAL_STREAMS < 2 } {
     puts "No L3 streams on card - Aborting Test!"
     puts "Press the 'ENTER' key to exit."
     gets stdin response
     exit
} else {
         puts "Testing with $TOTAL_STREAMS streams"
}

#Unset the structure
unset StreamCount


#############################################################################################
# - Set BOX Number for transmitting card high order nibble of low order byte of iControl    #
#   sets the BOX number.                                                                    #
#   - Note that this is settable on a per card basis.                                       #
#   - Note the layer 3 address also sets the card stack IP and MAC address the default      #
#     gateway IP and other parameters for this example, we are only setting the BOX number. #
# - Setting the value to 8 will result in a box number of 9 since we start the count with   #
#   zero (zero = box 1)                                                                     #
#############################################################################################

#Declare a new structure
struct_new addr Layer3Address

set addr(iControl) 0x0080  

#Configure the card to send/recieve background traffic 
LIBCMD HTLayer3SetAddress addr $iHub $iSlot $iPort

#Unset the structure
unset addr

############################################################################################
# - Set distribution intervals.                                                            #
#   - They are set to variables here so the same variables can be referenced when setting  #
#     up the display.                                                                      #
############################################################################################

struct_new L3V2HistDist Layer3V2HistDistribution

   set L3V2HistDist(ulInterval.0.ul) $R0
   set L3V2HistDist(ulInterval.1.ul) $R1
   set L3V2HistDist(ulInterval.2.ul) $R2
   set L3V2HistDist(ulInterval.3.ul) $R3
   set L3V2HistDist(ulInterval.4.ul) $R4
   set L3V2HistDist(ulInterval.5.ul) $R5
   set L3V2HistDist(ulInterval.6.ul) $R6
   set L3V2HistDist(ulInterval.7.ul) $R7
   set L3V2HistDist(ulInterval.8.ul) $R8
   set L3V2HistDist(ulInterval.9.ul) $R9
   set L3V2HistDist(ulInterval.10.ul) $R10
   set L3V2HistDist(ulInterval.11.ul) $R11
   set L3V2HistDist(ulInterval.12.ul) $R12
   set L3V2HistDist(ulInterval.13.ul) $R13
   set L3V2HistDist(ulInterval.14.ul) $R14
   set L3V2HistDist(ulInterval.15.ul) $R15

#Specify/Activate combination histogram  
LIBCMD HTSetCommand $L3_HIST_V2_LATENCY_PER_STREAM 0 0 0 L3V2HistDist $iHub2 $iSlot2 $iPort2

#Clear histogram records
LIBCMD HTSetCommand $L3_HIST_START 0 0 0 "" $iHub2 $iSlot2 $iPort2

#Create the group and set to transmit a single burst of 10000 packets
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2
LIBCMD HGTransmitMode $SINGLE_BURST_MODE
LIBCMD HGBurstCount 10000

#HGStop command will synchronize the cards
LIBCMD HGStop

#Start transmitting
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

#Pause for 2 seconds
after 2000

struct_new L3StrmInfo Layer3StreamLongLatencyInfo*$TOTAL_STREAMS

LIBCMD HTGetStructure $L3_HIST_V2_LATENCY_PER_STREAM_INFO 0 0 0 L3StrmInfo 0 $iHub2 $iSlot2 $iPort2


for {set i 0} {$i < $TOTAL_STREAMS} {incr i} {
   # pull out data from ulStream
   set BOX [expr ($L3StrmInfo($i.ulStream) & 0x0F000000) / 0x010000000]   
   set SLOT [expr ($L3StrmInfo($i.ulStream) & 0x00FF0000) / 0x00010000]
   set STREAM [expr $L3StrmInfo($i.ulStream) & 0x0000FFFF]

   puts "==================================================================="
   puts "SEQUENCE TRACKING - Card [expr $iSlot2 +1]"
   puts "   $L3StrmInfo($i.ulTotalFrames) Frames received from CARD [expr $SLOT + 1], BOX [expr $BOX + 1], STREAM $STREAM"
   puts "		Frames in Sequence => $L3StrmInfo($i.ulSequenced)"
   puts "		Duplicate Frames   => $L3StrmInfo($i.ulDuplicate)"
   puts "		Lost Frames	   => $L3StrmInfo($i.ulLost)"
   puts "==================================================================="
   puts "PER STREAM LATENCY"
   puts "	Min Frame Latency for Stream $STREAM => [expr $L3StrmInfo($i.ulMinimum) * 0.1] uS"
   puts "	Max Frame Latency for Stream $STREAM => [expr $L3StrmInfo($i.ulMaximum) * 0.1] uS"
   puts "==================================================================="
   puts "LATENCY DISTRIBUTION in 0.1uS"
   puts "========================================================================="
   puts -nonewline "|[format "%7d" $R0] |[format "%7d" $R1] |[format "%7d" $R2] |[format "%7d" $R3] |"
   puts "[format "%7d" $R4] |[format "%7d" $R5] |[format "%7d" $R6] |[format "%7d" $R7] |"
   puts "-------------------------------------------------------------------------"
   puts -nonewline "|"
   for {set j 0} {$j < 8} {incr j}  {
   puts -nonewline "[format "%7d" $L3StrmInfo($i.ulFrames.$j)] |"
   }
   puts ""
   puts "-------------------------------------------------------------------------\n"
   puts "========================================================================="
   puts -nonewline "|[format "%7d" $R8] |[format "%7d" $R9] |[format "%7d" $R10] |[format "%7d" $R11] |"
   puts "[format "%7d" $R12] |[format "%7d" $R13] |[format "%7d" $R14] |[format "%7d" $R15] |"
   puts "-------------------------------------------------------------------------"
   puts -nonewline "|"
   for {set j 8} {$j < 16} {incr j}  {
   puts -nonewline "[format "%7d" $L3StrmInfo($i.ulFrames.$j)] |"
   }
   puts ""
   puts "-------------------------------------------------------------------------"
   puts "Press ENTER key for next stream data"
   gets stdin response
}

#Unset the structures
unset L3StrmInfo
unset L3V2HistDist

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
