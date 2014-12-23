###########################################################################################
# basic_xenpak.tcl                                                                        #
#                                                                                         #
# - Basic start, transmit, capture, display capture frames and profile for Xenpak cards   #
#                                                                                         #
# NOTE: This script works on the following cards:                                         #
#       - XLW-3720A                                                                       #
#       - XLW-3721A                                                                       #
#                                                                                         #
###########################################################################################


#############################################################################
# This proc checks the link LED .                               	    #
# CheckLink waits for 2 seconds or more, until the link is established.     #
# For other cards, CheckLink does not add any delay.                        #
#############################################################################
proc CheckLink {Hub Slot Port} {
    set Model ""
    set card_id [LIBCMD HTGetCardModel Model $Hub $Slot $Port]

    switch $card_id \
        $::CM_LAN_6301A { after 2000 } \
	$::CM_GX_1420B {
	    puts "Checking link status ..."
	    struct_new x Long
	    struct_new ExCardInfo ETHExtendedCardInfo

	    #a 2-second wait is necessary for GX-1420B
		after 2000

	    LIBCMD HTGetEnhancedStatus x $Hub $Slot $Port
	    while {![expr $x(l)&$::GIG_STATUS_LINK]} {
		LIBCMD HTGetStructure $::ETH_EXTENDED_CARD_INFO 0 0 0 ExCardInfo 0 $Hub $Slot $Port
		after 100
		LIBCMD HTGetEnhancedStatus x $Hub $Slot $Port
	    }
	    unset x
	    unset ExCardInfo
	} \
	default {
	    # Skip
	}
}

#############################################################################
# If smartlib.tcl is not loaded, attempt to locate it at the default location.
# The actual location is different on different platforms. 
#############################################################################
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

#############################################################################
# If chassis is not currently linked prompt for IP and link  
#############################################################################
if {[ETGetLinkStatus] < 0} {
     puts "SmartBits not linked - Enter chassis IP address"
     gets stdin ipaddr
     set retval [NSSocketLink $ipaddr 16385 0]  
     if {$retval < 0 } {
	  puts "Unable to connect to $ipaddr. Please try again."
	  exit
     }
}
#############################################################################
# Set the default variables
#############################################################################
set iHub 	0
set iSlot 	0
set iPort 	0

set iHub2 	0
set iSlot2 	1
set iPort2 	0

set FRAME_LENGTH    	100
set PREAMBLE_LENGTH 	8
set FRAME_GAP       	96
set BURST_GAP       	96
set BG1_LENGTH      	0
set BURST_SIZE      	10
set MULTIBURST_SIZE 	5
set Loopback	 	0

#############################################################################
# reserve the cards
#############################################################################
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2
puts "\nReserve iHub $iHub, iSlot $iSlot"
puts "\nReserve iHub2 $iHub2, iSlot2 $iSlot2\n"

# Reset cards
LIBCMD HTResetPort $RESET_FULL $iHub $iSlot $iPort
LIBCMD HTResetPort $RESET_FULL $iHub2 $iSlot2 $iPort2
puts "\nReset iHub $iHub, iSlot $iSlot $iPort"
puts "\nReset iHub2 $iHub2, iSlot2 $iSlot2 $iPort2\n"


# Check the link
CheckLink $iHub $iSlot $iPort
CheckLink $iHub2 $iSlot2 $iPort2
              
# Create structures              
struct_new tx       	GIGTransmit
struct_new counter  	GIGCounterInfo
struct_new packet    	NSCaptureDataInfo
struct_new cap 		NSCaptureSetup
struct_new cap_count 	NSCaptureCountInfo
struct_new fill_pat 	UChar*$FRAME_LENGTH
struct_new Profile       XENPAKProfile

# transmit mode
puts "Transmit single burst mode\n"

# Setup the main background pattern
for {set i 0} {$i < $FRAME_LENGTH } {incr i} {
	set fill_pat($i) 0xAA
}
LIBCMD HTSetStructure $GIG_STRUC_FILL_PATTERN 0 0 0 fill_pat 0 $iHub\
       $iSlot $iPort
puts "Fill background pattern with 0xAA\n"

