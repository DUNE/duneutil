from subprocess import Popen, PIPE
import sys

command = ["getfile.py", str(sys.argv[1]), str(sys.argv[2])]

p = Popen(command, stdout=PIPE, stderr=PIPE)
stdout, stderr = p.communicate()

if not stderr:
  #should just be one line
  line = stdout.split("\n")[0]
  print "Raw: ", line 
  
  nskip = line.split(" ")[1:] 
  raw = line.split(" ")[0]
  sub = raw.split("_")[3] + "_" + raw.split("_")[4].strip(".root")

  cmd = ["samweb", "list-files", "defname:", sys.argv[3]]

  p = Popen(cmd, stdout=PIPE, stderr=PIPE)
  stdout, stderr = p.communicate()
  if not stderr:
    for f in stdout.split("\n"):
      if raw.strip(".root") in f: 
        print "Reco:", f, nskip[0], nskip[1] 
        print
        print "Locations:"

        cmd = ["samweb", "locate-file", f]
        p = Popen(cmd, stdout=PIPE, stderr=PIPE)
        stdout, stderr = p.communicate()
        if not stderr:
          print stdout
