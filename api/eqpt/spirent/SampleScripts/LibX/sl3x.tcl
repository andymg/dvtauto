# sl3x.tcl
#
# Layer 3 LibX procedures for SmartLib.tcl environment
#
#


namespace eval l3x {

 namespace export set_streamtcp set_streamip set_streamipx set_streamudp \
         show_stream set_arp show_l3 set_l3 set_l2 set_streamzero\

########################### LAYER 3 PROCS ##################################
############################################################################
# Procedures to create, cobfigure and view IP IPX and UDP streams from command line.
#
# Takes a list for the txgroup and rxgroup
#      set_stream $card1 $card2 
# will set streams with 0 0 0 as source and 0 1 0 as the destination
#
# Setting a group of cards such as:
#	set txgroup [list $card1 $card2 $card3]
#       set rxgroup [list $card4 $card5 $card6]
#  allows you to set up stream pairs on all cards with
#     set_stream $txgroup $rxgroup
# The script automatically adjusts for different size group lists
#
# Streams will be generated with MAC addresses with 4th byte 
#  and the IP addresses with the 2nd octet set to card number (slot + 1) 
#
# Streams will be class A 10.x.x.x streams with Class C 255.255.255.0
# subnet mask.
#
# The default stream can be changed by passing in a different IP source 
# or destination IP.  The format of the default is 10.X.10.10.
# Any octet set as X will substitute the card number when the addresses
# are generated.  So for example, a source IP address for card 4 with
# the default 10.X.10.10 would have the address generated as 10.4.10.10.
#
# It is strongley suggested that you set one octet with X to ensure streams
# on different cards do not accidentally get set with the same IP address.
#
#####################################################################
##			IP STREAM				   ##
#####################################################################
proc set_streamip { {txgroup} {rxgroup} {NUM_STREAMS 10}  \
	{source_ip 10.X.1.10} {destination_ip 10.X.1.10} {TOS 0x00} } {

  global L3_DEFINE_MULTI_IP_STREAM L3_STREAM_IP L3_DEFINE_IP_STREAM L3_MOD_IP_STREAM

  # Check for link with chassis
  check_link

  # set constants
  set DATA_LENGTH 100
  set SOURCE_STREAM 1
  set SEQUENCE [expr $NUM_STREAMS - 1]

  # Setup structures
  struct_new streamIP StreamIP
  struct_new incrementIP StreamIP

  set gateway_ip 10.X.1.1

  ###################################################
  ############### GROUP SETUP #######################
  ###################################################
  # Loop count is set to the larger number of cards
  if {[llength $txgroup] >= [llength $rxgroup]} {
     set maxcards [llength $txgroup]
  } else {
     set maxcards [llength $rxgroup]
  }
  set txcount 0
  set rxcount 0
  # Split group and assign elements to Hub Slot Port variables for the Tx and Rx cards
  for {set i 0} {$i < $maxcards} {incr i} {    
       set source_card [split [lindex $txgroup $txcount]]
           set source_card [string trim $source_card { \ { } }]
	   set H [lindex $source_card 0]
	   set S [lindex $source_card 1]
	   set P [lindex $source_card 2]
       set dest_card [split [lindex $rxgroup $rxcount]]
           set dest_card [string trim $dest_card { \ { } }]
	   set H2 [lindex $dest_card 0]
	   set S2 [lindex $dest_card 1]
	   set P2 [lindex $dest_card 2]
       # If the count is beyond the number of cards in the group, reset to zero
       # This enables many to one or one to many by varying the number of cards
       # in each group      
       incr txcount
       if {$txcount > [expr [llength $txgroup] - 1]} {
	  set txcount 0
       }
       incr rxcount
       if {$rxcount > [expr [llength $rxgroup] - 1]} {
    	  set rxcount 0
       }
       #######################################################################
       ###################### STREAM SETUP ###################################
       #######################################################################
        set streamIP(ucActive)  1
        set streamIP(ucProtocolType)  $L3_STREAM_IP
        set streamIP(uiFrameLength) $DATA_LENGTH
        set streamIP(ucRandomLength)  0
        set streamIP(ucTagField)  1
        set streamIP(DestinationMAC.0)  0
        set streamIP(DestinationMAC.1)  0
        set streamIP(DestinationMAC.2)  0
        set streamIP(DestinationMAC.3)  [expr $S2 + 1]
        set streamIP(DestinationMAC.4)  0
        set streamIP(DestinationMAC.5)  1
        set streamIP(SourceMAC.0)  0
        set streamIP(SourceMAC.1)  0
        set streamIP(SourceMAC.2)  0
        set streamIP(SourceMAC.3)  [expr $S + 1]
        set streamIP(SourceMAC.4)  0
        set streamIP(SourceMAC.5)  1
        set streamIP(TimeToLive)  10
	# DESTINATION IP
	for {set j 0} {$j < 4} {incr j} {
           set octet [lindex [split $destination_ip .] $j]
           if {$octet == "X" } {
              set streamIP(DestinationIP.$j)  [expr $S2 +1]
           } else {
	      set streamIP(DestinationIP.$j)  $octet
           }
	}
	# SOURCE IP
 	for {set k 0} {$k < 4} {incr k} {
           set octet [lindex [split $source_ip .] $k]
           if { $octet == "X" } {
              set streamIP(SourceIP.$k)  [expr $S +1]
	   } else {
	      set streamIP(SourceIP.$k)  $octet
           }
	}
	# GATEWAY IP (ROUTER PORT)
	for {set l 0} {$l < 4} {incr l} {
           set octet [lindex [split $gateway_ip .] $l]
           if { $octet == "X" } {
              set streamIP(Gateway.$l)  [expr $S + 1]
           } else {
	   set streamIP(Gateway.$l)  $octet
           }           
        }
        set streamIP(Netmask.0)  255
        set streamIP(Netmask.1)  255
        set streamIP(Netmask.2)  255
        set streamIP(Netmask.3)  0
	# Protocol Type 4 = IP in IP
        set streamIP(Protocol)  4
	set streamIP(TypeOfService)  $TOS

        #####################################
        # Stream Creation
        # 1) if NUM_STREAMS was passed in by caller as zero
        #    or less SEQUENCE will be negative.  We check
        #    for this condititon and erase all streams on the card
        #    if this condition is true
        # 2) if SEQUENCE is zero or more, we get the number of streams
        #    currently on the card by calling check_stream procedure.
        #    If the number is one there are no streams on the card, and
        #    we use the L3_DEFINE stream creation procedure.  If the number
        #    of streams is 2 or more we use L3_MOD stream creation to append
        #    the new streams to the card.  We then set the source_stream variable
        #    to point to the newly created appended base stream, for the following
        #    L3_DEFINE_MULTI command
        # 3) The L3_DEFINE_MULTI command creates the number of additional streams
        #    specified by the value of SEQUENCE.  If SEQUENCE is zero, there will
        #    be zero additional streams created, if it is 1, one additional stream
        #    will be created and so on.
        #####################################

        if {$SEQUENCE < 0} {
            # ERASE ANY STREAMS ON CARD
            # "" in place of a stream structure erases all streams on card
            LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 "" 0 $H $S $P
        } else {
            set streams_on_card [l3x::check_stream $H $S $P]
            if { $streams_on_card < 2 } {
               # Create a single stream with L3_DEFINE
               LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $H $S $P
            } else {
               # Append a new stream at the end of the stream list
               LIBCMD HTSetStructure $L3_MOD_IP_STREAM $streams_on_card 0 0 streamIP 0 $H $S $P
               # set SOURCE_STREAM to point to the new stream
               set SOURCE_STREAM $streams_on_card
	    }
            ############################################################
            # Add additional streams with L3_DEFINE_MULTI_IP_STREAM
            #    Last byte of Destination MAC will increment by 1
            #    Last byte of Source MAC will increment by 1
            #    Last byte of Destination and Source IPs will increment by 1
            ############################################################
            set incrementIP(DestinationMAC.5)  1
            set incrementIP(SourceMAC.5)  1
            set incrementIP(DestinationIP.3)  1
            set incrementIP(SourceIP.3)  1
            LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM $SOURCE_STREAM $SEQUENCE 0 incrementIP 0 $H $S $P

            puts "Created [expr $SEQUENCE +1] IP streams on card in slot [expr $S +1]"
       }

   }

}
#####################################################################

#####################################################################
##			IPX STREAM				   ##
#####################################################################

proc set_streamipx { {txgroup} {rxgroup} {NUM_STREAMS 10} } {

   global STREAM_PROTOCOL_IPX L3_DEFINE_IPX_STREAM L3_DEFINE_MULTI_IPX_STREAM L3_MOD_IPX_STREAM

  # Check for link with chassis
   check_link

   # set constants
   set DATA_LENGTH 100
   set SOURCE_STREAM 1
   set SEQUENCE [expr $NUM_STREAMS - 1]

  # Setup structures
  struct_new streamIPX StreamIPX
  struct_new incrementIPX StreamIPX

  # Set default streams Any field set to X will be replaced
  # with the card number of the source card for ipxsource_net or ipxsource_host
  # or of the destination card for the ipxdest_source and ipxdest_host
  set ipxdest_net {00 00 00 X}
  set ipxdest_host {00 00 00 X 00 01}
  set ipxdest_socket 00
  set ipxsource_net {00 00 00 X}
  set ipxsource_host  {00 00 00 X 00 01}
  set ipxsource_socket 00

  ###################################################
  ############### GROUP SETUP #######################
  ###################################################
  # Loop count is set to the larger number of cards
  if {[llength $txgroup] >= [llength $rxgroup]} {
     set maxcards [llength $txgroup]
  } else {
     set maxcards [llength $rxgroup]
  }
  set txcount 0
  set rxcount 0
  # Split group and assign elements to Hub Slot Port variables for the Tx and Rx cards
  for {set i 0} {$i < $maxcards} {incr i} {    
       set source_card [split [lindex $txgroup $txcount]]
           set source_card [string trim $source_card { \ { } }]
	   set H [lindex $source_card 0]
	   set S [lindex $source_card 1]
	   set P [lindex $source_card 2]
       set dest_card [split [lindex $rxgroup $rxcount]]
           set dest_card [string trim $dest_card { \ { } }]
	   set H2 [lindex $dest_card 0]
	   set S2 [lindex $dest_card 1]
	   set P2 [lindex $dest_card 2]
       # If the count is beyond the number of cards in the group, reset to zero
       # This enables many to one or one to many by varying the number of cards
       # in each group      
       incr txcount
       if {$txcount > [expr [llength $txgroup] - 1]} {
	  set txcount 0
       }
       incr rxcount
       if {$rxcount > [expr [llength $rxgroup] - 1]} {
    	  set rxcount 0
       }
       #######################################################################
       ###################### STREAM SETUP ###################################
       #######################################################################
        set streamIPX(ucActive)  1
        set streamIPX(ucProtocolType)  $STREAM_PROTOCOL_IPX
	set streamIPX(ucRandomLength)  0
	set streamIPX(ucRandomData)  0
        set streamIPX(uiFrameLength) $DATA_LENGTH
        set streamIPX(ucTagField)  1

        set streamIPX(DestinationMAC.0)  0
        set streamIPX(DestinationMAC.1)  0
        set streamIPX(DestinationMAC.2)  0
        set streamIPX(DestinationMAC.3)  [expr $S2 + 1]
        set streamIPX(DestinationMAC.4)  0
        set streamIPX(DestinationMAC.5)  1
        set streamIPX(SourceMAC.0)  0
        set streamIPX(SourceMAC.1)  0
        set streamIPX(SourceMAC.2)  0
        set streamIPX(SourceMAC.3)  [expr $S + 1]
        set streamIPX(SourceMAC.4)  0
        set streamIPX(SourceMAC.5)  1
        set streamIPX(IPXlen) 10
	set streamIPX(IPXhop)  10
	set streamIPX(IPXtype)  0
	# DESTINATION NET
	for {set j 0} {$j < 4} {incr j} {
           set octet [lindex [split $ipxdest_net] $j]
           if {$octet == "X" } {
              set streamIPX(IPXdst.$j)  [expr $S2 +1]
           } else {
	      set streamIPX(IPXdst.$j)  $octet
           }
	}
	# DESTINATION HOST
	for {set k 0} {$k < 6} {incr k} {
           set octet [lindex [split $ipxdest_host] $k]
           if {$octet == "X" } {
              set streamIPX(IPXdstHost.$k)  [expr $S2 +1]
           } else {
	      set streamIPX(IPXdstHost.$k)  $octet
           }
	}
        # DESTNATION SOCKET
	set streamIPX(IPXdstSocket) $ipxdest_socket

	# SOURCE NET
	for {set l 0} {$l < 4} {incr l} {
           set octet [lindex [split $ipxsource_net] $l]
           if {$octet == "X" } {
              set streamIPX(IPXsrc.$l)  [expr $S +1]
           } else {
	      set streamIPX(IPXsrc.$l)  $octet
           }
	}
	# SOURCE HOST
	for {set m 0} {$m < 6} {incr m} {
           set octet [lindex [split $ipxsource_host] $m]
           if {$octet == "X" } {
              set streamIPX(IPXsrcHost.$m)  [expr $S +1]
           } else {
	      set streamIPX(IPXsrcHost.$m)  $octet
           }
	}
        # SOURCE SOCKET
	set streamIPX(IPXdstSocket) $ipxsource_socket

        #####################################
        # Stream Creation
        # 1) if NUM_STREAMS was passed in by caller as zero
        #    or less SEQUENCE will be negative.  We check
        #    for this condititon and erase all streams on the card
        #    if this condition is true
        # 2) if SEQUENCE is zero or more, we get the number of streams
        #    currently on the card by calling check_stream procedure.
        #    If the number is one there are no streams on the card, and
        #    we use the L3_DEFINE stream creation procedure.  If the number
        #    of streams is 2 or more we use L3_MOD stream creation to append
        #    the new streams to the card.  We then set the source_stream variable
        #    to point to the newly created appended base stream, for the following
        #    L3_DEFINE_MULTI command
        # 3) The L3_DEFINE_MULTI command creates the number of additional streams
        #    specified by the value of SEQUENCE.  If SEQUENCE is zero, there will
        #    be zero additional streams created, if it is 1, one additional stream
        #    will be created and so on.
        #####################################

        if {$SEQUENCE < 0} {
            # ERASE ANY STREAMS ON CARD
            # "" in place of a stream structure erases all streams on card
            LIBCMD HTSetStructure $L3_DEFINE_IPX_STREAM 0 0 0 "" 0 $H $S $P
        } else {
            set streams_on_card [l3x::check_stream $H $S $P]
            if { $streams_on_card < 2 } {
               # Create a single stream with L3_DEFINE
               LIBCMD HTSetStructure $L3_DEFINE_IPX_STREAM 0 0 0 streamIPX 0 $H $S $P
            } else {
               # Append a new stream at the end of the stream list
               LIBCMD HTSetStructure $L3_MOD_IPX_STREAM $streams_on_card 0 0 streamIPX 0 $H $S $P
               # set SOURCE_STREAM to point to the new stream
               set SOURCE_STREAM $streams_on_card
	    }
            ############################################################
            # Add additional streams with L3_DEFINE_MULTI_IPX_STREAM
            #    Last byte of Destination MAC will increment by 1
            #    Last byte of Source MAC will increment by 1
            #    Last byte of Destination and Source IPs will increment by 1
            ############################################################
            set incrementIPX(DestinationMAC.5)  1
            set incrementIPX(SourceMAC.5)  1
	    set incrementIPX(IPXdstHost.5)  1
	    set incrementIPX(IPXsrcHost.5)  1

            LIBCMD HTSetStructure $L3_DEFINE_MULTI_IPX_STREAM $SOURCE_STREAM $SEQUENCE 0 incrementIPX 0 $H $S $P

            puts "Created [expr $SEQUENCE +1] IPX streams on card in slot [expr $S +1]"
       }

  }
}
#####################################################################


#####################################################################
##			UDP STREAM				   ##
#####################################################################
proc set_streamudp { {txgroup} {rxgroup} {NUM_STREAMS 10} \
	{source_ip 10.X.1.10} {destination_ip 10.X.1.10} {TOS 0x00} } {

    global STREAM_PROTOCOL_UDP L3_DEFINE_UDP_STREAM L3_DEFINE_MULTI_UDP_STREAM L3_MOD_UDP_STREAM

  # Check for link with chassis
    check_link

    # set constants
    set DATA_LENGTH 100
    set SOURCE_STREAM 1
    set SEQUENCE [expr $NUM_STREAMS - 1]

    # Setup structures
    struct_new streamUDP StreamUDP
    struct_new incrementUDP StreamUDP

  # set default gateway
  set gateway_ip 10.X.1.1

  ###################################################
  ############### GROUP SETUP #######################
  ###################################################
  # Loop count is set to the larger number of cards
  if {[llength $txgroup] >= [llength $rxgroup]} {
     set maxcards [llength $txgroup]
  } else {
     set maxcards [llength $rxgroup]
  }
  set txcount 0
  set rxcount 0
  # Split group and assign elements to Hub Slot Port variables for the Tx and Rx cards
  for {set i 0} {$i < $maxcards} {incr i} {    
       set source_card [split [lindex $txgroup $txcount]]
           set source_card [string trim $source_card { \ { } }]
	   set H [lindex $source_card 0]
	   set S [lindex $source_card 1]
	   set P [lindex $source_card 2]
       set dest_card [split [lindex $rxgroup $rxcount]]
           set dest_card [string trim $dest_card { \ { } }]
	   set H2 [lindex $dest_card 0]
	   set S2 [lindex $dest_card 1]
	   set P2 [lindex $dest_card 2]
       # If the count is beyond the number of cards in the group, reset to zero
       # This enables many to one or one to many by varying the number of cards
       # in each group      
       incr txcount
       if {$txcount > [expr [llength $txgroup] - 1]} {
	  set txcount 0
       }
       incr rxcount
       if {$rxcount > [expr [llength $rxgroup] - 1]} {
    	  set rxcount 0
       }
       #######################################################################
       ###################### STREAM SETUP ###################################
       #######################################################################

        set streamUDP(ucActive)  1
        set streamUDP(ucProtocolType)  $STREAM_PROTOCOL_UDP
        set streamUDP(uiFrameLength) $DATA_LENGTH
        set streamUDP(ucTagField)  1
        set streamUDP(DestinationMAC.0)  0
        set streamUDP(DestinationMAC.1)  0
        set streamUDP(DestinationMAC.2)  0
        set streamUDP(DestinationMAC.3)  [expr $S2 + 1]
        set streamUDP(DestinationMAC.4)  0
        set streamUDP(DestinationMAC.5)  1
        set streamUDP(SourceMAC.0)  0
        set streamUDP(SourceMAC.1)  0
        set streamUDP(SourceMAC.2)  0
        set streamUDP(SourceMAC.3)  [expr $S + 1]
        set streamUDP(SourceMAC.4)  0
        set streamUDP(SourceMAC.5)  1
        set streamUDP(TimeToLive)  10
	# DESTINATION IP
	for {set j 0} {$j < 4} {incr j} {
           set octet [lindex [split $destination_ip .] $j]
           if {$octet == "X" } {
              set streamUDP(DestinationIP.$j)  [expr $S2 +1]
           } else {
	      set streamUDP(DestinationIP.$j)  $octet
           }
	}
	# SOURCE IP
 	for {set k 0} {$k < 4} {incr k} {
           set octet [lindex [split $source_ip .] $k]
           if { $octet == "X" } {
              set streamUDP(SourceIP.$k)  [expr $S +1]
	   } else {
	      set streamUDP(SourceIP.$k)  $octet
           }
	}
	# GATEWAY IP (ROUTER PORT)
	for {set l 0} {$l < 4} {incr l} {
           set octet [lindex [split $gateway_ip .] $l]
           if { $octet == "X" } {
              set streamUDP(Gateway.$l)  [expr $S + 1]
           } else {
	   set streamUDP(Gateway.$l)  $octet
           }           
        }
        set streamUDP(Netmask.0)  255
        set streamUDP(Netmask.1)  255
        set streamUDP(Netmask.2)  255
        set streamUDP(Netmask.3)  0
	set streamUDP(TypeOfService)  $TOS
	set streamUDP(UDPSrc) 	4369
 	set streamUDP(UDPDest)	3100
 	set streamUDP(UDPLen) 100

        #####################################
        # Stream Creation
        # 1) if NUM_STREAMS was passed in by caller as zero
        #    or less SEQUENCE will be negative.  We check
        #    for this condititon and erase all streams on the card
        #    if this condition is true
        # 2) if SEQUENCE is zero or more, we get the number of streams
        #    currently on the card by calling check_stream procedure.
        #    If the number is one there are no streams on the card, and
        #    we use the L3_DEFINE stream creation procedure.  If the number
        #    of streams is 2 or more we use L3_MOD stream creation to append
        #    the new streams to the card.  We then set the source_stream variable
        #    to point to the newly created appended base stream, for the following
        #    L3_DEFINE_MULTI command
        # 3) The L3_DEFINE_MULTI command creates the number of additional streams
        #    specified by the value of SEQUENCE.  If SEQUENCE is zero, there will
        #    be zero additional streams created, if it is 1, one additional stream
        #    will be created and so on.
        #####################################

        if {$SEQUENCE < 0} {
            # ERASE ANY STREAMS ON CARD
            # "" in place of a stream structure erases all streams on card
            LIBCMD HTSetStructure $L3_DEFINE_UDP_STREAM 0 0 0 "" 0 $H $S $P
        } else {
            set streams_on_card [l3x::check_stream $H $S $P]
            if { $streams_on_card < 2 } {
               # Create a single stream with L3_DEFINE
               LIBCMD HTSetStructure $L3_DEFINE_UDP_STREAM 0 0 0 streamUDP 0 $H $S $P
            } else {
               # Append a new stream at the end of the stream list
               LIBCMD HTSetStructure $L3_MOD_UDP_STREAM $streams_on_card 0 0 streamUDP 0 $H $S $P
               # set SOURCE_STREAM to point to the new stream
               set SOURCE_STREAM $streams_on_card
	    }
            ############################################################
            # Add additional streams with L3_DEFINE_MULTI_UDP_STREAM
            #    Last byte of Destination MAC will increment by 1
            #    Last byte of Source MAC will increment by 1
            #    Last byte of Destination and Source IPs will increment by 1
            ############################################################
            set incrementUDP(DestinationMAC.5)  1
            set incrementUDP(SourceMAC.5)  1
            set incrementUDP(DestinationIP.3)  1
            set incrementUDP(SourceIP.3)  1
            LIBCMD HTSetStructure $L3_DEFINE_MULTI_UDP_STREAM $SOURCE_STREAM $SEQUENCE 0 incrementUDP 0 $H $S $P

            puts "Created [expr $SEQUENCE +1] UDP streams on card in slot [expr $S +1]"
       }


  }
}

#########################################################################

#########################################################################
# show_stream
#
# Pulls stream data from a L3 SmartBits card
# Stream type SmartBits is used as the target structure
# other types can not be used currently.
#
# USAGE:
# show_stream <Hub> <Slot> <Port> <number of streams to show>
# Hub Slot Port are defaulted to 0 0 0.  Running without arguments will 
# attempt to display the first five streams from the first card in the
# first chassis.
# To show 5 streams from the third card in the first chassis:
# show_stream 0 2
#
# Uses L3_DEFINED_STREAM_COUNT_INFO to check for streams
# on the target, will display count and not continue if the count is less 
# than 2.
# If the requested number of streams is larger than the number on the card,
# the program will modify the request to match the number of streams on
# the card.
#
# ASSUMES:
# Target card is an L3 card that supports these commands.  Will terminate with
# an error for non-L3 cards.
# The NetcomSystems misc.tcl script has been sourced and the LIBCMD error
# handling function is available.
# ET1000.tcl has been sourced and a link has been established between the
# SmartBits chassis and the controlling PC.
##########################################################################
proc show_stream { {group} {streams 5} {output stdout} } {

  global L3_DEFINED_STREAM_COUNT_INFO L3_STREAM_INFO

   check_link
   struct_new DefStreams  ULong*3
   struct_new SB StreamSmartBits

foreach card $group {
   set card [split $card]
   set card [string trim $card { \ { } }]
   set H [lindex $card 0]
   set S [lindex $card 1]
   set P [lindex $card 2]

    #####################################
    # Check for number of streams       #
    # using L3_DEFINED_STREAM_COUNT_INFO#
    # This program only sets up only one#
    # stream.                           #
    # There is one non-transmitting     #
    # stream always on the card         #
    # used to hold card data so the     #
    # count of transmitting streams will#
    # always be one less than the total #
    # reported.                         #
    #####################################

    LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 DefStreams 0 $H $S $P
    if { $DefStreams(0.ul)  < 2 } {
       puts $output "No transmitting streams on card [expr $S +1]"
    } else {
       # if there are fewer streams on card than requested change
       # the streams variable to match what's actually there
       if { $DefStreams(0.ul)  < $streams } {
          set streams $DefStreams(0.ul)
       }
   
       ############################################
       # set up a SmartBits type structure to hold#
       # card configuration data.                 #
       ############################################

       for {set j 1} {$j < $streams} {incr j} {
          ############################################
          # Get stream data for stream count $j      #
          # Do not pull Stream 0 ("hidden" stream)   #
          ############################################
          LIBCMD HTGetStructure $L3_STREAM_INFO $j 0 0 SB 0 $H $S $P

          puts -nonewline $output "\n Card [expr $S +1] - Stream $j of [expr $DefStreams(0.ul) - 1] - STATUS => "
          if { $SB(ucActive) == 1} {
             puts $output "Active"
          } else {
             puts $output "Inactive"
          }
          puts $output "-----------------------------------------------------------"
          puts $output "Layer 2 Data:"
          puts -nonewline $output "    Destination MAC ==> "
          for {set i 0} {$i < 6} {incr i} {
             puts  -nonewline $output " [format %02X $SB(ProtocolHeader.$i)]"
          }
          puts $output ""
          puts -nonewline $output "    Source MAC      ==> "
          for {set i 6} {$i < 12} {incr i} {
             puts  -nonewline $output " [format %02X $SB(ProtocolHeader.$i)]"
          }
          puts $output "\n-----------------------------------------------------------"
          puts $output "Layer 3 Data:"
          puts -nonewline $output "   Stream type is "

          switch $SB(ucProtocolType) {
	  0 { puts $output "SmartBits"}
          2 { puts $output "IP"
              puts -nonewline $output "    Destination IP       ==> "
              for {set i 16} {$i < 19} {incr i} {
                 puts  -nonewline $output "[format %d  $SB(ProtocolHeader.$i)]."
              }
              puts $output "[format %d $SB(ProtocolHeader.19)]"   

              puts -nonewline $output "    Source IP            ==> "
              for {set i 20} {$i < 23} {incr i} {
                 puts  -nonewline $output "[format %d $SB(ProtocolHeader.$i)]."
              }
              puts $output "[format %d  $SB(ProtocolHeader.23)]"   
              puts $output "\n   Frame length is $SB(uiFrameLength) bytes"
	      }
	   3 { puts $output "IPX"
              puts -nonewline $output "    Dest Net ==> "
              for {set i 16} {$i < 20} {incr i} {
                 puts  -nonewline $output "[format %02d $SB(ProtocolHeader.$i)] "
              }
              puts -nonewline $output " Dest Host ==> "
              for {set i 20} {$i < 26} {incr i} {
                 puts  -nonewline $output "[format %02d $SB(ProtocolHeader.$i)] "
              }
	      puts -nonewline $output " Sckt => [format %02d $SB(ProtocolHeader.26)]"
              puts ""

              puts -nonewline $output "    Srce Net ==> "
              for {set i 28} {$i < 32} {incr i} {
                 puts  -nonewline $output "[format %02d $SB(ProtocolHeader.$i)] "
              }
              puts -nonewline $output " Srce Host ==> "
              for {set i 32} {$i < 38} {incr i} {
                 puts  -nonewline $output "[format %02d $SB(ProtocolHeader.$i)] "
              }
	      puts -nonewline $output " Sckt => [format %02d $SB(ProtocolHeader.38)]"
              puts $output ""
	     }
	  4 { puts $output "UDP"
             puts -nonewline $output "    Destination IP  ==> "
             for {set i 16} {$i < 19} {incr i} {
                puts  -nonewline $output "[format %d $SB(ProtocolHeader.$i)]."
             }
             puts "[format %d  $SB(ProtocolHeader.19)]"   

             puts -nonewline $output "    Source IP       ==> "
             for {set i 20} {$i < 23} {incr i} {
                puts  -nonewline $output "[format %d $SB(ProtocolHeader.$i)]."
             }
             puts $output "[format %d  $SB(ProtocolHeader.23)]"   
             puts $output "\n   Frame length is $SB(uiFrameLength) bytes"
            }
	 5 { puts $output "ARP"}
	 8 { puts $output "TCP"
             puts -nonewline $output "    Destination IP  ==> "
             for {set i 16} {$i < 19} {incr i} {
                puts  -nonewline $output "[format %d $SB(ProtocolHeader.$i)]."
             }
             puts $output "[format %d  $SB(ProtocolHeader.19)]"   

             puts -nonewline $output "    Source IP       ==> "
             for {set i 20} {$i < 23} {incr i} {
                puts  -nonewline $output "[format %d $SB(ProtocolHeader.$i)]."
             }
             puts $output "[format %d $SB(ProtocolHeader.23)]"   
             puts $output "\n   Frame length is $SB(uiFrameLength) bytes"
            }
	 default {puts $output "unknown"}
 	
         }
	# Check ARP state - when ARP is sent time is recorded in 52 53 53 and 55
        # when reply is received the time is recorded in 56 57 58 and 59
        # all zero fields indicate an event has not happened, ie ARPStart = 0 
        # indicates ARP request was not sent, ARPEnd = 0 indicates reply was never
        # received.  Byte order on time may be system dependent
        set ARPStart 0
        set ARPStart [expr $ARPStart + $SB(ProtocolHeader.54) * 0x10000]
        set ARPStart [expr $ARPStart + $SB(ProtocolHeader.53) * 0x100]
        set ARPStart [expr $ARPStart + $SB(ProtocolHeader.52) * 1]

        set ARPEnd 0
        set ARPEnd [expr $ARPEnd + $SB(ProtocolHeader.58) * 0x10000]
        set ARPEnd [expr $ARPEnd + $SB(ProtocolHeader.57) * 0x100]
        set ARPEnd [expr $ARPEnd + $SB(ProtocolHeader.56) * 1]

	if { $ARPStart == 0 } {
             puts "   ARP requests have not been sent"
        } else {
		if { $ARPEnd == 0 } {
                     puts "   ARP requests have been sent but replies have not been received"
		} else {
		     puts "   ARP exchange complete"
                }
        }
             
         ################################################
         # ProtocolHeader area will contain the raw data#
         ################################################

         puts $output "------------------------------------------------"
         puts $output "              Raw Protocol Data     "
         puts $output "------------------------------------------------"
         for {set i 0} {$i < 64} {incr i} {
            if { [expr $i % 16] == 0 } {
               puts $output ""
               puts -nonewline $output "[format "%02X" $i]:  "
            }
         puts  -nonewline $output " [format %02X  $SB(ProtocolHeader.$i)]"
         }

         puts $output ""
         if {$output == "stdout"} {
         puts "\nPress ENTER to continue"
         gets stdin response
         }
    }
  }
 }
}
  
######################## END show_stream ################################


#########################################################################
# check_stream
#
# returns number of streams on card
# Only works for a single card.
#
# Internal function not exported into global namespace.  
#########################################################################
proc check_stream { H S P } {

  global L3_DEFINED_STREAM_COUNT_INFO

  struct_new DefStreams  ULong*3

    #####################################
    # Check for number of streams       #
    # using L3_DEFINED_STREAM_COUNT_INFO#
    # return value to caller            #
    #####################################

    LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 DefStreams 0 $H $S $P
    return $DefStreams(0.ul)

}
#########################################################################

#########################################################################
# set_streamzero
#
# removes all streams
#
# Internal function not exported into global namespace.  
#########################################################################
proc set_streamzero { group } {

   global L3_DEFINE_SMARTBITS_STREAM

   foreach card $group {
      set card [split $card]
      set card [string trim $card { \ { } }]
      set H [lindex $card 0]
      set S [lindex $card 1]
      set P [lindex $card 2]

   LIBCMD HTSetStructure $L3_DEFINE_SMARTBITS_STREAM 0 0 0 "" 0 $H $S $P
   }
}
#########################################################################

########################## set_arp ######################################
proc set_arp { {group} } {

   global L3_START_ARPS

   check_link

   foreach card $group {
      set card [split $card]
      set card [string trim $card { \ { } }]
      set H [lindex $card 0]
      set S [lindex $card 1]
      set P [lindex $card 2]
   }

   LIBCMD HTSetCommand $L3_START_ARPS 0 0 0 "" $H $S $P

}
######################## END set_arp ####################################

########################## show_l3 ######################################
proc show_l3 { {group} {output stdout} } {

   global L3_TX_ADDRESS_INFO

   check_link
   struct_new L3Addr Layer3Address

   foreach card $group {
      set card [split $card]
      set card [string trim $card { \ { } }]
      set H [lindex $card 0]
      set S [lindex $card 1]
      set P [lindex $card 2]


   ####################################
   # Get and display the L3 data
   ####################################
   LIBCMD HTGetStructure $L3_TX_ADDRESS_INFO 0 0 0 L3Addr 0 $H $S $P
   puts $output "\n\n\n"
   puts $output "==================================================="
   puts $output "          Layer 3 Settings for Card [expr $S + 1]"
   puts $output "==================================================="
   puts -nonewline $output " Card MAC Address 	==> [format "%02X" $L3Addr(szMACAddress.0)] "
   puts -nonewline $output "[format "%02X" $L3Addr(szMACAddress.1)] "
   puts -nonewline $output "[format "%02X" $L3Addr(szMACAddress.2)] "
   puts -nonewline $output "[format "%02X" $L3Addr(szMACAddress.3)] "
   puts -nonewline $output "[format "%02X" $L3Addr(szMACAddress.4)] "
   puts $output "[format "%02X" $L3Addr(szMACAddress.5)]"

   puts -nonewline $output " Card stack IP Address 	==> $L3Addr(IP.0)."
   puts -nonewline $output "$L3Addr(IP.1)."
   puts -nonewline $output "$L3Addr(IP.2)."
   puts $output "$L3Addr(IP.3)"

   puts $output "---------------------------------------------------"

   puts -nonewline $output " Netmask 		==> $L3Addr(Netmask.0)."
   puts -nonewline $output "$L3Addr(Netmask.1)."
   puts -nonewline $output "$L3Addr(Netmask.2)."
   puts $output "$L3Addr(Netmask.3)"

   puts -nonewline $output " Gateway IP 		==> $L3Addr(Gateway.0)."
   puts -nonewline $output "$L3Addr(Gateway.1)."
   puts -nonewline $output "$L3Addr(Gateway.2)."
   puts $output "$L3Addr(Gateway.3)"

   puts $output "---------------------------------------------------"

   puts -nonewline $output " Ping Target IP 	==> $L3Addr(PingTargetAddress.0)."
   puts -nonewline $output "$L3Addr(PingTargetAddress.1)."
   puts -nonewline $output "$L3Addr(PingTargetAddress.2)."
   puts $output "$L3Addr(PingTargetAddress.3)"
   puts $output ""

   puts $output " Control Word	 	==> [format "%04X" $L3Addr(iControl)]\n"

      if {[expr $L3Addr(iControl) & 1] != 0} {
          puts $output "	General ARP response enabled"
      } else {
          puts $output "	Specific ARP response enabled"
      }

      if {[expr $L3Addr(iControl) & 2] != 0} {
          puts $output "	Transmitting $L3Addr(iPingTime) Ping packets per second"
      } else {
          puts $output "	Ping packet generation disabled"
      }
     
      if {[expr $L3Addr(iControl) & 4] != 0} {
          puts $output "	Transmitting $L3Addr(iSNMPTime) SNMP packets per second"
	  puts $output "	Transmitting $L3Addr(iRIPTime) RIP packets per second"
      } else {
          puts $output "	SNMP and RIP packet generation disabled"
      }

   puts $output "---------------------------------------------------"
   puts $output "\n\n\n"
   if {$output == "stdout"} {
   puts "\nPress ENTER to continue"
   gets stdin response
   }
   }
   unset L3Addr
}
######################## END show_l3 #####################################

########################################################################
# setl3.tcl
#
########################################################################

proc set_l3 { {group} } {

check_link

struct_new addr Layer3Address
   foreach card $group {
      set card [split $card]
      set card [string trim $card { \ { } }]
      set H [lindex $card 0]
      set S [lindex $card 1]
      set P [lindex $card 2]
puts "Configuration for card [expr $S +1]"
puts "Please enter IP addresses in XXX.XXX.XXX.XXX format"
puts "What is the card [expr $S +1] Gateway (Router Port) IP Address? "
gets stdin gateway_ip
puts "What is the card [expr $S +1] SmartCard stack IP (MUST be different from any stream)?"
gets stdin smartcard_ip
puts "What is the IP address of the ping target for card [expr $S +1]?"
gets stdin ping_target
puts "What is the Control Word for card [expr $S +1]?"
puts "		4 = SNMP and RIP"
puts "		2 = Ping"
puts "		1 = General ARP Response"
puts "		7 = Enable all; 0 = Disable all"
gets stdin control

#  Layer 3 Card IP Address
##########################################
for {set i 0} {$i < 4} {incr i} {
  set addr(IP.$i)  [lindex [split $smartcard_ip . ] $i ] 
}

##########################################
#  Layer 3 Card Gateway Address
##########################################
for {set i 0} {$i < 4} {incr i} {
  set addr(Gateway.$i)  [lindex [split $gateway_ip . ] $i ] 
}
##########################################
#  Layer 3 Card Ping Target
###########################################
for {set i 0} {$i < 4} {incr i} {
  set addr(PingTargetAddress.$i)  [lindex [split $ping_target . ] $i ] 
}
###########################################
# Set Control values
###########################################
set addr(iControl) $control  
set addr(iPingTime) 10   
set addr(iSNMPTime) 10   
set addr(iRIPTime) 10   
# Obsolete function do not use!         
# set addr(iGeneralIPResponse)   

##########################################
# Layer 3 Card MAC Address
##########################################
set addr(szMACAddress.0)  0
set addr(szMACAddress.1)  0
set addr(szMACAddress.2)  0
set addr(szMACAddress.3)  0
set addr(szMACAddress.4)  0
set addr(szMACAddress.5)  [expr $S + 1]
##########################################

##########################################
#   Layer 3 Card Netmask
##########################################
set addr(Netmask.0)  255
set addr(Netmask.1)  255
set addr(Netmask.2)  255
set addr(Netmask.3)  0
##########################################

LIBCMD HTLayer3SetAddress addr $H $S $P

}
}

########################## END set_l3 ###############################


##########################################################################
# set_l2
#
# Displays current card state (L2 or L3) and stream count and gives
# user the option of removing the transmitting streams
##########################################################################
proc set_l2 { {group} } {

global L3_DEFINED_STREAM_COUNT_INFO L3_DEFINE_SMARTBITS_STREAM

check_link

struct_new DefStreams  ULong*3
   foreach card $group {
      set card [split $card]
      set card [string trim $card { \ { } }]
      set H [lindex $card 0]
      set S [lindex $card 1]
      set P [lindex $card 2]

LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 DefStreams 0 $H $S $P

  if {$DefStreams(0.ul) > 1} {
     puts ""
     puts " 	**************************************************"
     puts "	       - Card  [expr $S +1] is in Layer 3 Mode -\n"
     puts "	There are $DefStreams(0.ul) total streams currently on card [expr $S + 1]"
     puts "	[expr $DefStreams(0.ul) -1] transmitting streams plus the 1 hidden stream"
     puts " 	**************************************************"
     puts ""
     puts "Do you want to remove the transmitting streams (switch to Layer 2 mode)? (y/n)"
     gets stdin response
     if {$response == "y"} {
        puts "zeroing stream count"
        LIBCMD HTSetStructure $L3_DEFINE_SMARTBITS_STREAM 0 0 0 "" 0 $H $S $P
        LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 DefStreams 0 $H $S $P
        puts "Total stream count $DefStreams(0.ul) streams on card [expr $S + 1]"
        puts ""
     } else {
        puts "Keeping total stream count at $DefStreams(0.ul) streams on card [expr $S + 1]"
     }
  } else {
     puts ""
     puts " 	**************************************************"
     puts "	    - Card [expr $S +1] is already in Layer 2 mode -\n"
     puts " 	       (only hidden stream 0 is configured)"
     puts " 	**************************************************"
     puts ""
  }
  
  }
   puts ""
   puts "Press ENTER to continue"
   gets stdin response
 }

}
