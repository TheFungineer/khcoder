use utf8;

package kh_sysconfig;
use strict;

use kh_sysconfig::win32;
use kh_sysconfig::linux;

use Encode;
use Encode::Locale;
my $locale_fs = 1;
eval {
	Encode::encode('locale_fs', 'test');
};
if ( $@ ){
	warn $@;
	$locale_fs = 0;
}

sub readin{
	my $class = shift;
	$class .= '::'.&os;
	my $self;
	$self->{ini_file} = shift;
	$self->{cwd} = shift;
	bless $self, $class;

	# cwdのチェック
	if ( $] > 5.008 ) {
		if ( utf8::is_utf8($self->{cwd}) ){
			warn "Error: Unexpected UTF8 Flag!";
		}
	}
	#print "kh_sysconfig: $self->{cwd}\n";

	# 設定ファイルが揃っているか確認
	if (
		   ! -e "$self->{ini_file}"
		|| ! -e "./config/hinshi_chasen"
		|| ! -e "./config/hinshi_mecab"
		|| ! -e "./config/hinshi_mecab_k"
		|| ! -e "./config/hinshi_stemming"
		|| ! -e "./config/hinshi_stanford_cn"
		|| ! -e "./config/hinshi_stanford_en"
		|| ! -e "./config/hinshi_stanford_de"
		|| ! -e "./config/hinshi_freeling_ca"
		|| ! -e "./config/hinshi_freeling_de"
		|| ! -e "./config/hinshi_freeling_en"
		|| ! -e "./config/hinshi_freeling_fr"
		|| ! -e "./config/hinshi_freeling_it"
		|| ! -e "./config/hinshi_freeling_pt"
		|| ! -e "./config/hinshi_freeling_ru"
		|| ! -e "./config/hinshi_freeling_es"
		|| ! -e "./config/hinshi_freeling_sl"
	){
		# 揃っていない場合は設定を初期化
		$self->reset_parm;
	}

	# iniファイル
	#print "kh_sysconfig: $self->{ini_file}\n";
	open (CINI, '<:encoding(utf8)', "$self->{ini_file}") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$self->{ini_file}"
		);
	while (<CINI>){
		chomp;
		my @temp = split /\t/, $_;
		$self->{$temp[0]} = $temp[1];
	}
	close (CINI);

	# その他
	$self->{history_file} = $self->{cwd}.'/config/projects';
	$self->{history_trush_file} = $self->{cwd}.'/config/projects_trush';

	$self = $self->_readin;

	return $self;
}

#------------------#
#   設定の初期化   #

