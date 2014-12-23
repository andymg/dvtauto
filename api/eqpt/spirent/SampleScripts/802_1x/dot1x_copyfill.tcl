################################################################################################
# dot1x_copyfill.tcl                                                                           #
#                                                                                              #
# - Demonstrates the configuration of Supplicants for Terametrics XD and Xenpak cards.         #
# - Configures the Port for Supplicant Configuration                                           #
# - Configures one supplicant.      																			  #
# - Use copy command (NS_DOT1X_SUPPLICANT_COPY) to create 9 additional supplicants.            #
# - Use fill command (NS_DOT1X_SUPPLICANT_FILL) to change and increment Source MAc   			  #
# - Displays Port Statistics of Supplicants.                                                   #
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
#                                                                               #
#################################################################################

proc ConfigurePort {SetupInterval H S P } {

    struct_new portConfig NSDOT1XSupplicantPortConfig
    set portConfig(ulSessionSetupDelay) 	$SetupInterval
    set portConfig(ulSessionTearDownDelay) 20
    set portConfig(ulSessionBurstSize) 	100
    set portConfig(uiSessionMaxPending) 	100
    set portConfig(ucSessionControlMode)     $::DOT1X_SESSION_CONTROL_EVEN_BURST
    set portConfig(ucPortAuthenticationMode) $::DOT1X_MAC_BASED_AUTHENTICATION_MODE
    
    puts "\nConfiguring Port ..."
    LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_PORT_CONFIG 0 0 0 portConfig 0 $H $S $P
    unset portConfig
}


#################################################################################
# - Configure Supplicant                                                        #
#   Configure 1 Supplicants.                                                    #
#################################################################################

proc ConfigureSupplicant {AuthenticationTime HeldTime RetryTimes H S P } {

    struct_new supplicantConfigure NSDOT1XSupplicantConfig
    set supplicantConfigure(ulIndex) 0
    set supplicantConfigure(ulCount) 1
    set supplicantConfigure(ucSourceMAC) {2 2 2 2 2 2}
    set supplicantConfigure(ucDestinationMAC) {1 2 3 4 5 6}
    set supplicantConfigure(ucAuthenticationMode) $::DOT1X_AUTHENTICATION_MODE_ACTIVE
    set supplicantConfigure(uiMaxStart) 3
    set supplicantConfigure(uiStartTime) 30
    set supplicantConfigure(uiAuthenticationTime) $AuthenticationTime
    set supplicantConfigure(uiHeldTime) $HeldTime
    set supplicantConfigure(ucAuthenticationMethod) $::DOT1X_AUTHENTICATION_METHOD_EAPMD5
    set supplicantConfigure(ucAuthenticationID._char_) "tom"
    set supplicantConfigure(ucAuthenticationPassword._char_) "tom123"
    set supplicantConfigure(uiRetryCount) $RetryTimes
    
    puts "Configuring Supplicant ..."
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
    set startSupplicant(ulCount) 10
    set startSupplicant(ulAction) $::DOT1X_SUPPLICANT_START
    
    puts "Starting Supplicant to begin Authenticating ..."
    LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_CONTROL 0 0 0 startSupplicant 0 $H $S $P
    unset startSupplicant
}


#################################################################################
# - Stop Supplicants                                                            #
#	 Stop all Supplicants                                                        #
#################################################################################

proc StopSupplicant {H S P } {

    struct_new stopSupplicant NSDOT1XSupplicantControl
    
    set stopSupplicant(ulIndex) 0
    set stopSupplicant(ulCount) $::DOT1X_ALL
    set stopSupplicant(ulAction) $::DOT1X_SUPPLICANT_STOP
    
    puts "Stopping Supplicants ..."
    LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_CONTROL 0 0 0 stopSupplicant 0 $H $S $P
    unset stopSupplicant

}


#################################################################################
# - Copy Supplicant                                                             #
# - Copy Supplicant at index 0 and create 9 new Supplicants with the same       #
#   configuration as Supplicant at index 0                                      #
#################################################################################

proc CopySupplicant {H S P } {

    struct_new supplicantCopy NSDOT1XSupplicantCopy
    
    set supplicantCopy(ulBaseIndex) 0
    set supplicantCopy(ulDestinationIndex) 1
    set supplicantCopy(ulCount) 9
    
    puts "Copying Supplicant ..."
    LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_COPY 0 0 0 supplicantCopy 0 $H $S $P
    unset supplicantCopy
}

#################################################################################
# - Fill Supplicant                                                             #
# - Increment Source MAC for Supplicants with index 1 to 9                      #
#   Source MAC for Supplicant 1 will be 3.3.3.3.3.3, Supplicant 2 will be       #
#   4.4.4.4.4.4 and so on.                                                      #
#################################################################################

proc FillSupplicant {H S P } {

    struct_new supplicantFill NSDOT1XSupplicantFill
    
    set supplicantFill(ulBaseIndex) 0
    set supplicantFill(ulDestinationIndex) 1
    set supplicantFill(ulCount) 9
    set supplicantFill(uiField) $::DOT1X_SUPPLICANT_SRC_MAC
    for {set i 0} {$i < 6} {incr i} {
        set supplicantFill(ucDelta.$i) 1
    }
    
    puts "Changing Source MAC with Fill command ..."
    LIBCMD HTSetStructure $::NS_DOT1X_SUPPLICANT_FILL 0 0 0 supplicantFill 0 $H $S $P
    unset supplicantFill
}

