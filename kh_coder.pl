#!/usr/local/bin/perl

=head1 COPYRIGHT

Copyright (C) 2001-2013 �����̰� <http://koichi.nihon.to/psnl>

�ܥץ������ϥե꡼�����եȥ������Ǥ���

���ʤ��ϡ�Free Software Foundation ����ɽ����GNU���̸�ͭ���ѵ������The GNU General Public License�ˤΡ֥С������2�װ����Ϥ���ʹߤγƥС��������椫�餤���줫�����򤷡����ΥС������������˽��ä��ܥץ���������ѡ������ۡ��ޤ����ѹ����뤳�Ȥ��Ǥ��ޤ���

�ܥץ�������ͭ�ѤȤϻפ��ޤ��������ۤ������äƤϡ��Ծ����ڤ�������ŪŬ�����ˤĤ��Ƥΰ��ۤ��ݾڤ�ޤ�ơ������ʤ��ݾڤ�Ԥ��ޤ���

�ܺ٤ˤĤ��Ƥ�GNU���̸�ͭ���ѵ�������ɤ߲�������GNU���̸�ͭ���ѵ�������ܥץ������Υޥ˥奢���������ź�դ���Ƥ��ޤ������뤤��<http://www.gnu.org/licenses/>�Ǥ⡢GNU���̸�ͭ���ѵ������������뤳�Ȥ��Ǥ��ޤ���

=cut

$| = 1;

use strict;

use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

$kh_version = "3.Alpha.10b";

BEGIN {
	# �ǥХå��ѡ�
	#open (STDERR,">stderr.txt") or die;

	use Jcode;
	require kh_lib::Jcode_kh if $] > 5.008 && eval 'require Encode::EUCJPMS';

	use Encode::Locale;
	eval {
		binmode STDOUT, ":encoding(console_out)";
	};
	warn $@ if $@;

	my $locale_fs = 1;
	eval {
		Encode::decode('locale_fs', $ENV{'PWD'});
	};
	if ( $@ ){
		warn $@;
		$locale_fs = 0;
	}

	# for Windows [1]
	use Cwd;
	if ($^O eq 'MSWin32'){
		# Cwd.pm�ξ��
		no warnings 'redefine';
		sub Cwd::_win32_cwd {
			if (defined &DynaLoader::boot_DynaLoader) {
				$ENV{'PWD'} = Win32::GetCwd();
			}
			else { # miniperl
				chomp($ENV{'PWD'} = `cd`);
			}
			$ENV{'PWD'} = Encode::decode('locale_fs', $ENV{'PWD'}) if $locale_fs;
			$ENV{'PWD'} =~ s:\\:/:g ;
			$ENV{'PWD'} = Encode::encode('locale_fs', $ENV{'PWD'}) if $locale_fs;
			return $ENV{'PWD'};
		};
		*cwd = *Cwd::cwd = *Cwd::getcwd = *Cwd::fastcwd = *Cwd::fastgetcwd = *Cwd::_NT_cwd = \&Cwd::_win32_cwd;
		use warnings 'redefine';
	}

	# �⥸�塼��Υѥ����ɲ�
	unshift @INC, cwd.'/kh_lib';

	# for Windows [2]
	if ($^O eq 'MSWin32'){
		# ���󥽡����Ǿ���
		require Win32::Console;
		Win32::Console->new->Title('Console of KH Coder');
		Win32::Sleep(50);
		if (defined($PerlApp::VERSION) && substr($PerlApp::VERSION,0,1) >= 7 ){
			require Win32::API;
			my $FindWindow = new Win32::API('user32', 'FindWindow', 'PP', 'N');
			my $ShowWindow = new Win32::API('user32', 'ShowWindow', 'NN', 'N');
			my $hw = $FindWindow->Call( 0, 'Console of KH Coder' );
			$ShowWindow->Call( $hw, 7 );
		}
		$SIG{TERM} = $SIG{QUIT} = sub{ exit; };
		# ���ץ�å���
		#require Tk::Splash;
		#$splash = Tk::Splash->Show(
		#	Tk->findINC('kh_logo.bmp'),
		#	400,
		#	109,
		#	'',
		#);
		# Tk��Invoke���ʤ��ޥ������å��ѤΥ��ץ�å���
		if (eval 'require Win32::GUI::SplashScreen'){
			require Tk::Splash; # findINC�ؿ������뤿��
			Win32::GUI::SplashScreen::Show(
				-file => Tk->findINC('kh_logo.bmp'),
				-mintime => 3,
			);
		}
		# ����
		require Tk::Clipboard;
		require Tk::Clipboard_kh;
	} 
	# for Linux & Others
	else {
		use Tk;
		my $version_tk = $Tk::VERSION;
		if (length($version_tk) > 7){
			$version_tk = substr($version_tk,0,7);
		}
		if ($] > 5.008 && $version_tk <= 804.029){
			require Tk::FBox;
			require Tk::FBox_kh;
		}
	}

	# ������ɤ߹���
	require kh_sysconfig;
	$config_obj = kh_sysconfig->readin('./config/coder.ini',&cwd);
}

