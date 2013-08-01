#!/usr/bin/env python
"""Clones/Updates/Deletes a number of Repos read from a repo list file.

@author: Alexander Kuemmel
@email:  akisys@alexanderkuemmel.com
"""

import datetime
import pwd
import os
import sys
import re
import subprocess
import shutil
import glob
import gzip

# global configuration vars
run_as_user = "www-data"
clone_dir = os.path.dirname(os.path.abspath(__file__))
repolist_file = clone_dir + "/repolist.txt"
log_file = clone_dir + "/repolist.log"
max_log_size = 20480 # 20 KBytes

def clone_repos():
  """Read repolist and check for already cloned repos, mark them with 'i'"""
  with open(repolist_file, "r+") as repofile:
    repolist = repofile.readlines()
    for idx in range(0,len(repolist)):
      l = repolist[idx].strip()
      if re.match('^[^\six#]',l):
        # clone repo
        repo = l
        if not git("clone", "--mirror", repo, cwd = clone_dir):
          continue
        # mark as cloned
        repo = "i {0}\n".format(repo)
        repolist[idx] = repo
    repofile.seek(0)
    repofile.truncate(0)
    repofile.flush()
    repofile.writelines(repolist)
  pass

def remove_old_repos():
  """Read repolist and remove everything that's marked with leading 'x'"""
  with open(repolist_file, "r+") as repofile:
    repolist = repofile.readlines()
    rm_indices = []
    for idx in xrange(len(repolist)):
      l = repolist[idx].strip()
      if re.match('^[x]',l):
        repodir = clone_dir + "/" + os.path.basename(l)
        shutil.rmtree(repodir, ignore_errors=True)
        rm_indices.append(idx)
    for i in rm_indices:
      del repolist[i]
    repofile.seek(0)
    repofile.truncate(0)
    repofile.flush()
    repofile.writelines(repolist)
  pass

def update_repos():
  """Read repolist and update all cloned (marked 'i') repos"""
  with open(repolist_file, "r") as repofile:
    repolist = repofile.readlines()
    for idx in xrange(len(repolist)):
      l = repolist[idx].strip()
      if re.match('^[i]',l):
        repodir = clone_dir + "/" + os.path.basename(l)
        git("fetch", "--all", cwd = repodir)
  pass

def git(*args, **kwargs):
  """Simple Git subprocess frontend"""
  if 'cwd' not in kwargs:
    kwargs['cwd'] = clone_dir
  with open(log_file, "a+") as logoutput:
    now = datetime.datetime.now()
    logoutput.write("{0}\n".format(str(now)))
    kwargs['stdout'] = logoutput
    kwargs['stderr'] = logoutput
    kwargs['universal_newlines'] = True
    p = subprocess.Popen(['git'] + list(args), **kwargs)
    p.communicate()
    if p.returncode:
      return False
    return True
  pass

def log_rotate():
  """Checks logfile size and compresses if necessary"""
  st = os.stat(log_file)
  if st.st_size >= max_log_size:
    logfiles = glob.glob("{0}/{1}.[0-9].gz".format(clone_dir,os.path.basename(log_file)))
    for i in xrange(len(logfiles),0,-1):
      oldlog = logfiles[i-1]
      newlog = "{0}.{1}.gz".format(oldlog[:-5],i)
      os.rename(oldlog,newlog)
    f_in = open(log_file, "r+b")
    f_out = gzip.open(log_file + ".0.gz", "wb")
    f_out.writelines(f_in)
    f_out.close()
    f_in.seek(0)
    f_in.truncate(0)
    f_in.close()
  pass

if __name__ == "__main__":
  # check user id
  if not os.getuid() == pwd.getpwnam(run_as_user).pw_uid:
    print("Will only execute as user: {0}".format(run_as_user))
    sys.exit(1)
    pass
  clone_repos()
  update_repos()
  remove_old_repos()
  log_rotate()
  pass

