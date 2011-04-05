<?
#
# Written by Lars Larsson <lars.la@gmail.com>
#

print_r(apache_request_headers());

## <CONFIG>

# The user running the webserver must have write permissions to this folder
$BACKUPDIR="/var/backup";

# Your timezone
date_default_timezone_set('Europe/Stockholm');

# Do you want to recieve an email if we get an error from a client?
$error_mail="TRUE";

# Address to send the errorlog to if a client sends in an error-log
$mailto="you@yourdomain.com";

# SMTP-server
$smtp_server="smtp.varmdo.se";

# Name of sending user
$from_name="Backup";

# Mail from address
$from_mail="backup@varmdo.se";

## </CONFIG>

ini_set('sendmail_from', $from_mail);
ini_set('SMTP', $smtp_server);
ini_set('upload_max_filesize', '500M');

echo ini_get( 'upload_max_filesize' )."\n";

print_r($_FILES);
echo $_FILES['file']['name']."....\n";

if ($_FILES["file"]["error"] > 0) {
	echo "Return Code: " . $_FILES["file"]["error"] . "<br />";
} else {
	$filename=str_replace('/', '_', $_FILES["file"]["name"]);
	$tmpfile=$_FILES["file"]["tmp_name"];
	$hostname=str_replace('/', '_', $_GET["hostname"]);
	$type=$_GET["type"];

	if(!file_exists($BACKUPDIR."/".$hostname))
		mkdir($BACKUPDIR."/".$hostname);

	if($type == "error") {
		$filename = "backup-".$hostname."-".date('Y-m-d-U').".error";
		if($error_mail == "TRUE") {
			$subject = "Backup error from ".$hostname;
			$header = "From: ".$from_name." <".$from_mail.">\r\n";
			$error = file_get_contents($tmpfile);
			mail($mailto, $subject, $error, $header);
		}
	}

	if($type == "log")
		$filename = "backup-".$hostname."-".date('Y-m-d-U').".log";

	if($type == "incremental")
		$filename = "backup-".$hostname."-".date('Y-m-d-U').".inc";

	if(file_exists($BACKUPDIR."/".$hostname."/".$filename))
		$filename = $filename.date('U');
	
	move_uploaded_file($tmpfile, $BACKUPDIR."/".$hostname."/".$filename);

}




?>
