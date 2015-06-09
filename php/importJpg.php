<!DOCTYPE html>
<html>
<head>
<title>Import</title>
</head>
<body>
<p>
<?php
try {
	$queryString = '';
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
		$queryString = getenv('QUERY_STRING');
	}
	parse_str( $queryString, $_GET);

	$image_file = $_GET[ 'file'];
	$image_type = '';

	if(file_exists($image_file)){
		$type = exif_imagetype( $image_file);

		switch($type){
			case IMAGETYPE_GIF:{
				$image_type = 'GIF';
			}break;
			case IMAGETYPE_JPEG:{
				$image_type = 'JPEG';
			}break;
			case IMAGETYPE_PNG:{
				$image_type = 'PNG';
			}break;
			case IMAGETYPE_BMP:{
				$image_type = 'BMP';
			}break;
			default:{
				throw new Exception( 'Unknown image file type');
			};
		}
	} else {
		throw new Exception( 'File does not exists');
	}
}
catch ( Exception $e) {
	echo 'Error: ',  $e->getMessage(), "\n";
}
?>
</p>
</body>
</html> 

