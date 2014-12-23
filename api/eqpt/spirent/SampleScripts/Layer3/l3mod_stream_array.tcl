#######################################################################
#MOD_STREAM_ARRAY.TCL                                                 #
#                                                                     #
# - Sets up IP streams on a L3 Card then mods the length field        #
# - Demonstrates the effect of the various options on the             #
#   output.                                                           #
#                                                                     #
# NOTE: This script works on the following cards:                     #
#       - L3-67XX                                                     #
#       - ML-7710                                                     #
#       - ML-5710                                                     #
#       - LAN-6101A                                                   #
#       - LAN-6201A/B                                                 #
#       - LAN-3300A/3301A                                             #
#       - LAN-3310A/3311A                                             #
#       - POS-6500/6502                                               #
#       - POS-3505A/3504As                                            #
#                                                                     #
#######################################################################


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


set DATA_LENGTH 60
set SOURCE_STREAM 1
set ADD_STREAMS 9

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot
LIBCMD HTSlotReserve $iHub2 $iSlot2

###########################################################
# Set up base IP stream with L3_DEFINE_IP_STREAM          #
#                                                         #
# - Base Destination MAC is 00 00 00 00 00 01             #
# - Base Source MAC is 00 00 00 00 00 01                  #
#                                                         #
###########################################################

puts "start"

#####################################
# set to card at $iHub $iSlot $iPort#
#####################################

LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 - 0 $iHub $iSlot $iPort \
-ucActive       1 \
-ucProtocolType $L3_STREAM_IP \
-uiFrameLength  $DATA_LENGTH \
-ucTagField     1 \
-DestinationMAC {0 0 0 0 0 1} \
-SourceMAC      {0 0 0 0 0 1} \
-TimeToLive     10
puts "Finished L3_DEFINE_IP_STREAM"


##################################################################
# - Add additional streams with L3_DEFINE_MULTI_IP_STREAM        #
#                                                                #
# - MULTI_IP only changes the bytes you specify and increments   #
#   by the amount you specify.                                   #
#   So....                                                       #
# - Last byte of Destination MAC will increment by 1             #
# - Last byte of Source MAC will also increment by 1             #
# - This will allow us to number the stream sequence clearly     #
#                                                                #
##################################################################

struct_new ip StreamIP
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM $SOURCE_STREAM $ADD_STREAMS 0 ip 0 $iHub $iSlot $iPort\
-DestinationMAC  {0 0 0 0 0 1} \
-SourceMAC       {0 0 0 0 0 1}
puts "Finished L3_DEFINE_MULTI_IP_STREAM"
unset ip

################################################################################
# - Modify the data length of the streams                                      #
#   - ulIndex starts modifications with stream # 2                             #
#   - ulCount will interate 4 times                                            #
#   - ulField specifies the Frame Length field of the streams                  #
#   - ulField Count indicates we will use the first four elements              #
#              of ulData; 100 200 300 and 400                                  #
#   - ulFieldRepeat 2 means will will repeat each value at each                #
#     iteration twice.  This results in the number                             #
#     of modified streams being ulCount * ulFieldRepeat                        #
#                                                                              #
# - These settings will cause the field length of eight                        #
#   packets 2 through 9 to have their data lengths overwritten                 #
#   with 100 100 200 200 300 300 and 400 400                                   #
#                                                                              #
# - The total lengths produced by the ten stream group will be:                #
#   64 104 104 204 204 304 304 404 404 64                                      #
#   since the first and last streams of the ten defined streams                #
#   will be left at the original 60 byte data length plus 4 byte CRC           #
################################################################################

struct_new MyL3Array Layer3ModifyStreamArray
   set MyL3Array(ulIndex) 2
   set MyL3Array(ulCount) 4
   set MyL3Array(ulField) $L3MS_FIELD_FRAMELEN
   set MyL3Array(ulFieldCount) 4
   set MyL3Array(ulFieldRepeat) 2

# set up data array with 15 values from 100 to 1500
# for modifying length field of packets
# expr 1 + $1 prevents first modified packet getting
# a length of zero.

for {set i 0} {$i < 15} {incr i} {
      set MyL3Array(ulData.$i) [expr (1 + $i) * 100]
}

LIBCMD HTSetStructure $L3_MOD_STREAMS_ARRAY 0 0 0 MyL3Array 0 $iHub $iSlot $iPort

unset MyL3Array

puts "Finished MOD_STREAMS_ARRAY"

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