sub reset_parm{
		my $self = shift;
		print "Resetting parameters...\n";
		mkdir 'config' unless -d 'config';
		
		# 設定ファイルの準備
		unless (-e $self->{ini_file}){
			open (CON,">$self->{ini_file}") or 
				gui_errormsg->open(
					type    => 'file',
					thefile => "m: $self->{ini_file}"
				);
			close (CON);
		}
		
		# 品詞定義ファイルの作成準備
		use DBI;
		use DBD::CSV;
		my $dbh = DBI->connect("dbi:CSV:", undef, undef, {
			f_dir      => "./config",
			f_encoding => "UTF8",
			csv_eol    => "\n",
		}) or die;
		my @table = (
				"'7', '地名', '名詞-固有名詞-地域', ''",
				"'6', '人名', '名詞-固有名詞-人名', ''",
				"'5','組織名','名詞-固有名詞-組織', ''",
				"'4','固有名詞','名詞-固有名詞', ''",
				"'2','サ変名詞','名詞-サ変接続', ''",
				"'3','形容動詞','名詞-形容動詞語幹', ''",
				"'8','ナイ形容','名詞-ナイ形容詞語幹', ''",
				"'16','名詞B','名詞-一般','ひらがな'",
				#"'16','名詞B','名詞-副詞可能','ひらがな'",
				"'20','名詞C','名詞-一般','一文字'",
				#"'20','名詞C','名詞-副詞可能','一文字'",
				"'21','否定助動詞','助動詞','否定'",
				"'1','名詞','名詞-一般', ''",
				"'9','副詞可能','名詞-副詞可能', ''",
				"'10','未知語','未知語', ''",
				"'12','感動詞','感動詞', ''",
				"'12','感動詞','フィラー', ''",
				"'99999','HTMLタグ','タグ', 'HTML'",
				"'11','タグ','タグ', ''",
				"'17','動詞B','動詞-自立','ひらがな'",
				"'13','動詞','動詞-自立', ''",
				"'22','形容詞（非自立）','形容詞-非自立', ''",
				"'18','形容詞B','形容詞','ひらがな'",
				"'14','形容詞','形容詞', ''",
				"'19','副詞B','副詞','ひらがな'",
				"'15','副詞','副詞', ''"
		);
		
		# 茶筌用
		unless (-e "./config/hinshi_chasen"){
			$dbh->do(
				"CREATE TABLE hinshi_chasen (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_chasen
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			}
		}

		# MeCab用
		unless (-e "./config/hinshi_mecab"){
			$dbh->do(
				"CREATE TABLE hinshi_mecab (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_mecab
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			}
		}

		# Stemming用
		unless (-e "./config/hinshi_stemming"){
			$dbh->do(
				"CREATE TABLE hinshi_stemming (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'ALL', 'ALL', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_stemming
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}

		# Stanford POS Tagger用（英語）
		unless (-e "./config/hinshi_stanford_en"){
			$dbh->do(
				"CREATE TABLE hinshi_stanford_en (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"2, 'ProperNoun', 'NNP', ''",
				"1, 'Noun',  'NN', ''",
				"3, 'Foreign',  'FW', ''",
				"20, 'PRP',  'PRP', ''",
				"25, 'Adj',  'JJ', ''",
				"30, 'Adv',  'RB', ''",
				"35, 'Verb',  'VB', ''",
				"40, 'W',  'W', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_stanford_en
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}

		# Stanford POS Tagger用（ドイツ語）
		unless (-e "./config/hinshi_stanford_de"){
			$dbh->do(
				"CREATE TABLE hinshi_stanford_de (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'ADJA', 'ADJA', ''",
				"2, 'ADJD', 'ADJD', ''",
				"3, 'ADV', 'ADV', ''",
				"4, 'APPR', 'APPR', ''",
				"5, 'APPRART', 'APPRART', ''",
				"6, 'APPO', 'APPO', ''",
				"7, 'APZR', 'APZR', ''",
				"8, 'ART', 'ART', ''",
				"9, 'CARD', 'CARD', ''",
				"10, 'FM', 'FM', ''",
				"11, 'ITJ', 'ITJ', ''",
				"12, 'KOUI', 'KOUI', ''",
				"13, 'KOUS', 'KOUS', ''",
				"14, 'KON', 'KON', ''",
				"15, 'KOKOM', 'KOKOM', ''",
				"16, 'NN', 'NN', ''",
				"17, 'NE', 'NE', ''",
				"18, 'PDS', 'PDS', ''",
				"19, 'PDAT', 'PDAT', ''",
				"20, 'PIS', 'PIS', ''",
				"21, 'PIAT', 'PIAT', ''",
				"22, 'PIDAT', 'PIDAT', ''",
				"23, 'PPER', 'PPER', ''",
				"24, 'PPOSS', 'PPOSS', ''",
				"25, 'PPOSAT', 'PPOSAT', ''",
				"26, 'PRELS', 'PRELS', ''",
				"27, 'PRELAT', 'PRELAT', ''",
				"28, 'PRF', 'PRF', ''",
				"29, 'PWS', 'PWS', ''",
				"30, 'PWAT', 'PWAT', ''",
				"31, 'PWAV', 'PWAV', ''",
				"32, 'PAV', 'PAV', ''",
				"33, 'PTKZU', 'PTKZU', ''",
				"34, 'PTKNEG', 'PTKNEG', ''",
				"35, 'PTKVZ', 'PTKVZ', ''",
				"36, 'PTKANT', 'PTKANT', ''",
				"37, 'PTKA', 'PTKA', ''",
				"38, 'TRUNC', 'TRUNC', ''",
				"39, 'VVFIN', 'VVFIN', ''",
				"40, 'VVIMP', 'VVIMP', ''",
				"41, 'VVINF', 'VVINF', ''",
				"42, 'VVIZU', 'VVIZU', ''",
				"43, 'VVPP', 'VVPP', ''",
				"44, 'VAFIN', 'VAFIN', ''",
				"45, 'VAIMP', 'VAIMP', ''",
				"46, 'VAINF', 'VAINF', ''",
				"47, 'VAPP', 'VAPP', ''",
				"48, 'VMFIN', 'VMFIN', ''",
				"49, 'VMINF', 'VMINF', ''",
				"50, 'VMPP', 'VMPP', ''",
				"51, 'XY', 'XY', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_stanford_de
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}

		# Stanford POS Tagger用（中国語）
		unless (-e "./config/hinshi_stanford_cn"){
			$dbh->do(
				"CREATE TABLE hinshi_stanford_cn (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"2, 'ProperNoun', 'NR', ''",
				"1, 'Noun',  'NN', ''",#
				"3, 'Foreign',  'FW', ''",
				"25, 'Adj',  'VA', ''",
				"26, 'JJ',  'JJ', ''",
				"30, 'Adv',  'AD', ''",
				"35, 'Verb',  'VV', ''",
				"40, 'W',  'W', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_stanford_cn
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}

		# MeCab & Handic用（朝鮮語）
		unless (-e "./config/hinshi_mecab_k"){
			$dbh->do(
				"CREATE TABLE hinshi_mecab_k (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"2, 'ProperNoun', 'Noun-固有名詞', ''",
				"1, 'Noun',  'Noun-普通', ''",#
				"25, 'Adj',  'Adjective-自立', ''",
				"30, 'Adv',  'Adverb-一般', ''",
				"35, 'Verb',  'Verb-自立', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_mecab_k
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}

		# for FreeLing (English)
		unless (-e "./config/hinshi_freeling_en"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_en (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				#"2, 'ProperNoun', 'NP', ''",
				#"2, 'ProperNoun', 'NNP', ''",
				"1, 'Noun',  'N', ''",
				"3, 'Foreign',  'FW', ''",
				"20, 'PRP',  'PRP', ''",
				"25, 'Adj',  'JJ', ''",
				"30, 'Adv',  'RB', ''",
				"35, 'Verb',  'VB', ''",
				"40, 'W',  'W', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_en
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}
		
		# for FreeLing (French)
		unless (-e "./config/hinshi_freeling_fr"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_fr (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'AQ', 'AQ', ''",
				"2, 'AO', 'AO', ''",
				"3, 'AP', 'AP', ''",
				"4, 'R', 'R', ''",
				"5, 'N', 'N', ''",
				"6, 'V', 'V', ''",
				"7, 'I', 'I', ''",
				"81, 'AJ', 'AJ', ''",
				"82, 'AV', 'AV', ''",
				"83, 'U', 'U', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
				#"1, 'ALL', '*', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_fr
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}
		
		# for FreeLing (Spanish)
		unless (-e "./config/hinshi_freeling_es"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_es (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'AQ', 'AQ', ''",
				"2, 'AO', 'AO', ''",
				"3, 'AP', 'AP', ''",
				"4, 'R', 'R', ''",
				"5, 'N', 'N', ''",
				"6, 'V', 'V', ''",
				"7, 'I', 'I', ''",
				"81, 'AJ', 'AJ', ''",
				"82, 'AV', 'AV', ''",
				"83, 'U', 'U', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
				#"1, 'ALL', '*', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_es
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}
		
		# for FreeLing (Catalan)
		unless (-e "./config/hinshi_freeling_ca"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_ca (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'AQ', 'AQ', ''",
				"2, 'AO', 'AO', ''",
				"3, 'AP', 'AP', ''",
				"4, 'R', 'R', ''",
				"5, 'N', 'N', ''",
				"6, 'V', 'V', ''",
				"7, 'I', 'I', ''",
				"81, 'AJ', 'AJ', ''",
				"82, 'AV', 'AV', ''",
				"83, 'U', 'U', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
				#"1, 'ALL', '*', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_ca
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}
		
		# for FreeLing (Italian)
		unless (-e "./config/hinshi_freeling_it"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_it (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'AQ', 'AQ', ''",
				"2, 'AO', 'AO', ''",
				"3, 'AP', 'AP', ''",
				"4, 'R', 'R', ''",
				"5, 'N', 'N', ''",
				"6, 'V', 'V', ''",
				"7, 'I', 'I', ''",
				"81, 'AJ', 'AJ', ''",
				"82, 'AV', 'AV', ''",
				"83, 'U', 'U', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
				#"1, 'ALL', '*', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_it
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}
		
		# for FreeLing (Portuguese)
		unless (-e "./config/hinshi_freeling_pt"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_pt (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'AQ', 'AQ', ''",
				"2, 'AO', 'AO', ''",
				"3, 'AP', 'AP', ''",
				"4, 'R', 'R', ''",
				"5, 'N', 'N', ''",
				"6, 'V', 'V', ''",
				"7, 'I', 'I', ''",
				"81, 'AJ', 'AJ', ''",
				"82, 'AV', 'AV', ''",
				"83, 'U', 'U', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
				#"1, 'ALL', '*', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_pt
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}
		
		# for FreeLing (Russian)
		unless (-e "./config/hinshi_freeling_ru"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_ru (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'A', 'A', ''",
				"2, 'D', 'D', ''",
				"4, 'N', 'N', ''",
				"5, 'V', 'V', ''",
				"6, 'I', 'I', ''",
				"83, 'U', 'U', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
				#"1, 'ALL', '*', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_ru
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}

		# for FreeLing (German)
		unless (-e "./config/hinshi_freeling_de"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_de (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'A', 'A', ''",
				"3, 'R', 'R', ''",
				"4, 'N', 'N', ''",
				"5, 'V', 'V', ''",
				"6, 'I', 'I', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
				#"1, 'ALL', '*', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_de
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}

		# for FreeLing (Slovene)
		unless (-e "./config/hinshi_freeling_sl"){
			$dbh->do(
				"CREATE TABLE hinshi_freeling_sl (
					hinshi_id INTEGER,
					kh_hinshi CHAR(225),
					condition1 CHAR(225),
					condition2 CHAR(225)
				)"
			) or die;
			my @table = (
				"1, 'A', 'A', ''",
				"3, 'R', 'R', ''",
				"4, 'N', 'N', ''",
				"5, 'V', 'V', ''",
				"6, 'I', 'I', ''",
				"99999,'HTML_TAG','TAG','HTML'",
				"11,'TAG','TAG',''",
				#"1, 'ALL', '*', ''",
			);
			foreach my $i (@table){
				$dbh->do("
					INSERT INTO hinshi_freeling_sl
						(hinshi_id, kh_hinshi, condition1, condition2 )
					VALUES
						( $i )
				") or die($i);
			} # DBD::CSV関連が古いと、1文で複数行INSERTすることができない...
		}
		
		$dbh->disconnect;
}

#----------------------#
#   パスの文字コード   #

sub os_path{
	my $self  = shift;
	my $c     = shift;
	
	if ( utf8::is_utf8($c) ){
		$c = Encode::encode("locale_fs", $c) if $locale_fs;
		return $c;
	} else {
		#print "kh_sysconfig::os_path: returning $c\n";
		return $c;
	}
}

sub uni_path{
	my $self  = shift;
	my $c     = shift;
	
	unless ( utf8::is_utf8($c) ){
		$c = Encode::decode("locale_fs", $c) if $locale_fs;
	}
	$c =~ tr/\\/\//;
	
	return $c; 
}

sub os_code{
	print "kh_sysconfig::os_code: $Encode::Locale::ENCODING_LOCALE\n";
	return $Encode::Locale::ENCODING_LOCALE;
}

sub ini_backup{
	my $self = shift;
	
	my $file_ini = $self->cwd.'/config/coder.ini';
	my $file_bak = $file_ini.'.bak';
	
	unlink($file_bak) if -e $file_bak;
	
	use File::Copy;
	copy($file_ini, $file_bak);
	
	return $self;
}

#--------------------#
#   形態素解析関係   #

sub refine_cj{
	my $self = shift;
	bless $self, 'kh_sysconfig::'.$self->os.'::'.$self->c_or_j;
	return $self;
}

sub use_hukugo{
	my $self = shift;
	my $new = shift;
	if (length($new) > 0){
		$self->{use_hukugo} = $new;
	}
	return $self->{use_hukugo};
}

sub mecab_unicode{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{mecab_unicode} = $new;
	}
	return $self->{mecab_unicode};
}

sub mecabrc_path{
	my $self = shift;
	my $new  = shift;
	$self->{mecabrc_path} = $new if defined($new);
	return $self->{mecabrc_path};
}

sub freeling_dir{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{freeling_dir} = $new;
	}
	return $self->{freeling_dir};
}

sub c_or_j{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{c_or_j} = $new;
	}

	if (length($self->{c_or_j}) > 0) {
		return $self->{c_or_j};
	} else {
		return 'chasen';
	}
}

sub last_lang{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{last_lang} = $new;
	}

	if (length($self->{last_lang}) > 0) {
		return $self->{last_lang};
	} else {
		return $self->msg_lang;
	}
}

sub last_method{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{last_method} = $new;
	}

	if (length($self->{last_method}) > 0) {
		return $self->{last_method};
	} else {
		return 'chasen';
	}
}

sub stemming_lang{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{stemming_lang} = $new;
	}

	if (length($self->{stemming_lang}) > 0) {
		return $self->{stemming_lang};
	} else {
		return 'en';
	}
}

sub stanford_lang{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{stanford_lang} = $new;
	}

	if (length($self->{stanford_lang}) > 0) {
		return $self->{stanford_lang};
	} else {
		return 'en';
	}
}

sub freeling_lang{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{freeling_lang} = $new;
	}
	unless (defined($self->{freeling_lang})){
		$self->{freeling_lang} = 'en';
	}
	return $self->{freeling_lang};
}

sub stanf_tagger_path{
	my $self = shift;
	
	if ($::project_obj) {
		my $lang = $::project_obj->morpho_analyzer_lang;
		if ($lang eq 'en' || $lang eq 'cn') {
			my $call = 'stanf_tagger_path_'.$::project_obj->morpho_analyzer_lang;
			return $self->$call;
		}
	}
	return undef;
}

sub stanf_tagger_path_en{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{stanf_tagger_path_en} = $new;
	}
	return $self->{stanf_tagger_path_en};
}

sub stanf_tagger_path_cn{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{stanf_tagger_path_cn} = $new;
	}
	return $self->{stanf_tagger_path_cn};
}

sub stanf_jar_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{stanf_jar_path} = $new;
	}
	return $self->{stanf_jar_path};
}

sub stanf_seg_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{stanf_seg_path} = $new;
	}
	return $self->{stanf_seg_path};
}

