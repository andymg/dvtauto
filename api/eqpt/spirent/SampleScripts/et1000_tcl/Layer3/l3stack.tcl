#################################################################################################################
# L3stack.tcl                                                                                                   #
#                                                                                                               #
#  - This program sets the Layer3 information for the card in first slot only.                                  #
#  - The fields of the Layer3Address structure are:                                                             #
#    - struct_typedef Layer3Address {struct {UChar*6 szMACAddress}                                              #
#                                     {UChar*4 IP}                                                              #
#                                     {UChar*4 Netmask}                                                         #
#                                     {UChar*4 Gateway}                                                         #
#                                     {UChar*4 PingTargetAddress}                                               #
#                                     {int iControl}                                                            #
#                                     {int iPingTime}                                                           #
#                                     {int iSNMPTime}                                                           #
#                                     {int iRIPTime}                                                            #
#                                     {int iGeneralIPResponse}                                                  #
#       }                                                                                                       #
# - After setting the card with this program, you can verify the settings                                       #
#   using debug in SmartWindows.                                                                                #
# - Please note:                                                                                                #
#   -  The gateway address is the Ip address of the router port you are connecting to.                          #
#      If this is not correct, you will not pass any traffic.                                                   #
#   -  The IP address and MAC address are for the card itself.                                                  #
#      These addresses MUST be different than the router port and different from any of the IP streams.         #
#      You will encounter problems if you do not set different addresses.                                       #
#   -  To avoid accidentally adding a stream with the same value, it is recomended that you set the values      #
#      for the card lower than the values for the base stream.                                                  #
#      - For example, if the card is set to:  MAC address of 00 00 00 00 00 03 and                              #
#                                             IP  address of 192.168.100.3,                                     #
#                   set the first stream to:  MAC address of 00 00 00 00 00 10 and                              #
#                                             IP address of192.168.100.10.                                      #
#      Thus, when you use L3_DEFINE_MULTI to add 100 streams, there would be no danger of matching              #
#      the card settings.                                                                                       #
# - The (iControl) field enables or disables the choices that follow.                                           #
#   - If it is enabled, and the value of the field for ping ICMP etc is something other than zero, those        #
#     packets will be transmitted at the indicated rate.                                                        #
# - (iGeneralIPResponse) sets the respond to all ARPs.                                                          #                                                                                                                            #
#   - If this is enabled, the card will respond to all ARPs, even if there is not a stream configured with the  #
#     requested IP address.  It will respond with a bogus 00 00 00 00 00 5A MAC address, which may cause        #
#     problems.                                                                                                 #
#                                                                                                               #            #                                                                                                               #
# NOTE: This script works on the following cards:                                                               #
#       - L3-67XX                                                                                               #
#       - ML-7710                                                                                               #
#       - ML-5710                                                                                               #
#       - LAN-6101A                                                                                             #
#       - LAN-3300A/3301A                                                                                       #
#       - LAN-3310A/3311A                                                                                       #
#       - POS-6500/6502                                                                                         #
#       - POS-3505A/3504A                                                                                       #
#                                                                                                               #
#################################################################################################################


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

#Set the default values for Hub, SLot and Port
set iHub 0
set iSlot 0
set iPort 0

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

###########################################
#Set the Layer 3 information on the card  #
###########################################

puts "Setting the information for the card in the first Slot only"
puts ""

#Declare a new structure of type "Layer3Address"
struct_new addr Layer3Address


# Set the Layer 3 Card MAC Address
set addr(szMACAddress.0.uc) [format %c 0]
set addr(szMACAddress.1.uc) [format %c 0]
set addr(szMACAddress.2.uc) [format %c 0]
set addr(szMACAddress.3.uc) [format %c 0]
set addr(szMACAddress.4.uc) [format %c 0]
set addr(szMACAddress.5.uc) [format %c 1]

# Set the Layer 3 Card IP Address
set addr(IP.0.uc) [format %c 192]
set addr(IP.1.uc) [format %c 168]
set addr(IP.2.uc) [format %c 100]
set addr(IP.3.uc) [format %c 3]

# Set the Layer 3 Card Netmask
set addr(Netmask.0.uc) [format %c 255]
set addr(Netmask.1.uc) [format %c 255]
set addr(Netmask.2.uc) [format %c 255]
set addr(Netmask.3.uc) [format %c 0]

# Set the Layer 3 Card Gateway Address
set addr(Gateway.0.uc) [format %c 192]
set addr(Gateway.1.uc) [format %c 168]
set addr(Gateway.2.uc) [format %c 100]
set addr(Gateway.3.uc) [format %c 1]

# Set the Layer 3 Card Ping Target
set addr(PingTargetAddress.0.uc) [format %c 192]
set addr(PingTargetAddress.1.uc) [format %c 169]
set addr(PingTargetAddress.2.uc) [format %c 100]
set addr(PingTargetAddress.3.uc) [format %c 1]

#Enable frames. At present, "enable all types of frames", has been commented.
#set addr(iControl) 0x7  

#Disable frames
set addr(iControl) 0x0   

# Ping the gateway once every 1 second.
set addr(iPingTime) 1    

# Make an snmp request every 2 seconds.
set addr(iSNMPTime) 2    

# Send an RIP frame every 3 seconds.
set addr(iRIPTime) 3    

# Set the card to the above settings
LIBCMD HTLayer3SetAddress addr $iHub $iSlot $iPort

#Get the settings of the card, AT PRESENT, THIS COMMAND DOES NOT WORK
#                              --------------------------------------
LIBCMD HTLayer3GetAddress addr $iHub $iSlot $iPort

#Free resources
unset addr

#UnLink the chassis
puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts ""
puts "DONE!"

