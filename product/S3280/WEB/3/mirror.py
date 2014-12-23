#!/usr/bin/python
#-*- coding: utf-8 -*-
#filename mirror.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of mirroring
#
#
#Notes:
#
#History:
#        05/28/2013- Jerry Cheng,Created
#
#Copyright(c): Transition Networks, Inc.2013


#------------------------------------------------------------------------------------
import os,sys,random,string,time

#general speaking,it isn't suggest to call "__file__", another way is sys.argv[0]
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname( os.path.dirname(os.path.abspath(__file__))))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#------------------------------import selenium module-----------------------------------
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
#------------------------------import public module path--------------------------------- 

class WebMirrorCase:
    def __init__(self,brserType="firefox",DUTIP="192.168.3.74"):
        self.PubModuleEle = PubModuleCase(DUTIP)
        print "Initializing..."
        self.browserType = brserType.lower()
        self.DUTIPAddr = DUTIP
        st = self.PubModuleEle.ConnectionServer()
        print "Connection status %d."%st
        if st != 200 :
            print "Can't connect server!"
            sys.exit()
        else:
            print "Connection successful!"
        if self.browserType == "chrome" :
            print "Starting chrome browser..."

            self.driver = webdriver.Chrome()
        if self.browserType == "firefox" :
            print "Starting firefox browser..."
            self.driver = webdriver.Firefox()

        self.PubModuleEle.SetPubModuleValue(self.driver)
        self.tmp_handle = self.driver.current_window_handle

    def StartWebMirror(self,prjName):
        print "========startWebMirror========"
        domain = "http://admin:@%s"%(self.DUTIPAddr)
        print domain
        self.driver.get(domain)
        print self.driver.title
        assert (self.driver.title == prjName)
        print "start web successfully!"
        self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
        ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Configuration")).click()
        ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mirror.htm")).perform()
        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_id("mirror.htm")).click()

    def into_mirror_web(self):
        self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
        ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mirror.htm")).perform()
        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_id("mirror.htm")).click()

    def ConfigMirror(self):
        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
        select1 = Select(self.driver.find_element_by_id("portselect"))
        index1 = random.randint(0,8)
        index1 = str(index1)
        select1.select_by_value(index1)
        mirror_conf = {'port_to_mirror' : index1}
        mirror_port = {'0':'Disabled','1':'Rx only','2':'Tx only','3':'Enabled'}
        for i in range (1,9):
            i = str(i)
            select_path = "mode_%s"%i
            select2 = Select(self.driver.find_element_by_id(select_path))
            if i == index1:
                index2 = random.randint(0,1)
            else:
                index2 = random.randint(0,3)
            index2 = str(index2)
            time.sleep(1)
            select2.select_by_value(index2)
            mirror_conf[i] = mirror_port[index2]            
        self.driver.find_element_by_xpath("/html/body/form/p/input[2]").click()
        return mirror_conf

    def DeleteMirror(self):
        self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
        self.driver.find_element_by_link_text("Maintenance").click()
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

    def CheckMirrorConfig(self,conf):
        print "=====DUT will reboot soon======="
        re=self.PubModuleEle.DutReboot()
        if re == 0:
            sys.exit()

        time.sleep(2)
        self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
        ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Configuration")).click()
        ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mirror.htm")).perform()
        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_id("mirror.htm")).click()
        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
        port_select = Select(self.driver.find_element_by_id("portselect"))
        if port_select.first_selected_option.text != conf["port_to_mirror"]:
            print "the Configuration changed after the dut reboot"
            sys.exit()
        else:
            for i in range (1,9):
                i = str(i)
                select_path = "mode_%s"%i
                select = Select(self.driver.find_element_by_id(select_path))
                if select.first_selected_option.text != conf[i]:
                    print "the Configuration changed after the dut Rboot"
                    sys.exit()
        print "===all Configuration is correct====="
    def CloseSession(self):
        self.driver.close()

    




         