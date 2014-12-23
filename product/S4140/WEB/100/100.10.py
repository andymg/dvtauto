#!/usr/bin/python
#-*-  coding: utf-8 -*-

#Filename 100.10.py
#-----------------------------------------------------------------------------------
#Purpose: ntpfuzz
#
#
#Notes:
#History:
#        06/25/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

from attack import *
from scapy.all import *
from PubModuleVitesse import PubReadConfig


def ntpfuzz(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num):
	#when loop=1, it will send all ntp status
	AttackTest = AttackCases(ipdst)
	try:
		print "First to Test Management Port Attack"
		send(IP(dst=ipdst)/fuzz(UDP()/NTP(version=4)),loop=1,iface=mgmtnic)
		AttackTest.ChkDutSts()
		print "Start Testing Traffic Port Attack"
		print "It's better to use Management Port to do this feature testing,now I comment out it"
		#conf.route.add(host=ipdst,dev=trfcnic)
		#print "forge arp packets in order to use traffic port"
		#AttackTest.fgarp(macsrc,ipsrc,ipdst,trfcnic)
		#send(IP(dst=ipdst)/fuzz(UDP()/NTP(version=4)),loop=1,iface=trfcnic)
		#conf.route.resync()
		#AttackTest.ChkDutSts()
	except:
		print "FAIL"
		sys.exit()


if __name__=="__main__":
        prmts = PubReadConfig("")
	num = 2
	mgmtnic = prmts.GetParameter("PC","MGMTNIC")
        trfcnic = prmts.GetParameter("PC","TRFCNIC")
	ipsrc = "192.168.3.187"
	ipdst = prmts.GetParameter("DUT1","IP")
	macsrc = "00:27:19:9b:17:a5"
	print "==========Start Testing ntpfuzz============"
	ntpfuzz(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num)
	print "==========ntpfuzz testing finished==========="
	print "PASS"
