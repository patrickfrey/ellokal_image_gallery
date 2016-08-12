import strus
import itertools
import heapq
import re
import collections
import string
import inspect

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
        rt.addWeightingFunction( "BM25", {
            "k1": 1.2, "b": 0.75, "avgdoclen": 50,
            "metadata_doclen": "doclen",
            ".match": "docfeat"
        })

        # Summarizer for getting the document title:
        rt.addSummarizer( "attribute", { "name": "title" })
        # Summarizer for abstracting:
        rt.addSummarizer( "matchphrase", {
            "type": "orig", "metadata_title_maxpos": "maxpos_title",
            "windowsize": 40, "sentencesize": 100, "cardinality": 3, "maxdf": 0.2,
            "matchmark": '$<b>$</b>', "name_phrase": "summary",
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
        self.analyzer = self.context.createQueryAnalyzer()
        self.analyzer.definePhraseType(
                    "search", "word_en", "word", 
                    ["lc", ["stem", "en"], ["convdia", "en"], "lc"]
        )
        self.analyzer.definePhraseType(
                    "search", "word_de", "word", 
                    ["lc", ["stem", "de"], ["convdia", "de"], "lc"]
        )
        self.analyzer.definePhraseType(
                    "dym", "ngram_title", "word", 
                    ["lc", [ "ngram", "WithStart", 3]]
        )

    # Query for retrieval of documents:
    def evaluateQuery_search( self, querystr, firstrank, nofranks, restrictset):
        terms = self.analyzer.analyzePhrase( "search", querystr)
        if len( terms) == 0:
            # Return empty result for empty query:
            return []
        queryeval = self.queryeval_search
        query = queryeval.createQuery( self.storage)

        selexpr = ["contains"]
        for term in terms:
            selexpr.append( [term.type(), term.value()] )
            query.defineFeature( "docfeat", [term.type(), term.value()], 1.0)
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
            summary = ""
            for sumelem in rank.summaryElements():
                if sumelem.name() == 'title':
                    title = sumelem.value()
                elif sumelem.name() == 'summary':
                        summary = sumelem.value()
            rt.append( {
                   'weight':rank.weight(), 'docno':rank.docno(), 'title':title, 'summary':summary
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
                p1 += 1
                p2 += 1
                pass
            elif dist == 0:
                return False
            # Case 1 - Replace one character in string s1 with one from s2:
            elif Storage.hasPrefixMinEditDist_( s1, p1+1, s2, p2+1, dist-1):
                return True
            # Case 2 - Remove one character from string s1:
            elif Storage.hasPrefixMinEditDist_( s1, p1+1, s2, p2, dist-1):
                return True
            # Case 3 - Remove one character from string s2:
            elif Storage.hasPrefixMinEditDist_( s1, p1, s2, p2+1, dist-1):
                return True
            else:
                return False
        return p1==p2

    @staticmethod
    def hasPrefixMinEditDist( s1, s2, dist):
        return Storage.hasPrefixMinEditDist_( s1, 0, s2, 0, dist)

    @staticmethod
    def getDymCandidates( term, candidates):
        rt = []
        for cd in candidates:
            card = 2
            if len( term) < 4:
                card = 1
            if Storage.hasPrefixMinEditDist( term, cd, card):
                rt.append( DymItem( cd, candidates[ cd]))
        return rt

    # Query for retrieval of 'did you mean' proposals:
    def evaluateQuery_dym( self, querystr, nofranks):
        terms = querystr.split()
        ngrams = self.analyzer.analyzePhrase( "dym", querystr)
        if len( terms) == 0 or len(ngrams) == 0:
            # Return empty result for empty query:
            return []
        queryeval = self.queryeval_dym
        query = queryeval.createQuery( self.storage)

        selexpr = ["contains", 0, 0]
        position = 0
        for term in ngrams:
            if (term.position() != position):
                if (position != 0):
                    selexpr[2] = self.getCardinality( len(selexpr)-3)
                    query.defineFeature( "selfeat", selexpr, 1.0 )
                    selexpr = ["contains", 0, 0]
                position = term.position()
            selexpr.append( [term.type(), term.value()] )
            query.defineFeature( "docfeat", [term.type(), term.value()], 1.0)

        selexpr[2] = self.getCardinality( len(selexpr)-3)
        query.defineFeature( "selfeat", selexpr, 1.0 )
        query.setMaxNofRanks( nofranks)

        # Evaluate the query:
        candidates = {}
        result = query.evaluate()
        proposals = []
        for rank in result.ranks():
            for sumelem in rank.summaryElements():
                if sumelem.name() == 'title':
                    for elem in string.split( sumelem.value()):
                        weight = candidates.get( elem)
                        if (weight == None or weight < rank.weight()):
                            candidates[ elem] = rank.weight()

        # Get the candidates:
        for term in terms:
            proposals_tmp = []
            cdlist = self.getDymCandidates( term, candidates)
            for cd in cdlist:
                for prp in proposals:
                    proposals_tmp.append( DymItem( prp.name + " " + cd.name, cd.weight + prp.weight))
                else:
                    proposals_tmp.append( DymItem( cd.name, cd.weight))
            proposals,proposals_tmp = proposals_tmp,proposals

        # Sort the result:
        proposals.sort( key=lambda b: b.weight, reverse=True)
        rt = []
        nofresults = len(proposals)
        if nofresults > 20:
            nofresults = 20
        for proposal in proposals[ :nofresults]:
            rt.append( proposal.name)
        return rt

