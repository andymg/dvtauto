#######################################################################################
# Controller.tcl                                                                      #
#                                                                                     #
# Sample illustrates differences between SMB200/SMB2000 and                           #
# SMB600/SMB6000 chassis types                                                        #
#                                                                                     #
# There are two available modes COMPATIBLE MODE and NATIVE MODE                       #
#                                                                                     #
# COMPATIBLE MODE is designed to support existing scripts. This is                    #
# the mode you would select to use with existing scripts.                             #
#                                                                                     #
# NATIVE MODE is the more logical organization for the 6000/600                       #
# port layout.                                                                        #
#                                                                                     #
# The differences are explained in the SmartLibrary 3.07 documentation.               #
#                                                                                     #
# NOTE: This script works on the following cards:                                     #
#       - ALL CARDS                                                                   #
#######################################################################################


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


#################################################
# mode_limits
# displays the maximum values for
# hub slot and port in current mode
#
# The main program will call this in each of the 
# modes to illustrate the differences
#################################################
proc mode_limits {} {
   puts "This mode has:"
   puts " 	a maximum of [NSGetMaxHubs] Hubs"
   puts "	a maximum of [NSGetMaxSlots] Slots" 
   puts "	a maximum of [NSGetMaxPorts] Ports" 

}


############################################################
# Link to chassis - SMB600/SMB6000 family link via Ethernet only
# serial port is only used for set up
#
# Will prompt user for IP address and TCP Port Number.  
# Defaults are set for IPADDRESS and SOCKET.  User pressing ENTER
# accepts prompted default.
#
# Linking with ETSocketLink defaults to COMPATIBLE MODE
# Linking with NSSocketLink defaults to NATIVE MODE
#############################################################
set IPADDRESS 10.100.10.82
set SOCKET 16385

         puts "Enter IP Address (Press enter for default \[$IPADDRESS\]):"
         gets stdin response
	 if {$response != ""} {
             set IPADDRESS $response
         }
         puts "Enter Socket Number (Press enter for default \[$SOCKET\]):"
         gets stdin response
	 if {$response != ""} {
             set SOCKET $response
         }
         set iResp [ETSocketLink $IPADDRESS $SOCKET]
         if { $iResp < 0 } {
            puts "Ethernet link failed for IP address $IPADDRESS and socket $SOCKET"
         } else {
            puts "Ethernet linked"
         }  
####################################################
# Get Family Type wit ETGetProductFamily
#
# Values returned include:
#define FAMILY_UNKNOWN			  0
#define FAMILY_ET1000			  1
#define FAMILY_SMB2000			  2
#define FAMILY_SMB6000			  3
#####################################################
puts "\n\n"
puts "###############################################"
puts "	     CONTROLLER FAMILY AND MODEL"
puts ""

set product_family [ETGetProductFamily]
        switch $product_family {
                0 {puts "	   Unknown Product Family" }
                1 {puts "	   ET1000 Product Family"}
                2 {puts "	   SMB1000 Product Family"}
                3 {puts "	   SMB6000 Product Family"}
                default {puts "	   ERROR: Unknown type code"}
         }

#############################################################
#ETGetController will return an integer that identifies the
# controller type.  The defined types are (from ET1000.H)
#
#define CONTROLLER_UNKNOWN      	0
#define CONTROLLER_ET1000       	1
#define CONTROLLER_SMB1000      	2
#define CONTROLLER_SMB2000      	3
#define CONTROLLER_SMB6000		4
#define CONTROLLER_SMB200		5
#define CONTROLLER_SMB600		6
##############################################################
puts -nonewline "	Controller is "
set controller_type [ETGetController]
        switch $controller_type {
                0 {puts "an unknown controller type" }
                1 {puts "an ET1000 controller"}
                2 {puts "an SMB1000 controller"}
                3 {puts "an SMB2000 controller"}
                4 {puts "an SMB 6000 contrtoller"}
                5 {puts "an SMB 200 controller"}
                6 {puts "an SMB 600 controller" }
                default {puts "returning an unknown type code"}
         }
puts "###############################################"
puts "\n"
##################################################
# Set port mapping mode
# constants for NSSetPortMappingMode 
#define PORT_MAPPING_COMPATIBLE 0
#define PORT_MAPPING_NATIVE 1
#################################################
NSSetPortMappingMode $PORT_MAPPING_COMPATIBLE

puts "--------------------------------------------------"
puts "Checking Hub Slot Port values in COMPATIBLE mode..."
mode_limits

puts "--------------------------------------------------"

if { $product_family != 3} {
   puts "Native mode operation is not available on this chassis type"
} else {
   NSSetPortMappingMode $PORT_MAPPING_NATIVE
   puts "Checking Hub Slot Port values in NATIVE mode..."
   mode_limits
}

ETUnLink



