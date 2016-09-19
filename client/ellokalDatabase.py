import tornado.ioloop
import tornado.web
import tornado.gen
import collections
import psycopg2
from passlib.apps import custom_app_context as pwd_context
from pprint import pprint
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
    def completePictures( self, ranks, mode, picsize, lang):
        rt = []
        if not ranks:
            raise tornado.gen.Return( rt);
        dbquery = 'SELECT id,concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename,'
        if (lang == 'de'):
            dbquery += 'description_de'
        else:
            dbquery += 'description_en'
        dbquery += ' FROM ConcertPicture WHERE id IN ('
        rttab = {}
        for idx,rank in enumerate(ranks):
            if (idx > 0):
                dbquery += ','
            dbquery += str( rank['id'])
            rttab[ int( rank['id'])] = rank
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
            rtelem['eventdate'] = dbres[6].split()[0];
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
            rt.append( rttab[ rank['id']])
        if rt and mode == 1:
            dbquery = "SELECT image FROM ConcertPictureImg WHERE pictureId = '%s' AND size='%s'" % (rt[0]['id'], picsize)
            self.cursor.execute( dbquery )
            (image,) = self.cursor.fetchone()
            rt[0]['image'] = image
        raise tornado.gen.Return( rt )

    @tornado.gen.coroutine
    def pictureList( self, firstrank, nofranks, mode, picsize, lang):
        rt = []
        dbquery = 'SELECT ConcertPicture.id AS pictureId,concertId,title,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename,'
        if (lang == 'de'):
            dbquery += 'ConcertPicture.description_de'
        else:
            dbquery += 'ConcertPicture.description_en'
        dbquery += ' FROM ConcertPicture,Concert WHERE Concert.id = concertId ORDER BY eventdate DESC,pictureId DESC;';
        self.cursor.execute( dbquery )
        dbresults = self.cursor.fetchmany( firstrank + nofranks)
        for dbres in dbresults[ firstrank:]:
            rtelem = { "id":dbres[0], "concertId":dbres[1], "title":dbres[2], "focaldist":dbres[3], "apperture":dbres[4], 
                       "shutterspeed":dbres[5], "insertdate":dbres[6].strftime("%d.%m.%Y %H:%M"),
                       "eventdate":dbres[7].split()[0], "program":dbres[8], "resolution_X":dbres[9], "resolution_Y":dbres[10],
                       "width":dbres[11], "length":dbres[12], "meta":dbres[13], "fotographer":dbres[14],
                       "thumbnail":dbres[15], "filename": dbres[16] }
            rt.append( rtelem)
        if rt and mode == 1:
            dbquery = "SELECT image FROM ConcertPictureImg WHERE pictureId = '%s' AND size='%s'" % (rt[0]['id'], picsize)
            self.cursor.execute( dbquery )
            (image,) = self.cursor.fetchone()
            rt[0]['image'] = image
        raise tornado.gen.Return( rt )

    @tornado.gen.coroutine
    def concertList( self, first, nof, lang, restrictlist):
        rt = []
        dbquery = 'SELECT id,date,title,';
        if (lang == 'de'):
            dbquery += 'description_de'
        else:
            dbquery += 'description_en'
        restriction = ""
        if restrictlist:
            restriction = "WHERE ID IN (";
            for ri,rr in enumerate(restrictlist):
                if (ri):
                    restriction += ',';
                restriction += str(rr)
            restriction += ')';
        dbquery += ' FROM Concert %s ORDER BY id DESC' % restriction
        self.cursor.execute( dbquery )
        dbresults = self.cursor.fetchmany( first + nof)[ first:]
        for dbres in dbresults:
            rt.append({ "id":dbres[0], "date":dbres[1].strftime("%d.%m.%Y"), "title":dbres[2], "description":dbres[3] })
        raise tornado.gen.Return( rt )


