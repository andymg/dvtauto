#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 1.9.3.py
#-----------------------------------------------------------------------------------
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

from MonitorDMIClass import WebMonitorDMIClassCase
import sys,os,time,string,socket,re

from PubModuleVitesse import PubReadConfig
#----------------------------------------import public parameters-------------------------
def ChkInputVal():
    print ("Get parameters from Configuration file")
    parameters=PubReadConfig("")
    global caseName
    caseName = sys.argv[0]
    caseName = caseName[:-3]
    global prjName
    prjName =parameters.GetParameter("DUT1","PRODUCT")
    global brserType
    brserType=parameters.GetParameter("PC","BRWSRTYPE")
    global DUTIP
    DUTIP = parameters.GetParameter("DUT1","IP")
    

def PrtInputVal():
    print "\n=========parameters============================"
    print caseName
    print "          "+prjName
    print "                       "+brserType
    print "                                    "+DUTIP
    print "=========parameters============================\n"
#----------------------------------------------------------------------------------------

def StartPerformMainPro(caseName,prjName,brserType,DUTIP):
    print "=====startPerformMainPro===="
    WebMonitorDMI = WebMonitorDMIClassCase(prjName,brserType,DUTIP)
    WebMonitorDMI.StartWebMonitorDMI(prjName)
    WebMonitorDMI.ConfigDMI()
    WebMonitorDMI.DelConf()
    WebMonitorDMI.StartWebMonitorDMI(prjName)
    WebMonitorDMI.ConfigDMI()
    WebMonitorDMI.Reboot()
    WebMonitorDMI.CheckConfig()
    WebMonitorDMI.EngineWebMonitorDMI()
    WebMonitorDMI.ReadMonitorDMI()


if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP)
    print "PASS"
