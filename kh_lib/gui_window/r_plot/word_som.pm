package gui_window::r_plot::word_som;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;
	if (@{$self->{plots}} == 4){
		return [
			kh_msg->get('cls'),  # ���饹����
			kh_msg->get('gray'), # ���졼��������
			kh_msg->get('freq'), # �ٿ�
			kh_msg->get('umat'), # U����
		];
	} else {
		return [
			kh_msg->get('gray'), # ���졼��������
			kh_msg->get('freq'), # �ٿ�
			kh_msg->get('umat'), # U����
		];
	}
}

sub option1_name{
	return kh_msg->get('views'); # ' ���顼��';
}

sub win_title{
	return kh_msg->get('win_title'); # ��и졦�����ȿ����ޥå�
}

sub win_name{
	return 'w_word_som_plot';
}


sub base_name{
	return 'word_som';
}

1;