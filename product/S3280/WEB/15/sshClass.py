#!/usr/bin/python
# -*- coding: utf-8 -*-
# Filename: sshClass.py
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

class SshCase:
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

	def enabledSSH(self):
                print "\n************EnabledConfigurationSSH**************\n"
                self.pubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Security")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Security")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Switch")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Switch")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("SSH")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("SSH")).click()
		self.pubModuleEle.location("/html/frameset/frameset/frame[2]")
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("ssh_mode"))
		select = Select(self.driver.find_element_by_name("ssh_mode"))
		select.select_by_value("1")
		self.clickSaveButton()
		print "\n*************SetSSHenabledFinish*****************\n"
		print "SSH try to connect to server...\n"

	def clickSaveButton(self):
                if self.browserType == "firefox":
                        self.driver.find_element_by_xpath("/html/body/form/p/input").click()
                if self.browserType == "chrome":
                        self.driver.find_element_by_xpath("/html/body/form/p/input").click()

	def disabledSSH(self):
		print "\n***********DisabledConfigurationSSH**************\n"
		self.pubModuleEle.location("/html/frameset/frameset/frame[2]")
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("ssh_mode"))
		select = Select(self.driver.find_element_by_name("ssh_mode"))
		select.select_by_value("0")
		self.clickSaveButton()
		print "\n**************SetSSHdisabledFinish***************\n"

	def checkSSHConfig(self):
                print "\n*************CheckSSHConfiguration***************"
		self.pubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
		#ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		#WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
		#ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Security")).perform()
		#WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Security")).click()
		#ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Switch")).perform()
                #WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Switch")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("SSH")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("SSH")).click()
		self.pubModuleEle.location("/html/frameset/frameset/frame[2]")
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("ssh_mode"))
		getsel = Select(self.driver.find_element_by_name("ssh_mode"))
		getval = getsel.first_selected_option.text
		print "\nCurrent SSH is %s" %getval
		if getval == "Disabled":
			print "SSH configuration has no change after reboot...\n"
		else: 
			getval == "Enabled"
			print "SSH configuration changed after reboot...\n"
		print "*************CheckConfigurationFinish************\n"
	


		
	

	





                        
	


        
