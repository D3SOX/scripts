#!/usr/bin/python2
import numpy
result = [numpy.random.bytes(1024*1024) for x in xrange(8096*2)]
print len(result)
