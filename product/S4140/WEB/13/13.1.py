#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 13.1.py
#-----------------------------------------------------------------------------------
#Test Item:
#
#Purpose: 
#
#Steps:
#1.
#2.
#3.
#4.
#5.
#6.
#7.
#
#Notes:The parameters format: python caseName.py projectName browserType IP-Address
#History:
#        04/26/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

from SoftUploadClass import SoftUploadCase
import sys,os,time,string,socket,re

global firmwarepath
#firmwarepath = 

#-----------------------------------import public parameters--------------------------
def ChkInputVal():
    print ("The parameter number you input is %d.")%len(sys.argv)
    if len(sys.argv) != 4:
        print "The number you input is not correct!"
        sys.exit()
    global caseName
    caseName = sys.argv[0]
    caseName = caseName[:-3]
    global prjName
    prjName = sys.argv[1]
    global brserType
    brserType=sys.argv[2]
    print ("The broswer type you input is %s.")%brserType
    global DUTIP
    DUTIP = sys.argv[3]
    print ('The ip address you input is %s.')%DUTIP

def PrtInputVal():
    print "\n=========parameters============================"
    print sys.argv[0]
    print "          "+sys.argv[1]
    print "                       "+sys.argv[2]
    print "                                    "+sys.argv[3]
    print "=========parameters============================\n"
#-------------------------------------------------------------------------------------

def StartPerformMainPro(caseName,prjname,brserType,DUTIP):
    print "=====startPerformMainPro===="
    SoftUpload = SoftUploadCase(brserType,DUTIP)
    global m
    m=0
    try:
        SoftUpload.StartWebSoftUpload(prjName)
        SoftUpload.EngineSoftUpload()
        m=SoftUpload.SoftwareUpload(prjName)
    except:
        print "FAIL"
        sys.exit(5)
        softUpload.PubModuleEle.end()
    if m>3:
        print "FAIL"
        sys.exit(5)
        softUpload.PubModuleEle.end()

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP)
    print "PASS"
