package kh_datacheck;
use strict;
use kh_msg;

my $euc_code = '';
if (eval 'require Encode::EUCJPMS'){
	$euc_code = 'eucJP-ms';
} else {
	$euc_code = 'euc-jp';
}

my %errors = (
	'error_m1'  => kh_msg->get('error_m1'),#'Ĺ�����븫�Ф��Ԥ�����ޤ��ʼ�ư�����Բġ�',
	'error_c1'  => kh_msg->get('error_c1'),#'ʸ��������ޤ�Ԥ�����ޤ�',
	'error_c2'  => kh_msg->get('error_c2'),#'˾�ޤ����ʤ�Ⱦ�ѵ��椬�ޤޤ�Ƥ���Ԥ�����ޤ�',
	'error_n1a' => kh_msg->get('error_n1a'),#'Ĺ������Ԥ�����ޤ�',
	'error_n1b' => kh_msg->get('error_n1b'),#'Ĺ�������ˡ����ڡ�������������Ŭ���ʰ��֤˴ޤޤ�Ƥ��ʤ��Ԥ�����ޤ��ʼ�ư�����Բġ�',
	'error_mn' => kh_msg->get('error_mn'),#'H1��H5������Ȥä����Ф������˼��Ԥ��Ƥ����ǽ��������ޤ��ʼ�ư�����Բġ�',
);

sub run{
	my $class = shift;
	my $self;
	$self->{file_source} = $::config_obj->os_path( $::project_obj->file_target );
	$self->{file_temp}   = 'temp.txt';
	while (-e $self->{file_temp}){
		$self->{file_temp} .= '.tmp';
	}
	bless $self, $class;

	# ʸ�������ɤΥ����å�
	my $icode = kh_jchar->check_code($self->{file_source});
	unless (
		   $icode eq 'sjis'
		|| $icode eq 'euc'
		|| $icode eq 'jis'
		|| $icode eq 'utf8'
	) {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('error_charcode')#"ʬ���оݥե������ʸ��������Ƚ�̤˼��Ԥ��ޤ�����\n�ץ��������Խ����̤�ʸ�������ɤ���ꤷ�Ʋ�������\n�ץ��������Խ����̤򳫤��ˤϡ���˥塼����֥ץ������ȡע��ֳ����ע����Խ��פ򥯥�å����ޤ���"
		);
		return 0;
	}

	# ���ƥ����å��μ¹�
	open (SOURCE,"$self->{file_source}") or
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_source}
		);
	open (EDITED,">$self->{file_temp}") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_temp}
		);
	binmode(SOURCE);

	my $n = 1;
	while (<SOURCE>){
		s/\x0D\x0A|\x0D|\x0A/\n/g;
		chomp;
		
		my $ci = Jcode->new($_,$icode)->euc;
		
		my $co = '';
		my ($t_c1, $t_c2, $t_n1a, $t_n1b);
		
		# ���Ф���
		if ($ci =~ /^<(H)([1-5])>(.*)<\/H\2>$/i){
			if (length($ci) > 8000){
				$self->{error_m1}{flag} = 1;
				push @{$self->{error_m1}{array}}, [$n, $ci];
			}
			( $co, $t_c1, $t_c2, $t_n1a, $t_n1b ) = &my_cleaner::exec($3);
			$co = "<$1$2>$co</$1$2>";
		}
		# �̾�ι�
		else {
			( $co, $t_c1, $t_c2, $t_n1a, $t_n1b ) = &my_cleaner::exec($ci);
			if ($t_n1a and not $t_n1b){
				$self->{error_n1a}{flag} = 1;
				push @{$self->{error_n1a}{array}}, [$n, $ci];
			}
			if ($t_n1b){
				$self->{error_n1b}{flag} = 1;
				push @{$self->{error_n1b}{array}}, [$n, $ci];
			}
			if ($ci =~ /<H[1-5]>.+|.+<\/H[1-5]>/i){
				$self->{error_mn}{flag} = 1;
				push @{$self->{error_mn}{array}}, [$n, $ci];
			}
		}
		if ($t_c1){
			$self->{error_c1}{flag} = 1;
			push @{$self->{error_c1}{array}}, [$n, $ci];
		}
		if ($t_c2){
			$self->{error_c2}{flag} = 1;
			push @{$self->{error_c2}{array}}, [$n, $ci];
		}
		++$n;
		print EDITED Jcode->new($co,'euc')->$icode, "\n";
	}
	close (EDITED);
	close (SOURCE);

	# ��ݡ��ȡʳ��סˤκ���
	my $if_errors = 0;
	my $msg = '';
	foreach my $i ('error_m1','error_n1b','error_mn','error_c1','error_c2','error_n1a'){
		if ($self->{$i}{flag}){
			my $num = @{$self->{$i}{array}};
			$msg .= "  * $errors{$i}: $num".kh_msg->get('lines')."\n";
			
			# ��ư�����Ǥ��뤫�ɤ�����ʬ����
			if (
				   $i eq 'error_m1'
				|| $i eq 'error_n1b'
				|| $i eq 'error_mn'
			){
				++$self->{auto_ng};
			} else {
				++$self->{auto_ok};
			}
		}
	}
	if ($msg){
		$msg = kh_msg->get('errors_summary')."\n".$msg; # "ʬ���оݥե�������˰ʲ�����������ȯ������ޤ���������ɽ���ˡ�"
		$self->{repo_sum} = $msg;
	} else {
		$msg = kh_msg->get('looks_good'); #"ʬ���оݥե�������˴��Τ���������ȯ������ޤ���Ǥ�����\n������������˼¹ԤǤ���ȹͤ����ޤ���";
		gui_errormsg->open(
			type => 'msg',
			msg  => $msg,
			icon => 'info',
		);
		$self->clean_up;
		return 1;
	}
	
	# ��ݡ��ȡʾܺ١ˤκ���
	$msg = kh_msg->get('errors_detail')."\n";#"ʬ���оݥե�������˰ʲ�����������ȯ������ޤ����ʾܺ�ɽ���ˡ�\n";
	foreach my $i ('error_m1','error_n1b','error_mn','error_c1','error_c2','error_n1a'){
		if ($self->{$i}{flag}){
			my $num = @{$self->{$i}{array}};
			$msg .= "\n* $errors{$i}: $num".kh_msg->get('lines')."\n";
			
			foreach my $h (@{$self->{$i}{array}}){
				$msg .= "l. $h->[0]\t"; # ���ֹ�
				my $line;
				if (length($h->[1]) > 60 ){
					my $n = 60;
					while (
						   substr($h->[1],0,$n) =~ /\x8F$/
						or substr($h->[1],0,$n) =~ tr/\x8E\xA1-\xFE// % 2
					) {
						--$n;
					}
					$line = substr($h->[1],0,$n)."...\n";
				} else {
					$line .= "$h->[1]\n";
				}
				$line = Encode::decode($euc_code, $line);
				$msg .= $line;
			}
		}
	}
	$msg = Encode::encode('cp932', $msg, sub{'?'});
	$msg = Encode::decode('cp932', $msg);

	$self->{repo_full} = $msg;

	gui_window::datacheck->open($self);
}

