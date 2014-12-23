################################################################################################
# dot1x_basic_config.tcl                                                                       #
#                                                                                              #
# - Demonstrates the configuration of Supplicants for Terametrics XD and Xenpak cards.         #
# - Configures the Port for Supplicant Configuration                                           #
# - Configures 2 Supplicants.      																				  #
# - Modifies the Source Mac of the Second Supplicant                                           #
# - Starts Supplicants to begin Authentication and Verifies Authentication                     #
# - Displays Statistics of Supplicants.                                                        #
# - This script assumes that an Authenticator is on the Rx, and the ID and Password            #
#   expected by the Authenticator is "tom" and "tom123" respectively.                          #
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
# - Configure the Port for Supplicant Configuration                             #
#   Configure the Port for Supplicants to be started at an even interval.       #
#################################################################################

proc ConfigurePort {H S P } {

	struct_new portConfig NSDOT1XSupplicantPortConfig	
	
	set portConfig(ulSessionSetupDelay) 	20
	set portConfig(ulSessionTearDownDelay) 20
	set portConfig(ulSessionBurstSize) 		10
	set portConfig(uiSessionMaxPending) 	100			
	set portConfig(ucSessionControlMode) 	$::DOT1X_SESSION_CONTROL_EVEN_BURST
	set portConfig(ucPortAuthenticationMode) $::DOT1X_MAC_BASED_AUTHENTICATION_MODE
		
	puts "\nConfiguring Port ..."
	LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_PORT_CONFIG 0 0 0 portConfig 0 $H $S $P				
	unset portConfig
}


#################################################################################
# - Configure Supplicant                                                        #
#   Configure 2 Supplicants.                                                    #
#################################################################################

proc ConfigureSupplicant {H S P } {

	struct_new supplicantConfigure NSDOT1XSupplicantConfig	
	
	set supplicantConfigure(ulIndex) 0
	set supplicantConfigure(ulCount) 2
	set supplicantConfigure(ucSourceMAC) {2 2 2 2 2 2}
	set supplicantConfigure(ucDestinationMAC) {1 2 3 4 5 6}
	set supplicantConfigure(ucAuthenticationMode) $::DOT1X_AUTHENTICATION_MODE_ACTIVE
	set supplicantConfigure(uiMaxStart) 3
	set supplicantConfigure(uiStartTime) 30
	set supplicantConfigure(uiAuthenticationTime) 30
	set supplicantConfigure(uiHeldTime) 60
	set supplicantConfigure(ucAuthenticationMethod) $::DOT1X_AUTHENTICATION_METHOD_EAPMD5
	set supplicantConfigure(ucAuthenticationID._char_) "tom"
	set supplicantConfigure(ucAuthenticationPassword._char_) "tom123"
	set supplicantConfigure(uiRetryCount) 1
		
	puts "Configuring Supplicant ..."
	LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_CONFIG 0 0 0 supplicantConfigure 0 $H $S $P				
	unset supplicantConfigure
}

#################################################################################
# - Modify Supplicant                                                           #
#	 Modify Source MAC of second Supplicant, change the Source MAC from     #
#	 2.2.2.2.2.2 to 7.7.7.7.7                                               #
#################################################################################

proc ModifySupplicant {H S P } {

	struct_new modSupplicant NSDOT1XSupplicantModify	
	
	set modSupplicant(ulIndex) 1
	set modSupplicant(ulCount) 1
	set modSupplicant(uiField) $::DOT1X_SUPPLICANT_SRC_MAC
	for {set i 0} {$i < 6} {incr i} {
		set modSupplicant(ucData.$i) 7
	}
	
	puts "Modifying Second Supplicant ..."
	LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_MODIFY 0 0 0 modSupplicant 0 $H $S $P				
	unset modSupplicant
}

#################################################################################
# - Check Authentication                                                        #
#   Check if Supplicants has been Authenticated                                 #
#################################################################################

proc CheckAuthentication {H S P } {

	struct_new supplicantStatus NSDOT1XSupplicantStatusInfo*2
	
	puts "Checking for Successful Authentication ..."	
	LIBCMD HTGetStructure $::NS_DOT1X_SUPPLICANT_STATUS_INFO 0 2 0 supplicantStatus 0 $H $S $P
	
	for {set i 0} {$i < 2} {incr i} {
		while { ($supplicantStatus($i.ucSupplicantState) != $::DOT1X_SUPPLICANT_AUTHENTICATED) || \
		     ($supplicantStatus($i.ucSessionState) != $::DOT1X_SUPPLICANT_SESSION_AUTHENTICATED) } {		   			   	  	
		   	after 1000
		   	LIBCMD HTGetStructure $::NS_DOT1X_SUPPLICANT_STATUS_INFO 0 2 0 supplicantStatus 0 $H $S $P
		   		   
		}
	}			
	unset supplicantStatus
}
#################################################################################
# - Start Supplicant                                                            #
#	 Start Supplicants                                                      #
#################################################################################

proc StartSupplicant {H S P } {

	struct_new startSupplicant NSDOT1XSupplicantControl	
	
	set startSupplicant(ulIndex) 0
	set startSupplicant(ulCount) 2
	set startSupplicant(ulAction) $::DOT1X_SUPPLICANT_START
			
	puts "Starting Supplicant to begin Authenticating ..."
	LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_CONTROL 0 0 0 startSupplicant 0 $H $S $P				
	unset startSupplicant
}


#################################################################################
# - Retrieve Statistics                                                         #
#                                                                               #
#################################################################################

