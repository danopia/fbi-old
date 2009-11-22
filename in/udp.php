<?php
$fp = pfsockopen("udp://127.0.0.1", 1337, $errno, $errstr);

if (!$fp)
	echo "ERROR: $errno - $errstr<br />\n";

socket_set_timeout($fp, 10);

$write = fwrite($fp, $_POST['payload'] . "\n");
fclose($fp);

if (!$write)
	echo "error writing to port: 9600.<br/>";

?>
