#!/usr/bin/python
#-*- coding: utf-8 -*-

#Filename: 100.9.py
#-----------------------------------------------------------------------------------
#Purpose: icmpleak
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


def icmpleak(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num):
	#This was a Linux 2.0 bug:
	AttackTest = AttackCases(ipdst)
	try:
		print "First to Test Management Port Attack"
		send(IP(dst=ipdst,options="\x02")/ICMP(),count=num,iface=mgmtnic)
		AttackTest.ChkDutSts()
		print "Start Testing Traffic Port Attack"
		conf.route.add(host=ipdst,dev=trfcnic)
		print "forge arp packets in order to use traffic port"
		AttackTest.fgarp(macsrc,ipsrc,ipdst,trfcnic)
		send(IP(dst=ipdst,options="\x02")/ICMP(),count=num,iface=trfcnic)
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
	print "=========Start Testing icmpleak==========="
	icmpleak(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num)
	print "=========icmpleak testing finished==========="
	print "PASS"
