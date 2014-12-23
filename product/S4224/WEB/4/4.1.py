#!/usr/bin/python
#-*- coding: utf-8 -*-
#filename access_manage.python

from AcessManage import Acess_manage

if __name__ == '__main__':
	a = Acess_manage()
	a.into_manage_web()

	a.add_client()
	a.add_to_full()
	a.del_all()
	a.add_to_full()
	a.reb_check()
	a.factory_default()
	a.CloseSession()
	print "all test is over, Pass!"


