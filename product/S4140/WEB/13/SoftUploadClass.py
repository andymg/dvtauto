#!/usr/bin/python
# -*- coding: utf-8 -*-
# Filename: softUploadClass.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of softupload test cases
#
#
#Notes:
#History:
#        04/26/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import time,re,sys,os,httplib,base64,random

#------------------------------import public module path---------------------------------
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#---------------------------------------------------------------------------------------

#-----------------------------import selenium module------------------------------------
from PubModuleVitesse import PubModuleCase
from selenium.webdriver.common.action_chains import ActionChains
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import TimeoutException
#---------------------------------------------------------------------------------------

class SoftUploadCase:
        #Initialize module, include "ip address","browser type","driver object"
	def __init__(self,brserType,DUTIP):
                self.PubModuleEle = PubModuleCase(DUTIP)
                print "Initializing..."
                self.browserType = brserType.lower()
                self.DUTIPAddr = DUTIP
                st = self.PubModuleEle.ConnectionServer()
                print "Connection status %d."%st
                if st != 200:
                        print "Can't connect server!"
                        sys.exit()
                else:
                        print "Connection successful!"
                if self.browserType == "chrome":
                        print "Starting chrome browser..."
		        self.driver = webdriver.Chrome()
                if self.browserType == "firefox":
                        print "Starting firefox browser..."
		        self.driver = webdriver.Firefox()
		self.PubModuleEle.SetPubModuleValue(self.driver)
		self.tmp_handle = self.driver.current_window_handle
	#Starting browser... (Chrome,Firefox)
	def StartWebSoftUpload(self,prjName):
                print "========startWebMac========"
                domain = "http://admin:@%s"%(self.DUTIPAddr)
                print domain
                self.driver.get(domain)
		print self.driver.title
		assert (self.driver.title == prjName)
		print "start web successfully!"
        def ClickUploadButton(self):
                if self.browserType == "firefox":
                        self.driver.find_element_by_xpath("//input[@value='Upload']").submit()
                if self.browserType == "chrome":
                        self.driver.find_element_by_xpath("//input[@value='Upload']").click()	
	def EngineSoftUpload(self):
                print "=======engineSoftUpload===="
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(1)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Maintenance")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Maintenance")).click()
		time.sleep(1)
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Software")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Software")).click()
		time.sleep(1)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("upload.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("upload.htm")).click()
        def close_alert_and_get_its_text(self):
                try:
                   alert = self.driver.switch_to_alert()
                   if self.accept_next_alert:
                        alert.accept()
                   else:
                        alert.dismiss()
                   return alert.text
                finally: self.accept_next_alert = True
        def SetSoftUpload(self,prjName):
                print "======setSoftUpload========"
                time.sleep(1)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("activate_now")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("activate_now")).click()
                self.driver.find_element_by_name("firmware").send_keys("./project/prjName/firmware/S3280-v1.5.3.dat")
		self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
		time.sleep(1)
                self.ClickUploadButton()
                time.sleep(1)
                self.driver.switch_to_alert().accept()
        def SearchSoftUpload(self):
                print "=======searchSoftUpload===="
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(1)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("upload.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("upload.htm")).click()
        def SoftwareUpload(self,prjName):
                print "=======softwareUpload======"
                self.SetSoftUpload(prjName)
                time.sleep(1)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                m = 1
                global progress
                progress = "Initial!"
                while True:
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                        progress = self.driver.execute_script('return document.getElementById("ticker");')
                        print "Loop %d."%m
                        judge = not progress
                        if judge != True:
                                break
                        m=m+1
                        if m>3:
                                break
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                        self.SearchSoftUpload()
                        self.SetSoftUpload(prjName)
                        time.sleep(2)
                return m
