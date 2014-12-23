#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: PortsConfig.py
#-----------------------------------------------------------------------------------

import os,sys,random,string,time

getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
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



class Ports:
	def __init__(self,prjName,brsertype,DUTIP):
		self.prjName=prjName
		self.browserType=brsertype
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

	def StartPortsWeb(self):
		print "========StartPortsWeb========"
		domain = "http://admin:@%s"%(self.DUTIP)
		self.driver.get(domain)
		assert (self.driver.title == self.prjName)
		print "start web successfully!"
		self.pubmodul.location("/html/frameset/frameset/frame[1]")
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Ports")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Ports")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("ports.htm")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_id("ports.htm")).click()
	
	def Web_Config(self):
		self.pubmodul.location("/html/frameset/frameset/frame[2]")
		config={}
		for i in range (1,9):
			config[i]={}
			if i<=4:
				cf=random.choice(['0A0A0A0A0','1A1A0A0A0','1A0A1A0A0','1A0A1A1A0','1A0A2A0A0','1A0A2A1A0','1A0A3A1A0'])
			else:
				cf=random.choice(['0A0A0A0A0','1A1A0A0A0','1A0A2A1A0','1A0A3A1A0'])
			config[i]['configured']=cf
			speed=str("speed_%d"%i)
			select1=Select(self.driver.find_element_by_id(speed))
			select1.select_by_value(cf)
			time.sleep(1)
			flow=str("flow_%d"%i)
			self.driver.find_element_by_id(flow).click()
			framesize=random.randint(1518,9600)
			framesize=str(framesize)
			config[i]['max']=framesize
			max=str("max_%d"%i)
			self.driver.find_element_by_id(max).clear()
			self.driver.find_element_by_id(max).send_keys(framesize)
			if i <= 4:
				exc=str("exc_%d"%i)
				exc_value=random.choice(['0','1'])
				config[i]['exc']="exc_value"
				select2=Select(self.driver.find_element_by_id(exc))
				select2.select_by_value(exc_value)
				time.sleep(1)
				pwr=str("pwr_%d"%i)
				pwr_value=random.choice(['0','1','2','3'])
				config[i]['pwr']=pwr_value
				select3=Select(self.driver.find_element_by_id(pwr))
				select3.select_by_value(pwr_value)
				time.sleep(1)
			desc=string.join(random.sample('abcdefghijklmnopqrstuvwxyz0123456789!@#$%^*',31)).replace(" ","")
			config[i]['desc']=desc
			name=str("name_%d"%i)
			self.driver.find_element_by_id(name).send_keys(desc)
			time.sleep(1)
		self.driver.find_element_by_xpath("/html/body/form/p/input[2]").click()
		time.sleep(1)
		return config

	def DelConf(self):
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
	
	def Reboot(self):
		print "ready to reboot"
		time.sleep(5)
		self.pubmodul.location("/html/frameset/frameset/frame[1]")
		re=self.pubmodul.DutReboot()
		return re

	def CheckConfig(self,config):
		self.pubmodul.location("/html/frameset/frameset/frame[1]")
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Configuration")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Configuration")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Ports")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Ports")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("ports.htm")).perform()
		WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_id("ports.htm")).click()
		self.pubmodul.location("/html/frameset/frameset/frame[2]")
		for i in range (1,9):
			speed=str("speed_%d"%i)
			select1=Select(self.driver.find_element_by_id(speed))
			speed=select1.first_selected_option.text
			if cmp(speed,config[i]['configured']):
				print "the configuration changed in port %d,configured"%i
				sys.exit()
			max=str("max_%d"%i)
			max=self.driver.find_element_by_id(max).get_attribute('value')
			if cmp(max,config[i]['max']):
				print "the configuration changed in port %d,max frame"%i
				sys.exit()
			if i <= 4:
				exc=str("exc_%d"%i)
				select2=Select(self.driver.find_element_by_id(exc))
				exc=select2.first_selected_option.text
				if cmp(exc,config[i]['exc']):
					print "the configuration changed in port %d,excessive"%i
					sys.exit()
				pwr=str("pwr_%d"%i)
				select3=Select(self.driver.find_element_by_id(pwr))
				pwr=select3.first_selected_option.text
				if cmp(pwr,config[i]['pwr']):
					print "the configuration changed in port %d,power control"%i
					sys.exit()
			name=str("name_%d"%i)
			name=self.driver.find_element_by_id(name).get_attribute('value')
			if cmp(name,config[i]['desc']):
				print "the configuration changed in port %d,Description"%i
				sys.exit()
		print "all configuration is correct !!"
		print "Pass\n"

	def CloseSession(self):
		self.driver.close()
