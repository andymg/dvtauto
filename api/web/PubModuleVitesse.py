#!/usr/bin/python
#-*- coding: utf-8 -*-
# Filename: pubModuleVitesse.py
#-----------------------------------------------------------------------------------
#Purpose: This is a Public Module for Vitesse product
#
#
#Notes:
#
#History:
#        04/23/2013- Jefferson Sun,Created
#
#Copyright(c): Transition Networks, Inc.2013
#------------------------------------------------------------------------------------
import sys,os,time,string,socket,re,httplib,base64,random,array,struct,platform
import commands
# import os.path
import telnetlib,pexpect,Queue,threading,ConfigParser,paramiko
from selenium.webdriver.common.action_chains import ActionChains
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import TimeoutException
base = [str(x) for x in range(10)] + [ chr(x) for x in range(ord('A'),ord('A')+6)]
from scapy.all import *

#the PubReadConfig for read config file for auto test
class PubReadConfig:
    #Initializing the object for "PubRedConfig", including config file path
    def __init__(self,configpath=""):
        localpath=os.path.dirname(__file__)
        self.cfpath="%s/config.cfg"%localpath
        ####self.config = ConfigParser.RawConfigParser(allow_no_value=True)####
        self.config = ConfigParser.RawConfigParser()#
        if configpath:
            self.cfpath=configpath
        if os.path.isfile(self.cfpath):
            self.config.read(self.cfpath)
        else:
            print "Cannot find config file at %s!"%self.cfpath
            print "Please check you config file !!!"
            sys.exit()
    
    #return Parameter based on section and parameter options.
    def GetParameter(self,section,parameter):
        print os.path
        if self.HasOptions(section,parameter):
            tempparameter=self.config.get(section, parameter)
            return tempparameter
        else:
            print "Do not find parameter %s in section %s"%(section,parameter)
            return None
    
    def GetSestions(self):
        return self.config.sections()
    
    def HasSection(self,session):
        sename=session
        return self.config.has_section(sename)
    
    def OptionsSection(self,session):
        sename=session
        return self.config.options(sename)
        
    def HasOptions(self,session,option):
        sename=session
        opname=option
        return self.config.has_option(sename, opname)
    
    #return the config path
    def PathOfconfig(self):
        return self.cfpath

#get Mac from ARP
#usage: 
"""
#init
nickname="eth1"
ipdst="192.168.3.53"

#create queue for thread
queue1 = Queue.Queue()

#create queue
proc1 = GetMacInArp("xxx",ipdst,queue1)

#thread start
a=proc1.start() 

#send traffic
p=sendp(Ether()/ARP(op=2,pdst=ipdst),iface=nickname,count=1)
time.sleep(1)

#wait for thread finished
proc1.join()

#To get the MAC
print queue1.get()   
"""
class GetMacInArp(threading.Thread):
    def __init__(self,threadname,ipofDut,queuename,nickname="eth0"):
        threading.Thread.__init__(self, name = threadname)
        self.tpqueue=queuename
        self.ipofDut=ipofDut
        self.nickname=nickname
    
    def arp_monitor_callback(self,pkt):
        if ARP in pkt and pkt[ARP].op in (1,2): #who-has or is-at
#                return pkt.sprintf("%ARP.hwsrc% %ARP.psrc%")
            if self.ipofDut==pkt.sprintf("%ARP.psrc%"):
                self.dutmac=pkt.sprintf("%ARP.hwsrc%")
                self.tpqueue.put(self.dutmac)
        if self.dutmac!=None:
            print "capture successful"
            thread.exit()
                
    def run(self):
        self.dutmac=None
#       sniff(prn=self.arp_monitor_callback, filter="arp", store=10)
        sniff(prn=self.arp_monitor_callback, store=0,iface=self.nickname,timeout=10)
        print "capture timeout"
        self.tpqueue.put(None)

