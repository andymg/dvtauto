#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 5.1.1.py
#-----------------------------------------------------------------------------------
#Test Item:
#
#Purpose: To verify the configuration of Aging Configuration.
#
#Steps:
#1.Start web page.
#2.Enable Automatic Aging, set Aging Time to be 600s, save
#3.Check whether the configuration is effective by sending an arp
#4.Set Aging Time to be 300s, save
#5.Check whether the configuration is effective by sending an arp
#6.Set Aging Time to be 20s, save
#7.Check whether the configuration is effective by sending an arp
#8.Reboot DUT.
#9.Check if the configuration can be saved or not?
#10.Disable Automatic Aging, save
#11.Check whether the configuration is effective by sending an arp
#12.Reboot DUT.
#13.Check if the configuration can be saved or not?
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
    print ("Get parameters from Configuration file")
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

def AgingConf_Check(caseName,prjName,brserType,DUTIP):
    print "=====startAgingConf_Check===="
    WebMac = WebMacCase(brserType,DUTIP)

    try:
        WebMac.StartWebMac(prjName)
        WebMac.FactoryDefault();
        WebMac.EngineMac()

        WebMac.AgingConfig(disable = "0", Agingtime = "600")
        WebMac.CheckMAC_Port(DUTIP)        
        WebMac.AgingConfig(disable = "0", Agingtime = "300")
        WebMac.CheckMAC_Port(DUTIP)
        WebMac.AgingConfig(disable = "0", Agingtime = "20")
        WebMac.CheckMAC_Port(DUTIP)
        WebMac.AgingConfig(disable = "0", Agingtime = "10")
        WebMac.CheckMAC_Port(DUTIP)      
        WebMac.Check_MAC_Config()

        WebMac.AgingConfig(disable = "1")
        WebMac.CheckMAC_Port(DUTIP)
        WebMac.AgingConfig(disable = "1")
        WebMac.CheckMAC_Port(DUTIP)
        WebMac.Check_MAC_Config()
    except:
        print "FAIL"
        sys.exit(5)
    time.sleep(5)
    WebMac.PubModuleEle.end() 

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    AgingConf_Check(caseName,prjName,brserType,DUTIP)
    print "PASS"
