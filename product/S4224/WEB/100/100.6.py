#!/usr/bin/python
#-*- coding: utf-8 -*-

#Filename: 100.6.py
#-----------------------------------------------------------------------------------
#Purpose: ackscan
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


def ackscan(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num):
	AttackTest = AttackCases(ipdst)
	try:
		print "First to Test Management Port Attack"
		send(IP(dst=ipdst)/TCP(dport=[80,666],flags="A"),count=num,iface=mgmtnic)
		AttackTest.ChkDutSts()
		print "Start Testing Traffic Port Attack"
		conf.route.add(host=ipdst,dev=trfcnic)
		print "forge arp packets in order to use traffic port"
		AttackTest.fgarp(macsrc,ipsrc,ipdst,trfcnic)
		send(IP(dst=ipdst)/TCP(dport=[80,666],flags="A"),count=num,iface=trfcnic)
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
	print "=========Start Testing ackscan=========="
	ackscan(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num)
	print "=========ackscan testing finished============"
	print "PASS"
