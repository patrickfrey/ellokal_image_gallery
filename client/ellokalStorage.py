import strus
import itertools
import heapq
import re
import collections

# Structure data types:
DymItem = collections.namedtuple('DymItem', ["name","weight"])

class Storage:
    # Create a query evaluation scheme for search:
    def createQueryEval_search( self):
        rt = self.context.createQueryEval()
        # Declare the sentence marker feature needed for abstracting:
        rt.addTerm( "sentence", "sent", "")

        # Declare the feature used for selecting result candidates:
        rt.addSelectionFeature( "selfeat")

        # Query evaluation scheme:
        rt.addWeightingFunction( "BM25pff", {
            "k1": 1.2, "b": 0.75, "avgdoclen": 50,
            "metadata_title_maxpos": "maxpos_title", "metadata_doclen": "doclen",
            "titleinc": 2.4, "tidocnorm": 100, "windowsize": 40, 'cardinality': 3,
            "ffbase": 0.1, "fftie": 10,
            "proxffbias": 0.3, "proxfftie": 20, "maxdf": 0.2,
            ".struct": "sentence", ".match": "docfeat"
        })
        rt.addWeightingFunction( "metadata", {"name": "pageweight" } )

        # Summarizer for getting the document title:
        rt.addSummarizer( "attribute", { "name": "title" })
        # Summarizer for abstracting:
        rt.addSummarizer( "matchphrase", {
            "type": "orig", "metadata_title_maxpos": "maxpos_title",
            "windowsize": 40, "sentencesize": 100, "cardinality": 3, "maxdf": 0.2,
            "matchmark": '$<b>$</b>',
            ".struct": "sentence", ".match": "docfeat", ".para": "para"
        })
        return rt

        # Create a query evaluation scheme for "did you mean" query proposals:
        def createQueryEval_dym( self):
            rt = self.context.createQueryEval()

            # Declare the feature used for selecting result candidates:
            rt.addSelectionFeature( "selfeat")

            # Query evaluation scheme:
            rt.addWeightingFunction( "td", {
                ".match": "docfeat"
            })
            rt.addWeightingFunction( "metadata", {"name": "pageweight" } )

            # Summarizer for getting the document title:
            rt.addSummarizer( "attribute", { "name": "title" })
            return rt

# Constructor. Initializes the query evaluation schemes and the query and document analyzers:
    def __init__(self, config):
        # Open local storage on file with configuration specified:
        self.context = strus.Context()
        self.storage = self.context.createStorageClient( config )
        self.queryeval_search = self.createQueryEval_search()         # search = document search
        self.queryeval_dym = self.createQueryEval_dym()               # dym = did you mean ... ?

    # Query for retrieval of documents:
    def evaluateQuery_search( self, terms, firstrank, nofranks, restrictset):
        if len( terms) == 0:
            # Return empty result for empty query:
            return []
        queryeval = self.queryeval_search
        query = queryeval.createQuery( self.storage)

        selexpr = ["contains"]
        for term in terms:
            selexpr.append( [term.type, term.value] )
            query.defineFeature( "docfeat", [term.type, term.value], 1.0)
        query.defineFeature( "selfeat", selexpr, 1.0 )
        query.setMaxNofRanks( nofranks)
        query.setMinRank( firstrank)
        if (len(restrictset) > 0):
            query.addDocumentEvaluationSet( restrictset )
        # Evaluate the query:
        result = query.evaluate()
        rt = []
        for rank in result.ranks():
            title = ""
            for sumelem in rank.summaryElements():
                if sumelem.name() == 'title':
                    title = sumelem.value()
            rt.append( {
                   'docno':rank.docno(), 'title':title
            })
        return rt

    @staticmethod
    def getCardinality( featlen):
        if (featlen > 5):
            return 4
        elif (featlen > 3):
            return 3
        elif (featlen > 2):
            return 2
        return featlen

    @staticmethod
    def hasPrefixMinEditDist_( s1, p1, s2, p2, dist):
        l1 = len(s1)
        l2 = len(s2)

        while p1 < l1 and p2 < l2:
            if s1[ p1].lower() == s2[ p2].lower():
                pass
            elif dist == 0:
                return false
            # Case 1 - Replace one character in string s1 with one from s2:
            elif hasMinEditDist( s1, p1+1, s2, p2+1, dist-1):
                return true
            # Case 2 - Remove one character from string s1:
            elif hasMinEditDist( s1, p1+1, s2, p2, dist-1):
                return true
            # Case 3 - Remove one character from string s2:
            elif hasMinEditDist( s1, p1, s2, p2+1, dist-1):
                return true
            else:
                return false
        return p1==p2

    @staticmethod
    def hasPrefixMinEditDist( s1, s2, dist):
        return hasPrefixMinEditDist_( s1, 0, s2, 0, dist)

    @staticmethod
    def getDymCandidates( term, candidates):
        rt = []
        for cd in candidates:
            card = 2
            if len( term) < 4:
                card = 1
            if hasPrefixMinEditDist( term, cd, card):
                rt.append( DymItem( cd, candidates[ cd]))
        return rt

    # Query for retrieval of 'did you mean' proposals:
    def evaluateQuery_dym( self, terms, ngrams, nofranks):
        if len( terms) == 0 or len(ngrams) == 0:
            # Return empty result for empty query:
            return []
        queryeval = self.queryeval_search
        query = queryeval.createQuery( self.storage)

        selexpr = ["contains"]
        position = 0
        for term in ngrams:
            if (term.position() != position):
                if (position != 0):
                    query.defineFeature( "selfeat", 0, getCardinality( len(selexpr)-1), selexpr, 1.0 )
                    selexpr = ["contains"]
                position = term.position()
            selexpr.append( [term.type, term.value] )
            query.defineFeature( "docfeat", [term.type, term.value], 1.0)

        query.defineFeature( "selfeat", 0, getCardinality( len(selexpr)-1), selexpr, 1.0 )
        query.setMaxNofRanks( nofranks)

        # Evaluate the query:
        candidates = {}
        result = query.evaluate()
        proposals = []
        for rank in result.ranks():
            for sumelem in rank.summaryElements():
                if sumelem.name() == 'title':
                    for elem in string.split( title):
                        if (candidates.get( elem) == None):
                            candidates[ elem] = rank.weight()
                        else:
                            candidates[ elem] += rank.weight()

        # Get the candidates:
        for term in terms:
            proposals_tmp = []
            for cd in getDymCandidates( term, candidates):
                for res in rt:
                    proposals_tmp.append( DymItem( res.name + " " + cd.name, cd.weight() + res.weight()))
                else:
                    proposals_tmp.append( DymItem( cd.name, cd.weight()))
            proposals,proposals_tmp = proposals_tmp,proposals

        # Sort the result:
        proposals.sort( lambda b: -b.weight())
        rt = []
        nofresults = len(proposals)
        if nofresults > 20:
            nofresults = 20
        for proposal in proposals[ :nofresults]:
            rt.append( proposal.name())
        return rt

