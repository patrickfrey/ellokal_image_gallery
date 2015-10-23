<!DOCTYPE html>
<html>
<head>
<title>El Lokal Bilder Suche</title>
<link href="ellokal.css" rel="stylesheet" type="text/css">
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
</head>
<body>
<h1>El Lokal Bilder Suche</h1>
<div id="search_form">
<div id="search_elements">

<?php
require "strus.php";

$resultcols = ("id","concertId","focaldist","apperture","shutterspeed","insertdate","eventdate","program","resolution_X","resolution_Y","width","length","meta","fotographer","thumbnail","filename","summary","weight");
function evalDatabaseQuery( $context, $idlist, $minRank, $maxNofRanks)
{
	$rt = ();
	// Connecting, selecting database
	$dbconn = pg_connect("host=localhost dbname=ellokal") or die('Could not connect: ' . pg_last_error());

	// Performing SQL query
	$query = 'SELECT id,concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename FROM ConcertPicture';
	$whereclause = '';
	if ($idlist)
	{
		$whereclause .= "id IN (";
		$idx = 0;
		foreach ($idlist as $id)
		{
			if ($idx++ > 0) $whereclause .= ',';
			$whereclause .= "$id";
		}
		$whereclause .= "id IN (";
	}
	if ($whereclause != '')
	{
		$query .= " WHERE " . $whereclause;
	}
	$result = pg_query( $query) or die('Query failed: ' . pg_last_error());

	// Printing results in HTML
	$lastRank = $minRank + $maxNofRanks -1;
	$ridx = 0;
	while ($row = pg_fetch_array( $result, null, PGSQL_ASSOC))
	{
		if ($ridx > $lastRank) break;
		if ($ridx >= $minRank)
		{
			$rt[] = $row;
		}
		++$ridx;
	}

	// Free resultset
	pg_free_result($result);

	// Closing connection
	pg_close($dbconn);
}

function evalStrusQuery( $context, $queryString, $minRank, $maxNofRanks)
{
	$storage = $context->createStorageClient( "" );
	$analyzer = $context->createQueryAnalyzer();
	$queryeval = $context->createQueryEval();

	$analyzer->definePhraseType( "text", "stem", "word", 
			["lc",
			["dictmap", "irregular_verbs_en.txt"],
			["stem", "en"],
			["convdia", "en"],
			"lc"]);

	$queryeval->addTerm( "sentence", "sent", "");
	$queryeval->addWeightingFunction( 1.0, "BM25", [
				"k1" => 0.75, "b" => 1.5, "avgdoclen" => 10,
				".match" => "docfeat" ]);
	}
	$queryeval->addSummarizer(
			"TITLE", "attribute", [
			"name" => "title" ] );
	$queryeval->addSummarizer(
			"DOCID", "attribute", [
			"name" => "docid" ] );
	$queryeval->addSummarizer( "CONTENT", "matchphrase", [
			"type" => "orig", "len" => 40, "nof" => 3, "structseek" => 30,
			"mark" => '<b>$</b>',
			".struct" => "sentence", ".match" => "docfeat" ] );
	$queryeval->addSelectionFeature( "selfeat");

	$query = $queryeval->createQuery( $storage);
	$terms = $analyzer->analyzePhrase( "text", $queryString);
	if (count( $terms) > 0)
	{
		foreach ($terms as &$term)
		{
			$query->pushTerm( "stem", $term->value);
			$query->pushDuplicate();
			$query->defineFeature( "docfeat");
		}
		$query->pushExpression( "contains", count($terms));
		$query->defineFeature( "selfeat");
	}
	$query->setMaxNofRanks( $maxNofRanks);
	$query->setMinRank( $minRank);
	$results = $query->evaluate();
	$idlist = ();
	$summarylist = ();
	$weightlist = ();
	foreach ($results as &$result)
	{
		$id = 0;
		$summary = '';
		foreach ($result->attributes as &$attrib)
		{
			if ($attrib->name == 'DOCID')
			{
				$id = intval( $attrib->value);
				$idlist[] = $id;
			}
			if ($attrib->name == 'CONTENT')
			{
				if ($summary != '') $summary .= " // ";
				$summary .= $attrib->value;
			}
		}
		$summarylist[ $id] = $summary;
		$weightlist[ $id] = $result->weight;
	}
	$dbres = evalDatabaseQuery( $context, $idlist, $minRank, $maxNofRanks);
	foreach ($dbres as &$result)
	{
		$result[] = $summarylist[ intval( $dbres['id'])];
		$result[] = $weightlist[ intval( $dbres['id'])];
	}
	return $dbres;
}

