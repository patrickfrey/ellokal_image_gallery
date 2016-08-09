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
import json

storage = None

# [1] HTTP handlers:
class QueryHandler( tornado.web.RequestHandler ):
    @tornado.gen.coroutine
    def get(self):
        try:
            session = ellokalSession.EllokalSession( self)
            db = ellokalDatabase.EllokalDatabase()
            
            response = { 'error': None,
                         'id': storage.evaluateQuery_search( terms, firstrank, nofranks, restrictset):,
                         'username': user.username,
                         'email': user.email }
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
        storage = Storage( options.config)
        myport = int(options.port)

        # Start server:
        print( "Starting server on port %u with config %s... " % (myport,myconfig) )
        application.listen( myport )
        print( "Listening on port %u" % myport )
        ioloop = tornado.ioloop.IOLoop.current()
        ioloop.start()
        print( "Terminated")
    except Exception as e:
        print( e)


