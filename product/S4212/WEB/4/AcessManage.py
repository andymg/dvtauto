#!/usr/bin/python
#-*- coding: utf-8 -*-
#filename access_manage.python

import sys,time,os,socket,struct,base64,httplib
from selenium.webdriver.support.ui import Select 
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium import webdriver
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
from PubModuleVitesse import PubModuleCase
from PubModuleVitesse import PubReadConfig

class Acess_manage():
	def __init__(self):
		print ("Get parameters from Configuration file")
		parameters=PubReadConfig("")
		global caseName
		caseName = sys.argv[0]
		caseName = caseName[:-3]
		global prjName
		prjName =parameters.GetParameter("DUT1","PRODUCT")
		global brserType
		brserType=parameters.GetParameter("PC","BRWSRTYPE")
		global DUTIP
		DUTIP = parameters.GetParameter("DUT1","IP")
		self.switch_type = prjName
		self.brower_type = brserType
		self.URL = DUTIP
		global netcard
		netcard = parameters.GetParameter("PC","MGMTNIC")
                global netcardip
                netcardip = parameters.GetParameter("PC","MGMTIP")
		self.conn = PubModuleCase(self.URL)
		self.st1 = self.conn.ConnectionServer()
		if self.st1 != 200:
			print "connect to server failed...%d" %self.st1
			sys.exit()
		self.driver = self.conn.LoginToWeb()
		self.mac = self.conn.GetDutMac()
		print "the mac of dut is %s"%self.mac

	def into_manage_web(self):
		self.conn.location("/html/frameset/frameset/frame[1]")
		print self.brower_type
		if (self.switch_type=="S3280"):
			self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/a").click()
			time.sleep(1)
			self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li[4]/a").click()
			time.sleep(1)
			self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li[4]/div/ul/li/a").click()
			time.sleep(1)
			self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li[4]/div/ul/li/div/ul/li[6]/a").click()
		elif (self.switch_type=="S4140"):
			self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/a").click()
			time.sleep(1)
			self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li[3]/a").click()
			time.sleep(1)
			self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li[3]/div/ul/li/a").click()
			time.sleep(1)
			self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li[3]/div/ul/li/div/ul/li[6]/a").click()
		self.conn.location("/html/frameset/frameset/frame[2]")	
	def clicksavebutton(self):
		self.conn.location("/html/frameset/frameset/frame[2]")
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath("/html/body/form/p[3]/input")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver: driver.find_element_by_xpath("/html/body/form/p[3]/input")).click()		
	def clickaddbutton(self):
		self.conn.location("/html/frameset/frameset/frame[2]")
		self.driver.find_element_by_xpath("/html/body/form/p[2]/input").click()
	def check_entry_num(self):
		time.sleep(5)
		entry_list1 = self.driver.find_elements_by_class_name("config_even")
		entry_list2 = self.driver.find_elements_by_class_name("config_odd")
		i = 0
		for entry in entry_list1:
			i = i+1
		for entry in entry_list2:
			i = i+1
		return i
	
	def add_client(self):
		self.conn.location("/html/frameset/frameset/frame[2]")
		entrynum = self.check_entry_num()
		print "==========the number of access management entry is %d==========" %entrynum
		while entrynum:
			self.conn.ScreenshotSele("/html/frameset/frameset/frame[2]","acess_manage",self.switch_type)
			
			print "==========please factory default the access_manage entry=========="
			sys.exit()
		self.select = Select(self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr/td[2]/select"))
		self.select.select_by_value("1")
		self.clickaddbutton()
                local_ip = netcardip
		ip_num = socket.ntohl(struct.unpack("I",socket.inet_aton(local_ip))[0])
		print "your local address is %s"%local_ip
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td[2]/input").clear()
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td[2]/input").send_keys(local_ip)
		ip_num = ip_num+1
		end_ip = socket.inet_ntoa(struct.pack('I',socket.htonl(ip_num)))
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td[3]/input").clear()
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td[3]/input").send_keys(end_ip)
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td[4]/input").click()
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td[5]/input").click()
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td[6]/input").click()
		self.clicksavebutton()
		print "============================================"
		print "        creat the entry successfully        "
		print "        use legal ip http server            "
		print "============================================"

		st = self.conn.ConnectionServer()
		if st==200:
			print "pass!"
		else:
			print "the ip cannot http server"
			sys.exit()
		#time.sleep(2)
		time.sleep(2)
		print "============================================"
		print "        use legal ip https server           "
		print "============================================"
		st = self.conn.ConnectionServer(httpmode="https")
		if st==200:
			print "pass!"
		else:
			print "the ip cannot https server"
			sys.exit()
		#time.sleep(2)
		time.sleep(2)
		print "============================================"
		print "        use legal ip snmp to server         "
		print "============================================"

		result = self.conn.SnmpToServer()
		if result == 0:
			sys.exit()
		#time.sleep(2)
		time.sleep(2)
		print "============================================"
		print "        use legal ip telnet to server       "
		print "============================================"

		self.conn.TelnetToSserver()
		#time.sleep(1)
		time.sleep(2)

		print "============================================"
		print "        use legal ip ssh to server          "
		print "============================================"

		self.conn.SshToServer()
		#time.sleep(1)
		time.sleep(2)
		

		print "============================================"
		print "   use illegal ip estabilish tcp to server  "
		print "============================================"

		
		re = self.conn.TcpHandShake(portdest=23,nickname=netcard)
		if re == 0:
			print "illegal ip could not estabilish telnet tcp connect"
			print "pass\n"
		re = self.conn.TcpHandShake(portdest=22,nickname=netcard)
		if re == 0:
			print "illegal ip could not estabilish ssh tcp connect"
			print "pass\n"
		####
		time.sleep(2)

		print "============================================"
		print "   remove the the snmp in the web and test  "
		print "============================================"

		self.conn.location("/html/frameset/frameset/frame[2]")
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td[5]/input").click()
		self.clicksavebutton()
		time.sleep(2)
		result2 = self.conn.SnmpToServer()
		if result2 == 0:
			print "illegal ip can not snmp to server,successfully"
		else:
			print "illegal ip can snmp to server,failed"
			sys.exit()


		print "=====del the entry for access_manage========"
		print "                                            "
		self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td/input").click()
		self.select = Select(self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr/td[2]/select"))
		self.select.select_by_value("0")
		time.sleep(1)
		self.clicksavebutton()
		print "Function test is over,pass"


	def add_to_full(self):
		print "now add the entry to the max num\n"
		self.driver.find_element_by_xpath("/html/body/form/p[2]/input").click()

		ip_first = "1.1.1.1"
		i = 1
		j = 2
		ip_first_num = socket.ntohl(struct.unpack("I",socket.inet_aton(ip_first))[0])
		while True:
			m = r"/html/body/form/table[2]/tbody/tr[%d]/td[2]/input"%j
			try:
				alert = self.driver.switch_to_alert()
				alert.accept()
				global max_num
				max_num = i-1
				print "the max num of the entry is %d\n"%max_num

				break
			except:
	
				#ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath(m)).perform()
				#WebDriverWait(self.driver, 30).until(lambda driver: driver.find_element_by_xpath(m)).clear()
				while True:
					try:
						ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath(m)).perform()
						WebDriverWait(self.driver, 30).until(lambda driver: driver.find_element_by_xpath(m)).clear()
						break
					except:
						time.sleep(7)

				self.driver.find_element_by_xpath(m).send_keys(ip_first) 	
				ip_sec_num = ip_first_num+1
				ip_sec = socket.inet_ntoa(struct.pack('I',socket.htonl(ip_sec_num)))
				a = r"/html/body/form/table[2]/tbody/tr[%d]/td[3]/input"%j
				time.sleep(1)
				self.driver.find_element_by_xpath(a).clear()
				self.driver.find_element_by_xpath(a).send_keys(ip_sec) 
				b = r"/html/body/form/table[2]/tbody/tr[%d]/td[4]/input"%j
				self.driver.find_element_by_xpath(b).click() 
				c = r"/html/body/form/table[2]/tbody/tr[%d]/td[5]/input"%j
				self.driver.find_element_by_xpath(c).click() 
				d = r"/html/body/form/table[2]/tbody/tr[%d]/td[6]/input"%j
				self.driver.find_element_by_xpath(d).click() 
				self.driver.find_element_by_xpath("/html/body/form/p[3]/input").click()
				time.sleep(1)
				ActionChains(self.driver).move_to_element(self.driver.find_element_by_xpath("/html/body/form/p[2]/input")).perform()
				WebDriverWait(self.driver, 30).until(lambda driver: driver.find_element_by_xpath("/html/body/form/p[2]/input")).click()
				time.sleep(1)
				j = j+1
				i = i+1
				ip_first_num = ip_sec_num+1
				ip_first = socket.inet_ntoa(struct.pack('I',socket.htonl(ip_first_num)))

	def del_all(self):
		print "now clear all the entry:\n"
		loop = max_num+1
		for i in range (1 , loop):
			self.driver.find_element_by_xpath("/html/body/form/table[2]/tbody/tr[2]/td/input").click()
			self.clicksavebutton()
			time.sleep(1)
		print "all entry has been delete"


	def reb_check(self):
		re=self.conn.DutReboot()
		if re == 0:
			sys.exit()
		self.into_manage_web()
		num = self.check_entry_num()
		if (num==max_num):
			print "check Element successfully"
		else:
			print "check Element failed"
			sys.exit()

	def factory_default(self):
		self.conn.location("/html/frameset/frameset/frame[1]")
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Maintenance")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver: driver.find_element_by_link_text("Maintenance")).click()
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Factory Defaults")).perform()
		WebDriverWait(self.driver, 30).until(lambda driver: driver.find_element_by_link_text("Factory Defaults")).click()

		self.conn.location("/html/frameset/frameset/frame[2]")
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



	def CloseSession(self):
		self.driver.close()

		


