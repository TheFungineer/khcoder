package gui_window::word_netgraph;
use base qw(gui_window);

use strict;
use utf8;
use Tk;

use gui_widget::tani;
use gui_widget::hinshi;
use mysql_crossout;
use kh_r_plot;

my $bench = 0;
my $debug = 0;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf_w = $win->LabFrame(
		-label => kh_msg->get('u_w'), # 集計単位と抽出語の選択
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue'
	)->pack(-fill => 'both', -expand => 1, -side => 'left');

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		tani_command => sub{
			if ($self->{var_obj}){
				$self->{var_obj}->new_tani($self->tani);
			}
			if ( $self->{net_obj}{var_obj2} ){
				$self->{net_obj}{var_obj2}->new_tani($self->tani);
			}
		},
		verb   => kh_msg->get('use'), # 利用
	);

	my $lf = $win->LabFrame(
		-label => kh_msg->get('net_opt'), # ■共起ネットワークの設定
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue'
	)->pack(-fill => 'x', -expand => 0);

	# 共起関係の種類
	$lf->Label(
		-text => kh_msg->get('e_type'), # 共起関係（edge）の種類
		-font => "TKFN",
	)->pack(-anchor => 'w');

	my $f5 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 1
	);

	$f5->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	unless ( defined( $self->{radio_type} ) ){
		$self->{radio_type} = 'words';
	}

	$f5->Radiobutton(
		-text             => kh_msg->get('w_w'), # 語 ― 語
		-font             => "TKFN",
		-variable         => \$self->{radio_type},
		-value            => 'words',
		-command          => sub{ $self->refresh(3);},
	)->pack(-anchor => 'nw', -side => 'left');

	$f5->Label(
		-text => ' ',
		-font => "TKFN",
	)->pack(-anchor => 'nw', -side => 'left');

	$f5->Radiobutton(
		-text             => kh_msg->get('w_v'), # 語 ― 外部変数・見出し
		-font             => "TKFN",
		-variable         => \$self->{radio_type},
		-value            => 'twomode',
		-command          => sub{ $self->refresh(3);},
	)->pack(-anchor => 'nw');

	my $f6 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 1
	);

	$f6->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	$self->{var_lab} = $f6->Label(
		-text => kh_msg->get('var'), # 外部変数・見出し：
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	$self->{var_obj} = gui_widget::select_a_var->open(
		parent        => $f6,
		tani          => $self->tani,
		show_headings => 1,
	);

	# 共起ネットワークのオプション
	$self->{net_obj} = gui_widget::r_net->open(
		parent  => $lf,
		command => sub{ $self->calc; },
		from    => $self,
		pack    => { -anchor   => 'w'},
	);

	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf,
		command   => sub{ $self->calc; },
		pack      => { -anchor   => 'w' },
		show_bold => 1,
	);

	$win->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'), # 実行時にこの画面を閉じない
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;},
	)->pack(-side => 'right', -pady => 2, -anchor => 'se')->focus;

	$self->refresh(3);
	return $self;
}

sub refresh{
	my $self = shift;

	my (@dis, @nor);
	if ( $self->{radio_type} eq 'words' ){
		push @dis, $self->{var_lab};
		$self->{var_obj}->disable;
	} else {
		push @nor, $self->{var_lab};
		$self->{var_obj}->enable;
	}

	foreach my $i (@nor){
		$i->configure(-state => 'normal');
	}

	foreach my $i (@dis){
		$i->configure(-state => 'disabled');
	}
	
	$self->{net_obj}->refresh;
	
	#$nor[0]->focus unless $_[0] == 3;
}

sub start_raise{
	my $self = shift;
	$self->{words_obj}->settings_load;
}

