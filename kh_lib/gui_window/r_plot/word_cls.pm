package gui_window::r_plot::word_cls;
use base qw(gui_window::r_plot);

sub renew_command{
	my $self = shift;
	$self->{photo_pane}->yview(moveto => 0);

	if ($::main_gui->if_opened('w_word_cls_height')){
		$::main_gui->get('w_word_cls_height')->renew(
			$self->{ax}
		);
	}
}

sub photo_pane_width{
	return 490;
}

sub option1_options{
	return [ 'nothing' ];
}

sub option1_name{
	return kh_msg->get('method'); #  ��ˡ��
}

sub start{
	my $self = shift;
	$self->{bottom_frame}->Button(
		-text => kh_msg->get('agglomer'), # ʻ����
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			if ($::main_gui->if_opened('w_word_cls_height')){
				$::main_gui->get('w_word_cls_height')->renew(
					$self->{ax}
				);
			} else {
				gui_window::cls_height::word->open(
					plots => $self->{merges},
					type  => 0,
				);
			}
		}
	)->pack(-side => 'left',-padx => 2);
}

sub end{
	my $self = shift;
	
	if ($::main_gui->if_opened('w_word_cls_height')){
		$::main_gui->get('w_word_cls_height')->close;
	}
	
	&gui_window::r_plot::end($self);
}

sub win_title{
	return kh_msg->get('win_title'); # ��и졦���饹����ʬ��
}

sub win_name{
	return 'w_word_cls_plot';
}


sub base_name{
	return 'word_cls';
}

1;