#------------------------#
#   �ܺ٥�ݡ��Ȥ���¸   #

sub save{
	my $self = shift;
	my $path = shift;

	open (REPORT,">$path") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $path
		);

	print REPORT Jcode->new( $self->{repo_full} )->euc;

	close (REPORT);
	
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($path);
	}
}

#--------------#
#   ��ư����   #

sub edit{
	my $self = shift;

	# �Хå����å׺���
	my $file_target = $::config_obj->os_path( $::project_obj->file_target );
	$self->{file_backup} = $::project_obj->file_backup;
	rename($file_target, $self->{file_backup}) or
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_backup}
		);

	# �������ִ���
	rename($self->{file_temp}, $file_target) or
		gui_errormsg->open(
			type => 'file',
			thefile => $file_target
		);

	# Diff����
	if ( 0 ) {
	#if (-s $self->{file_backup} < 50*1024*1024 ) {
		$self->{diff} = 1;
		use Text::Diff;
		my $diff = diff(
			$self->{file_backup},
			$::project_obj->file_target,
			{STYLE => "OldStyle"}
		);
		$self->{file_diff} = $::project_obj->file_diff;
		open (DIFFO, ">$self->{file_diff}") or 
			gui_errormsg->open(
				type => 'file',
				thefile => $self->{file_diff}
			);
		print DIFFO $diff;
		close (DIFFO);
	} else {
		$self->{diff} = 0;
	}

	# ��ݡ��ȡʾܺ١ˤκƺ���
	if ($self->{auto_ng}){
		my $msg = kh_msg->get('errors_detail')."\n";#"ʬ���оݥե�������˰ʲ�����������ȯ������ޤ����ʾܺ�ɽ���ˡ�\n";
		foreach my $i ('error_m1','error_n1b','error_mn','error_c1','error_c2','error_n1a'){
			if ($self->{$i}{flag}){
			
				# ��ư�����Ǥ��뤫�ɤ�����ʬ����
				if (
					   $i eq 'error_m1'
					|| $i eq 'error_n1b'
					|| $i eq 'error_mn'
				){
					next;
				}
				
				#unless ( $errors{$i} =~ /��ư�����Բ�/ ){
				#	next;
				#}
				
				my $num = @{$self->{$i}{array}};
				$msg .= "\n* $errors{$i}�� $num".kh_msg->get('lines')."\n";
				
				foreach my $h (@{$self->{$i}{array}}){
					$msg .= "l. $h->[0]\t"; # ���ֹ�
					my $line;
					if (length($h->[1]) > 60 ){
						my $n = 60;
						while (
							   substr($h->[1],0,$n) =~ /\x8F$/
							or substr($h->[1],0,$n) =~ tr/\x8E\xA1-\xFE// % 2
						) {
							--$n;
						}
						$line = substr($h->[1],0,$n)."...\n";
					} else {
						$line = "$h->[1]\n";
					}
					$line = Encode::decode($euc_code, $line);
					$msg .= $line;
				}
			}
		}
		$msg = Encode::encode('cp932', $msg, sub{'?'});
		$msg = Encode::decode('cp932', $msg);
		$self->{repo_full} = $msg;
	} else {
		$self->{repo_full} = kh_msg->get('corrected')."\n"; #"���Τ��������Ϥ��٤ƽ�������Ƥ��ޤ���\n";
	}
	
	#print "back up [0]: $self->{file_backup}\n";
	return $self;
}

