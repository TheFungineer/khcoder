package gui_window::r_plot_opt::doc_cls;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# ���饹�����ο�ʬ��
	if ( $self->{command_f} =~ /ggplot2/ ){
		$self->{check_color_cls} = 1;
	} else {
		$self->{check_color_cls} = 0;
	}

	# ��ʬ��
	$lf->Checkbutton(
			-text     =>
				kh_msg->get('gui_widget::r_cls->color'), # ���饹�����ο�ʬ��
			-variable => \$self->{check_color_cls},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	return $self;
}

sub calc{
	my $self = shift;
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# start dendro.+/s){
		$r_command = $1;
		#$r_command = Jcode->new($r_command)->euc
		#	if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('r_net_msg_fail'), # Ĵ���˼��Ԥ��ޤ��ޤ�����
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	my ($w, $h) = ($::config_obj->plot_size_codes, $self->{font_obj}->plot_size);

	if ($self->{check_color_cls}){
		$r_command .= &gui_window::doc_cls::r_command_dendro2(
			$self->{font_obj}->font_size
		);
	} else {
		$r_command .= &gui_window::doc_cls::r_command_dendro1(
			$self->{font_obj}->font_size
		);
		($w, $h) = ($h, $w);
	}

	my $wait_window = gui_wait->start;

	my $plot = kh_r_plot->new(
		name      => 'doc_cls_dendro',
		command_f =>  $r_command,
		width     => $w,
		height    => $h,
		font_size => $self->{font_obj}->font_size,
	) or return 0;
	$plot->rotate_cls unless $self->{check_color_cls};

	if ($::main_gui->if_opened('w_doc_cls_plot')){
		$::main_gui->get('w_doc_cls_plot')->close;
	}

	gui_window::r_plot::doc_cls->open(
		plots       => [$plot],
		ax          => $self->{ax},
	);

	$plot = undef;
	$self->{command_f} = undef;

	$wait_window->end(no_dialog => 1);
	$self->close;
	return 1;

}

sub win_title{
	return kh_msg->get('win_title'); # ��и졦���饹����ʬ�ϡ�Ĵ��
}

sub win_name{
	return 'w_doc_cls_plot_opt';
}

1;