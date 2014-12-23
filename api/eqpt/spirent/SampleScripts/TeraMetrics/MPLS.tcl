####################################################################################
#                                                                                  # 
# MPLS.tcl                                                                         #
#                                                                                  #
# - This sample illustrates how to configure a Teramterics card for dynamic        #
#   MPLS - Only on TERAMETRIC cards.                                               #
#   2 cards are need for dynamic MPLS.                                             #
# - This sample assumes that the cards are in slot 0 and 1.                        #
#   It create an MPLS subprocess on each card, before MPLS configurations          #
#   begins.                                                                        #
#                                                                                  #
#                                                                                  #
#                                                                                  #
####################################################################################
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




#Create Routing Domain
proc CreateRoutingDomain {H S P	} {
	upvar LocalIP LocalIP PeerIP PeerIP
	
	struct_new CreateRD MPLSRoutingDomain					  
	set CreateRD(ucLocalIPAddress) $LocalIP($S)	
	set CreateRD(ucPeerIPAddress)  $PeerIP($S) 	
	set CreateRD(ucLocalNetMask) {255 255 255 0}
	set CreateRD(ulMaxLSPRequest) 20
			
	LIBCMD HTSetStructure $::MPLS_ROUTING_DOMAIN_CREATE 0 0 0 CreateRD 0 $H $S $P   
	after 1000
}
#Delete Routing Domain
proc DeleteRoutingDomain {H S P } {
	
	struct_new DeleteRD MPLSRoutingDomainDeleteAll  	                          
	set DeleteRD(ulPacketRate) 5	
	set DeleteRD(ulLeaveLSPs) 0
	
	LIBCMD HTSetStructure $::MPLS_ROUTING_DOMAIN_DELETE_ALL 0 0 0 DeleteRD 0 $H $S $P	
}
# Create LSP's
proc CreateLSP {H S P } {
	upvar PeerIP PeerIP
	
	struct_new CreateLSP MPLSLSP  	                          
	set CreateLSP(ulRoutingDomainIndex) 0;
	set CreateLSP(ucEgressIP) $PeerIP($S)				
	set CreateLSP(ulExtendedTunnelID) 1234
	set CreateLSP(uiTunnelID)  1
				
	LIBCMD HTSetStructure $::MPLS_LSP_CREATE 0 0 0 CreateLSP 0 $H $S $P
	after 2000	
}
#Check if all LSP's have establised
proc IsLSPComplete { H S P } {
	struct_new Lsp MPLSLSPNotComplete		
	LIBCMD HTGetStructure $::MPLS_LSP_NOT_COMPLETE 0 0 0 Lsp 0 $H $S $P
		
	return $Lsp(ulCount)	
}
#Start MPLS Signalling
proc Start { H S P } {
	
	struct_new Start MPLSStart
	set Start(ulPacketRate) 20	
	
	LIBCMD HTSetStructure $::MPLS_START 0 0 0 Start 0 $H $S $P
	after 1000	
}
#Get Number of LSP's
proc GetLSPCount { H S P } {
    
    struct_new LSPCount MPLSLSPCountInfo

    LIBCMD HTGetStructure $::MPLS_LSP_COUNT_INFO  0 0 0 LSPCount 0 \
			$H $S $P
    puts "Number of LSP's on card $S ==> $LSPCount(ulLSPCount)"  
    
}
#Get Labels
proc GetRoutingDomainLSPLabelInfo { H S P LspCount} {
    
    struct_new LabelInfo MPLSLabelDataInfo*$LspCount
    LIBCMD HTGetStructure $::MPLS_LABEL_DATA_INFO 0 0 0 LabelInfo 0 \
			$H $S $P

    for {set j 0} {$j < $LspCount} {incr j} {
	    puts "Routing Domain Index 0"
	    puts "LSP Index:$LabelInfo($j.ulLSPIndex)  card [expr $S + 1] Label ==> $LabelInfo($j.ulLabel).\n"		
    }
    
}
#Create subprocess
proc CreateSubProcess { H S P } {
	
	struct_new CreateSubproc NSCreateSubprocess                             
	set CreateSubproc(ulUserID)             0		           		                         
	set CreateSubproc(ulGroupID)         	0	                         					                         
	set CreateSubproc(uiModuleID)  	49664                                 					                         					                         
	set CreateSubproc(ulSharedMemKey)    	286331153    
	set CreateSubproc(ucCommand.0)        	[ConvertCtoI "m"]
	set CreateSubproc(ucCommand.1)        	[ConvertCtoI "p"]
	set CreateSubproc(ucCommand.2)        	[ConvertCtoI "l"]
	set CreateSubproc(ucCommand.3)        	[ConvertCtoI "s"]
	set CreateSubproc(ucCommand.4)        	[ConvertCtoI "d"]
	                 
	LIBCMD HTSetStructure $::NS_CREATE_SUBPROCESS 0 0 0 CreateSubproc 0 $H $S $P
	return $CreateSubproc(ulSubprocessHandle)
	after 2000

}
#Create more LSP's
proc CopyDelta { H S P } {
    upvar NumLSP NumLSP
    struct_new delta MPLSLSPCopyDelta
    set delta(uiTunnelID) 1
    LIBCMD HTSetStructure $::MPLS_LSP_COPY_DELTA 0 [expr $NumLSP -1] 0 delta 0 \
		    $H $S $P
    after 2000    
}
    
    
   