sub han_dic_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{han_dic_path} = $new;
	}
	return $self->{han_dic_path};
}

sub msg_lang{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{msg_lang} = $new;
	}

	if (length($self->{msg_lang}) > 0) {
		return $self->{msg_lang};
	} else {
		return 'jp';
	}
}

sub msg_lang_set{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{msg_lang_set} = $new;
	}

	if (length($self->{msg_lang_set}) > 0) {
		return $self->{msg_lang_set};
	} else {
		return 0;
	}
}

sub stopwords{
	my $self = shift;
	my %args = @_;

	unless ( length($args{locale}) ){
		$args{locale} = 'd';
	}

	my $type = $args{method}.'_'.$args{locale};

	if ( defined( $args{stopwords} ) ){
		# データ保存
		my $dbh = DBI->connect("dbi:CSV:", undef, undef, {
			f_dir      => "./config",
			f_encoding => "UTF8",
			csv_eol    => "\n",
		}) or die;
		
		if (-e "./config/stopwords_$type"){
			$dbh->do("
				DROP TABLE stopwords_$type
			") or die;
		}
		
		$dbh->do("
			CREATE TABLE stopwords_$type (name CHAR(225))
		") or die;
		
		my $sth = $dbh->prepare(
			"INSERT INTO stopwords_$type (name) VALUES (?)"
		) or die;
		
		foreach my $i (@{$args{stopwords}}){
			$sth->execute($i);
		}
		
		$dbh->disconnect;
		return $args{stopwords};
	} else {
		# データ読み出し
		my @words = ();
		my $dbh = DBI->connect("dbi:CSV:", undef, undef, {
			f_dir      => "./config",
			f_encoding => "UTF8",
			csv_eol    => "\n",
		}) or die;
		if (-e "./config/stopwords_$type"){
			my $sth = $dbh->prepare("
				SELECT name FROM stopwords_$type
			") or die;
			$sth->execute;
			while (my $i = $sth->fetch){
				push @words, $i->[0];
			}
		}
		$dbh->disconnect;
		return \@words;
	}
}

sub stopwords_current{
	my $self = shift;

	my $type = $self->c_or_j;
	
	if ($self->c_or_j eq 'stemming'){
		$type .= '_'.$::project_obj->morpho_analyzer_lang;
	}
	elsif ($self->c_or_j eq 'stanford'){
		$type .= '_'.$::project_obj->morpho_analyzer_lang;
	}
	elsif ($self->c_or_j eq 'freeling'){
		$type .= '_'.$::project_obj->morpho_analyzer_lang;
	} else {
		$type .= '_d';
	}
	#print "type: $type\n";
	
	my @words = ();
	my $cwd = $self->cwd;
	my $dbh = DBI->connect("dbi:CSV:", undef, undef, {
		f_dir      => "$cwd/config",
		f_encoding => "UTF8",
		csv_eol    => "\n",
	}) or die;
	if (-e "$cwd/config/stopwords_$type"){
		my $sth = $dbh->prepare("
			SELECT name FROM stopwords_$type
		") or die;
		$sth->execute;
		while (my $i = $sth->fetch){
			push @words, $i->[0];
		}
	}
	$dbh->disconnect;
	return \@words;
}

#sub use_sonota{
#	my $self = shift;
#	my $new = shift;
#	if ( length($new) > 0 ){
#		$self->{use_sonota} = $new;
#	}
#
#	if ( $self->{use_sonota} ){
#		return $self->{use_sonota};
#	} else {
#		return 0;
#	}
#}

sub hukugo_chasenrc{
	my $self = shift;
	my $new = shift;
	
	if ( defined($new) ){
		$self->{hukugo_chasenrc} = $new;
	}
	
	if ( length($self->{hukugo_chasenrc}) ){
		return $self->{hukugo_chasenrc};
	} else {
		my $t = '';
		$t .= '(連結品詞'."\n";
		$t .= "\t".'((複合名詞)'."\n";
		$t .= "\t\t".'(名詞)'."\n";
		$t .= "\t\t".'(接頭詞 名詞接続)'."\n";
		$t .= "\t\t".'(接頭詞 数接続)'."\n";
		$t .= "\t\t".'(記号 一般)'."\n";
		$t .= "\t".')'."\n";
		$t .= ')'."\n";
		return $t;
	}
}


#-------------#
#   GUI関係   #

# Window位置とサイズのリセット
sub ClearGeometries{
	my $self = shift;
	foreach my $i (keys %{$self}){
		undef $self->{$i} if $i =~ /^w_/;
	}
	return $self;
}

sub DocSrch_CutLength{
	my $self = shift;
	if (defined($self->{DocSrch_CutLength})){
		return $self->{DocSrch_CutLength};
	} else {
		return '85';
	}
}

sub DocView_WrapLength_on_Win9x{
	my $self = shift;
	if (defined($self->{DocView_WrapLength_on_Win9x})){
		return $self->{DocView_WrapLength_on_Win9x};
	} else {
		return '80';
	}
}

sub color_DocView_info{
	my $self = shift;
	my $i    = $self->{color_DocView_info};
	unless ( defined($i) ){
		$i = "#008000,white,0";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless defined($h[2]) && length($h[2]);
		return @h;
	}
}

sub color_ListHL_fore{
	my $self = shift;
	
	
	if( defined( $self->{color_ListHL_fore} ) ){
		return $self->{color_ListHL_fore};
	} else {
		return 'black';
	}
}

sub color_ListHL_back{
	my $self = shift;
	
	
	if( defined( $self->{color_ListHL_back} ) ){
		return $self->{color_ListHL_back};
	} else {
		return '#AFEEEE';
	}
}


sub color_DocView_search{
	my $self = shift;
	my $i    = $self->{color_DocView_search};
	unless ( defined($i) ){
		$i = "black,yellow,0";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless defined($h[2]) && length($h[2]);
		return @h;
	}
}

sub color_DocView_force{
	my $self = shift;
	my $i    = $self->{color_DocView_force};
	unless ( defined($i) ){
		$i = "black,cyan,0";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless defined($h[2]) && length($h[2]);
		return @h;
	}
}

sub color_DocView_html{
	my $self = shift;
	my $i    = $self->{color_DocView_html};
	unless ( defined($i) ){
		$i = "red,white,0";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless defined($h[2]) && length($h[2]);
		return @h;
	}
}

sub color_DocView_CodeW{
	my $self = shift;
	my $i    = $self->{color_DocView_CodeW};
	unless ( defined($i) ){
		$i = "blue,white,1";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless length($h[2]);
		return @h;
	}
}

sub plot_size_words{
	my $self = shift;
	my $new  = shift;

	# the default value
	unless ( $self->{plot_size_words} ){
		$self->{plot_size_words} = 640;
	}
	
	# set a new value
	if ( defined($new) ){
		$self->{plot_size_words} = $new;
	}
	
	return $self->{plot_size_words};
}

sub plot_size_codes{
	my $self = shift;
	my $new  = shift;

	# the default value
	unless ( $self->{plot_size_codes} ){
		$self->{plot_size_codes} = 480;
	}
	
	# set a new value
	if ( defined($new) ){
		$self->{plot_size_codes} = $new;
	}
	
	return $self->{plot_size_codes};
}

sub plot_font_size{
	my $self = shift;
	my $new  = shift;

	# the default value
	unless ( $self->{plot_font_size} ){
		$self->{plot_font_size} = 100;
	}
	
	# set a new value
	if ( defined($new) ){
		$self->{plot_font_size} = $new;
	}
	
	return $self->{plot_font_size};
}

sub win_gmtry{
	my $self = shift;
	my $win_name = shift;
	my $geometry = shift;
	if (defined($geometry)){
		$self->{$win_name} = $geometry;
	} else {
		return $self->{$win_name};
	}
}

sub win32_monitor_chk{
	my $self = shift;
	my $new = shift;
	
	if ( defined($new) ){
		$self->{win32_monitor_chk} = $new;
	}
	
	return $self->{win32_monitor_chk};
}

#---------------#
#   MySQL関連   #
#---------------#

sub sql_username{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{sql_username} = $new;
	}
	return $self->{sql_username};
}

sub sql_password{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{sql_password} = $new;
	}
	return $self->{sql_password};
}

sub sql_port{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{sql_port} = $new;
	}
	return $self->{sql_port};
}

sub sql_host{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{sql_host} = $new;
	}
	if ( defined($self->{sql_host}) ){
		return $self->{sql_host};
	} else {
		return 'localhost';
	}
}

