#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 1.10.1.py
#-----------------------------------------------------------------------------------
#
#
#Notes:
#
#History:
#        06/19/2013- Jerry Cheng,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------
import sys,os,time,string,socket,re
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
from PubModuleVitesse import PubReadConfig
from Ports import Ports

def ChkInputVal():
    print ("Get parameters from Configuration file")
    parameters=PubReadConfig("")
    global caseName
    caseName = sys.argv[0]
    caseName = caseName[:-3]
    global prjName
    prjName =parameters.GetParameter("DUT1","PRODUCT")
    global brserType
    brserType=parameters.GetParameter("DUT1","BRWSRTYPE")
    global DUTIP
    DUTIP = parameters.GetParameter("DUT1","IP")
    


def PrtInputVal():
    print "\n=========parameters============================"
    print caseName
    print "          "+prjName
    print "                       "+brserType
    print "                                    "+DUTIP
    print "=========parameters============================\n"

def StartPerformMainPro(caseName,prjName,brserType,DUTIP):
	prjName=prjName
	brserType=brserType
	DUTIP=DUTIP
	print "=======startPerformMainPro====\n"
	port = Ports(prjName,brserType,DUTIP)
	port.StartPortsWeb()
	print "==========start to config the ports=======\n"
	configuration = port.Web_Config()
	print "===start to factory default the ports config===="
	try:
		port.DelConf()
		time.sleep(30)
	except:
		print "there is an error while factory default"
		print "failed"
		sys.exit()
	print "==========start to config the ports=======\n"
	port.StartPortsWeb()
	configuration = port.Web_Config()
	print configuration
	print "======dut will reboot and check the config======"
	try:
		re=port.Reboot()
	except:
		print "there is an error while reboot dut"
		print "failed"
		sys.exit()
	if not re:
		print "DUT reboot failed,please check it"
		sys.exit()
	port.CheckConfig(configuration)
	print "======factory default and close session========="
	port.DelConf()
	print "pass"
	port.CloseSession()



if __name__ == "__main__":
	ChkInputVal()
	PrtInputVal()
	StartPerformMainPro(caseName,prjName,brserType,DUTIP)


