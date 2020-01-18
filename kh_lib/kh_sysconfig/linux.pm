package kh_sysconfig::linux;
use base qw(kh_sysconfig);
use strict;

#----------------------------#
#   ������ɤ߹��ߥ롼����   #
#----------------------------#

sub _readin{
	use Jcode;
	use kh_sysconfig::linux::chasen;
	use kh_sysconfig::linux::mecab;
	use kh_sysconfig::linux::mecab_k;
	use kh_sysconfig::linux::stemming;
	use kh_sysconfig::linux::stanford;
	use kh_sysconfig::linux::freeling;

	my $self = shift;


	# Chasen������
	if (-e $self->chasenrc_path){
		my $flag = 0; my $msg = '(Ϣ���ʻ�';
		if (-e $self->chasenrc_path){
			open (CRC,"$self->{chasenrc_path}") or
				gui_errormsg->open(
					type    => 'file',
					thefile => "$self->{chasenrc_path}"
				);
			while (<CRC>){
				chomp;
				if ($_ eq '; by KH Coder, start.'){
					$flag = 1;
					next;
				}
				elsif ($_ eq '; by KH Coder, end.'){
					$flag = 0;
					next;
				}

				unless ($flag){
					next;
				}
				if ($_ eq "$msg"){
					$self->{use_hukugo} = 1;
				}
			}
			close (CRC);
		}
		unless ($self->{use_hukugo}){
			$self->{use_hukugo} = 0;
		}
	}

	return $self;
}

#------------------#
#   �����ͤ���¸   #
#------------------#

sub save{
	my $self = shift;

	$self = $self->refine_cj;
	if ($self->path_check){
		$self->config_morph;
	}

	$self->save_ini;
	
	return 1;
}

sub save_ini{
	my $self = shift;
	$self = $self->refine_cj;

	my @outlist = (
		'chasenrc_path',
		'grammarcha_path',
		'mecab_unicode',
		'mecabrc_path',
		'stanf_jar_path',
		'stanf_tagger_path_en',
		'stanf_tagger_path_cn',
		'stanf_seg_path',
		'han_dic_path',
		'freeling_dir',
		'freeling_lang',
		'stanford_lang',
		'stemming_lang',
		'last_lang',
		'last_method',
		'c_or_j',
		'msg_lang',
		'msg_lang_set',
		'r_path',
		'r_plot_debug',
		'sqllog',
		'sql_username',
		'sql_password',
		'sql_host',
		'sql_port',
		'multi_threads',
		'mail_if',
		'mail_smtp',
		'mail_from',
		'mail_to',
		'use_heap',
		'all_in_one_pack',
		'font_main',
		'font_plot',
		'font_plot_cn',
		'font_plot_kr',
		'font_plot_ru',
		'font_pdf',
		'font_pdf_cn',
		'font_pdf_kr',
		'kaigyo_kigou',
		'color_DocView_info',
		'color_DocView_search',
		'color_DocView_force',
		'color_DocView_html',
		'color_DocView_CodeW',
		'color_ListHL_fore',
		'color_ListHL_back',
		'plot_size_words',
		'plot_size_codes',
		'plot_font_size',
		'DocView_WrapLength_on_Win9x',
		'DocSrch_CutLength',
		'app_html',
		'app_csv',
		'app_pdf',
	);

	my $f = $self->{ini_file};
	open (INI, '>encoding(utf8)', $f) or
		gui_errormsg->open(
			type    => 'file',
			thefile => ">$f"
		);
	foreach my $i (@outlist){
		my $value = $self->$i(undef,'1');
		$value = '' unless defined $value;
		print INI "$i\t$value\n";
	}
	foreach my $i (keys %{$self}){
		if ( index($i,'w_') == 0 ){
			my $value = $self->win_gmtry($i);
			$value = '' unless defined $value;
			print INI "$i\t$value\n";
		}
	}
	if ($self->{main_window}){
		print INI "main_window\t$self->{main_window}";
	}
	close (INI);
	return 1;

}

#--------------------------------#
#   �ʲ��������ͤ��֤��롼����   #
#--------------------------------#

#--------------------#
#   �����ǲ��ϴط�   #

sub chasenrc_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{chasenrc_path} = $new;
	}
	return $self->{chasenrc_path};
}

sub grammarcha_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{grammarcha_path} = $new;
	}
	return $self->{grammarcha_path};
}

#sub juman_path{
#	my $self = shift;
#	my $new = shift;
#	if ($new){
#		$self->{juman_path} = $new;
#	}
#	return $self->{juman_path};
#}


#--------------------------#
#   �������ץꥱ�������   #

sub app_html{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_html} = $new;
	}
	if ($self->{app_html}){
		return $self->{app_html};
	} else {
		return 'firefox \'%s\' &';
	}
}

sub app_pdf{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_pdf} = $new;
	}
	if ($self->{app_pdf}){
		return $self->{app_pdf};
	} else {
		return 'acroread %s &';
	}
}

sub app_csv{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_csv} = $new;
	}
	if ($self->{app_csv}){
		return $self->{app_csv};
	} else {
		return 'soffice -calc %s &';
	}
}

#-------------#
#   GUI�ط�   #

sub mw_entry_length{
	return 30;
}

sub font_main{
	my $self = shift;
	my $new  = shift;
	$self->{font_main} = $new         if length($new);
	$self->{font_main} = 'kochi gothic,10'  unless length($self->{font_main});
	return $self->{font_main};
}

sub font_plot{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot} = $new         if defined($new) && length($new);
	unless ( length($self->{font_plot}) ){
		if ( $^O =~ /darwin/){
			$self->{font_plot} = 'Hiragino Kaku Gothic Pro W3';
		} else {
			$self->{font_plot} = 'IPAPGothic';
		}
	}
	return $self->{font_plot};
}

sub font_plot_cn{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_cn} = $new if defined($new) && length($new);
	unless ( length($self->{font_plot_cn}) ){
		if ( $^O =~ /darwin/){
			$self->{font_plot_cn} = 'STHeiti';
		} else {
			$self->{font_plot_cn} = 'Droid Sans Fallback';
		}
	}
	return $self->{font_plot_cn};
}

sub font_plot_kr{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_kr} = $new         if defined($new) && length($new);
	unless ( length($self->{font_plot_kr}) ){
		if ( $^O =~ /darwin/){
			$self->{font_plot_kr} = 'AppleGothic';
		} else {
			$self->{font_plot_kr} = 'UnDotum';
		}
	}
	return $self->{font_plot_kr};
}

sub font_plot_ru{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_ru} = $new         if defined($new) && length($new);
	unless ( length($self->{font_plot_ru}) ){
		if ( $^O =~ /darwin/){
			$self->{font_plot_ru} = 'Helvetica';
		} else {
			$self->{font_plot_ru} = 'Droid Sans';
		}
	}
	return $self->{font_plot_ru};
}


1;

__END__