proc DisplayStats {H S P } {

	struct_new supplicantStats NSDOT1XSupplicantStatsInfo*2
	LIBCMD HTGetStructure $::NS_DOT1X_SUPPLICANT_STATS_INFO 0 2 0 supplicantStats 0 $H $S $P
	
	for {set i 0} {$i < 2} {incr i} {
		puts "\nDisplaying Supplicant Statistics for Supplicant $i:"
		puts "---------------------------------------------------------------"
		puts "Tx EAPOL Start       Frames: $supplicantStats($i.ulTxEAPOLStartFrames)      "
		puts "Tx EAPOL LogOff      Frames: $supplicantStats($i.ulTxEAPOLLogOffFrames)     "
		puts "Tx EAPOL ResponseID  Frames: $supplicantStats($i.ulTxEAPOLResponseIDFrames) "
		puts "Tx EAPOL Response    Frames: $supplicantStats($i.ulTxEAPOLResponseFrames)   "
		puts "Tx EAPOL Key         Frames: $supplicantStats($i.ulTxEAPOLKeyFrames)        "
		puts "Tx EAPOL             Frames: $supplicantStats($i.ulTxEAPOLFrames)           "
		puts "Rx EAPOL             Frames: $supplicantStats($i.ulRxEAPOLFrames)           "
		puts "Rx EAPOL RequestID   Frames: $supplicantStats($i.ulRxEAPOLRequestIDFrames) "
		puts "Rx EAPOL Request     Frames: $supplicantStats($i.ulRxEAPOLRequestFrames)    "
		puts "Rx EAPOL Invalid     Frames: $supplicantStats($i.ulRxEAPOLInvalidFrames)    "
		puts "Rx EAPOL LengthError Frames: $supplicantStats($i.ulRxEAPOLLengthErrorFrames)"
		puts "Rx EAPOL Key         Frames: $supplicantStats($i.ulRxEAPOLKeyFrames)"
		puts "Rx EAPOL Success     Frames: $supplicantStats($i.ulRxEAPOLSuccessFrames)"
		puts "Rx EAPOL Failure     Frames: $supplicantStats($i.ulRxEAPOLFailureFrames)"
		puts "Rx EAPOL Alert       Frames: $supplicantStats($i.ulRxEAPOLAlertFrames)"
		puts "EAPOL Frame Version: $supplicantStats($i.ulEAPOLFrameVersion)"
		puts "Last Frame MAC Address: $supplicantStats($i.ucLastFrameMACAddress)"
		puts "---------------------------------------------------------------\n\n"
		
	}
	unset supplicantStats

}
#################################################################################
# - Start Supplicant Subprocess                                                 #
#	                                                                        #
#################################################################################

proc StartSubprocess {H S P } {

	struct_new subProcess NSCreateSubprocess
	set subProcess(ulUserID) 	0		           		                         
	set subProcess(ulGroupID)  0	                         					                         
	set subProcess(uiModuleID) 51968                       					                         					                         
	set subProcess(ulSharedMemKey)    	1684108910
 	set subProcess(ucCommand.0) [ConvertCtoI "d"]
 	set subProcess(ucCommand.1) [ConvertCtoI "o"]
 	set subProcess(ucCommand.2) [ConvertCtoI "t"]
 	set subProcess(ucCommand.3) [ConvertCtoI "1"]
 	set subProcess(ucCommand.4) [ConvertCtoI "x"]
 	set subProcess(ucCommand.5) [ConvertCtoI "d"]
 	
 	LIBCMD HTSetStructure $::NS_CREATE_SUBPROCESS 0 0 0 subProcess 0 $H $S $P
 	return  $subProcess(ulSubprocessHandle)
}


set TxHub 0
set TxSlot 0
set TxPort 0

struct_new ulSubHandle ULong

# Reserve the cards
LIBCMD HTSlotReserve $TxHub $TxSlot

# Reset the cards to the default values
LIBCMD HTResetPort $RESET_FULL $TxHub $TxSlot $TxPort

#################################################################################
# - Start Subprocess for Supplicant                                             #
#                                                                               #
#################################################################################
set ulSubHandle(ul) [StartSubprocess $TxHub $TxSlot $TxPort]

#################################################################################
# - Delete all supplicants, and clear all the supplicants and session           #
#   statistics on the port.                                                     #
#################################################################################
LIBCMD HTSetCommand $::NS_DOT1X_SUPPLICANT_RESET 0 0 0 "" $TxHub $TxSlot $TxPort

#################################################################################
# - Configure port for Supplicant configuration.                                #
#                                                                               #
#################################################################################
ConfigurePort $TxHub $TxSlot $TxPort

#################################################################################
# - Configure Supplicants.                                                      #
#                                                                               #
#################################################################################
ConfigureSupplicant $TxHub $TxSlot $TxPort

#################################################################################
# - Modify Supplicant Configuration.                                            #
#                                                                               #
#################################################################################
ModifySupplicant $TxHub $TxSlot $TxPort

#################################################################################
# - Start Supplicant, to begin Authentication                                   #
#                                                                               #
#################################################################################
StartSupplicant $TxHub $TxSlot $TxPort

#################################################################################
# - Check Authentication                                                        #
#                                                                               #
#################################################################################
CheckAuthentication $TxHub $TxSlot $TxPort

#################################################################################
# - Display Supplicant Statistics                                               #
#                                                                               #
#################################################################################
DisplayStats $TxHub $TxSlot $TxPort

#Destroy Subporcess
LIBCMD HTSetStructure $::NS_DESTROY_SUBPROCESS 0 0 0 ulSubHandle 0 $TxHub $TxSlot $TxPort

# Unlink from Chassis
NSUnLink
puts "DONE!"