sub sqllog{
	my $self = shift;
	my $new = shift;
	
	if ( defined($new) && length($new) ){
		$self->{sqllog} = $new;
	}

	return $self->{sqllog};
}

sub sqllog_file{
	my $self = shift;
	return "./config/sql.log";
}

#------------#
#   その他   #

sub all_in_one_pack{
	my $self = shift;
	return $self->{all_in_one_pack};
}

sub kaigyo_kigou{
	my $self = shift;
	my $new  = shift;
	
	# 新しい値を指定された場合
	if (defined($new)){
		$self->{kaigyo_kigou} = $new;
	}
	
	# デフォルト値
	unless ($self->{kaigyo_kigou}){
		return '（↓）';
	}
	
	return $self->{kaigyo_kigou};
}

sub R{
	my $self = shift;
	return $self->{R};
}

sub R_version{
	my $self = shift;
	
	if ( $self->{R} ){
		if ( $self->{R_version} ){
			return $self->{R_version};
		} else {
			$::config_obj->R->send(
				'print( paste("khcoder", R.Version()$major, R.Version()$minor , sep="") )'
			);
			my $v1 = $::config_obj->R->read;
			if ($v1 =~ /"khcoder(.+)"/){
				$v1 = $1;
			} else {
				warn "could not get Version Number of R...\n";
				return 0;
			}
			
			if ($v1 =~ /([0-9])([0-9]+)\./){
				print "R Version: $1.$2, ";
				$self->{R_version} = $1 * 100 + $2;
				
				$::config_obj->R->send(
					'print( paste("khcoder",R.Version()$arch,sep="") )'
				);
				my $arch = $::config_obj->R->read;
				if ($arch =~ /"khcoder(.+)"/){
					$arch = $1
				}
				print "$arch\n";
				
				return $self->{R_version};
			} else {
				warn "could not get Version Number of R...\n";
				return 0;
			}
		}
	} else {
		return 0;
	}
}

