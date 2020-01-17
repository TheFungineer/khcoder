package kh_r_plot;
use strict;
use utf8;

use kh_r_plot::network;
use kh_r_plot::corresp;
use kh_r_plot::mds;

use vars qw($if_font);
$kh_r_plot::if_font = 0;

my $if_lt25 = 0;
my $debug = 0;

sub new{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	# Debug用出力 0
	if ($::config_obj->r_plot_debug){
		$self->{path} = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name};
		my $file_debug = $self->{path}.'_0.r';
		open (RDEBUG, '>encoding(utf8)', $file_debug) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_debug,
			)
		;
		print RDEBUG
			"# command_f\n",
			$self->{command_f},
			"\n\n# command_a\n",
			$self->{command_a}
		;
		close (RDEBUG)
	}
	
	$self->{command_a} = '' unless defined( $self->{command_a} );
	$self->{command_s} = '' unless defined( $self->{command_s} );
	return undef unless $::config_obj->R;
	
	# ファイル名
	$self->{path} = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name};

	# コマンドの文字コード
	if ( utf8::is_utf8($self->{command_f}) ){
		# It's OK!
	} else {
		$self->{command_f} = Encode::decode('utf8', Jcode->new($self->{command_f})->utf8);
		$self->{command_a} = Encode::decode('utf8', Jcode->new($self->{command_a})->utf8);
		$self->{command_s} = Encode::decode('utf8', Jcode->new($self->{command_s})->utf8);
		warn( "Warn: R commands are not decoded!\n" );
	}

	# コマンドから日本語コメントを削除
	if (
		   ($::config_obj->os eq 'win32')
		&! ($::project_obj->morpho_analyzer_lang eq 'jp')
	){
		$self->{command_f} =~ s/#.*?\p{Hiragana}.*?\n/\n/go;
		$self->{command_f} =~ s/#.*?\p{Katakana}.*?\n/\n/go;
		$self->{command_f} =~ s/#.*?\p{Han}.*?\n/\n/go;
		$self->{command_a} =~ s/#.*?\p{Hiragana}.*?\n/\n/go;
		$self->{command_a} =~ s/#.*?\p{Katakana}.*?\n/\n/go;
		$self->{command_a} =~ s/#.*?\p{Han}.*?\n/\n/go;
		$self->{command_s} =~ s/#.*?\p{Hiragana}.*?\n/\n/go;
		$self->{command_s} =~ s/#.*?\p{Katakana}.*?\n/\n/go;
		$self->{command_s} =~ s/#.*?\p{Han}.*?\n/\n/go;
	}

	# コマンドの改行コード
	$self->{command_f} =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$self->{command_a} =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$self->{command_s} =~ s/\x0D\x0A|\x0D|\x0A/\n/g;

		# command_sはプロットの保存専用コード。
		# 現在はMDSでのみ使用。

	my $command = '';
	if (length($self->{command_a})){
		$command = $self->{command_a};
	} else {
		$command = $self->{command_f};
	}
	
	# Delete characters outside of the current locale (Win32)
	if ($::config_obj->os eq 'win32') {
		my %locwin = (
			'jp' => 'cp932',
			'en' => 'cp1252',
			'cn' => 'cp936',
			'de' => 'cp1252',
			'es' => 'cp1252',
			'fr' => 'cp1252',
			'it' => 'cp1252',
			'nl' => 'cp1252',
			'pt' => 'cp1252',
			'kr' => 'cp949',
			'ca' => 'cp1252',
			'ru' => 'cp1251',
			'sl' => 'cp1251',
		);
		my $lang = $::project_obj->morpho_analyzer_lang;
		$lang = $locwin{$lang};
		$command = Encode::encode($lang, $command, sub{'?'} );
		$command = Encode::decode($lang, $command);
	}
	
	# Debug用出力 1
	if ($::config_obj->r_plot_debug){
		my $file_debug = $self->{path}.'.r';
		open (RDEBUG, '>encoding(utf8)', $file_debug) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_debug,
			)
		;
		print RDEBUG
			"# command_f\n",
			$self->{command_f},
			"\n\n# command_a\n",
			$self->{command_a}
		;
		close (RDEBUG)
	}
	
	# Linux用フォント設定
	if ( ($::config_obj->os ne 'win32') and ($kh_r_plot::if_font == 0) ){
		system('xset fp rehash');
		$::config_obj->R->output_chk(0);
		if ( $::config_obj->R_version < 207 ){
			# 2.7以前
			$::config_obj->R->send(
				 'options(X11fonts = c('
				.'"-*-gothic-%s-%s-normal--%d-*-*-*-*-*-*-*",'
				.'"-adobe-symbol-*-*-*-*-%d-*-*-*-*-*-*-*"))'
			);
		} else {
			# 2.7以降
			$::config_obj->R->send(
				 'X11.options(fonts = c('
				.'"-*-gothic-%s-%s-normal--%d-*-*-*-*-*-*-*",'
				.'"-adobe-symbol-*-*-*-*-%d-*-*-*-*-*-*-*"))'
			);
		}

		# Cairo
		unless ($^O =~ /darwin/i ){
			my $f = $::config_obj->font_plot_current;
			$::config_obj->R->send(
				 "try( library(Cairo) )\n"
				."try( CairoFonts(\n"
				."	regular    =\"$f:style=Regular\",\n"
				."	bold       =\"$f:style=Regular,Bold\",\n"
				."	italic     =\"$f:style=Regular,Italic\",\n"
				."	bolditalic =\"$f:style=Regular,Bold Italic,BoldItalic\"\n"
				."))"
			);
		}
		$::config_obj->R->output_chk(1);
		$kh_r_plot::if_font = 1;
	}

	# Windows用の設定
	if ( ($::config_obj->os eq 'win32') and ($kh_r_plot::if_font == 0) ){
		print "loading Cairo...\n";
		$::config_obj->R->output_chk(0);
		$::config_obj->R->send( "try( library(Cairo) )" );
		$::config_obj->R->output_chk(1);
		$kh_r_plot::if_font = 1;
	}

	# Rのバージョンが2.5.0より小さい場合の対処
	unless ($if_lt25){
		if ($::config_obj->R_version > 205){
			$if_lt25 = 1;
		} else {
			$::config_obj->R->output_chk(0);
			$::config_obj->R->send(
				'as.graphicsAnnot <- function(x) if (is.language(x) || !is.object(x)) x else as.character(x)'
			);
			$::config_obj->R->output_chk(1);
			$if_lt25 = 2;
			#print "as.graphicsAnnot defined.\n";
		}
	}

	# width・heightのチェック
	$self->{width}  = $::config_obj->plot_size_codes unless defined($self->{width});
	$self->{height} = $::config_obj->plot_size_codes unless defined($self->{height});
	
	unless (
		   (length($self->{width} ) == 0 || $self->{width}  =~ /^[0-9]+$/)
		&& (length($self->{height}) == 0 || $self->{height} =~ /^[0-9]+$/)
	){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('illegal_plot_size') # プロットサイズの指定が不正です
		);
		return 0;
	}

	$self->{font_size} = $::config_obj->plot_font_size / 100 unless $self->{font_size};

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send("the_warning <<- \"\"\n");
	print "kh_r_plot::new lock ok.\n" if $debug;
	$self->{path} = $self->R_device(
		$self->{path},
		$self->{width},
		$self->{height},
	);
	print "kh_r_plot::new R.device ok.\n" if $debug;
	$self->set_par;
	print "kh_r_plot::new set_par ok.\n" if $debug;
	$::config_obj->R->send($command);
	print "kh_r_plot::new send ok.\n" if $debug;
	$self->{r_msg} = $::config_obj->R->read;
	print "kh_r_plot::new read ok.\n" if $debug;
	$::config_obj->R->send('dev.off()');
	print "kh_r_plot::new dev.off ok.\n" if $debug;
	$::config_obj->R->unlock;
	print "kh_r_plot::new unlock ok.\n" if $debug;
	$::config_obj->R->output_chk(1);

	# Reading text output from R
	use Encode;
	use Encode::Locale;
	my $loc = 'console_out';
	if (
		   ( $::config_obj->os eq 'win32' )
		&& $::project_obj->morpho_analyzer_lang eq 'cn')
	{
		$loc = 'cp936'
	}
	$self->{r_msg} = Encode::decode($loc, $self->{r_msg});

	# 結果のチェック
	if (
		not (-e $self->{path})
		or ( $self->{r_msg} =~ /error/i )
		or ( index($self->{r_msg},'エラー') > -1 )
		or ( index($self->{r_msg},Jcode->new('エラー','euc')->utf8) > -1 )
	) {
		my $msg = kh_msg->get('faliled_in_plotting');
		$msg .= $self->{r_msg}."\n\n";
		
		$msg .= "No output file." if not -e $self->{path};
		
		print "output file: $self->{path}\n";
		
		gui_errormsg->open(
			type   => 'msg',
			window => \$::main_gui->mw,
			msg    => $msg,
		);
		return 0;
	}
	
	# テキスト出力
	#my $txt = $self->{r_msg};
	#if ( length($txt) ){
	#	$txt = Jcode->new($txt)->sjis if $::config_obj->os eq 'win32';
	#	print "[Begin]--------------------------------------------------[R]\n";
	#	print "$txt\n";
	#	print "[End]----------------------------------------------------[R]\n";
	#}
	
	return $self;
}

