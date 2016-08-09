import tornado.web

class EllokalSession:
    def __init__( self, requestHandler):
        self.requestHandler = requestHandler

    def logout( self):
        pass

    def setUserid( self, userid):
        self.requestHandler.set_secure_cookie( "ellokal_userid", str(userid), expires_days=7)

    def getUserid( self):
        return self.requestHandler.get_secure_cookie( "ellokal_userid", value=None, max_age_days=7)


