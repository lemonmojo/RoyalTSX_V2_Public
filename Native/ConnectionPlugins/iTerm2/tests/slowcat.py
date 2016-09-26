#! /usr/bin/python
import sys, time

def usage():
  print "usage: %s [-d delay] [-r count] file [file ...]" % (sys.argv[0])
  print "delay: delay in seconds"
  print "count: number of times to repeat printing files"
  print ""
  print "example: %s -d .02 logfile.txt" % (sys.argv[0])
  sys.exit()

delay = .02
repeat = 1
i = 1
try:
  while i < len(sys.argv):
    n = 0
    flag = sys.argv[i]
    if flag == '-d':
      value = sys.argv[i + 1]
      delay = float(value)
      n = 2
    elif flag == '-r':
      value = sys.argv[i + 1]
      repeat = int(value)
      n = 2
    elif flag == '--':
      i += 1
      break
    else:
      break
    i += n
except Exception, e:
  usage()

def slowcat(filename):
  f = open(filename, 'r')
  contents = f.read()
  if delay <= 0:
    sys.stdout.write(contents)
    sys.stdout.flush()
  else:
    for c in contents:
      sys.stdout.write(c)
      sys.stdout.flush()
      time.sleep(delay)
  f.close()

while repeat != 0:
  repeat -= 1
  for filename in sys.argv[i:]:
    slowcat(filename)