class PubModuleCase:
    #Initializing the object for "PubModuleCase", including "server ip address"
    def __init__(self,DUTIP):
                self.DUTIPAddr = DUTIP
                self.randomValue = 0
                
    #Get the "driver" object from other case module
    def SetPubModuleValue(self,driver):
                self.driver = driver
                
    #Retrieve current browser type.
    def GetBroswerType(self):
                browserType=self.driver.execute_script("return navigator.userAgent.toLowerCase()") 
                print browserType
                if re.search(r'msie',browserType):
                        return 1
                if re.search(r'firefox',browserType):
                        return 2
                if re.search(r'chrome',browserType):
                        return 3
                return 0
            
    #Locate frame which is operated.
    def location(self,value):
		loc_chd = self.driver.current_window_handle
                self.driver.switch_to_window(loc_chd)
		self.driver.switch_to_default_content()
		self.driver.switch_to_frame(self.driver.find_element_by_xpath(value))
        
    #When the operation is wrong, the program will perfom to screenshot.
    def ScreenshotSele(self,value,caseName,prjName):
                timeStr = str(time.strftime("%Y%m%d%H%M%S",time.localtime()))
                rtnpath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.getcwd()))))
                prjName=prjName.upper()
                pngpath = os.path.join(rtnpath,"log",prjName,"WEB")
                isExistPath=os.path.exists(pngpath)
                if not isExistPath:
                        #os.makedirs(pngpath)
                        print "create the screenshot path to save picture"
                strTm = pngpath+"/"+caseName+"-"+timeStr+".png"
                print strTm
                self.driver.get_screenshot_as_file(strTm)
                
    #Switch hex num to dec num.
    def dec2hex(self,num):
                mid = []
                while True:
                     if num == 0: break
                     num,rem = divmod(num, 16)
                     mid.append(base[rem])
                return ''.join([str(x) for x in mid[::-1]])
            
    #When the program end, we need close the file and web driver.
    def end(self):
                print "=============The end============"
		self.driver.quit()
        
    #Get the random number between m and n.
    def GetRandomNumber(self,m,n):
                return random.randint(m,n)
                
    #Set the value of "select" by tag.
    def SetSelectElement(self):
                intValue = random.randint(1,15)
                setValue = "%d"%(intValue)
                WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_tag_name("select"))
                select = Select(self.driver.find_element_by_tag_name("select"))
                select.select_by_visible_text(setValue)
                
    #Get the server connection state the usage: ConnectionServer(username="***",password="***",httpmode="***")default browertype is firefox.
    def ConnectionServer(self,**args):
                self.username = "admin"
                self.password = ""
                self.httpmode="http"
                if args:
                    for temparg in args:
                        if temparg.lower() =="httpmode":
                                self.httpmode = str(args[temparg]).lower()
                        if temparg.lower() =="username":
                                self.username = str(args[temparg])
                        if temparg.lower() =="password":
                                self.password = str(args[temparg])                               
                auth = base64.encodestring("%s:%s" % (self.username, self.password))
                headers = {"Authorization" : "Basic %s" % auth}
                st = 0
                try:
                    IPStr = "%s"%(self.DUTIPAddr)
                    if  self.httpmode =="https":
                        conn = httplib.HTTPSConnection(IPStr,timeout=3)
                    else:
                        conn = httplib.HTTPConnection(IPStr,timeout=3)
                    conn.request("GET", "/navbar.htm", headers=headers)
                    st = conn.getresponse().status
                finally:
                    if st != 200:
                        print "FAILED to connected to %s://%s with username=%s password=%s !"%(self.httpmode,IPStr,self.username,self.password)
                    return st

    def factorydefault(self):
        print "=============factorydefault============"
        self.location("/html/frameset/frameset/frame[1]")
        ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("factory.htm")).perform()
        WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("factory.htm")).click()
        self.location("/html/frameset/frameset/frame[2]")
        time.sleep(5)
        self.driver.find_element_by_xpath("//input[@value='Yes']").click()
        print "DUT will factory Default soon ..."
        time.sleep(1)

                    
