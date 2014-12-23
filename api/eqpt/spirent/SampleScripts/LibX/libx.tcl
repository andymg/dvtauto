#libx.tcl
#
# extension procedures for NetcomSystems SmartLib
#
# set_link checks and creates link via serial or ethernet
# check_link checks state of link and calls set_link if not connected
#
# set_default sets target card to defined default settings
#
# Transmission commands:
# run stop burst
#
# 10/100 -L3 control commands
# set_capture   show_capture
# set_count     show_count
# set_stream    show_stream
# set_mii 	show_mii
# check_cardlink
# check_mii 
# 
# From MISC.TCL
# LIBCMD and C2I
#
# Commands for other types of SmartCards are held in type specific
# files such as l3x.tcl for L3 commands.
#
# Command Usage:
# Most commands addressed to a particular card take a Tcl list
# as an argument.  This can be one of the defined lists such as 
# card1 card2 etc, or it can be a list if lists made up of these 
# card lists. For example:
#  	run $card1
#  will start the card in the first slot transmitting.
# Setting a group such as :
#	set group1 [list $card1 $card2 $card3 $card4]
# and then followinf with:
# 	run $group1
#  will start the four cards in group1 transmitting
# 
# Check commands that check the status of a state or a bit setting
# only work against a single card.  If a group is passsed it will
# return the status of the first card on the group.
#
# show commands can have the output redirected to an external file
# The calling function must open the file and pass in the file handle
# to the variable output.
#
# A libx namespace is created to prevent filling the main namespace
# with all the variables set in the libx routines.  Only the procedure
# names are exported.  If there is a conflict between a libx procedure
# name and a variable in the main namespace, an error will be displayed
# when the libx namespace is imported.
###############################################################

set __LIBX_TCL__ 1

# define cards as Tcl lists
set card1 [list {0 0 0}]; set card2 [list {0 1 0}]; set card3 [list {0 2 0}]
set card4 [list {0 3 0}]; set card5 [list {0 4 0}]; set card6 [list {0 5 0}]
set card7 [list {0 6 0}]; set card8 [list {0 7 0}]; set card9 [list {0 8 0}]
set card10 [list {0 9 0}]; set card11 [list {0 10 0}]; set card12 [list {0 11 0}]
set card13 [list {0 12 0}]; set card14 [list {0 13 0}]; set card15 [list {0 14 0}]
set card16 [list {0 15 0}]; set card17 [list {0 16 0}]; set card18 [list {0 17 0}]
set card19 [list {0 18 0}]; set card20 [list {0 19 0}]; set card21 [list {0 20 0}]
set card22 [list {0 21 0}]; set card23 [list {0 22 0}]; set card24 [list {0 23 0}]
set card25 [list {0 24 0}]; set card26 [list {0 25 0}]; set card27 [list {0 26 0}]
set card28 [list {0 27 0}]; set card29 [list {0 28 0}]; set card30 [list {0 29 0}]
set card31 [list {0 30 0}]; set card32 [list {0 31 0}]; set card33 [list {0 32 0}]
set card34 [list {0 33 0}]; set card35 [list {0 34 0}]; set card36 [list {0 35 0}]
set card37 [list {0 36 0}]; set card38 [list {0 37 0}]; set card39 [list {0 38 0}]
set card40 [list {0 39 0}]; set card41 [list {0 40 0}]; set card42 [list {0 41 0}]
set card43 [list {0 42 0}]; set card44 [list {0 43 0}]; set card45 [list {0 44 0}]
set card46 [list {0 45 0}]; set card47 [list {0 46 0}]; set card48 [list {0 47 0}]
set card49 [list {0 48 0}]; set card50 [list {0 49 0}]; set card51 [list {0 50 0}]
set card52 [list {0 51 0}]; set card53 [list {0 52 0}]; set card54 [list {0 53 0}]
set card55 [list {0 54 0}]; set card56 [list {0 55 0}]; set card57 [list {0 56 0}]
set card58 [list {0 57 0}]; set card59 [list {0 58 0}]; set card60 [list {0 59 0}]
###############################################################
namespace eval libx {