# Setup the transmit parameters
set tx(uiMainLength)            $FRAME_LENGTH
set tx(ucPreambleByteLength)    $PREAMBLE_LENGTH
set tx(ucFramesPerCarrier)      0
set tx(ulGap)                   $FRAME_GAP
set tx(ucMainRandomBackground)  0
set tx(ucBG1RandomBackground)   0
set tx(ucBG2RandomBackground)   0
set tx(ucMainCRCError)          0
set tx(ucBG1CRCError)           0
set tx(ucBG2CRCError)           0
set tx(ucJabberCount)           0
set tx(ucLoopback)              0
set tx(ulBG1Frequency)          0
set tx(ulBG2Frequency)          0
set tx(uiBG1Length)             0
set tx(uiBG2Length)             0
set tx(uiLinkConfiguration)     $GIG_AFN_FULL_DUPLEX
set tx(uiVFD1Offset)            0
set tx(iVFD1Range)              0
set tx(ucVFD1Mode)              $GIG_VFD_OFF
set tx(ulVFD1CycleCount)        0
for {set i 0} {$i < 8} {incr i} {
    set tx(ucVFD1Data.$i) [expr 0x00]
}
set tx(uiVFD2Offset)            0
set tx(iVFD2Range)              0
set tx(ucVFD2Mode)              $GIG_VFD_OFF
set tx(ulVFD2CycleCount)        0
for {set i 0} {$i < 8} {incr i} {
    set tx(ucVFD2Data.$i) [expr 0x00]
}
set tx(uiVFD3Offset)            0
set tx(uiVFD3Range)             0
set tx(ulVFD3Count)             0
set tx(ucVFD3Mode)              $GIG_VFD3_OFF
set tx(ulBurstCount)            $BURST_SIZE
set tx(ulMultiburstCount)       $MULTIBURST_SIZE
set tx(ulInterBurstGap)         $BURST_GAP
set tx(ucTransmitMode)          $GIG_SINGLE_BURST_MODE
set tx(ucEchoMode)              0
set tx(ucPeriodicGap)           0
set tx(ucCountRcverrOrOvrsz)    0
set tx(ucGapByBitTimesOrByRate) 0
set tx(ucRandomLengthEnable)    0
set tx(uiVFD1BlockCount)        0
set tx(uiVFD2BlockCount)        0
set tx(uiVFD3BlockCount)        0

# Set the transmitting card's transmit parameters
LIBCMD HTSetStructure $GIG_STRUC_TX 0 0 0 tx 0 $iHub $iSlot $iPort

# transmit mode
puts "Number of frames transmit $BURST_SIZE\n"

# Start capture
set cap(ulCaptureMode)   $CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $CAPTURE_EVENTS_ALL_FRAMES
LIBCMD HTSetStructure $NS_CAPTURE_SETUP 0 0 0 cap 0 $iHub2 $iSlot2 $iPort2
LIBCMD HTSetCommand $NS_CAPTURE_START 0 0 0 0 $iHub2 $iSlot2 $iPort2
puts "Start capture"

# If the card is in loopback mode, then this function below needs to be accessed.
if { $Loopback } {
	struct_new gigMacConfig       GIGMacConfig
	set gigMacConfig(ucPreambleLen) 	8
	set gigMacConfig(ucEnableJumboFrame) 	0
	set gigMacConfig(ucEnableObeyPause) 	0
	set gigMacConfig(ucLoopBackMode) 	$GIG_PHY_LOOP_LOCAL_XGMII

	LIBCMD HTSetStructure $GIG_STRUC_MAC_CONFIG 0 0 0 gigMacConfig 0 $iHub $iSlot $iPort
	unset gigMacConfig
}	
	
# Clear counters
LIBCMD HTClearPort $iHub $iSlot $iPort
LIBCMD HTClearPort $iHub2 $iSlot2 $iPort2

puts "Clear counter on Tx and Rx\n"

# Transmit
LIBCMD HTRun $HTRUN $iHub $iSlot $iPort

puts "Transmiting...\n"

# wait 4 seconds
after 4000

# Stop capture
LIBCMD HTSetCommand $NS_CAPTURE_STOP 0 0 0 0 $iHub2 $iSlot2 $iPort2
puts "Stop catpure"

puts ""
LIBCMD HTGetStructure $GIG_STRUC_COUNTER_INFO 0 0 0 counter 0\
       $iHub $iSlot $iPort
puts "Get Tx counters..."
puts "Transmit $counter(ullTxFrames.low) packets\n"  

LIBCMD HTGetStructure $GIG_STRUC_COUNTER_INFO 0 0 0 counter 0\
        $iHub2 $iSlot2 $iPort2
puts "Get Rx counters..."
puts "Receive  $counter(ullRxFrames.low) packets\n"  

# Get capture count 
LIBCMD HTGetStructure $::NS_CAPTURE_COUNT_INFO 0 0 0 cap_count 0 $iHub2\
	$iSlot2 $iPort2
