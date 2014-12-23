
import threading,time
from log import ConfigCase
import sys,os,time,string,socket,re,random
from PubModuleVitesse import PubModuleCase
from PubModuleVitesse import PubReadConfig
#global Config
#---------------------------------import public parameters-----------
def ChkInputVal():
    print ("Get parameters from Configuration file")
    getconfig = PubReadConfig()
    global caseName
    caseName = sys.argv[0]
    caseName = caseName[:-3]
    global prjName
    prjName = getconfig.GetParameter("DUT1","PRODUCT")
    global brserType
    brserType=getconfig.GetParameter("PC","BRWSRTYPE")
    global DUTIP
    DUTIP = getconfig.GetParameter("DUT1","IP")
    global srvaddr
    srvaddr = getconfig.GetParameter("PC","MGMTIP")
def PrtInputVal():
    print "\n*******************Parameters********************"
    print "\nThe case name is: "+sys.argv[0]
    print "\nThe project name is: "+prjName
    print "\nThe broswer type is: "+brserType
    print "\nThe IP address is: "+DUTIP
    print "\n*******************Parameters********************"
#----------------------------------------------------------------------
def StartPerformMainPro(caseName,prjName,brserType,DUTIP):
    print "=====startPerformMainPro===="
    print"sys.path"
    
    Config = ConfigCase(brserType,DUTIP)
    try:
        Config.StartWebConfig(prjName)
        Config.engineConfigLog(srvaddr)
        threads = []
        func = []
        time.sleep(3)
        for i in xrange(2):
            if i == 0:
                threads.append(threading.Thread(target=Config.PubModuleEle.DutReboot))
                pass
            if i == 1:
                threads.append(threading.Thread(target=Config.CapSyslog))
        for i in xrange(2):
            threads[i].start()
        for i in xrange(2):
            threads[i].join()  	
    except:
        print "FAIL"
    Config.PubModuleEle.end()
        
if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP)
    print  "PASS"   