 namespace export run stop burst set_count show_count set_capture \
         show_capture set_link set_mii show_mii set_default \
	 check_link check_cardlink LIBCMD C2I
###############################################################

################### LIBCMD ####################################
# LIBCMD error handler (from misc.tcl)
###############################################################
proc LIBCMD {args} {
	set iResponse [uplevel $args]
	if {$iResponse < 0} {
	   puts "$args :  $iResponse"
	}
}
#################### END LIBCMD ###############################


######################## C2I ##################################
# converts uc to integer (same as ConvertUCtoI in current 
# misc.tcl
###############################################################
proc C2I {ucItem} {
	set iItem 0
	set ucMin [format %c 0x00]
	set ucMax [format %c 0xFF]

	if {$ucItem == $ucMin} {
		set iItem 0
	} elseif {$ucItem == $ucMax} {
		set iItem 255
	} else {
		scan $ucItem %c iItem
	}

	return $iItem
}
##################### END C2I #################################


##############################################################################################
##############################################################################################
# TRANSMIT PROCEDURES
#
# run issues HTRun $HTRUN command to target card
# 	ARGUMENTS HUB SLOT PORT
# Does not check or set transmission parameters
#
# stop issues HTRun $HTSTOP command to target card
# 	ARGUMENTS HUB SLOT PORT
#
# burst sets card in burst mode and sends HTRun command
# Resets to continuous mode on exit
#	ARGUMENTS HUB SLOT PORT  BURST_SIZE
################################################################
proc list2group {group} {
   HGSetGroup ""
    foreach card $group {
       set card [split $card]
       set card [string trim $card { \ { } }]
       HGAddtoGroup [lindex $card 0] [lindex $card 1] [lindex $card 2]
    }
}
##################### run #####################################
proc run {group} {

    check_link
    list2group $group
    LIBCMD HGStart
}
##################### END run #################################

#################### stop #####################################
proc stop { {group} } {

   check_link
   list2group $group
   LIBCMD HGStop
}
################ END stop #####################################

################### burst #####################################
# Resets transmit mode to continuous at end (may not be the 
# entry condition.  Checks for TmtPktRate = 0 for complettion
# to allow for long burst sizes
###############################################################
proc burst { {group} {burst_size 100} } {
   global SINGLE_BURST_MODE CONTINUOUS_PACKET_MODE HTRUN

   check_link
   list2group $group
   struct_new txcount HTCountStructure*[llength $group]

   LIBCMD HGTransmitMode $SINGLE_BURST_MODE
   LIBCMD HGBurstCount $burst_size
   LIBCMD HGRun $HTRUN
   after 1000
   LIBCMD HGGetCounters txcount
   while {$txcount(0.TmtPktRate) > 0} {
      after 200
      LIBCMD HGGetCounters txcount
   }
   LIBCMD HGTransmitMode $CONTINUOUS_PACKET_MODE   
}
################ END burst ####################################


##############################################################################################
##############################################################################################
# LINK PROCEDURES
#
# set_link Checks for readiness of systems to run Tcl SmartLin programs
# Checks that library is availble by checking that __ET1000_TCL__ variable has
# been set; checks that the library has completely loaded by testing the number
# of defined variables.  Checks the version of library installed.
# Next it checks for the current link and if one does not exist, prompts the user
# for a serial port of Ethernet IP address to link with.
#
# Does not check to see if the target chassis is Ethernet capable.
# 	ARGUMENTS NONE
#################################################################

################ set_link #####################################
proc set_link {} {

global ETCOM1 ETCOM2 ETCOM3 ETCOM4

 if { [uplevel #0 info exists __ET1000_TCL__] < 1 } {
    puts "Netcom Systems Programming Library not installed"	
    puts "You must source et1000.tcl before running SmartLib scripts"
    puts "Press Enter key to exit"
    gets stdin response
    exit
 }
 if { [string len [uplevel #0 info vars]] > 10000 } {
    set x ""
    set y ""
    ETGetLibVersion x y
    puts "$x $y installed"
 } else {
    puts "Netcom Systems Programming Library not installed correctly"
    puts "The library dlls were probably not loaded correctly"
    puts "Press Enter key to exit"
    gets stdin response
    exit
 }
 puts ""
   ############################################################
   # Check for link with SMB
   ############################################################
   if {[ETGetLinkStatus] > 0} {
      set portno [ETGetCurrentLink]
      puts "SmartBits current link is $portno"
   } else {   
   while {1} {
     puts "No current link to a SmartBits chassis"
     puts ""
     puts "Please enter COM Port number (1-4) or enter E for Ethernet link (Q to quit)"
     gets stdin portno 
     if { $portno == "Q" || $portno == "q" } {
        break
     }
   ######################################
   # If user entered E or e we ask for  #
   # and IP address and socket number   #
   # User is given choice of a default  #
   # value.				#
   # An error message is displayed if   #
   # the return value is negative.      #
   ######################################
     set IPADDRESS "10.100.13.140"
     set SOCKET 16385
     if { $portno == "E" || $portno == "e" } {
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
         break
     }  
     #################################################################
     # If the input is not E (evaluated above) or the number 1-4, we #
     # send an "invalid input" message and repeat the loop.          #
     # If the input is within 1-4 we use a switch statement to send  #
     # the correct link command.  Please note that you can not       #
     # concatenate ETCOM with $portno (as in ETLink ETCOM$portno).   #
     # Tcl will always evaluate the string as zero, which will work  #
     # if you are connected to COM1 (since $ETCOM1 is zero), but not #
     # for other COM Ports.					     #
     #################################################################
                         
     if {  $portno < 1 || $portno > 4 } {  
        puts "Invalid input $portno. Please select a COM Port from 1 to 4 or E for Ethernet"
     } else {                            
        switch $portno  {     
           1  { set iResp [ETLink $ETCOM1] }      
           2  { set iResp [ETLink $ETCOM2] }      
           3  { set iResp [ETLink $ETCOM3] }
           4  { set iResp [ETLink $ETCOM4] }
	   default {puts "Input filter failed"}
        }                     
           
	   ###############################################
           # iResp greater than zero means link succeeded#
           ###############################################
           if {$iResp > 0} {                      
             set speed [ETGetBaud]                
             puts "SmartBits connected on COM Port $portno at $speed bps"
             break 
           } else {  
             puts "Could not connect to COM $portno: Error $iResp"
             break
           }           
      }           
   }   
 }  


}
#################### END set_link ###########################

###############################################################
# check_link
#
# Checks for link
# If chassis is not linked, set_link procedure is run.
###############################################################
proc check_link {} {
   if {[ETGetLinkStatus] < 0} {
      puts "SmartBits chassis is not linked"
      set_link
   }
}
###############################################################



##############################################################################################
##############################################################################################
# COUNT PROCEDURES
#
# set_count clears counter data on target card with HTClearPort
# 	ARGUMENTS HUB SLOT PORT
#
# show_count displays the standard (HTCountStructure) data
#	ARGUMENTS HUB SLOT PORT
#############################################################

####################### set_count ###########################
proc set_count { {group} } {
   check_link
   list2group $group
   HGClearPort
}
#####################END set_count ##########################

#################### show_count #############################
proc show_count { {group} {output stdout} } {

  check_link
  list2group $group
  struct_new cs HTCountStructure*[expr [llength $group] +1]
  after 100
  LIBCMD HGGetCounters cs
  for {set i 0} {$i < [llength $group]} {incr i} {
     puts $output "======================================================="
     puts $output "	 	   Counter Data Card [expr [lindex [split [lindex $group $i]] 1] +1]                |"
     puts $output "======================================================="
     puts $output "    	   Events (Total)    |     Rates (Per Second) |"
     puts $output "======================================================="
     puts $output "Tx Packets 	[format "%12d" $cs($i.TmtPkt)] | 		 [format "%12d" $cs($i.TmtPktRate)] |"
     puts $output "Rx Packets 	[format "%12d" $cs($i.RcvPkt)] | 		 [format "%12d" $cs($i.RcvPktRate)] |"
     puts $output "-------------------------------------------------------"
     puts $output "Recvd Trigger	[format "%12d" $cs($i.RcvTrig)] | 		 [format "%12d" $cs($i.RcvTrigRate)] |"
     puts $output "Collisions	[format "%12d" $cs($i.Collision)] | 		 [format "%12d" $cs($i.CollisionRate)] |"
     puts $output "-------------------------------------------------------"
     puts $output "CRC Errors	[format "%12d" $cs($i.CRC)] | 		 [format "%12d" $cs($i.CRCRate)] |"
     puts $output "Align Errors	[format "%12d" $cs($i.Align)] | 		 [format "%12d" $cs($i.AlignRate)] |"
     puts $output "-------------------------------------------------------"
     puts $output "Oversize	[format "%12d" $cs($i.Oversize)] | 		 [format "%12d" $cs($i.OversizeRate)] |"
     puts $output "Undersize	[format "%12d" $cs($i.Undersize)] | 		 [format "%12d" $cs($i.UndersizeRate)] |"
     puts $output "-------------------------------------------------------"

     if {$output == "stdout"} {
        puts "\nPress ENTER to continue"
        gets stdin response
     }
  }
}
################# END show_count ##########################


##############################################################################################
##############################################################################################
# STATUS PROCEDURES
# Checks current status on target card
##############################################################################################

################# check_cardlink ##########################
# checks link status of target card
# returns 1 if the card is linked, -1 if it isn't
# Only works on a single card.  If a list of cards is passed
# in it will only return the status of the first card in the
# list.
# Returns 1 if card is linked, -1 if it is not linked -2 if
# card is not supported.
###########################################################
proc check_cardlink { {group} } {

global FAST7410_STATUS_LINK
check_link 
set H [lindex [split [lindex $group 0] ] 0]
set S [lindex [split [lindex $group 0] ] 1]
set P [lindex [split [lindex $group 0] ] 2]

        set cardname ""
        LIBCMD HTGetCardModel cardname $H $S $P
        switch $cardname {
	   SX-7205 -
	   SX-7210 -
	   SX-7405 -
	   SX-7410 -
	   ML-7710 {
		     set stat ""
		     LIBCMD HTGetEnhancedStatus stat $H $S $P
		     if { $stat & $FAST7410_STATUS_LINK } {
			 set ret_val 1
		     } else {
			 set ret_val -1
		     }
		   }
	   default {
		    puts "$cardname card not supported by check_cardlink proc"
		    set ret_val -2
		    }
	}
	return $ret_val
  }

################# END check_cardlink ##########################



##############################################################################################
# CAPTURE PROCEDURES
#
# set_capture sets capture on the target card
# 	ARGUMENTS HUB SLOT PORT
#
# show_capture displays the data captured
#	ARGUMENTS HUB SLOT PORT NUMBER
##############################################################################################

################ set_capture ##############################
# stops and restarts capture on target card
# capture capable 10/100 only
###########################################################

proc set_capture { {group} }  {

global FST_CAPTURE_PARAMS L3_CAPTURE_OFF_TYPE L3_CAPTURE_ALL_TYPE GIG_STRUC_CAPTURE_SETUP

check_link
foreach card $group {
   set card [split $card]
   set card [string trim $card { \ { } }]
   set H [lindex $card 0]
   set S [lindex $card 1]
   set P [lindex $card 2]

   set cardname ""
   LIBCMD HTGetCardModel cardname $H $S $P
      switch $cardname {
	   LAN-6100A/3100A -
	   SX-7210 -
	   SX-7410  {
		   struct_new CapParams FSTCaptureParams
		   set CapParams(ucCRCErrors)   [format %c 0]
		   set CapParams(ucOnTrigger)   [format %c 0]
		   set CapParams(ucFilterMode)  [format %c 0]
		   set CapParams(ucStartStopOnConditionXMode) [format %c 0]
		   set CapParams(uc64BytesOnly) [format %c 0]
		   set CapParams(ucLast64Bytes) [format %c 0]
		   set CapParams(ucCollisions)  [format %c 0]
		   set CapParams(ucStartStop)   [format %c 1]
		   LIBCMD HTSetStructure $FST_CAPTURE_PARAMS 0 0 0 CapParams 0 $H $S $P
		   unset CapParams
	   }
	   POS-6500A/3500A -
	   POS-6502A/3502A -
	   LAN-6101A/3101A -
	   LAN-6201B/3201B -
	   L3-6710 -
	   ML-5710A - 
	   ML-7710  {
		   LIBCMD HTSetCommand $L3_CAPTURE_OFF_TYPE 0 0 0 "" $H $S $P
		   LIBCMD HTSetCommand $L3_CAPTURE_ALL_TYPE 0 0 0 "" $H $S $P
	   }
	   GX-1405 -
	   GX-1420B -
	   LAN-6200A/3200A
		    {
		   struct_new CapSetup GIGCaptureSetup
		   set CapSetup(ucCRCErrors)       [format %c 0]
		   set CapSetup(ucRxTrigger)       [format %c 0]
		   set CapSetup(ucTxTrigger)       [format %c 0]
		   set CapSetup(ucRCErrors)        [format %c 0]
		   set CapSetup(ucFilterMode)      [format %c 0]
		   set CapSetup(ucStartStopOnConditionMode)        [format %c 0]
		   set CapSetup(uc64BytesOnly)     [format %c 0]
		   set CapSetup(ucLast64Bytes)     [format %c 0]
		   set CapSetup(ucStartStop)       [format %c 1]
		   LIBCMD HTSetStructure $GIG_STRUC_CAPTURE_SETUP 0 0 0 CapSetup 0 $H $S $P
		   unset CapSetup
	   }
	   default  {
		   puts "$cardname card not supported by set_capture proc"
		     }
     }

   }
}
############### END set_capture ###########################

############### show_capture ##############################
# displays capture data on target card - for Ethernet
# cards only.
#
# Uses foreach to process each card in group 
# lindex split offs the hub slot and port.
#
#  The switch command selects the command set appropriate 
# to the particular target card.  The structures are unset
# after each card capture is displayed. 
###########################################################

proc show_capture { {group} {CAP_COUNT 5} {output stdout} } {

global FST_CAPTURE_PARAMS FST_CAPTURE_DATA_INFO FST_CAPTURE_COUNT_INFO FST_CAPTURE_INFO\
       L3_CAPTURE_PACKET_DATA_INFO L3_CAPTURE_COUNT_INFO \
       GIG_STRUC_CAPTURE_SETUP GIG_STRUC_CAP_COUNT_INFO GIG_STRUC_CAP_INFO \
       GIG_STRUC_CAP_INFO GIG_STRUC_CAP_DATA_INFO

check_link

foreach card $group {
   set card [split $card]
   set card [string trim $card { \ { } }]
   set H [lindex $card 0]
   set S [lindex $card 1]
   set P [lindex $card 2]

   set cardname ""
   LIBCMD HTGetCardModel cardname $H $S $P

      switch $cardname {
	   LAN-6100A/3100A -
	   SX-7210 -
	   SX-7410  {
		    struct_new CapParams FSTCaptureParams
		    set CapParams(ucStartStop)   [format %c 0]
		    LIBCMD HTSetStructure $FST_CAPTURE_PARAMS 0 0 0 CapParams 0 $H $S $P
		    unset CapParams
		    struct_new CapCount FSTCaptureCountInfo
		    LIBCMD HTGetStructure $FST_CAPTURE_COUNT_INFO 0 0 0 CapCount 0 $H $S $P
		    if {$CapCount(ulCaptureCount) < 1} {
         		   puts $output "No packets captured on card [expr $S + 1]"
		    } else {
		           if {$CapCount(ulCaptureCount) < $CAP_COUNT} {
     		              set CAP_COUNT $CapCount(ulCaptureCount)
                           }
		 	   puts $output "Displaying $CAP_COUNT packets of $CapCount(ulCaptureCount) captured on card [expr $S + 1]"
			   struct_new CapInfo FSTCaptureInfo
			   LIBCMD HTGetStructure $FST_CAPTURE_INFO 0 $CAP_COUNT 0 CapInfo 0 $H $S $P
		 	   struct_new CapData FSTCaptureDataInfo
		   	      for {set i 0} {$i < $CAP_COUNT} {incr i} {
        	      		   set CapData(ulFrameNum) $i                   
        	      		   LIBCMD HTGetStructure $FST_CAPTURE_DATA_INFO 0 0 0 CapData 0 $H $S $P
        	      		   puts $output ""                                       
        	      		   puts $output "---------"
        	      		   puts $output "FRAME $i"
        	      		   puts $output "---------"
        	         	      for {set j 0} {$j < $CapInfo(FrameInfo.$i.uiLength)} {incr j} {
                           		   if {[expr $j % 16] == 0} {                                              
		               		   puts $output ""                                   
                               		   puts -nonewline $output [format "%4i:   " $j]   
                           	           }
                         	      set iData  [C2I $CapData(ucData.$j.uc) ]                              
                         	      puts -nonewline $output " [format "%02X" $iData]"          
                                      }
         	  		   puts $output "\n" 
   				   if {$output == "stdout"} {
        	  		   puts "Press ENTER key to continue, Q to quit"
        	  		   gets stdin response
				      if {$response == "Q" || $response == "q"} {
			   	        break
				      }
				   }
			     }
         	     }
		   }

	   POS-6500A/3500A -
	   POS-6502A/3502A -
	   LAN-6101A/3101A -
	   LAN-6201B/3201B -		
	   L3-6710 -
	   ML-5710A -  
	   ML-7710 {
		    struct_new CapCount Layer3CaptureCountInfo
		    LIBCMD HTGetStructure $L3_CAPTURE_COUNT_INFO 0 0 0 CapCount 0 $H $S $P
		      if {$CapCount(ulCount) < 1} {
         		   puts $output "No packets captured on card [expr $S + 1]"
		      } else {
		           if {$CapCount(ulCount) < $CAP_COUNT} {
     		             set CAP_COUNT $CapCount(ulCount)
                           }
		           puts $output "Displaying $CAP_COUNT packets of $CapCount(ulCount) captured on card [expr $S + 1]"
		           struct_new CapData Layer3CaptureData
		           for {set i 0} {$i < $CAP_COUNT} {incr i} {
         	              LIBCMD HTGetStructure $L3_CAPTURE_PACKET_DATA_INFO $i 0 0 CapData 0 $H $S $P
        	      	      puts $output ""   
        	      	      puts $output "---------"
        	      	      puts $output "FRAME $i"
        	      	      puts $output "---------"
         	              for {set j 0} {$j < $CapData(uiLength)} {incr j} {
                  	        if {[expr $j % 16] == 0} {
                                   puts $output ""
                                   puts -nonewline $output [format "%4i:   " $j]
                  	        }
		              set iData  [C2I $CapData(cData.$j.c) ]                              
                              puts -nonewline $output " [format "%02X" $iData]"                     
         	              }
         	           puts $output "\n"
   			     if {$output == "stdout"} {
        	               puts "Press ENTER key to continue, Q to quit"
        	               gets stdin response
			          if {$response == "Q" || $response == "q"} {
			            break
			          }
			     }
         	           }
		      }
	           }

	   GX-1405 -
	   GX-1420B -
	   LAN-6200A/3200A
		    {
	            struct_new CapSetup GIGCaptureSetup
 	            set CapSetup(ucStartStop)  [format %c 0]
	            LIBCMD HTSetStructure $GIG_STRUC_CAPTURE_SETUP 0 0 0 CapSetup 0 $H $S $P
	            struct_new CapCount GIGCaptureCountInfo
	            LIBCMD HTGetStructure $GIG_STRUC_CAP_COUNT_INFO 0 0 0 CapCount 0 $H $S $P

                    if {$CapCount(ulCount) < 1} {
                       puts $output "No packets captured on card [expr $S + 1]"
	            } else {
	               if {$CapCount(ulCount) < $CAP_COUNT} {
     	                    set CAP_COUNT $CapCount(ulCount)
                       }
	               puts $output "Displaying $CAP_COUNT packets of $CapCount(ulCount) captured on card [expr $S + 1]"
                       # get information such as frame length of the captured frames
                       struct_new CapInfo GIGCaptureInfo
                       LIBCMD HTGetStructure $GIG_STRUC_CAP_INFO 0 $CAP_COUNT 0 CapInfo 0 $H $S $P
	               struct_new CapData GIGCaptureDataInfo
	               for {set i 0} {$i < $CAP_COUNT} {incr i} {
                          set CapData(ulFrame) $i
                          puts $output ""
                          puts $output "---------"
                          puts $output "FRAME $i"
                          puts -nonewline $output "---------"
                          LIBCMD HTGetStructure $GIG_STRUC_CAP_DATA_INFO 0 0 0 CapData 0 $H $S $P

                          for {set j 0} {$j < $CapInfo(FrameInfo.$i.uiLength)} {incr j} {
                               if {[expr $j % 16] == 0} {
                                    puts $output ""
                                    puts -nonewline $output [format "%4i:   " $j]
                               }
                               set iData [C2I $CapData(ucData.$j.uc)]
                               puts -nonewline $output " [format "%02X" $iData]"
                          }
                          puts $output "\n" 
   	                  if {$output == "stdout"} {
                             puts "Press ENTER key to continue, Q to quit"
                             gets stdin response
	                     if {$response == "Q" || $response == "q"} {
	                        break
	                     }
	                 }

	                }
	              }
		    }
	   default  {
		    puts "$cardname card not supported by show_capture proc"
		    }
     }
      # check that structures exist before unsetting to eliminate
      # structure does not exist messages in case of no packets captured
      if { [info exists CapCount] } {
          unset CapCount
      }
      if { [info exists CapData] } {
          unset CapData
      }
      if {[info exists CapInfo]} {
        unset CapInfo
      }
   }	 
}


################ END show_capture #########################


##############################################################################################
# Transmission Parameters
##############################################################################################




##############################################################################################
# MII Procedures
# show_mii displays the contents of the target card mii registers
# set_mii allows any register in a card or group of cards
# check_mii checks a bit position and returns 1 if it is set, -1 if not.
##############################################################################################
############### show_mii ##################################
# displays current contents of mii register 0,1,2,3,4 and 5
###########################################################
proc show_mii { {group} {output stdout} } {

  check_link
  set MAX_MII_REGISTERS 6
  set con_reg 0
  set register 0
  set address 0
  set contents 0x0000

foreach card $group {
   set card [split $card]
   set card [string trim $card { \ { } }]
   set H [lindex $card 0]
   set S [lindex $card 1]
   set P [lindex $card 2]

        set cardname ""
        LIBCMD HTGetCardModel cardname $H $S $P
        switch $cardname {
	   LAN-6100A/3100A -
	   LAN-6101A/3101A -
	   GX-1420B -
	   SX-7205 -
	   SX-7210 -
	   SX-7405 -
	   SX-7410 -
	   ML-7710 {
                    LIBCMD HTFindMIIAddress address con_reg $H $S $P
                    puts $output "***************************************************************"
                    puts $output "Reading MII Registers at Address $address on card [expr $S + 1]"
                    puts $output "***************************************************************"
                    puts $output ""
                    for {set register 0} {$register < $MAX_MII_REGISTERS} {incr register} {
                    LIBCMD HTReadMII $address $register contents $H $S $P
                    puts -nonewline $output "Register $register "
                	switch $register {
                        0 {puts -nonewline $output "[format "%-14s" Control] " }
                        1 {puts -nonewline $output "[format "%-14s" Status] "}
                        2 {puts -nonewline $output "[format "%-14s" "PHY Identifier"] "}
                        3 {puts -nonewline $output "[format "%-14s" "PHY Identifier"] "}
                        4 {puts -nonewline $output "[format "%-14s" Advertisement] "}
                        5 {puts -nonewline $output "[format "%-14s" "Link Partner"] "}
                        6 {puts -nonewline $output "[format "%-14s" Expansion] " }
                        default {puts -nonewline $output "[format "%-14s" Unknown] "}
                        }
                   puts $output "->	:  [format %04x $contents]"

                   }
                   puts $output ""
                   puts $output "***********************************************"
		   }
	   default {
		    puts "$cardname card not supported by show_mii proc"
		    }
	}
        if {$output == "stdout"} {
        puts "\nPress ENTER to continue"
        gets stdin response
        }
 }
}
############### END show_mii ###########################

############### set_mii ################################
# sets mii register to hex value of word
########################################################
proc set_mii { {group} {word 0} {register 0} } {
  
  set address 0
  set con_reg ""

  check_link
  foreach card $group {
    set card [split $card]
    set card [string trim $card { \ { } }]
    set H [lindex $card 0]
    set S [lindex $card 1]
    set P [lindex $card 2]

        set cardname ""
        LIBCMD HTGetCardModel cardname $H $S $P
        switch $cardname {
	   LAN-6100A/3100A -
	   LAN-6101A/3101A -
	   GX-1420B -
	   SX-7205 -
	   SX-7210 -
	   SX-7405 -
	   SX-7410 -
	   ML-7710 {
  		    LIBCMD HTFindMIIAddress address con_reg $H $S $P
		    after 100
  		    LIBCMD HTWriteMII $address $register $word $H $S $P
		   }
	   default {
		    puts "$cardname card not supported by set_mii proc"
		    }
	}
  }
}

################ END set_mii ###########################


############### check_mii ##############################
# checks register contents of word.  If the bit pattern
# is set in the target register the function returns 1
# If the bit pattern is not set, it returns -1
# Only works against a single card.  If a group is passed
# in it will return the status of the first card in the group
########################################################
proc check_mii { {group} {word 0x0000} {register 0} } {
  
  check_link

  set con_reg ""
  set contents ""
  set address ""

  set H [lindex [split [lindex $group 0] ] 0]
  set S [lindex [split [lindex $group 0] ] 1]
  set P [lindex [split [lindex $group 0] ] 2]

        set cardname ""
        LIBCMD HTGetCardModel cardname $H $S $P
        switch $cardname {
	   LAN-6100A/3100A -
	   SX-7205 -
	   SX-7210 -
	   SX-7405 -
	   SX-7410 -
	   ML-7710 {
  		      LIBCMD HTFindMIIAddress address con_reg $H $S $P
  		      LIBCMD HTReadMII $address register contents $H $S $P
  		      if { $contents & $word } {
     			return 1
  		      } else {
     			return -1
		      }
		   }
	   default {
		    puts "$cardname card not supported by check_mii proc"
		    }
	}
                  
}
################ END check_mii #########################



##############################################################################
####################### SET DEFAULT ##########################################
##############################################################################
# sets target card to specified default settings For 10/100 Ethernet, Gbit
# ATM cards. TR and WAN not yet implemented
##############################################################################
proc set_default { {group} }  {

 check_link

  foreach card $group {
    set card [split $card]
    set card [string trim $card { \ { } }]
    set H [lindex $card 0]
    set S [lindex $card 1]
    set P [lindex $card 2]

    set cardname ""
    LIBCMD HTGetCardModel cardname $H $S $P
    switch $cardname {
	SE-6205 -
	SC-6305 -
	ST-6405 -
	ST-6410  {puts "L2 10Mb Ethernet"
		  set_ethernet $H $S $P}
	LAN-6100A/3100A -
	SX-7205 -
	SX-7210 -
	SX-7405 -
	SX-7410  {puts "L2 FastEthernet"
		  set_fastethernet $H $S $P}
	ML-5710A -
 	L3-6705 -
	L3-6710  {puts "L3 10 Mb"
		  set_L3 $H $S $P}
	ML-7710  {puts "ML-7710 Card"
		  set_fastL3 $H $S $P}
	LAN-6200A/3200A -
	GX-1405  {puts "Gigabit Card"
		  set_gigabit $H $S $P}
	AT-9015 -
	AT-9029 -
	AT-9025 -
	AT-9034 -
	AT-9045 -
	AT-9155 -
 	AT-9155C -
	AT-9622  {puts "ATM Card"
		  set_atm $H $S $P $cardname}
	WN-3405 -
	WN-3415 -
	WN-3420  {puts "WAN Card"}
	TR-8405  {puts "Token Ring Card"}
	VG-7605  {puts "VG-AnyLAN Card"}
	
	default  {puts "Unknown card"}
   }
 }

}


   #//////////////////////////////set_ethernet////////////////////////////
	proc set_ethernet { H S P } {
	global CONTINUOUS_PACKET_MODE HALFDUPLEX_MODE
	set DATA_LENGTH 60

	#######################################################
	# Sets 60 byte packet length, minimum gap, continuous #
	# tansmission & standard backoff aggressiveness       #
	#######################################################
	LIBCMD HTDataLength $DATA_LENGTH $H $S $P
	LIBCMD HTCollisionBackoffAggressiveness 10 $H $S $P
	LIBCMD HTGap 96 $H $S $P
	LIBCMD HTTransmitMode $CONTINUOUS_PACKET_MODE $H $S $P
        LIBCMD HTDuplexMode $HALFDUPLEX_MODE  $H $S $P

	struct_new filldata Int*$DATA_LENGTH

	# Fill the packet with zeroes   #
	#################################
	for {set i 0} {$i < $DATA_LENGTH} {incr i} {
        	set filldata($i.i) 0x00
	}
	#############################################
	# Fill destination MAC with 0xFF (broadcast)#
	#############################################
	for {set i 0} {$i < 6} {incr i} {
		set filldata($i.i) 0xFF
        }
	#########################################
	# Set LSB of source MAC to card number  #
	#########################################
	set filldata(11.i) [expr $S + 1]
	HTFillPattern $DATA_LENGTH filldata $H $S $P
	unset filldata
        }
   #///////////////////////////end set_ethernet///////////////////////////

   #//////////////////////////set_fastethernet////////////////////////////
	proc set_fastethernet { H S P } {

        set_ethernet $H $S $P

	#Set speed and MII
	set Register 0
  	set Address 0
  	LIBCMD HTFindMIIAddress Address Register $H $S $P
	############################################################
	# Advertise all four modes 100 and 10 full and half duplex #
	############################################################
  	set Register 4
  	set Contents 0x01e1
  	LIBCMD HTWriteMII $Address $Register $Contents $H $S $P
	############################################################
	# Set control register to 100 full autonegotiation enabled #
	############################################################
  	set Register 0
  	set Contents 0x3100
  	LIBCMD HTWriteMII $Address $Register $Contents $H $S $P
	}
   #////////////////////////end set_fastethernet/////////////////////////

   #///////////////////////////default_L3////////////////////////////////
	proc default_L3 { H S P } {

	global L3_DEFINE_IP_STREAM
	# Delete all streams and force to L2 mode
	LIBCMD HTSetStructure $L3_DEFINE_IP_STREAM 0 0 0 "" 0 $H $S $P

	###################################################
	# Zero out L3 Stack params and disable general ARP# 
	# response and packet generation                  #
	###################################################
	struct_new L3Address Layer3Address
	set L3Address(iControl) 0x0  
	set L3Address(iPingTime) 0   
	set L3Address(iSNMPTime) 0
	set L3Address(iRIPTime) 0            
	set L3Address(iGeneralIPResponse) 0 
	HTLayer3SetAddress L3Address $H $S $P 
	unset L3Address
	}
   #//////////////////////////////end default_L3////////////////////////////

   #/////////////////////////////////set_L3/////////////////////////////////
	proc set_L3 { H S P } {
	default_L3 $H $S $P
	set_ethernet $H $S $P
	}
   #////////////////////////////////end set_L3/////////////////////////////

   #////////////////////////////////set_fastL3/////////////////////////////
	proc set_fastL3 { H S P } {
	default_L3 $H $S $P
	set_fastethernet $H $S $P
	}
   #////////////////////////////////end set_fastL3//////////////////////////

   #////////////////////////////////set_gigabit/////////////////////////////
	proc set_gigabit { H S P } {
	
	global GIG_AFN_FULL_DUPLEX GIG_VFD_OFF GIG_VFD3_OFF GIG_CONTINUOUS_MODE \
	GIG_STRUC_FILL_PATTERN GIG_STRUC_TX GIG_STRUC_AUTO_FIBER_NEGOTIATE \
	GIG_STRUC_ALT_TX
	 

	set DATA_LENGTH 60
	set ENABLE 1
	set DISABLE 0

	struct_new GigTX GIGTransmit
	set GigTX(uiMainLength) $DATA_LENGTH
	set GigTX(ucPreambleByteLength) [format %c 8]
	set GigTX(ucFramesPerCarrier)  [format %c 1]
	set GigTX(ulGap) 96
	set GigTX(ucMainRandomBackground) [format %c $DISABLE]
	set GigTX(ucBG1RandomBackground) [format %c $DISABLE]
	set GigTX(ucBG2RandomBackground) [format %c $DISABLE]
	set GigTX(ucSS1RandomBackground) [format %c $DISABLE]
	set GigTX(ucSS2RandomBackground) [format %c $DISABLE]
	set GigTX(ucMainCRCError) [format %c $DISABLE]
	set GigTX(ucBG1CRCError) [format %c $DISABLE]
	set GigTX(ucBG2CRCError) [format %c $DISABLE]
	set GigTX(ucSS1CRCError) [format %c $DISABLE]
	set GigTX(ucSS2CRCError) [format %c $DISABLE]
	set GigTX(ucJabberCount) [format %c $DISABLE]
	set GigTX(ucLoopback) [format %c $DISABLE]
	set GigTX(ulBG1Frequency) 0
	set GigTX(ulBG2Frequency) 0
	set GigTX(uiBG1Length) 0
	set GigTX(uiBG2Length) 0
	set GigTX(uiSS1Length) 0
	set GigTX(uiSS2Length) 0
	set GigTX(uiLinkConfiguration) $GIG_AFN_FULL_DUPLEX
	set GigTX(ucVFD1Mode) [format %c $GIG_VFD_OFF]
	set GigTX(ucVFD2Mode) [format %c $GIG_VFD_OFF]
	set GigTX(ucVFD3Mode) [format %c $GIG_VFD3_OFF]
	set GigTX(ucMainBG1Mode) [format %c $DISABLE]
	set GigTX(ulBurstCount) 1
	set GigTX(ulMultiburstCount) 1
	set GigTX(ulInterBurstGap) 0
	set GigTX(ucTransmitMode)  [format %c $GIG_CONTINUOUS_MODE]
	set GigTX(ucEchoMode) [format %c $DISABLE]
	set GigTX(ucPeriodicGap) [format %c 0]
	set GigTX(ucCountRcverrOrOvrsz) [format %c 0]
	set GigTX(ucGapByBitTimesOrByRate) [format %c 0]
	set GigTX(ucRandomLengthEnable) [format %c $DISABLE]
	set GigTX(uiVFD1BlockCount) 1
	set GigTX(uiVFD2BlockCount) 1
	set GigTX(uiVFD3BlockCount) 1
	LIBCMD HTSetStructure $GIG_STRUC_TX 0 0 0 GigTX 0 $H $S $P
	unset GigTX
	# Set background fill all zero
	############################################
	struct_new filldata Int*$DATA_LENGTH
	for {set i 0} {$i < $DATA_LENGTH} {incr i} {
        	set filldata($i.i) 0x00
	}
	#############################################
	# Fill destination MAC with 0xFF (broadcast)#
	#############################################
	for {set i 0} {$i < 6} {incr i} {
		set filldata($i.i) 0xFF
        }
	#########################################
	# Set LSB of source MAC to card number  #
	#########################################
	set filldata(11.i) [expr $S + 1]
	LIBCMD HTSetStructure $GIG_STRUC_FILL_PATTERN 0 0 0 filldata 0 $H $S $P
	unset filldata

	struct_new  GigAFN GIGAutoFiberNegotiate
	set GigAFN(ucMode) [format %c $DISABLE]
	set GigAFN(ucRestart) [format %c $DISABLE]
 	set GigAFN(ucEnableCCode) [format %c $DISABLE]
 	LIBCMD HTSetStructure $GIG_STRUC_AUTO_FIBER_NEGOTIATE 0 0 0 GigAFN 0 $H $S $P
	unset GigAFN

	struct_new GigAltTX GIGAltTransmit
	set GigAltTX(ucEnableSS1) [format %c $DISABLE]
	set GigAltTX(ucEnableSS2) [format %c $DISABLE]
	set GigAltTX(ucEnableBG1) [format %c $DISABLE]
	set GigAltTX(ucEnableBG2) [format %c $DISABLE]	
 	set GigAltTX(ucEnableHoldoff) [format %c $ENABLE]
 	LIBCMD HTSetStructure $GIG_STRUC_ALT_TX 0 0 0 GigAltTX 0 $H $S $P									
	unset GigAltTX

	}
   #///////////////////////////////end set_gigabit//////////////////////////

   #/////////////////////////////set_tokenring//////////////////////////////
   #/////////////////////////////end set_tokenring//////////////////////////

   #///////////////////////////////set_atm//////////////////////////////////
	proc set_atm { H S P name } {

	global ATM_CARD_CAPABILITY ATM_STREAM_CONTROL ATM_STR_ACTION_DISCONNECT \
	ATM_STR_ACTION_RESET ATM_DS 1_CELL_FRAMING ATM_INTERNAL_CLOCK ATM_CORRECT_ERRORED_CELLS \
	ATM_LOOPBACK_DISABLED ATM_DS1_0_TO_133_BUILDOUT ATM_DS1_B8ZS_ENCODING TRUE \
	ATM_DS1_ESF_LINE_FRAMING ATM_DS1_E1_LINE_PARAM ATM_E1_CELL_FRAMING ATM_E1_BUILDOUT \
	ATM_E1_HDB3_ENCODING ATM_25_FRAMING ATM_E3_CELL_FRAMING ATM_DS3_SHORT_BUILDOUT \
	ATM_OC3_FRAMING ATM_OC12_FRAMING ATM_LINE ATM_DS3_E3_LINE_PARAM

	###############################################################
	#Get Card Capabilties to derive arguments for other commands  #
	###############################################################
	struct_new CardCapabilities ATMCardCapabilities
	LIBCMD HTGetStructure $ATM_CARD_CAPABILITY 0 0 0 CardCapabilities 0 $H $S $P

	##########################
	# Disconnect all streams #
	##########################
	struct_new ATM ATMStreamControl
	set ATM(ucAction) [format %c $ATM_STR_ACTION_DISCONNECT]
	set ATM(ulStreamIndex) 0
	set ATM(ulStreamCount) $CardCapabilities(uiMaxStream)
	LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P
	##########################
	# Reset all streams      #
	##########################
	set ATM(ucAction) [format %c $ATM_STR_ACTION_RESET]
	set ATM(ulStreamIndex) 0
	set ATM(ulStreamCount) $CardCapabilities(uiMaxStream)
	LIBCMD HTSetStructure $ATM_STREAM_CONTROL 0 0 0 ATM 0 $H $S $P

	unset CardCapabilities
	unset ATM

	#######################################
	# Reset Physical interface parameters #
	# based on card type 	              #
	#######################################
	switch $name {

	AT-9015 {
		struct_new LineParams ATMDS1E1LineParams
    		set LineParams(ucFramingMode) [format %c $ATM_DS 1_CELL_FRAMING]
    		set LineParams(ucTxClockSource) [format %c $ATM_INTERNAL_CLOCK]
    		set LineParams(ucCellScrambling) [format %c $TRUE]
    		set LineParams(ucHecCoset) [format %c $TRUE]
    		set LineParams(ucRxErroredCells) [format %c $ATM_CORRECT_ERRORED_CELLS]
    		set LineParams(ucLoopBackEnable) [format %c $ATM_LOOPBACK_DISABLED]
    		set LineParams(ucLineBuildout) [format %c $ATM_DS1_0_TO_133_BUILDOUT]
    		set LineParams(ucLineCoding) [format %c $ATM_DS1_B8ZS_ENCODING]
    		set LineParams(ucLineFraming) [format %c $ATM_DS1_ESF_LINE_FRAMING]
    		for {set i 0} {$i < 4} {incr i} {
		  set LineParams(ucIdleCellHeader.$i.uc) \0
		}
		LIBCMD HTSetStructure $ATM_DS1_E1_LINE_PARAM 0 0 0 LineParams 0 $H $S $P
		unset LineParams
 		}

	AT-9020 {
		struct_new LineParams ATMDS1E1LineParams
  		set LineParams(ucFramingMode) [format %c $ATM_E1_CELL_FRAMING]
    		set LineParams(ucTxClockSource) [format %c $ATM_INTERNAL_CLOCK]
    		set LineParams(ucCellScrambling) [format %c $TRUE]
    		set LineParams(ucHecCoset) [format %c $TRUE]
    		set LineParams(ucRxErroredCells) [format %c $ATM_CORRECT_ERRORED_CELLS]
    		set LineParams(ucLoopBackEnable) [format %c $ATM_LOOPBACK_DISABLED]
    		set LineParams(ucLineBuildout) [format %c $ATM_E1_BUILDOUT]
    		set LineParams(ucLineCoding) [format %c $ATM_E1_HDB3_ENCODING]
    		set LineParams(ucLineFraming) \0
    		for {set i 0} {$i < 4} {incr i} {
		  set LineParams(ucIdleCellHeader.$i.uc) \0
		}
		LIBCMD HTSetStructure $ATM_DS1_E1_LINE_PARAM 0 0 0 LineParams 0 $H $S $P
		unset LineParams
		}

	AT-9025 {
		struct_new LineParams ATMLineParams
  		set LineParams(ucFramingMode) [format %c $ATM_25_FRAMING]
  		set LineParams(ucTxClockSource) [format %c $ATM_INTERNAL_CLOCK]
  		set LineParams(ucCellScrambling) [format %c $TRUE]
  		set LineParams(ucHecCoset) [format %c $TRUE]
  		set LineParams(ucRxErroredCells) [format %c $ATM_CORRECT_ERRORED_CELLS]
  		set LineParams(ucLoopBackEnable) [format %c $ATM_LOOPBACK_DISABLED]
  		for {set i 0} {$i < 4} {incr i} {
		  	set LineParams(ucIdleCellHeader.$i.uc) \0
		}
		LIBCMD HTSetStructure $ATM_LINE 0 0 0 LineParams 0 $H $S $P
		unset LineParams
		}

	AT-9034 {
 		struct_new LineParams ATMDS3E3LineParams
		set LineParams(ucFramingMode) [format %c $ATM_E3_CELL_FRAMING]
 		set LineParams(ucTxClockSource)  [format %c $ATM_INTERNAL_CLOCK]
 		set LineParams(ucCellScrambling) [format %c $TRUE]
 		set LineParams(ucHecCoset) [format %c $TRUE]
 		set LineParams(ucRxErroredCells) [format %c $ATM_CORRECT_ERRORED_CELLS] 
 		set LineParams(ucLoopBackEnable) [format %c $ATM_LOOPBACK_DISABLED]
 		set LineParams(ucLineBuildout) [format %c $ATM_DS3_SHORT_BUILDOUT]
 		for {set i 0} {$i < 4} {incr i} {
		  	set LineParams(ucIdleCellHeader.$i.uc) \0
		}
		LIBCMD HTSetStructure $ATM_DS3_E3_LINE_PARAM 0 0 0 LineParams 0 $H $S $P
		unset LineParams
		}

	AT-9045 {
 		struct_new LineParams ATMDS3E3LineParams
		set LineParams(ucFramingMode) [format %c $ATM_E3_CELL_FRAMING]
		set LineParams(ucTxClockSource)  [format %c $ATM_INTERNAL_CLOCK]
 		set LineParams(ucCellScrambling) [format %c $TRUE]
 		set LineParams(ucHecCoset) [format %c $TRUE]
 		set LineParams(ucRxErroredCells) [format %c $ATM_CORRECT_ERRORED_CELLS] 
		set LineParams(ucLoopBackEnable) [format %c $ATM_LOOPBACK_DISABLED]
 		set LineParams(ucLineBuildout) [format %c $ATM_DS3_SHORT_BUILDOUT]
		for {set i 0} {$i < 4} {incr i} {
		  	set LineParams(ucIdleCellHeader.$i.uc) \0
		}
		LIBCMD HTSetStructure $ATM_DS3_E3_LINE_PARAM 0 0 0 LineParams 0 $H $S $P
		unset LineParams
		}

	AT-9155C -
	AT-9155 {
		struct_new LineParams ATMLineParams
		set LineParams(ucFramingMode) [format %c $ATM_OC3_FRAMING]
		set LineParams(ucTxClockSource) [format %c $ATM_INTERNAL_CLOCK]
		set LineParams(ucCellScrambling) [format %c $TRUE]
		set LineParams(ucHecCoset) [format %c $TRUE]
		set LineParams(ucRxErroredCells) [format %c $ATM_CORRECT_ERRORED_CELLS]
		set LineParams(ucLoopbackEnable) [format %c $ATM_LOOPBACK_DISABLED]
		for {set i 0} {$i < 4} {incr i} {
		  	set LineParams(ucIdleCellHeader.$i.uc) \0
		}
		LIBCMD HTSetStructure $ATM_LINE 0 0 0 LineParams 0 $H $S $P
		unset LineParams
		}

	AT-9622 {
		struct_new LineParams ATMLineParams
		set LineParams(ucFramingMode) [format %c $ATM_OC12_FRAMING]
  		set LineParams(ucTxClockSource) [format %c $ATM_INTERNAL_CLOCK]
  		set LineParams(ucCellScrambling) [format %c $TRUE]
  		set LineParams(ucHecCoset) [format %c $TRUE]
  		set LineParams(ucRxErroredCells) [format %c $ATM_CORRECT_ERRORED_CELLS]
  		set LineParams(ucLoopBackEnable) [format %c $ATM_LOOPBACK_DISABLED]
 		for {set i 0} {$i < 4} {incr i} {
		  	set LineParams(ucIdleCellHeader.$i.uc) \0
		}
		LIBCMD HTSetStructure $ATM_LINE 0 0 0 LineParams 0 $H $S $P
		unset LineParams
		}

		default {puts "unknown ATM Card Type"} 
	}

	}


   #///////////////////////////////end set_atm//////////////////////////////

   #////////////////////////////////set_wan/////////////////////////////////
   #////////////////////////////////end set_wan/////////////////////////////


}





