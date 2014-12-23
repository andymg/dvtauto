#!/usr/bin/python
# -*- coding: utf-8 -*-
# Filename: userclass.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of user test cases
#
#
#Notes:
#History:
#        04/23/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import time,re,sys,os,httplib,base64,random

#------------------------------import public module--------------------------------------
#general speaking,it isn't suggest to call "__file__", another way is sys.argv[0]
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname( os.path.dirname(os.path.abspath(__file__))))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#----------------------------------------------------------------------------------------

#------------------------------import selenium module------------------------------------
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


class WebUserCase:
        #Initialize module, will include "caseName","ProjectName","browser type","ip address","driver object"
	def __init__(self,brserType,DUTIP):
                self.PubModuleEle = PubModuleCase(DUTIP)
                print "Initializing..."
                self.browserType = brserType.lower()
                self.DUTIPAddr = DUTIP
                st = self.PubModuleEle.ConnectionServer()
                print "Connection status %d."%st
                if st != 200:
                        sys.exit()
                if self.browserType == "chrome":
                        print "Starting chrome browser..."
		        self.driver = webdriver.Chrome()
                if self.browserType == "firefox":
                        print "Starting firefox browser..."
		        self.driver = webdriver.Firefox()
		self.PubModuleEle.SetPubModuleValue(self.driver)
		self.tmp_handle = self.driver.current_window_handle
	#Starting browser... (Chrome,Firefox)
	def StartWebUser(self,prjName):
                print "=======startWebUser======="
                domain = "http://admin:@%s"%(self.DUTIPAddr)
                print domain
                self.driver.get(domain)
		print self.driver.title
		assert (self.driver.title == prjName)
		print "start web successfully!"
        #Finding the "users" table in the web
	def EngineUser(self):
                print "========engineUser========"
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Security")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Security")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Switch")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Switch")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Users")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Users")).click()
        #Because the operation way of the "submit" button is different in the different broswer, so we need distinguish to use.
        def ClickButtonType(self):
                if self.browserType == "firefox":
                        WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("addNewEntry")).send_keys(Keys.RETURN)
                if self.browserType == "chrome":
                        WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("addNewEntry")).click()
        def ClickAddUserSaveButton(self):
                if self.browserType == "firefox":
                        self.driver.find_element_by_xpath("//input[@value='Save']").send_keys(Keys.RETURN)
                if self.browserType == "chrome":
                        self.driver.find_element_by_xpath("//input[@value='Save']").click()
        #add the new users.
        def AddNewUser(self,userNum):
            time.sleep(1)
            self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
	    print '=========addNewUser======='
	    for i in range(1,userNum+1):
                    time.sleep(2)
		    prefix = 'user_'
                    usrname="%s%d"%(prefix,i)
                    print usrname
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    self.ClickButtonType()
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    time.sleep(2)
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("username")).perform()
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("username")).send_keys(usrname)
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("password1")).perform()
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("password1")).send_keys("123456")
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("password2")).perform()
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("password2")).send_keys("123456")
                    self.PubModuleEle.SetSelectElement()
                    self.ClickAddUserSaveButton()
                    time.sleep(2)
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("addNewEntry"))
        #check the default user is "admin" and the level is 15, or report errors and screenshots
        def CheckUser(self,caseName,prjName):
                print "=========checkUser========"
                time.sleep(2)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                x = self.driver.execute_script('var tluser=document.getElementById("userConfigs");return tluser.rows.length;')
                userNumerr="Existing %d users in the system!"%(x)
                print userNumerr
                if x != 1:
                        print "ERROR:Existing more than one user in the system,Please delete all except for admin!"
                        self.PubModuleEle.ScreenshotSele("/html/frameset/frameset/frame[2]",caseName,prjName)
                        re=self.PubModuleEle.DutReboot(mode='fd')
                        if not re:
                            print "factory default failed"
                            sys.exit()
                        self.StartWebUser(prjName)
                        self.EngineUser()
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")

                if x == 1:
                        adminUser = self.driver.execute_script('var tluser=document.getElementById("userConfigs");return tluser.childNodes[0].childNodes[0].childNodes[0].text;')
                        print adminUser
                        privi = self.driver.execute_script('var tluser=document.getElementById("userConfigs");return tluser.childNodes[0].childNodes[1].innerHTML;')
                        print privi
                        if adminUser != "admin" or privi != "15":
                                print "The user is not admin, or the priviledge is not 15!"
                                #tStr = str(time.strftime("%Y%m%d%H%M%S",time.localtime()))
                                #strT = "F:\\selenium\\"+tStr+".png"
                                #print strT
                                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                                self.PubModuleEle.screenshotSele("/html/frameset/frameset/frame[2]",caseName,prjName)
                                #self.driver.get_screenshot_as_file(strT)
                                self.driver.quit()
                                print "===please factory default Device===="
                                re=self.PubModuleEle.DutReboot(mode='fd')
                                if not re:
                                    print "factory default failed"
                                    sys.exit()
                                self.StartWebUser(prjName)
                                self.EngineUser()
                                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                print "=start to execute user cases="

	def AddUserHandle(self,userNum,caseName,prjName):
                print "=======addUserHandle======"
		self.driver.implicitly_wait(5)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
		self.CheckUser(caseName,prjName)            #Judge Legal
		self.AddNewUser(userNum)        #Add new user
	#delete the users that have been added.
	def DeleteUser(self,userNum):
                print '========deleteUser========'
                time.sleep(2)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                for pos in range(1,userNum+1):
                        time.sleep(2)
                        prefix = 'user_'
                        usrname="%s%d"%(prefix,pos)
                        userInfo = "The No.%d is "%pos+usrname
                        print userInfo
                        #jerry modified
                        WebDriverWait(self.driver, 30).until(lambda driver: driver.find_element_by_xpath("/html/body/table/tbody/tr[2]/td/a")).click()
                        #WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text(usrname)).click()
                        time.sleep(1)
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                        ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath("//input[@value='Delete User']")).perform()
                        WebDriverWait(self.driver, 30).until(lambda driver:driver.find_element_by_xpath("//input[@value='Delete User']")).click()
                        time.sleep(1)
                        self.driver.switch_to_alert().accept()
                        #jerry modified
                        time.sleep(1)
                        #self.PubModuleEle.location("/html/frameset/frameset/frame[2]") 
        #check the users added is existence after rebooting or not.  
        def CheckElem(self,userNum):
		time.sleep(5)
		print "========checkElem========"
		st = self.PubModuleEle.ConnectionServer()
                print "Connection status %d."%(st)
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
		self.EngineUser()
		time.sleep(2)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
		n = 0
		print "Start to check the element...\n"
		n = self.driver.execute_script('var tluser=document.getElementById("userConfigs");return tluser.rows.length;')
                n = n-1
                if n == userNum:
                        time.sleep(2)
                        print "Add users number is %d."%(n)
                        print "The element checked is existence, check successfully!"
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                        self.driver.close()
                else:
                        time.sleep(2)
                        print "n=%d"%(n)
                        print "The element checked is not existence, check failed!"
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                        self.driver.close()
        #Because the operation way of the "submit" button is different in the different broswer, so we need distinguish to use.
        def ClickDeleteUserButton(self):
                if self.browserType == "firefox":
                        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_name("warm")).send_keys(Keys.RETURN)
                if self.browserType == "chrome":
                        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_name("warm")).click()
        #Find the "Restart Device" table and reboot the system, and check when the server is normal connection. 
        def CheckRebootElement(self,userNum):
                print "======checkRebootElement====="
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Switch")).click()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Security")).click()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Maintenance")).click()
                time.sleep(1)
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Restart Device")).click()
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                self.ClickDeleteUserButton()
		n = 0
		time.sleep(2)
                while True:
                        n = n + 1
                        st = self.PubModuleEle.ConnectionServer()
                        if st == 0:
                                print "Connection status %d. Failure...  [%d]"%(st,n)
                        if st == 200:
                                print "Connection status %d. Success!  [%d]"%(st,n)
                                break
			time.sleep(5)
		if n==10:
                        print "No connection,exit after 5 seconds!"
                        time.sleep(5)
                        self.driver.close()
                print "OK,start to check element!"
                self.CheckElem(userNum)
		
