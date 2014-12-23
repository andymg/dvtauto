################################################################################################
# ns_igmv3.tcl                                                                                 #
#                                                                                              #
# - Demonstrates the configuration of IGMPV3 on LAN6101/3101 cards.                            #
# - Creates an interface with multicast groups on the interface.                               #
# - Changes the filter mode on one group.                                                      #
# - Gets statistics for the multicast group and interface.                                     #
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



 
########################################################
#   Initialize IGMP Stack                              #
########################################################
proc InitializeIGMP {H S P } {
	
	struct_new Init NSIGMPv3Config	
	set Init(ucVersion)            		3
	set Init(ucOptions)             	64
	set Init(uiMaxNumGroups)        	20
	set Init(ucMaxAddressBlock)     	2
	set Init(uiMaxIPPerBlock)       	60
	set Init(ucRobustnessVariable) 	        2
	set Init(ucUnsolicitedReportInterval)   2		
	DCMD HTSetStructure $::NS_IGMPV3_CONFIG 0 0 0 Init 0 $H $S $P
	unset Init
	after 10000

}

########################################################
## Config Groups, include groups by setting	       #	
## uiFilterMode to  IGMPV3_INCLUDE_FILTER_MODE         #
########################################################
proc ConfigGroups {H S P } {

	struct_new groupConf NSIGMPv3GroupConfig	
	set groupConf(ucIPAddress)       {8 7 6 5}
	set groupConf(ucMACAddress)      {5 4 3 2 1 1}
	set groupConf(ucVLANEnable)           0
	set groupConf(uiVID)                  0
	set groupConf(uiNumInterface)         1
	set groupConf(uiIPAddressStepCount)   0
	set groupConf(uiMACStepCount)         0
	set groupConf(uiVIDStepCount)     0
	set groupConf(ucGroupIPAddress)  {0xe0 1 1 1}
	set groupConf(uiNumGroup)  1
	set groupConf(uiGroupIPStepCount) 0
	set groupConf(ulInitialReportGap) 50
	set groupConf(uiFilterMode) $::IGMPV3_INCLUDE_FILTER_MODE
	set groupConf(ucNumAddressBlock) 2			
	set groupConf(IPAddressBlock.0.ucStartIPAddress)         {9 1 1 1}
	set groupConf(IPAddressBlock.0.ucUpperIPAddressBoundary)  {9 1 1 2}
	set groupConf(IPAddressBlock.0.uiIPChangeStep)              1
	set groupConf(IPAddressBlock.0.uiNumIP)                     2			
	set groupConf(IPAddressBlock.1.ucStartIPAddress)          {11 1 1 1}
	set groupConf(IPAddressBlock.1.ucUpperIPAddressBoundary)  {11 1 1 2}
	set groupConf(IPAddressBlock.1.uiIPChangeStep)              1
	set groupConf(IPAddressBlock.1.uiNumIP)                     2	
		
	DCMD HTSetStructure $::NS_IGMPV3_GROUP_CONFIG 0 0 0 groupConf 0 $H $S $P
	after 10000				
	unset groupConf
}

########################################################
##   Retrieve and Check Stats 
########################################################
proc GroupStats {H S P} {

	struct_new stats NSIGMPv3StatsInfo		
	set stats(ucIPAddress)	{8 7 6 5}
	set stats(ucMACAddress) {5 4 3 2 1 1}
	set stats(ucVLANEnable)	0
	set stats(ucPRI)	0
	set stats(ucCFI)    0
	set stats(uiVID) 0
	set stats(ucGroupIPAddress)	{0xe0 1 1 1}
	
	DCMD HTGetStructure $::NS_IGMPV3_STATS_INFO 0 0 0 stats 0 $H $S $P
	puts "Total number of Allow group record messages sent out ==> $stats(ulAllowSent)"
	puts "Total number of Block group record messages sent out ==> $stats(ulBlockSent)"
	puts "Received number of V3 query messages                 ==> $stats(ulV3GroupQueryReceived)" 
	puts "Total number of IGMPV3 3 reports sent out            ==> $stats(ulTotalV3ReportSent)" 
	puts "Total number of Is Included group messages sent out  ==> $stats(ulIsIncludeSent)" 
	puts "Total number of Is Excluded group messages sent out  ==> $stats(ulIsExcludeSent)" 	
	puts "Total number of To Included group messages sent out  ==> $stats(ulToIncludeSent)" 
	puts "Total number of To Excluded group messages sent out  ==> $stats(ulToExcludeSent)" 
	puts "IGMPV2 query reports received   ==> $stats(ulV2QueryReceived)" 
	puts "IGMPV1 query reports received   ==> $stats(ulV1QueryReceived)"
	puts "IGMPV2 report messages received ==> $stats(ulV2ReportReceived)"
	puts "IGMPV2 report messages received ==> $stats(ulV1ReportReceived)"		
	
}

