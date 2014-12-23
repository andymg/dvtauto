##################################################################
# L3_HIST_V2_LAT_PER_STRM.TCL                                    #
#                                                                #
# - Displays latency and sequence information                    #
#                                                                #
# NOTE: This script works on the following cards:                #
#       - L3-67XX                                                #
#       - ML-7710                                                #
#       - ML-5710                                                #
#       - LAN-6101A                                              #
#       - LAN-3300A/3301A                                        #
#       - LAN-3310A/3311A                                        #
#       - POS-6500/6502                                          #
#       - POS-3505A/3504As                                       #
#                                                                #
##################################################################

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
set iSlot2 0
set iPort2 1

set num2Add 9

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

#set up streams
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 - 0 $iHub $iSlot $iPort\
-ucActive       1 \
-ucProtocolType $L3_STREAM_IP \
-uiFrameLength  $DATA_LENGTH \
-ucRandomLength 0 \
-ucTagField     1 \
-DestinationMAC {0 0 0 0 1 0} \
-SourceMAC      {0 0 0 0 0 1} \
-TimeToLive     10 \
-DestinationIP  {192 158 100 1} \
-SourceIP       {192 148 100 1} \
-Netmask        {255 255 255 0} \
-Gateway        {192 148 100 1} \
-Protocol       4

struct_new ip StreamIP
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM 1 $num2Add 0 ip 0 $iHub $iSlot $iPort \
-DestinationMAC {0 0 0 0 0 3} \
-SourceMAC      {0 0 0 0 0 2} \
-DestinationIP  {0 0 0 1} \
-SourceIP       {0 0 0 1}
unset ip

#############################################
# Check for L3 streams.  Test will not      #
# work if there are no streams transmitting #
# The DEFINED_STREAM_COUNT will return the  #
# total stream count (including the first,  #
# hidden stream, so we have to adjust the   #
# count to show the count of transmitting   #
# streams.                                  #
#############################################

struct_new DefStreams  ULong*3

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 DefStreams 0 $iHub $iSlot $iPort

set TOTAL_STREAMS [expr $DefStreams(0.ul) - 1]
if {  $TOTAL_STREAMS < 2 } {
     puts "No L3 streams on card - Aborting Test!"
     puts "Press ENTER key to exit"

     gets stdin response

     exit
} else {
         puts "Testing with $TOTAL_STREAMS streams"
}

#Unset the structure
unset DefStreams


######################################################################
# Set BOX Number for transmitting card                               #
# - high order nibble of low order byte of iControl                  #
#   sets the BOX number.  Note that this is settable                 #
#   on a per card basis.                                             #
#                                                                    #
# - Note the layer 3 address also sets the card stack                #
# - IP and MAC address the default gateway IP and other              #
#   parameters for this example, we are only setting the BOX         #
#   number.                                                          #
# - Setting the value to 8 will result in a box number of 9          #
#   since we start the count with zero (zero = box 1)                #
######################################################################

struct_new addr Layer3Address

set addr(iControl) 0x0080  

LIBCMD HTLayer3SetAddress addr $iHub $iSlot $iPort

unset addr

############################################################################
# Set distribution intervals.                                              #
# - They are set to variables here so the same variables can be referenced #
#   when setting up the display.                                           #
############################################################################

LIBCMD HTSetCommand $L3_HIST_V2_LATENCY_PER_STREAM 0 0 0 - $iHub2 $iSlot2 $iPort2\
-ulInterval.0.ul $R0 \
-ulInterval.1.ul $R1 \
-ulInterval.2.ul $R2 \
-ulInterval.3.ul $R3 \
-ulInterval.4.ul $R4 \
-ulInterval.5.ul $R5 \
-ulInterval.6.ul $R6 \
-ulInterval.7.ul $R7 \
-ulInterval.8.ul $R8 \
-ulInterval.9.ul $R9 \
-ulInterval.10.ul $R10 \
-ulInterval.11.ul $R11 \
-ulInterval.12.ul $R12 \
-ulInterval.13.ul $R13 \
-ulInterval.14.ul $R14 \
-ulInterval.15.ul $R15 

LIBCMD HTSetCommand $L3_HIST_START 0 0 0 NULL $iHub2 $iSlot2 $iPort2

# Create the group and set to transmit a single burst of 10000 packets
LIBCMD HGSetGroup ""
LIBCMD HGAddtoGroup $iHub $iSlot $iPort
LIBCMD HGAddtoGroup $iHub2 $iSlot2 $iPort2
LIBCMD HGSetSpeed $SPEED_10MHZ
LIBCMD HGGap 96
LIBCMD HGDuplexMode $HALFDUPLEX_MODE
LIBCMD HGTransmitMode $SINGLE_BURST_MODE
LIBCMD HGBurstCount 10000

# This group stop command will synchronize the cards
LIBCMD HGStop
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort
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

#Unset the structure
unset L3StrmInfo

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"

