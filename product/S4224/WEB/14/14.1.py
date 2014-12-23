#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 14.1.py
#-----------------------------------------------------------------------------------
#Notes:The parameters format: python caseName.py projectName browserType IP-Address
#History:
#        06/17/2013- Olivia Hu, Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

from configClass import ConfigCase
from PubModuleVitesse import PubModuleCase
from PubModuleVitesse import PubReadConfig
import sys,os,time,string,socket,re



#-----------------------------------import public parameters--------------------------
def ChkInputVal():
    print ("Get parameters from Configuration file")
    getconfig = PubReadConfig()
    global caseName
    caseName = sys.argv[0]
    caseName = caseName[:-3]
    global prjName
    prjName = getconfig.GetParameter("DUT1","PRODUCT")
    global brserType
    brserType=getconfig.GetParameter("PC","BRWSRTYPE")
    global DUTIP
    DUTIP = getconfig.GetParameter("DUT1","IP")

def PrtInputVal():
    
    print "\n*******************Parameters********************"
    print "\nThe case name is: "+sys.argv[0]
    print "\nThe project name is: "+prjName
    print "\nThe broswer type is: "+brserType
    print "\nThe IP address is: "+DUTIP
    print "\n*******************Parameters********************"
#-------------------------------------------------------------------------------------

def startPerformMainPro(caseName,prjName,brserType,DUTIP):
    
    print "***************StartPerformMainPro***************"
    Config = ConfigCase(brserType,DUTIP)
    
    try:
        Config.startWebConfig(prjName)
	Config.engineConfigBackup()
	Config.engineConfigRestore()
	
    except:
        print "FAIL"
    Config.pubModuleEle.end()

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    startPerformMainPro(caseName,prjName,brserType,DUTIP)
    print "PASS"
    sys.exit()
