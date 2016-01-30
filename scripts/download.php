<?php

#################################################################################
# Copyright (C) Steven M. Japalucci - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Written by Steven M Japalucci RHCE RHCT <steve.japalucci@gmail.com>, August 2013
#################################################################################
if (isset($_GET['file']) and isset($_GET['download'])) { 
$file = $_GET['file'];
   if(file_exists("$file")){
      // and the file is readable
      if(is_readable("$file")){
         // get the file size
         $size=filesize("$file");
         // open the file for reading
         if($fp=@fopen("$file",'r')){
            // send the headers
            header("Content-type: application/pdf");
            header("Content-Length: $size");
            header("Content-Disposition: attachment; filename=\"$file\"");
			header("Cache-Control: maxage=5"); //In seconds
			header("Pragma: public");
            // send the file content
            fpassthru($fp);
            // close the file
            fclose($fp);
            // and quit
            exit;
         }
      }else{ // file is not readable
         $error='Cannot read file';
      }
   }else{  // the file does not exist
      $error='File not found';
   }
    // if all went well, the exit above will prevent anything below from showing
	// otherwise, we'll display an error message we created above
	?>
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
	<html>
	<head>
	<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
	<title>Image Download</title>
	</head>
	<body>
	<h1>Download Failed</h1>
	<?php
   	if($error) print "<p>The error message is: $error</p>\n";
	?>
	</body>
	</html>
<?php
} elseif(isset($_GET['file'])) {
	$file = $_GET['file'];
	if(file_exists("$file")){
		$content = '<a href="download.php?file='.$file.'&download=true"><img src="http://'.$_SERVER['HTTP_HOST'].'/images/pdf_icon.png" width="100px"><br>'.$file.'<br>Click Here</a>
		';
	} else {
		$content = '<br><a href="#"><img src="http://'.$_SERVER['HTTP_HOST'].'/images/not_found.png" width="50px"><br>'.$file.'<br>Not found!</a>';
	}
?>
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
	<html>
	<head>
	<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <style>
	body {
		font-family:"Trebuchet MS", Helvetica, sans-serif;
		font-size:12px;
		font-weight:bold;
		color:#000;
	}
	a {
		text-decoration:none;
		font-family:"Trebuchet MS", Helvetica, sans-serif;
		font-size:12px;
		font-weight:bold;
		color:#000;
	}
	.link-container {
		border: 4px solid;
		border-color:#BBBEC0;
		background-color:#EAEEF0;
		width: 600px;
    	height: 450px;
		border-radius:10px;
		padding-top:30px;
		top: 15%
	}

	.link-container a {
		display: table;
    	margin: 0 auto;
		top: 10%;
		background-color: #D4DCE1;
		width: 200px;
    	height: 150px;
		text-align: center;
		border-radius: 10px;
		position:relative;
		padding-top:15px;
		border: 3px solid;
		border-color:#fff;
		
	}

	.link-container a:hover {
		background: #eee;
		color:#999;
	}
	div {
   	width: 600px;
    	height: 450px;
    	background-color: #fff;

    	position: absolute;
    	left: 0;
    	right: 0;
    	margin: auto;
		text-align:center;
	}
	</style>
	<title><?php echo "$file"; ?> Download</title>
	</head>
	<body>
    <div>
    	
    	<div class="link-container">
        	<img width="55%" src="http://<?php echo $_SERVER['HTTP_HOST']; ?>/images/logo2.png">
        	<?php echo $content; ?>
            
        </div>
    </div>
	</body>
    </html>
<?php
}
?>
	
