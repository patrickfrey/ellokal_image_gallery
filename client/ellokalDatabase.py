import tornado.ioloop
import tornado.web
import tornado.gen
import collections
import psycopg2
from passlib.apps import custom_app_context as pwd_context

# Structure data types:
PicureRow = collections.namedtuple('PicureRow', ["id","concertId","focaldist","apperture","shutterspeed","insertdate","eventdate","program","resolution_X","resolution_Y","width","length","meta","fotographer","thumbnail","filename","summary","weight"])

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
    def getPictures( self, idlist, startindex, nofranks):
        dbquery = 'SELECT id,concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename FROM ConcertPicture'
        whereclause = ''
        if (idlist):
            whereclause += "id IN ("
            idx = 0
            for id in idlist:
                if (idx++ > 0):
                    whereclause += ','
                whereclause += string(id)
            whereclause += ")"
            dbquery += " WHERE " + whereclause
        }
        self.cursor.execute( dbquery )
        result = self.cursor.fetchmany( startindex + nofranks)
        raise tornado.gen.Return( result[ startindex: ] )


