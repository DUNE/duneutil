#!/usr/bin/env python

from __future__ import print_function

# Creation Date : 2013-10-28, Qizhong Li
# upgraded to be python2 and python 3 compatible by Tom Junk. Only modified print statements

import os, sys
import samweb_client

Project = sys.argv[1]
Destination = sys.argv[2]

samweb = samweb_client.SAMWebClient(experiment='lbne')

def testProject(defname="project", appFamily="demo", appName="demo", appVersion="demo"):

    projectname = samweb.makeProjectName(defname)
    projectinfo = samweb.startProject(projectname, defname)
    projecturl = projectinfo["projectURL"]
    print ("Project name is %s" % projectinfo["project"])
    print ("Project URL is %s" % projecturl)

    deliveryLocation = None # set this to a specific hostname if you want - default is the local hostname
    cpid = samweb.startProcess(projecturl, appFamily, appName, appVersion, deliveryLocation)
    print ("Consumer process id %s" % cpid)
    processurl = samweb.makeProcessUrl(projecturl, cpid)
    print ("Process URL is %s" % processurl)

    while True:
        try:
            newfile = samweb.getNextFile(processurl)['url']
            print ("Got file %s" % newfile)
            print ("Attempting globus-url-copy to scratch...")
            stat = os.system('globus-url-copy %s %s' % (newfile,Destination))
        except samweb_client.NoMoreFiles:
            print ("No more files available")
            break

        samweb.releaseFile(processurl, newfile)
        print ("Released file %s" % newfile)

    samweb.stopProject(projecturl)
    print samweb.projectSummaryText(projecturl)
    print ("Project ended")

if __name__ == '__main__':

    testProject(defname=Project)



# vim 73
