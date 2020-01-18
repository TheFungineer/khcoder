package gui_window::r_plot_opt::cod_corresp;
use base qw(gui_window::r_plot_opt);
use utf8;

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# 差異の顕著な語のみ分析
	my $fsw = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$self->{check_filter_w_widget} = $fsw->Checkbutton(
		-text     => kh_msg->get('gui_window::cod_corresp->flw'), # 差異が顕著なコードを分析に使用：
		-variable => \$self->{check_filter_w},
		-command  => sub{ $self->refresh_flw;},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$self->{entry_flw_l1} = $fsw->Label(
		-text => kh_msg->get('gui_window::cod_corresp->top'), # 上位
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 0);

	$self->{entry_flw} = $fsw->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 0);
	#$self->{entry_flw}->insert(0,'50');
	$self->{entry_flw}->bind("<Key-Return>",sub{$self->calc;});
	$self->{entry_flw}->bind("<KP_Enter>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_flw});

	# 特徴的な語のみラベル表示
	my $fs = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 2,
	);

	$fs->Checkbutton(
		-text     => kh_msg->get('gui_window::cod_corresp->flt'), # 原点から離れたコードのみラベル表示：
		-variable => \$self->{check_filter},
		-command  => sub{ $self->refresh_flt;},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$self->{entry_flt_l1} = $fs->Label(
		-text => kh_msg->get('gui_window::cod_corresp->top'), # 上位
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_flt} = $fs->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 0);
	#$self->{entry_flt}->insert(0,'50');
	$self->{entry_flt}->bind("<Key-Return>",sub{$self->calc;});
	$self->{entry_flt}->bind("<KP_Enter>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_flt});

	#$self->refresh_flt;

	# バブルプロット用のパラメーター
	my ($check_bubble, $chk_resize_vars, $chk_std_radius, $num_size, $num_var)
		= (0,1,0,100,100);

	if ( $self->{command_f} =~ /bubble_size/ ){
		$check_bubble = 1;
	} else {
		$check_bubble = 0;
	}

	if ( $self->{command_f} =~ /std_radius <\- ([0-9]+)\n/ ){
		$chk_std_radius = $1;
	}
	
	if ( $self->{command_f} =~ /resize_vars <\- ([0-9]+)\n/ ){
		$chk_resize_vars = $1;
	}

	if ( $self->{command_f} =~ /bubble_size <\- ([0-9]+)\n/ ){
		$num_size = $1;
	}

	if ( $self->{command_f} =~ /bubble_var <\- ([0-9]+)\n/ ){
		$num_var = $1;
	}

	$self->{use_alpha} = 1;
	if ( $self->{command_f} =~ /use_alpha <\- ([0-9]+)\n/ ){
		$use_alpha = $1;
	}

	# バブルプロット
	$self->{bubble_obj} = gui_widget::bubble->open(
		parent          => $lf,
		type            => 'corresp',
		command         => sub{ $self->calc; },
		check_bubble    => $check_bubble,
		chk_resize_vars => $chk_resize_vars,
		chk_std_radius  => $chk_std_radius,
		num_size        => $num_size,
		num_var         => $num_var,
		use_alpha       => $use_alpha,
		pack            => {
			-anchor => 'w',
		},
	);

	# 成分
	$self->{xy_obj} = gui_widget::r_xy->open(
		parent    => $lf,
		command   => sub{ $self->calc; },
		pack      => { -anchor => 'w', -pady => 2 },
		r_cmd     => $self->{command_f},
	);

	if ( $self->{command_f} =~ /\nflt <\- ([0-9]+)\n/ ){
		if ($1){
			$self->{check_filter} = 1;
			$self->{entry_flt}->insert(0,$1);
		} else {
			$self->{check_filter} = 0;
			$self->{entry_flt}->insert(0,'50');
		}
		$self->refresh_flt;
	}

	if ( $self->{command_f} =~ /\nflw <\- ([0-9]+)\n/ ){
		if ($1 > 0){
			$self->{check_filter_w} = 1;
			$self->{entry_flw}->insert(0,$1);
		} else {
			$self->{check_filter_w} = 0;
			$self->{entry_flw}->insert(0,'50');
		}
		$self->refresh_flw;
	}

	unless ($self->{command_f} =~ /\n# aggregate\n/){
		$self->{check_filter_w_widget}->configure(-state => 'disabled');
	}

	return $self;
}

# 「特徴語に注目」のチェックボックス
sub refresh_flt{
	my $self = shift;
	if ( $self->{check_filter} ){
		$self->{entry_flt}   ->configure(-state => 'normal');
		$self->{entry_flt_l1}->configure(-state => 'normal');
		#$self->{entry_flt_l2}->configure(-state => 'normal');
	} else {
		$self->{entry_flt}   ->configure(-state => 'disabled');
		$self->{entry_flt_l1}->configure(-state => 'disabled');
		#$self->{entry_flt_l2}->configure(-state => 'disabled');
	}
	return $self;
}

sub refresh_flw{
	my $self = shift;
	if ( $self->{check_filter_w} ){
		$self->{entry_flw}   ->configure(-state => 'normal');
		$self->{entry_flw_l1}->configure(-state => 'normal');
	} else {
		$self->{entry_flw}   ->configure(-state => 'disabled');
		$self->{entry_flw_l1}->configure(-state => 'disabled');
	}
	return $self;
}

sub refresh_std_radius{
	my $self = shift;
	if ( $self->{check_bubble} ){
		$self->{chkw_std_radius}->configure(-state => 'normal');
		$self->{chkw_resize_vars}->configure(-state => 'normal');
	} else {
		$self->{chkw_std_radius}->configure(-state => 'disabled');
		$self->{chkw_resize_vars}->configure(-state => 'disabled');
	}
}

sub calc{
	my $self = shift;
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		#$r_command = Jcode->new($r_command)->euc
		#	if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('r_net_msg_fail'),
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}
	$r_command .= "# END: DATA\n";

	my $biplot = 0;
	if ( $self->{command_f} =~ /biplot <\- ([0-9]+)\n/ ){
		$biplot = $1;
	}

	my $filter = 0;
	if ( $self->{check_filter} ){
		$filter = $self->gui_jgn( $self->{entry_flt}->get );
	}

	my $filter_w = 0;
	if ( $self->{check_filter_w} ){
		$filter_w = $self->gui_jgn( $self->{entry_flw}->get );
	}

	my $wait_window = gui_wait->start;
	my $plot = &gui_window::word_corresp::make_plot(
		base_win     => $self,
		$self->{xy_obj}->params,
		flt          => $filter,
		flw          => $filter_w,
		biplot       => $biplot,
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		r_command    => $r_command,
		plotwin_name => 'cod_corresp',
		bubble       => $self->{bubble_obj}->check_bubble,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		resize_vars  => $self->{bubble_obj}->chk_resize_vars,
		bubble_size  => $self->{bubble_obj}->size,
		bubble_var   => $self->{bubble_obj}->var,
		use_alpha    => $self->{bubble_obj}->alpha,
	);
	$wait_window->end(no_dialog => 1);
	
	# プロットWindowを開く
	if ($::main_gui->if_opened('w_cod_corresp_plot')){
		$::main_gui->get('w_cod_corresp_plot')->close;
	}
	
	gui_window::r_plot::cod_corresp->open(
		plots       => $plot,
		ax          => $self->{ax},
	);
	
	
	$self->close
}

sub win_title{
	return kh_msg->get('win_title'); # コーディング・対応分析：調整
}

sub win_name{
	return 'w_cod_corresp_plot_opt';
}

1;