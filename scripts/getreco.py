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


  #find the runset for the run
  cmd = ["samweb", "list-definitions"]
  p = Popen(cmd, stdout=PIPE, stderr=PIPE)
  stdout, stderr = p.communicate()
  if not stderr:
    for d in stdout.split("\n"):
      if "reco-unified" in d and str(sys.argv[1]) in d: 

        cmd = ["samweb", "list-files", "defname:", d]
      
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
      
              print
              print "Access URLs:"        
              cmd = ["samweb", "get-file-access-url", f, "--schema=xroot"]
              p = Popen(cmd, stdout=PIPE, stderr=PIPE)
              stdout, stderr = p.communicate()
              if not stderr:
                print stdout
  else: print stderr


