#!/usr/bin/python
# -*- coding: utf-8 -*-
# Filename: VlanPortClass.py
#-----------------------------------------------------------------------------------
#Purpose: This is a private class of ports test cases
#
#
#Notes:
#History:
#        09/13/2013- Champion,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------

import time,re,sys,os,httplib,base64,random

#------------------------------------public module path-----------------------------------
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)

#----------------------------------------------------------------------------------------

#------------------------------------public module---------------------------------------
from PubModuleVitesse import PubReadConfig
#---------------------------------------------------------------------------------------

#--------------------------------------import selenium module----------------------------
from PubModuleVitesse import PubModuleCase
from selenium.webdriver.common.action_chains import ActionChains
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.ui import Select
#---------------------------------------------------------------------------------------

#-------------------------------import scapy module-------------------------------------
from scapy.all import *
from scapy.sendrecv import debug, srp1
#---------------------------------------------------------------------------------------

PortType = []
IngressFiltering = []
FrameType = []
VlanMode = []
VlanId = []
TxTag = []

class WebVlanPortsCase:
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
	def StartWebVlanPorts(self,prjName):
                print "========startWebVlanPorts========"
                domain = "http://admin:@%s"%(self.DUTIPAddr)
                print domain
                self.driver.get(domain)
		print self.driver.title
		assert (self.driver.title == prjName)
		print "start web successfully!"
        #Finding the "users" table in the web
	def ClickButtonType(self):
                if self.browserType == "firefox":
                        print "clickButtonTypeFirefox"
                        WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("addNewEntry")).send_keys(Keys.RETURN)
                if self.browserType == "chrome":
                        print "clickButtonTypeChrome"
                        WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("addNewEntry")).click()
        
        def ClickSaveButton(self):
                if self.browserType == "firefox":
                        self.driver.find_element_by_xpath("//input[@value='Save']").send_keys(Keys.RETURN)
                if self.browserType == "chrome":
                        self.driver.find_element_by_xpath("//input[@value='Save']").click()	

        def factorydefault(self):
                self.PubModuleEle.factorydefault()
                time.sleep(3)
                self.driver.close()

