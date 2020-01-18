package gui_window::r_plot::cod_som;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;
	if (@{$self->{plots}} == 4){
		return [
			kh_msg->get('gui_window::r_plot::word_som->cls'),  # ���饹����
			kh_msg->get('gui_window::r_plot::word_som->gray'), # ���졼��������
			kh_msg->get('gui_window::r_plot::word_som->freq'), # �ٿ�
			kh_msg->get('gui_window::r_plot::word_som->umat'), # U����
		];
	} else {
		return [
			kh_msg->get('gui_window::r_plot::word_som->gray'), # ���졼��������
			kh_msg->get('gui_window::r_plot::word_som->freq'), # �ٿ�
			kh_msg->get('gui_window::r_plot::word_som->umat'), # U����
		];
	}
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_som->views'); # ' ���顼��';
}

sub win_title{
	return kh_msg->get('win_title'); # �����ɡ������ȿ����ޥå�
}

sub win_name{
	return 'w_cod_som_plot';
}


sub base_name{
	return 'cod_som';
}

1;