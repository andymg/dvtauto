#!/usr/bin/python
# -*- coding: utf-8 -*-
# Filename: configClass.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of bkandre(backup and restore) test cases
#
#
#Notes:
#History:
#        06/17/2013- Olivia Hu, Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import time,re,sys,os,httplib,base64,random

#------------------------------import public module path---------------------------------
#general speaking,it isn't suggest to call "__file__", another way is sys.argv[0]
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname( os.path.dirname(os.path.abspath(__file__))))))
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

class ConfigCase:
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
		
        def clickBackupButton(self):
                print "\nBackup in Processing...\n"
                if self.browserType == "firefox":
                        self.driver.find_element_by_xpath("/html/body/form/input").submit()
                if self.browserType == "chrome":
                        self.driver.find_element_by_xpath("/html/body/form/input").click()
                        
	def engineConfigBackup(self):
                print "\n************EngineConfigurationBackup************\n"
                self.pubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(1)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[4]/a").click() #find "Maintenance"
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[4]/div/ul/li[4]/a").click() #find "Configuration"
                time.sleep(2)
                #self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[4]/div/ul/li[4]/div/ul/li/a").click() #find "Backup Binary"
                #time.sleep(2)
		#self.pubModuleEle.location("/html/frameset/frameset/frame[2]")
                #time.sleep(1)
		#self.clickBackupButton()
		print "Technical Difficulties: can't close the popup windows...\n"
                time.sleep(5)
                print "***********ConfigurationBackupFinish*************"	

	def engineConfigRestore(self):
                print "\n************EngineConfigurationRestore***********"
                #self.pubModuleEle.location("/html/frameset/frameset/frame[1]")
                #time.sleep(1)
		#self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[4]/a").click() #find "Maintenance"
		#time.sleep(1)
		#self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[4]/div/ul/li[4]/a").click() #find "Configuration"
		#time.sleep(1)
		self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[4]/div/ul/li[4]/div/ul/li[2]/a").click() #find "Restore Binary"
                time.sleep(1)
		self.clickRestoreButton()
                time.sleep(1)
		print "***********ConfigurationRestoreFinish************\n"
		
	def clickRestoreButton(self):
                print "\nRestore in Processing..."
		self.pubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(1)
                #self.driver.find_element_by_xpath("/html/body/form/input").send_keys("D:\FirefoxDownload\S3280_v1.6.0-May21-bugfix_conf.bin") # for windows OS
                self.driver.find_element_by_xpath("/html/body/form/input").send_keys("/home/olivia/Downloads/S3280_v1.5.4_conf.bin") #(for linux OS)
                time.sleep(1)
		self.pubModuleEle.location("/html/frameset/frameset/frame[2]")
		time.sleep(1)
		self.driver.find_element_by_xpath("/html/body/form/input[2]").click()
		print "\nPlease wait for 90 seconds ...\n"
		time.sleep(90)


        