#######################################---PortClass---#################################################
	
        def EnginePorts(self):
                print "=========EnginePorts========="
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(1)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("VLANs")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("VLANs")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("vlan_port.htm")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("vlan_port.htm")).click()

        #Set the value of "select" by Id.
        def SetSelectValue(self,elemId,i):
                print "========setSelectValue======="
                print elemId
                value = "<>"
                randomNumber = 0
                if elemId == "__ctl__":
                    elemId = elemId+"%d"%i
                    print elemId
                if elemId == "__ctl__1" or elemId == "porttypev2_" or elemId == "mgmtport":
                    randomNumber = self.PubModuleEle.GetRandomNumber(0,3)
                    print "The PortType random number is %d."%randomNumber
                    if randomNumber == 0:
                        value = "Unaware"
                    elif randomNumber == 1:
                        value = "C-port"
                    elif randomNumber == 2:
                        value = "S-port"
                    elif randomNumber == 3:
                        value = "S-custom-port"
                if elemId == "__ctl__4" or elemId == "frametypev2_":
                    randomNumber = self.PubModuleEle.GetRandomNumber(0,2)
                    print "The Frame Type random number is %d."%randomNumber
                    if randomNumber == 0:
                        value = "All"
                    elif randomNumber == 1:
                        value = "Tagged"
                    elif randomNumber == 2:
                        value = "Untagged"
                if elemId == "__ctl__6" or elemId == "selpvlan_":
                    randomNumber = self.PubModuleEle.GetRandomNumber(0,1)
                    print "The Mode random number is %d."%randomNumber
                    if randomNumber == 0:
                        value = "Specific"
                    elif randomNumber == 1:
                        value = "None"
                    self.randomValue = randomNumber
                if elemId == "__ctl__8" or elemId == "tx_tag_":
                    randomNumber = self.PubModuleEle.GetRandomNumber(0,3)
                    print "The Tx Tag random number is %d."%randomNumber
                    if randomNumber == 0 or randomNumber == 1:
                        value = "Untag_pvid"
                        randomNumber = 0
                    elif randomNumber == 2:
                        value = "Tag_all"
                    elif randomNumber == 3:
                        value = "Untag_all"
                if elemId == "porttypev2_" or elemId == "frametypev2_" or elemId == "selpvlan_" or elemId == "tx_tag_":
                    elemId = elemId+"%d"%i
                    print elemId
                print value     
                select = Select(self.driver.find_element_by_id(elemId))
                time.sleep(1)
                select.select_by_visible_text(value)
                return randomNumber

        #Set the value of "checkbox" by Id.
        def SetCheckboxValue(self,eId,i):
                print "=======setCheckboxValue======"
                print eId
                randomNumber = random.randint(0,1)
                eId = eId+"%d"%i
                print eId
                if randomNumber == 1:
                     ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(eId)).perform()
                     WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id(eId)).click()
                return randomNumber

        #Set the value of "input" component.
        def SetPortsInputValue(self,eId,i):
                print "======setPortsInputValue====="
                print eId
                randomNumber = random.randint(1,4094)
                eId = eId+"%d"%i
                print eId
                randomNumStr = "%d"%randomNumber
                print randomNumStr
                if self.randomValue != 1:
                     self.driver.execute_script('document.getElementById("'+eId+'").value="";')
                     ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(eId)).perform()
		     WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id(eId)).send_keys(randomNumStr)
                     return str(randomNumStr)
                return "1"
       
        def SetPortsParameters(self):
                global sportsValueStr
                global MgmtPort
                print "======setPortsParameters====="
                time.sleep(1)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                sportsRandomNumber = random.randint(1536,65535)
                sportsValueStr = (self.PubModuleEle.dec2hex(sportsRandomNumber))
                self.driver.execute_script('document.getElementById("tpid").value="";')
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("tpid")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("tpid")).send_keys(sportsValueStr)
                MgmtPort = (str(self.SetSelectValue("mgmtport",-1)))
                time.sleep(1)
                self.SetSelectValue("__ctl__",1)
                time.sleep(1)
                FrameType_ctl_ = self.SetCheckboxValue("__ctl__",3)
                time.sleep(1)
                self.SetSelectValue("__ctl__",4)
                time.sleep(1)
                self.SetSelectValue("__ctl__",6)
                time.sleep(1)
                self.SetPortsInputValue("__ctl__",7)
                time.sleep(1)
                self.SetSelectValue("__ctl__",8)
                time.sleep(1)
                for pos in range(1,9):
                        value = self.SetSelectValue("porttypev2_",pos)
                        PortType.append(str(value))
                        time.sleep(1)
                        value = self.SetCheckboxValue("ingressflt_",pos)
                        if FrameType_ctl_ == 1:
                            value = value^1
                        IngressFiltering.append(str(value))
                        time.sleep(1)
                        value = self.SetSelectValue("frametypev2_",pos)
                        FrameType.append(str(value))
                        time.sleep(1)
                        value = self.SetSelectValue("selpvlan_",pos)
                        VlanMode.append(str(value))
                        time.sleep(1)
                        value = self.SetPortsInputValue("pvid_",pos)
                        VlanId.append(str(value))
                        time.sleep(1)
                        value = self.SetSelectValue("tx_tag_",pos)
                        TxTag.append(str(value))
                        time.sleep(1)
                time.sleep(2)
                self.ClickSaveButton()

        def RebootCheckPorts(self):
                print "======setPortsParameters====="
                self.PubModuleEle.DutReboot()
                self.EnginePorts()
                time.sleep(3)
                self.CheckPortsParameters()

        def CheckPortsParameters(self):
                GetPortType = []
                GetIngressFiltering = []
                GetFrameType = []
                GetVlanMode = []
                GetVlanId = []
                GetTxTag = []
                print "======CheckPortsParameters====="
                time.sleep(1)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                for i in xrange(1,9):
                    PortTypeId = "porttypev2_" + "%d"%i
                    IngressFilteringId = "ingressflt_" + "%d"%i
                    FrameTypeId = "frametypev2_" + "%d"%i
                    VlanModeId = "selpvlan_" + "%d"%i
                    VlanIdId = "pvid_" + "%d"%i
                    TxTagId = "tx_tag_" + "%d"%i
                    time.sleep(1)
                    GetPortType.append(str(self.driver.find_element_by_id(PortTypeId).get_attribute("value")))
                    GetIngressFiltering.append(str(self.driver.find_element_by_id(IngressFilteringId).get_attribute("checked")))
                    GetFrameType.append(str(self.driver.find_element_by_id(FrameTypeId).get_attribute("value")))
                    GetVlanMode.append(str(self.driver.find_element_by_id(VlanModeId).get_attribute("value")))
                    GetVlanId.append(str(self.driver.find_element_by_id(VlanIdId).get_attribute("value")))
                    GetTxTag.append(str(self.driver.find_element_by_id(TxTagId).get_attribute("value")))
                    if(GetIngressFiltering[i-1] == "true"):
                        GetIngressFiltering[i-1] = "1"
                    else:
                        GetIngressFiltering[i-1] = "0"
                sportsValueStrId = "tpid"
                MgmtPortId = "mgmtport"
                GetsportsValueStr = str(self.driver.find_element_by_id(sportsValueStrId).get_attribute("value"))
                GetMgmtPort = str(self.driver.find_element_by_id(MgmtPortId).get_attribute("value"))
                for i in xrange(0,8):
                    if GetPortType[i] == PortType[i]:
                        pass
                    else:
                        raise
                    if GetIngressFiltering[i] == IngressFiltering[i]:
                        pass
                    else:
                        raise
                    if GetFrameType[i] == FrameType[i]:
                        pass
                    else:
                        raise
                    if GetVlanId[i] == VlanId[i]:
                        pass
                    else:
                        raise
                    if GetTxTag[i] == TxTag[i]:
                        pass
                    else:
                        raise   
                if GetsportsValueStr == sportsValueStr:
                    pass
                else:
                    raise
                if GetMgmtPort == MgmtPort:
                    pass
                else:
                    raise
                for i in xrange(0,8):
                    if GetVlanMode[i] == VlanMode[i]:
                        pass
                    else:
                        raise
                
        def SetMgmtPortandCheck(self):
                print "======SetMgmtPortandCheck====="
                self.SetMgmtPort("8100","Unaware")
                received = self.Checkpacket("Unaware",0x8100)
                self.Check(received)
                received = self.Checkpacket("Unaware",0x88a8)
                self.Check(received)
                received = self.Checkpacket("Unaware",0x9100)
                self.Check(received)
                received = self.Checkpacket("Unaware",0x9200)
                self.Check(received)
                self.SetMgmtPort("8100","C-port")
                received = self.Checkpacket("C-port",0x8100)
                self.Check(received)
                received = self.Checkpacket("C-port",0x88a8)
                self.Check(received+1)
                received = self.Checkpacket("C-port",0x9100)
                self.Check(received+1)
                received = self.Checkpacket("C-port",0x9200)
                self.Check(received+1)
                self.SetMgmtPort("8100","S-port")
                received = self.Checkpacket("S-port",0x8100)
                self.Check(received+1)
                received = self.Checkpacket("S-port",0x88a8)
                self.Check(received)
                received = self.Checkpacket("S-port",0x9100)
                self.Check(received+1)
                received = self.Checkpacket("S-port",0x9200)####can't find sent packet
                self.Check(received+1)
                self.SetMgmtPort("8101","S-custom-port")
                received = self.Checkpacket("S-custom-port",0x8101)
                self.Check(received)
                received = self.Checkpacket("S-custom-port",0x8100)
                self.Check(received+1)
                received = self.Checkpacket("S-custom-port",0x88a8)
                self.Check(received+1)
                received = self.Checkpacket("S-custom-port",0x9100)
                self.Check(received+1)
                received = self.Checkpacket("S-custom-port",0x9200)
                self.Check(received+1)

        def SetMgmtPort(self,Ethertype,PortType):        
                print "======setMgmtPortsParameters====="
                time.sleep(1)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                self.driver.execute_script('document.getElementById("tpid").value="";')
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("tpid")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("tpid")).send_keys(Ethertype)
                select = Select(self.driver.find_element_by_id("mgmtport"))
                select.select_by_visible_text(PortType)
                time.sleep(1)
                self.ClickSaveButton()
                time.sleep(3)
                self.Refresh()
                time.sleep(1)
        
        def Refresh(self):
                print "======Refresh====="
                time.sleep(1)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("refresh")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("refresh")).click()

        def Checkpacket(self,PortType,Ethertype):
                print "======Checkpacket====="
                time.sleep(1)
                parameters = PubReadConfig("")
                mgmtmac = str(parameters.GetParameter("PC","MGMTMAC"))
                mgmtip = str(parameters.GetParameter("PC","MGMTIP"))
                dstip = str(parameters.GetParameter("DUT1","IP"))
                mgmtnic = str(parameters.GetParameter("PC","MGMTNIC"))
                if PortType == "Unaware":
                    eth = Ether(src=mgmtmac,type=0x0806,dst="ff:ff:ff:ff:ff:ff")
                    arp = ARP(hwtype=0x0001,ptype=0x0800,op=0x0001,hwsrc=mgmtmac,psrc="192.168.1.42",pdst=dstip,hwdst="ff:ff:ff:ff:ff:ff")
                    a = eth/arp
                else:
                    eth = Ether(src=mgmtmac,type=Ethertype,dst="ff:ff:ff:ff:ff:ff")
                    priority = random.randint(0,7)
                    dot1q=Dot1Q(type=0x0806,prio=priority,vlan=1)
                    arp = ARP(hwtype=0x0001,ptype=0x0800,op=0x0001,hwsrc=mgmtmac,psrc="192.168.1.42",pdst=dstip,hwdst="ff:ff:ff:ff:ff:ff")
                    a = eth/dot1q/arp
                os.system("ifconfig eth0 promisc")
                Reply = srp1(a,iface=mgmtnic,timeout=3)
                os.system("ifconfig eth0 -promisc")
                if Reply == None:
                    return 0
                else:
                    if Reply.op == 2:
                        return 1
                    else:
                        return 0

        def Check(self,value):
                if value == 1:
                    pass
                else:
                    raise

