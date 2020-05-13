	
import paramiko
import os, sys, re
import subprocess, platform


hosts = open("pythoncheckhosts",'r')
fileout = open('py_unameout.txt', 'w')
fileouterr = open('py_unamerr.txt', 'w')

username = "ubuntu"
passw = "ms%a$d@^!"

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

def pkgver():
            stdin, stdout, stderr = client.exec_command('python -V')
            #print(stdout.read().decode())
            pkgver.inf = stdout.read().decode()
            pkgver.err = stderr.read().decode()
            if pkgver.err:
                print(pkgver.err)
            return
#pkgver()

def pkgupd():
                stdin, stdout, stderr = client.exec_command('service nignx status | grep vendor')
 #           print(stdout.read().decode())
            pkgupd.ffxupd = stdout.read().decode()
 #           print(ffxupd)
            pkgupd.err = stderr.read().decode()
            if pkgupd.err:
                    print(pkgupd.err)
            return
#pkgupd()


#print(pkgver.info)
#print(pkgupd.ffxupd)

#no_update = 'No packages marked for update'
#version_check = 'Version     : 68.6.0'
def strmatch():
        matched1 = re.match("Ubuntu SMP Fri", pkgupd.ffxupd)	
        match1 = str(bool(matched1)
        matched2 = re.match("vendor preset: enabled", pkgver.info)	
        match2 = str(bool(matched2))
        return 


#if match1 == "True" and match2 == "True" :
#   print("No Update is required, All uptodate")
#elif match1 == "True" and match2 == "False":
#   print("I will remove and install app now")
#else:
#   print("i have an error")




def pkginst():

   try:
      for host in hosts:
         host=host.strip()
         print ("connecting....", host)
         client.connect(host, username=username, password=passw)
         pkgver()
         print("test")
         pkgupd()
         print("onexec", pkgver.inf)
         print("onexec", pkgupd.ffxupd)
         strmatch()
         if match1 == "True" and match2 == "True" :
              print("No Update is required, All uptodate")
         elif match1 == "True" and match2 == "False":
              print("I will remove and install app now")
         else:
              print("i have an error")
   except:
         print("Authentication Error,%s")
         fileouterr.write(host + "\t "  + "unable to connect sshException" + "\n")
         return pkginst()
pkginst()


 #        stdin, stdout, stderr = client.exec_command('uname -a')
 #        osdist = stdout.read().decode()
 #        stdin, stdout, stderr = client.exec_command("python -c 'import platform; print(platform.python_version())'")
 #        python_version = stdout.read().decode()
 #        fileout.write( host + "\t pyver: " +  python_version + "\t OS-Distro: %s"  % osdist + "\n" )


hosts.close()
client.close()
fileout.close()
