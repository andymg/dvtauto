###########################################################################################
# L3ClearStreams.tcl                                                                      #
#                                                                                         #
# - Displays the number of streams on target L3 card originally.                          #
# - Adds 10 more streams to the card.                                                     #
# - Displays the number of streams on target L3 card after adding 10 more streams.        #
# - Then clears the streams from the card.                                                #
# - Displays the number of streams after clearing the streams on the card                 #
# Please Note:                                                                            #
# - Stream 0 on layer three cards is reserved for internal use.                           #
# - This 0 stream on layer three cards is set to inactive so it will not                  #
#   transmit.                                                                             #
# - For this reason, there will always be one stream reported                             #
#   on the target L3 card.  If you want the program to report the number                  #
#   of user available streams on the cards, use expr to subtract one from the result.     #
#   as in:                                                                                #
#   "There are [expr $DefStreams(0.ul) - 1] streams"                                      #
#                                                                                         #
# NOTE: This script will run on the following cards only:                                 #
#       - L3-67XX                                                                         #
#       - ML-7710                                                                         #
#       - ML-5710                                                                         #
#       - LAN-6101A                                                                       #
#       - LAN-3300A / 3301A                                                               #
#       - LAN- 3310A / 3311A
#       - POS-3505A / 3504                                                                 #
#                                                                                         #
###########################################################################################


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

#Declare default variables
set iHub 0
set iSlot 0
set iPort 0
set DATA_LENGTH 60

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

#Declare a new structure
struct_new StreamCount ULong

#Get the number of streams on the card and display it
LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort
puts "Number of streams currently on the card [expr $iSlot + 1] is $StreamCount(ul)"


#Set up and add streams on card          
puts "Setting up streams on the card, please wait.."

#Declare a structure
struct_new streamIP StreamIP*10

#Add 10 more streams to the card
for {set i 0} {$i < 10} {incr i} {
      set streamIP($i.ucActive) [format %c 1]
      set streamIP($i.ucProtocolType) [format %c $L3_STREAM_IP]
      set streamIP($i.uiFrameLength) $DATA_LENGTH
      set streamIP($i.ucRandomLength) [format %c 1]
      set streamIP($i.ucTagField) [format %c 1]
      set streamIP($i.DestinationMAC.0.uc) [format %c 0]
      set streamIP($i.DestinationMAC.1.uc) [format %c 0]
      set streamIP($i.DestinationMAC.2.uc) [format %c 0]
      set streamIP($i.DestinationMAC.3.uc) [format %c 0]
      set streamIP($i.DestinationMAC.4.uc) [format %c 1]
      set streamIP($i.DestinationMAC.5.uc) [format %c 0]
      set streamIP($i.SourceMAC.0.uc) [format %c 0]
      set streamIP($i.SourceMAC.1.uc) [format %c 0]
      set streamIP($i.SourceMAC.2.uc) [format %c 0]
      set streamIP($i.SourceMAC.3.uc) [format %c 0]
      set streamIP($i.SourceMAC.4.uc) [format %c 0]
      set streamIP($i.SourceMAC.5.uc) [format %c 1]
      set streamIP($i.TimeToLive) [format %c 10]
      set streamIP($i.DestinationIP.0.uc) [format %c 192]
      set streamIP($i.DestinationIP.1.uc) [format %c 158]
      set streamIP($i.DestinationIP.2.uc) [format %c 100]
      set streamIP($i.DestinationIP.3.uc) [format %c 1]
      set streamIP($i.SourceIP.0.uc) [format %c 192]
      set streamIP($i.SourceIP.1.uc) [format %c 148]
      set streamIP($i.SourceIP.2.uc) [format %c 100]
      set streamIP($i.SourceIP.3.uc) [format %c 1]
      set streamIP($i.Protocol) [format %c 4]
}

#Set the streams on the card
LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 streamIP 0 $iHub $iSlot $iPort

#Unset the structure
unset streamIP

puts ""

#Get the number of streams after adding 10 more streams
LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort

#Display the number of streams on the card
puts "Number of streams added on card [expr $iSlot + 1] are $StreamCount(ul) "

#Clear the streams from the card
puts "Clearing streams on the card, please wait.."
LIBCMD HTSetStructure $L3_DEFINE_SMARTBITS_STREAM 0 0 0 "" 0 $iHub $iSlot $iPort

#Get the number of streams on the card after clearing the streams
LIBCMD HTGetStructure $L3_DEFINED_STREAM_COUNT_INFO 0 0 0 StreamCount 0 $iHub $iSlot $iPort
puts ""
puts "Number of streams after clearing all the streams on card [expr $iSlot + 1] is $StreamCount(ul)"
puts "--------------------------------------------------------------------------------"
puts "Please Note:"
puts "Number of streams, after the streams have been cleared will always report 1,"
puts "as 0 has been reserved for internal use."
puts "--------------------------------------------------------------------------------"

#Unset the structure
unset StreamCount

#UnLink from the chassis.
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts ""
puts "DONE!"