################################################################################
# CreateU64String - Creates a U64 or double long string by appending the ulong #
#                   values $high and $low                                      #
#                                                                              #
# inputs:  high: the first 32 bits of the double long value                    #
#           low: the last 32 bits of the double long value                     #
#                                                                              #
# returns:  The string created by appending the values $high and $low.         #
################################################################################
proc CreateU64String {high low} {
    switch -- $high {
        0 {return $low}
        default {
            return "$high$low"
    }
    } 
}

#################################################################################
# - Retrieve Statistics                                                         #
#	                                                                        #
#################################################################################

proc DisplayPortStats {H S P } {

    struct_new stats NSDOT1XSupplicantSessionStatsInfo
    
    puts "\nDisplaying Port Statistics for Supplicants "
    LIBCMD HTGetStructure $::NS_DOT1X_SUPPLICANT_SESSION_STATS_INFO 0 0 0 stats 0 $H $S $P
    
    puts "\n-----------------------------------------------------------------------------------"
    puts " Setup Rate for Supplicants                   :  $stats(ulSetupRate) "
    puts " Authentications Attempted                    :  $stats(ulAuthenticationAttempted) "
    puts " Authentications Successful                   :  $stats(ulAuthenticationSuccessful) "
    puts " Authentications Failed                       :  $stats(ulAuthenticationFailed) "
    puts " Authentication Retries                       :  $stats(ulAuthenticationRetries) "
    puts " Supplicants being Retried                    :  $stats(ulRetried) "
    puts " Failed Supplicants (retries exhausted)       :  $stats(ulFailed) "
    puts " Supplicants Configured                       :  $stats(ulConfigured) "
    puts " Supplicants being Authenticated              :  $stats(ulAuthenticating) "
    puts " Supplicants Authenticated                    :  $stats(ulAuthenticated)  "
    puts " Supplicants Configured, but Idle             :  $stats(ulIdle)"
    puts " Supplicants being Retried or being Started   :  $stats(ulPending)"
    puts " Supplicants being Stopped (in Pending State) :  $stats(ulTerminatedPending)"
    puts " Time when Statistics was Collected           :  $stats(SessionRetrievedTime.ulSecond) seconds\
        $stats(SessionRetrievedTime.ulMicrosecond) microseconds"
    puts " Time when Statistics was Updated             :  $stats(SessionUpdateTime.ulSecond) seconds \
        $stats(SessionUpdateTime.ulMicrosecond) microseconds"
    puts " Total Time for Supplicant Authentication     :  [CreateU64String $stats(u64SetupTime.high) \
        $stats(u64SetupTime.low)]"
    puts "\n-----------------------------------------------------------------------------------"
    
    unset stats
	
}

#################################################################################
# - Check the state of Supplicants                                              #
#	 Verify if both Supplicants have been Authenticated                     #
#################################################################################

proc CheckSupplicantState {SetupInterval AuthenticationTime HeldTime RetryTimes H S P} {

    # Total Maximum Time for each Supplicant to be Authenticated
    set maxAuthenticatingTime [expr $SetupInterval + \
        ($RetryTimes*($AuthenticationTime + $HeldTime))*1000 ]
    set totalAuthenticationTime [expr $maxAuthenticatingTime *10]  ;# for all Supplicants
    set elapsedTotalTime 0
    
    struct_new supplicantStatus NSDOT1XSupplicantStatusInfo*10
    
    puts "Checking for Successful Authentication ..."
    LIBCMD HTGetStructure $::NS_DOT1X_SUPPLICANT_STATUS_INFO 0 10 0 supplicantStatus 0 $H $S $P
    
    for {set i 0} {$i < 10} {incr i} {
        while { ($supplicantStatus($i.ucSupplicantState) != $::DOT1X_SUPPLICANT_AUTHENTICATED) || \
            ($supplicantStatus($i.ucSessionState) != $::DOT1X_SUPPLICANT_SESSION_AUTHENTICATED) } {
            
            after $maxAuthenticatingTime
            LIBCMD HTGetStructure $::NS_DOT1X_SUPPLICANT_STATUS_INFO 0 10 0 supplicantStatus 0 $H $S $P
            incr elapsedTotalTime [expr $maxAuthenticatingTime]
        }
    }
    
    if {$elapsedTotalTime >= $totalAuthenticationTime} {
        puts " *** ERROR Authentication Failed ***"
    }
}


set TxHub 0
set TxSlot 0
set TxPort 0
source show.tcl

struct_new ulSubHandle ULong

set SetupInterval 20         ;# Setup Interval between Supplicants
set AuthenticationTime 30    ;# Authentication time - time that a supplicant waits for a response from the 
                             #Authenticator before timing out
set HeldTime 60              ;# Time to wait after Authenticator Failure in seconds
set RetryTimes 1             ;# Number of Retry attempts after Authentication Failure

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
ConfigurePort $SetupInterval $TxHub $TxSlot $TxPort 


#################################################################################
# - Configure Supplicants.                                                      #
#                                                                               #
#################################################################################
ConfigureSupplicant $AuthenticationTime $HeldTime $RetryTimes $TxHub $TxSlot $TxPort 


#################################################################################
# - Copy Supplicant Configuration.                                              #
#                                                                               #
#################################################################################
CopySupplicant $TxHub $TxSlot $TxPort


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
after 3000
#################################################################################
# - Check Supplicant State                                                      #
#                                                                               #
#################################################################################
CheckSupplicantState $SetupInterval $AuthenticationTime $HeldTime $RetryTimes \
                     $TxHub $TxSlot $TxPort
                     

#################################################################################
# - Display Port Statistics                                                     #
#                                                                               #
#################################################################################
DisplayPortStats $TxHub $TxSlot $TxPort

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