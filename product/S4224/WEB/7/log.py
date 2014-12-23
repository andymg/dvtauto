import time,re,sys,os,httplib,base64,random,socket
#----------------------import public module--------------------
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#----------------------------------------------------------------

#-------------------------import selenium module------------------
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
from selenium.webdriver.remote.command import Command
from selenium.webdriver.remote.webdriver import WebDriver as RemoteWebDriver
from selenium.common.exceptions import WebDriverException
#----------------------------import scapy module---------------------------------------
from scapy.all import*
import threading

class ConfigCase:
        #Initialize module, will include "caseName","ProjectName","browser type","ip address","driver object"
	def __init__(self,brserType,DUTIP):
                self.PubModuleEle = PubModuleCase(DUTIP)
                print "Initializing..."
                self.browserType = brserType.lower()
                self.DUTIP = DUTIP
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
	def StartWebConfig(self,prjName):
                print "\n=======startWebUser======="
                domain = "http://admin:@%s"%(self.DUTIP)
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

        def engineConfigLog(self,srvaddr):
                print "\n========engineConfig========"
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/a").click()# locate Configuration
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li/a").click()#locate System
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li/div/ul/li[6]/a").click()# locate log
                time.sleep(2)
                print "***********ConfigurationFinish*************"
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(2)
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("server_mode"))
                select = Select(self.driver.find_element_by_name("server_mode"))
                select.select_by_value("1")
                elem=self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td[2]/input")
                elem.clear()
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td[2]/input").send_keys(srvaddr)
                s1=self.driver.find_element_by_name("server_addr").get_attribute("value")
                print "the serveraddr is %s"%s1
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("syslog_level"))
                select = Select(self.driver.find_element_by_name("syslog_level"))
                select.select_by_value("0")
                self.driver.find_element_by_xpath( "/html/body/form/p/input").click()
                                                                    
        def CheckConfig(self,pkg):
                print "\n====CheckConfig===="
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)           
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[2]/div/ul/li/a").click() #locate monitor system
                time.sleep(5)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[2]/div/ul/li/div/ul/li[3]/a").click() #locate log
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(8)                   
                i = 0
                while 1:
                    i = i+1
                    if i == 1:
                        Levelxpath = "/html/body/table[2]/tbody/tr/td/a"
                        Timexpath = "/html/body/table[2]/tbody/tr/td[3]"
                        Messagexpath = "/html/body/table[2]/tbody/tr/td[4]"
                    else:
                        Levelxpath = "/html/body/table[2]/tbody/tr[%d]/td/a"%i
                        Timexpath = "/html/body/table[2]/tbody/tr[%d]/td[3]"%i
                        Messagexpath = "/html/body/table[2]/tbody/tr[%d]/td[4]"%i
                    try:
                        Levelvalue = self.driver.find_element_by_xpath(Levelxpath).text
                        Timevalue = self.driver.find_element_by_xpath(Timexpath).text
                        Messagevalue = self.driver.find_element_by_xpath(Messagexpath).text
                        Levelvalue = "ID"+Levelvalue
                    except:
                        print "finish read the Syslog table"
                        break        
                    if pkg[i-1].find(Levelvalue) != -1 and pkg[i-1].find(Timevalue) != -1 and pkg[i-1].find(Messagevalue) != -1:
                        pass
                    else:
                        print "can't find the sniffered packet in syslog table"
                        raise
                print "CheckConfig successfully\n"	

#----------------------------ManualSyslog---------------------------------------

	def SendSyslog(self,choice):
                print "\n====SendSyslog===="
		self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
		time.sleep(2)
		ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Ports")).perform()
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_link_text("Ports")).click()
                ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("ports.htm")).perform()
                WebDriverWait(self.driver,30).until(lambda driver: driver.find_element_by_id("ports.htm")).click() #ports configuration
                time.sleep(3)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
		WebDriverWait(self.driver,30).until(lambda driver:driver.find_element_by_id("speed_4"))
                if choice == 1:
                    Select(self.driver.find_element_by_id("speed_4")).select_by_value("0A0A0A0A0")
                elif choice == 2:
                    Select(self.driver.find_element_by_id("speed_4")).select_by_value("1A1A0A0A0")
                time.sleep(2)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
		self.driver.find_element_by_xpath("/html/body/form/p/input[2]").click() #click save
		time.sleep(10)
                self.driver.find_element_by_xpath("/html/body/div/form/input").click() # refresh
                print"send manul Info"

        def SyslogTest(self,choice):
                print "\n====SyslogTest===="
                t1=threading.Thread(target=self.CapSyslog,args=(choice,))
                t1.start()
                t2=threading.Thread(target=self.SendSyslog,args=(choice,))
                t2.start()
                t1.join()
                t2.join()

        def CapSyslog(self,choice=0,iface="eth0"):
                package = []
                print "\n====CapSyslog===="
                if choice == 0:
                    timeout = 70
                else:
                    timeout = 30
                filter1="udp and port 514 and src 192.168.3.59"
                pkg=sniff(iface=iface,filter=filter1,timeout=timeout)
                num=len(pkg)
                if num==0:
                        print "can not capture the Syslog"
                        raise
                else:
                        for i in xrange(num):
                            try:
                                string = pkg[i][3].load
                            except:
                                continue
                            if string.find("syslog - ID") != -1:
                                package.append(pkg[i][3].load)
                        print "CapSyslog successfully"
                        print package
                        if choice == 0:
                            self.CheckConfig(pkg = package)
                        if choice == 1:
                            self.ManuallyCheckConfig(pkg = package,choice = 1)
                        elif choice == 2:
                            self.ManuallyCheckConfig(pkg = package,choice = 2)

        def ManuallyCheckConfig(self,pkg,choice):
                print "\n====ManuallyCheckConfig===="
                if choice == 1:
                    if pkg[0].find("Link down on port 4") != -1:
                        pass
                    else:
                        print "the sniffered packet is incorrect"
                        raise
                if choice == 2:
                    if pkg[0].find("Link up on port 4") != -1:
                        pass
                    else:
                        print "the sniffered packet is incorrect"
                        raise
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)           
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[2]/div/ul/li/a").click() #locate monitor system
                time.sleep(5)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[2]/div/ul/li/div/ul/li[3]/a").click() #locate log
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(8)                   
                i = 0
                while 1:
                    i = i+1
                    if i == 1:
                        Levelxpath = "/html/body/table[2]/tbody/tr/td/a"
                        Timexpath = "/html/body/table[2]/tbody/tr/td[3]"
                        Messagexpath = "/html/body/table[2]/tbody/tr/td[4]"
                    else:
                        Levelxpath = "/html/body/table[2]/tbody/tr[%d]/td/a"%i
                        Timexpath = "/html/body/table[2]/tbody/tr[%d]/td[3]"%i
                        Messagexpath = "/html/body/table[2]/tbody/tr[%d]/td[4]"%i
                    try:
                        Levelvalue = self.driver.find_element_by_xpath(Levelxpath).text
                        Timevalue = self.driver.find_element_by_xpath(Timexpath).text
                        Messagevalue = self.driver.find_element_by_xpath(Messagexpath).text
                        Levelvalue = "ID"+Levelvalue
                    except:
                        print "finish read the table"
                        i = 0
                        break
                    if pkg[0].find(Timevalue) != -1 and pkg[0].find(Messagevalue) != -1:
                        break
                if i == 0:
                    print "can't find the sniffered packet in syslog table"
                    raise  
                print "ManuallyCheckConfig successfully\n"
