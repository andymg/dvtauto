###############################################################################################################
# LibVer.tcl                                                                                                  #
#                                                                                                             #
# This program, is a simple Script to retrieve and display current library version.                           #
#                                                                                                             #
# - It demonstrates how functions that expect a stream are run in Tcl.                                        #
# - An empty string must be set up (like we do here with set lib "" ) for each string required by the command.# 
# - You do not need to be linked to get the library version.                                                  #
#                                                                                                             #              #                                                                                                             #
# NOTE: This script works on the following cards:                                                             #
#       - ALl CARDS                                                                                           #
#                                                                                                             #
###############################################################################################################


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
         
                  puts "Could not find the file '$libPath'."
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


#Set the variables
set lib ""
set ver ""

#Get the library version
ETGetLibVersion lib ver

#Print the library version
puts "This system is running $lib version $ver"
puts "DONE"