sub multi_threads{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{multi_threads} = $new;
	}
	
	if ( length($self->{multi_threads}) ){
		return $self->{multi_threads};
	} else {
		return 0;
	}
}

sub font_pdf{
	my $self = shift;
	my $new  = shift;
	$self->{font_pdf} = $new if defined($new) && length($new);
	$self->{font_pdf} = 'Japan1GothicBBB' unless length($self->{font_pdf});
	return $self->{font_pdf};
}

sub font_pdf_cn{
	my $self = shift;
	my $new  = shift;
	$self->{font_pdf_cn} = $new if defined($new) && length($new);
	$self->{font_pdf_cn} = 'GB1' unless length($self->{font_pdf_cn});
	return $self->{font_pdf_cn};
}

sub font_pdf_kr{
	my $self = shift;
	my $new  = shift;
	$self->{font_pdf_kr} = $new if defined($new) && length($new);
	$self->{font_pdf_kr} = 'Korea1deb' unless length($self->{font_pdf_kr});
	return $self->{font_pdf_kr};
}

sub font_pdf_current{
	my $self = shift;

	# プロジェクトの言語にあわせてフォントを返す
	if ($::project_obj) {
		my $lang = $::project_obj->morpho_analyzer_lang;
		if ($lang eq 'cn') {                         # Chinese
			return $self->font_pdf_cn;
		}
		elsif ($lang eq 'kr'){                       # Korean
			return $self->font_pdf_kr;
		}
		elsif ($lang eq 'jp'){                       # Japanese
			return $self->font_pdf;
		}
		#elsif (                                      # Russian
		#	$lang eq 'ru'
		#	&& $^O =~ /darwin/
		#	&& $::config_obj->all_in_one_pack
		#){
		#	#return 'RU';
		#	return 'ArialMT';
		#}
		else{                                        # English & Euro
			if ($self->msg_lang eq 'jp') {
				return $self->font_pdf;
			} else {
				return 'sans';
			}
		}
	}

	return $self->font_pdf;
}

