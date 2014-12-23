# Copyright (c) 2007 by Spirent Communications, Inc.
# All Rights Reserved
#
# By accessing or executing this software, you agree to be bound 
# by the terms of this agreement.
# 
# Redistribution and use of this software in source and binary forms,
# with or without modification, are permitted provided that the 
# following conditions are met:
#   1.  Redistribution of source code must contain the above copyright 
#       notice, this list of conditions, and the following disclaimer.
#   2.  Redistribution in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer
#       in the documentation and/or other materials provided with the
#       distribution.
#   3.  Neither the name Spirent Communications nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# This software is provided by the copyright holders and contributors 
# [as is] and any express or implied warranties, including, but not 
# limited to, the implied warranties of merchantability and fitness for
# a particular purpose are disclaimed.  In no event shall Spirent
# Communications, Inc. or its contributors be liable for any direct, 
# indirect, incidental, special, exemplary, or consequential damages
# (including, but not limited to: procurement of substitute goods or
# services; loss of use, data, or profits; or business interruption)
# however caused and on any theory of liability, whether in contract, 
# strict liability, or tort (including negligence or otherwise) arising
# in any way out of the use of this software, even if advised of the
# possibility of such damage.

# File Name:    Change_Notification.tcl
# Description:  This script demonstrates how to use the Change Notification Event Queue
#               to receive notifications when an object's attribute value changes.
#               The main advantage of using the event queue versus polling the data model 
#               is that ALL attribute changes are recorded in the queue. Polling the data
#               model at intervals means data changes may be missed.
#               There are 2 examples, listening for a port's link status to go up/down
#               and listening for certain properties of GeneratorPortResults.

#package require SpirentTestCenter
source SpirentTestCenter.tcl

# Physical topology
set szChassisIp 10.6.2.28
set iTxSlot 1
set iTxPort 3
set iRxSlot 1
set iRxPort 4

# Configure the queue with a limit of 100 events.
# Old events will be thrown out if the queue is not serviced quickly enough.
# This limit is per object type. Set to -1 for unlimited.
stc::perform ChangeNotificationConfigure -limit 100

# Create the root project object
puts "Creating project ..."
set hProject [stc::create project]

# Create ports
puts "Creating ports ..."
set hPortTx [stc::create port -under $hProject -location //$szChassisIp/$iTxSlot/$iTxPort \
                            -useDefaultHost False ]
set hPortRx [stc::create port -under $hProject -location //$szChassisIp/$iRxSlot/$iRxPort \
                            -useDefaultHost False ]

# Enable change notification on both ports and only for the Online attribute.
stc::perform ChangeNotificationEnable -handle $hPortTx -attributes { Online }
stc::perform ChangeNotificationEnable -handle $hPortRx -attributes { Online }

# Attach ports.
puts "[clock format [clock seconds] -format %m-%d-%Y%l:%M:%S%p] Attaching Ports ..."
stc::perform attachPorts -portList [list $hPortTx $hPortRx] -autoConnect TRUE

# Apply the configuration.
puts "Apply configuration"
stc::apply

# Retrieve handles to the generator and analyzer.
set hGenerator [stc::get $hPortTx -children-Generator]
set hAnalyzer [stc::get $hPortRx -children-Analyzer]

# Create a stream block.
puts "Configuring stream block ..."
set iStreamBlockLoad 100

set hStreamBlock [stc::create streamBlock -under $hPortTx -insertSig true \
                    -frameConfig "" -frameLengthMode FIXED -maxFrameLength 1200 -FixedFrameLength 256 \
    -Load $iStreamBlockLoad -LoadUnit FRAMES_PER_SECOND]

# Add an EthernetII Protocol Data Unit (PDU).
puts "Adding headers"
stc::create ethernet:EthernetII -under $hStreamBlock -name sb1_eth -srcMac 00:00:20:00:00:00 \
                            -dstMac 00:00:00:00:00:00

# Use modifier to generate multiple streams.
puts "Creating Modifier on Stream Block ..."
set hRangeModifier [stc::create RangeModifier \
      -under $hStreamBlock \
      -ModifierMode INCR \
      -Mask "0000FFFFFFFF" \
      -StepValue "000000000001" \
      -Data "000000000000" \
      -RecycleCount 4294967295 \
      -RepeatCount 0 \
      -DataType BYTE \
      -EnableStream FALSE \
      -Offset 0 \
      -OffsetReference "sb1_eth.dstMac"]

