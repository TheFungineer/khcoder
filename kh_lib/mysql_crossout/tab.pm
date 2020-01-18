package mysql_crossout::tab;
use base qw(mysql_crossout);
use strict;

sub out2{                               # length�����򤹤�
	my $self = shift;
	
	open (F,'>:encoding(utf8)', $self->{file_temp}) or die("could not open $self->{file_temp}");
	
	# �������Ƥκ���
	my $id = 1;
	my $last = 1;
	my $started = 0;
	my %current = ();
	while (1){
		my $sth = mysql_exec->select(
			$self->sql2($id, $id + 30000),
			1
		)->hundle;
		$id += 30000;
		unless ($sth->rows > 0){
			last;
		}
		
		while (my $i = $sth->fetch){
			if ($last != $i->[0] && $started == 1){
				# �񤭽Ф�
				my $temp = "$last\t";
				if ($self->{midashi}){
					$temp .= kh_csv->value_conv_t($self->{midashi}->[$last - 1])."\t";
				}
				foreach my $h ( 'length_c','length_w',@{$self->{wList}} ){
					if ($current{$h}){
						$temp .= "$current{$h}\t";
					} else {
						$temp .= "0\t";
					}
				}
				chop $temp;
				print F "$temp\n";
				# �����
				%current = ();
				$last = $i->[0];
			}
			
			$last = $i->[0] unless $started;
			$started = 1;
			
			# HTML������̵��
			if (
				!  ( $self->{use_html} )
				&& ( $i->[2] =~ /<[h|H][1-5]>|<\/[h|H][1-5]>/o )
			){
				next;
			}
			
			# ����
			++$current{'length_w'};
			$current{'length_c'} += length($i->[2]);
			if ($self->{wName}{$i->[1]}){
				++$current{$i->[1]};
			}
		}
		$sth->finish;
	}
	
	# �ǽ��Ԥν���
	my $temp = "$last\t";
	if ($self->{midashi}){
		$temp .= kh_csv->value_conv_t($self->{midashi}->[$last - 1])."\t";
	}
	foreach my $h ( 'length_c','length_w',@{$self->{wList}} ){
		if ($current{$h}){
			$temp .= "$current{$h}\t";
		} else {
			$temp .= "0\t";
		}
	}
	chop $temp;
	print F "$temp\n";
	close (F);
}

sub finish{
	my $self = shift;
	
	open (OUTF,'>:encoding(utf8)', $self->{file}) or
		gui_errormsg->open(
			type    => 'file',
			thefile => $self->{file},
		);
	
	# �إå��Ԥκ���
	my $head = ''; my @head;
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$head .= "$i\t";
		push @head, $i;
		if ($self->{tani} eq $i){
			last;
		}
	}
	if ($self->{midashi}){
		$head .= "id\tname\tlength_c\tlength_w\t";
	} else {
		$head .= "id\tlength_c\tlength_w\t";
	}

	foreach my $i (@{$self->{wList}}){
		$head .= kh_csv->value_conv_t($self->{wName}{$i})."\t";
	}
	chop $head;
	#if ($::config_obj->os eq 'win32'){
	#	$head = Jcode->new($head)->sjis;
	#}
	print OUTF "$head\n";
	
	# ���־���ȤΥޡ���
	
	my $sql;
	$sql .= "SELECT ";
	foreach my $i (@head){
		$sql .= "$i"."_id,";
	}
	chop $sql;
	$sql .= "\nFROM $self->{tani}\n";
	$sql .= "ORDER BY id";
	my $sth = mysql_exec->select($sql,1)->hundle;
	
	open (F, '<:encoding(utf8)', $self->{file_temp}) or die;
	while (<F>){
		my $srow = $sth->fetchrow_hashref;
		my $head;
		foreach my $i (@head){
			$head .= $srow->{"$i"."_id"};
			$head .= "\t";
		}
		print OUTF "$head"."$_";
	}
	close (F);
	close (OUTF);
	unlink("$self->{file_temp}");
}



1;