sub clear_env{
	#$::config_obj->R->send('print( ls() )');
	#print "before: ", $::config_obj->R->read, "\n";

	$::config_obj->R->output_chk(0);
	$::config_obj->R->send("
		the_list <- ls()
		the_list <- the_list[substring(the_list,0,4) != \"PERL\"]
		if ( length(the_list) > 0 ){
			rm(list=the_list)
		}
		rm(the_list)
	");

	if ( $if_lt25 == 2 ){
		$::config_obj->R->send(
			'as.graphicsAnnot <- function(x) if (is.language(x) || !is.object(x)) x else as.character(x)'
		);
	}
	$::config_obj->R->output_chk(1);

	#$::config_obj->R->send('print( ls() )');
	#print "after: ", $::config_obj->R->read, "\n";

	#print "R env has been cleared.\n";
}

sub set_par{
	my $self = shift;
	my $opt  = shift;
	$opt = '' unless defined($opt);

	$::config_obj->R->output_chk(0);
	$::config_obj->R->send(
		'par(mai=c(0,0,0,0), mar=c(4,4,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )'
	);

	my $font;
	if ($opt eq 'ps_font') {
		$font = $::config_obj->font_pdf_current;
	} else {
		$font = $::config_obj->font_plot_current;
	}
	$::config_obj->R->send( "par(family=\"$font\")" );
	$::config_obj->R->send( "PERL_font_family <- \"$font\"" );

	# Windowsではロケールを設定する
	if ($::config_obj->os eq 'win32') {
		my %loc = (
			'jp' => 'Japanese',
			'en' => 'English',
			'cn' => 'Chinese',
			'de' => 'German',
			'es' => 'Spanish',
			'fr' => 'French',
			'it' => 'Italian',
			'nl' => 'Dutch',
			'pt' => 'Portuguese',
			'kr' => 'Korean',
			'ca' => 'Catalan',
			'ru' => 'Russian',
			'sl' => 'Slovenian',
		);
		
		my $lang = $::project_obj->morpho_analyzer_lang;
		if ($lang eq 'en') {
			$lang = $::config_obj->msg_lang;
		}
		$lang = $loc{$lang};
		if ($lang) {
			$::config_obj->{R}->send("Sys.setlocale(category=\"LC_ALL\",locale=\"$lang\")");
		}
	}
	
	$::config_obj->R->output_chk(1);

	return $self;
}

sub rotate_cls{
	my $self = shift;
	
	unless (eval 'require Image::Magick;'){
		print "Could not rotate the dendrogram: No Image-Magick.\n";
		return $self;
	}
	
	# tempファイルの名前
	my $type = '';
	if ($self->{path} =~ /\.bmp$/){
		$type = 'bmp';
	} else {
		$type = 'png';
	}
	
	# tempファイルにリネーム
	my $temp = "hoge";
	my $n = 0;
	while (-e "$temp$n.$type"){
		++$n;
	}
	$temp = $::config_obj->cwd.'/'."$temp$n.$type";
	use File::Copy;
	copy($self->{path}, $temp);
	#print "$temp, $self->{path}\n";

	# 画像操作
	my $p = Image::Magick->new;
	$p->Read( $::config_obj->uni_path( $temp ) );
	unless ($p->[0]){
		warn("Could not rotate the dendrogram: $!");
		unlink($temp);
		return $self;
	}
	$p->Rotate( degrees=>90 );
	
	if ($self->{width} > 1000){
		# スケール部分切り出し
		my $scale_height = int( 41 * $self->{dpi} / 72 );
		$p->Crop(geometry=> "$self->{height}x$scale_height+0+0");
		
		# 本体切り出し
		print "$temp\n";
		$p->Read( $::config_obj->uni_path( $temp ) );
		unless ($p->[1]){
			warn("Could not rotate the dendrogram: $!");
			unlink($temp);
			return $self;
		}
		$p->[1]->Rotate(degrees=>90);
		my $start = int( $self->{width} * 0.033 + 33 - 10 );
		my $height = int( $self->{width} - $self->{width} * 0.033 +10)-$start;
		$p->[1]->Crop(geometry=> "$self->{height}x$height+0+$start");
		
		# 貼り合わせ
		$p = $p->append(stack => "true");
	}
	
	if ($type eq 'bmp'){ 
		$p->Write(filename=>"$temp", compression=>'None');
	} else {
		$p->Write($temp);
	}
	
	unlink($self->{path});
	rename($temp, $self->{path});

	return $self;
}

sub save{
	my $self = shift;
	my $target_os_path = shift;
	
	my $path;
	$path =
		$::config_obj->cwd
		.'/config/R-bridge/'
		.$::project_obj->dbname
		.'_'
		.$self->{name}
		.'_save'
	;
	
	if (-e $path){
		unlink $path or die("could not delete file: $path");
	}
	#my $temp_os_path = $path;
	
	$path = $::config_obj->uni_path($path);
	$path =~ tr/\\/\//;
	
	$self->clear_env;
	
	if ($target_os_path =~ /\.r$/i){
		$path .= ".r";
		$self->_save_r($path);
	}
	elsif ($target_os_path =~ /\.png$/i){
		$path .= ".png";
		$self->_save_png($path);
	}
	elsif ($target_os_path =~ /\.eps$/i){
		$path .= ".eps";
		$self->_save_eps($path);
	}
	elsif ($target_os_path =~ /\.pdf$/i){
		$path .= ".pdf";
		$self->_save_pdf($path);
	}
	elsif ($target_os_path =~ /\.emf$/i){
		$path .= ".emf";
		$self->_save_emf($path);
	}
	elsif ($target_os_path =~ /\.svg$/i){
		$path .= ".svg";
		$self->_save_svg($path);
	}
	elsif ($target_os_path =~ /\.graphml$/i){
		$path .= ".graphml";
		$self->_save_graphml($path);
	}
	elsif ($target_os_path =~ /\.net$/i){
		$path .= ".net";
		$self->_save_net($path);
	}
	elsif ($target_os_path =~ /\.csv$/i){
		$path .= ".csv";
		$self->_save_csv($path);
	}
	else {
		warn "The file type is not supported yet:\n$target_os_path\n";
	}

	my $temp_os_path = $::config_obj->os_path($path);
	unless ( -e $temp_os_path ){
		warn "failed to save the plot: ".$::config_obj->R->read;
		return 0;
	}
	
	use File::Copy;
	copy($temp_os_path, $target_os_path) or die("failed to copy the file: $temp_os_path, $target_os_path");
}

sub R_device{
	my $self  = shift;
	my $path  = shift;
	my $width = shift;
	my $height = shift;
	
	$path .= '.png';
	unlink($path) if -e $path;
	
	$width  = $::config_obj->plot_size_words unless $width;
	$height = $::config_obj->plot_size_words unless $height;

	# Setup the dpi value
	my $dpi = 72;
	use Statistics::Lite qw(min);
	if (
		(
			   $self->{command_f} =~ /ggdendro/
			|| $self->{command_f} =~ /rect\.hclust/
		)
		and not ( $self->{command_f} =~ /pp_type/ )
	) {                         # dendrogram
		$dpi = int( 72 * ($::config_obj->plot_size_codes / 480) );
	}
	elsif ($self->{command_f} =~ /# dpi: short based\n/){ # short based (codes, mainly)
		$dpi = int( 72 * ( min($width,$height) / 480) );
	}
	elsif ($height == $width) { # square
		$dpi = int( 72 * ($height / 640) ) if $height > 640;
	}
	elsif (
		   $height == $::config_obj->plot_size_codes
		&& $width  == $::config_obj->plot_size_words
	){                          # default rectangle
		$dpi = int( 72 * ($::config_obj->plot_size_words / 640) );
	}
	elsif ( min($width,$height) > 640 ) { # unknown
		$dpi = int( 72 * ( min($width,$height) / 640 ) )
	}

	$dpi = int( $dpi * $self->{font_size} );

	return 0 unless $::config_obj->R;
	$self->{dpi} = $dpi;
	
	my $p = 12 * $dpi / 72;
	#print "point size: $p\n";
	
	my $uni_path = $::config_obj->uni_path($path);
	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=$width, height=$height, unit=\"px\", file=\"$uni_path\", bg = \"white\", type=\"png\", dpi=$dpi)
		} else {
			png(\"$uni_path\", width=$width, height=$height, unit=\"px\", res=$dpi ) # pointsize=$p
		}
	");
	return $path;
}

sub _save_emf{
	my $self = shift;
	my $path = shift;
	
	my $w = 8;
	if ($self->{width} > $self->{height}){
		$w = sprintf("%.5f", 8 * $self->{width} / $self->{height} );
	}
	my $h = 8;
	if ($self->{height} > $self->{width}){
		$h = sprintf("%.5f", 8 * $self->{height} / $self->{width} );
	}
	
	$self->{font_size} = $::config_obj->plot_font_size / 100 unless $self->{font_size};
	my $p = int(12 * $self->{font_size});
	if ($p > 12) {
		my $diff = $p - 12;
		$p = 12 + int($diff * 0.5);
	}
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send( "saving_emf <- 1" );
	$::config_obj->R->send(
		 "win.metafile(filename=\"$path\", width = $w, height = $h, pointsize=$p)"
	);
	$self->set_par;
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send($self->{command_s});
	} else {
		$::config_obj->R->send($self->{command_f});
	}
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_pdf{
	my $self = shift;
	my $path = shift;

	my $w = 8;
	if ($self->{width} > $self->{height}){
		$w = sprintf("%.5f", 8 * $self->{width} / $self->{height} );
	}
	my $h = 8;
	if ($self->{height} > $self->{width}){
		$h = sprintf("%.5f", 8 * $self->{height} / $self->{width} );
	}

	$self->{font_size} = $::config_obj->plot_font_size / 100 unless $self->{font_size};
	my $p = int(12 * $self->{font_size});
	if ($p > 12) {
		my $diff = $p - 12;
		$p = 12 + int($diff * 0.5);
	}

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	
	# Use "cairo_pdf" when the prject language is Russian
	my $lang = '';
	if ( $::project_obj ) {
		$lang = $::project_obj->morpho_analyzer_lang;
	}
	if ($lang eq 'ru') {
		$::config_obj->R->send(
			 "cairo_pdf(file=\"$path\", height = $h, width = $w, "
			."pointsize=$p)"
		);
	} else {
		$::config_obj->R->send(
			 "pdf(file=\"$path\", height = $h, width = $w, "
			."family=\"".$::config_obj->font_pdf_current."\", pointsize=$p)"
		);
	}

	$self->set_par('ps_font');
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send($self->{command_s});
	} else {
		$::config_obj->R->send($self->{command_f});
	}
	$::config_obj->R->send('dev.off()');

	if (
		$lang eq 'ru'
		&& $^O =~ /darwin/
		&& $::config_obj->all_in_one_pack
		&& 0
	) {
		#$::config_obj->R->send(
		#	"embedFonts(\"$path\", fontpaths=\"".$::config_obj->cwd."/deps/fonts\")"
		#);
		$::config_obj->R->send("Sys.setlocale(category=\"LC_ALL\",locale=\"ja_JP.UTF-8\")");
	}
	
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}


sub _save_eps{
	my $self = shift;
	my $path = shift;

	my $w = 8;
	if ($self->{width} > $self->{height}){
		$w = sprintf("%.5f", 8 * $self->{width} / $self->{height} );
	}
	my $h = 8;
	if ($self->{height} > $self->{width}){
		$h = sprintf("%.5f", 8 * $self->{height} / $self->{width} );
	}

	$self->{font_size} = $::config_obj->plot_font_size / 100 unless $self->{font_size};
	my $p = int(12 * $self->{font_size});
	if ($p > 12) {
		my $diff = $p - 12;
		$p = 12 + int($diff * 0.5);
	}

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send( "saving_eps <- 1" );
	
	# Use "cairo_ps" when the prject language is Russian or Korean
	my $lang = '';
	if ( $::project_obj ) {
		$lang = $::project_obj->morpho_analyzer_lang;
	}
	if ($lang eq 'ru' || $lang eq 'kr' || $^O =~ /darwin/i ) {
		$::config_obj->R->send(
			"cairo_ps(\"$path\", height = $h, width = $w, pointsize=$p)"
		);
	} else {
		$::config_obj->R->send(
			 "postscript(\"$path\", horizontal = FALSE, onefile = FALSE,"
			."paper = \"special\", height = $h, width = $w,"
			."family=\"".$::config_obj->font_pdf_current."\",pointsize=$p)"
		);
	}

	$self->set_par('ps_font');
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send($self->{command_s});
	} else {
		$::config_obj->R->send($self->{command_f});
	}
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_png{
	my $self = shift;
	my $path = shift;
	
	my $width = $self->{width};
	my $height = $self->{height};

	$width  = $::config_obj->plot_size_words unless $width;
	$height = $::config_obj->plot_size_words unless $height;

	# Setup the dpi value
	my $dpi = 72;
	use Statistics::Lite qw(min);
	if (
		(
			   $self->{command_f} =~ /ggdendro/
			|| $self->{command_f} =~ /rect\.hclust/
		)
		and not ( $self->{command_f} =~ /pp_type/ )
	) {                         # dendrogram
		$dpi = int( 72 * ($::config_obj->plot_size_codes / 480) );
	}
	elsif ($self->{command_f} =~ /# dpi: short based\n/){ # short based (codes, mainly)
		$dpi = int( 72 * ( min($width,$height) / 480) );
	}
	elsif ($height == $width) { # square
		$dpi = int( 72 * ($height / 640) ) if $height > 640;
	}
	elsif (
		   $height == $::config_obj->plot_size_codes
		&& $width  == $::config_obj->plot_size_words
	){                          # default rectangle
		$dpi = int( 72 * ($::config_obj->plot_size_words / 640) );
	}
	elsif ( min($width,$height) > 640 ) { # unknown
		$dpi = int( 72 * ( min($width,$height) / 640 ) )
	}

	$dpi = int( $dpi * $self->{font_size} );
	$self->{dpi} = $dpi;
	
	my $p = 12 * $dpi / 72;

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;

	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=$width, height=$height, unit=\"px\", file=\"$path\", type=\"png\", bg=\"white\", dpi=$dpi)
		} else {
			png(\"$path\", width=$self->{width}, height=$self->{height}, unit=\"px\", res=$dpi)
		}
	");


	$self->set_par;
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send($self->{command_s});
	} else {
		$::config_obj->R->send($self->{command_f});
	}
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_svg{
	my $self = shift;
	my $path = shift;
	
	$self->{width}  = 480 unless $self->{width};
	$self->{height} = 480 unless $self->{height};
	
	# for darwin
	my $w = 8;
	if ($self->{width} > $self->{height}){
		$w = sprintf("%.5f", 8 * $self->{width} / $self->{height} );
	}
	my $h = 8;
	if ($self->{height} > $self->{width}){
		$h = sprintf("%.5f", 8 * $self->{height} / $self->{width} );
	}

	$self->{font_size} = $::config_obj->plot_font_size / 100 unless $self->{font_size};
	my $p = int(12 * $self->{font_size});
	if ($p > 12) {
		my $diff = $p - 12;
		$p = 12 + int($diff * 0.5);
	}

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;

	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(
				width=$w * 80,
				height=$h * 80,
				file=\"$path\",
				type=\"svg\",
				onefile=TRUE,
				bg=\"transparent\",
				dpi=72,
				units=\"px\",
				pointsize=$p
			)
		} else {
			# for darwin
			library(RSVGTipsDevice)
			devSVGTips(
				\"$path\",
				width=$w,
				height=$h,
				bg=\"white\",
				fg=\"black\",
				toolTipMode=0
			)
		}
	");

	$self->set_par;
	
	# for darwin
	if ($^O =~ /darwin/i){
		$::config_obj->R->send(
			'par(mai=c(0,0,0,0), mar=c(5,4,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )'
		);
	}
	
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send($self->{command_s});
	} else {
		$::config_obj->R->send($self->{command_f});
	}
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	# for darwin (No harm in Windows. But what's this?)
	#my $file_temp = $::config_obj->file_temp;
	#open my $fhi, '<:encoding(eucJP-ms)', $path      or die("file: $path");
	#open my $fho, '>:encoding(utf8)',     $file_temp or die("file: $file_temp");
	#while (<$fhi>){
	#	print $fho $_;
	#}
	#close $fhi;
	#close $fho;
	#unlink $path;
	#rename($file_temp, $path) or die("rename $file_temp, $path");
	
	return 1;
}