#Get the LoginToWeb the usage:                    
#This function should work after ConnectionServer 
    def LoginToWeb(self,browertype="firefox",**args):
        self.brower_type="firefox"
        if args:
            for temparg in args:
                if temparg.lower() =="url":
                    self.addurl = str(args[temparg])
        if self.brower_type=="firefox":
            self.driver = webdriver.Firefox()
        if self.brower_type=="chrome":
            self.driver = webdriver.Chrome()
        print "======opening the brower===== "
        self.domain = "http://%s:%s@%s" %(self.username,self.password,self.DUTIPAddr)
        self.driver.get(self.domain)
        time.sleep(2)
        self.local = self.driver.current_window_handle
        return self.driver 


    #Get the value of "input" component by tag.
    def GetInputElementByValue(self,tag,value):
                inputElement = self.driver.find_elements_by_tag_name(tag)
                for i in inputElement:
                    print "value is: %s" %i.get_attribute("value")
                    InputValue = i.get_attribute("value");
                    if InputValue == value:
                            return i
                            break

    #Make the value of "input" component become to blank.
    def SetInputValue(self,elemName):
                scriptJs = 'document.getElementById("'+elemName+'")'+'.value=""'
                self.driver.execute_script(scriptJs)

    #Make DUT reboot for S3280 and S4140 the usage: DutReboot(mode="fd",httpmode="https") default mode is reboot with http.
    #Return "1" means DUT bootup successful and "0" means bootup fail.This function should work after ConnectionServer                     
    def DutReboot(self,**args):
        self.rthttpmode="http"
        self.rbmode="rb"
        if args:
            for temparg in args:
                if temparg.lower() =="httpmode":
                    self.rthttpmode = str(args[temparg]).lower()           
                if temparg.lower() =="mode":
                    self.rbmode = str(args[temparg]).lower()  
        self.location("/html/frameset/frameset/frame[1]")
        ActionChains(self.driver).move_to_element(self.driver.find_element_by_link_text("Maintenance")).perform()
        WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_link_text("Maintenance")).click()
        if self.rbmode == "fd":
            ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("factory.htm")).perform()
            WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("factory.htm")).click()
            print "DUT will factory Default soon ..."
        else:
            ActionChains(self.driver).move_to_element(self.driver.find_element_by_id("wreset.htm")).perform()
            WebDriverWait(self.driver, 30).until(lambda driver :driver.find_element_by_id("wreset.htm")).click()
            print "DUT will reboot soon ..."
        time.sleep(1)
        self.location("/html/frameset/frameset/frame[2]")
        time.sleep(5)
        self.driver.find_element_by_xpath("//input[@value='Yes']").click()   
        time.sleep(5)
        self.i = 1
        if self.rbmode == "fd":
            while True:
                self.st = self.driver.current_url.find("factory_done")
                if self.st==-1:
                    print "Waiting for DUT bootup ...%d"%self.i
                else:
                    time.sleep(5) 
                    print "DUT factory default successfully!"
                    return 1
                    break
                self.i += 1
                if (self.i == 12):
                    print "DUT can not factory default smoothly.Please check DUT manually!"
                    return 0
                else:
                    time.sleep(5)            
        else:
            while True:
                self.st = self.ConnectionServer(httpmode=self.rthttpmode)
                if self.st != 200:
                    print "Waiting for DUT bootup ...%d"%self.i
                else:
                    time.sleep(5) 
                    print "DUT bootup successfully!"
                    return 1
                    break
                self.i += 1
                if (self.i == 12):
                    print "DUT do not bootup again\n DUT bootup FAIL!"
                    return 0
                else:
                    time.sleep(5)   
                    
