#!/usr/bin/python
#-*- coding: utf-8 -*-

#Filename: 100.4.py
#-----------------------------------------------------------------------------------
#Purpose: malformed
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


def malformed(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num):
	AttackTest = AttackCases(ipdst)
	try:
		print "Fist to Test Management Port Attack using method 1"
		arping(ipdst,iface=mgmtnic)
		send(IP(dst=ipdst,ihl=2,version=3)/ICMP(),count=num,iface=mgmtnic)
		AttackTest.ChkDutSts()
		print "Start Testing Traffic Port Attack using method 1"
		conf.route.add(host=ipdst,dev=trfcnic)
		print "forge arp packets due to using traffic to do testing"
		AttackTest.fgarp(macsrc,ipsrc,ipdst,trfcnic)
		send(IP(dst=ipdst,ihl=2,version=3)/ICMP(),count=num,iface=mgmtnic)
		conf.route.resync()
		AttackTest.ChkDutSts()
	except:
		print "FAIL"
		sys.exit()


if __name__=="__main__":
        prmts = PubReadConfig("")
	num = 100
	mgmtnic = prmts.GetParameter("PC","MGMTNIC")
        trfcnic = prmts.GetParameter("PC","TRFCNIC")
	ipsrc = "192.168.3.187"
	ipdst = prmts.GetParameter("DUT1","IP")
	macsrc = "00:27:19:9b:17:a5"
	print "=========Start Testing malformed=============="
	malformed(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num)
	print "=========malformed testing finished==========="
	print "PASS"
