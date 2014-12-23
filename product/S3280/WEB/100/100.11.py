#!/usr/bin/python
#-*- coding: utf-8 -*-

#Filename 100.11.py
#-----------------------------------------------------------------------------------
#Purpose: tcpfuzz
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


def tcpfuzz(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num):
	AttackTest = AttackCases(ipdst)
	try:
		print "First to Test Management Port Attack"
		send(IP(dst=ipdst)/fuzz(TCP()),count=num,iface=mgmtnic)
		AttackTest.ChkDutSts()
		print "Start Testing Traffic Port Attack"
		conf.route.add(host=ipdst,dev=trfcnic)
		print "forge arp packets in order to use traffic port"
		AttackTest.fgarp(macsrc,ipsrc,ipdst,trfcnic)
		send(IP(dst=ipdst)/fuzz(TCP()),count=num,iface=trfcnic)
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
	print "=======Start Testing tcpfuzz======="
	tcpfuzz(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num)
	print "=========tcpfuzz testing finished========="
	print "PASS"
