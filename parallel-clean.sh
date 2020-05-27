#!/usr/bin/env bash

awkg -F '\t' -b 'from html import unescape; goods, bads = 0, 0' '
good = len(R) == 2
if good:
  src = R[0].strip()
  tgt = R[1].strip()
  good &= "http" not in src and "http" not in tgt
  src = unescape(src).split()
  tgt = unescape(tgt).split()
  good &= 1 <= len(src) <= 512 and 1 <= len(tgt) <= 512
  good &= 1/5 <= len(src)/len(tgt) <= 5
  good &= max(len(w) for w in src + tgt) < 30 

if good:
   goods += 1
   print(" ".join(src), " ".join(tgt))
else:
   bads += 1

# if not good: # print bad
#  print(R0)
' -e 'sys.stderr.write(f"good={goods:,} bad={bads:,} records")'
