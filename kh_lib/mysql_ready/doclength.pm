package mysql_ready::doclength;
use strict;

my $records_per_once = 200;

use mysql_exec;



sub make_each{
	my $class = shift;
	my $self;
	
	$self->{tani} = shift;
	
	$self->{html} = "99999";
	my $max = mysql_exec->select("SELECT count(*) from $self->{tani}")->hundle->fetch->[0];
	
	bless $self, $class;

	mysql_exec->drop_table("$self->{tani}_length");
	mysql_exec->do("
		CREATE TABLE $self->{tani}_length (
			id int primary key not null,
			c int,
			w int
		)
	",1);

	my $id = 1;
	while (1){
		mysql_exec->do(
			$self->sql($id, $id + $records_per_once),
			1
		);
		$id += $records_per_once;
		if ($id > $max){last;}
	}

}

sub sql{
	my $self = shift;
	my $d1 = shift;
	my $d2 = shift;
	
	my $sql = "INSERT INTO $self->{tani}_length (id, c, w)\n";
	$sql .= "SELECT $self->{tani}.id, sum(lc), sum(lw)\n";
	$sql .= "FROM hyosobun_t, $self->{tani}\n";
	$sql .= "WHERE\n";


	my ($flag, $n) = (0,0);
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($i eq $self->{tani}){ $flag = 1; }

		if ($flag){
			if ($n){
				$sql .= "	AND ";
			} else {
				$sql .= "	";
			}
			$sql .= "hyosobun_t.$i"."_id = $self->{tani}.$i"."_id\n";
			++$n;
		}
	}

	$sql .= "	AND $self->{tani}.id >= $d1\n";
	$sql .= "	AND $self->{tani}.id < $d2\n";
	$sql .= "GROUP BY $self->{tani}.id";
	
	return $sql;
}




1;