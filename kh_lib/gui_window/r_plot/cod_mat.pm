package gui_window::r_plot::cod_mat;
use base qw(gui_window::r_plot);


sub option1_options{
	return [
		kh_msg->get('heat'), # '�ҡ��ȥޥå�',
		kh_msg->get('fluc'), # '�Х֥�ץ�å�',
		#kh_msg->get('line'),
	];
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_corresp->view'); # ' ɽ����';
}

sub photo_pane_width{
	my $self = shift;
	return 640;
}

# Ĵ���Ѥ�Window�򳫤�
sub open_config{
	my $self = shift;
	
	# �����������μ���
	my $ax = $self->{ax};
	$self->{ax} = 0;
	$self->renew(1);
	my $plot_size_heat = $self->{photo}->cget(-image)->height;
	
	$self->{ax} = 1;
	$self->renew(1);
	my $plot_size_maph = $self->{photo}->cget(-image)->height;
	my $plot_size_mapw = $self->{photo}->cget(-image)->width;
	
	$self->{ax} = $ax;
	$self->renew(1);
	print "size: $plot_size_heat, $plot_size_maph, $plot_size_mapw\n";

	my $base_name = 'gui_window::r_plot_opt::'.$self->base_name;
	$self->{child} = $base_name->open(
		command_f      => $self->{plots}[$self->{ax}]->command_f,
		font_size      => $self->{plots}[$self->{ax}]->{font_size} * 100,
		ax             => $self->{ax},
		plot_size_heat => $plot_size_heat,
		plot_size_maph => $plot_size_maph,
		plot_size_mapw => $plot_size_mapw
	);
	
	return $self;
}

# ����ɽ���ѥ��֥������Ȥ�ƺ����ʥ�������С���ꥻ�åȤ��뤿���
sub renew{
	my $self = shift;
	my $opt  = shift;
	
	return 0 unless $self->{optmenu};

	$self->{photo_pane}->xview(moveto => 0) unless $opt;
	$self->{photo_pane}->yview(moveto => 0) unless $opt;

	$gui_window::r_plot::imgs->{$self->win_name}->delete;
	$gui_window::r_plot::imgs->{$self->win_name}->destroy;
	$gui_window::r_plot::imgs->{$self->win_name} = undef;

	$gui_window::r_plot::imgs->{$self->win_name} = 
		$self->{win_obj}->Photo('photo_'.$self->win_name,
			-file => $self->{plots}[$self->{ax}]->path,
		)
	;

	$self->renew_command;
}




sub win_title{
	return kh_msg->get('win_title');
}

sub win_name{
	return 'w_cod_mat_plot';
}


sub base_name{
	return 'cod_mat';
}

sub child_windows{
	return ('');
}

1;