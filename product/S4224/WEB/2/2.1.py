#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 2.1.py
#-----------------------------------------------------------------------------------
#Test Item:
#
#Purpose: To verify the configuration of VLAN Membership Configuration.
#
#Steps:
#1.Start web page.
#2.Configure the table "VLAN Membership Configuration".
#3.Add "VLAN ID", "VLAN Name", "Port Members" and save.
#4.Delete the above configuration and save.
#5.Add "VLAN ID", "VLAN Name", "Port Members" and save again.
#6.Restart the Switch.
#7.Check the configurtion.
#
#Notes:The parameters format: python caseName.py
#History:
#        09/13/2013- Champion,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

from VlanPortClass import WebVlanPortsCase
import sys,os,time,string,socket,re
from PubModuleVitesse import PubReadConfig

global crtNum
crtNum = 23

#------------------------------import public parameters---------------------------------
def ChkInputVal():
    print ("Get parameters from Configuration file")
    parameters=PubReadConfig("")
    global caseName
    caseName = sys.argv[0]
    caseName = caseName[:-3]
    global prjName
    prjName = parameters.GetParameter("DUT1","PRODUCT")
    global brserType
    brserType= parameters.GetParameter("PC","BRWSRTYPE")
    print ("The broswer type you input is %s.")%brserType
    global DUTIP
    DUTIP = parameters.GetParameter("DUT1","IP")
    print ('The ip address you input is %s.')%DUTIP
    if prjName is None or brserType is None or DUTIP is None:
        print "Please check the parameters in file %s"%parameters.PathOfConfig()
        sys.exit()

def PrtInputVal():
    print "\n=========parameters============================"
    print sys.argv[0]
    print "prjName      "+prjName
    print "brserType    "+brserType
    print "DUTIP        "+DUTIP
    print "=========parameters============================\n"
#-----------------------------------------------------------------------------------

def StartPerformMainPro(caseName,prjName,brserType,DUTIP,crtNum):
    print "=====startPerformMainPro===="
    WebVlan = WebVlanPortsCase(brserType,DUTIP)
    try:
         WebVlan.StartWebVlanPorts(prjName)
         WebVlan.EngineVlan()
         WebVlan.AddVlanHandle(crtNum)
         WebVlan.DeleteVlan(crtNum)
         WebVlan.AddVlanHandle(crtNum)
         WebVlan.CheckRebootElement(crtNum)
    except:   
        WebVlan.factorydefault()
        WebVlan.PubModuleEle.end()
        print "FAIL" 
        sys.exit(1)
    WebVlan.factorydefault()
    WebVlan.PubModuleEle.end()

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP,crtNum)
    print "PASS"
