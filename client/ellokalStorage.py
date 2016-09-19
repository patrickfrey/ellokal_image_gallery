import strus
import itertools
import heapq
import re
import collections
import string
import inspect
import re
from pprint import pprint

# Structure data types:
DymItem = collections.namedtuple('DymItem', ["phrase","weight"])
ItemOccupation = collections.namedtuple('ItemOccupation', ["list","weight"])

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
            "k1": 1.2, "b": 0.75, "avgdoclen": 10,
            "metadata_doclen": "doclen",
            ".match": "docfeat"
        })
        rt.addWeightingFunction( "metadata", { "name":"pictureno" });
        rt.addWeightingFormula( "(_0 * 100000) + (sqrt(_1) / 100)", {} );

        # Summarizers:
        rt.addSummarizer( "attribute", { "name": "title" })
        rt.addSummarizer( "attribute", { "name": "docid" })
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
        # Summarizers:
        rt.addSummarizer( "attribute", { "name": "title" })
        rt.addSummarizer( "attribute", { "name": "docid" })
        return rt

    # Constructor. Initializes the query evaluation schemes and the query and document analyzers:
    def __init__(self, config_search, config_dym):
        # Open local storage on file with configuration specified:
        self.context = strus.Context()
        self.storage_search = self.context.createStorageClient( config_search )
        self.storage_dym = self.context.createStorageClient( config_dym )
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
        self.analyzer.definePhraseType(
                    "word", "word_title", "word", 
                    ["lc", [ "convdia", "en"]]
        )

    # Query for retrieval of pictures:
    def evaluateQuery_search_pictures( self, querystr, firstrank, nofranks, restrictset):
        concertids = []
        concertid_search = re.search('([^#]*)[#]([0-9]*)(.*)', querystr);
        while concertid_search:
            concertids.append( int(concertid_search.group(2)));
            querystr = concertid_search.group(1) + concertid_search.group(3);
            concertid_search = re.search('([^#]*)[#]([0-9]*)(.*)', querystr);
        terms = self.analyzer.analyzePhrase( "search", querystr)
        if not terms and not concertids:
            # Return empty result for empty query:
            return []
        queryeval = self.queryeval_search
        query = queryeval.createQuery( self.storage_search)

        docexpr = ["union"]
        if not terms:
            for concertid in concertids:
                query.defineFeature( "docfeat", ['concertid', str(concertid)], 1.0)
        selexpr = ["contains"]
        if concertids:
            for concertid in concertids:
                docexpr.append( ['concertid', str(concertid)] )
            selexpr.append( docexpr)
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
            docid = None
            summary = ""
            for sumelem in rank.summaryElements():
                if sumelem.name() == 'title':
                    title = sumelem.value()
                elif sumelem.name() == 'docid':
                    docid = sumelem.value()
                elif sumelem.name() == 'summary':
                    summary = sumelem.value()
            rt.append( {
                   'weight':rank.weight(), 'id':docid, 'title':title, 'summary':summary
            })
        return rt

    # Query for retrieval of concerts:
    def evaluateQuery_search_concerts( self, querystr, firstrank, nofranks):
        terms = self.analyzer.analyzePhrase( "word", querystr)
        if len( terms) == 0:
            # Return empty result for empty query:
            return []
        queryeval = self.queryeval_dym
        query = queryeval.createQuery( self.storage_dym)

        selexpr = ["contains"]
        for term in terms:
            selexpr.append( [term.type(), term.value()] )
            query.defineFeature( "docfeat", [term.type(), term.value()], 1.0)
        query.defineFeature( "selfeat", selexpr, 1.0 )
        query.setMaxNofRanks( nofranks)
        query.setMinRank( firstrank)
        # Evaluate the query:
        result = query.evaluate()
        rt = []
        for rank in result.ranks():
            title = ""
            docid = None
            for sumelem in rank.summaryElements():
                if sumelem.name() == 'title':
                    title = sumelem.value()
                elif sumelem.name() == 'docid':
                    docid = sumelem.value()
            rt.append( {
                   'weight':rank.weight(), 'id':docid, 'title':title
            })
        return rt

    @staticmethod
    def getCardinality( featlen):
        if (featlen >= 4):
            return 3
        if (featlen >= 2):
            return 2
        return 1

    @staticmethod
    def prefixEditDist_( s1, p1, s2, p2, dist):
        l1 = len(s1)
        l2 = len(s2)

        while p1 < l1 and p2 < l2:
            if s1[ p1].lower() == s2[ p2].lower():
                p1 += 1
                p2 += 1
                pass
            elif dist == 0:
                return -1
            else:
                # Case 1 - Replace one character in string s1 with one from s2:
                rt = Storage.prefixEditDist_( s1, p1+1, s2, p2+1, dist-1)
                if (rt >= 0):
                    return rt + 1
                # Case 2 - Remove one character from string s1:
                rt = Storage.prefixEditDist_( s1, p1+1, s2, p2, dist-1)
                if (rt >= 0):
                    return rt + 1
                # Case 3 - Remove one character from string s2:
                rt = Storage.prefixEditDist_( s1, p1, s2, p2+1, dist-1)
                if (rt >= 0):
                    return rt + 1
                return -1
        if (p1==p2 or p2==l2) and p1==l1:
            return 0
        else:
            return -1

    @staticmethod
    def prefixEditDist( s1, s2):
        dist = 2
        if len( s1) < 4:
            dist = 1
        if len( s1) < 3:
            dist = 0
        return Storage.prefixEditDist_( s1, 0, s2, 0, dist)

    @staticmethod
    def getBestElemOccuppation( terms, elems):
        if not terms:
            return []
        occupation = [ ItemOccupation( [], 0.0)]
        for termidx,term in enumerate(terms):
            tmp_occupation = []
            for elemidx,elem in enumerate( elems):
                dist = Storage.prefixEditDist( term, elem)
                if dist < 0:
                    continue
                for oc in occupation:
                    if not elemidx in oc.list:
                        tmp_occupation.append( ItemOccupation( oc.list + [elemidx], oc.weight + 1.0/(dist+1) ))
            occupation = tmp_occupation
            if not occupation:
                return None
        maxorderdist = 5
        rt = None
        for oc in occupation:
            orderdist = 0
            li = 1
            while li < len(oc.list):
                if oc.list[li] < oc.list[li-1]:
                    oc.list[li-1],oc.list[li] = oc.list[li],oc.list[li-1]
                    orderdist += 1
                    if orderdist > maxorderdist:
                        return None
                    if li > 1:
                        li -= 1
                else:
                    li += 1
            if oc.list:
                orderdist += oc.list[0] + oc.list[-1] - len(oc.list) + 1
            weight = (0.75 * oc.weight) + (0.25 * oc.weight / (orderdist+3))
            if not rt or rt.weight < weight:
                rt = ItemOccupation( oc.list, weight)
        return rt

    # Query for retrieval of 'did you mean' proposals:
    def evaluateQuery_dym( self, querystr, nofranks):
        # Analyze query:
        ngrams = self.analyzer.analyzePhrase( "dym", querystr)
        words  = self.analyzer.analyzePhrase( "word", querystr)
        if not words or not ngrams:
            # Return empty result for empty query:
            return []
        querystr = re.sub(r'([^a-zA-Z0-9])', " ", querystr)
        terms = querystr.split()
        queryeval = self.queryeval_dym
        query = queryeval.createQuery( self.storage_dym)

        selexprlist = []

        selexpr = ["contains", 0, 0]
        position = 0
        prev_first = None
        this_first = None
        for term in ngrams:
            if (term.position() != position):
                prev_first,this_first = this_first,term
                if (position != 0):
                    selexpr[2] = self.getCardinality( len(selexpr)-3)
                    selexprlist.append( selexpr)
                    selexpr = ["contains", 0, 0]
                    query.defineFeature( "docfeat", ["sequence", 1, [prev_first.type(), prev_first.value()], [term.type(), term.value()]], 1.5)
                position = term.position()
                if prev_first:
                    for term in words:
                        if (term.position() == prev_first.position()):
                            query.defineFeature( "docfeat", ["sequence", 1, [term.type(), term.value()], [this_first.type(), this_first.value()]], 2.5)
            selexpr.append( [term.type(), term.value()] )
            query.defineFeature( "docfeat", [term.type(), term.value()], 1.0)

            selexpr[2] = self.getCardinality( len(selexpr)-3)
            selexprlist.append( selexpr)

            for term in words:
                prev_first,this_first = this_first,term
                query.defineFeature( "docfeat", [term.type(), term.value()], 3.0)

            query.defineFeature( "selfeat", ["union"] + selexprlist, 1.0 )

            query.setMaxNofRanks( nofranks)

            # Evaluate the query:
            result = query.evaluate()
            dymitems = []

            for rank in result.ranks():
                for sumelem in rank.summaryElements():
                    if sumelem.name() == 'title':
                        sumweight = 0.0
                        weight = rank.weight()
                        occupied = []
                        title = re.sub(r'([^a-zA-Z0-9])', " ", sumelem.value())
                        elems = title.split()
                        occupation = Storage.getBestElemOccuppation( terms, elems)
                        if occupation is None:
                            continue
                        dymitems.append( DymItem( sumelem.value(), occupation.weight * rank.weight()))

            dymitems.sort( key=lambda b: b.weight, reverse=True)
            weight = None
            for dymidx,dymitem in enumerate(dymitems):
               if weight is None:
                   weight = dymitem.weight
               elif (weight > dymitem.weight + dymitem.weight / 2):
                   dymitems = dymitems[ :dymidx]
                   break

            # Get the results:
            rt = []
            duplicates = {}
            for dymitem in dymitems:
                dupkey = dymitem.phrase.strip().lower()
                if not duplicates.get( dupkey):
                    rt.append( dymitem.phrase)
                    duplicates[ dupkey] = 1
            return rt

