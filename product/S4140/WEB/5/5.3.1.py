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
#2.Add VlanID, Mac Address, Port members randomly, save
#3.Delete all the configuration, save
#4.Add VlanID, Mac Address, Port members randomly, save
#5.Reboot DUT.
#6.Check if the configuration can be saved or not?
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

def MacTableConfig(caseName,prjName,brserType,DUTIP):
    print "=====startMacTableConfig===="
    WebMac = WebMacCase(brserType,DUTIP)
    try:
        WebMac.StartWebMac(prjName)
        WebMac.FactoryDefault()
        WebMac.EngineMac()
        WebMac.AddMacTable(1)
        WebMac.DeleteMacTable()
        WebMac.AddMacTable(2)
        #WebMac.PubModuleEle.DutReboot()   #Reboot the switch, then it will break down
        WebMac.Check_MacTableConfig()
    except:
        print "FAIL"
        sys.exit(5)
    WebMac.PubModuleEle.end()

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    MacTableConfig(caseName,prjName,brserType,DUTIP)
    print "PASS"
