########################################################################################
#L3_MOD_STREAM_ARRAY.TCL                                                               #
#                                                                                      #
# - Sets up IP streams on a L3 Card and then mods the length field                     #
# - Demonstrates the effect of the various options on the output.                      #
# - Adds additional streams with L3_DEFINE_MULTI_IP_STREAM                             #
# - MULTI_IP only changes the bytes specified and increments                           #
#   by the amount specified.                                                           #
# - Modifies the data and sets the stream array on the card                            #
#                                                                                      #
# NOTE: This script runs on the following cards:                                       #
#       - L3-67XX                                                                      #
#       - ML-7710                                                                      #
#       - ML-5710                                                                      #
#       - LAN-6101A                                                                    #
#       - LAN-6201A/B                                                                  #
#       - LAN-3300A/3301A                                                              #
#       - LAN-3310A/3311A                                                              #
#       - POS-6500/6502                                                                #
#       - POS-3505A/3504A                                                              #
#                                                                                      #
########################################################################################


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
	  puts "Unable to connect to $ipaddr. Please try again.$retval"
	  exit
     }
}

#Set the default variables
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
# - Set up base IP stream with L3_DEFINE_IP_STREAM        #
# - Base Destination MAC is 00 00 00 00 00 01             #
# - Base Source MAC is 00 00 00 00 00 01                  #
###########################################################

puts "Setting up IP streams on the card"

#Set up the IP Stream 
struct_new streamIP StreamIP

        set streamIP(ucActive) [format %c 1]
        set streamIP(ucProtocolType) [format %c $L3_STREAM_IP]
        set streamIP(uiFrameLength) $DATA_LENGTH
        set streamIP(ucTagField) [format %c 1]
        set streamIP(DestinationMAC.0.uc) [format %c 0]
        set streamIP(DestinationMAC.1.uc) [format %c 0]
        set streamIP(DestinationMAC.2.uc) [format %c 0]
        set streamIP(DestinationMAC.3.uc) [format %c 0]
        set streamIP(DestinationMAC.4.uc) [format %c 0]
        set streamIP(DestinationMAC.5.uc) [format %c 1]
        set streamIP(SourceMAC.0.uc) [format %c 0]
        set streamIP(SourceMAC.1.uc) [format %c 0]
        set streamIP(SourceMAC.2.uc) [format %c 0]
        set streamIP(SourceMAC.3.uc) [format %c 0]
        set streamIP(SourceMAC.4.uc) [format %c 0]
        set streamIP(SourceMAC.5.uc) [format %c 1]
        set streamIP(TimeToLive) [format %c 10]

# set to card at $iHub $iSlot $iPort#

#Set up the IP Stream on the card
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#Pause for 1 sec
after 1000

#Unset the structure
unset streamIP

################################################################
# - Add additional streams with L3_DEFINE_MULTI_IP_STREAM      #
# - MULTI_IP only changes the bytes you specify and increments #
#   by the amount you specify.                                 #
#   So....                                                     #
# - Last byte of Destination MAC will increment by 1           #
# - Last byte of Source MAC will also increment by 1           #
# - This will allow us to number the stream sequence clearly   #
################################################################

after 1000
puts "Setting up multiple streams with L3_DEFINE_MULTI_IP_STREAM "
puts "by incrementing the DestinationMAC and SourceMac"
after 1000

#Increment the DestinationMac and the SourceMAc
struct_new incrementIP StreamIP

set incrementIP(DestinationMAC.5.uc) [format %c 1]
set incrementIP(SourceMAC.5.uc) [format %c 1]

#Set the multiple streams on the card
LIBCMD HTSetStructure $L3_DEFINE_MULTI_IP_STREAM $SOURCE_STREAM $ADD_STREAMS 0 incrementIP 0 $iHub $iSlot $iPort

#Unset the structure
unset incrementIP


############################################################################
# - Modify the data length of the streams                                  #
# - ulIndex starts modifications with stream # 2                           #
# - ulCount will interate 4 times                                          #
# - ulField specifies the Frame Length field of the streams                #
# - ulField Count indicates we will use the first four elements            #
#              of ulData; 100 200 300 and 400                              #
# - ulFieldRepeat 2 means will will repeat each value at each              #
#               iteration twice.  This results in the number               #
#  		of modified streams being ulCount * ulFieldRepeat          #
#                                                                          #
# - These settings will cause the field length of eight packets,           #
#   2 through 9 to have their data lengths overwritten                     #
#   with 100 100 200 200 300 300 and 400 400                               #
#                                                                          #
# - The total lengths produced by the ten stream group will be:            #
#   64 104 104 204 204 304 304 404 404 64                                  #
#   since the first and last streams of the ten defined streams            #
#   will be left at the original 60 byte data length plus 4 byte CRC       #
############################################################################

puts "Modifying the stream array now.."
after 1000

#Create a new structure
struct_new MyL3Array Layer3ModifyStreamArray

   set MyL3Array(ulIndex) 2
   set MyL3Array(ulCount) 4
   set MyL3Array(ulField) $L3MS_FIELD_FRAMELEN
   set MyL3Array(ulFieldCount) 4
   set MyL3Array(ulFieldRepeat) 2

# set up data array with 15 values from 100 to 1500 for modifying length field of packets
# expr 1 + $1 prevents first modified packet getting a length of zero.

for {set i 0} {$i < 15} {incr i} {
      set MyL3Array(ulData.$i.ul) [expr (1 + $i) * 100]
}

puts "Setting up the stream array on the card"
after 1000
#Set the streams array on the card
LIBCMD HTSetStructure $L3_MOD_STREAMS_ARRAY 0 0 0 MyL3Array 0 $iHub $iSlot $iPort

#Unset the structure
unset MyL3Array


puts "Finished MOD_STREAMS_ARRAY"

#UnLink from the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"

