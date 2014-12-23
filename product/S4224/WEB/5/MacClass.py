#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: macClass.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of mac address table
#
#
#Notes:
#
#History:
#        04/25/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import time,re,sys,os,httplib,base64,random,string

#------------------------------import public module path--------------------------------- 
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#---------------------------------------------------------------------------------------

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

#-------------------------------import scapy module-------------------------------------
from scapy.all import *
from scapy.sendrecv import debug, srp1
#---------------------------------------------------------------------------------------

class WebMacCase:
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
	def StartWebMac(self,prjName):
                print "\n========startWebMac========"
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

	def EngineMac(self):
                print "\n=========engineMac========="
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(3)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mac.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("mac.htm")).click()

        def SetMacLearning(self):
                print "\n======setMacLearning====="
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                global randomList
                randomList = []
                for i in range(0,8):
                        randomList.append(random.randint(1,3))
                for j in range(0,8):
                        autoId = "Learn_Auto_%d"%(j+1)
                        disableId = "Learn_Disable_%d"%(j+1)
                        secureId = "Learn_Secure_%d"%(j+1)
                        if randomList[j] == 1:
                             ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(autoId)).perform()
                             WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(autoId)).click()
                        if randomList[j] == 2:
                             ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(disableId)).perform()
                             WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(disableId)).click()
                        if randomList[j] == 3:
                             ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(secureId)).perform()
                             WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(secureId)).click()
                time.sleep(3)
                self.ClickSaveButton()
                print "SetMacLearning finished"

        def CheckMacLearning(self):
                print "\n======CheckMacLearning====="
                self.PubModuleEle.DutReboot()
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mac.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("mac.htm")).click()
                time.sleep(5)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(5)
                PortList = []
                for i in range(0,8):
                    for j in range(1,4):
                        Portxpath = "/html/body/form/table[2]/tbody/tr[%d]/td[%d]/input"%((2+j),(2+i))
                        Portstatus = str(self.driver.find_element_by_xpath(Portxpath).get_attribute("checked"))
                        if Portstatus == "true":
                            PortList.append(j)
                            break        
                for i in range(0,8):
                    if PortList[i] != randomList[i]:
                        print i
                        raise
                print "CheckMacLearning finished"

        def FactoryDefault(self):
                print "\n=====FactoryDefault====="
                self.PubModuleEle.DutReboot(mode='fd')
                print "FactoryDefault finished"

        def AgingConfig(self, disable = "0", Agingtime = "300"):
                global agingtime
                global disable_value
                print "\n=====AgingConfig====="
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mac.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("mac.htm")).click()
                time.sleep(3) 
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(3) 
                disable_value=str(self.driver.find_element_by_id("DisableAgeing").get_attribute("checked"))
                agingtime = string.atoi(self.driver.find_element_by_id("agebox").get_attribute("value"))
                time.sleep(3) 
                if disable_value == "true":
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("DisableAgeing")).perform()
		    WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("DisableAgeing")).click()
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("agebox")).perform()
		    WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("agebox")).clear()
                    WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("agebox")).send_keys("20")
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath("/html/body/form/p[2]/input[2]")).perform()
                    WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_xpath("/html/body/form/p[2]/input[2]")).click()
                    time.sleep(3)                                  
                if disable == "0":
                    agingtime = string.atoi(Agingtime)
                    disable_value = "None"
                    if 10 <= agingtime <= 1000000:
                        print "\ndisable = " + disable + " Agingtime = " + Agingtime
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                        ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("agebox")).perform()
		        WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("agebox")).clear()
                        WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("agebox")).send_keys(Agingtime)
                        ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath("/html/body/form/p[2]/input[2]")).perform()
                        WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_xpath("/html/body/form/p[2]/input[2]")).click()
                        time.sleep(3)
                    else:
                        print "out of range"
                if disable == "1":
                    disable_value = "true"
                    print "\ndisable = " + disable
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("DisableAgeing")).perform()
		    WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("DisableAgeing")).click()
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath("/html/body/form/p[2]/input[2]")).perform()
                    WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_xpath("/html/body/form/p[2]/input[2]")).click()
                    time.sleep(3)               
                print "AgingConfig finished"
                time.sleep(3)

        def CheckMAC_Port(self,dst):
                global check_web_port_xpath
                global agingtime
                global disable_value
                print "\n=========CheckMAC_Port========"
                #----------------send an ARP packet-----------------------
                random_src = "%x%x:%x%x:%x%x:%x%x:%x%x:%x%x" % (0, 0, 0, random.uniform(0,15), random.uniform(0,15), random.uniform(0,15),\
                             random.uniform(0,15), random.uniform(0,15), random.uniform(0,15), random.uniform(0,15), random.uniform(0,15),\
                             random.uniform(0,15))
                eth = Ether(src = random_src,type=0x0806)
                #arp = ARP(hwtype = 0x0001,ptype = 0x0800,op = 0x0001,hwsrc = random_src,psrc = '192.168.1.32',pdst = dst)
                arp = ARP(hwtype = 0x0001,ptype = 0x0800,op = 0x0001,hwsrc = random_src,pdst = dst)
                a = eth/arp
                success = 1
                success = sendp(a,iface="eth1")
                if success == None:
                    print "send an ARP Packet successfully"
                else:
                    print "fail in sending an ARP Packet"
                    raise
                #----------------check mac---------------------------------- 
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(3)
	        #ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Monitor")).perform()
	        #WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Monitor")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("dyna_mac.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("dyna_mac.htm")).click()
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(3)
                time.sleep(agingtime)
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath("/html/body/div/form/input[2]")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_xpath("/html/body/div/form/input[2]")).click()
                time.sleep(3)
                i = 3
                check_web_mac_xpath = "/html/body/table/tbody/tr[3]/td[3]"
                check_web_port_xpath = "/html/body/table/tbody/tr[3]/td[5]/img"
                MACaddress = self.driver.find_element_by_xpath(check_web_mac_xpath).text
                mac_flag = 0
                while MACaddress:
                    if MACaddress.lower() == random_src[0:2] + "-" + random_src[3:5] + "-" + random_src[6:8] + "-" + random_src[9:11] + "-" +\
                                             random_src[12:14] + "-" + random_src[15:17]:
                        print "get the right MACaddress"
                        mac_flag = 1
                        break
                    else:
                        mac_flag = 0
                        i +=1
                    check_web_mac_xpath="/html/body/table/tbody/tr[%d]/td[3]"%i
                    check_web_port_xpath="/html/body/table/tbody/tr[%d]/td[5]/img"%i
                    try:
                        MACaddress = self.driver.find_element_by_xpath(check_web_mac_xpath).text
                    except:
                        print "searching all the table"
                        break
                if disable_value == "None":
                    if mac_flag:
                        print "Shouldn't get the right MACaddress"
                        raise
                    else :
                        print "Haven't gottn the right MACaddress"
                else :
                    if mac_flag:
                        print "Have gottn the right MACaddress"       
                    else :
                        print "Should get the right MACaddress" 
                        raise
                print "finished checking MAC"
                #----------------check the right port----------------------------------
                if mac_flag:
                    try :
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")                   
                        self.driver.find_element_by_xpath(check_web_port_xpath)
                        print "get the right port"
                        port_flag = 1;
                    except :
                        print "can't get the right port"
                        port_flag = 0
                    if not port_flag:
                        print "Haven't gotten the right port"
                        raise
                    else :
                        print "Have gotten the right port"
                    print "finished checking Port"
                print "----CheckMAC_Port finished---"
                time.sleep(5)

        def Check_MAC_Config(self):
                print "\n=========Check_MAC_Port_Config========"
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mac.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("mac.htm")).click()
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                check_disable_value = str(self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr/td[2]/input").get_attribute("checked"))
                self.PubModuleEle.DutReboot()
                time.sleep(5)
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mac.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("mac.htm")).click()
                time.sleep(5)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(5)
                check_disable_value = str(self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr/td[2]/input").get_attribute("checked"))
                if(check_disable_value != disable_value):
                    raise
                else:
                    print "right disable_value"            
                if(check_disable_value == "None"):
                    check_agingtime = str(self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td[2]/input").get_attribute("value"))
                    if check_agingtime != str(agingtime):
                        raise
                    else:
                        print "right agingtime"         
                print "----Check_MAC_Config finished---"
                time.sleep(3)
            
        def Check_MacTableConfig(self):
                print "\n=========Check_MacConfig========"
                global PortMem
                global MacID
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("mac.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("mac.htm")).click()
                time.sleep(5) 
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(5)         
                Check_WebVlan = []
                Check_WebMac = []
                for i in range(64):
                    Check_WebVlanxpath="/html/body/form/table[3]/tbody/tr[%d]/td[2]"%(i+3)
                    Check_WebMacxpath="/html/body/form/table[3]/tbody/tr[%d]/td[3]"%(i+3)
                    Check_WebPortID = "Dest_%d_"%(i+1)
                    Check_WebPort = []        
                    for j in range (1,9):
                        select_Check_WebPortID = Check_WebPortID + str(j)
                        ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(select_Check_WebPortID)).perform()
                        status = WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id\
                                          (select_Check_WebPortID)).get_attribute("checked")
		        Check_WebPort.append(str(status))
                        if Check_WebPort[j-1] == "true":
                            Check_WebPort[j-1] = 1
                        else:
                            Check_WebPort[j-1] = 0  
                        if PortMem[i][j-1] != Check_WebPort[j-1]:
                            raise 
                        time.sleep(3)  
                    Check_WebMac.append(str(self.driver.find_element_by_xpath(Check_WebMacxpath).text))
                    if MacID[i] != Check_WebMac[i]:
                        raise
                    Check_WebVlan.append(str(self.driver.find_element_by_xpath(Check_WebVlanxpath).text))
                    if Check_WebVlan[i] != "1":
                        raise
                    time.sleep(3)
                print "----Check_MacTableConfig finished---"
                time.sleep(3)

        def AddMacTable(self, process):
                print "\n=========AddMacTable========"
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                global selectVID
                global MacID
                global PortMem
                PortMem = []
                selectVID = range(64)
                if process == 1:
                    VlanID = range(1,4094)
                    selectVID = random.sample(VlanID,64)  
                elif process == 2:
                    for i in range(64):
                        selectVID[i] = 1                              
                MacID = range(100,164)
                for i in range(64):
                    MacID[i] = "00-00-00-00-00-%X"%MacID[i]
                for i in range(0,64):
                    WebVlanID = "VID_%d"%(i+1)
                    WebMacID = "MAC_%d"%(i+1)
                    WebPortID = "Dest_%d_"%(i+1)                   
                    PortMem.append([0,0,0,0,0,0,0,0])
                    PortNum = random.randint(1,255)
                    k = 0
                    while PortNum:
                        PortNum,rem = divmod(PortNum,2)
                        PortMem[i][k] = rem
                        k = k+1
                    time.sleep(3)
                    self.driver.find_element_by_xpath("/html/body/form/p/input").click()
                    time.sleep(3)
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(WebVlanID)).perform()
	            WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(WebVlanID)).clear()
                    WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(WebVlanID)).send_keys(str(selectVID[i]))
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(WebMacID)).perform()
	            WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(WebMacID)).clear()
                    WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(WebMacID)).send_keys(str(MacID[i]))
                    for j in range (1,9):
                        selectWebPortID = WebPortID + str(j)
                        ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(selectWebPortID)).perform()
                        if (PortMem[i][j-1]):
		            WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(selectWebPortID)).click()
                time.sleep(3)
                self.driver.find_element_by_xpath("/html/body/form/p[2]/input[2]").click()
                time.sleep(10)
                print "----AddMacTable finished---"
                time.sleep(10)

        def DeleteMacTable(self):
                print "\n=========DeleteMacTable========"
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                for i in range(0,64):
                    DeleteID = "Delete_%d"%(i+1)
                    self.driver.find_element_by_id(DeleteID).click()
                self.driver.find_element_by_xpath("/html/body/form/p[2]/input[2]").click()
                time.sleep(3)
                print "----DeleteMacTable finished---"
                time.sleep(5)

        def SendMACs(self,dst):
                print"\n=========SendMACs========"
                global Send_MAC
                src_mac = []
                Send_MAC = []
                for i in xrange(64):
                    a = i + 1
                    j = '%s' % ('%x' % a)
                    if len(j) == 1:
                        x = "0" + j
                        y = "00"
                    elif len(j) == 2:
                        x = j
                        y = "00"
                    elif len(j) == 3:
                        x = j[1:]
                        y = "0" + j[0]
                    else:
                        x = j[2:]
                        y = j[:2]
                    src_mac.append("00:01:00:00:" + y + ":" + x)
                    Send_MAC.append("00-01-00-00-" + y + "-" + x)
                    eth = Ether(src = src_mac[i],type=0x0806)
                    #arp = ARP(hwtype = 0x0001,ptype = 0x0800,op = 0x0001,hwsrc = src_mac[i],psrc = '192.168.1.32',pdst = dst)
                    arp = ARP(hwtype = 0x0001,ptype = 0x0800,op = 0x0001,hwsrc = src_mac[i],pdst = dst)
                    a = eth/arp
                    sendp(a,iface='eth1')
                    time.sleep(0.1)
                print "----SendMACs finished---"
                time.sleep(3)

        def Check_MACs(self):
                print"\n=========Check_Macs========"
                global Send_MAC
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("dyna_mac.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("dyna_mac.htm")).click()
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(3)
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("StartMacAddr")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("StartMacAddr")).clear()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("StartMacAddr")).send_keys("00-01-00-00-00-01")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("NumberOfEntries")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("NumberOfEntries")).clear()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("NumberOfEntries")).send_keys("100")
                self.driver.find_element_by_xpath("/html/body/div/form/input[2]").click()
                time.sleep(5)
                for i in xrange(64):
                    for j in xrange(100):
                        Check_Mac_xpath = "/html/body/table/tbody/tr[%d]/td[3]"%(j+3) 
                        Check_Mac = self.driver.find_element_by_xpath(Check_Mac_xpath).text    
                        if Send_MAC[i].upper() == Check_Mac:                         
                            Check_Type_xpath = "/html/body/table/tbody/tr[%d]/td"%(j+3)
                            Check_VlanID_xpath = "/html/body/table/tbody/tr[%d]/td[2]"%(j+3)
                            Check_Port_xpath = "/html/body/table/tbody/tr[%d]/td[5]/img"%(j+3)
                            Check_Type = self.driver.find_element_by_xpath(Check_Type_xpath).text
                            Check_VlanID = self.driver.find_element_by_xpath(Check_VlanID_xpath).text
                            break
                        elif j == 100:
                            raise
                        if Check_Type == "Dynamic" and Check_VlanID == "1":
                            self.driver.find_element_by_xpath(Check_Port_xpath)
                        else:
                            raise
                print "----Check_MACs finished---"
                time.sleep(3)

        def DutReboot(self,**args):
                self.PubModuleEle.rthttpmode="http"
                ##self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                #ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Maintenance")).perform()
                #WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Maintenance")).click()
                ##ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("wreset.htm")).perform()
                ##WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("wreset.htm")).click()
                print "DUT will reboot soon ..."
                time.sleep(3)
                ##self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                ##time.sleep(5)
                ##self.driver.find_element_by_xpath("//input[@value='Yes']").click()   
                ##time.sleep(5)
                self.PubModuleEle.i = 1
                time.sleep(120)   ###wait for reboot accomplishment
                while True: 
                    self.st = self.PubModuleEle.ConnectionServer(httpmode=self.PubModuleEle.rthttpmode)
                    if self.st != 200:
                        print "Waiting for DUT bootup ...%d"%self.PubModuleEle.i
                    else:
                        time.sleep(5) 
                        print "DUT bootup successfully!"
                        time.sleep(10)
                        return 1
                        break
                    self.PubModuleEle.i += 1
                    if (self.PubModuleEle.i == 12):
                        print "DUT do not bootup again\n DUT bootup FAIL!"
                        time.sleep(10)
                        return 0
                    else:
                        time.sleep(5) 






                