# Display stream block information.
puts "\n\nStreamBlock information"
set lstStreamBlockInfo [stc::perform StreamBlockGetInfo -StreamBlock $hStreamBlock]

foreach {szName szValue} $lstStreamBlockInfo {
puts \t$szName\t$szValue
}
puts \n\n


# Configure generator
puts "Configuring Generator"
set hGeneratorConfig [stc::get $hGenerator -children-GeneratorConfig]

stc::config $hGeneratorConfig \
          -DurationMode SECONDS \
              -BurstSize 1 \
          -Duration 100 \
              -LoadMode FIXED \
              -FixedLoad 25 \
          -LoadUnit PERCENT_LINE_RATE \
              -SchedulingMode RATE_BASED

# Subscribe to realtime results
set hResultDataSetGeneratorPortResults [stc::subscribe -Parent $hProject \
           -ConfigType Generator \
           -resulttype GeneratorPortResults ]

# Apply configuration.
puts "Apply configuration"
stc::apply

# Proc to service the Change Notification Event Queue
proc serviceQueue {} {  

    puts "Servicing queue..."

    # Retrieve all the ChangeNotificationEvents currently in the queue.
    array set command [ stc::perform ChangeNotificationRetrieveQueue ]

    # Iterate the event handles and display each event's
    # handle of the object that was changed, timestamp, and attribute name/value pair.
    foreach hEvent $command(-EventHandles) {        
        set handle [ stc::get $hEvent -handle ]
        set timestamp [ stc::get $hEvent -timestamp ]
        set attribute [ stc::get $hEvent -attribute ]
        puts "Handle: $handle Timestamp: $timestamp Attribute name/value: $attribute"        
    }        
}

set lstGeneratorPortResults [stc::get $hResultDataSetGeneratorPortResults -ResultHandleList]
foreach hPortResult $lstGeneratorPortResults {

    # Enable change notification for each generator port result and only
    # for the TotalFrameCount and TotalBitRate attributes.
    stc::perform ChangeNotificationEnable -handle $hPortResult -attributes { TotalFrameCount TotalBitRate } 

    # All attributes can be enabled by not specifying the attribute list, like this...
    #stc::perform ChangeNotificationEnable -handle $hPortResult
}

# Start the analyzer and generator.
puts "Start Analyzer"
stc::perform AnalyzerStart -AnalyzerList $hAnalyzer
puts "Current analyzer state [stc::get $hAnalyzer -state]"

puts "Start Generator"
stc::perform GeneratorStart -GeneratorList $hGenerator
puts "Current generator state [stc::get $hGenerator -state]"

set iTransmitTime 10
puts "\nRun test for $iTransmitTime seconds ..."
for {set i 0} {$i < $iTransmitTime} {incr i} {
    # Servicing the queue every second while the test is running.
    serviceQueue    
    after 1000 
}

# Stop the analyzer and generator.
puts "Stop Generator"
stc::perform GeneratorStop -GeneratorList $hGenerator
puts "Current generator state [stc::get $hGenerator -state]"

puts "Stop Analyzer"
stc::perform AnalyzerStop -AnalyzerList $hAnalyzer
puts "Current analyzer state [stc::get $hAnalyzer -state]"

# Detach ports.
puts "[clock format [clock seconds] -format %m-%d-%Y%l:%M:%S%p] Detaching Ports ..."
stc::perform DetachPorts -portList [list $hPortTx $hPortRx]

# Disable change notification for each port.
# This command disables ALL attributes.
# To disable individual attributes, use an attribute list, like this
#stc::perform ChangeNotificationDisable -handle $hPortTx -attributes { Online }
stc::perform ChangeNotificationDisable -handle $hPortTx
stc::perform ChangeNotificationDisable -handle $hPortRx
foreach hPortResult $lstGeneratorPortResults {

    # Disable change notification for all attributes of each port result.
    stc::perform ChangeNotificationEnable -handle $hPortResult
}

# Note that disabling change notification does not clear out the event queue.
# There should be more events in the queue when serviceQueue is called again here.
serviceQueue

# This is not necessary, since retrieving the queue automatically flushes it.
# This call is just an example of how to explicitly flush the queue if needed.
stc::perform ChangeNotificationFlushQueue

# Delete configuration
puts "Deleting project"
stc::delete $hProject

