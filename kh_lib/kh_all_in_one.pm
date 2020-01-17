package kh_all_in_one;
use strict;

#-------------------------------#
#   All In One �Ǥε�ư����λ   #
#-------------------------------#

# All In One�ǤǤϡ�
# (1)��config\coder.ini�פ˲����������ä���
#	all_in_one_pack	1
#	sql_username	khc
#	sql_password	khc
#	sql_host	localhost
#	sql_port	3307
# (2) Ʊ������MySQL������
#	�桼��������: khc[khc], root[khcallinone]
#	��khc.ini�פ�ź�դ���

sub init{
	# ���Ѳ�ǽ�ʥ�����̤����
	require Win32::SystemInfo;
	my %mHash = (AvailPhys => 0);
	Win32::SystemInfo::MemoryStatus(\%mHash,'MB');
	$mHash{AvailPhys} = 32 if $mHash{AvailPhys} < 32;
	$mHash{AvailPhys} = int($mHash{AvailPhys});
	$mHash{AvailPhys} = 2048 if $mHash{AvailPhys} > 2048;
	print "Available Physical Memory: $mHash{AvailPhys}MB\n";
	$mHash{AvailPhys} = $mHash{AvailPhys} - 500;
	$mHash{AvailPhys} = 16 if $mHash{AvailPhys} < 16;

	# ��䥤Υѥ�����
	if (
		not -e $::config_obj->chasen_path
		and -e $::config_obj->cwd.'/dep/chasen/chasen.exe'
	) { 
		$::config_obj->chasen_path(
			$::config_obj->cwd.'/dep/chasen/chasen.exe'
		);
	}

	# Mecab�Υѥ�����
	if (
		not -e $::config_obj->mecab_path
		and -e $::config_obj->cwd.'/dep/mecab/bin/mecab.exe'
	) { 
		$::config_obj->mecab_path(
			$::config_obj->cwd.'/dep/mecab/bin/mecab.exe'
		);
	}
	
	# FreeLIng�Υѥ�����
	if (
		not -d $::config_obj->freeling_dir
		and -d $::config_obj->cwd.'/dep/freeling40'
	) { 
		$::config_obj->freeling_dir(
			$::config_obj->cwd.'/dep/freeling40'
		);
	}
	
	# HanDic�Υѥ�����
	if (
		not -d $::config_obj->han_dic_path
		and -d $::config_obj->cwd.'/dep/handic'
	) { 
		$::config_obj->han_dic_path(
			$::config_obj->cwd.'/dep/handic'
		);
	}
	
	# Stanford segmenter�Υѥ�����
	if (
		not -d $::config_obj->stanf_seg_path
		and -d $::config_obj->cwd.'/dep/stanford-segmenter'
	) { 
		$::config_obj->stanf_seg_path(
			$::config_obj->cwd.'/dep/stanford-segmenter'
		);
	}

	# Stanford POS Tagger�Υѥ�����
	if (
		not -e $::config_obj->stanf_tagger_path_en
		and -e $::config_obj->cwd.'/dep/stanford-postagger/models/wsj-0-18-left3words-distsim.tagger'
	) {
		$::config_obj->stanf_tagger_path_en(
			$::config_obj->cwd.'/dep/stanford-postagger/models/wsj-0-18-left3words-distsim.tagger'
		);
	}

	if (
		not -e $::config_obj->stanf_tagger_path_cn
		and -e $::config_obj->cwd.'/dep/stanford-postagger/models/chinese-distsim.tagger'
	) {
		$::config_obj->stanf_tagger_path_cn(
			$::config_obj->cwd.'/dep/stanford-postagger/models/chinese-distsim.tagger'
		);
	}

	if (
		not -e $::config_obj->stanf_jar_path
		and -e $::config_obj->cwd.'/dep/stanford-postagger/stanford-postagger.jar'
	) {
		$::config_obj->stanf_jar_path(
			$::config_obj->cwd.'/dep/stanford-postagger/stanford-postagger.jar'
		);
	}

	# R�Υѥ�����
	if (not -e $::config_obj->r_path){
		require Devel::Platform::Info::Win32;
		my $os_info = Devel::Platform::Info::Win32->new->get_info();
		#use Data::Dumper;
		#print Dumper $os_info;
		
		my $candidate = '';
		if (
			( ($os_info->{wow64} == 1) || ($os_info->{is64bit} == 1) )
			&& -e $::config_obj->cwd.'/dep/R/bin/x64/Rterm.exe'
		){
			$candidate = '/dep/R/bin/x64/Rterm.exe';
		} else {
			$candidate = '/dep/R/bin/i386/Rterm.exe';
		}
		if (-e $::config_obj->cwd.$candidate){
			$::config_obj->r_path( $::config_obj->cwd.$candidate)
		}
	}

	if (
		not -e $::config_obj->r_path
		and -e $::config_obj->cwd.'/dep/R/bin/Rterm.exe'
	){
		$::config_obj->r_path($::config_obj->cwd.'/dep/R/bin/Rterm.exe');
	}
	if (
		not -e $::config_obj->r_path
		and -e $::config_obj->cwd.'/dep/R/bin/i386/Rterm.exe'
	){
		$::config_obj->r_path($::config_obj->cwd.'/dep/R/bin/i386/Rterm.exe');
	}
	$ENV{R_LIBS_USER} = 'DO_NOT_LOAD_FROM_USER_DIR';
	
	# MySQL����ե����뽤����khc.ini��
	my $p1 = $::config_obj->cwd.'/dep/mysql/';
	my $p2 = $::config_obj->cwd.'/dep/mysql/data/';
	my $p3 = $p1; chop $p3;

	my $p4 = $p1.'tmp/';
	unless (-e $p4){
		mkdir($p4) or
			gui_errormsg->open(
				type    => 'file',
				thefile => "$p4"
			)
		;
	}

	open (MYINI,$::config_obj->cwd.'/dep/mysql/khc.ini') or 
		gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini"
		);
	open (MYININ,'>'.$::config_obj->cwd.'/dep/mysql/khc.ini.new') or 
		gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini.new"
		);
	while(<MYINI>){
		chomp;
		if ($_ =~ /^basedir = (.+)$/){
			print MYININ "basedir = $p1\n";
		}
		elsif ($_ =~ /^datadir = (.+)$/){
			print MYININ "datadir = $p2\n";
		}
		elsif ($_ =~ /^tmpdir = (.+)$/){
			print MYININ "tmpdir = $p4\n";
		}
		elsif ($_ =~ /max_heap_table_size/i){
			print MYININ
				"max_heap_table_size = "
				.$mHash{AvailPhys}
				."M\n"
			;
		} else {
			print MYININ "$_\n";
		}
	}
	close (MYINI);
	close (MYININ);
	unlink($::config_obj->cwd.'\dep\mysql\khc.ini') or
		gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini"
		);
	rename(
		$::config_obj->cwd.'\dep\mysql\khc.ini.new',
		$::config_obj->cwd.'\dep\mysql\khc.ini'
	) or gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini.new"
	);

	# MySQL�ε�ư
	return 1 if mysql_exec->connection_test;
	print "Starting MySQL...\n";
	require Win32;
	require Win32::Process;
	my $obj;
	my ($mysql_pass, $cmd_line);
	
	$mysql_pass = $::config_obj->cwd.'\dep\mysql\bin\mysqld.exe';
	$cmd_line = 'bin\mysqld --defaults-file=khc.ini';

	Win32::Process::Create(
		$obj,
		$mysql_pass,
		$cmd_line,
		0,
		Win32::Process->CREATE_NO_WINDOW,
		$p3,
	) or gui_errormsg->open(
		type => 'mysql',
		sql  => 'Start'
	);
	
	$::config_obj->save;
	return 1;
}

sub mysql_stop{
	mysql_exec->shutdown_db_server;
	#system 'c:\apps\mysql\bin\mysqladmin --port=3307 --user=root --password=khcallinone shutdown';
}

1;