use Tk;
use mysql_ready;
use mysql_words;
use mysql_conc;
use kh_project;
use kh_projects;
use kh_morpho;
use gui_window;

# Say hello
print "\nkhcoder version $kh_version, Copyright (C) 2001-2020 Koichi Higuchi\nkhcoder comes with ABSOLUTELY NO WARRANTY.\nThis is free software, and you are welcome to redistribute it\nunder certain conditions. All details here:\nhttps://www.gnu.org/licenses/old-licenses/gpl-2.0.txt\n\n";
print "This is KH Coder $kh_version on $^O.\n";
print "CWD: ", $config_obj->cwd, "\n";

# Windows�ǥѥå������Ѥν����
if (
	   ($::config_obj->os eq 'win32')
	&& $::config_obj->all_in_one_pack
){
	use kh_all_in_one;
	kh_all_in_one->init;
}

# Mac OS X�ǥѥå������Ѥν����
if (
	   ($^O eq 'darwin')
	&& $::config_obj->all_in_one_pack
){
	use kh_all_in_mac;
	kh_all_in_mac->init;
}

# R�ν����
use Statistics::R;

no  warnings 'redefine';
*Statistics::R::output_chk = sub {return 1};
use warnings 'redefine';

if (
	   (
			   length($::config_obj->r_path)
			&& -e $::config_obj->os_path( $::config_obj->r_path )
		)
	|| ( not length($::config_obj->r_path) )
){
	$::config_obj->{R} = Statistics::R->new(
		r_bin   => $::config_obj->os_path( $::config_obj->r_path ),
		#r_dir   => $::config_obj->os_path( $::config_obj->r_dir  ),
		log_dir => $::config_obj->{cwd}.'/config/R-bridge',
		tmp_dir => $::config_obj->{cwd}.'/config/R-bridge',
	);
}

if ($::config_obj->{R}){
	$ENV{LANGUAGE} = 'EN';
	$::config_obj->{R}->startR;

	if ($::config_obj->os ne 'win32'){
		$::config_obj->{R}->send('Sys.setlocale(category="LC_ALL",locale="ja_JP.UTF-8")');
	}

	$::config_obj->{R}->send('dummy_d <- matrix(1:9, nrow=3, ncol=3)');
	$::config_obj->{R}->send('dummy_r <- cmdscale(dist(dummy_d), k=1)');
	$::config_obj->{R}->read();
	$::config_obj->{R}->output_chk(1);
} else {
	$::config_obj->{R} = 0;
}

chdir ($::config_obj->{cwd});
$::config_obj->R_version;

# �ޥ������åɽ����ν���
use my_threads;
my_threads->init;

# GUI�γ���
$main_gui = gui_window::main->open;
MainLoop;

__END__

# �ƥ����ѥץ��������Ȥ򳫤�
kh_project->temp(
	target  =>
		'F:/home/Koichi/Study/perl/test_data/STATS_News-IT-2004/2004p.txt',
	#	'E:/home/higuchi/perl/core/data/SalaryMan/both_all.txt',
	dbname  =>
		'khc13',
	#	'khc2',
)->open;
$::main_gui->close_all;
$::main_gui->menu->refresh;
$::main_gui->inner->refresh;

# �����ͥåȥ������
my $win_net = gui_window::word_netgraph->open;
$win_net->calc;

# �����ͥåȥ���Ρ�Ĵ���פ򷫤��֤�
my $n = 0;
while (1){
	my $c = $::main_gui->get('w_word_netgraph_plot');

	my $cc = gui_window::r_plot_opt::word_netgraph->open(
		command_f => $c->{plots}[$c->{ax}]->command_f,
		size      => $c->original_plot_size,
	);
	
	my $en = 100 + int( rand(50) );
	$cc->{entry_edges_number}->delete(0,'end');
	$cc->{entry_edges_number}->insert(0,$en);
	
	$cc->calc;
	
	++$n;
	print "#### $n ####\n";
	
	my $sn = int(rand(5));
	sleep $sn;
}

MainLoop;

