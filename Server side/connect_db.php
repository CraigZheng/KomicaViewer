<?php
	//the purpose of this file is to estabilish a mysql database connection.
	
	$mysqli = new mysqli("pdb18.awardspace.net", "1583255_civ", "httph.acfun.tvt9999", "1583255_civ");
	mysqli_query($mysqli, "SET NAMES utf8");
	if ($mysqli->connect_error){
		echo('Connect Error (' .$mysqli->connect_errno. ')'.$mysqli->connect_error);
	}
	

?>