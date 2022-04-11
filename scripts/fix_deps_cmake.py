#!/bin/env python3
import os
import sys
from glob import glob as ls
import fileinput

version = sys.argv[1]

print("Fixing product_deps files in %s"%os.environ['MRB_SOURCE'])
print("Updating to larsoft version %s"%version)
suite = ['dunecore', 'duneana', 'dunesw', 'dunecalib', 'dunesim', 'duneprototypes',
         'dunereco', 'protoduneana', 'duneopdet', 'dunedataprep',
         'duneexamples', 'duneutil']
dirs = ['%s/%s/'%(os.environ['MRB_SOURCE'], d) for d in suite]


for d in dirs:
  #if 'duneutil' in d: continue
  dirname = d.split('/')[-2]
  print(d, dirname)

  for line in fileinput.input(d+'CMakeLists.txt', inplace=True):
    #if 'project(%s'%dirname in line:
    if 'CMAKE_PROJECT_VERSION_STRING' in line: 
      split = line.split()
      #split[2] = version.replace('_', '.').strip('v')
      split[1] = version.replace('_', '.').strip('v') + ')'
      print(' '.join(split), end='\n')
    else: print(line, end='')
   
  suite = ['dunecore', 'duneana', 'dunesw', 'dunecalib', 'dunesim', 'duneprototypes',
           'dunereco', 'protoduneana', 'duneopdet', 'dunedataprep',
           'duneexamples', 'duneutil']
  new_suite = suite
  for line in fileinput.input(d+'ups/product_deps', inplace=True):
    found = False
    if 'product' in line and 'version' in line:
      n_spaces = line.find('v')
    for s in suite:
      if s in line and 'parent' not in line:
        split = line.split() 
        split[1] = version
        split.insert(1, ' '*(n_spaces-len(s))) 
        print(''.join(split), end='\n')
        new_suite.remove(s)
        found = True
        break
    if not found:
      print(line, end='')
    suite = new_suite
        
