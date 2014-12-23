#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: 12.1.py
#-----------------------------------------------------------------------------------
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

from LimitControl import LimitControl
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
    global manageNic
    manageNic = parameters.GetParameter("PC","MGMTNIC")
    global dataNic
    dataNic = parameters.GetParameter("PC","TRFCNIC")
    global testport
    testport = parameters.GetParameter("TOPO","TRFCNIC")
    if prjName is None or brserType is None or DUTIP is None:
        print "Please check the parameters in file %s"%parameters.PathOfconfig()
        sys.exit()



def PrtInputVal():
    print "\n=========parameters============================"
    print sys.argv[0]
    print "          "+prjName
    print "                       "+brserType
    print "                                    "+DUTIP
    print "=========parameters============================\n"

def StartPerformMainPro(prjName,brserType,DUTIP,managenic,datanic):
	prjName=prjName
	brserType=brserType
	DUTIP=DUTIP
	managenic=managenic
	datanic=datanic
	print "=======startPerformMainPro====\n"
	limitc=LimitControl(prjName,brserType,DUTIP,managenic,datanic)
	time.sleep(1)
	print "==========start to config the LimitControl=======\n"
	limitc.StartWeb()
	time.sleep(1)
	
	limitc.WebConfig()
	time.sleep(1)
	print "===start to factory default the LimitControl config===="
	try:
		limitc.FactoryDefault()
	except:
		print "there is an error while factory default"
		print "failed"
		sys.exit()
	time.sleep(1)
	print "==========start to config the LimitControl=======\n"
	limitc.StartWeb()
	config=limitc.WebConfig().copy()
	print "==========start to restart dut ==================="
	try:
		limitc.Restart()
	except:
		print "======there is an error while reboot dut======"
		print "failed"
		sys.exit()
	print "==========start to check the configuration========"
	print config
	time.sleep(1)
	limitc.CheckConfig(config)

	print "=========start to config the SNMP================="
	limitc.SnmpConfig()
	print "===start to test the function of LimitControl====="
	
	limitc.FunctionCheck(testport)
	print "=========factory default and close============"
	try:
		limitc.FactoryDefault()
	except:
		print "there is an error while factory default"
		print "failed"
		sys.exit()
	limitc.CloseSession()
	print "Pass"



if __name__ == '__main__':
	ChkInputVal()
	PrtInputVal()
	StartPerformMainPro(prjName,brserType,DUTIP,manageNic,dataNic)


