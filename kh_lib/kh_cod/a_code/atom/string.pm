# ����ʸ����ˤ�����

package kh_cod::a_code::atom::string;
use base qw(kh_cod::a_code::atom);
use strict;

use mysql_exec;
use POSIX qw(log10);

#-----------------#
#   SQLʸ�ν���   #
#-----------------#

my %sql_join = (
	'bun' =>
		'',
	'dan' =>
		'
			AND dan.dan_id = bun.dan_id
			AND dan.h5_id = bun.h5_id
			AND dan.h4_id = bun.h4_id
			AND dan.h3_id = bun.h3_id
			AND dan.h2_id = bun.h2_id
			AND dan.h1_id = bun.h1_id
		',
	'h5' =>
		'
			AND h5.h5_id = bun.h5_id
			AND h5.h4_id = bun.h4_id
			AND h5.h3_id = bun.h3_id
			AND h5.h2_id = bun.h2_id
			AND h5.h1_id = bun.h1_id
		',
	'h4' =>
		'
			AND h4.h4_id = bun.h4_id
			AND h4.h3_id = bun.h3_id
			AND h4.h2_id = bun.h2_id
			AND h4.h1_id = bun.h1_id
		',
	'h3' =>
		'
			AND h3.h3_id = bun.h3_id
			AND h3.h2_id = bun.h2_id
			AND h3.h1_id = bun.h1_id
		',
	'h2' =>
		'
			AND h2.h2_id = bun.h2_id
			AND h2.h1_id = bun.h1_id
		',
	'h1' =>
		'AND h1.h1_id = bun.h1_id'
);

sub reset{}

my $dn;

#--------------------#
#   WHERE����SQLʸ   #
#--------------------#

sub expr{
	my $self = shift;
	my $t = $self->tables;
	unless ($t){ return '0';}
	
	$t = $t->[0];
	my $col = (split /\_/, $t)[2].(split /\_/, $t)[3];
	my $sql = "IFNULL(".$self->parent_table.".$col,0)";
	return $sql;
}

sub idf{
	my $self = shift;
	return 0 unless $self->tables;
	
	# ��ʸ����μ������ݻ�
	unless (
		($dn->{$self->{tani}}) && ($dn->{check} eq $::project_obj->file_target)
	){
		$dn->{$self->{tani}} = mysql_exec->select(
			"SELECT COUNT(*) FROM $self->{tani}",1
		)->hundle->fetch->[0];
		$dn->{check} = $::project_obj->file_target;
	}
	
	# �׻�
	my $df;
	$df = mysql_exec->select(
		"SELECT COUNT(*) FROM $self->{tables}[0]",1
	)->hundle->fetch->[0];
	return 0 unless $df;
	
	return log10($dn->{$self->{tani}} / $df);
}


#---------------------------------------#
#   �����ǥ��󥰽�����tmp table������   #
#---------------------------------------#

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;

	# ������μ���
	my $query = $self->raw;
	chop $query;
	substr($query,0,1) = '';

	# ����å���Υ����å��ȥơ��֥�̾����
	my @c_c = kh_cod::a_code->cache_check(
		tani => $tani,
		kind => 'string',
		name => $query
	);
	my $table = "ct_$tani"."_string_$c_c[1]";
	$self->{tables} = ["$table"];
	if ($c_c[0]){
		return 1;
	}
	
	# �ơ��֥����
	mysql_exec->drop_table($table);
	mysql_exec->do("
		CREATE TABLE $table (
			id INT primary key not null,
			num INT
		)
	",1);

	# INSERT
	my $sql;
	$sql = "
		INSERT
		INTO $table (id, num)
		SELECT $tani.id, count(*)
		FROM $tani, bun_r";
	unless ($tani eq 'bun'){$sql .= " ,bun";}
	$sql .= "
		WHERE
			    bun.id = bun_r.id
			$sql_join{$tani}
			AND rowtxt like \"%$query%\"
		GROUP BY $tani.id
	";
	mysql_exec->do($sql,1);

}

#-------------------------------#
#   ���Ѥ���tmp table�Υꥹ��   #

sub tables{
	my $self = shift;
	return $self->{tables};
}

#----------------#
#   �ƥơ��֥�   #
sub parent_table{
	my $self = shift;
	my $new  = shift;
	
	if (length($new)){
		$self->{parent_table} = $new;
	}
	return $self->{parent_table};
}

sub pattern{
	return '^\'.+\'$';
}
sub name{
	return 'string';
}

1;