#Return DUT MAC and This function should work after ConnectionServer 
    def GetDutMac(self):          
        auth = base64.encodestring("%s:%s" % (self.username, self.password))
        headers = {"Authorization" : "Basic %s" % auth}
        IPStr = "%s"%(self.DUTIPAddr)
        conn = httplib.HTTPConnection(IPStr,timeout=3)
        conn.request("GET", "/stat/sys", headers=headers)
        res = conn.getresponse()
        contentstring=res.read()[0:17].replace("-", ":")
        return contentstring     

#Return the status of using SNMP connect to DUT  
#usage: SnmpToServer(dutip="xxxx",version="2c",community="xxxx")
    def SnmpToServer(self,**args):
        server="%s"%(self.DUTIPAddr)
        snmpversion="2c"
        snmpcommunity="public"
        if args:
            for temparg in args:
                if temparg.lower() =="dutip":
                    server = str(args[temparg])   
                if temparg.lower() =="version":
                    snmpversion = int(args[temparg]) 
                if temparg.lower() =="community":
                    snmpcommunity = str(args[temparg])
        #snmp_session = netsnmp.Session(Version=snmpversion,DestHost=server,Community=snmpcommunity)
        #snmp_session = netsnmp.Session(Version=2,DestHost=server,Community=snmpcommunity)
        #oid_get = netsnmp.Varbind('sysDescr.0')
        #vars1 = netsnmp.VarList(oid_get)
        #result_get = snmp_session.get(vars1)
        #print result_get
        result=commands.getstatusoutput("snmpget -v"+ snmpversion + " -c " + snmpcommunity + " " + server + " sysDescr.0")
        #print result
        if result[0] == 256:
            print "The response of SNMP from DUT is %s"%result[1]
            print "Connect to %s with SNMP mode Version=%s Community=%s failed!"%(server,snmpversion,snmpcommunity)
            return 0
        elif result[0] == 0:
            print "Connect to %s with SNMP mode Version=%s Community=%s successfully"%(server,snmpversion,snmpcommunity)
            return 1

        #if result_get[0]==None:
        #    print "The response of SNMP from DUT is %s"%result_get
        #    print "Connect to %s with SNMP mode Version=%s Community=%s failed!"%(server,snmpversion,snmpcommunity)
        #    return 0
        #else:
        #    print "Connect to %s with SNMP mode Version=%s Community=%s successfully"%(server,snmpversion,snmpcommunity)
        #    return 1

#Return the status of using Telnet connect to DUT  
#usage: TelnetToSserver(dutip="xxxx",username="xxxx",password="xxxx")
    def TelnetToSserver(self,**args):
        host = self.DUTIPAddr
        user = self.username
        password = self.password
        if args:
            for temparg in args:
                if temparg.lower() =="dutip":
                    host = str(args[temparg])   
                if temparg.lower() =="username":
                    user = str(args[temparg])
                if temparg.lower() =="password":
                    password = str(args[temparg])
        try:
            tn = telnetlib.Telnet(host,timeout=3)
            tn.read_until("Username: ",2)
            tn.write(user+'\r')
            tn.read_until("Password: ",2)
            tn.write(password+'\r')
            time.sleep(2)    
        except:
            print "Can not established the Telnet session with DUT %s"%host
            return 0
            sys.exit()

        tn.read_very_eager()
        tn.write('ip'+'\r')
        try:
            tn.read_very_eager()
            print "Login to DUT(%s) Telnet session with Username=%s Password=%s successfully"%(host,user,password)
            return 1
            sys.exit()
        except:
            print "Can not Login to DUT(%s) Telnet session with Username=%s Password=%s"%(host,user,password)
            return 0
            sys.exit()