try {
	$queryString = "";
	$minRank = 0;
	$nofRanks = 20;
	$scheme = "db";
	if (PHP_SAPI == 'cli')
	{
		# ... called from command line (CLI)
		$ai = 0;
		foreach ($argv as $arg)
		{
			if ($ai > 0)
			{
				if ($queryString != "")
				{
					$queryString .= ' ';
				}
				$queryString .= $arg;
			}
			++$ai;
		}
	}
	else
	{
		# ... called from web server
		parse_str( getenv('QUERY_STRING'), $_GET);
		if (array_key_exists( 'n', $_GET))
		{
			$nofRanks = intval( $_GET['n']);
		}
		if (array_key_exists( 'i', $_GET))
		{
			$minRank = intval( $_GET['i']);
		}
		if (array_key_exists( 's', $_GET))
		{
			$scheme = $_GET['s'];
		}
		$queryString = $_GET['q'];
	}
	$context = new StrusContext( "localhost:7181" );
	$schemeDatabase_checked = "";
	$schemeStrus_checked = "";
	if ($scheme == "db")
	{
		$results = evalDatabaseQuery( $context, $minRank, $nofRanks);
		$schemeDatabase_checked = "checked";
	}
	else
	{
		$results = evalStrusQuery( $context, $queryString, $minRank, $nofRanks);
		$schemeStrus_checked = "checked";
	}
	echo '<form name="search" class method="GET" action="query.php">';
	echo "<input id=\"search_input\" class=\"textinput\" type=\"text\" maxlength=\"256\" size=\"32\" name=\"q\" tabindex=\"1\" value=\"$queryString\"/>";
	echo "<input type=\"hidden\" name=\"n\" value=\"$nofRanks\"/>";
	echo "<input type=\"radio\" name=\"scheme\" value=\"Database\" $schemeDatabase_checked/>BM25_dpfc";
	echo "<input type=\"radio\" name=\"scheme\" value=\"BM25\" $schemeStrus_checked/>BM25";
	echo '<input id="search_button" type="image" src="search_button.jpg" tabindex="2"/>';
	echo '</form>';
	echo '</div>';
	echo '</div>';

	foreach ($results as &$result)
	{
		echo '<div id="search_rank">';
		foreach ($result as &$attr)
		{
			echo '<div id="rank_elem">' . "$attr</div>";
		}
		echo '</div>';
	}
	echo '</div>';
	echo '<div id="navigation_form">';
	echo '<div id="navigation_elements">';
	$nextMinRank = $minRank + $nofRanks;
	$prevMinRank = $minRank - $nofRanks;
	if ($prevMinRank >= 0)
	{
		echo '<form name="prev" class method="GET" action="query.php">';
		
		echo "<input type=\"hidden\" name=\"q\" value=\"$queryString\"/>";
		echo "<input type=\"hidden\" name=\"n\" value=\"$nofRanks\"/>";
		echo "<input type=\"hidden\" name=\"i\" value=\"$prevMinRank\"/>";
		echo "<input type=\"hidden\" name=\"scheme\" value=\"$scheme\"/>";
		echo '</form>';
	}
	if (count( $results) >= $nofRanks)
	{
		echo '<form name="next" class method="GET" action="query.php">';
		echo "<input type=\"hidden\" name=\"q\" value=\"$queryString\">";
		echo "<input type=\"hidden\" name=\"n\" value=\"$nofRanks\">";
		echo "<input type=\"hidden\" name=\"i\" value=\"$nextMinRank\">";
		echo "<input type=\"hidden\" name=\"scheme\" value=\"$scheme\">";
		echo '</form>';
	}
	$context->close();
	echo '</div>';
	echo '</div>';
}
catch( Exception $e ) {
	echo '<p>';
	echo '<font color="red">';
	echo 'Error: ',  $e->getMessage(), "\n";
	echo '</font>';
	echo '</p>';
}
?>

</body>
</html>