sub start{
	my $self = shift;

	# Windowを閉じる際のバインド
	$self->win_obj->bind(
		'<Control-Key-q>',
		sub{ $self->withd; }
	);
	$self->win_obj->bind(
		'<Key-Escape>',
		sub{ $self->withd; }
	);
	$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->withd; });
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_corresp->select_pos'), # '品詞が1つも選択されていません。',
		);
		return 0;
	}

	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $self->tani,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
	)->wnum;
	
	$check_num =~ s/,//g;
	#print "$check_num\n";

	if ($check_num < 5){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_mds->select_3words'), # '少なくとも5つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	if ($check_num > 300){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					kh_msg->get('gui_window::word_corresp->too_many1') # 現在の設定では
					.$check_num
					.kh_msg->get('gui_window::word_corresp->too_many2') # 語が布置されます。
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many3') # 布置する語の数は100〜150程度におさえることを推奨します。
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many4') # 続行してよろしいですか？
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	$self->{words_obj}->settings_save;

	my $wait_window = gui_wait->start;

	# データの取り出し
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => 0,
	)->run;

	print '$r_command is_utf8 (1): ', utf8::is_utf8($r_command), "\n" if $debug;

	# 見出しの取り出し
	if (
		(
			   $self->{radio_type} eq 'twomode'
			&& $self->{var_obj}->var_id =~ /h[1-5]/
		)
		or (
			   $self->{radio_type} eq 'words'
			&& $self->{net_obj}->cor_var == 1
			&& $self->{net_obj}{var_obj2}->var_id =~ /h[1-5]/
		)
	) {
		my $tani1 = $self->tani;
		my $tani2;
		if ($self->{radio_type} eq 'twomode'){
			$tani2 = $self->{var_obj}->var_id;
		} else {
			$tani2 = $self->{net_obj}{var_obj2}->var_id;
		}
		
		# 見出しリスト作成
		my $max = mysql_exec->select("SELECT max(id) FROM $tani2")
			->hundle->fetch->[0];
		my %heads = ();
		for (my $n = 1; $n <= $max; ++$n){
			$heads{$n} = mysql_getheader->get($tani2, $n);
		}

		if ($tani1 eq $tani2) {
			gui_errormsg->open(
				type => 'msg',
				msg  => 'Unexpected selection of computing units!',
			);
			$wait_window->end(no_dialog => 1);
			return 0;
		}

		my $sql = '';
		$sql .= "SELECT $tani2.id\n";
		$sql .= "FROM   $tani1, $tani2\n";
		$sql .= "WHERE \n";
		foreach my $i ("h1","h2","h3","h4","h5"){
			$sql .= " AND " unless $i eq "h1";
			$sql .= "$tani1.$i"."_id = $tani2.$i"."_id\n";
			if ($i eq $tani2){
				last;
			}
		}
		$sql .= "ORDER BY $tani1.id \n";
		my $h = mysql_exec->select($sql,1)->hundle;

		$r_command .= "\nv0 <- c(";
		while (my $i = $h->fetch){
			$r_command .= "\"$heads{$i->[0]}\",";
		}
		chop $r_command;
		$r_command .= ")\n";
	}

	# 外部変数の取り出し
	if (
		(
			   $self->{radio_type} eq 'twomode'
			&& $self->{var_obj}->var_id =~ /^[0-9]+$/
		)
		or (
			   $self->{radio_type} eq 'words'
			&& $self->{net_obj}->cor_var == 1
			&& $self->{net_obj}{var_obj2}->var_id =~ /^[0-9]+$/
		)
	) {
		
		my $var_obj;
		if ($self->{radio_type} eq 'twomode') {
			$var_obj = mysql_outvar::a_var->new(undef,$self->{var_obj}->var_id);
		} else {
			$var_obj = mysql_outvar::a_var->new(undef,$self->{net_obj}{var_obj2}->var_id);
		}
		
		my $sql = '';
		if ($var_obj->{tani} eq $self->tani){
			$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
			$sql .= "ORDER BY id";
		} else {
			my $tani1 = $self->tani;
			my $tani2 = $var_obj->{tani};
			$sql .= "SELECT $var_obj->{table}.$var_obj->{column}\n";
			$sql .= "FROM   $tani1, $tani2,$var_obj->{table}\n";
			$sql .= "WHERE \n";
			foreach my $i ("h1","h2","h3","h4","h5"){
				$sql .= " AND " unless $i eq "h1";
				$sql .= "$tani1.$i"."_id = $tani2.$i"."_id\n";
				if ($i eq $tani2){
					last;
				}
			}
			$sql .= " AND $tani2.id = $var_obj->{table}.id \n";
			$sql .= "ORDER BY $tani1.id \n";
		}
		
		$r_command .= "v0 <- c(";
		my $h = mysql_exec->select($sql,1)->hundle;
		my $n = 0;
		while (my $i = $h->fetch){
			if ( length( $var_obj->{labels}{$i->[0]} ) ){
				my $t = $var_obj->{labels}{$i->[0]};
				$t =~ s/"/ /g;
				$r_command .= "\"$t\",";
			} else {
				$r_command .= "\"$i->[0]\",";
			}
			++$n;
		}
		
		chop $r_command;
		$r_command .= ")\n";
	}

	if (
		   $self->{net_obj}->cor_var == 1
		&& $self->{net_obj}{var_obj2}->var_id eq 'pos'
	) {
		$r_command .= "v0 <- 1:nrow(d)\n";
	}

	# 外部変数・見出しデータの統合
	if ($self->{radio_type} eq 'twomode'){
		$r_command = $r_command;
		$r_command .= &r_command_concat;
	}

	# データ整理
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	$self->{net_obj}->{edge_type} = $self->gui_jg( $self->{radio_type} );

	use plotR::network;
	my $plotR = plotR::network->new(
		$self->{net_obj}->params,
		font_size        => $self->{font_obj}->font_size,
		font_bold        => $self->{font_obj}->check_bold_text,
		plot_size        => $self->{font_obj}->plot_size,
		r_command        => $r_command,
		plotwin_name     => 'word_netgraph',
	);
	
	# プロットWindowを開く
	$wait_window->end(no_dialog => 1);
	
	if ($::main_gui->if_opened('w_word_netgraph_plot')){
		$::main_gui->get('w_word_netgraph_plot')->close;
	}

	return 0 unless $plotR;
	
	my $ax = 0;
	if (
		   $self->{net_obj}{check_cor_var} == 1
		&& $self->{radio_type} ne "twomode"
	){
		$ax = 6;
	}
	
	gui_window::r_plot::word_netgraph->open(
		plots       => $plotR->{result_plots},
		msg         => $plotR->{result_info},
		msg_long    => $plotR->{result_info_long},
		ax          => $ax,
		#no_geometry => 1,
	);

	$plotR = undef;

	unless ( $self->{check_rm_open} ){
		$self->withd;
	}
	return 1;
}