#Return the status of using Telnet connect to DUT  
#usage: SshToServer(dutip="xxxx",username="xxxx",password="xxxx")
    def SshToServer(self,**args):
        host = self.DUTIPAddr
        user = self.username
        password = self.password
        if args:
            for temparg in args:
                if temparg.lower() =="dutip":
                    host = str(args[temparg]) 
                if temparg.lower() =="username":
                    user = str(args[temparg])
                if temparg.lower() =="password":
                    password = str(args[temparg])
        system = platform.system()
        if system.lower() == "linux":
            ssh = pexpect.spawn('ssh %s@%s'%(user,host))
            time.sleep(8)
            try:
                ssh.expect('password: ',5)
            except:
                ssh.sendline('yes')
                try:
                    ssh.expect('password: ',2)
                except:
                    print "error"
                    sys.exit()
            ssh.sendline(password)
            time.sleep(3)
            try :
                check_user_passwd = ssh.expect('denied',2)
                print "SSH failed,please check your username/passoword"
                ssh.close()
            except:
                print "SSH successfully"
                ssh.close()
        elif system.lower() == "windows":   
            #try:
            #    ssh = paramiko.SSHClient()
            #    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            #    ssh.connect(host,22,user, password)
            #except:
            #    print "SSH failed,please check your username/passoword"
            #    ssh.close()
            #print "SSH successfully"
            #ssh.close()
            pass

#AllInterfaces will return the info of all interface name and related IP address
#########It only support linux system,not recommend to call it
#    def AllInterfaces(self):
#        is_64bits = sys.maxsize > 2**32
#        struct_size = 40 if is_64bits else 32
#        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
#        max_possible = 8 # initial value
#        while True:
#            bytes = max_possible * struct_size
#            names = array.array('B', '\0' * bytes)
#            outbytes = struct.unpack('iL', fcntl.ioctl(s.fileno(),0x8912,  # SIOCGIFCONF
#            struct.pack('iL', bytes, names.buffer_info()[0])
#            ))[0]
#            if outbytes == bytes:
#                max_possible *= 2
#            else:
#                break
#        namestr = names.tostring()
#        return [(namestr[i:i+16].split('\0', 1)[0],
#            socket.inet_ntoa(namestr[i+20:i+24]))
#            for i in range(0, outbytes, struct_size)]
        
#Return TCP SYN result with different IP
#usage: TcpHandShake("1.1.1.1",nickname="xxxx",macsrc="xxxx",macdst="xxxx",ipsrc="xxx",portdest="xxx",portsrc="xxx")
    def TcpHandShake(self,dstip=None,**args):
        #basic parameters
        nickname="eth0"
        ipsrc=None
        if not dstip: 
            ipdst=self.DUTIPAddr
        macsrc=None
        portdest=80
        portsrc=random.randint(1024,65535)
        macdst="ff:ff:ff:ff:ff:ff"
        if args:
            for temparg in args:
                if temparg.lower() =="nickname":
                    nickname = str(args[temparg])
                if temparg.lower() =="macsrc":
                    macsrc = str(args[temparg])
                if temparg.lower() =="macdst":
                    macdst = str(args[temparg])
                if temparg.lower() =="ipsrc":
                    ipsrc = str(args[temparg])      
                if temparg.lower() =="portdest":
                    portdest = int(args[temparg])
                if temparg.lower() =="portsrc":
                    portsrc = int(args[temparg])
        #OS need use Root
        if os.geteuid() != 0:
            print "Please run as root."
            exit()
            return 0
        
        #add IPtable and router for PC
        iptablecommand = "iptables -A OUTPUT -p tcp --tcp-flags RST RST -d "+ipdst+" -j DROP"
        os.system(iptablecommand)
        conf.route.add(host=ipdst,dev=nickname)

        #Send arp and TCP syn packet
        send(ARP(op=2,hwsrc=macsrc,psrc=ipsrc,pdst=ipdst),iface=nickname)
        time.sleep(1)
        TCP_SYN=Ether(src=macsrc)/IP(src=ipsrc,dst=ipdst)/TCP(sport=portsrc,dport=portdest,flags="S",seq=100)
        TCP_SYNACK=sr1(TCP_SYN,retry=-3,timeout=2,iface=nickname)
        ip=IP(src=ipsrc,dst=ipdst)
        
        #To check DUT response
        if TCP_SYNACK is None:
            print "unable to get TCP_SYNACK response"
            print "please check Network configuration"
            return 0
        else:
            if TCP_SYNACK[TCP].flags==18:
                print "DUT return TCP SA"
                my_ack=TCP_SYNACK.seq + 1
                TCP_ACK=TCP(sport=portsrc,dport=portdest,flags="A",seq=101,ack=my_ack)
                send(Ether(src=macsrc,dst=None)/ip/TCP_ACK,iface=nickname)
                time.sleep(1)
                return 1
            else:
                print "Get wrong TCP_SYNACK reponse"
                print "See the received packet blow for details"
                TCP_SYNACK.show()
                return 0
        time.sleep(3)
        
        #Finished works
        os.system('iptables --flush')
        conf.route.resync()
        exit()



        
