#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: LimitControl.py
#-----------------------------------------------------------------------------------

import os,sys,random,string,time,socket#,fcntl

#general speaking,it isn't suggest to call "__file__", another way is sys.argv[0]
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname( os.path.dirname(os.path.abspath(__file__))))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#------------------------------import selenium module-----------------------------------

from PubModuleVitesse import PubModuleCase
from PubModuleVitesse import PubReadConfig
from selenium.webdriver.common.action_chains import ActionChains
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import TimeoutException
#----------------------------import scapy module----------------------------------------
from scapy.all import *
import threading



class LimitControl: 
	def __init__(self,prjName,brsertype,DUTIP,managenic,datanic):
		self.managenic=managenic
		self.datanic=datanic
		self.prjName=prjName.lower()
		self.browserType=brsertype.lower()
		self.DUTIP=DUTIP
		self.pubmodul=PubModuleCase(DUTIP)
		st=self.pubmodul.ConnectionServer()
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

		self.pubmodul.SetPubModuleValue(self.driver)
		self.tmp_handle = self.driver.current_window_handle

	def StartWeb(self):
		print "========StartPortsWeb========"
		domain = "http://admin:@%s"%(self.DUTIP)
		self.driver.get(domain)
#		assert (self.driver.title == self.prjName)
		print "start web successfully!"
		self.pubmodul.location("/html/frameset/frameset/frame[1]")
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Security")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Security")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Network")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Network")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Limit Control")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Limit Control")).click()


	def WebConfig(self):
		self.pubmodul.location("/html/frameset/frameset/frame[2]")
		select=Select(self.driver.find_element_by_id("glbl_ena"))
		select.select_by_visible_text("Enabled")
		age=str(random.randint(10,10000000))
		self.driver.find_element_by_id("aging_enabled").click()
		self.driver.find_element_by_id("aging_period").clear()
		self.driver.find_element_by_id("aging_period").send_keys(age)
		config = {}
		config['age']=age
		if self.prjName == 's3280':
			j=9
		if self.prjName == 's4140':
			j=5
		for i in range (1,j):
			config[i]={}
			ena=str("ena_%d"%i)
			select1=Select(self.driver.find_element_by_id(ena))
			select1.select_by_value("1")
			limit_value=str(random.randint(1,1024))

			limit=str("limit_%d"%i)
			config[i]['limit']=limit_value
			self.driver.find_element_by_id(limit).clear()
			self.driver.find_element_by_id(limit).send_keys(limit_value)
			action=str('action_%d'%i)
			action_value=random.choice(['0','1','2','3'])
			config[i]['action']=action_value
			select2=Select(self.driver.find_element_by_id(action))
			select2.select_by_value(action_value)
			time.sleep(1)
		self.driver.find_element_by_xpath("/html/body/form/p/input[2]").click()
		time.sleep(2)
		return config

	def FactoryDefault(self):
		self.pubmodul.location("/html/frameset/frameset/frame[1]")
		self.driver.find_element_by_link_text("Maintenance").click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Factory Defaults")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Factory Defaults")).click()
		self.pubmodul.location("/html/frameset/frameset/frame[2]")
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


	def CheckConfig(self,config):
		self.StartWeb()
		self.pubmodul.location("/html/frameset/frameset/frame[2]")
		value=self.driver.find_element_by_id("aging_period").get_attribute("value")
		if config['age'] != value:
			print "configuration changed"
			print "failed"
			sys.exit()
		if self.prjName == 's3280':
			j=9
		if self.prjName == 's4140':
			j=5
		for i in range (1,j):
			limit=str("limit_%d"%i)
			value=self.driver.find_element_by_id(limit).get_attribute("value")
			if config[i]['limit'] != value:
				print "configuration changed"
				print "failed"
				sys.exit()
			action=str('action_%d'%i)
			value=self.driver.find_element_by_id(action).get_attribute("value")
			if config[i]['action'] != value:
				print "configuration changed"
				print "failed"
				sys.exit()
		print "configuration not changed"
		print "successfully"

	def Restart(self):
		time.sleep(1)
		re=self.pubmodul.DutReboot()
		if re == 0:
			print "dut reboot failed,please check the dut"
			sys.exit()
		else:
			print "dut reboot successfully"



	def CloseSession(self):
		self.driver.close()

	def Getlimit(self):
		return self.limit

	def FunctionCheck(self,testport):
		portnum = testport[-1]
		self.pubmodul.location("/html/frameset/frameset/frame[1]")
		self.driver.find_element_by_link_text("Limit Control").click()
		time.sleep(1)
		self.pubmodul.location("/html/frameset/frameset/frame[2]")
		if os.geteuid() != 0:
			print "Please run as root."
			sys.exit()
		print "the test port is set to port%s!!!!"%portnum
		limit_index="limit_%s"%portnum
		self.limit=self.driver.find_element_by_id(limit_index).get_attribute("value")
		print "the max num of mac address in port%s is %s"%(portnum,self.limit)
		print "set the action of port%s as Shutdown"%portnum
		action_index="action_%s"%portnum
		select=Select(self.driver.find_element_by_id(action_index))
		select.select_by_visible_text("Shutdown")
		time.sleep(1)
		self.driver.find_element_by_xpath("/html/body/form/p/input[2]").click()
		time.sleep(1)
		
		print "now we send the over limit-num of mac address"

		self.limit=int(self.limit)+1
		self.mac=self.pubmodul.MacIncrease('00:00:00:00:00:01',self.limit,2)

		#sendp((Ether(src=self.mac,dst='ff:ff:ff:ff:ff:ff')),iface='eth2',inter=0.1)
                sendp((Ether(src=self.mac,dst='ff:ff:ff:ff:ff:ff')),iface='eth1',inter=0.1)
		time.sleep(1)
		self.driver.find_element_by_xpath("html/body/div/form/input").click()
		time.sleep(1)
		openindex="/config/psec_limit_reopen?port=%s"%portnum
		elem=self.driver.find_element_by_name(openindex)
		if elem.is_enabled() == True:
			print "port%s's limit action of Shutdown works well"%portnum
		else:
			print "port%s did not Shutdown while the mac address exceed the limit"%portnum
			print "failed"
			sys.exit()
		elem.click()
		time.sleep(1)
		
		print "set the action of port%s as trap"%portnum
		select=Select(self.driver.find_element_by_id(action_index))
		select.select_by_visible_text("Trap")
		self.driver.find_element_by_xpath("/html/body/form/p/input[2]").click()
		time.sleep(1)
		self.TrapTest(self.managenic,self.datanic,portnum)
		timeout=self.limit/10+11
		time.sleep(timeout)

		print "stat to test the ShutdownandTrap"
		select=Select(self.driver.find_element_by_id(action_index))
		select.select_by_visible_text("Trap & Shutdown")
		time.sleep(1)
		self.driver.find_element_by_xpath("/html/body/form/p/input[2]").click()
		time.sleep(1)
		self.TrapTest(self.managenic,self.datanic,portnum)
		time.sleep(timeout)
		self.driver.find_element_by_xpath("html/body/div/form/input").click()
		time.sleep(1)
		try:
			self.driver.find_element_by_name(openindex).click()
			print "port%s's limit action of Shutdown works well"%portnum
		except:
			print "port%s did not Shutdown while the mac address exceed the limit"%portnum
			print "failed"
			sys.exit()
		print "pass"






	def SendMac(self,iface='eth2'):
		print "now we send the over limit-num of mac address"
		sendp((Ether(src=self.mac,dst='ff:ff:ff:ff:ff:ff')),iface=iface,inter=0.1)
		time.sleep(1)

	def CapTrap(self,iface='eth1',port='1'):
		timeout=self.limit/10+10
		filter="udp and port 162 and src %s"%self.DUTIP
		pkg=sniff(iface=iface, filter=filter,timeout=timeout)
		num=len(pkg)
		if num == 0:
			print "can not capture the trap"
			print "failed0"
		else:
			try:
				#the last number of the oid is the index of port
				#if the test port is port1,then the oid is 1.X.X.X.1
				#if the test port is port 2 ,then the oid is 1.X.X.2
				port=port
				oid = '1.3.6.1.4.1.868.2.5.3.1.4.4.1.4.%s'%port
				print oid
				if pkg[0][SNMP][5].oid.val == oid:
					print "capture the trap for the macreached"
					print "Pass"
				else:
					print "can not capture the trap"
					print "failed1"
			except:
				print "can not capture the trap"
				print "failed2"
				sys.exit()


	def TrapTest(self,managenic,datanic,port):
		managenic=managenic
		datanic=datanic
		port=port
		t1=threading.Thread(target=self.CapTrap,args=(managenic,port))
		t1.start()
		t2=threading.Thread(target=self.SendMac,args=(datanic,))
		t2.start()

	
	def SnmpConfig(self):
		parameters = PubReadConfig("")
                pc_ip = parameters.GetParameter("PC","MGMTIP")
                print "pc_ip:" + pc_ip
		self.pubmodul.location("/html/frameset/frameset/frame[1]")
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Switch")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Switch")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("SNMP")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("SNMP")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("snmp.htm")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_id("snmp.htm")).click()
		self.pubmodul.location("/html/frameset/frameset/frame[2]")
		select1=Select(self.driver.find_element_by_id("trap_mode"))
		select1.select_by_visible_text("Enabled")
		select2=Select(self.driver.find_element_by_id("trap_version"))
		select2.select_by_visible_text("SNMP v2c")
		des=self.driver.find_element_by_id("trap_dip")
		des.clear()
		des.send_keys(pc_ip)
		select3=Select(self.driver.find_element_by_id("trap_inform_mode"))
		select3.select_by_visible_text("Disabled")
		self.driver.find_element_by_xpath("/html/body/form/p/input").click()
