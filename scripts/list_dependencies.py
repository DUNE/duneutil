#!/bin/env python3
import os

suite = ['dunecore', 'duneana', 'dunesw', 'dunecalib', 'dunesim', 'duneprototypes',
         'dunereco', 'protoduneana', 'duneopdet', 'dunedataprep',
         'duneexamples', 'duneutil']
dep_files = ['%s/%s/ups/product_deps'%(os.environ['MRB_SOURCE'], s) for s in suite]
print(dep_files)

deps_to_repo = dict()

deps = dict() 
a = 0
for df in dep_files:
  repo = suite[a]
  a += 1
  with open(df, 'r') as f:
    lines = f.readlines()
    found_header = False
    for l in lines:
      if len(l.split()) > 1 and l.split()[0] == 'product' and l.split()[1] == 'version':
        found_header = True
        continue
      elif 'end_product_list' in l:
        break
      if found_header:
        if not l.split()[0] in deps_to_repo.keys():
          deps_to_repo[l.split()[0]] = []
        deps_to_repo[l.split()[0]].append(repo)
        if l.split()[0] in deps.keys(): continue
        if l.split()[0] in suite: continue
        deps[l.split()[0]] = l.split()[1]
print()
for k, v in deps.items():
  print(k, v, deps_to_repo[k])
