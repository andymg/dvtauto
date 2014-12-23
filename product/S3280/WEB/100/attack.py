#!/usr/bin/python
# -*- coding: utf-8 -*-

# Filename: attack.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of attack class
#
#
#Notes:
#History:
#        06/19/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import os,sys
from scapy.all import *

#------------------------------------public module path-----------------------------------
#general speaking,it isn't suggest to call "__file__", another way is sys.argv[0]
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname( os.path.dirname(os.path.abspath(__file__))))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#----------------------------------------------------------------------------------------

from PubModuleVitesse import PubModuleCase

class AttackCases:
    def __init__(self,DUTIP):
        self.PubModuleEle = PubModuleCase(DUTIP)

    def ChkDutSts(self):
        st = self.PubModuleEle.ConnectionServer()
        print "Connection status %d."%st
        if st != 200:
            print "Attack result in the Target DUT doesn't work"
            sys.exit()
        else:
            print "The target DUT can work,start to the next steps"

    def fgarp(self,macsrc,ipsrc,ipdst,nic):
	send(ARP(op=2,hwsrc=macsrc,psrc=ipsrc,pdst=ipdst),iface=nic)
	
    
