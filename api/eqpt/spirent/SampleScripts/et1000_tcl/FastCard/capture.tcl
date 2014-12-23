####################################################################################
# CAPTURE.TCL                                                                      #
# - Tcl script that illustrates capture and Alternate Stream                       #
#   setup on SX-7210 and SX-7410 SmartCards                                        #
#                                                                                  #
# NOTE: This script works on the following cards:                                  #
#       - LAN-6100                                                                 #
#                                                                                  #
####################################################################################

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
set iSlot 2
set iPort 0

set iHub2 0
set iSlot2 3
set iPort2 0

set NUM_FRAMES 10
set DATA_LENGTH 60
set CRC 4
set DISPLAY_FRAMES 2

# RESERVE CARDS 
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

# RESET CARDS 
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2

####################################################################
# setup transmit on Card 1 -Single burst, with ten ($NUM_FRAMES)   #
# 60-byte ($DATA_LENGTH) packets.                                  #
####################################################################

LIBCMD HTTransmitMode $SINGLE_BURST_MODE $iHub $iSlot $iPort
LIBCMD HTBurstCount $NUM_FRAMES $iHub $iSlot $iPort
LIBCMD HTDataLength $DATA_LENGTH $iHub $iSlot $iPort

################################################################################
# Background Data - Main Stream                                                #
# - Set background of standard packet to CC. This is useful for                #
#   troubleshooting, since the default is all 0's.                             #
# - If the card has all zero packets, you know you have a very basic problem   #
#   (such as not having a card in the target slot.                             #
# - Each Main Stream packet will be 60 CC bytes followed by a four byte CRC.   #
################################################################################

struct_new filldata Int*$DATA_LENGTH
for {set i 0} {$i < $DATA_LENGTH} {incr i} {
      set filldata($i.i) 0xCC
}

LIBCMD HTFillPattern $DATA_LENGTH filldata $iHub $iSlot $iPort

#########################################################################################################
# Alternate Packet Setup                                                                                #
#                                                                                                       #
# - Alternate transmit is a feature of 7x10 cards.                                                      #
# - This allows you to create a completely different frame to be inserted periodically                  #
#   in the data stream.                                                                                 #
# - The detail of the Alt Tranmit function will be found in the 100 MB Fast Ethernet                    #
#   section of the SmartLib Message Function Manual.                                                    #
# - Alt Transmit is controlled by the FST_ALTERNATE_TX iType1.                                          #
# - The structure type associated with FST_ALTERNATE_TX is FSTAlternateTX.                              #
# - This holds the setup information for the capture.                                                   #
# - A structure is created of type FSTAlternateTX with:                                                 #
#         struct_new AltTx FSTAlternateTx                                                               #
#   ...where AltTx is the name of the structure of this type we create.                                 #
# - The elements of the FSTAlternateTX structure are found in the Message Function Manual               #
#   under FST_ALTERNATE_TX.                                                                             #
# - After the AltTx structure is created, we set the various options.                                   #
#   A brief summary of the options follows.                                                             #
#   - Note that some elements are unsigned chars requiring the format                                   #
#     command to ensure proper interpretation.                                                          #
#     - Failure to do this will result in a "Bad Data Type" error from Tcl.                             #
# - (ucEnabled) turns alternate transmit on - 0 turns it off                                            #
# - (usCRCErrors) setting to 0 means NO CRC ERRORS; setting it to 1 will cause all                      #
#   alternate packets to have CRC errors.                                                               #
# - (ucErrorSymbol) and (ucDribble) are similar.  Setting to 1 will cause these errors in               #
#   the Alternate packet, zero will not cause these errors.                                             #
# - In this example, all error types are set to zero so the alternate transmit packet will              #
#   be a good packet.                                                                                   #
# - (ucAlternateCount) sets how often the alternate packet will be transmitted.                         #
#   It is the number of main stream packets that will be transmitted before an Alternate Packet.        #
#   Here it is set to three, meaning we will transmit, three main packets then one alternate,           #
#   three more main packets another alternate and so on.                                                #
# - (uiDataLength) sets the packet size (not including CRC).  We set it to the value $ALT_LENGTH,       #
#   defined as 76 above.                                                                                #
#   - Note that since this is type int, it does not require the format command.                         #
# - (ucData.$i.uc) is the data byte itself. We use a simple for loop to initialize                      #
#   all the elements to 33.  The $i here is a variable for the current vlaue of the loop counter        #
#   so we set element zero the first time, and set element 1 the second time                            #
#   (when the loop counter i holds a value of 1) and so on.                                             #
# - HTSetStructure sends the data to the card. FST_ALTERNATE_TX is iType 1, all other iTypes            #
#   for this function are zero.  AltTx is the name of the structure holding our configuration           #
#   setup data. The last four elements are the Length field and Hub Slot Port.                          #
# - The alternate packet will be all 3's and will transmit every fourth                                 #
#   packet.                                                                                             #
#########################################################################################################

