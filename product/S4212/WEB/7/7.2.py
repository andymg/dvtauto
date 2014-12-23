from log import ConfigCase
import sys,os,time,string,socket,re,random
from PubModuleVitesse import PubModuleCase
from PubModuleVitesse import PubReadConfig
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
        Config.SyslogTest(1)
        Config.SyslogTest(2)			
    except:
        print "FAIL"
    time.sleep(2)  
    Config.PubModuleEle.end()
        
if __name__ == "__main__":
    ChkInputVal()
    PrtInputVal()
    StartPerformMainPro(caseName,prjName,brserType,DUTIP)
    print  "PASS"
    #sys.exit()  
