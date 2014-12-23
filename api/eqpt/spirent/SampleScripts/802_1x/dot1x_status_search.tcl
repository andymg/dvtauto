################################################################################################
# dot1x_status_search.tcl                                                                      #
#                                                                                              #
# - Demonstrates how to search for Supplicant(s) whose states Authenticated                    #
#                                                                                              #
#                                                                                              #
# - Configures the Port for Supplicant Configuration                                           #
# - Configures 20 Supplicants.      	                                                       #
# - Modifies the Source MAC of the Supplicants using NS_DOT1X_SUPPLICANT_FILL                  #
# - Uses Supplicants State (DOT1X_SUPPLICANT_STATUS_SUPPICANT_STATE) as the search criteria,   #
# - and return the indexes of Supplicants whose states are authenticated                       #
#   (DOT1X_SUPPLICANT_AUTHENTICATED)                                                           #
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
# - Start Supplicant Subprocess                                                 #
#	                                                                             #
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

#################################################################################
# - Configure the Port for Supplicant Configuration                             #
#   Configure the Port for Supplicants to be started at an even interval.       #
#   1 Supplicant will be started every 15ms.                                    #
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
#   Configure 20 Supplicants.                                                    #
#################################################################################

proc ConfigureSupplicant {H S P } {

	struct_new supplicantConfigure NSDOT1XSupplicantConfig	
	
	set supplicantConfigure(ulIndex) 0
	set supplicantConfigure(ulCount) 20
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
	set supplicantConfigure(uiRetryCount) 0
		
	puts "\nConfiguring Supplicant ..."
	LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_CONFIG 0 0 0 supplicantConfigure 0 $H $S $P				
	unset supplicantConfigure
}

#################################################################################
# - Start Supplicant                                                            #
#	 Start Supplicant with index 0 to index 9                               #
#################################################################################

proc StartSupplicant {H S P } {

	struct_new startSupplicant NSDOT1XSupplicantControl	
	
	set startSupplicant(ulIndex) 0
	set startSupplicant(ulCount) 20
	set startSupplicant(ulAction) $::DOT1X_SUPPLICANT_START
			
	puts "\nStarting Supplicant to begin Authenticating ..."
	LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_CONTROL 0 0 0 startSupplicant 0 $H $S $P				
	unset startSupplicant
}

#################################################################################
# - Stop Supplicants                                                            #
#	 Stop all Supplicants                                                   #
#################################################################################

proc StopSupplicant {H S P } {

	struct_new stopSupplicant NSDOT1XSupplicantControl	
	
	set stopSupplicant(ulIndex) 0
	set stopSupplicant(ulCount) $::DOT1X_ALL
	set stopSupplicant(ulAction) $::DOT1X_SUPPLICANT_STOP
			
	puts "\nStopping Supplicants ..."
	LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_CONTROL 0 0 0 stopSupplicant 0 $H $S $P				
	unset stopSupplicant
}

#################################################################################   
# - Fill Supplicant                                                             #   
# - Increment Source MAC for Supplicants with index 1 to 19                     #   
#   Source MAC for Supplicant 1 will be 3.3.3.3.3.3, Supplicant 2 will be       #   
#   4.4.4.4.4.4  and so on.                                                     #   
#################################################################################   
                                                                                    
proc FillSupplicant {H S P } {                                                      
                                                                                    
	struct_new supplicantFill NSDOT1XSupplicantFill	                                 
	                                                                                 
	set supplicantFill(ulBaseIndex) 0                                                
	set supplicantFill(ulDestinationIndex) 1                                         
	set supplicantFill(ulCount) 19                                                    
	set supplicantFill(uiField) $::DOT1X_SUPPLICANT_SRC_MAC                          
	for {set i 0} {$i < 6} {incr i} {
		set supplicantFill(ucDelta.$i) 1
	}	                                                  
	                                                                                 
	puts "\nChanging Source MAC with Fill command ..."                                 
	LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_FILL 0 0 0 supplicantFill 0 $H $S $P				
	unset supplicantFill                                                             
}                                                                                   

    

#################################################################################            
# - Search for Supplicants which are in Authenticated  State                    #            
#                                                                               #            
#################################################################################            
                                                                                             
proc StatusSearch {H S P } {                                                              
                                                                                             
	struct_new search NSDOT1XSupplicantStatusSearchInfo	                                    
	                                                                                          
	set search(ulIndex) 0                                                            
	set search(ulCount) 20                                                           
	set search(uiSearchField) $::DOT1X_SUPPLICANT_STATUS_SUPPICANT_STATE                                   
	set search(uiReturnField) $::DOT1X_SUPPLICANT_STATUS_INDEX 	 
	set search(u64SearchRangeLow.low) $::DOT1X_SUPPLICANT_AUTHENTICATED                                                    
	set search(u64SearchRangeHigh.low) $::DOT1X_SUPPLICANT_AUTHENTICATED
	 
	puts "\nSearch for Supplicants which are Authenticated ..."
	HTGetStructure $::NS_DOT1X_SUPPLICANT_STATUS_SEARCH_INFO 0 0 0 search 0 $H $S $P	
			
	puts "\nNumber of Supplicants Authenticated : $search(ulReturnCount)"
	puts "\nSupplicants Authenticated ..."
	for {set i 0} {$i < $search(ulReturnCount)} {incr i} {
		puts "Supplicant with index : $search(u64Data.$i.low)"
	}    
                                                              
	unset search                                                                     
}


#################################################################################
# - Check the state of Supplicants                                              #
#	 Verify if both Supplicants have been Authenticated                     #
#################################################################################

proc CheckSupplicantState {H S P} {
	
	struct_new supplicantStatus NSDOT1XSupplicantStatusInfo*10
	
	puts "\nChecking for Successful Authentication ..."	
	LIBCMD HTGetStructure $::NS_DOT1X_SUPPLICANT_STATUS_INFO 0 10 0 supplicantStatus 0 $H $S $P
	
	for {set i 0} {$i < 10} {incr i} {
		 
		while { ($supplicantStatus($i.ucSupplicantState) != $::DOT1X_SUPPLICANT_AUTHENTICATED) || \
		     ($supplicantStatus($i.ucSessionState) != $::DOT1X_SUPPLICANT_SESSION_AUTHENTICATED) } {	
		
			after 3000
			LIBCMD HTGetStructure $::NS_DOT1X_SUPPLICANT_STATUS_INFO 0 10 0 supplicantStatus 0 $H $S $P							
								
		}	
	}
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
# - Fill Parameter Supplicant Configuration.                                    #
#                                                                               #
#################################################################################
FillSupplicant $TxHub $TxSlot $TxPort


#################################################################################
# - Start Supplicant, to begin Authentication                                   #
#                                                                               #
#################################################################################
StartSupplicant $TxHub $TxSlot $TxPort 
	
	
#################################################################################
# - Check Supplicant State                                                      #
#                                                                               #
#################################################################################
CheckSupplicantState $TxHub $TxSlot $TxPort

#################################################################################  
# - Status Search                                                               #  
#   Search for Supplicants in Connecting, Acquired or Authenticating States     #  
#################################################################################  
StatusSearch $TxHub $TxSlot $TxPort                                            


#################################################################################
# - Stop Supplicants to end Authentication                                      #
#                                                                               #
#################################################################################
StopSupplicant $TxHub $TxSlot $TxPort 

#Destroy Subporcess
LIBCMD HTSetStructure $::NS_DESTROY_SUBPROCESS 0 0 0 ulSubHandle 0 $TxHub $TxSlot $TxPort

# Unlink from Chassis
NSUnLink
puts "DONE!"