package mysql_morpho_check;
use strict;
use mysql_exec;

sub search{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	unless ( length($self->{query}) ){
		return;
	}
	
	my $q = $self->{query};
	
	# ���ܸ졦���졦�ڹ��ʳ��ξ���query��tokenize���롣
	unless (
		   $::project_obj->morpho_analyzer_lang eq 'jp'
		|| $::project_obj->morpho_analyzer_lang eq 'cn'
		|| $::project_obj->morpho_analyzer_lang eq 'kr'
	){
		# ������Фؤ��б�
		# (1)�������
		#my @keywords = ();
		#my $h = mysql_exec->select("
		#	SELECT genkei.name
		#	FROM   genkei, khhinshi
		#	WHERE
		#		genkei.khhinshi_id = khhinshi.id
		#		AND (
		#			   khhinshi.name = '����'
		#			OR khhinshi.name = 'TAG'
		#		)
		#",1)->hundle;
		#while (my $i = $h->fetch){
		#	if ($i->[0] =~ /_/){
		#		$i->[0] =~ tr/_/ /;
		#		push @keywords, $i->[0];
		#	}
		#}
		# (2)�ޡ���
		# ����ä����Ǥ��Ƹ�Ƥ��

		# tokenize
		my $class =
			 "kh_morpho::perl::stemming::"
			.$::project_obj->morpho_analyzer_lang
		;
		my $self;
		$self->{dummy} = 1;
		bless $self, $class;
		my ($w) = $self->tokenize($q);
		$q = '';
		foreach my $i (@{$w}){
			$q .= ' ' if length($q);
			$q .= $i;
		}
	}
	
	$q = mysql_exec->quote($q);
	$q =~ s/'(.+)'/$1/;
	
	my $h = mysql_exec->select("
		SELECT hyoso.name, hyosobun.bun_idt
		FROM bun_r, hyosobun LEFT JOIN hyoso ON hyosobun.hyoso_id = hyoso.id
		WHERE
			bun_r.rowtxt LIKE \'%$q%\'
			AND hyosobun.bun_idt  = bun_r.id
		ORDER BY hyosobun.id
		LIMIT 1000
	",1)->hundle;
	
	my %d;
	while (my $i = $h->fetch){
		if ( defined($d{$i->[1]}) && length($d{$i->[1]}) ){
			$d{$i->[1]} .= " / $i->[0]";
		} else {
			$d{$i->[1]} .= $i->[0];
		}
	}
	my @d;
	for my $i (sort {$a <=> $b} keys %d ){
		push @d, [$d{$i}, $i];
	}
	return \@d;
}

sub detail{
	my $class = shift;
	my $query = shift;
	return mysql_exec->select("
		SELECT 
			hyoso.name,
			genkei.name,
			hselection.name,
			hinshi.name,
			katuyo.name
		FROM hyoso, genkei, hselection, hinshi, katuyo, hyosobun
		WHERE
			hyosobun.bun_idt = $query
			AND hyosobun.hyoso_id = hyoso.id
			AND hyoso.genkei_id = genkei.id
			AND hyoso.katuyo_id = katuyo.id
			AND hyoso.hinshi_id = hinshi.id
			AND genkei.khhinshi_id = hselection.khhinshi_id
		ORDER BY hyosobun.id
	",1)->hundle->fetchall_arrayref;
}

1;