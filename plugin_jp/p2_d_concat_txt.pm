package p2_d_concat_txt;
use strict;
use utf8;

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		name     => 'テキストファイルの結合',
		menu_cnf => 0,
		menu_grp => 'データ準備',
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	gui_window::concat_txt->open; # GUIを起動
}

#-------------------------------#
#   GUI操作のためのルーチン群   #

package gui_window::concat_txt;
use base qw(gui_window);
use strict;
use Tk;

# Windowの作成
sub _new{
	my $self = shift;
	my $mw = $self->{win_obj};

	$mw->title(
		'テキストファイルの結合'
	);

	$mw->Label(
		-text => '指定されたフォルダ内のテキストファイル（*.txt）をすべて結合します',
	)->pack(-anchor => 'w');

	my $fra_lab = $mw->LabFrame(
		-label       => 'Options',
		-labelside   => 'acrosstop',
		-borderwidth => 2
	)->pack(
		-expand => 'yes',
		-fill   => 'both'
	);

	# フォルダ用フレーム
	my $fra1 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra1->Label(
		-text => 'フォルダ：',
	)->pack(
		-side => 'left',
	);

	$self->{btn1} = $fra1->Button(
		-text => '参照',
		-font => 'TKFN',
		-borderwidth => 1,
		-command => sub{ $mw->after
			(10,
				sub { $self->_get_folder; }
			);
		}
	)->pack(-padx => '2',-side => 'left');

	$self->{entry_folder} = $fra1->Entry()->pack(
		-side   => 'left',
		-fill   => 'x',
		-expand => 'x',
	);

	$self->{entry_folder}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry_folder},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	# 見出しレベル選択用フレーム
	my $fra2 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra2->Label(
		-text => 'ファイル名の見出しレベル：',
	)->pack(
		-side => 'left',
	);

	$self->{tani_obj} = gui_widget::optmenu->open(
		parent  => $fra2,
		pack    => {-side => 'left'},
		options =>
			[
				['H1', 'h1'],
				['H2', 'h2'],
				['H3', 'h3'],
				['H4', 'h4'],
				['H5', 'h5'],
			],
		variable => \$self->{tani},
	);
	$self->{tani_obj}->set_value('h2');

	# 文字コード選択用フレーム
	my $fra3 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra3->Label(
		-text => '文字コード：',
	)->pack(
		-side => 'left',
	);
	
	$self->{icode_obj} = gui_widget::optmenu->open(
		parent  => $fra3,
		pack    => {-side => 'left'},
		options =>
			[
				['日本語（自動）',      'jp_auto' ],
				['日本語（EUC）',       'eucjp'   ],
				['日本語（Shift JIS）', 'cp932'   ],
				['Unicode（UTF-8）',    'utf8'    ],
				['Latin1',              'latin1'  ],
				['自動',                'auto'    ]
			],
		variable => \$self->{icode},
	);
	$self->{icode_obj}->set_value('jp_auto');
	
	
	# チェックボックス
	$self->{if_conv} = 1;
	$self->{check2} = $fra_lab->Checkbutton(
		-variable => \$self->{if_conv},
		-text     => 'データ内の半角山カッコ「<>」をスペースに変換する',
		-font     => "TKFN",
	)->pack(-anchor => 'w');

	# ボタン類の配置
	$mw->Button(
		-text    => 'キャンセル',
		-font    => "TKFN",
		-width   => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(
		-side => 'right',
		-padx => 2
	);
	$mw->Button(
		-text    => 'OK',
		-width   => 8,
		-font    => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_exec;});}
	)->pack(
		-side => 'right'
	);

	return $self;
}

sub _get_folder{
	my $self = shift;

	# UTF8フラグはついているけど、中身はCP932というヘンなものが帰ってくるので、
	# 修正しておく（UTF8フラグを落としておく）
	my $path = $self->{win_obj}->chooseDirectory;
	use Encode;
	$path = Encode::decode($::config_obj->os_code, "$path");
	$path = Encode::encode($::config_obj->os_code, $path);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$path = $::config_obj->os_path($path);
		$self->{entry_folder}->delete('0','end');
		$self->{entry_folder}->insert(0,$self->gui_jchar($path));
	}
	
	return $self;
}

sub _exec{
	my $self = shift;
	
	# フォルダのチェック
	my $path = $self->gui_jg_filename_win98( $self->{entry_folder}->get() );
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);
	unless (-d $path){
		gui_errormsg->open(
			type => 'msg',
			msg  => 'フォルダ指定が不正です',
		);
		return 0;
	}

	# 保存先の参照
	my @types = (
		[ "text file",[qw/.txt/] ],
		["All files",'*']
	);
	my $save = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt('名前を付けて結合ファイルを保存')
	);
	unless ($save){
		return 0;
	}
	$save = gui_window->gui_jg_filename_win98($save);
	$save = gui_window->gui_jg($save);
	$save = $::config_obj->os_path($save);


	# 処理の実行
	my @files = ();
	open my $fh, '>:encoding(utf8)', $save or
		gui_errormsg->open(
			type    => 'file',
			thefile => $save,
		);

	my $read_each = sub {
		# ファイル名関係
		return if(-d $File::Find::name);
		return unless $_ =~ /.+\.txt$/;
		
		my $f = $File::Find::name;
		#print "$f, ";

		my $f_o = substr($f, length($path) + 1, length($f) - length($path));
		$f_o = $::config_obj->uni_path( $f_o );
		$f_o =~ s/\\/\//g;

		print $fh "<$self->{tani}>file:$f_o</$self->{tani}>\n";
		push @files, "file:$f_o";

		# 文字コード
		my $icode = $self->{icode};
		if ($icode eq 'jp_auto') {
			$icode = kh_jchar->check_code2($f);
		}
		elsif ($icode eq 'auto'){
			$icode = kh_jchar->check_code_all($f);
		}
		
		# 読み込み
		open (TEMP, "<:encoding($icode)", $f) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $f,
			);
		while ( <TEMP> ){
			if ($self->{if_conv}){
				$_ =~ tr/<>/  /;
			}
			print $fh $_;
		}
		close (TEMP);
		print $fh "\n";
	};

	use File::Find;
	find($read_each, $path);
	close($fh);
	$fh = undef;
	#if ($::config_obj->os eq 'win32'){
	#	kh_jchar->to_sjis($save);
	#}

	# ファイル名の格納
	my $names = substr( $save,0, rindex($save,'.txt') );
	$names .= '_names.txt';
	open my $fhn, '>:encoding(utf8)', $names or
		gui_errormsg->open(
			type    => 'file',
			thefile => $names,
		);
	foreach my $i (@files){
		print $fhn "$i\n";
	}
	close ($fhn);

	$self->close;
}

sub win_name{
	return 'w_concat_txt';
}

1;