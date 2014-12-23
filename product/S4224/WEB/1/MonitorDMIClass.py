#!/usr/bin/python
# -*- coding: utf-8 -*-
# Filename: monitorDMIClass.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of monitorDMI test cases
#
#
#Notes:
#History:
#        04/26/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import time,re,sys,os,httplib,base64,random

#-------------------------------import public module path---------------------------------
#general speaking,it isn't suggest to call "__file__", another way is sys.argv[0]
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname( os.path.dirname(os.path.abspath(__file__))))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#-----------------------------------------------------------------------------------------
from PubModuleVitesse import PubModuleCase
#------------------------------import selenium module-------------------------------------
from PubModuleVitesse import PubModuleCase
from selenium.webdriver.common.action_chains import ActionChains
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import TimeoutException
#----------------------------------------------------------------------------------------

class WebMonitorDMIClassCase:
        #Initialize module, include "ip address","browser type","driver object"
	def __init__(self,prjName,brserType,DUTIP):
                self.prjName = prjName.lower()
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
	def StartWebMonitorDMI(self,prjName):
                print "=====startWebMonitorDMI====="
                domain = "http://admin:@%s"%(self.DUTIPAddr)
                print domain
                self.driver.get(domain)
		print self.driver.title
		assert (self.driver.title == prjName)
		print "start web successfully!"
       
        def ClickSaveButton(self):
                if self.browserType == "firefox":
                        self.driver.find_element_by_xpath("//input[@value='Save']").send_keys(Keys.RETURN)
                if self.browserType == "chrome":
                        self.driver.find_element_by_xpath("//input[@value='Save']").click()	

	def EngineWebMonitorDMI(self):
                print "=====engineWebMonitorDMI===="
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(1)
		#ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Monitor")).perform()
		#WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Monitor")).click()
		#ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Ports")).perform()
		#WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Ports")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(" stat_dmi_detailed.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(" stat_dmi_detailed.htm")).click()
        
        def ReadMonitorDMI(self):
                print "========readMonitorDMI======"
                time.sleep(1)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                if self.prjName == 's3280':
                        index=5
                elif self.prjName == 's4224':
                        index=1
                for i in range (1,29):
                        value=str(index)
                        select=Select(self.driver.find_element_by_id("portselect"))
                        select.select_by_value(value)
                        time.sleep(1)
                        threshlod=self.driver.find_element_by_xpath("/html/body/table[2]/tbody/tr[4]/td[2]/label").text
                        print "Rx Power Intrusion Threshold of port%s is %s"%(value,threshlod)
                        index=index+1
                
                self.driver.close()

        def ConfigDMI(self):
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                self.driver.find_element_by_link_text("Configuration").click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Ports")).perform()
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Ports")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("DMI")).perform()
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("DMI")).click()
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")

                if self.prjName == 's3280':
                        index=5
                elif self.prjName == 's4224':
                        index=1
                self.config=[]
                for i in range (1,29):
                        time.sleep(1)
                        ID = str("rpit_%d"%index)
                        value=random.randint(0,65535)
                        value=str(value)
                        self.config.append(value)
                        self.driver.find_element_by_id(ID).clear()
                        self.driver.find_element_by_id(ID).send_keys(value)
                        index=index+1
                self.driver.find_element_by_xpath("/html/body/form/p/input[2]").click()
                time.sleep(1)

        def DelConf(self):
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                self.driver.find_element_by_link_text("Maintenance").click()
                time.sleep (1)
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Factory Defaults")).perform()
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Factory Defaults")).click()
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_name("factory")).perform()
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_name("factory")).click()
                temp = 1
                while True:
                        try:
                                elem = self.driver.find_element_by_xpath("/html/body/h1")
                                if elem.text == "Configuration Factory Reset Done":
                                        print "=======Factory Default successfully======\n"
                                        break
                                        raise error
                        except:
                                time.sleep(3)
                                if temp != 10:
                                        temp = temp+1
                                else:
                                        print "there is an error while factory default"
                                        break
        def Reboot(self):
                print "ready to reboot"
                time.sleep(5)
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                try:
                    re=self.PubModuleEle.DutReboot()
                except:
                    print "there is an error while reboot dut"
                    print "failed"
                    sys.exit()
                if not re:
                    print "DUT reboot failed,please check it"
                    sys.exit()

        def CheckConfig(self):
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                self.driver.find_element_by_link_text("Configuration").click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Ports")).perform()
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Ports")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("DMI")).perform()
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("DMI")).click()
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                if self.prjName == 's3280':
                        index=5
                elif self.prjName == 's4224':
                        index=1
                for i in range (0,28):
                        ID = str("rpit_%d"%index)
                        value=self.driver.find_element_by_id(ID).get_attribute('value')
                        if self.config[i] != value:
                                print "config changed after reboot,please check the dut"
                                sys.exit()
                        index=index+1
                print "configuration not changed "
                print "Pass"