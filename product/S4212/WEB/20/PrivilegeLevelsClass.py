#!/usr/bin/python
# -*- coding: utf-8 -*-
# Filename: PrivilegeLevelsCLass.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of bkandre(backup and restore) test cases
#
#
#Notes:
#History:
#        06/27/2013- Olivia Hu, Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import time,re,sys,os,httplib,base64,random

#------------------------------import public module path---------------------------------
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#sys.path.append(os.getcwd())
#---------------------------------------------------------------------------------------

#-----------------------------import selenium module------------------------------------
from PubModuleVitesse import PubModuleCase
import sys,os,time,string,socket,re,httplib, base64,random
from selenium.webdriver.common.action_chains import ActionChains
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import TimeoutException

from selenium.webdriver.remote.command import Command
from selenium.webdriver.remote.webdriver import WebDriver as RemoteWebDriver
from selenium.common.exceptions import WebDriverException

#---------------------------------------------------------------------------------------

class PrivilegeLevelsCase:
        #Initialize module, include "ip address","browser type","driver object"
	def __init__(self,brserType,DUTIP):
                self.pubModuleEle = PubModuleCase(DUTIP)
                print "Initializing..."
                self.browserType = brserType.lower()
                self.DUTIPAddr = DUTIP
                st = self.pubModuleEle.ConnectionServer()
                print "Connection status %d."%st
                if st != 200:
                        sys.exit()
                if self.browserType == "chrome":
                        print "Starting chrome browser..."
		        self.driver = webdriver.Chrome()
                if self.browserType == "firefox":
                        print "Starting firefox browser..."
		        self.driver = webdriver.Firefox()
		self.pubModuleEle.SetPubModuleValue(self.driver)
		self.tmp_handle = self.driver.current_window_handle
		
	#Starting browser... (Chrome,Firefox)
	def startWebConfig(self,prjName):
                print "\n*******************StartWebMac*******************"
                domain = "http://admin:@%s"%(self.DUTIPAddr)
                print domain
                self.driver.get(domain)
		print self.driver.title
		assert (self.driver.title == prjName)
		print "Start web successfully!"

	def checkPriviLevelsConfig(self,v):
                print "\n******Check Privilege Levels Configuration*******"
		self.pubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Security")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Security")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Switch")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Switch")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("priv_lvl.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("priv_lvl.htm")).click()
		self.pubModuleEle.location("/html/frameset/frameset/frame[2]")
		randomNumber = self.pubModuleEle.GetRandomNumber(0,3)
                if randomNumber == 0:
			value = "cro_"
                elif randomNumber == 1:
                        value = "crw_"
		elif randomNumber == 2:
                        value = "sro_"
                elif randomNumber == 3:
                	value = "srw_"
		print "\nStart to check the %sxxx ralated parameters..."%value
		ele = ["Aggregation", "Diagnostics", "EPS", "ERPS", "ETHER_SAT", "ETH_LINK_OAM","EVC", "IP", "IPMC_LIB",
			"IPMC_Snooping", "LACP", "LLDP", "Loop_Protect","MAC_Table", "MEP", "MVR", "Maintenance", "Mirroring",
			"PHY", "PTP", "Port_Security", "Ports", "Private_VLANs", "QoS", "SNMP", "Security", "Spanning_Tree",
			"Static_Routing", "System", "Timer", "VCL", "VLAN_Translation", "VLANs", "sFlow"]
		i = 0
		while i<len(ele):
			ele1 = "%s%s" %(value, ele[i])
			oldval = int("%d"%v)
			WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(ele1))
			getsel = Select(self.driver.find_element_by_id(ele1))
			getSetval = getsel.first_selected_option.text
			getval = int(getSetval)
			if getval == oldval:
				print "\nPASS: Current %s%s value is %d" %(value, ele[i],getval)
			else:
				print "\nFAIL: Current %s%s value is %s not %d" %(value, ele[i],getval, oldval)
			time.sleep(1)
			i = i+1
		print "\n***********Check Configuration Finish************"

	def setPriviLevel(self,v):
                print "\n************SetPrivilegeLevelConfig**************\n"
                self.pubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Security")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Security")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Switch")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Switch")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("priv_lvl.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("priv_lvl.htm")).click()
		self.pubModuleEle.location("/html/frameset/frameset/frame[2]")
		ele = ["Aggregation", "Diagnostics", "EPS", "ERPS", "ETHER_SAT", "ETH_LINK_OAM","EVC", "IP", "IPMC_LIB",
			"IPMC_Snooping", "LACP", "LLDP", "Loop_Protect","MAC_Table", "MEP", "MVR", "Maintenance", "Mirroring",
			"PHY", "PTP", "Port_Security", "Ports", "Private_VLANs", "QoS", "SNMP", "Security", "Spanning_Tree",
			"Static_Routing", "System", "Timer", "VCL", "VLAN_Translation", "VLANs", "sFlow"]	
		value = "%d"%v
		v1 = "cro_"
		v2 = "crw_"
		v3 = "sro_"
		v4 = "srw_"
		i = 0
		while i<len(ele):
			ele1 = "%s%s" %(v1, ele[i])
			ele2 = "%s%s" %(v2, ele[i])
			ele3 = "%s%s" %(v3, ele[i])
			ele4 = "%s%s" %(v4, ele[i])
			WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(ele1))
			select = Select(self.driver.find_element_by_id(ele1))
			select.select_by_value(value)
			WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(ele2))
			select = Select(self.driver.find_element_by_id(ele2))
			select.select_by_value(value)
			WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(ele3))
			select = Select(self.driver.find_element_by_id(ele3))
			select.select_by_value(value)
			WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(ele4))
			select = Select(self.driver.find_element_by_id(ele4))
			select.select_by_value(value)
			print "Set all %s value to %d\n" %(ele[i], v)
			i=i+1
			time.sleep(1)
		self.clickSaveButton()
		print "\n************SetPrivilegeLevelFinish**************\n"


	def clickSaveButton(self):
                if self.browserType == "firefox":
                        self.driver.find_element_by_xpath("/html/body/form/p/input").send_keys(Keys.RETURN)
                if self.browserType == "chrome":
                        self.driver.find_element_by_xpath("/html/body/form/p/input").click()

	
	


		
	

	





                        
	


        
