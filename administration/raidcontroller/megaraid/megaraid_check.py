#!/usr/bin/env python

import sys
import codecs
import collections
import re

sys.stdin = codecs.getreader('utf8')(sys.stdin)
sys.stdout = codecs.getwriter('utf8')(sys.stdout)

diskinfo_status = collections.namedtuple('diskinfo_status', ['id','model','status'])
arrayinfo_status = collections.namedtuple('arrayinfo_status', ['id','type','size','status','inprogress'])
controllerinfo_status = collections.namedtuple('controllerinfo_status', ['id','model'])

ctrl_full_nfo = collections.namedtuple('ctrl_full_nfo', ['info', 'array'])
arry_full_nfo = collections.namedtuple('arry_full_nfo', ['status', 'info', 'disk'])
disk_full_nfo = collections.namedtuple('disk_full_nfo', ['status', 'info'])

def parse_disk_status(string):
  disk_raw = re.findall(r'(.*) \| (.*) \| (.*)', string)[0]
  return diskinfo_status(disk_raw[0], disk_raw[1], disk_raw[2])


def parse_array_status(string):
  array_raw = re.findall(r'(.*) \| (.*) \| (.*) \| (.*) \| (.*)', string)[0]
  return arrayinfo_status(array_raw[0],array_raw[1],array_raw[2],array_raw[3],array_raw[4])

def parse_controller_status(string):
  ctrl_raw = re.findall(r'(.*) \| (.*)', string)[0]
  return controllerinfo_status( ctrl_raw[0], ctrl_raw[1] )

def parse_status(stringlist):
  #{{{
  controllers = []
  arrays = []
  disks = []
  for l in stringlist:
    l = l.strip()
    if l.startswith('--'): continue
    if l.count('|') == 1: #ctrlinfos
      controllers.append(parse_controller_status(l))
    if l.count('|') == 4: #arrayinfos
      arrays.append(parse_array_status(l))
    if l.count('|') == 2: #diskinfos
      disks.append(parse_disk_status(l))
  disk_map = dict([ (d.id, d) for d in disks])
  ctrl_map = dict([ (c.id, c) for c in controllers])
  arry_map = dict([ (a.id, a) for a in arrays])
  return (ctrl_map, arry_map, disk_map)
  #}}}

def full_status(controllers, arrays, disks):
  #print arrays
  ctrl = {}
  for idc,c in controllers.items():
    #ctrl[idc] = {'info' : c, 'array' : {}}
    ctrl[idc] = ctrl_full_nfo(info = c, array = {})
    for ida,a in arrays.items():
      if ida.startswith(idc):
        arr_id = ida.replace(idc,'')
        ctrl[idc].array[arr_id] =  arry_full_nfo(status = a.status, info = a, disk = {})
        for idd,d in disks.items():
          if idd.startswith(ida):
            dsk_id = idd.replace(ida,'')
            ctrl[idc].array[arr_id].disk[dsk_id] = disk_full_nfo(status = d.status, info = d)
  print(ctrl)

def simple_status(controllers, arrays, disks):
  failed_disks = dict([ (dsk_id,dsk_nfo) for dsk_id,dsk_nfo in disks.items() if dsk_nfo.status.lower() != "online"])
  failed_items = []
  for fid,fd in failed_disks.items():
    for cid,c in controllers.items():
      if fid.startswith(cid):
        for aid,a in arrays.items():
          if aid.startswith(cid):
            failed_items.append((c,a,fd))
            pass
  critical_threshold = 3
  warning_threshold = 1
  RETURN_STATE = 'CRITICAL'
  if len(failed_items) < critical_threshold:
    RETURN_STATE = 'WARNING'
  if len(failed_items) < warning_threshold:
    RETURN_STATE = 'OK'
  
  for fi in failed_items:
    c,a,d = fi
    s = "controller: %s (%s), array: %s (%s,%s,%s), disk: %s (%s)" % (c.id,c.model,a.id,a.status,a.type,a.size,d.id,d.status)
    print(s)
  pass


def demo_input():
  return [l for l in sys.stdin if len(l.strip())]

if __name__ == "__main__":
  simple_status(* parse_status(demo_input()))
  #full_status(* parse_status(demo_input()))
