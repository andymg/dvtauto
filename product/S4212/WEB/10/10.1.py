#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 10.1.py
#-----------------------------------------------------------------------------------
#Test Item:
#
#Purpose: To verify the configuration of user add&&delete function.
#
#Steps:
#1.Start web page.
#2.Check if there is existence some user except for "admin".
#3.add specific user
#4.delete user
#5.add specific user
#6.reboot DUT.
#7.check if the configuration can be saved or not?
#
#Notes:The parameters format: python caseName.py projectName browserType IP-Address
#History:
#        04/23/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import sys,os,time,string,socket,re
from UserClass import WebUserCase
from PubModuleVitesse import PubReadConfig
global userNum
userNum = 3

#----------------------------------public parameters---------------------------------
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
    if prjName is None or brserType is None or DUTIP is None:
        print "Please check the parameters in file %s"%parameters.PathOfconfig()
        sys.exit()
#     print ("The parameter number you input is %d.")%len(sys.argv)
#     if len(sys.argv) != 4:
#         print "The number you input is not correct!"
#         sys.exit()
#     global caseName
#     caseName = sys.argv[0]
#     caseName = caseName[:-3]
#     global prjName
#     prjName = sys.argv[1]
#     global brserType
#     brserType=sys.argv[2]
#     print ("The broswer type you input is %s.")%brserType
#     global DUTIP
#     DUTIP = sys.argv[3]
#     print ('The ip address you input is %s.')%DUTIP
def PrtInputVal():
    print "\n=========parameters============================"
    print sys.argv[0]
    print "prjName   "+prjName
    print "brserType              "+brserType
    print "DUTIP                               "+DUTIP
    print "=========parameters============================\n"
#-----------------------------------------------------------------------

def StartPerformMainPro(caseName,prjName,brserType,DUTIP,userNum):
    print "=====startPerformMainPro===="
    print ("BTW,Will Create User Number is %d.")%userNum
    WebUser = WebUserCase(brserType,DUTIP)
    
    WebUser.StartWebUser(prjName)
    WebUser.EngineUser()
    WebUser.AddUserHandle(userNum,caseName,prjName)
    WebUser.DeleteUser(userNum)
    WebUser.AddUserHandle(userNum,caseName,prjName)
    WebUser.CheckRebootElement(userNum)
    #except:
    #    print "FAIL"
    #    sys.exit(5)
    WebUser.PubModuleEle.end()

if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP,userNum)
    print  "PASS"
    sys.exit()
    time.sleep(2)