#MacIncrease1 will return one mac (original mac + 100)
    '''
usage1:
mac="00:00:00:00:00:01"
print MacIncrease1(mac,1) # it will return one mac "00:00:00:00:00:02"
print MacIncrease1(mac,3) # it will return one mac "00:00:00:00:00:04"

usage2:
mac="00:00:00:00:00:00"
x=random.randint(1,1000000) # x is a random num
ranmac=MacIncrease1(mac,x)  #ranmac is a random MAC
    '''
    def MacIncrease1(self,orimac,step):
        step=int(step)
        tempmac=[]
        originmac=orimac.split(":")
        for a in range(0,6):
            tempmac.append(int(originmac[a], 16))
        tempmac[5]=tempmac[5]+step
        temploopnum=5
        for b in range(0,6):
            tempb=temploopnum-b
            if tempmac[tempb]>255:
                tempnum=tempmac[tempb]/256
                tempmac[tempb]=int(tempmac[tempb]%256)
                tempmac[tempb-1]=int(tempmac[tempb-1]+tempnum)
                if tempb==0:
                    for b in range(0,6):
                        tempb=temploopnum-b
                        if tempmac[tempb]>255:
                            tempnum=tempmac[tempb]/256
                            tempmac[tempb]=int(tempmac[tempb]%256)
                            tempmac[tempb-1]=int(tempmac[tempb-1]+tempnum) 
        actmac=[]
        for a in range(0,6):
            strmac ="%X"%tempmac[a]
            if len(strmac)<2:
                strmac ="0%s"%strmac
            actmac.append(strmac)
        str_convert = string.join(actmac,":")
#     actmac=actmac.join()    
        return str_convert.upper()

#MacIncrease will return a list for numbers of mac
    '''
usage:
mac="00:00:00:00:00:01"
x=self.PubModuleEle.MacIncrease(mac,"2") #and list x is include 2 mac:"00:00:00:00:00:01" and mac="00:00:00:00:00:02"
x=self.PubModuleEle.MacIncrease(mac,"3",4) #and list x is include 3 mac:"00:00:00:00:00:01" "00:00:00:00:00:05" and "00:00:00:00:00:09"
support step>1 only 
if step=0 means return many same mac
    '''
    def MacIncrease(self,orimac,numofmac,step=1):
        maclist=[]
        maclist.append(orimac.upper())
        numofmac=long(numofmac)
        step=int(step)
        tempsteps=step
        if re.match("[0-9a-f]{2}([-:])[0-9a-f]{2}(\\1[0-9a-f]{2}){4}$", orimac.lower()):
            for i in range(0,numofmac-1):
                maclist.append(self.MacIncrease1(orimac,tempsteps))
                tempsteps=tempsteps+step
            return maclist
        else:
            print orimac,"Please check format of MAC Address "
            return 0

#GetHwAddr will return PC interface mac
#    '''
#usage:
#print getHwAddr('eth0')
#print getHwAddr('eth1')
#    '''
#    def GetHwAddr(self,ifname):
#        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
#        info = fcntl.ioctl(s.fileno(), 0x8927,  struct.pack('256s', ifname[:15]))
#        return ''.join(['%02x:' % ord(char) for char in info[18:24]])[:-1]

