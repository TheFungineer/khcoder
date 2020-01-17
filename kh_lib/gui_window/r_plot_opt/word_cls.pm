package gui_window::r_plot_opt::word_cls;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# ���饹������
	$self->{cls_obj} = gui_widget::r_cls->open(
		parent  => $lf,
		command => sub{ $self->calc; },
		pack    => { -anchor   => 'w'},
		r_cmd   => $self->{command_f},
	);

	return $self;
}

sub calc{
	my $self = shift;
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('r_net_msg_fail'), # Ĵ���˼��Ԥ��ޤ��ޤ�����
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	if (
		   $self->{cls_obj}->cluster_number =~ /Auto/i
		|| $self->{font_obj}->plot_size     =~ /Auto/i
	) {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('err_no_auto'), # ����Window�Ǥϡ�Auto�׻���ϤǤ��ޤ��󡣿��ͤ����Ϥ��Ƥ�������
		);
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;

	&gui_window::word_cls::make_plot(
		$self->{cls_obj}->params,
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'word_cls',
	);

	$wait_window->end(no_dialog => 1);
	$self->close;
	return 1;
}

sub win_title{
	return kh_msg->get('win_title'); # ��и졦���饹����ʬ�ϡ�Ĵ��
}

sub win_name{
	return 'w_word_cls_plot_opt';
}

1;