#----------------------------------#
#   ��λ����������ե�����κ��   #

sub clean_up{
	my $self = shift;
	unlink($self->{file_temp}) if -e $self->{file_temp};
}

#--------------------------------------------------------------#
#   ������ʸ��������ʬ�����Ⱦ�ѵ��������ޤ��֤��˥롼����   #
#--------------------------------------------------------------#

package my_cleaner;

BEGIN{
	use vars qw($ascii $twoBytes $threeBytes $ctrl $rep $character_undef);
	$ascii           = '[\x00-\x7F]';
	$twoBytes        = '[\x8E\xA1-\xFE][\xA1-\xFE]';
	$threeBytes      = '\x8F[\xA1-\xFE][\xA1-\xFE]';
	$ctrl            = '[[:cntrl:]]';                         # ����ʸ��
	$character_undef = '(?:[\xA9-\xAF\xF5-\xFE][\xA1-\xFE]|'  # 9-15,85-94��
		. '\x8E[\xE0-\xFE]|'                                     # Ⱦ�ѥ�������
		. '\xA2[\xAF-\xB9\xC2-\xC9\xD1-\xDB\xEB-\xF1\xFA-\xFD]|' # 2��
		. '\xA3[\xA1-\xAF\xBA-\xC0\xDB-\xE0\xFB-\xFE]|'          # 3��
		. '\xA4[\xF4-\xFE]|'                                     # 4��
		. '\xA5[\xF7-\xFE]|'                                     # 5��
		. '\xA6[\xB9-\xC0\xD9-\xFE]|'                            # 6��
		. '\xA7[\xC2-\xD0\xF2-\xFE]|'                            # 7��
		. '\xA8[\xC1-\xFE]|'                                     # 8��
		. '\xCF[\xD4-\xFE]|'                                     # 47��
		. '\xF4[\xA7-\xFE]|'                                     # 84��
		. '\x8F[\xA1-\xFE][\xA1-\xFE])';                         # 3�Х���ʸ��
}

sub exec{
	my $t = shift;
	
	my $flag_bake     = 0;
	my $flag_hankaku  = 0;
	my $flag_long     = 0;
	my $flag_longlong = 0;

	if (length($t) > 8000){
		$flag_long = 1;
	}
	
	# morpho_analyzer
	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
	){                                            # chasen��mecab��Ȥ����
		if ($t =~ /'|\\|"|<|>|$ctrl|\|/){
			$flag_hankaku = 1;
		}
		# Ⱦ�ѵ���κ��
		$t =~ s/'/��/g;
		$t =~ s/\\/��/g;
		$t =~ s/"/��/g;
		$t =~ s/\|/��/g;
		$t =~ s/</��/g;
		$t =~ s/>/��/g;
		$t =~ s/$ctrl/ /g;
	} else {                                      # chasen��mecab�ʳ��ξ��
		if ($t =~ /<|>|$ctrl/){
			$flag_hankaku = 1;
		}
		# Ⱦ�ѵ���κ��
		$t =~ s/</��/g;
		$t =~ s/>/��/g;
		$t =~ s/$ctrl/ /g;
	}


	# ��ʸ�����Ľ���
	my @chars = $t =~ /$ascii|$twoBytes|$threeBytes/og;

	my $n = 0;
	my $r = '';
	my $cu = '';
	foreach my $i (@chars){
		# �����Ƥ���ʸ���ϥ����åסʵ����¸ʸ����3�Х���ʸ���⥹���åס�
		if (
			   ($i =~ /$character_undef/o)
			|| (
				   ($i =~ /$ascii/o)
				&! ($i =~ /[[:print:]]/o)
			)
		){
			$flag_bake = 1;
			next;
		}
		
		# Ⱦ�ѥ��ʤν���
		if ($i =~ /(?:\x8E[\xA6-\xDF])/){ 
			$i = Jcode->new($i,'euc')->h2z;
			$flag_hankaku = 1;
		}
		
		# �ޤ��֤�
		if (
			( $n > 200   )
			&& ( $flag_long )
			&& (
				   $i eq ' '
				|| $i eq '��'
				|| $i eq '��'
				|| $i eq '.'
				|| $i eq '-'
				|| $i eq '��'
				|| $i eq '��'
			)
		){
			$cu .= "$i\n";
			$r .= $cu;
			if (length($cu) > 8000){
				$flag_longlong = 1;
			}
			$cu = '';
			$n = -1;
		} else {
			$cu .= $i;
		}
		++$n;
	}
	if (length($cu) > 8000){
		$flag_longlong = 1;
	}
	$r .= "$cu";
	#$r = Jcode->new($r,'euc')->sjis;
	
	return ($r,$flag_bake,$flag_hankaku,$flag_long,$flag_longlong);
}

1;