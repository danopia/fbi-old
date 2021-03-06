<?php
if (strlen($_POST['payload']) > 0)
{
	$fp = pfsockopen("udp://127.0.0.1", 1337, $errno, $errstr);
	socket_set_timeout($fp, 10);
	$write = fwrite($fp, stripslashes($_POST['payload']) . "\n");
	fclose($fp);

	exit;
}
?>
<html>
<head>
<title>Commit Hook for GitHub integration</title>
</head>

<body>
<h2>Hello there!</h2>
<h3>You've stumbled upon FBI's GitHub integration hook.</h3>
<p>This URL is used by GitHub to send commit notifications to FBI via
a very cool technology called webhooks.</p>

<h3>Setting up FBI for your GitHub repo</h3>
<p>First of all, you need access to the Admin tab on the repo. This is
important. If you don't have the Admin tab, find the person who does
have it.</p>
<p>Once you click the Admin tab on your repo, click the Service Hooks
link in the sub-navbar, right below the tab strip. In the first empty
box labeled URL, paste in the URL that this page is at (should resemble
http://fbi.danopia.net/github). Click "Update Settings" to apply your
new hook.</p>
<p>You'll need to add the project to your channels if you want FBI to
announce there. Add it like so: "FBI-1: add project *projectname*",
where projectname is the name of the repo, not including username.
(I have to figure out how I'll handle forks. D: )</p>
<p>You may use the "Test Hook" link to test out FBI without spamming
up your commit history.</p>
</body>
</html>
