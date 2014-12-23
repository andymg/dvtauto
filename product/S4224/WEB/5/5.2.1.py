#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 5.2.1.py
#-----------------------------------------------------------------------------------
#Test Item:
#
#Purpose: To verify the configuration of MAC Table Learning.
#
#Steps:
#1.Start web page.
#2.Set the status of port1...port8 randomly, save
#3.Reboot DUT.
#4.Check if the configuration can be saved or not?
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

def MacTableLearning(caseName,prjName,brserType,DUTIP):
    print "=====startMacTableLearning===="
    WebMac = WebMacCase(brserType,DUTIP)
    try:
        WebMac.StartWebMac(prjName)
        WebMac.FactoryDefault()
        WebMac.EngineMac()
        WebMac.SetMacLearning()
        WebMac.CheckMacLearning()
    except:
        print "FAIL"
        sys.exit(5)
    WebMac.PubModuleEle.end()

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    MacTableLearning(caseName,prjName,brserType,DUTIP)
    print "PASS"
