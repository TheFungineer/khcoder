package kh_morpho::linux::mecab;
use strict;
use utf8;
use base qw( kh_morpho::linux );

#---------------------#
#   MeCabの実行関係   #
#---------------------#

sub _run_morpho{
	my $self = shift;	
	
	# 初期化
	$self->{store} = '';
	
	$self->{target_temp} = $self->target.'.tmp';
	$self->{output_temp} = $self->output.'.tmp';
	unlink $self->{target_temp} if -e $self->{target_temp};
	unlink $self->{output_temp} if -e $self->{output_temp};
	
	if (-e $self->output){
		unlink $self->output or 
			gui_errormsg->open(
				thefile => $self->output,
				type => 'file'
			);
	}
	
	my $rcpath = '';
	$rcpath = ' -r '.$::config_obj->mecabrc_path if length($::config_obj->mecabrc_path);
	
	$self->{cmdline} = "mecab $rcpath -Ochasen -o \"$self->{output_temp}\" \"$self->{target_temp}\"";
	
	if ($::config_obj->all_in_one_pack){
		$self->{cmdline} = "DYLD_FALLBACK_LIBRARY_PATH=\"$::ENV{DYLD_FALLBACK_LIBRARY_PATH}\" $self->{cmdline}";
	}
	
	#print "morpho: $self->{cmdline}\n";
	
	# 処理開始
	my $icode = kh_jchar->check_code2($self->target);
	open (TRGT, "<:encoding($icode)", $self->target) or 
		gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		);
	while ( <TRGT> ){
		my $t   = $_;
		while ( index($t,'<') > -1){
			my $pre = substr($t,0,index($t,'<'));
			my $cnt = substr(
				$t,
				index($t,'<'),
				index($t,'>') - index($t,'<') + 1
			);
			unless ( index($t,'>') > -1 ){
				gui_errormsg->open(
					msg  => kh_msg->get('kh_morpho::mecab->illegal_bra'),
					type => 'msg'
				);
				exit;
			}
			substr($t,0,index($t,'>') + 1) = '';
			
			$self->_mecab_run($pre);
			$self->_mecab_outer($cnt);
			
			#print "[[$pre << $cnt >> $t]]\n";
		}
		$self->_mecab_store($t);
	}
	close (TRGT);
	$self->_mecab_run();
	return(1);
}

sub _mecab_run{
	my $self = shift;
	my $t    = shift;

	$self->_mecab_store($t) if length($t);
	$self->_mecab_store_out;

	return 1 unless -s $self->{target_temp} > 0;
	unlink $self->{output_temp} if -e $self->{output_temp};

	# MeCabにわたすファイル内容のチェック
	open my $fh_chk, '<', $self->{target_temp} or
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		)
	;
	#my $read_chk = '';
	my $has_lf = 0;
	while (<$fh_chk>){
		#$read_chk .= $_;
		if ($_ =~ /.*\n$/){
			$has_lf = 1;
		} else {
			$has_lf = 0;
		}
	}
	close $fh_chk;
	
	# 最後に改行文字をつけておく
	if ( $has_lf == 0 ){
		open my $fh_add, '>>', $self->{target_temp} or
			gui_errormsg->open(
				thefile => $self->{target_temp},
				type => 'file'
			)
		;
		print $fh_add "\n";
		close $fh_add;
		
		#$read_chk = Jcode->new($read_chk)->utf8;
		#print "Added LF for MeCab: $read_chk\n";
	}

	# MeCabの実行
	system "$self->{cmdline}";
	
	unless (-e $self->{output_temp}){
		$self->Exec_Error("No output file");
	}

	# 結果の取り出し
	my $cut_eos;
	if ( $self->{stlast} =~ /\n\Z/o){
		$cut_eos = 0;
	} else {
		$cut_eos = 1;
	}
	
	my $icode = 'euc-jp';
	$icode = 'utf8' if $::config_obj->mecab_unicode;
	open (OTEMP, "<:encoding($icode)", $self->{output_temp}) or
		gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		);
	open (OTPT,">>:encoding(utf8)",$self->output) or
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);
	
	my $last_line = '';

	# 句点「。」が必ず1語になるよう修正
	while( <OTEMP> ){
		#if ( $::config_obj->mecab_unicode ){
		#	$_ = Jcode->new($_,'utf8')->sjis;
		#}

		if ( length($last_line) > 0 ){
			if (
				   index($last_line,'。') > -1
				&& length( (split /\t/, $last_line)[0] ) > 2
			){
				my $w = (split /\t/, $last_line)[0];
				# print "w: $w, ";
				#$w = Jcode->new($w,'sjis')->euc;
				
				while ( index($w,'。') > -1 ){
					if ( index($w,'。') > 0 ){
						my $pre = substr($w, 0, index($w,'。'));
						#$pre = Jcode->new($pre,'euc')->sjis;
						# print "pre: $pre, ";
						print OTPT "$pre\t$pre\t$pre\t記号-一般\t\t\n";
					}
					# print "$maru, ";
					print OTPT "。\t。\t。\t記号-句点\t\t\n";
					substr($w, 0, index($w,'。') + 1) = '';
				}
				#$w = Jcode->new($w,'euc')->sjis;
				print "l: $w\n";
				print OTPT "$w\t$w\t$w\t記号-一般\t\t\n";
			} else {
				print OTPT $last_line;
			}
		}
		$last_line = $_;
	}
		# 最後に余分な「EOS」が付くのを削除
	if ($last_line =~ /^EOS\n/o && $cut_eos){
	
	} else {
		print OTPT $last_line; 
	}
	
	close (OTEMP);
	close (OTPT);
	
	unlink $self->{output_temp} or
		gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		);

	unlink $self->{target_temp} or 
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		);

	# unlink 確認
	use Time::HiRes;
	for ( my $n = 0; $n < 20; ++$n ){
		if ( not ( -e $self->{output_temp} ) and not ( -e $self->{target_temp} ) ){
			if ($n > 0) {
				print "unlink: it was necessary to wait $n loop(s)\n";
			}
			last;
		}
		if ($n == 19) {
			gui_errormsg->open(
				thefile => $self->{target_temp},
				type => 'file'
			);
		}
		Time::HiRes::sleep (0.5);
	}

	$self->{store} = '';
}

sub _mecab_outer{
	my $self = shift;
	my $t    = shift;
	my $name = 'タグ';

	open (OTPT,">>:encoding(utf8)",$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);

	print OTPT "$t\t$t\t$t\t$name\t\t\n";

	close (OTPT);
}

sub _mecab_store{
	my $self = shift;
	my $t    = shift;
	
	return 1 unless length($t) > 0;
	
	$self->{store} .= $t;
	$self->{stlast} = $t;
	
	if ( length($self->{store}) > 1048576 ){
		$self->_mecab_store_out;
	}

	return $self;
}


sub _mecab_store_out{
	my $self = shift;

	return 1 unless length($self->{store}) > 0;

	my $icode = 'euc-jp';
	$icode = 'utf8' if $::config_obj->mecab_unicode;
	
	my $arg;
	if (-e $self->{target_temp}) {
		$arg = ">>:encoding($icode)";
	} else {
		$arg = ">:encoding($icode)";
	}

	open (TMPO, $arg, $self->{target_temp}) or
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		)
	;

	print TMPO $self->{store};
	close (TMPO);

	$self->{store} = '';
	return $self;
}

sub exec_error_mes{
	return kh_msg->get('error');
}


1;
