#####################################################################
#MOD_STREAM_ARRAY.TCL                                               #
#                                                                   #
# Sets up IP streams on a L3 Card then mods the 3rd gateway octet   #
#                                                                   #
# NOTE: This script works on the following cards:                   #
#       - L3-67XX                                                   #
#       - ML-7710                                                   #
#       - ML-5710                                                   #
#       - LAN-6101A                                                 #
#       - LAN-6201A/B                                               #
#       - LAN-3300A/3301A                                           #
#                                                                   #
#####################################################################

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

set iHub        0
set iSlot       0
set iPort       0

set iHub2       0
set iSlot2      0
set iPort2      1 

set SOURCE_STREAM 1
set ADD_STREAMS 9

proc display_stream { H S P {streams 5} {output stdout} } {

  global L3_DEFINED_STREAM_COUNT_INFO L3_STREAM_INFO

   struct_new DefStreams  ULong
    #####################################
    # Check for number of streams       #
    # using L3_DEFINED_STREAM_COUNT_INFO#
    #####################################

    LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 DefStreams 0 $H $S $P
    if { $DefStreams(ul)  < 2 } {
         puts $output "No transmitting streams on card [expr $S +1]"
    } else {
             # if there are fewer streams on card than requested change
             # the streams variable to match what's actually there
             if { $DefStreams(ul)  < $streams } {
                  set streams $DefStreams(ul)
             }
   
       ############################################
       # set up a SmartBits type structure to hold#
       # card configuration data.                 #
       ############################################
       struct_new SB StreamSmartBits

       for {set j 1} {$j < [expr $streams + 1]} {incr j} {
             ############################################
             # Get stream data for stream count $j      #
             # Do not pull Stream 0 ("hidden" stream)   #
             ############################################

          LIBCMD HTGetStructure $L3_STREAM_INFO $j 0 0 SB 0 $H $S $P

          puts -nonewline $output "\n Card [expr $S +1] - Stream $j of [expr $DefStreams(ul) - 1] - STATUS => "
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
          puts $output "   Stream type is IP"

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
  
######################## END show_stream ################################


# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

###########################################################
# Set up base IP stream with L3_DEFINE_IP_STREAM          #
#                                                         #
# - Base Destination MAC is 00 00 00 00 01 00             #
# - Base Source MAC is 00 00 00 00 00 01                  #
# - Base Destination IP is 192.158.100.1                  #
# - Base Source IP is 192.148.100.1                       #
#                                                         #
# - Note the format %c used with uc data types            #
#                                                         #
###########################################################

struct_new streamIP StreamIP

        set streamIP(ucActive) 1
        set streamIP(ucProtocolType) $L3_STREAM_IP
        set streamIP(uiFrameLength) 60
        set streamIP(ucTagField) 1
        set streamIP(DestinationMAC.0) 0
        set streamIP(DestinationMAC.1) 0
        set streamIP(DestinationMAC.2) 0
        set streamIP(DestinationMAC.3) 2
        set streamIP(DestinationMAC.4) 0
        set streamIP(DestinationMAC.5) 1
        set streamIP(SourceMAC.0) 0
        set streamIP(SourceMAC.1) 0
        set streamIP(SourceMAC.2) 0
        set streamIP(SourceMAC.3) 1
        set streamIP(SourceMAC.4) 0
        set streamIP(SourceMAC.5) 1
        set streamIP(TimeToLive) 10
        set streamIP(TimeToLive) 10
        set streamIP(DestinationIP.0) 2
        set streamIP(DestinationIP.1) 2
        set streamIP(DestinationIP.2) 2
        set streamIP(DestinationIP.3) 10
        set streamIP(SourceIP.0) 1
        set streamIP(SourceIP.1) 1
        set streamIP(SourceIP.2) 1
        set streamIP(SourceIP.3) 10
        set streamIP(Netmask.0) 255
        set streamIP(Netmask.1) 255
        set streamIP(Netmask.2) 255
        set streamIP(Netmask.3) 0
        set streamIP(Gateway.0) 3
        set streamIP(Gateway.1) 3
        set streamIP(Gateway.2) 3
        set streamIP(Gateway.3) 3

#####################################
# set to card at $iHub $iSlot $iPort#
#####################################

LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

puts "Finished L3_DEFINE_IP_STREAM"
unset streamIP

####################################################################
# - Add additional streams with L3_DEFINE_MULTI_IP_STREAM          #
#                                                                  #
# - MULTI_IP only changes the bytes you specify and increments     #
#   by the amount you specify.                                     #
#   So....                                                         #
# - Last byte of Destination MAC will increment by                 #
# - Last byte of Source MAC will increment by 1                    #
# - This will allow us to track the stream sequence                #
#                                                                  #
####################################################################

struct_new incrementIP StreamIP

set incrementIP(DestinationMAC.5) 1
set incrementIP(SourceMAC.5) 1

LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM $SOURCE_STREAM $ADD_STREAMS 0 incrementIP 0 $iHub $iSlot $iPort

unset incrementIP

puts "Finished L3_DEFINE_MULTI_IP_STREAM"

#######################################################################
# - Modify the Gateway address                                        #
#   - ulIndex starts modifications with stream 2                      #
#   - ulCount will interate 4 times                                   #
#   - ulField specifies the Frame Length field                        #
#   - ulField Count indicates we will use the first four elements     #
#     of ulData; 10 2 30 and 40                                       #
#   - ulFieldRepeat means will will only repeat the value at each     #
#     iteration once                                                  #
#                                                                     #
# - These settings will cause the four                                #
#   packets 2, 3, 4 and 5 to have the 3rd octet of the gateway        #
#   address overwritten with 10 20 30 and 40                          #
#######################################################################

struct_new MyL3Array Layer3ModifyStreamArray

   set MyL3Array(ulIndex) 2
   set MyL3Array(ulCount) 4
   set MyL3Array(ulField) $L3MS_FIELD_GATEWAYC
   set MyL3Array(ulFieldCount) 4
   set MyL3Array(ulFieldRepeat) 1

# set up data array with 15 values from 10 to 150
# for modifying length field of packets
# expr 1 + $1 prevents first modified packet getting
# an octet of zero.

for {set i 0} {$i < 15} {incr i} {
      set MyL3Array(ulData.$i.ul) [expr (1 + $i) * 10]
}

LIBCMD HTSetStructure $L3_MOD_STREAMS_ARRAY 0 0 0 MyL3Array 0 $iHub $iSlot $iPort

display_stream $iHub $iSlot $iPort [expr $ADD_STREAMS + 1]

unset MyL3Array

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"


