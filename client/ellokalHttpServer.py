#!/usr/bin/python
import tornado.ioloop
import tornado.web
import tornado.websocket
import tornado.gen
import os
import sys
import struct
import binascii
import heapq
import optparse
import signal
import time
import random
import string
import unidecode
import ellokalDatabase
import ellokalSession
import ellokalStorage
import strus
import json
import inspect
import pprint

# Storage instance
storage = None

# [1] HTTP handlers:
class QueryHandler( tornado.web.RequestHandler ):
    @tornado.gen.coroutine
    def get(self):
        try:
            session = ellokalSession.EllokalSession( self)
            db = ellokalDatabase.EllokalDatabase()
            # q = query terms:
            querystr = self.get_argument( "q", "")
            # i = firstrank:
            firstrank = int( self.get_argument( "i", 0))
            # n = nofranks:
            nofranks = int( self.get_argument( "n", 4))
            # d = document number to restrict to:
            restricts = self.get_argument( "d", "").split()
            restrictset = []
            for rs in restricts:
                restrictset.append( int(rs))
            searchresult = storage.evaluateQuery_search( querystr, firstrank, nofranks, restrictset)
            result = yield db.completePictures( searchresult)
            response = { 'error': None,
                         'result': result
            }
            self.write(response)
        except Exception as e:
            response = { 'error': str(e) }
            self.write(response)

class DymHandler( tornado.web.RequestHandler ):
    @tornado.gen.coroutine
    def get(self):
        try:
            session = ellokalSession.EllokalSession( self)
            db = ellokalDatabase.EllokalDatabase()
            # q = query terms:
            querystr = self.get_argument( "q", "")
            # n = nofranks:
            nofranks = int( self.get_argument( "n", 6))
            response = { 'error': None,
                         'result': storage.evaluateQuery_dym( querystr, nofranks)
            }
            self.write(response)
        except Exception as e:
            response = { 'error': str(e) }
            self.write(response)


# [3] Dispatcher:
application = tornado.web.Application([
     # /query in the URL triggers the handler for answering queries:
    (r"/ellokal/query", QueryHandler),
    # /dym in the URL triggers the handler for getting query proposals (did you mean):
    (r"/ellokal/dym", DymHandler)
], cookie_secret
      = ''.join(random.SystemRandom().choice(string.ascii_uppercase + string.digits)
            for _ in range(256))
)

# [4] Server main:
if __name__ == "__main__":
    try:
        # Parse arguments:
        usage = "usage: %prog [options]"
        parser = optparse.OptionParser( usage=usage)
        parser.add_option("-s", "--storage", dest="config", default="path=data/storage",
                          help="Specify the storage configuration as CONFIG (default %s)" % "path=data/storage",
                          metavar="CONFIG")
        parser.add_option("-p", "--port", dest="port", default=80,
                          help="Specify the port of this server as PORT (default %u)" % 80,
                          metavar="PORT")

        (options, args) = parser.parse_args()
        storage = ellokalStorage.Storage( options.config)
        myport = int(options.port)

        # Start server:
        print( "Starting server on port %u with config %s... " % (myport,options.config) )
        application.listen( myport )
        print( "Listening on port %u" % myport )
        ioloop = tornado.ioloop.IOLoop.current()
        ioloop.start()
        print( "Terminated")
    except Exception as e:
        print( e)


