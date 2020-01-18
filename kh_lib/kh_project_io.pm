package kh_project_io;

use strict;
use MySQL::Backup_kh;
use MIME::Base64;
use YAML qw(DumpFile LoadFile);
use Archive::Zip;

sub export{
	my $savefile = $_[0];

	my $mb = new_from_DBH MySQL::Backup_kh($::project_obj->dbh);

	# MySQL�Υǡ������Ǽ
	my $file_temp_mysql = $::config_obj->file_temp;
	open (MYSQLO,'>:encoding(utf8)', $file_temp_mysql) or
		gui_errormsg->open(
			type => 'file',
			file => $file_temp_mysql
		)
	;
	$mb->create_structure(*MYSQLO);
	$mb->data_backup(*MYSQLO);
	$mb->create_index_structure(*MYSQLO);
	close (MYSQLO);

	# MySQL::Backup�Ϥ�����Ƚ�������ɬ�פ����ä�
	#   1. �Хå����åפε�ư�򡢰�Ԥ��Ĥν��Ϥ��ѹ�       �� OK
	#   2. �Хå����åפθ�Ψ��                             �� OK
	#   3. ʣ��Index���б�                                  �� OK
	#   4. �ꥹ�ȥ��ε�ư�⡢��Ԥ����ɤ߹���Ǥμ¹Ԥ��ѹ� �� OK

	# ����ե���������
	my $file_temp_info = $::config_obj->file_temp;
	my %info;
	$info{'file_name'} = encode_base64(
		Encode::encode('utf8', $::project_obj->file_short_name),
		''
	);
	$info{'comment'}   = encode_base64(
		Encode::encode('utf8', $::project_obj->comment),
		''
	);
	DumpFile($file_temp_info, %info) or
		gui_errormsg->open(
			type => 'file',
			file => $file_temp_info
		)
	;

	# Zip�ե�����˸Ǥ��
	my $zip = Archive::Zip->new();
	
	$zip->addFile( $file_temp_mysql, 'mysql' );
	$zip->addFile( $file_temp_info,  'info' );
	$zip->addFile(
		$::config_obj->os_path($::project_obj->file_target),
		'target'
	);
	
	unless ( $zip->writeToFileNamed($savefile) == "AZ_OK" ) {
		gui_errormsg->open(
			type => 'file',
			file => $savefile
		)
	}

	# ����ե��������
	unlink ($file_temp_mysql, $file_temp_info);

	return 1;
}

sub import{
	my $file_save   = shift;
	my $file_target = shift;

	# �ץ������Ȥ򳫤��Ƥ�����ϥ�����
	$::main_gui->close_all;
	undef $::project_obj;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;

	# ʬ���оݥե�����β���
	my $zip = Archive::Zip->new();
	unless ( $zip->read( $file_save ) == "AZ_OK" ) {
		print "Could not open zip file!\n";
		return undef;
	}

	my $file_temp_target = $::config_obj->file_temp;
	unless ( $zip->extractMember('target',$file_temp_target) == "AZ__OK" ){
		print "Could not extract target file!\n";
		return undef;
	}
	rename($file_temp_target, $file_target) or
		gui_errormsg->open(
			type => 'file',
			file => $file_target
		)
	;	# 2�Х���ʸ��������ʸ���ˤ��ե�����̾�˴ޤޤ�Ƥ���ȡ�����˼��Ԥ��롪
		# �Τǡ����ä���temp�ե�����˲��ष�Ƥ����͡���

	# �ץ������Ȥ���Ͽ
	my $info = &get_info($file_save);
	
	my $new = kh_project->new(
		target  => $file_target,
		comment => $info->{comment},
		icode   => 0,
	) or return 0;
	kh_projects->read->add_new($new) or return 0; # ���Υץ������Ȥ��������

	# MySQL�ǡ����١����ν����ʥ��ꥢ��
	my @tables = mysql_exec->table_list;
	foreach my $i (@tables){
		mysql_exec->drop_table($i);
	}

	# MySQL�ǡ����١���������
	my $file_temp_mysql = $::config_obj->file_temp;
	unless ( $zip->extractMember('mysql',$file_temp_mysql) == "AZ__OK" ){
		return undef;
	}
	my $mb = new_from_DBH MySQL::Backup_kh($::project_obj->dbh);
	$mb->run_restore_script($file_temp_mysql);
	unlink($file_temp_mysql);

	undef $::project_obj;
}


sub get_info{
	my $file = shift;
	
	# ����
	my $zip = Archive::Zip->new();
	unless ( $zip->read( $file ) == "AZ_OK" ) {
		return undef;
	}
	my $file_temp_info = $::config_obj->file_temp;
	unless ( $zip->extractMember('info',$file_temp_info) == "AZ__OK" ){
		return undef;
	}

	# ���
	my %info = LoadFile($file_temp_info) or return undef;
	foreach my $i (keys %info){
		$info{$i} = Encode::decode('utf8', decode_base64($info{$i}) )
	}
	unlink($file_temp_info);

	return \%info;
}




1;
