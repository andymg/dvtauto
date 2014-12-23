#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 5.3.1.py
#-----------------------------------------------------------------------------------
#Test Item:
#
#Purpose: To verify the configuration of Static MAC Table Configuration.
#
#Steps:
#1.Start web page.
#2.Send 64 ARP packets to 192.168.3.74
#3.Check the MAC Address Table 
#
#Notes:The parameters format: python caseName.py
#History:
#        08/13/2013- Champion,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

from MacClass import WebMacCase
import sys,os,time,string,socket,re
from PubModuleVitesse import PubReadConfig

#------------------------------public access-----------------------------------------
def ChkInputVal():
    print("Get parameters from Configuration file")
    parameters = PubReadConfig("")
    global caseName
    caseName = sys.argv[:-3]
    global prjName
    prjName = parameters.GetParameter("DUT1","PRODUCT")
    global brserType
    brserType = parameters.GetParameter("PC","BRWSRTYPE")
    global DUTIP
    DUTIP = parameters.GetParameter("DUT1","IP")
    if prjName is None or brserType is None or DUTIP is None:
        sys.exit()

def PrtInputVal():
    print "\n=========parameters============================"
    print sys.argv[0]
    print "prjName      "+prjName
    print "brserType    "+brserType
    print "DUTIP        "+DUTIP
    print "=========parameters============================\n"
#-----------------------------------------------------------------------------------

def DynamicMac(caseName,prjName,brserType,DUTIP):
    print "=====startDynamicMac===="
    WebMac = WebMacCase(brserType,DUTIP)
    try:
        WebMac.StartWebMac(prjName)
        WebMac.FactoryDefault()
        WebMac.EngineMac()
        WebMac.SendMACs(DUTIP)
        WebMac.Check_MACs()
    except:
        print "FAIL"
        sys.exit(5)
    WebMac.PubModuleEle.end()

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    DynamicMac(caseName,prjName,brserType,DUTIP)
    print "PASS"
