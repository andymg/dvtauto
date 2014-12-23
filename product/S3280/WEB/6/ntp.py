import time,re,sys,os,httplib,base64,random
#----------------------import public module--------------------
#general speaking,it isn't suggest to call "__file__", another way is sys.argv[0]
getpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname( os.path.dirname(os.path.abspath(__file__))))))
modpath = os.path.join(getpath,"api","web")
sys.path.append(modpath)
#----------------------------------------------------------------

#-------------------------import selenium module------------------
from PubModuleVitesse import PubModuleCase
from selenium.webdriver.common.action_chains import ActionChains
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import TimeoutException
#-------------------------------------------------------------------
class ConfigCase:
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
	def StartWebConfig(self,prjName):
                print "=======startWebUser======="
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
       
	def engineConfigNtp(self,ntpsrv1,ntpsrv2,ntpsrv3,ntpsrv4,ntpsrv5):
                print "========engineConfig========"
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/a").click()# locate Configuration
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li/a").click()#locate System
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li/div/ul/li[4]/a").click()
                time.sleep(2)
                print "***********ConfigurationFinish*************"
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(2)
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("ntp_mode"))
                select = Select(self.driver.find_element_by_name("ntp_mode"))
                select.select_by_value("1")
                
               
                print "***************NTPConfiguration***************************"
                elem=self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[3]/td[2]/input")
                elem.clear()
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[3]/td[2]/input").send_keys(ntpsrv1)
                s1=self.driver.find_element_by_name("ntp_server1").get_attribute("value")
               
                print "the server1 is %s"%s1
                elem=self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[4]/td[2]/input")
                elem.clear()
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[4]/td[2]/input").send_keys(ntpsrv2)
                s2=self.driver.find_element_by_name("ntp_server2").get_attribute("value")
              
                
                elem=self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[5]/td[2]/input")
                elem.clear()
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[5]/td[2]/input").send_keys(ntpsrv3)
                s3=self.driver.find_element_by_name("ntp_server3").get_attribute("value")
               
               
                elem=self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[6]/td[2]/input")
                elem.clear()
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[6]/td[2]/input").send_keys(ntpsrv4)
                s4=self.driver.find_element_by_name("ntp_server4").get_attribute("value")
               
               
                elem=self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[7]/td[2]/input")
                elem.clear()
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[7]/td[2]/input").send_keys(ntpsrv5)
                s5=self.driver.find_element_by_name("ntp_server5").get_attribute("value")
                self.driver.find_element_by_xpath( "/html/body/form/p/input").click()
                global s
                s=[s1,s2,s3,s4 ,s5]
        def GetRandomNumber(self,m,n):
                return random.randint(m,n)
        def GetRandomString(self,list):
                return random.choice(list)
        def engineConfigTime(self):
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li/div/ul/li[5]/a").click()# locate Time
                time.sleep(2)
        def engineRange(self):
                for i in range(1,4):
                        self.engineConfigZone()
                        self.engineConfigStart()
        def engineConfigZone(self):
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(2)
                timezone=self.GetRandomString(['-3600','1','4804','3000','4200','6000','7200'])
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("time_zone"))
                select = Select(self.driver.find_element_by_name("time_zone"))
                select.select_by_value(timezone)
                
                getval = select.first_selected_option.text
                print "the timezone is %s"%getval
                
                elem=self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[3]/td[2]/input")
                elem.clear()
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[3]/td[2]/input").send_keys("Cas")
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("mode"))
                select = Select(self.driver.find_element_by_name("mode"))
                select.select_by_value("1")
                time.sleep(2)  
                                              
                        
        def engineConfigStart(self):
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(2)
                num = self.GetRandomNumber(1,5)
                num=str(num)
                print "The  start week random number is %s\n"%num
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("week_s"))
                select = Select(self.driver.find_element_by_name("week_s"))
                select.select_by_visible_text(num)
               
                string=self.GetRandomString(['Sun','Mon','Tue','Wed','Thu','Fri','Sat'])
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("day_s"))
                select = Select(self.driver.find_element_by_name("day_s"))
                select.select_by_visible_text(string)
               
                string=self.GetRandomString(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'])
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("month_s"))
                select = Select(self.driver.find_element_by_name("month_s"))
                select.select_by_visible_text(string)
               
                num=self.GetRandomNumber(0,23)
                num=str(num)
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("hours_s"))
                select = Select(self.driver.find_element_by_name("hours_s"))
                select.select_by_visible_text(num)
                
                num=self.GetRandomNumber(0,59)
                num=str(num)
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("minutes_s"))
                select = Select(self.driver.find_element_by_name("minutes_s"))
                select.select_by_visible_text(num)
               
                # config End time settings
                num=self.GetRandomNumber(1,5)
                num=str(num)
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("week_e"))
                select = Select(self.driver.find_element_by_name("week_e"))
                select.select_by_visible_text(num)
                print "the end week random number is %s\n"%num
                string=self.GetRandomString(['Sun','Mon','Tue','Wed','Thu','Fri','Sat'])
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("day_e"))
                select = Select(self.driver.find_element_by_name("day_e"))
                select.select_by_visible_text(string)
                
                string=self.GetRandomString(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'])
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("month_e"))
                select = Select(self.driver.find_element_by_name("month_e"))
                select.select_by_visible_text(string)
                
                num=self.GetRandomNumber(0,23)
                num=str(num)
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("hours_e"))
                select = Select(self.driver.find_element_by_name("hours_e"))
                select.select_by_visible_text(num)
               
                num=self.GetRandomNumber(0,59)
                num=str(num)
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_name("minutes_e"))
                select = Select(self.driver.find_element_by_name("minutes_e"))
                select.select_by_visible_text(num)
                
                #Config offset settings
                elem=self.driver.find_element_by_xpath("/html/body/form/table[3]/tbody/tr[18]/td[2]/input")
                elem.clear()
                self.driver.find_element_by_xpath("/html/body/form/table[3]/tbody/tr[18]/td[2]/input").send_keys("1")
                self.driver.find_element_by_xpath( "/html/body/form/p/input").click()
        
        def engineConfigInfo(self):
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/a").click()# locate Configuration
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li/a").click()#locate System
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li/div/ul/li/div/ul/li[4]/a").click()
                time.sleep(2)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(2)
                c1=self.driver.find_element_by_name("ntp_server1").get_attribute("value")
                print"the server1 is %s\n"%c1
                c2=self.driver.find_element_by_name("ntp_server2").get_attribute("value")
                c3=self.driver.find_element_by_name("ntp_server3").get_attribute("value")
                c4=self.driver.find_element_by_name("ntp_server4").get_attribute("value")
                c5=self.driver.find_element_by_name("ntp_server5").get_attribute("value")
                c=[c1,c2,c3,c4,c5]
                i=0
              
                while i<len(c):
                        t=i+1
             
                        if s[i]==c[i]:
                                print "server %d configuration is correct" %t
                        else :
                                print "the Configuration changed after the dut Rboot"
                        time.sleep(1)
                        i=i+1
                print "check all configuration"
        def systime(self):     
                self.PubModuleEle.location("/html/frameset/frameset/frame[1]")
                time.sleep(2)
                                
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[2]/div/ul/li/a").click()
                time.sleep(2)
                self.driver.find_element_by_xpath("/html/body/form/table/tbody/tr[2]/td/ul/li[2]/div/ul/li/div/ul/li/a").click()# locate information
                time.sleep(2)
                self.PubModuleEle.location("/html/frameset/frameset/frame[2]")
                time.sleep(300)
                self.driver.find_element_by_xpath( "/html/body/div/form/input[2]").click()
                time.sleep(15)
                sysdate=self.driver.find_element_by_id("sys_date").text
                print "the date is %s"%sysdate
                systime=self.driver.find_element_by_id("sys_uptime").text
                print "the time is %s"%systime
  
        
                               
                