sub font_plot_current{
	my $self = shift;

	# 中国語 / 韓国語プロジェクトを開いている時だけ中 / 韓フォントを返す
	if ($::project_obj) {
		my $lang = $::project_obj->morpho_analyzer_lang;
		if ($lang eq 'cn') {
			return $self->font_plot_cn;
		}
		elsif ($lang eq 'kr'){
			return $self->font_plot_kr;
		}
		elsif ($lang eq 'ru'){
			return $self->font_plot_ru;
		}
	}
	return $self->font_plot;
}

sub r_plot_debug{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{r_plot_debug} = $new;
	}
	
	if ( length($self->{r_plot_debug}) ){
		return $self->{r_plot_debug};
	} else {
		return 0;
	}
}

sub r_path{
	my $self = shift;
	my $new = shift;
	if ( length($new) && -e $new ){
		$self->{r_path} = $new;
	}
	return $self->{r_path};
}

sub r_default_font_size{
	my $self = shift;
	
	warn("'r_default_font_size' is deprecated. Please use 'plot_font_size' instead.\n");
	
	if ($self->R_version > 210){
		return 100;
	} else {
		return 80;
	}
}

sub in_preprocessing{
	my $self = shift;
	my $new = shift;
	if ( length($new) ){
		$self->{in_preprocessing} = $new;
	}
	return $self->{in_preprocessing};
}