#Define Structures and variables
set iTxHub 0
set iTxSlot 0
set iTxPort 0

set iRxHub 0
set iRxSlot 1
set iRxPort 0

set NumLSP 5
struct_new ulSubHandle ULong*2


set LocalIP($iTxSlot) {192 168 1 1}
set LocalIP($iRxSlot) {192 168 1 2}

set PeerIP($iTxSlot) {192 168 1 2}
set PeerIP($iRxSlot) {192 168 1 1}


###########################################################################################
# Reset cards                                                                             #
###########################################################################################
LIBCMD HTSlotReserve $iTxHub $iTxSlot
LIBCMD HTSlotReserve $iRxHub $iRxSlot

###########################################################################################
# Create an MPLS subprocess on each card(Tx and Rx), save the handle that is returned     #
# for each SubProcess. To be used to destroyed the subprocess at the end of the test.     #
###########################################################################################
puts "Creating Subprocess on both cards...\n"  
set ulSubHandle(0) [CreateSubProcess $iTxHub $iTxSlot $iTxPort]
set ulSubHandle(1) [CreateSubProcess $iRxHub $iRxSlot $iRxPort]

###########################################################################################
# Create Rounting Domain on Tx and Rx cards.                                              #
###########################################################################################
puts "Creating Rounting Domain on both cards...\n" 
CreateRoutingDomain $iTxHub $iTxSlot $iTxPort
CreateRoutingDomain $iRxHub $iRxSlot $iRxPort

###########################################################################################
# Create LSP's on Tx and Rx cards.                                                        #
###########################################################################################
puts "Creating one LSP on both cards...\n" 
CreateLSP $iTxHub $iTxSlot $iTxPort
CreateLSP $iRxHub $iRxSlot $iRxPort

###########################################################################################
# Create more LSP's on Tx and Rx cards using MPLS_LSP_COPY_DELTA.                                                        #
###########################################################################################
puts "Creating [expr $NumLSP -1] LSP on both cards...\n"
CopyDelta $iTxHub $iTxSlot $iTxPort
CopyDelta $iRxHub $iRxSlot $iRxPort

###########################################################################################
# Start MPLS signalling                                                                   #
###########################################################################################
puts "Start MPLS signalling...\n" 
Start $iTxHub $iTxSlot $iTxPort
Start $iRxHub $iRxSlot $iRxPort

###########################################################################################
# Check the number of LSP's that haven't established yet.                                 #
###########################################################################################
puts "Check for LSP to be up...\n" 
set NumIncompleteLSP [IsLSPComplete $iTxHub $iTxSlot $iTxPort]
while {$NumIncompleteLSP > 0} {
	set $NumIncompleteLSP [IsLSPComplete $iTxHub $iTxSlot $iTxPort]
	puts "Number of LSP's not established: $NumIncompleteLSP"
	after 2000
}

set NumIncompleteLSP [IsLSPComplete $iRxHub $iRxSlot $iRxPort]
while {$NumIncompleteLSP > 0} {
	set $NumIncompleteLSP [IsLSPComplete $iRxHub $iRxSlot $iRxPort]
	puts "Number of LSP's not established: $NumIncompleteLSP"
	after 2000
}	

###########################################################################################
# Get Labels create on LSP's                                                              #
###########################################################################################
GetRoutingDomainLSPLabelInfo $iTxHub $iTxSlot $iTxPort $NumLSP
GetRoutingDomainLSPLabelInfo $iRxHub $iRxSlot $iRxPort $NumLSP

###########################################################################################
# Get Number of LSP's on Routing Domain 0                                                 #
###########################################################################################
GetLSPCount $iTxHub $iTxSlot $iTxPort
GetLSPCount $iRxHub $iRxSlot $iRxPort

###########################################################################################
# Delete Routing Domain                                                                   #
###########################################################################################
puts "Delete Routing Domain on both cards...\n"
DeleteRoutingDomain $iTxHub $iTxSlot $iTxPort
DeleteRoutingDomain $iRxHub $iRxSlot $iRxPort




###########################################################################################
# Destroy SubProcess                                                                 #
###########################################################################################
puts "Destroying SubProcess on both cards...\n"
LIBCMD HTSetStructure $::NS_DESTROY_SUBPROCESS 0 0 0 ulSubHandle(0) 0 \
			$iTxHub $iTxSlot $iTxPort

LIBCMD HTSetStructure $::NS_DESTROY_SUBPROCESS 0 0 0 ulSubHandle(1) 0 \
			$iRxHub $iRxSlot $iRxPort


#UnLink the chassis
puts "UnLinking from the chassis now.."
ETUnLink



