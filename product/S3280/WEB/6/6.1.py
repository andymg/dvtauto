#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 22.1.py
#-----------------------------------------------------------------------------------
#Notes:The parameters format:
#History:
#        07/17/2013- Madeline Niu, Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import sys,os,time,string,socket,re,random
from ntp import ConfigCase
from PubModuleVitesse import PubReadConfig
global ntpsrv1
ntpsrv1 = "192.168.0.254"
global ntpsrv2
ntpsrv2="2001:db8:1:f101::1"
global ntpsrv3
ntpsrv3="fewAFGd"
global ntpsrv4
ntpsrv4="www.tndvt.com"
global ntpsrv5
ntpsrv5="dddddddddddddddddddd"

#---------------------------------import public parameters-----------
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


#----------------------------------------------------------------------
def StartPerformMainPro(caseName,prjName,brserType,DUTIP):
    print "=====startPerformMainPro===="
    try:
  
        Config = ConfigCase(brserType,DUTIP)
    
        Config.StartWebConfig(prjName)
        Config.engineConfigNtp(ntpsrv1,ntpsrv2,ntpsrv3,ntpsrv4,ntpsrv5)
        Config.engineConfigTime()
        Config.engineRange()
        Config.engineConfigZone()
        Config.engineConfigStart()
        Config.PubModuleEle.DutReboot()
        time.sleep(40)
        Config.engineConfigInfo()
        Config.systime()
    except:   
    
		
        print "FAIL"
    Config.PubModuleEle.end()
    

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP)
    print  "PASS"
    sys.exit()
    time.sleep(2)
		
		
