# ATMData.tcl
# 
# Program retireves and displays settings and capabilities of
# an ATM card. Updated to show ATM2 card and extended capabilities
#
#################################################################

#########################################
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

set iHub 0
set iSlot 0
set iPort 0

# Reserve the cards
LIBCMD HTSlotReserve $iHub $iSlot

#################################################################
# ATM_CARD_TYPE iType1 returns card model (ie 9025, 9155, 9622 etc
#################################################################
struct_new CardType ATMCardType
LIBCMD HTGetStructure $ATM_CARD_TYPE 0 0 0 CardType 0 $iHub $iSlot $iPort
puts ""
puts "ATM Card Model $CardType(uiProductCode)"
unset CardType

################################################################
# $ATM_CARD_INFO iType1 returns the various firmware levels on the
# ATM card.
# 
# The structure of uiMainFwVersion is as follows:
# It is a 16 bit value where the MSB indicates release status:
# 	if the MSB is set (MSB=1) it is a full QA approved release
#	if the MSB is not set (MSB=0) it is an internal Beta release
#
# This is reflected by the masking of the MSB ($CardData(uiMainFwVersion) & 0x7FFF)
# and the test for the bits status [expr $CardData(uiMainFwVersion) & 0x8000]
#
# An example would be as follows:
# struct_new CardData ATMCardInfo
# HTGetStructure $ATM_CARD_INFO 0 0 0 CardData 0 $iHub $iSlot $iPort
#
# This creates a structure CardData and fills it with the FW data from the
# card at iHub iSlot iPort.  We can display the Main FW value with: 
#  	puts "$CardData(uiMainFwVersion)"
# 	Suppose the number displayed is 41873
#
#	Converting this to hex yields 0xA391 or 1010 0011 1001 0001 in binary
# 	This shows the MSB is set so this is a RELEASED version
#	As a result our test:
#	[expr $CardData(uiMainFwVersion) & 0x8000]
# 	will evaluate as TRUE since is will produce a non zero value
#
#	We do not want the Release bit when we retriev the version number so we
#	lose it by ANDing with a zero in the MSB position as in:
#	($CardData(uiMainFwVersion) & 0x7FFF)
#
#	In this example it will convert A319 to 2391 (hex) when we strip the MSB
#	or 9105 decimal.  This translates as the #9 build of the 1.05 release
#
#	Pulling off the Major Release number:
#	[expr ((($CardData(uiMainFwVersion) & 0x7FFF) / 100) % 10)]
#	& 0x7FFF masks the release bit giving 9105 decimal
#	Dividing by 100 gives 9.1 and the Modulo 10 returns 1
#
#	Pulling off the Minor Release number
#	[format "%02d" [expr ($CardData(uiMainFwVersion) & 0x7FFF) % 100 ]]
#	The AND with 0x7FFF masks the release bit for 9105
#	Modulo 100 returns 5 (9105 divided by 100 gives 91 with a remainder
#	of 5).  The format "02d" specifies a decimal display of two places with
# 	a leading zero if there is only one digit.
###########################################################################
  
struct_new CardData ATMCardInfo
LIBCMD HTGetStructure $ATM_CARD_INFO 0 0 0 CardData 0 $iHub $iSlot $iPort

puts -nonewline "Firmware Level [expr ((($CardData(uiMainFwVersion) & 0x7FFF) / 100) % 10)]"
puts -nonewline "."
puts -nonewline "[format "%02d" [expr ($CardData(uiMainFwVersion) & 0x7FFF) % 100 ]]"
puts -nonewline " - Build number [expr [expr $CardData(uiMainFwVersion) /1000 ] &0x1F]"

if [expr $CardData(uiMainFwVersion) & 0x8000] {
  puts " (Released Version)"
} else {
   puts " (Internal Version)"
}
puts "  Firmware Components"
puts "	SAR Boot FW Version [expr $CardData(uiSarBootFwVersion) /100].[format "%02d" [expr $CardData(uiSarBootFwVersion) % 100]]"
puts "	SAR Main FW Version [expr $CardData(uiSarMainFwVersion) /100].[format "%02d" [expr $CardData(uiSarMainFwVersion) % 100]]"
puts "	PCI FPGA Version [expr $CardData(uiPciFpgaVersion) /100].[format "%02d" [expr $CardData(uiPciFpgaVersion) % 100]]"
puts "	GAP FPGA Version [expr $CardData(uiGapFpgaVersion) /100].[format "%02d" [expr $CardData(uiGapFpgaVersion) % 100]]"
puts "	PCI FPGA Version [expr $CardData(uiPciFpgaVersion) /100].[format "%02d" [expr $CardData(uiPciFpgaVersion) % 100]]"
puts "	BPTRG FPGA Version [expr $CardData(uiBptrgFpgaVersion) /100].[format "%02d" [expr $CardData(uiBptrgFpgaVersion) % 100]]"

#puts "Product Code $CardData(uiProductCode)"
unset CardData

#########################################################################
# $ATM_CARD_CAPABILITIES iType1 returns the max capabilities of the
# target card.
# Max Line Rate is a long, all other are integer types, so no
# special conversions are needed.
#########################################################################
struct_new Capability ATMCardCapabilities
LIBCMD HTGetStructure $ATM_CARD_CAPABILITY 0 0 0 Capability  0 $iHub $iSlot $iPort
puts ""
puts "  Card Capabilities"
puts "	Maximum Line Rate is $Capability(ulLineCellRate) cells/second"
puts "	Maximum streams possible is $Capability(uiMaxStream)"
puts "	Maximum connections is $Capability(uiMaxConnection)"
puts "	Maximum number of SVCs is $Capability(uiMaxCalls)"
puts "	Maximum number of LANE Clients is $Capability(uiMaxLaneClients)"
puts "	Max VPI Bits is $Capability(uiMaxVPIBits)"
puts "	Max VCI Bits is $Capability(uiMaxVCIBits)"
puts ""

   # Supported Features are indicated by bitfields in the uiSupportedFeatures Control Word
   # from atmitems.h
   #
   #	define ATM_FEATURES_GLOBAL_TRIGGERS		0x0000
   #	define ATM_FEATURES_PER_CONN_TRIGGERS		0x0001
   #	/* Specific to determining whether Burst Count/connection is supported */
   #	define ATM_FEATURES_PER_CONN_BURST		0x0002
   #	/* Specific to determining whether Burst Count/port is supported */
   #	define ATM_FEATURES_PER_PORT_BURST		0x0004
set FEATURES $Capability(uiSupportedFeatures)
puts "Supported Features [format %X $FEATURES]"
	if { ($ATM_FEATURES_PER_CONN_TRIGGERS & $FEATURES) > 0} {
		puts "	ATM2 Type card"
		puts "	Supports Per Stream Triggers"
        } else {
 		puts "	ATM1 Type card"
		puts "	Global Triggers Only"
        }

	if { ($ATM_FEATURES_PER_CONN_BURST & $FEATURES) > 0} {
		puts "	Supports Burst Mode"
        } else {
 		puts "	Does not support Burst Mode"
        }
unset Capability


#UnLink from the chassis
LIBCMD NSUnLink