sub _save_r{
	my $self = shift;
	my $path = shift;
	$path = $::config_obj->os_path($path);
	
	# 日本語データでOSの文字コードがcp932の場合のみcp932で出力
	my $out_code = 'utf8';
	if (
		   ( $::config_obj->os_code eq 'cp932' )
		&& ( $::project_obj->morpho_analyzer_lang eq 'jp' )
	) {
		$out_code = 'cp932';
	}
	
	my $t = $self->{command_f};
	
	# SOMのための特殊処理
	if ($t =~ /^load\(\"(.+)\"\)/){
		my $file = $1;
		$file = $::config_obj->os_path($file);
		$file .= '_s';
		if ( -e $file ){
			#print "file: $file\n";
			open (my $fh, '<:encoding(utf8)', $file)
				or gui_errormsg->open(
					type    => 'file',
					thefile => $file,
				)
			;
			my $t0 = '';
			while (<$fh>){
				$t0 .= $_;
			}
			close $fh;
			$t =~ s/^load\(\"(.+)\"\)\n//;
			$t = $t0."\n".$t;
		}
	}
	
	open (OUTF, ">:encoding($out_code)", $path) or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $path,
		);
	
	# データをファイル内に記述
	if ( $t =~ /source\(\"(.+)\", encoding=\"UTF-8\"\)/ ){
		my $file_data = $1;
		$file_data = $::config_obj->os_path($file_data);
		open my $fhr, '<:encoding(utf8)', $file_data or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_data,
			);
		while (<$fhr>){
			print OUTF $_;
		}
		close $fhr;
		$t =~ s/source\(\"(.+)\", encoding=\"UTF-8\"\)//;
	}
	if ( $t =~ /source\(\"(.+)\"\)/ ){
		my $file_data = $1;
		$file_data = $::config_obj->os_path($file_data);
		open my $fhr, '<:encoding(cp1251)', $file_data or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_data,
			);
		while (<$fhr>){
			print OUTF $_;
		}
		close $fhr;
		$t =~ s/source\(\"(.+)\"\)//;
	}
	print OUTF $t,"\n";
	close (OUTF);
	
	return 1;
}

sub command_f{
	my $self = shift;
	return $self->{command_f};
}

sub r_msg{
	my $self = shift;
	return $self->{r_msg};
}

sub path{
	my $self = shift;
	return $self->{path};
}

#sub DESTROY{
#	my $self = shift;
#	print "DESTROYed: $self->{name}\n";
#}

1;
