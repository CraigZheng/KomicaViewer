<?php
	//allow user to submit feedbacks to my server

	//connect to DB
	include_once 'connect_db.php';
	
	//request is make with GET
	$access_token = "";
	$vendorID = "";
	$topic = "";
	$title = "";
	$time = "";
	$name = "";
	$content = "";
	$emotion = "";
	
	if (isset($_GET['access_token'])) {
		$access_token = $_GET['access_token'];
	}
	if (isset($_GET['vendorID'])){
		$vendorID = $_GET['vendorID'];
	}
	if (isset($_GET['topic'])){
		$topic = $_GET['topic'];
	}
	if (isset($_GET['title'])){
		$title = $_GET['title'];

	}
	if (isset($_GET['time'])){
		$time = $_GET['time'];

	}
	if (isset($_GET['name'])){
		$name = $_GET['name'];

	}
	if (isset($_GET['content'])){
		$content = $_GET['content'];
	}
	if (isset($_GET['emotion'])){
		$emotion = $_GET['emotion'];
	}
	
	
	$sql = "INSERT INTO kv_custom_forum (access_token, vendorID, topic, title, time, name, content, emotion) 
		VALUES ('$access_token', '$vendorID', '$topic', '$title', '$time', '$name', '$content', '$emotion')";

	$result = mysqli_query($mysqli, $sql);
	if ($result){
		//successed
		echo "successed";
	}
	else {
		//failed
		echo "failed";
		echo $mysqli->error;
	}


?>