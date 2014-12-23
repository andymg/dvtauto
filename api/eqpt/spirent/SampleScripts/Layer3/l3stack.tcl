######################################################################################################
# L3stack.tcl                                                                                        #
#                                                                                                    #
#  - Sets the Layer3 information for the card in first slot only                                     #
#                                                                                                    #
#  - The fields of the Layer3Address structure are:                                                  #
#                                                                                                    #
#  struct_typedef Layer3Address {struct                                                              #
#   {UChar*6 szMACAddress}                                                                           #
#   {UChar*4 IP}                                                                                     #
#   {UChar*4 Netmask}                                                                                #
#   {UChar*4 Gateway}                                                                                #
#   {UChar*4 PingTargetAddress}                                                                      #
#   {int iControl}                                                                                   #
#   {int iPingTime}                                                                                  #
#   {int iSNMPTime}                                                                                  #
#   {int iRIPTime}                                                                                   #
#   {int iGeneralIPResponse}                                                                         #
#  }                                                                                                 #
#  - After setting the card with this program you can verify the settings                            #
#     using debug in SmartWindows.                                                                   #
#                                                                                                    #
#  - Some things to note.  The gateway address is the Ip address of the router port                  #
#     you are connecting to.  If this is not correct, you will not pass any traffic.                 #
#                                                                                                    #
#  - Also note the IP address and MAC address are for the card itself.  This MUST be                 #
#    different than the router port and different from any of the IP streams.  You will              #
#    have problems if this is not so.  Set the values for the card lower than the values for         #
#    values for the base stream so you don't accidentally add a stream with the same value.          #
#    For example is the card is set to a MAC address of 00 00 00 00 00 03 and an IP                  #
#    address of 192.168.100.3, set the first stream to 00 00 00 00 00 10 and 192.168.100.10.         #
#    That way if you use L3_DEFINE_MULTI to add 100 streams, there's no danger of matching           #
#    the card settings.                                                                              #
#                                                                                                    #
# -  The (iControl) field enables or disables the choices that follow.  If it is enabled             #
#    and the value of the field for ping ICMP etc is something other than zero, those packets        #
#    will be transmitted at the indicated rate.                                                      #
#                                                                                                    #
# -  (iGeneralIPResponse) sets the respond to all ARPs.  If this is enabled, the card                #
#    will respond to all ARPs even if there is not a stream configured with the requested IP         #
#    address.  It will respond with a bogus 00 00 00 00 00 5A MAC address, which may cause           #
#    problems.                                                                                       #
#                                                                                                    #
# NOTE: This script works on the following cards:                                                    #
#       - L3-67XX                                                                                    #
#       - ML-7710                                                                                    #
#       - ML-5710                                                                                    #
#       - LAN-6101A                                                                                  #
#       - LAN-3300A/3301A                                                                            #
#       - LAN-3310A/3311A                                                                            #
#       - POS-6500/6502                                                                              #
#       - POS- 3505A/3504As                                                                          #
#                                                                                                    #
######################################################################################################

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


set iHub 0
set iSlot 0
set iPort 0

# Reserve the card
LIBCMD HTSlotReserve $iHub $iSlot

struct_new addr Layer3Address

# Layer 3 Card MAC Address
set addr(szMACAddress) {0 0 0 0 0 1}

#  Layer 3 Card IP Address
set addr(IP) {192 168 100 3}

#   Layer 3 Card Netmask
set addr(Netmask) {255 255 255 0}

#  Layer 3 Card Gateway Address
set addr(Gateway) {192 168 100 1}

#  Layer 3 Card Ping Target
set addr(PingTargetAddress) {192 169 100 1}

#set addr(iControl) 0x7  ;# enable all types of frames below
set addr(iControl) 0x0  ;# disable all types of frames below
set addr(iPingTime) 1   ;# ping the gateway once a second
set addr(iSNMPTime) 2   ;# make an snmp request every 2 seconds
set addr(iRIPTime) 3            ;# send a RIP frame every 3 seconds

LIBCMD HTLayer3SetAddress addr $iHub $iSlot $iPort

#Unset the structure
unset addr

puts "UnLinking from the chassis now.."
LIBCMD NSUnLink
puts "DONE!"