puts "Capture count $cap_count(ulCount)"	

# Display capture packets
puts "Display captured packets"
for {set index 0 } {$index < $cap_count(ulCount)} {incr index} {    	
    puts "\nPacket $index\n"
	    
    set packet(ulFrameIndex)      $index
    set packet(ulRequestedLength)      [expr $FRAME_LENGTH + 4]
    LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 packet 0 $iHub2 $iSlot2 $iPort2
    
    # Display the packet
    for {set j 0} {$j < $packet(ulRetrievedLength)} {incr j} {
        set iData 0
        if {[expr $j % 16] == 0} {
            puts ""
             puts -nonewline [format "%4i:   " $j]
        }

        puts -nonewline " "
        puts -nonewline " [format "%02X" $packet(ucData.$j._ubyte_)]"  
                                   
    }
           
}  

#####################################################
#
# Show xenpak profile
#
puts "\n"
puts "********** TESTING XENPAK_PROFILE_INFO **********"

#puts "Read XENPAKProfile"
LIBCMD HTGetStructure $XENPAK_PROFILE_INFO 0 0 0 Profile 0 $iHub2 $iSlot2 $iPort2

        
puts "*       ucModuleDetected: $Profile(ucModuleDetected)"
puts "*           ucNVRVersion: $Profile(ucNVRVersion)"
puts "*              uiNVRSize: $Profile(uiNVRSize)"
 
 
if { $Profile(ucTransceiverType) == $XENPAK_TYPE } {
puts "ucTransceiverType = XENPAK_TYPE"
} else {
puts "ucTransceiverType = XENPAK_UNSPECIFIED_TYPE"
}

puts -nonewline "*        ucConnectorType: "
switch $$Profile(ucConnectorType) \
	$XENPAK_OPTICAL_SC_TYPE	{ puts -nonewline "                      \t - XENPAK_OPTICAL_SC_TYPE" } \
	$XENPAK_OPTICAL_LC_TYPE	{ puts -nonewline "                      \t - XENPAK_OPTICAL_LC_TYPE" } \
	$XENPAK_OPTICAL_MT_RJ_TYPE	{ puts -nonewline "                      \t - XENPAK_OPTICAL_MT_RJ_TYPE" } \
	$XENPAK_OPTICAL_MU_TYPE	{ puts -nonewline "                      \t - XENPAK_OPTICAL_MU_TYPE" } \
	$XENPAK_OPTICAL_FC_PC_TYPE	{ puts -nonewline "                      \t - XENPAK_OPTICAL_FC_PC_TYPE" } \
	$XENPAK_OPTICAL_PIGTAIL_TYPE	{ puts -nonewline "                      \t - XENPAK_OPTICAL_PIGTAIL_TYPE" } \
	default { puts "                      \t - Connect type Undefined"}

puts -nonewline "*         ucProtocolType: "
set val [format "0x%02X" $Profile(ucProtocolType._ubyte_)]
switch $val \
	$XENPAK_10GBE	{ puts -nonewline "                      \t - XENPAK_10GBE" } \
	$XENPAK_10GFC	{ puts -nonewline "                      \t - XENPAK_10GFC" } \
	$XENPAK_WIS	{ puts -nonewline "                      \t - XENPAK_WIS" } \
	$XENPAK_LSS	{ puts -nonewline "                      \t - XENPAK_LSS" } \
	$XENPAK_SONET_SDH { puts -nonewline "                      \t - XENPAK_SONET_SDH" } \
	default { puts "                      \t - 10GbE Code Undefined"}
puts ""

