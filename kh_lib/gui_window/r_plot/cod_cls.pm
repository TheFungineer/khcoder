package gui_window::r_plot::cod_cls;
use base qw(gui_window::r_plot);

sub renew_command{
	my $self = shift;
	$self->{photo_pane}->yview(moveto => 0);

	if ($::main_gui->if_opened('w_cod_cls_height')){
		$::main_gui->get('w_cod_cls_height')->renew(
			$self->{ax}
		);
	}
}

sub photo_pane_width{
	return 490;
}

sub option1_options{
	return [
		'Wardˡ',
		'��ʿ��ˡ',
		'�Ǳ���ˡ'
	];
}

sub option1_name{
	return ' ��ˡ��';
}

sub start{
	my $self = shift;
	$self->{bottom_frame}->Button(
		-text => $self->gui_jchar('ʻ����'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $self->win_obj->after
			(
				10,
				sub {
					if ($::main_gui->if_opened('w_cod_cls_height')){
						$::main_gui->get('w_cod_cls_height')->renew(
							$self->{ax}
						);
					} else {
						gui_window::cls_height::cod->open(
							plots => $self->{merges},
							type  => $self->{ax},
						);
					}
				}
			);
		}
	)->pack(-side => 'left',-padx => 2);
}

sub end{
	if ($::main_gui->if_opened('w_cod_cls_height')){
		$::main_gui->get('w_cod_cls_height')->close;
	}
}

sub win_title{
	return '�����ǥ��󥰡����饹����ʬ��';
}

sub win_name{
	return 'w_cod_cls_plot';
}


sub base_name{
	return 'cod_cls';
}

1;