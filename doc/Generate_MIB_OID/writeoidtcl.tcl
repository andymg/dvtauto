#!/usr/bin/tclsh
#This script is used for generate oid maping file 
#2013-0407
#Author: Andym

set ptrfile [lindex $argv 0]
set dstfile [lindex $argv 1]

foreach arg $argv {
   puts "argv is $arg"
}
puts "Source file is $ptrfile"
puts "dst file is $dstfile"
puts "argc is $argc"

   #check the dump and ptr file is whether exist
   set is_exist [file exists $ptrfile]
   if { $is_exist != 1 } {
   puts "ptrfile is not exists"
   return 0
   }

puts "begin to grnerate new file"

set nhd [ open $dstfile "w"]

set ptrhd [open $ptrfile "r" ]
set ptr_lines [read $ptrhd]
set lines [split $ptr_lines "\n"]
#puts $ptr_lines
set linestart ""


#puts "$datalines "
foreach ptrline $lines {
	set name [ split $ptrline ]
	puts "name is $name"
	set newstr [ lindex $name 0 ]

	set p1 [ lindex [ split $newstr ":" ] 1 ]
	#puts "$p1"
	set p2 [ lindex $name 1 ]
	#puts $p2
	set num [ lindex [ split [lindex $name 2] ":" ] 1 ]
	#puts "num is $num"
    if { $num != "" } {
	    set p3 [ lindex [ split [ lindex $name 2 ] ":" ] 1 ]
	} 
    if { $num == "" } {
	    set p3 [ lindex $name 2 ]
	} 
	set p4 [ lindex $name 3]
	#Todo get ptr name 
	if {$p3 == "RowStatus"} {
	set p4 read-create
	}
	
	#add name to the line to be write to new file
	append linestart "set "
	append linestart $p1\(oid\)
	#append linestart " \[list"
	append linestart " $p2\n"
	append linestart "set $p1\(type\) "
	append linestart "$p3 \n"
	append linestart "set $p1\(access\) "
	append linestart "$p4"
	#append linestart "\]"
	#output line to file
	set linestart 
	puts $nhd "$linestart"
   set linestart ""
}

#close nhd file at last
if { $nhd != ""} { catch { close $nhd } }