struct_new AltTx FSTAlternateTx
set AltTx(ucEnabled)  [format %c 1]
set AltTx(ucCRCErrors)  [format %c 0]
set AltTx(ucErrorSymbol)  [format %c 0]
set AltTx(ucDribble)  [format %c 0]
set AltTx(ulAlternateCount)  3
set AltTx(uiDataLength) $DATA_LENGTH

for {set i 0} {$i < $DATA_LENGTH} {incr i} {
      set AltTx(ucData.$i.uc)  [format %c 0x33]
}

LIBCMD HTSetStructure $FST_ALTERNATE_TX 0 0 0 AltTx 0 $iHub $iSlot $iPort

################################################################################################################
# Capture Setup                                                                                                #
#                                                                                                              #
# - Capture on the 100MB Fast Cards is controlled by the NS_CAPTURE_SETUP iType1 found in the Message          #
#   Function Manual.                                                                                           #
# - The data structure type associated with NS_CAPTURE_PARAMS is NSCaptureSetup, the individual elements       #
#   of which are described the Message Function Manual in the NS_CAPTURE_SETUP section.                        #                                                                                                            #
# - HTSetStrucuture with the $FST_CAPTURE_PARAMS iType1 sets the configuration to a target card.               #
#                                                                                                              #
################################################################################################################

struct_new CapSetup NSCaptureSetup
set CapSetup(ulCaptureMode) $CAPTURE_MODE_FILTER_ON_EVENTS
set CapSetup(ulCaptureLength) $CAPTURE_LENGTH_ENTIRE_FRAME
set CapSetup(ulCaptureEvents) $CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $NS_CAPTURE_SETUP 0 0 0 CapSetup 0 $iHub2 $iSlot2 $iPort2

# Send data
HTRun $HTRUN $iHub $iSlot $iPort

LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2

#################################################################################################################
# - Get capture count  (number of frames captured) and output to user                                           #
# - CapCount structure will hold the number of frames captured                                                  #
#   after HTGetStructure $NS_CAPTURE_COUNT_INFO is run                                                         #
#################################################################################################################

# Get and display captured data
struct_new CapCount NSCaptureCountInfo

LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 CapCount 0 $iHub2 $iSlot2 $iPort2
puts "Count = $CapCount(ulCount)"


#################################################################################################################
# Get and output the capture data                                                                               #
#                                                                                                               #
# - This shows the individual bytes CapData structure created to hold the actual packet                         #
#   data from the SmartCard.                                                                                    #
#################################################################################################################

struct_new CapData NSCaptureDataInfo
for {set i 0} {$i < $CapCount(ulCount)} {incr i} {
      set CapData(ulFrameIndex) $i
      LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 CapData 0 $iHub2 $iSlot2 $iPort2

      puts ""
      puts "---------"
      puts "FRAME $i"
      puts "---------"
      set CapData(ulRequestedLength) [expr $DATA_LENGTH + $CRC]
      for {set j 0} {$j < $CapData(ulRetrievedLength)} {incr j} {
	    if {[expr $j % 16] == 0} {                ;# if divisible by 16
		puts ""                                ;# start a new line with
			puts -nonewline [format "%4i:   " $j]  ;# the byte number
		}
		set iData [ConvertCtoI $CapData(ucData.$j.uc)]	;# use function from misc.tcl
		puts -nonewline [format " %02X" $iData]         ;# 2 digits leading 0
	}
	puts ""
	if {[expr $i % $DISPLAY_FRAMES] == 0 } {    	;#stop scrolling
		puts ""
		puts "Press ENTER key to continue"
		gets stdin response
	}
}

# Unset the structures created
unset filldata
unset CapSetup
unset CapCount
unset CapData
unset AltTx

#UnLink from the chassis
puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"