puts "*    ucStdComplianceCode: "
for { set i 0 } { $i < 10 } { incr i } {
set val [format "0x%02X" $Profile(ucStdComplianceCode.$i._ubyte_)]
if { $i == 0 } {    		
   puts -nonewline "*             10GbE Code: "   
   switch $val \
	$XENPAK_10GBASE_SR	{ puts "                      \t - XENPAK_10GBASE_SR" } \
	$XENPAK_10GBASE_LR	{ puts "                      \t - XENPAK_10GBASE_LR" } \
	$XENPAK_10GBASE_ER	{ puts "                      \t - XENPAK_10GBASE_ER" } \
	$XENPAK_10GBASE_LX4	{ puts "                      \t - XENPAK_10GBASE_LX4" } \
	$XENPAK_10GBASE_SW	{ puts "                      \t - XENPAK_10GBASE_SW" } \
	$XENPAK_10GBASE_LW4	{ puts "                      \t - XENPAK_10GBASE_LW4" } \
	$XENPAK_10GBASE_LW	{ puts "                      \t - XENPAK_10GBASE_LW" } \
	$XENPAK_10GBASE_EW	{ puts "                      \t - XENPAK_10GBASE_EW" } \
	default { puts "                      \t - 10GbE Code Undefined"}
   puts ""
} elseif { $i == 2 } {
    puts -nonewline "*             SONET/SDH: "
    switch $val \
	$XENPAK_S_64_1	{ puts "                      \t - XENPAK_S_64_1" } \
	$XENPAK_S_64_2A	{ puts "                      \t - XENPAK_S_64_2A" } \
	$XENPAK_S_64_2B	{ puts "                      \t - XENPAK_S_64_2B" } \
	$XENPAK_S_64_3A	{ puts "                      \t - XENPAK_S_64_3A" } \
	$XENPAK_S_64_3B	{ puts "                      \t - XENPAK_S_64_3B" } \
	$XENPAK_S_64_5A	{ puts "                      \t - XENPAK_S_64_5A" } \
	$XENPAK_S_64_5B	{ puts "                      \t - XENPAK_S_64_5B" } \
	default { puts "                      \t - SONET/SDH Undefined"}
   puts ""
} elseif { $i == 3 } {   
    puts -nonewline "*             SONET/SDH: "
    switch $val \
	$XENPAK_I_64_1R	{ puts "                      \t - XENPAK_I_64_1R" } \
	$XENPAK_I_64_1	{ puts "                      \t - XENPAK_I_64_1" } \
	$XENPAK_I_64_2R	{ puts "                      \t - XENPAK_I_64_2R" } \
	$XENPAK_I_64_2	{ puts "                      \t - XENPAK_I_64_2" } \
	$XENPAK_I_64_3	{ puts "                      \t - XENPAK_I_64_3" } \
	$XENPAK_I_64_5	{ puts "                      \t - XENPAK_I_64_5" }   \
	default { puts "                      \t - SONET/SDH Undefined"}	
   puts ""
} elseif { $i == 4 } {  
    puts -nonewline "*              SONET/SDH: "
    switch $val \
	$XENPAK_L_64_1	{ puts "                      \t - XENPAK_L_64_1" } \
	$XENPAK_S_64_2A	{ puts "                      \t - XENPAK_S_64_2A" } \
	$XENPAK_S_64_2B	{ puts "                      \t - XENPAK_S_64_2B" } \
	$XENPAK_L_64_2C	{ puts "                      \t - XENPAK_L_64_2C" } \
	$XENPAK_L_64_3	{ puts "                      \t - XENPAK_L_64_3" } \
	default { puts "                      \t - SONET/SDH Undefined"}
   puts ""
} elseif { $i == 5 } {   
    puts -nonewline "*              SONET/SDH: "
    switch $val \
	$XENPAK_V_64_2A	{ puts "                      \t - XENPAK_V_64_2A" } \
	$XENPAK_V_64_2B	{ puts "                      \t - XENPAK_V_64_2B" } \
	$XENPAK_V_64_3	{ puts "                      \t - XENPAK_V_64_3" } \
	default { puts "                      \t - SONET/SDH Undefined"}
   puts ""
};
};

puts "*    uiTransmissionRange: $Profile(uiTransmissionRange)"
puts "*          ucFiberType.0: $Profile(ucFiberType.0)"
puts "*          ucFiberType.1: $Profile(ucFiberType.1)"
puts "*           ulPackageOUI: $Profile(ulPackageOUI)"
puts "* ulTransceiverVendorOUI: $Profile(ulTransceiverVendorOUI)"
puts "*                 ucName: $Profile(ucName._char_)"
puts "*           ucPartNumber: $Profile(ucPartNumber._char_)"
puts "*             ucRevision: $Profile(ucRevision._char_)"
puts "*         ucSerialNumber: $Profile(ucSerialNumber._char_)"
puts "*         ucDateCodeYear: $Profile(ucDateCodeYear._char_)"
puts "*        ucDateCodeMonth: $Profile(ucDateCodeMonth._char_)"
puts "*          ucDateCodeDay: $Profile(ucDateCodeDay._char_)"
puts "*    ucDateCodeLotNumber: $Profile(ucDateCodeLotNumber._char_)"
puts "*             ucReserved: $Profile(ucReserved._char_)"
puts "********************************************************\n"

# Unset the structure
unset tx
unset counter
unset fill_pat
unset cap
unset packet
unset cap_count
unset Profile


#UnLinking from the chassis
puts "UnLinking from the chassis now.."
ETUnLink
puts "DONE!"


