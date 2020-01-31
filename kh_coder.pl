#!/usr/local/bin/perl

=head1 COPYRIGHT

Copyright (C) 2001-2013 鐃緒申鐃緒申鐃縮逸申 <http://koichi.nihon.to/psnl>

鐃旬プワ申鐃緒申鐃緒申鐃熟フリー鐃緒申鐃緒申鐃春トワ申鐃緒申鐃緒申鐃叔わ申鐃緒申

鐃緒申鐃淑わ申鐃熟￥申Free Software Foundation 鐃緒申鐃緒申表鐃緒申鐃緒申GNU鐃緒申鐃縮醐申有鐃緒申鐃術居申鐃緒申鐃緒申鐃�The GNU General Public License鐃祝の「バ￥申鐃緒申鐃緒申鐃�2鐃竣逸申鐃緒申鐃熟わ申鐃緒申聞澆粒謄弌鐃緒申鐃緒申鐃緒申鐃緒申罎�申蕕わ申鐃緒申譴�申鐃緒申鐃緒申鬚掘鐃緒申鐃緒申離弌鐃緒申鐃緒申鐃緒申鐃緒申鐃緒申鐃緒申暴鐃緒申辰鐃緒申椒廛鐃緒申鐃緒申鐃緒申鐃緒申鐃術￥申鐃緒申鐃緒申鐃循￥申鐃殉わ申鐃緒申鐃術刻申鐃緒申鐃暑こ鐃夙わ申鐃叔わ申鐃殉わ申鐃緒申

鐃旬プワ申鐃緒申鐃緒申鐃緒申有鐃術とは思わ申鐃殉わ申鐃緒申鐃緒申鐃緒申鐃循わ申鐃緒申鐃緒申鐃獣ては￥申鐃峻常申鐃緒申鐃准わ申鐃緒申鐃緒申鐃緒申的適鐃緒申鐃緒申鐃祝つわ申鐃銃の逸申鐃循わ申鐃楯証わ申泙鐃銃￥申鐃緒申鐃緒申鐃淑わ申鐃楯証わ申圓鐃緒申泙鐃緒申鐃�

鐃旬細につわ申鐃銃わ申GNU鐃緒申鐃縮醐申有鐃緒申鐃術居申鐃緒申鐃緒申鐃緒申匹濂鐃緒申鐃緒申鐃緒申鐃�GNU鐃緒申鐃縮醐申有鐃緒申鐃術居申鐃緒申鐃緒申鐃緒申椒廛鐃緒申鐃緒申鐃緒申離泪縫絅�申鐃緒申鐃緒申鐃緒申鐃緒申添鐃春わ申鐃緒申討鐃緒申泙鐃緒申鐃緒申鐃緒申襪わ申鐃�<http://www.gnu.org/licenses/>鐃叔も、GNU鐃緒申鐃縮醐申有鐃緒申鐃術居申鐃緒申鐃緒申鐃緒申鐃緒申鐃緒申鐃暑こ鐃夙わ申鐃叔わ申鐃殉わ申鐃緒申

=cut

$| = 1;

use strict;

use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

$kh_version = "3.Alpha.10b";

BEGIN {
	# 鐃叔バッワ申鐃術￥申
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
		# Cwd.pm鐃塾常申鐃�
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

	# 鐃盾ジ鐃遵ー鐃緒申離僖鐃緒申鐃緒申媛鐃�
	unshift @INC, cwd.'/kh_lib';

	# for Windows [2]
	if ($^O eq 'MSWin32'){
		# 鐃緒申鐃藷ソ￥申鐃緒申鐃叔常申鐃緒申
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
		# 鐃緒申鐃竣ワ申奪鐃緒申鐃�
		#require Tk::Splash;
		#$splash = Tk::Splash->Show(
		#	Tk->findINC('kh_logo.bmp'),
		#	400,
		#	109,
		#	'',
		#);
		# Tk鐃緒申Invoke鐃緒申鐃淑わ申鐃殉ワ申鐃緒申鐃緒申鐃獣ワ申鐃術のワ申鐃竣ワ申奪鐃緒申鐃�
		if (eval 'require Win32::GUI::SplashScreen'){
			require Tk::Splash; # findINC鐃舜随申鐃緒申鐃緒申鐃暑た鐃緒申
			Win32::GUI::SplashScreen::Show(
				-file => Tk->findINC('kh_logo.bmp'),
				-mintime => 3,
			);
		}
		# 鐃緒申鐃緒申
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

	# 鐃緒申鐃緒申鐃緒申匹濆鐃緒申鐃�
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
print "\nKH Coder version $kh_version, Copyright (C) 2001-2020 Koichi Higuchi\nFork with minor changes by David-O. Mercier and Simon R.-Girard\n\nKH Coder comes with ABSOLUTELY NO WARRANTY.\nThis is free software, and you are welcome to redistribute it\nunder certain conditions. All details here:\nhttps://www.gnu.org/licenses/old-licenses/gpl-2.0.txt\n\n";
print "This is KH Coder $kh_version running on $^O.\n";
print "CWD: ", $config_obj->cwd, "\n";

# Windows鐃叔パッワ申鐃緒申鐃緒申鐃術の緒申鐃緒申鐃�
if (
	   ($::config_obj->os eq 'win32')
	&& $::config_obj->all_in_one_pack
){
	use kh_all_in_one;
	kh_all_in_one->init;
}

# Mac OS X鐃叔パッワ申鐃緒申鐃緒申鐃術の緒申鐃緒申鐃�
if (
	   ($^O eq 'darwin')
	&& $::config_obj->all_in_one_pack
){
	use kh_all_in_mac;
	kh_all_in_mac->init;
}

# R鐃塾緒申鐃緒申鐃�
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
		$::config_obj->{R}->send('Sys.setlocale(category="LC_ALL",locale="en_CA.UTF-8")');
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

# 鐃殉ワ申鐃緒申鐃緒申鐃獣ド緒申鐃緒申鐃塾緒申鐃緒申
use my_threads;
my_threads->init;

# GUI鐃塾鰹申鐃緒申
$main_gui = gui_window::main->open;
MainLoop;

__END__

# 鐃銃ワ申鐃緒申鐃術プワ申鐃緒申鐃緒申鐃緒申鐃夙を開わ申
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

# 鐃緒申鐃緒申鐃粛ットワー鐃緒申鐃緒申鐃緒申
my $win_net = gui_window::word_netgraph->open;
$win_net->calc;

# 鐃緒申鐃緒申鐃粛ットワー鐃緒申鐃塾￥申調鐃緒申鐃竣を繰わ申鐃瞬わ申
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

