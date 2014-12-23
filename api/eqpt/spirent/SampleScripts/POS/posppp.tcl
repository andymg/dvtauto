#####################################################################
# posppp.tcl                                                        #
#                                                                   #
# Program tested against two POS-3500As in a SmartBits 600          #
#                                                                   #
# Sets up PPP on POS                                                #
# ASSUMES:                                                          #
# SmartLib.tcl has been sourced                                     #
# You will need to set ipaddr to the address of the local box       #
# POS cards connected back to back                                  #
#                                                                   #
# NOTE: This script works on the following cards:                   #
#       - POS-6500/6502                                             #
#                                                                   #
#####################################################################


if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/smartlib.tcl"
} else {
         set libPath "../../../../include/smartlib.tcl"
}

# if it is not loaded, try to source it at the default path
if { ! [info exists __SMARTLIB_TCL__] } {
     if {[file exists $libPath]} {
          source $libPath
   } else {   
               
            # Enter the location of the "smartlib.tcl" file or enter "Q" or "q" to quit
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

# SET CONSTANTS

set iHub 0
set iSlot 0
set iPort 0

set iHub2 0
set iSlot2 1
set iPort2 0

# address of card stack
set ppp_ip1 "10.1.1.[expr $iSlot + 1]"
set ppp_ip2 "10.1.1.[expr $iSlot2 + 1]"

# address of SmartMetricsStreams
set stream1ip 10.1.1.100
set stream2ip 10.1.1.200

# 10,000 packets
set burst_count 10000

# number of captured packets to display
set packets_per_display 5

# packet length
set data_length 120

    ################################################################################
    ################################################################################
    ############################   PROCEDURES   ####################################
    ################################################################################
    ################################################################################

################### LIBCMD ####################################
# LIBCMD error handler (from misc.tcl)
###############################################################
proc LIBCMD {args} {
	set iResponse [uplevel $args]
	if {$iResponse < 0} {
	   puts "$args :  $iResponse"
	}
}
#################### END LIBCMD ###############################

#####################################################################
# wait_for_input
# Pause routine that allows user to view error messages
#####################################################################
proc wait_for_input {} {

   puts "Press ENTER to continue"
   gets stdin response
   return $response
}
#####################################################################

#####################################################################
# reset_capture   stop and restart capture
#####################################################################
proc reset_capture { H S P } {

#LIBCMD HTSetCommand $::L3_CAPTURE_OFF_TYPE 0 0 0 "" $H $S $P
#LIBCMD HTSetCommand $::L3_CAPTURE_ALL_TYPE 0 0 0 "" $H $S $P

# Capture set up
struct_new cap NSCaptureSetup
set cap(ulCaptureMode)   $::CAPTURE_MODE_FILTER_ON_EVENTS
set cap(ulCaptureLength) $::CAPTURE_LENGTH_ENTIRE_FRAME
set cap(ulCaptureEvents) $::CAPTURE_EVENTS_ALL_FRAMES

LIBCMD HTSetStructure $::NS_CAPTURE_SETUP 0 0 0 cap 0 $H $S $P
after 2000

# Start capture
LIBCMD HTSetCommand $::NS_CAPTURE_START 0 0 0 0 $H $S $P

}
#####################################################################

#####################################################################
# show_packet 
# displays the contents of num_packets formatted in readable form
#####################################################################
proc show_packet { H S P num_packets } {

global data_length NS_CAPTURE_DATA_INFO NS_CAPTURE_COUNT_INFO

# Stop capture
LIBCMD HTSetCommand $::NS_CAPTURE_STOP 0 0 0 0 $H $S $P

struct_new CapCount NSCaptureCountInfo
LIBCMD HTGetStructure $NS_CAPTURE_COUNT_INFO 0 0 0 CapCount 0 $H $S $P
   if {$CapCount(ulCount) < 1} {
       puts "No packets captured on card [expr $S + 1]"
   } else {
      if {$CapCount(ulCount) < $num_packets} {
      set num_packets $CapCount(ulCount)
      }
    struct_new CapData NSCaptureDataInfo
    for {set i 0} {$i < $num_packets} {incr i} {
         set capData(ulFrameIndex)         $i
         set capData(ulRequestedLength)    2048
         LIBCMD HTGetStructure $NS_CAPTURE_DATA_INFO 0 0 0 CapData 0 $H $S $P
#         for {set j 0} {$j < [expr $data_length + 4]} {incr j} {}
         for {set j 0} {$j < $CapData(ulRetrievedLength)} {incr j} {
         set iData 0
                  if {[expr $j % 16] == 0} {
                        puts ""
                        puts -nonewline [format "%4i:   " $j]
                  }
                  puts -nonewline " "
                  puts -nonewline [format "%02X" $CapData(ucData.$j._ubyte_)]                     
         }
         puts ""
	 if {$i < [expr $num_packets - 1]} {
	 puts ""
	 puts "Press ENTER to display packet [expr $i + 2]"
	 gets stdin response
	 } else {
	 puts "End of captured data!"
	 }
    }
 }
}
#####################################################################

####################################################################
#
#####################################################################
proc set_line_cfg {H S P} {
struct_new MyLineCfg POSCardLineConfig
   set MyLineCfg(ucCRC32Enabled) 0
   set MyLineCfg(ucScramble) 1
LIBCMD HTSetStructure $::POS_CARD_LINE_CONFIG 0 0 0 MyLineCfg 0 $H $S $P
}

####################################################################
# set_encap
#####################################################################
proc set_encap {H S P} {
struct_new MyEncap POSCardPortEncapsulation
   set MyEncap(ucEncapStyle) $::PROTOCOL_ENCAP_TYPE_STD_PPP
  LIBCMD HTSetStructure $::POS_CARD_PORT_ENCAP 0 0 0 MyEncap 0 $H $S $P
}
####################################################################

############################################################################
# PPP Configuration
#
############################################################################
proc ppp_config {H S P our_ip peer_ip} {

  struct_new MyPPPParamCfg PPPParamCfg

  set MyPPPParamCfg(ulpppInstance) 0
  set MyPPPParamCfg(ulpppCount) 1

  # From PPPItems.h
  # * Current PPP negotiation options:
  # *	PPPO_MRU          		0x0001
  # * PPPO_USECHAPAUTH  		0x0010
  # * PPPO_USEPAPAUTH   		0x0020
  # * PPPO_USEMAGIC     		0x0080
  # * PPPO_USENONE			0x0000
  #
  # Use OR to combine options as shown.
  # We ask for MRU negotiation and Magic Number
  set MyPPPParamCfg(uipppWeWish) [expr $::PPPO_USEMAGIC + $::PPPO_MRU]
  # We MUST get at least Magic Number (will fail without)
  set MyPPPParamCfg(uipppWeMust) $::PPPO_USEMAGIC
  # But we CAN support any of the options
  set MyPPPParamCfg(uipppWeCan) [expr $::PPPO_USEMAGIC + $::PPPO_MRU]
  set MyPPPParamCfg(ucpppEnablePPP) 1

  set MyPPPParamCfg(uipppMRU) 1500
  set MyPPPParamCfg(uipppMaxFailure) 5
  set MyPPPParamCfg(uipppMaxConfigure) 10
  set MyPPPParamCfg(uipppMaxTerminate) 2
  # 0 generates random Magic Number
  set MyPPPParamCfg(ulpppMagicNumber) 2
  set MyPPPParamCfg(uipppRestartTimer) 3
  set MyPPPParamCfg(uipppRetryCount) 1
  set MyPPPParamCfg(ucpppIPEnable) 1
  for {set i 0} {$i < 4} {incr i} {
    set octet [lindex [split $our_ip .] $i]
    set MyPPPParamCfg(ucpppOurIPAddr.$i) $octet
  }
  # Default Gateway is the same as the peer ip in 
  for {set j 0} {$j < 4} {incr j} {
    set octet [lindex [split $peer_ip .] $j]
    set MyPPPParamCfg(ucpppPeerIPAddr.$j) $octet
  }
  LIBCMD HTSetStructure $::PPP_SET_CONFIG 0 0 0 MyPPPParamCfg 0 $H $S $P
}

############################################################################


####################################################################
# POS_set_stream
# Sets up IP stream on card.  Caller passes in Hub Slot Port of Tx card
# (H S P) and Hub Slot Port of Rx card (H2 S2 P2).  Procedure uses slot
# numbers to set IP addresses (second octet is derived from card slot number.
#####################################################################
proc POS_set_stream {H S P source_ip dest_ip} {
  struct_new streamIP StreamIP

      set streamIP(ucActive) 1
      set streamIP(ucProtocolType) $::L3_STREAM_IP
      set streamIP(uiFrameLength) $::data_length
      set streamIP(ucTagField) 1
      set streamIP(TypeOfService) 0
      set streamIP(TimeToLive) 10
      # Source IP
      for {set i 0} {$i < 4} {incr i} {
        set octet [lindex [split $source_ip .] $i]
        set streamIP(SourceIP.$i) $octet
      }
      # Destination IP
      for {set j 0} {$j < 4} {incr j} {
        set octet [lindex [split $dest_ip .] $j]
        set streamIP(DestinationIP.$j) $octet
      }
      set streamIP(Netmask.0) 255
      set streamIP(Netmask.1) 255
      set streamIP(Netmask.2) 255
      set streamIP(Netmask.3) 0
      set streamIP(Protocol) 4
  LIBCMD HTSetStructure $::L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $H $S $P

  ###########################################
  # Define stream extension
  # Multiburst mode with Burst Count of 10,000
  # and an MBurstCount of 2 sends two 10,000 packet bursts
  ###########################################
  struct_new extensionIP L3StreamExtension
       set extensionIP(ulFrameRate) 5000
       set extensionIP(ulTxMode) $::L3_SINGLE_BURST_MODE
       set extensionIP(ulBurstCount) $::burst_count
       set extensionIP(ulMBurstCount) 0
       set extensionIP(ulBGPatternIndex) 0
       set extensionIP(ulBurstGap) 0
       set extensionIP(uiInitialSeqNumber) 0
  LIBCMD HTSetStructure $::L3_DEFINE_STREAM_EXTENSION 0 0 0 extensionIP 0 $H $S $P

}

############################################################################
# LCP Control
# Passing open as an argument opens LCP; anything else closes LCP
############################################################################
proc lcp_control {H S P action } {

  struct_new MyPPPControlCfg PPPControlCfg

  set MyPPPControlCfg(ulpppInstance) 0
  set MyPPPControlCfg(ulpppCount) 1
  if {$action == "open"} {
     puts "Opening LCP"
     set MyPPPControlCfg(ucpppAction) $::PPP_OPEN_LCP
  } else {
     puts "Closing LCP"
     set MyPPPControlCfg(ucpppAction) $::PPP_CLOSE_LCP  
  }
  LIBCMD HTSetStructure $::PPP_SET_CTRL 0 0 0 MyPPPControlCfg 0 $H $S $P  
}
############################################################################

####################################################################
# lcp_status
# Uses while loop to poll until LCP status is UP
############################################################################
proc lcp_status {H S P} {

  struct_new MyPPPStatusInfo PPPStatusInfo

  LIBCMD HTGetStructure $::PPP_STATUS_INFO 0 1 0 MyPPPStatusInfo 0 $H $S $P

  set timeout_count 20
  set loop_count 0

  while {$MyPPPStatusInfo(ucppplcpState) > 0} {
     puts "Current LCP status on card [expr $S + 1] is $MyPPPStatusInfo(ucppplcpState)"
     after 2500
     LIBCMD HTGetStructure $::PPP_STATUS_INFO 0 1 0 MyPPPStatusInfo 0 $H $S $P
     incr loop_count
     if {$loop_count > $timeout_count} {
        break
     }
  }
  if {$MyPPPStatusInfo(ucppplcpState) == 0} {
     puts "Final LCP State on card [expr $S + 1] is UP"
  } elseif {$MyPPPStatusInfo(ucppplcpState) == 1} {
     puts "Final LCP State on card [expr $S + 1] is DOWN"
  } else {
     puts "Final LCP State on card [expr $S + 1] is an interim or undefined state"
  }
}
############################################################################

#################################################################
# show_counter_data
#################################################################
proc show_lcp_counts {H S P} {

struct_new MyPPPStatsInfo PPPStatsInfo

LIBCMD HTGetStructure $::PPP_STATS_INFO 0 1 0 MyPPPStatsInfo 0 $H $S $P

puts "================================================================="
puts " 	              LCP Counts Card [expr $S + 1] 	"
puts "================================================================="
puts "     LCP Configure Requests Sent[format "%10d" $MyPPPStatsInfo(ullcpConfReqSent)]"
puts "     LCP Configure Ack Sent	[format "%10d" $MyPPPStatsInfo(ullcpConfAckSent)]"
puts "     LCP Configure Nak Sent	[format "%10d" $MyPPPStatsInfo(ullcpConfNakSent)]"
puts "     LCP Configure Reject Sent	[format "%10d" $MyPPPStatsInfo(ullcpConfRejectSent)]"
puts "     LCP Terminate Requests Sent[format "%10d" $MyPPPStatsInfo(ullcpTermReqSent)]"
puts "     LCP Terminate Ack Sent	[format "%10d" $MyPPPStatsInfo(ullcpTermAckSent)]"
puts "     LCP Protocol Reject Sent	[format "%10d" $MyPPPStatsInfo(ullcpTermReqSent)]"
puts "     LCP Discard Requests Sent	[format "%10d" $MyPPPStatsInfo(ullcpDiscardReqSent)]"
puts "     LCP Code Reject Sent	[format "%10d" $MyPPPStatsInfo(ullcpCodeRejectSent)]"
puts "     LCP Reset Request Sent	[format "%10d" $MyPPPStatsInfo(ullcpResetReqSent)]"
puts "     LCP Reset Ack Sent		[format "%10d" $MyPPPStatsInfo(ullcpResetAckSent)]"
puts "================================================================="

}
##################################################################

##############################################################   
# wait_for_stop
# loop checks Tx Rate (packets/sec) and waits until it is zero
# Failure to wait until transmission is complete can result
# in false counter readings.
############################################################## 
proc wait_for_txstop {H S P} {

   struct_new count HTCountStructure
   after 1000
   HTGetCounters count $H $S $P

   while {($count(TmtPktRate) != 0)} {
       HTGetCounters count $H $S $P
       after 200
   }
}
############################################################## 
proc show_counts { } {
  struct_new cs HTCountStructure*2
  LIBCMD HGGetCounters cs

  puts "------------------------------------------------------------"
  puts "	  	    Test Packet Counts"
  puts "------------------------------------------------------------"
  puts "    	        Card [expr $::iSlot + 1]			Card [expr $::iSlot2 +1]"
  puts "------------------------------------------------------------"
  puts "Tx Packets 	$cs(0.TmtPkt)		|	$cs(1.TmtPkt)"
  puts "Rx Packets 	$cs(0.RcvPkt)		|	$cs(1.RcvPkt)"
  puts "------------------------------------------------------------"

}
###############################################################################


    ###############################################################
    ###############################################################
    ####################      MAIN      ###########################
    ###############################################################
    ###############################################################

# Check link state and prompt for connect IP if not already linked
  if {[ETGetLinkStatus] < 0} {  
     puts "SmartBits not linked - Enter chassis IP address"
     gets stdin ipaddr
     set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]  
     if {$retval < 0 } {
	  puts "Unable to connect to $ipaddr. Please try again."
	  exit 
     }  
  } else {
     puts "Smartbits already linked"
  }

 
# Explicitly reserve cards 
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

###################
# Set up group
###################
HGSetGroup ""
HGAddtoGroup $iHub $iSlot $iPort
HGAddtoGroup $iHub2 $iSlot2 $iPort2

# reset card and erase any streams
HGResetPort $RESET_FULL

###########################################
# Check both cards belong to group before
# testing.
###########################################
if {([HGIsHubSlotPortInGroup $iHub $iSlot $iPort] < 1) || ([HGIsHubSlotPortInGroup $iHub2 $iSlot2 $iPort2] < 1)} {
    puts "Group not configured correctly"
    gets stdin response
    exit
}

set_line_cfg $iHub $iSlot $iPort
set_line_cfg $iHub2 $iSlot2 $iPort2

set_encap $iHub $iSlot $iPort
set_encap $iHub2 $iSlot2 $iPort2

POS_set_stream $iHub $iSlot $iPort $stream1ip $stream2ip
POS_set_stream $iHub2 $iSlot2 $iPort2 $stream2ip $stream1ip

ppp_config $iHub $iSlot $iPort $ppp_ip1 $ppp_ip2
ppp_config $iHub2 $iSlot2 $iPort2 $ppp_ip2 $ppp_ip1

lcp_control $iHub $iSlot $iPort open
lcp_control $iHub2 $iSlot2 $iPort2 open

lcp_status $iHub $iSlot $iPort 
lcp_status $iHub2 $iSlot2 $iPort2


###########################################
# Clear counters with HGClearPort and
# create Counter Strucutres to hold count data
###########################################
LIBCMD HGClearPort
# reset capture on card 2
reset_capture $iHub2 $iSlot2 $iPort2

#####################################################
# Start transmission with HGStart
# wait_for_txstop waits until burst is done
####################################################
LIBCMD HGStart
wait_for_txstop $iHub $iSlot $iPort 
wait_for_txstop $iHub2 $iSlot2 $iPort2

puts "Displaying Counts"
show_counts

puts "Displaying LCP Counts"
wait_for_input
show_lcp_counts $iHub $iSlot $iPort 
wait_for_input
show_lcp_counts $iHub2 $iSlot2 $iPort2

puts "Displaying Capture Data from card [expr $iSlot2 + 1]"
wait_for_input
show_packet $iHub2 $iSlot2 $iPort2 $packets_per_display


