#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 2.2.py
#-----------------------------------------------------------------------------------
#Test Item:
#
#Purpose: To verify the configuration of Ethertype for Custom S-ports, Management Port - PortType and VLAN Port Configuration.
#
#Steps:
#1.Start web page.
#2.Configure the configuration of Ethertype for Custom S-ports, Management Port - PortType, VLAN Port Configuration and save.
#3.Restart the Switch.
#4.Check the configurtion.
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

#------------------------------import public parameters----------------------------------
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

def StartPerformMainPro(caseName,prjName,brserType,DUTIP):
    print "=====startPerformMainPro===="
    WebPorts = WebVlanPortsCase(brserType,DUTIP)
    try:
        WebPorts.StartWebVlanPorts(prjName)
        WebPorts.EnginePorts()
        WebPorts.SetPortsParameters()
        WebPorts.RebootCheckPorts()
    except:  
        WebPorts.factorydefault()
        WebPorts.PubModuleEle.end()
        print "FAIL" 
        sys.exit(1)
    WebPorts.factorydefault()
    WebPorts.PubModuleEle.end()

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP)
    print "PASS"
