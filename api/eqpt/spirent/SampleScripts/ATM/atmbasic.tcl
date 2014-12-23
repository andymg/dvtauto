#############################################################################################
# atmbasic.tcl                                                                              #
#                                                                                           #
# - Sets up two streams each on two cards then starts, stops the streams on card 1.         #
# - Displays Tx Rx counts on both cards.                                                    #
#                                                                                           #
# - Creates numStreams PVC streams starting at 0/32 (0/20 hex) and incrementing upward.     #
#                                                                                           #
# - Program will work with two cards connected back to back without a DUT.                  #
# - AT-9155 ATM Cards are installed in slot 1 and slot 3.                                   #
#############################################################################################

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

#cards in slots 1...
set iHub 0
set iSlot 0
set iPort 0

#... and 3
set iHub2 0
set iSlot2 2
set iPort2 0

set numStreams 2


##################    PROCEDURES   #######################


##########################################################
# LIBCMD error handler                                   #
##########################################################
proc LIBCMD {args} {
	set iResponse [uplevel $args]
	if {$iResponse < 0} {
	   puts "$args :  $iResponse"
	}
}


#########################################################
# waitForInput                                          #
# - Simple wait until ENTER is pressed routine          #
#########################################################

proc waitForInput {} {
	puts "\nPress ENTER for per stream counts"
	gets stdin response
}


#######################################################################
# connectToSmartBits                                                  #
#                                                                     #
# - Checks that SmartLib.tcl is loaded, exits if not found.           #
# - Checks for link with chassis.  If not linked, will link to IP     #
#   address if one was passed in, will prompt user for IP otherwise   #
#######################################################################

