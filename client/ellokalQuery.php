<?php
try
{
	$restrictset = NULL;
	$nofRanks = 4;
	$minRank = 0;
	$mode = 0;
	$picsize = 100;
	$language = "de";
	$queryString = NULL;

	parse_str( getenv('QUERY_STRING'), $_GET);
	if (array_key_exists( 'm', $_GET))
	{
		$mode = intval( $_GET['m']);
	}
	if (array_key_exists( 'n', $_GET))
	{
		$nofRanks = intval( $_GET['n']);
	}
	if (array_key_exists( 'i', $_GET))
	{
		$minRank = intval( $_GET['i']);
	}
	if (array_key_exists( 'd', $_GET))
	{
		$restrictset = $_GET['d'];
	}
	if (array_key_exists( 'l', $_GET))
	{
		$language = $_GET['l'];
	}
	if (array_key_exists( 'q', $_GET))
	{
		$queryString = $_GET['q'];
	}
	if (array_key_exists( 's', $_GET))
	{
		$picsize = intval( $_GET['s']);
	}
	if ($mode == 2)
	{
		$command = "list";
	}
	else
	{
		$command = "query";
	}
	$service_url = 'http://127.0.0.1/ellokal/' . $command
			. '?q=' . urlencode($queryString)
			. '&i=' . urlencode($minRank)
			. '&n=' . urlencode($nofRanks)
			. '&m=' . urlencode($mode)
			. '&l=' . urlencode($language)
			. '&s=' . urlencode($picsize)
			. '&d=' . urlencode($restrictset);
	$response = array(
		"error" => "server not running"
	);
	$curl = curl_init( $service_url);
	curl_setopt( $curl, CURLOPT_RETURNTRANSFER, true);
	$curl_response = curl_exec( $curl);
	if (curl_error($curl))
	{
		$errmsg = curl_error($curl);
		curl_close($curl);
		if (!$errmsg) {
			$errmsg = "unknown server error";
		}
		$response = array(
			"error" => $errmsg
		);
	}
	else
	{
		curl_close($curl);
		$decoded = json_decode( $curl_response);
		if (isset($decoded->response->status) && $decoded->response->status == 'ERROR')
		{
			$response = array(
				"error" => $decoded->response->errormessage
			);
		}
		else
		{
			$response = $decoded;
		}
	}
	echo json_encode( $response);
}
catch( Exception $e ) {
	$response = array(
		"error" => $e->getMessage()
	);
	echo json_encode( $response);
}
?>