#######################################---VlanClass---#################################################
        #Finding the "users" table in the web
	def EngineVlan(self):
                print "========engineValn========"
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(1)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("VLANs")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("VLANs")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("VLAN Membership")).perform()
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("VLAN Membership")).click()

        def SetPortMembers(self,prefix,n):
                for i in range(1,n+1):
                         portPrefix="%s%d"%(prefix,i)
                         intValue = random.randint(0,1)
                         if intValue == 1:
				elem = self.driver.find_element_by_id(portPrefix)
				elem.click()

        def AddNewVlan(self,num):
            time.sleep(1) 
            number="%d"%(num+1)
            self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
	    print '=========addNewVlan======='
	    for i in range(1,num+1):
                    time.sleep(2)
                    #self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    time.sleep(1)
		    prefix = 'vlan'
                    vlanName="%s%d"%(prefix,i+1)
                    print vlanName
                    vlanId="%d"%(i+1)
                    print "The vlan id is "+vlanId
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("addNewEntry")).perform()
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("addNewEntry")).click()
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    time.sleep(1)
                    vlanIdElemName="vid_new_1"
                    print "The element name is "+vlanIdElemName+" in the web."
                    vlanNameElemName="name_new_1"
                    print "The vlan element name is "+vlanNameElemName
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(vlanIdElemName)).perform()
                    self.PubModuleEle.SetInputValue(vlanIdElemName)
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id(vlanIdElemName)).send_keys(vlanId)
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(vlanNameElemName)).perform()
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id(vlanNameElemName)).send_keys(vlanName)
                    self.SetPortMembers("mask_new_1_",8)
                    self.ClickSaveButton()
                    self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                    time.sleep(2)
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("addNewEntry"))
                    ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("NumberOfEntries")).perform()
                    self.driver.execute_script('document.getElementById("NumberOfEntries").value="";')
                    WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("NumberOfEntries")).send_keys(number)
                    self.driver.find_element_by_xpath("//input[@value='Refresh']").click()
	
        def AddVlanHandle(self,num):
                print "=======addVlanHandle======"
                
		self.driver.implicitly_wait(5)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
		self.AddNewVlan(num)        #Add new user
	
        #delete the users that have been added.
	def DeleteVlan(self,num):
                print '========deleteVlan========'
                time.sleep(1)
                number="%d"%(num+1)
                time.sleep(2)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("NumberOfEntries")).perform()
                self.driver.execute_script('document.getElementById("NumberOfEntries").value="";')
                WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("NumberOfEntries")).send_keys(number)
                self.driver.find_element_by_xpath("//input[@value='Refresh']").click()
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                for pos in range(1,num+1):
                        prefix = 'delete_'
                        delElemTag="%s%d"%(prefix,(pos+1))
                        ActionChains(self.driver).move_to_element(self.driver.find_element_by_id(delElemTag)).perform()
                        WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id(delElemTag)).click()
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                self.ClickSaveButton()
                time.sleep(3)
        
        #check the vlan added is existence after rebooting or not.  
        def CheckElem(self,num):
		time.sleep(5)
                number="%d"%(num+1)
		print "========checkElem========"
		st = self.PubModuleEle.ConnectionServer()
                print "Connection status %d."%(st)
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
		self.EngineVlan()
		time.sleep(2)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
		n = 0
		print "Start to check the element...\n"
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("NumberOfEntries")).perform()
                self.driver.execute_script('document.getElementById("NumberOfEntries").value="";')
                WebDriverWait(self.driver, 30).until(lambda driver : driver.find_element_by_id("NumberOfEntries")).send_keys(number)
                self.driver.find_element_by_xpath("//input[@value='Refresh']").click()
                time.sleep(3)
		n = self.driver.execute_script('return document.getElementById("vlanData").rows.length;')
                n = n-3
                if n == num:
                        time.sleep(2)
                        print "Add vlan number is %d."%(n)
                        print "The element checked is existence, check successfully!"
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                        #self.driver.close()
                else:
                        time.sleep(2)
                        print "n=%d"%(n)
                        print "The element checked is not existence, check failed!"
                        self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                        raise
                        #self.driver.close()
        
        #Because the operation way of the "submit" button is different in the different broswer, so we need distinguish to use.
        def ClickDeleteVlanButton(self):
                if self.browserType == "firefox":
                        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_name("warm")).send_keys(Keys.RETURN)
                if self.browserType == "chrome":
                        WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_name("warm")).click()
        
        #Find the "Restart Device" table and reboot the system, and check when the server is normal connection. 
        def CheckRebootElement(self,num):
                print "======checkRebootElement====="
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("VLANs")).click()
		WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Configuration")).click()
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Maintenance")).click()
                time.sleep(1)
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Restart Device")).click()
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                self.ClickDeleteVlanButton()
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
                self.CheckElem(num)