#--------------#
#   アクセサ   #

sub label{
	return kh_msg->get('win_title'); # 抽出語・共起ネットワーク：オプション
}

sub win_name{
	return 'w_word_netgraph';
}

sub min{
	my $self = shift;
	return $self->{words_obj}->min;
}
sub max{
	my $self = shift;
	return $self->{words_obj}->max;
}
sub min_df{
	my $self = shift;
	return $self->{words_obj}->min_df;
}
sub max_df{
	my $self = shift;
	return $self->{words_obj}->max_df;
}
sub tani{
	my $self = shift;
	return $self->{words_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{words_obj}->hinshi;
}

sub r_command_concat{
	return '
# 1つの外部変数が入ったベクトルを0-1マトリクスに変換
mk.dummy <- function(dat){
	dat  <- factor(dat)
	cols <- length(levels(dat))
	ret <- NULL
	for (i in 1:length( dat ) ){
		c <- numeric(cols)
		c[as.numeric(dat)[i]] <- 1
		ret <- rbind(ret, c)
	}
	colnames(ret) <- paste( "<>", levels(dat), sep="" )
	rownames(ret) <- NULL
	return(ret)
}
v1 <- mk.dummy(v0)

# 抽出語と外部変数を接合
n_words <- ncol(d)
d <- cbind(d, v1)

d <- subset(
	d,
	v0 != "'
	.kh_msg->get('gui_window::word_corresp->nav') # 欠損値
	.'" & v0 != "." & v0 != "missing"
)
v0 <- NULL
v1 <- NULL

d <- t(d)
d <- subset(
	d,
	rownames(d) != "<>'
	.kh_msg->get('gui_window::word_corresp->nav') # 欠損値
	.'" & rownames(d) != "<>." & rownames(d) != "<>missing"
)
d <- t(d)

';
}

1;