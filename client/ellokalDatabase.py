import tornado.ioloop
import tornado.web
import tornado.gen
import collections
import psycopg2
from passlib.apps import custom_app_context as pwd_context
import pprint
import inspect

class EllokalDatabase:
    def __init__( self):
        self.conn = psycopg2.connect( host="localhost", dbname="ellokaldb", user="ellokal", password="1w5b5ufh")
        self.cursor = self.conn.cursor()

    def close( self):
        self.cursor.close()
        self.conn.close()

    def commit( self):
        self.conn.commit()

    # QUERY:
    @tornado.gen.coroutine
    def completePictures( self, ranks):
        rt = []
        if not ranks:
            raise tornado.gen.Return( rt);
        dbquery = 'SELECT id,concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename FROM ConcertPicture WHERE id IN ('
        rttab = {}
        for idx,rank in enumerate(ranks):
            if (idx > 0):
                dbquery += ','
            dbquery += str( rank['docno'])
            rttab[ rank['docno']] = rank
        dbquery += ");"
        self.cursor.execute( dbquery )
        dbresults = self.cursor.fetchmany( len(ranks))
        for dbres in dbresults:
            rtelem = rttab[ dbres[0]]
            rtelem['id'] = dbres[0]
            rtelem['concertId'] = dbres[1]
            rtelem['focaldist'] = dbres[2]
            rtelem['apperture'] = dbres[3]
            rtelem['shutterspeed'] = dbres[4]
            rtelem['insertdate'] = dbres[5].strftime("%d.%m.%Y %H:%M")
            rtelem['eventdate'] = dbres[6]
            rtelem['program'] = dbres[7]
            rtelem['resolution_X'] = dbres[8]
            rtelem['resolution_Y'] = dbres[9]
            rtelem['width'] = dbres[10]
            rtelem['length'] = dbres[11]
            rtelem['meta'] = dbres[12]
            rtelem['fotographer'] = dbres[13]
            rtelem['thumbnail'] = dbres[14]
            rtelem['filename'] = dbres[15]
            rttab[ dbres[0]] = rtelem
        for rank in ranks:
            rt.append( rttab[ rank['docno']])
        raise tornado.gen.Return( rt )


