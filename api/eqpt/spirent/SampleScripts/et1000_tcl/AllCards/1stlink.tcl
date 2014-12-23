#########################################################################################
# 1stLink.tcl                                                                           #
#                                                                                       #
# This program demonstrates the required steps to connect to a SMB using COM ports.     #
#                                                                                       #
# NOTE: This script works on the following cards:                                       #
#       - All Cards                                                                     #
#                                                                                       #
#########################################################################################

# This script works with COM port connections only. For usage of Internet connections, 
# please refer to other samples in the same directory. 

#################################################################################
# - Checks that correct version of SmartLib Tcl interface is loaded.            #
# - If it is not loaded, attempt to load it.                                    #
#                                                                               #
#################################################################################

# If et1000.tcl is not loaded, attempt to locate it at the default location.
# The actual location is different on different platforms. 
if  {$tcl_platform(platform) == "windows"} {
      set libPath "../../../../tcl/tclfiles/et1000.tcl"
} else {
         set libPath "../../../../include/et1000.tcl"
}
# if "et1000.tcl" is not loaded, try to source it from the default path
if { ! [info exists __ET1000_TCL__] } {
     if {[file exists $libPath]} {
          source $libPath
} else {   
               
         #Enter the location of the "et1000.tcl" file or enter "Q" or "q" to quit
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



#Prompt the user to enter a COM port
puts "" 
puts "Please enter the COM port number you are using to connect to your SmartBits: "
puts "Enter 1, 2, 3 or 4; and press ENTER to continue: "

#Get the users input from the keyboard
gets stdin input

puts "Connecting to SMB ..."
switch $input {
	1 {set retval [ETLink $ETCOM1]}
	2 {set retval [ETLink $ETCOM2]}
	3 {set retval [ETLink $ETCOM3]}
	4 {set retval [ETLink $ETCOM4]}
	5 {set retval [ETLink $ETCOM5]}
	6 {set retval [ETLink $ETCOM6]}
	7 {set retval [ETLink $ETCOM7]}
	8 {set retval [ETLink $ETCOM8]}
	default {
		puts "Undefined COM port. Please try again. "
		exit
		}
}

after 1000
if {$retval >= 0} {
	puts "SmartBits is connected. Press ENTER to disconnect."
	gets stdin
	puts "Unlinking from COM$input ..."
	LIBCMD ETUnLink

} else {
	puts "Could not connect to SmartBits. Please check your COM port and try again."
}

puts "END."







