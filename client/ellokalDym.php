<?php
try
{
	$nofRanks = 10;
	$queryString = "";

	parse_str( getenv('QUERY_STRING'), $_GET);
	if (array_key_exists( 'n', $_GET))
	{
		$nofRanks = intval( $_GET['n']);
	}
	if (array_key_exists( 'q', $_GET))
	{
		$queryString = $_GET['q'];
	}

	$service_url = 'http://127.0.0.1/ellokal/dym'
			. '?q=' . urlencode($queryString)
			. '&n=' . urlencode($nofRanks);
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
