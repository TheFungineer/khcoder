package gui_window::contxt_out::tab;
use base qw(gui_window::contxt_out);

use strict;

#--------------#
#   ���å�   #
#--------------#

sub go{
	print "go!";
	
	my $self = shift;
	my $file = shift;
	
	$self->{words_obj}->settings_save;
	
	mysql_contxt::tab->new(
		tani     => $self->{tani_obj}->value,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
		tani_df  => $self->tani_df,
		hinshi2  => $self->hinshi2,
		max2     => $self->max2,
		min2     => $self->min2,
		max_df2  => $self->max_df2,
		min_df2  => $self->min_df2,
		tani_df2 => $self->tani_df2,
	)->culc->save($file);
}

#-----------------#
#   ��¸��λ���  #

sub file_name{
	my $self = shift;
	my @types = (
		[ $self->gui_jchar("���ֶ��ڤ�"),[qw/.txt/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('gui_window::contxt_out::csv->saving')),
		-initialdir       => $self->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	return $path;
}

# Window��٥�
sub label{
	return kh_msg->get('win_title') # ����и��ʸ̮�٥��ȥ��ɽ�ν��ϡ� ���ֶ��ڤ�
}

sub win_name{
	return 'w_cross_out_tab';
}

1;
