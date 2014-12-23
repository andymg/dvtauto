

##########################################################################################
#Multi-Link.tcl                                                                          #
#                                                                                        #
#This sample allows the user to link to multiple SmartBits chassis:                      #
# - Checks if the "et1000.tcl file has been sourced, if not, then allows                 #
#   the user to specify the path to source it.                                           #
# - User has the choice to select an Ethernet Link or a Serial Link                      #
# - Links to multiple chassis                                                            #
# - Gets and Outputs the total number of links                                           #
# - Transmits packets to the multiple chassis                                            #
# - UnLinks from all the established links                                               #
#                                                                                        #
# NOTE: This script works on the following cards:                                        #
#       - All Cards                                                                      #
#                                                                                        #
##########################################################################################

#Set the path for the "et1000.tcl"
if {$tcl_platform(platform) == "windows"} {
  set libPath "../../../../tcl/tclfiles/et1000.tcl"
} else {
  set libPath "../../../../include/et1000.tcl"
}

# if the et1000.tcl file is not loaded, try to source it at the default path
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

# Enter the type of connection - Ethernet Link or Serial Port Link. Enter 'C' to Continue

set response ""
set count ""
set comport ""
while {1} {

            puts "Enter  the Type of link you would like to connect through: "
            puts "Enter 'E' or 'e' to establish an ethernet connection or "
            puts "Enter 'S' or 's' to establish a Serial Link connection."
            puts "Enter 'C' or 'c' to continue"
            gets stdin response 

            switch [string toupper $response] {
                                        # If chassis is not currently linked prompt for IP and link    
                                   E { 
                                       #Allows the user to enter an IP address for an ethernet connection
                                       puts "Enter chassis IP address"
                                       gets stdin ipaddr
                                       set retval [NSSocketLink $ipaddr 16385 $RESERVE_ALL]
                  
                                       #Check to see if there is an error
		                       if {$retval < 0} {
		                            puts " $ipaddr reports error $retval"
                                          } else {
                                                   puts "$ipaddr is now linked"
                                       }
		                    
	                            }
                                  S {    
                                      #Allows the user to enter a COM PORT Number           
                                      puts "Enter the COM PORT: ' number?'"
                                      gets stdin comport
                                      if {$comport < $ETMAXCOM} {
                                           LIBCMD ETLink [expr $comport - 1]
                                      }
	                            }
                                  C {
                                      #Allows to continue with the program
                                      break
	                            }
             }
}                  
	    
    #Get the number of total number of  multi-links established
    set count [ETGetTotalLinks]
    puts "The Total Number Of Links Are: $count" 
   
    #Transmit Packets
    for {set i 0} {$i < $count} {incr i} {
	LIBCMD HTRun $HTRUN [expr $i * 4] 0 0
    }

    #Stop Transmitting
    for {set i 0} {$i < $count} {incr i} {
	puts "Transmitting On: HUB: [expr $i * 4] SLOT: 0 PORT: 0"
	LIBCMD HTRun $HTSTOP [expr $i * 4] 0 0
         
    }
 
    #UnLink From All The Links Established
    for {set i 0} {$i < $count} {incr i} {
	puts "UnLinking Now: HUB: [expr $i * 4] SLOT: 0 PORT: 0"
    }    

    LIBCMD NSUnLinkAll


             
 
      
            
        
 
      