sub use_heap {
	my $self = shift;
	my $new = shift;
	
	if ( defined($new) && length($new) ){                     # 新しい値の指定
		$self->{use_heap} = $new;
	}
	unless (defined($self->{use_heap})){     # デフォルト値
		$self->{use_heap} = 1;
	}
	return $self->{use_heap};
}

sub mail_if{
	my $self = shift;
	my $new = shift;
	if ( defined($new) && length($new) ){
		$self->{mail_if} = $new;
	}
	return $self->{mail_if};
}

sub mail_smtp{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{mail_smtp} = $new;
	}
	return $self->{mail_smtp};
}

sub mail_from{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{mail_from} = $new;
	}
	return $self->{mail_from};
}

sub mail_to{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{mail_to} = $new;
	}
	return $self->{mail_to};
}

sub history_file{
	my $self = shift;
	return $self->{history_file};
}

sub history_trush_file{
	my $self = shift;
	return $self->{history_trush_file};
}

sub cwd{
	my $self = shift;
	my $c = $self->{cwd};
	$c = $self->os_path($c);
	return $c;
}
sub pwd{
	my $self = shift;
	return $self->{cwd};
}


sub icon_image_file{
	return Tk->findINC('ghome.gif');
}

sub logo_image_file{
	my $self = shift;
	return Tk->findINC('kh_logo.bmp');
}


sub os{
	if ($^O eq 'MSWin32') {
		return 'win32';
	} else {
		return 'linux';
	}
}

sub file_temp{
	my $n = 0;
	while (-e "temp$n.txt"){
		++$n;
	}
	open   (KH_SYSCNF_TEMP, ">temp$n.txt");
	close  (KH_SYSCNF_TEMP);
	return ("temp$n.txt");
}


1;