########################################################
## Modify Groups, by changing uiFilterMode             #
## to IGMPV3_EXCLUDE_FILTER_MODE                       #
########################################################
proc ModGroups {H S P} {

	struct_new modgroup NSIGMPv3GroupMod
	
	set modgroup(ucIPAddress)       {8 7 6 5}
	set modgroup(ucMACAddress)    {5 4 3 2 1 1}
	set modgroup(ucVLANEnable)           0
	set modgroup(uiVID)                  0
	set modgroup(ucGroupIPAddress)  {0xe0 1 1 1}
	set modgroup(uiFilterMode) $::IGMPV3_EXCLUDE_FILTER_MODE
	set modgroup(IPAddressBlockChange.ucStartIPAddress)         {9 1 1 1}
	set modgroup(IPAddressBlockChange.ucUpperIPAddressBoundary) {9 1 1 2}
	set modgroup(IPAddressBlockChange.uiIPChangeStep)              1
	set modgroup(IPAddressBlockChange.uiNumIP)                     2
			
	DCMD HTSetStructure $::NS_IGMPV3_GROUP_MOD 0 0 0 modgroup 0 $H $S $P
	after 30000
	unset modgroup

}

set TxHub        0
set TxSlot       0
set TxPort       0

set RxHub      0
set RxSlot      1
set RxPort      0


LIBCMD HTSlotReserve $TxHub $TxSlot
LIBCMD HTSlotReserve $RxHub $RxSlot

###########################################################################################
# Reset cards                                                                             #
###########################################################################################
LIBCMD HTResetPort $::RESET_FULL $TxHub $TxSlot $TxPort
LIBCMD HTResetPort $::RESET_FULL $RxHub $RxSlot $RxPort	

###########################################################################################
# Reset cards Speed                                                                       #
###########################################################################################
DCMD HTSetSpeed $::SPEED_100MHZ $TxHub $TxSlot $TxPort
DCMD HTSetSpeed $::SPEED_100MHZ $RxHub $RxSlot $RxPort			
after 2000
	
###########################################################################################
# Reset IGMP protocol stack                                                               #
###########################################################################################		
DCMD HTSetCommand $::L3_IGMP_RESET 0 0 0 "" $TxHub $TxSlot $TxPort
DCMD HTSetCommand $::L3_IGMP_RESET 0 0 0 "" $RxHub $RxSlot $RxPort
	
	
###########################################################################################
# Initialize IGMPV3 protocol stack                                                        #
###########################################################################################        				
InitializeIGMP $TxHub $TxSlot $TxPort
			
###########################################################################################
# Configure interfaces and multicast groups in each interface	                          #
########################################################################################### 		
ConfigGroups $TxHub $RxSlot $TxPort 

###########################################################################################
# Change state of existing multicast group    	                                          #
###########################################################################################			
ModGroups $TxHub $TxSlot $TxPort

###########################################################################################
# Get stats for multicast group	                                                          #
###########################################################################################
GroupStats $TxHub $TxSlot $TxPort 
				
###########################################################################################
# Leave All                                                    	                          #
###########################################################################################		
DCMD HTSetCommand $::NS_IGMPV3_LEAVE_ALL 0 0 0 "" $TxHub $TxSlot $TxPort

			
NSUnLink
puts "DONE!"