# 外部変数による指定（KH Coderバージョン1x 互換）

package kh_cod::a_code::atom::outvar_o;
use base qw(kh_cod::a_code::atom);
use strict;
use utf8;
my $debug = 0;

sub expr{
	my $self = shift;
	
	if ($self->{valid}){
		my ($col,$tab);
		$col = (split /\_/, $self->{tables}[0])[2].(split /\_/, $self->{tables}[0])[3];
		$tab = $self->parent_table;
		return "IFNULL($tab.$col,0)";
	} else {
		return '0';
	}
}

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;

	if ($self->raw =~ /^"(.+)"$/){
		$self->{raw} = $1;
		$self->{raw} =~ s/""/"/g;
	}

	# ルール指定の解釈
	my ($var, $val);
	if ($self->raw =~ /<>(.+)\-\->(.+)$/o){
		$var = $1;
		$val = $2;
		print "atom-outvar_o: $var, $val\n" if $debug;
	} else {
		die("something wrong!");
	}
	
	# 変数の存在を確認
	my $var_obj = mysql_outvar::a_var->new($var);
	unless ($var_obj->{tani}){
		$self->{valid} = 0;
		return 1;
	}
	print "atom-outvar_o: the variable found\n" if $debug;
	
	# 集計単位が矛盾しないかどうか確認
	$self->{valid} = 1;
	if ($tani eq 'dan'){                # 段落単位の場合
		if ($var_obj->{tani} eq 'bun'){
			$self->{valid} = 0;
			return 1;
		}
	}
	elsif ($tani =~ /h([1-5])/i) {      # H1-H5単位の場合
		if ($var_obj->{tani} eq 'bun' || $var_obj->{tani} eq 'dan'){
			$self->{valid} = 0;
			return 1;
		}
		my $var_tani_num = substr($var_obj->{tani},1,1);
		print "atom-outvar_o: $var_tani_num, $1\n" if $debug;
		if ($var_tani_num > $1){
			print "atom-outvar_o: tani looks NG\n" if $debug;
			$self->{valid} = 0;
			return 1;
		}
	}
	print "atom-outvar_o: tani looks ok\n" if $debug;

	# テーブル名決定
	$val = $var_obj->real_val($val);
	my $table = "ct_$tani"."_ovo"."$var_obj->{id}"."_"
		.$var_obj->real_val_id($val);
	print "atom-outvar_o: table: $val: $table\n" if $debug;
	$self->{tables} = ["$table"];

	# テーブル作成
	if ( mysql_exec->table_exists($table) ){
		print "atom-outvar_o: the table already exists\n" if $debug;
		return 1;
	}
	mysql_exec->do("
		CREATE TABLE $table (
			id INT primary key not null,
			num INT
		)
	",1);
	
	$val = mysql_exec->quote($val);
	#$val = Encode::encode('utf8', $val) if utf8::is_utf8($val);
	
	if ($var_obj->{tani} eq $tani){          # 集計単位が同じ場合
		my $sql = "
			INSERT
			INTO $table (id, num)
			SELECT id, 1
			FROM $var_obj->{table}
			WHERE
				$var_obj->{column} = $val
		";
		mysql_exec->do("$sql",1);
		$sql = Encode::encode('utf8', $sql) if utf8::is_utf8($sql);
		print "$sql" if $debug;
	} else {                                 # 集計単位が異なる場合
		my $sql;
		$sql .= "INSERT INTO $table (id, num) SELECT $tani.id, 1 FROM\n";
		$sql .= "$var_obj->{table}, $var_obj->{tani}, $tani\n";
		$sql .= "WHERE\n";
		$sql .= "$var_obj->{table}.id = $var_obj->{tani}.id\n";
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$sql .= "and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
			last if ($i eq $var_obj->{tani});
		}
		$sql .= "and $var_obj->{table}.$var_obj->{column} = $val";
		$sql = Encode::encode('utf8', $sql) if utf8::is_utf8($sql);
		mysql_exec->do("$sql",1);
	}
}

#--------------#
#   アクセサ   #

sub raw_for_cache_chk{
	my $self = shift;
	
	# 解釈
	my ($var, $val);
	if ($self->raw =~ /<>(.+)\-\->(.+)$/o){
		$var = $1;
		$val = $2;
		print "atom-outvar_o: $var, $val\n" if $debug;
	} else {
		return $self->{raw}.'(invalid)';
	}
	my $var_obj = mysql_outvar::a_var->new($var);
	return 
		$self->{raw}
		."($var_obj->{table}:$var_obj->{column}:".$var_obj->real_val($val).")";
}

sub tables{
	my $self = shift;
	return $self->{tables};
}

sub parent_table{
	my $self = shift;
	my $new  = shift;
	
	if (length($new)){
		$self->{parent_table} = $new;
	}
	return $self->{parent_table};
}

sub pattern{
	return '^<>.+\-\->.+|^"<>.+\-\->.+"$';
}
sub name{
	return 'outvar_o';
}

1;