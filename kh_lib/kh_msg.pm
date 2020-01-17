package kh_msg;

use strict;
use YAML qw(LoadFile);

use utf8;
use Encode;

my $utf8 = find_encoding('utf8');

my $msg;
my $msg_fb;

my $debug = 1;

sub get{
	# キー作成
	          shift;
	my $key = shift;
	my $caller = shift;
	
	if ( length($caller) ){
	#	print "kh_msg: caller is specified: $caller, $key\n" if $debug;
	}
	$caller = (caller)[0]    unless length($caller);
	
	if ($key =~ /^(.+)\->(.+)$/){
		$key    = $2;
		$caller = $1;
		#print "kh_msg: caller is specified: $caller, $key\n" if $debug;
	}
		
	$caller =~ s/::(linux|win32)//go;

	# メッセージをロード
	&load unless $msg;

	# メッセージを返す
	my $t = '';
	if ( defined( $msg->{$caller}{$key} ) ){
		$t = $msg->{$caller}{$key};
	}
	elsif ( defined($msg_fb->{$caller}{$key}) ) {
		$t = $msg_fb->{$caller}{$key};
		print "kh_msg: fall back: $caller, $key\n";
	} else {
		$t = 'error: '.$key;
		print "kh_msg: no msg: $caller, $key\n";
	}
	
	unless ( utf8::is_utf8($t) ){
		$t = $utf8->decode($t);
	}
	return $t;
}

sub pget{
	# キー作成
	          shift;
	my $key = shift;
	my $caller = shift;
	
	$caller = (caller)[0]    unless length($caller);
	
	if ($key =~ /^(.+)\->(.+)$/){
		$key    = $2;
		$caller = $1;
		#print "kh_msg: caller is specified: $caller, $key\n" if $debug;
	}
		
	$caller =~ s/::(linux|win32)//go;

	# メッセージをロード
	&load unless $msg;

	# メッセージを返す
	my $the_msg;
	if (
		   ( $::project_obj->morpho_analyzer_lang eq $::config_obj->msg_lang )
		|| ( $::project_obj->morpho_analyzer_lang eq 'en' )
		|| ( $::config_obj->msg_lang eq 'en' )
		|| (
				   ( $::project_obj->morpho_analyzer_lang eq 'cn' )
				&& ( $::config_obj->msg_lang eq 'jp' )
		)
	){
		$the_msg = $msg;
	} else {
		$the_msg = $msg_fb;
	}
	
	my $t = '';
	if ( defined( $the_msg->{$caller}{$key} ) ){
		$t = $the_msg->{$caller}{$key};
	} else {
		$t = 'error: '.$key;
		print "kh_msg::pget: no msg: $caller, $key\n";
	}
	
	unless ( utf8::is_utf8($t) ){
		$t = $utf8->decode($t);
	}
	return $t;
}

sub gget{
	# キー作成
	          shift;
	my $key = shift;
	my $caller = 'global';
	
	# メッセージをロード
	&load unless $msg;

	# メッセージを返す
	my $t = '';
	if ( defined( $msg->{$caller}{$key} ) ){
		$t = $msg->{$caller}{$key};
	}
	elsif ( defined($msg_fb->{$caller}{$key}) ) {
		$t = $msg_fb->{$caller}{$key};
		print "kh_msg: fall back: $caller, $key\n";
	} else {
		$t = 'error: '.$key;
		print "kh_msg: no msg: $caller, $key\n";
	}
	
	unless ( utf8::is_utf8($t) ){
		$t = $utf8->decode($t);
	}
	return $t;
}

sub load{
	my $lang = 'en';
	my $locale = '';
	if ( $::config_obj->msg_lang_set ){
		$lang = $::config_obj->msg_lang;
	} else {
		if ($::config_obj->os eq 'win32'){
			use Encode::Locale;
			$locale = $Encode::Locale::ENCODING_LOCALE;
			$lang = 'jp' if $locale eq 'cp932';
		} else {
			$locale = $ENV{LANG};
			#$locale = $ENV{LANG_BAK}
			#	if $^O eq 'darwin'
			#	&& $::config_obj->all_in_one_pack
			#;
			$lang = 'jp' if $locale =~ /ja_JP\./;
		}
		$::config_obj->msg_lang($lang);
		print "Locale: $locale\n";
	}

	my $file =
		$::config_obj->cwd
		.$utf8->encode( '/config/' )
		.$utf8->encode( 'msg.' )
		.$utf8->encode( $::config_obj->msg_lang )
	;
	if (-e $file){
		$msg = LoadFile($file) or die;
	}

	unless ($::config_obj->msg_lang eq 'en'){
		my $file_fb =
			$::config_obj->cwd
			.$utf8->encode('/config/')
			.$utf8->encode('msg.')
			.$utf8->encode('en')
		;
		$msg_fb = LoadFile($file_fb) or die;
		
		if ($debug){
			# 足りないメッセージや重複をチェック
			my %chk = ();
			foreach my $i (keys %{$msg_fb}){
				++$chk{$i};
				unless ($chk{$i} == 1){
					print "Duplicated msg in ".$::config_obj->msg_lang.".msg: $i\n";
				}
				unless ( length( $msg->{$i} ) ){
					print "Missing from ".$::config_obj->msg_lang.".msg: $i\n";
				}
			}
			%chk = ();
			foreach my $i (keys %{$msg}){
				++$chk{$i};
				unless ($chk{$i} == 1){
					print "Duplicated msg in jp.msg: $i\n";
				}
				unless ( length( $msg_fb->{$i} ) ){
					print "Missing from jp.msg: $i\n";
				}
			}
		}
	}

}


1;