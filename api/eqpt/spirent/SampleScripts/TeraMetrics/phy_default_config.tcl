################################################################################################
# phy_default_config.tcl                                                                       #
#                                                                                              #
# - Demonstrates the configuration of Phy default setting for Terametrics XD port.             #
# - Read back the configuration and display it                                                 #
#                                                                                              #
################################################################################################

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



#################################################################################
# - If chassis is not currently linked, prompt for IP address and then link.    #
#                                                                               #
#################################################################################
  
if {[ETGetLinkStatus] < 0} {
	puts "SmartBits not linked - Enter chassis IP address"
	gets stdin ipaddr
	set retval [NSSocketLink $ipaddr 16385 $RESERVE_NONE]  
	if {$retval < 0 } {
		puts "Unable to connect to $ipaddr. Please try again."
		exit
	}
}



#################################################################################
# - Configure Phy default.                                                      #
#################################################################################

proc ConfigurePhyDefault {H S P } {

	puts "\nSetting Phy default ..."
	
	# Below we only set the active media, auto negotiation enable and duplex mode (link configuration)
	# auto negotiation restart and port speed are unchanged by using constant NS_FIELD_UNCHANGED
	struct_new phyDftCfg NSPhyDefaultConfig	
	set phyDftCfg(uiActiveMedia)            $::COPPER_MODE
	set phyDftCfg(uiAutoNegotiationEnable)  1
	set phyDftCfg(uiAutoNegotiationRestart) $::NS_FIELD_UNCHANGED
	set phyDftCfg(uiSpeed)                  $::NS_FIELD_UNCHANGED
	set phyDftCfg(uiLinkConfigurationMask)  0x0060
	set phyDftCfg(uiLinkConfiguration)      $::NS_PHY_DEFAULT_FULL_DUPLEX 
		
	LIBCMD HTSetStructure $::NS_PHY_DEFAULT_CONFIG 0 0 0 phyDftCfg  0 $H $S $P				
	unset phyDftCfg 
}


#################################################################################
# - Retrieve Phy default setting set by user, which will take effect after the  #
#   next HTSlotReboot or power cycle the chessis                                #
#################################################################################

proc DisplayPhyDefault {H S P } {

	struct_new phyDftCfgInfo NSPhyDefaultConfig	

	puts "\nGetting Phy default setting..."
	LIBCMD HTGetStructure $::NS_PHY_DEFAULT_CONFIG_INFO 0 0 0 phyDftCfgInfo  0 $H $S $P				

	puts "\nDisplay Phy default setting..."
	puts "  active media:             $phyDftCfgInfo(uiActiveMedia)"
	puts "  auto negotiation enable:  $phyDftCfgInfo(uiAutoNegotiationEnable)"
	puts "  auto negotiation restart: $phyDftCfgInfo(uiAutoNegotiationRestart)"
	puts "  port speed:               $phyDftCfgInfo(uiSpeed)"
	puts "  link configuration mask:  $phyDftCfgInfo(uiLinkConfigurationMask)"
	puts "  link configuration:       $phyDftCfgInfo(uiLinkConfiguration)" 
		
	unset phyDftCfgInfo 
}

set TxHub 0
set TxSlot 0
set TxPort 0


# Reserve the cards
LIBCMD HTSlotReserve $TxHub $TxSlot

# Reset the cards
LIBCMD HTResetPort $RESET_FULL $TxHub $TxSlot $TxPort

#################################################################################
# - Configure Phy default.                                                      #
#                                                                               #
#################################################################################
ConfigurePhyDefault $TxHub $TxSlot $TxPort

#################################################################################
# - Retrieve Phy default setting set by user, which will take effect after the #
#   HTSlotReboot or power cycle the chessis                                     #
#################################################################################
DisplayPhyDefault $TxHub $TxSlot $TxPort

# Release the slot
LIBCMD HTSlotRelease $TxHub $TxSlot

# Unlink from Chassis
NSUnLink
puts "\nDONE!"