proc connectToSmartBits { {ipaddr 0} } {
   # Check for library load
   if {[uplevel #0 info exists __SMARTLIB_TCL__] < 1} {
        puts "SmartLibrary not loaded - source SmartLib.tcl before starting program"
        gets stdin response
        exit
   }

   # Check for link state, connect if not linked
   if {[ETGetLinkStatus] < 1} {
        if {$ipaddr == 0} {
             puts "Chassis not linked, Enter SmartBits chassis IP address"
             gets stdin ipaddr
        } 

        set retval [NSSocketLink $ipaddr 16385 $RESERVE_ALL]
   }
}

#########################################################
# setATMOC3                                             #
# - Set line parameters for ATM OC-3 (AT-9155) card.    #
#########################################################

proc setATMOC3 { H S P } {

   struct_new LineParams ATMLineParams
   set LineParams(ucFramingMode)  $::ATM_OC3_FRAMING
   set LineParams(ucTxClockSource)  $::ATM_INTERNAL_CLOCK
   set LineParams(ucCellScrambling)  $::TRUE
   set LineParams(ucHecCoset)  $::TRUE
   set LineParams(ucRxErroredCells)  $::ATM_CORRECT_ERRORED_CELLS
   set LineParams(ucLoopbackEnable)  $::ATM_LOOPBACK_DISABLED

   for {set i 0} {$i < 4} {incr i} {
         set LineParams(ucIdleCellHeader.$i) 0
   }

   LIBCMD HTSetStructure $::ATM_LINE 0 0 0 LineParams 0 $H $S $P

}

############################################################
# getMaxStreamCount                                        #
# - Queries card for the maximum number of streams it can  #
#   support and returns value to caller                    #
############################################################

proc getMaxStreamCount {H S P} {

   struct_new CardCapabilities ATMCardCapabilities

   LIBCMD HTGetStructure $::ATM_CARD_CAPABILITY 0 0 0 CardCapabilities 0 $H $S $P

   return $CardCapabilities(uiMaxStream)
}

#########################################################
# getMaxBandwidth                                       #
# - Queries card for the maximum bandwidth of card      #
#########################################################

proc getMaxBandwidth {H S P} {

   struct_new CardCapabilities ATMCardCapabilities
   LIBCMD HTGetStructure $::ATM_CARD_CAPABILITY 0 0 0 CardCapabilities 0 $H $S $P
   return $CardCapabilities(ulLineCellRate)

}


##############################################################
# clearATMStream                                             #
#  - disconnects and resets all streams on target card       #
##############################################################

proc clearATMStream {H S P} {
   struct_new ATM ATMStreamControl

   set maxStreamsOnCard [getMaxStreamCount $H $S $P]
   #Disconnect all streams
   set ATM(ucAction) $::ATM_STR_ACTION_DISCONNECT
   set ATM(ulStreamIndex) 0
   set ATM(ulStreamCount) $maxStreamsOnCard
   LIBCMD HTSetStructure $::ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P

   # Reset All Streams
   set ATM(ucAction) $::ATM_STR_ACTION_RESET
   set ATM(ulStreamIndex) 0
   set ATM(ulStreamCount) $maxStreamsOnCard
   LIBCMD HTSetStructure $::ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P

}


########################################################################
# createATMStream                                                      #
#                                                                      #
# - Sets up the stream parameters such as type encapsulation,          #
#   rate class, PCR and cell header.  Equivalent to the values         #
#   set on the top part of the Stream Setup window in                  #
#   SmartWindows                                                       #
#                                                                      #
# - Accpets params for encapsulation (either SNAP or 1577) VPI/VCI     #
#   and CLP values                                                     #
#                                                                      #
# - If you are sending the traffic through a device                    #
#   you will need to create VCCs with the corresponding VPI:VCI        #
########################################################################

proc createATMStream {H S P {streams 5} {encap snap} {vpi 0} {vci 0x20} {clp 0} } {

   struct_new MyPVC ATMStream
   puts "\nCreating $streams new streams on card [expr $S + 1]"

   for {set i 0} {$i < $streams} {incr i} {
         set MyPVC(uiIndex) $i
         set MyPVC(ucConnType) $::ATM_PVC 

         # set encapsulation to SNAP or CLIP depending on what was passed in as encap
         if {$encap == "snap"} {
              set MyPVC(ucEncapType) $::STR_ENCAP_TYPE_NULL
         } else {
	          set MyPVC(ucEncapType) $::STR_ENCAP_TYPE_RFC1577 
         }

         set MyPVC(ucGenRateClass) $::STR_RATE_CLASS_UBR

         # divide total line rate by number of streams to get Peak Cell Rate for each stream
         # We call getMaxBandwidth proc to get cards max cell rate
         set maxRate [getMaxBandwidth $H $S $P]
         set MyPVC(ulGenPCR) [expr $maxRate / $streams]

         # Assemble cell header.  Since header is 32 bits arranged as follows:
         # GFC | VPI | VCI | CLP
         #  0    00   0000    0
         # We use hex multiplication to shift VPI 20 bit places left and VCI 4 bit places left
         set cellHeader [expr ($vpi * 0x00100000) + ($vci * 0x10) + $clp]

         # Add counter * 10 hex (for 4 bit position shift) to LSB of VCI for increment 
         set MyPVC(ulCellHeader) [expr $cellHeader + ($i * 0x10)]

         # display cell headers as streams are created 08X formats as 8 position hex with leading zeroes
         puts -nonewline "Creating stream $MyPVC(uiIndex) - Cell Header [format "%08X" $MyPVC(ulCellHeader)]"
         puts " - PCR $MyPVC(ulGenPCR) cells/sec"
         # send to card
         LIBCMD HTSetStructure $::ATM_STREAM 0 0 0 MyPVC 0 $H $S $P
  }
}

#############################################################
# createBridgedFrame                                        #
#                                                           #
#############################################################

proc createBridgedFrame {H S P {streams 5} {destMAC {0x00 0x00 0xAA 0xBB 0xCC 0x00} } } {

   set frameLength 60
   set userDataLength 24

   struct_new FrameDef ATMFrameDefinition 

      set FrameDef(uiStreamIndex) 0
      set FrameDef(uiFrameLength) $frameLength
      set FrameDef(uiDataLength) $userDataLength
      #Set RFC 1483 bridged header type
      set FrameDef(ucFrameData.0) 0xAA
      set FrameDef(ucFrameData.1) 0xAA
      set FrameDef(ucFrameData.2) 0x03
      set FrameDef(ucFrameData.3) 0x00
      set FrameDef(ucFrameData.4) 0x80
      set FrameDef(ucFrameData.5) 0xC2
      set FrameDef(ucFrameData.6) 0x00
      set FrameDef(ucFrameData.7) 0x07
      set FrameDef(ucFrameData.8) 0x00
      set FrameDef(ucFrameData.9) 0x00
      # destination MAC
      for {set i 0} {$i < 6} {incr i} {
  	set FrameDef(ucFrameData.[expr $i + 10])  [lindex [split $destMAC] $i ] 
      }
      # source MAC - set to Slot number of card 1
      set FrameDef(ucFrameData.16) 0x00
      set FrameDef(ucFrameData.17) 0x00
      set FrameDef(ucFrameData.18) 0xAA
      set FrameDef(ucFrameData.19) 0x00
      set FrameDef(ucFrameData.20) 0x00
      set FrameDef(ucFrameData.21) [expr $S + 1]
      # Type 0800
      set FrameDef(ucFrameData.22) 0x08
      set FrameDef(ucFrameData.23) 0x00

      # Fill rest of frame with 33
      set FrameDef(uiFrameFillPattern) 0x3333
      set FrameDef(ulFrameFlags) 0
      LIBCMD HTSetStructure $::ATM_FRAME_DEF 0 0 0 FrameDef 0 $H $S $P

      # make num_streams - 1 copies
      struct_new FrameCopy ATMFrameCopyReq
      set FrameCopy(uiStartStrNum) 1
      set FrameCopy(uiStrCount) [expr $streams - 1]
      set FrameCopy(uiNumMods) 0
      LIBCMD HTSetStructure $::ATM_FRAME_COPY 0 0 0 FrameCopy 0 $H $S $P
}

############################################################
# connectATMStream                                         #
#                                                          #
############################################################

proc connectATMStream {H S P {streams 5} } {
   struct_new ATM ATMStreamControl
   set ATM(ulStreamIndex) 0
   set ATM(ulStreamCount) $streams
   set ATM(ucAction) $::ATM_STR_ACTION_CONNECT
  LIBCMD HTSetStructure $::ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P

}

##############################################################################
# startATMStream                                                             #
# - index is the first stream in the group to be acted upon                  #
# - count is the number of streams to act upon.                              #
# - For all streams index = 0 and count = the number of streams on the card  #
# - For the streams from 3 to 5, index = 3 and count = 2                     #
##############################################################################

proc startATMStream {H S P {index 0} {count 5} } {
   struct_new ATM ATMStreamControl
   set ATM(ulStreamIndex) $index
   set ATM(ulStreamCount) $count
   set ATM(ucAction) $::ATM_STR_ACTION_START
  LIBCMD HTSetStructure $::ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P
}

############################################################
# stopATMStream                                            #
# - Same as startATMStream                                 #
############################################################

proc stopATMStream {H S P {index 0} {count 5} } {
   struct_new ATM ATMStreamControl
   set ATM(ulStreamIndex) $index
   set ATM(ulStreamCount) $count
   set ATM(ucAction) $::ATM_STR_ACTION_STOP
  LIBCMD HTSetStructure $::ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P
}


#################################################################
# showATMCount                                                  #
# - Displays the per stream information (other counts triggers  #
#   CRC32 errors etc are also available with this iType)        #
#################################################################

proc showATMCount {H S P streams} {

  struct_new ExtVCCInfo ATMExtVCCInfo
  LIBCMD HTGetStructure $::ATM_STREAM_EXT_VCC_INFO 0 $streams 0 ExtVCCInfo 0 $H $S $P

  for {set i 0} {$i < $streams} {incr i} {
        puts  "==> Card [expr $S + 1] - Stream $i - Cell Header [format %08X $ExtVCCInfo(status.$i.ulCellHeader) Card [expr $S + 1]]" 
        puts  "   -------------------------------------------"
        puts  "   | Tx Frames |   $ExtVCCInfo(status.$i.ulTxFrame)"
        puts  "   | Rx Frames |   $ExtVCCInfo(status.$i.ulRxFrame)"
        puts  "   -------------------------------------------"
  }

}



################    MAIN    #################

# connect to SmartBits chassis
connectToSmartBits

# set line parameters for both cards
setATMOC3  $iHub $iSlot $iPort
setATMOC3  $iHub2 $iSlot2 $iPort2

# erase any existing streams...
clearATMStream $iHub $iSlot $iPort
clearATMStream $iHub2 $iSlot2 $iPort2

# ...and create numStreams new ones
createATMStream $iHub $iSlot $iPort $numStreams
createATMStream $iHub2 $iSlot2 $iPort2 $numStreams

# set frame data for the new streams Destination MAC is passed in
createBridgedFrame $iHub $iSlot $iPort $numStreams {0x00 0x00 0x11 0x11 0x11 0x00}
createBridgedFrame $iHub2 $iSlot2 $iPort2 $numStreams {0x00 0x00 0x22 0x22 0x22 0x00}

# connect the streams
connectATMStream $iHub $iSlot $iPort $numStreams
connectATMStream  $iHub2 $iSlot2 $iPort2 $numStreams

# start all streams on card 1 transmitting
startATMStream $iHub $iSlot $iPort 0 $numStreams

# display message and wait for user to press ENTER
puts "Transmitting"
puts "Press ENTER key to stop"
gets stdin response

puts -nonewline "Stopping...."
# stop all streams on card 1
stopATMStream $iHub $iSlot $iPort 0 $numStreams
puts "done"

# display the frame counts for the two cards with a blank line in between
puts "Getting per stream counts\n"
showATMCount $iHub $iSlot $iPort $numStreams
puts ""
showATMCount $iHub2 $iSlot2 $iPort2 $numStreams

# Unlink from chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
