package kh_nbayes::Util;

use List::Util qw(max sum);

sub knb2lst{
	my $class = shift;
	my $self = {@_};
	bless $self, $class;

	# �ؽ���̤��ɤ߹���
	$self->{cls} = Algorithm::NaiveBayes->restore_state($self->{path});
	my $fixer = 0;
	foreach my $i (values %{$self->{cls}{model}{smoother}}){
		$fixer = $i if $fixer > $i;
	}

	# �ǡ�������[1]
	my @labels = $self->{cls}->labels;
	my @rows;
	my %printed = ();
	foreach my $i (@labels){ # $i = ��٥�
		foreach my $h (keys %{$self->{cls}{model}{probs}{$i}}){ # $h = ��
			unless ( $printed{$h} ){
				my $current = [ $h ];
				foreach my $k (@labels){ # $k = ��٥�
					push @{$current},
						(
							   $self->{cls}{model}{probs}{$k}{$h}
							|| $self->{cls}{model}{smoother}{$k} 
						)
						- $fixer
					;
				}
				push @rows, $current;
				$printed{$h} = 1;
			}
		}
	}

	$self->{info}{instances} = $self->{cls}{instances};
	$self->{info}{words} = @rows;
	$self->{info}{labels} = \@labels;

	# ������Ψ
	my $prior_probs = [kh_msg->get('prior')]; # [������Ψ]
	foreach my $i (@labels){
		push @{$prior_probs}, $self->{cls}{model}{prior_probs}{$i} - $fixer;
	}
	push @rows, $prior_probs;

	$self->{cls} = undef; # ����Υ��ꥢ

	# �ǡ�������[2]
	my $c = @labels;
	my @sort;
	foreach my $i (
		sort { sum( @{$b}[1..$c] ) <=> sum( @{$a}[1..$c] ) } 
		@rows
	){
		my @current = ();
		# ������
		foreach my $h ( @{$i} ){
			push @current, $h;
		}
		
		# ʬ��
		my $sum = sum( @{$i}[1..$c] );
		my $s = 0;
		foreach my $h ( @{$i}[1..$c] ){
			$s += ( $sum / $c - $h ) ** 2;
		}
		$s /= $c;
		push @current, $s;
		
		# �Ԥ�%
		foreach my $h ( @{$i}[1..$c] ){
			push @current, $h / $sum * 100;
		}
		
		push @sort, \@current;
	}
	undef @rows;

	$self->{rows} = \@sort;
	return $self;
}

sub rows{
	my $self = shift;
	return $self->{rows};
}
sub instances{
	my $self = shift;
	return $self->{info}{instances};
}
sub words{
	my $self = shift;
	return $self->{info}{words};
}
sub labels{
	my $self = shift;
	return @{$self->{info}{labels}};
}


sub make_csv{
	my $self = shift;
	
	my $csv = shift;
	print "$csv\n";
	
	# �񤭽Ф�
	use File::BOM;
	open (COUT, '>:encoding(utf8):via(File::BOM)', $csv) or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$csv",
		);

	my @labels = $self->labels;

	my $header = '';
	$header .= ','.kh_msg->get('h_score','gui_window::use_te_g').',';  #',������,';
	for (my $n = 1; $n <= $#labels; ++$n){
		$header .= ',';
	}
	$header .= ','.kh_msg->get('pcnt','gui_window::word_freq')."\n";#",�Ԥ�%\n";

	$header .= kh_msg->gget('words').','; #"��и�,";
	foreach my $i (@labels){
		$header .= kh_csv->value_conv($i).',';
	}
	$header .= kh_msg->get('variance','gui_window::bayes_view_knb').','; #'ʬ��,';
	foreach my $i (@labels){
		$header .= kh_csv->value_conv($i).',';
	}
	chop $header;
	print COUT "$header\n";

	foreach my $i ( @{$self->{rows}} ){
		my $c = 0;
		my $t = '';
		foreach my $h (@{$i}){
			if ($c){
				$t .= "$h,";
			} else {
				$t .= kh_csv->value_conv($h).',';
			}
			++$c;
		}
		chop $t;
		print COUT "$t\n";
	}
	close (COUT);
	
	return 1;
}

1;
