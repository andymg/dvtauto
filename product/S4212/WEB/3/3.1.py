#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 3.1.py
#-----------------------------------------------------------------------------------

from mirror import WebMirrorCase
import sys,os,time,string,socket,re
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
from PubModuleVitesse import PubReadConfig

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
    print sys.argv[0]
    print "          "+prjName
    print "                       "+brserType
    print "                                    "+DUTIP
    print "=========parameters============================\n"
#-----------------------------------------------------------------------------------
def StartPerformMainPro(caseName,prjName,brserType,DUTIP):
    print "=====startPerformMainPro===="
    webmirror = WebMirrorCase(brserType,DUTIP)
    webmirror.StartWebMirror(prjName)
    print "==========start to config the mirror port=======\n"
    configuration = webmirror.ConfigMirror()
    print "===start to factory default the mirror config===="
    webmirror.DeleteMirror()
    print "==========start to config the mirror port=======\n"
    webmirror.into_mirror_web()
    configuration = webmirror.ConfigMirror()
    print configuration
    print "======dut will reboot and check the config======"
    webmirror.CheckMirrorConfig(configuration)
    print "======factory default and close session========="
    webmirror.DeleteMirror()
    print "pass"
    webmirror.CloseSession()


if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP)
