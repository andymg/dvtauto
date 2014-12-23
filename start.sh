#!/bin/bash

echo "=============initialize Automation Platform============"
#check the current system verison
#cat /proc/version


#$ lsb_release -a {don't usually, special debian}
#No LSB modules are available.
#Distributor ID: Ubuntu
#Description:    Ubuntu 12.04.1 LTS
#Release:        12.04
#Codename:       precise

#jeff@dvtauto:~$ uname -r | cat /etc/issue
#Ubuntu 12.04.1 LTS \n \l
#Debian GNU/Linux 6.0 \n \l

echo "======please be patient as this may take some time====="
echo "========start to check Tcl/Tk=============="

echo "========start to check Perl installation && version==========="
#check if perl has been installed
#$ whereis perl
#perl: /usr/bin/perl /etc/perl /usr/lib/perl /usr/bin/X11/perl /usr/share/perl /usr/share/man/man1/perl.1.gz
#$which perl
#/usr/bin/perl

#ls /bin /usr/bin /usr/local/bin | grep -i perl

#check perl version
perl -le 'print $]'

#check perl module 
#perldoc module

#jeff@dvtauto:~$ perldoc snmp
#You need to install the perl-doc package to use this program.

#perl -le "use module"

echo "========start to check Python installation && version========="

#check python version
python -V 2>&1 | awk '{print $2}'

# or other ways to verify
#jeff@dvtauto:~$ python -c 'import platform; print platform.python_version()'
#2.7.3
#jeff@dvtauto:~$ python -c 'import sys; print sys.version' 2>&1
#2.7.3 (default, Aug  1 2012, 05:14:39)
#[GCC 4.6.3]
#jeff@dvtauto:~$ python -c 'import sys; print sys.version' 2>&1 | awk '$1~/[0-9]\.[0-9].*/{print $1}'
#2.7.3
echo "----------------------check net-snmp install or not---------------------------------
