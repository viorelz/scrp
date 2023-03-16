#!/usr/bin/perl
# spe - 10/2006

use DBI;
use MIME::Lite;

my $user = "root";
my $password = "qHc96M";
my $emailalertfrom = "alert\@host6.domain.tld";
my $emailalertto = "lucilanga\@domain.tld";
my $mysqladmin = "/usr/bin/mysqladmin";
my $sql = "SHOW FULL PROCESSLIST";
my $killedAQuery = 0;
my $dbhost=`/bin/hostname`;

while (1) {
	$db_handle = 0;
	while ($db_handle == 0) {
		$db_handle = DBI->connect("dbi:mysql:database=mysql;host=127.0.0.1:port=3306;user=".$user.";password=".$password);
		if ($db_handle == 0) {
			sleep(1);
		}
	}

	$statement = $db_handle->prepare($sql)
	    or die "Couldn't prepare query '$sql': $DBI::errstr\n";

	$statement->execute()
	    or die "Couldn't execute query '$sql': $DBI::errstr\n";
	while (($row_ref = $statement->fetchrow_hashref()) && ($killedAQuery == 0))
	{
		if ($row_ref->{Command} eq "Query") {
			if ($row_ref->{Time} >= 200) {
				@args = ($mysqladmin, "-u".$user, "-p".$password, "kill", $row_ref->{Id});
				$returnCode = system(@args);
				#$emailMessage = "A slow query as been detected (more than $row_ref->{Time} seconds). SQLKiller will try to kill this request.\nThe query is:\n$row_ref->{Info}\n\n";
				$emailMessage = "A slow query as been detected (more than $row_ref->{Time} seconds). SQLKiller will try to kill this request.\nThe query is:\n$row_ref\n\n";
while( my ($k, $v) = each %$row_ref ) {
        $emailMessage .= "key: $k, value: $v.\n";
    }
				if ($returnCode != 0) {
					$emailMessage .= "Result: The SQL request cannot be killed. This SQL request is probably a fake slow query due to an another SQL request. The problematic request is the first killed successfully\n";
				}
				else {
					$emailMessage .= "Result: The SQL request has been killed successfully\n";
				}
				my $msg = new MIME::Lite 
					From    =>$emailalertfrom, 
					To      =>$emailalertto,          
					Subject =>'[ SQLKILLER ] A query has been killed on '.$dbhost,
					Type    =>'TEXT',   
					Data    =>$emailMessage;
				$msg -> send;
				$killedAQuery = 1;
			}
		}
	}
	$statement->finish();
	$db_handle->disconnect();
	if ($killedAQuery == 0) {
		sleep(5);
	}
	else {
		$killedAQuery = 0;
		#sleep(1);
	}
}

