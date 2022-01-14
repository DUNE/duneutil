#!/bin/env python3

import os
from glob import glob as ls

srcs = os.environ['MRB_SOURCE']
dirs = ls('%s/*/'%srcs)

prod_vs = []
for d in dirs:
  with open('%sups/product_deps'%d, 'r') as f:
    found = False
    print(d.split('/')[-2])
    for l in f.readlines():
      if 'end_product_list' in l: break
      if found:
        print(l.split()[:2])
        if l.split()[0] in [pv[0] for pv in prod_vs]: continue
        prod_vs += l.split()[:2]

      if 'product' in l and 'version' in l and '#' not in l:
        found = True
