package TermExtract::BrillsTagger;
use TermExtract::Calc_Imp;

use strict;
use Exporter ();
use vars qw(@ISA $VERSION @EXPORT);
use locale;

@ISA = qw(TermExtract::Calc_Imp Exporter);
@EXPORT = qw();
$VERSION = "2.15";

# ========================================================================
# get_noun_frq -- Get noun frequency.
#                 The values of the hash are frequency of the noun.
# �i���p��Ƃ��̕p�x�𓾂�T�u���[�`���j
#
#  Over-write TermExtract::Calc_Imp::get_noun_frq
#
# ========================================================================

sub get_noun_frq {
    my $self = shift;
    my $data = shift;           # ���̓f�[�^
    my $mode = shift || 0;      # ���̓f�[�^���t�@�C�����A�ϐ����̎��ʗp�t���O
    my %cmp_noun_list = ();     # ������ƕp�x������ꂽ�n�b�V���i�֐��̖߂�l�j

    $self->IgnoreWords('of', 'Of', 'OF');  # of �͏d�v�x�v�Z�O�Ƃ���

    # ���͂���Ƀt�@�C���Ɖ��肵�A��K�̓t�@�C���ɂ��Ή��ł���悤�A�t�@�C��
    # ���e��1�s���ǂݍ���ŏ�������悤�ɕύX�i����k�� 2012 08/01�j

    # ���͂��t�@�C���̏ꍇ
    #if ($mode ne 'var') {                                       # higuchi
    #    local($/) = undef;                                      # higuchi
    #    open (IN, $data) || die "Can not open input file. $!";  # higuchi
    #    $data = <IN>;                                           # higuchi
    #    close IN;                                               # higuchi
    #}                                                           # higuchi

    #foreach my $morph ((split /\n/, $data)) {                   # higuchi
    open (IN, $data) || die "Can not open input file. $!";       # higuchi
    while (<IN>){                                                # higuchi
        my $morph = $_;                                          # higuchi
        chomp $morph;
        next if $morph =~ /^\s*$/;

        # $status = 1   �O������(NN, NNS, NNP)
        #           2   �O���`�e��(JJ)
        #           3   �O�����L�i���(POS)
        #           4   �O��of
        #           5   �O���(CD)
        #           6   �O���ߋ������̓���(VBN)
        #           7   �O���O����(FW)
        my $status = 0;

        my $rest   = 0;  # �����ȊO�̌ꂪ����A���������J�E���g
        my @seg    = (); # ������̃��X�g�i�z��j

        foreach my $term (split(/ /, $morph)) {
            # ���l���؂�L���̏ꍇ
            if($term =~ /^[\s\+\-\%\&\$\*\#\^\|\/]/ || $term =~ /^[\d]+\//){
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                next;
            }
            next if $term =~ /suusiki/;  # �����͏��O

            # �����̏ꍇ
            if($term =~ /NN[PS]?$/ || $term =~ /NNPS$/){
                # �����`��P���`�ɒu��������B
                $term = &_stemming($term) if $term =~ /NNS$/;
                # �ŗL�����ȊO�͐擪�̑啶�����������ɁB
                $term = lcfirst($term) if ($term =~ /NNS?$/ && $term =~ /^[A-Z][a-z]/);
                $status = 1;
                push(@seg, $term); $rest = 0;
            }
            # �`�e��(JJ)�̏ꍇ
            elsif($term =~ /JJ$/){
                #�@�O�̌ꂪ"�Ȃ�","�`�e��","���L�i���","�"�̏ꍇ�͘A������
                if($status == 0 || $status == 2 || $status == 3 || $status == 5){
                    push(@seg, $term); $rest++;
                }
                else{
                    _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                    @seg = ($term); $rest++;
                }
                $status = 2;
           }
            # ���L�i���(POS)�̏ꍇ
            elsif($term =~ /POS$/){
               # �O�̌ꂪ�����̏ꍇ�͘A������
               if($status == 1){
                    $status = 3;
                    push(@seg, $term); $rest++;
                }
                else{
                    _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                }
            }
            # of �̏ꍇ
            elsif($term =~ /^of\/IN$/){
                # �O�̌ꂪ�����̏ꍇ�͘A������
                if($status == 1){
                    $status = 4;
                    push(@seg, $term); $rest++;
                }
                else{
                    _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                    $status = 0;
		}
            }
            # �(CD)�̏ꍇ�́A��̐擪�̂݋���
            elsif($term =~ /CD$/){
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                @seg = ($term);
                $status = 5;
            }
            # �ߋ������̓����͌�̐擪�̂݋���
            elsif($term =~ /VBN$/){
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                $status = 6;
                @seg = ($term); $rest++;
            }
            # �O����(FW)�̏ꍇ�͒P��Ƃ��ď���
            elsif($term =~ /FW$/){
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                $status = 7;
                @seg = ($term);
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
            }
            # �w�肵���i���ȊO�̏ꍇ�́A�����ŕ�����̋�؂�Ƃ���
            else{
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                $status = 0;
            }
        }
        # ���s���������ꍇ�͂����ŕ�����̋�؂�Ƃ���
        _increase_frq(\%cmp_noun_list, \@seg, \$rest);
        $status = 0;
    }
    close IN;                                                    # higuchi
    return \%cmp_noun_list;
}

# ---------------------------------------------------------------------------
#   _stemming  --  �����`��P���`�ɕς��邾����stemmer
# 
#   usage : _stemming(word);
# ---------------------------------------------------------------------------

sub _stemming {
    my $noun = shift;
	return $noun;                                                # higuchi

    if($noun =~ /ies\// && $noun !~ /[ae]ies\//){
	$noun =~ s/ies\//y\//;
    }
    elsif($noun =~ /es\// && $noun !~ /[aeo]es\//){
	$noun =~ s/es\//e\//;
    }
    elsif($noun =~ /s\// && $noun !~ /[us]s\//){
	$noun =~ s/s\//\//;
    }
    $noun;
}

# ---------------------------------------------------------------------------
#   _increase_frq  --  �p�x���₷
# 
#   usage : _increase_frq(frequency_of_compnoun, segment, rest_after_noun);
# ---------------------------------------------------------------------------

sub _increase_frq {
    my $frq_ref  = shift;
    my $seg      = shift;
    my $rest     = shift;
    my $allwords = "";

    # ������̖����͖����Ƃ��A����ȊO�͐؂�̂Ă�
    $#$seg -= $$rest if @$seg;
    $$rest = 0;

    if ($#$seg >= 0) {
        foreach my $word (@$seg) {
            $word =~ s/^\s+//;        # �ז��ȃX�y�[�X����菜��
            $word =~ s/\s+$//;
	    $word =~ s/\/[A-Z\$]+$//; # �^�O����菜��
            if ($allwords eq "") { 
                $allwords = $word;
            }
            else {
                $allwords .= ' ' . $word;
            }
        }
        # ' �ŋ�؂�ꂽ��͐ڑ�����
        $allwords =~ s/(\S+)\s(\'s\s)/$1$2/g;
        # ������ . �� , �͍폜����
        $allwords =~ s/\,$//;
        $allwords =~ s/\.$//;
        $$frq_ref{"$allwords"}++;
    }
    @$seg = ();
}

1;

__END__

=head1 NAME

    TermExtract::BrillsTagger 
                -- ���p�ꒊ�o���W���[���i"Brill's Tagger"��)

=head1 SYNOPSIS

    use TermExtract::BrillsTagger;

=head1 DESCRIPTION

    ���̓e�L�X�g���A"Brill's Tagger"�i�p���̕i���^�O�t�^�v���O�����j�ɂ�
  ���A���̌��ʂ����Ƃɓ��̓e�L�X�g������p��𒊏o����v���O�����B
    Brill's Tagger�����ɂ��č��ꂽ Monty Tagger �ɂ��Ή����Ă���B

    �Ȃ��ABrill's Tagger �Ń^�O�t�����s���ꍇ�́A���O��Brill's Tagger�t
  ����Perl�X�N���v�g Tokenizer.pl �������Ă������Ƃ𐄏����Ă���B

    �����W���[���̎g�p�@�ɂ��ẮA�e�N���X�iTermExtract::Calc_Imp)���A
  �ȉ��̃T���v���X�N���v�g���Q�Ƃ̂��ƁB

=head2 Sample Script

 #!/usr/local/bin/perl -w
 
 #
 #  ex_BT.pl
 #
 #�@�t�@�C������Brill's Tagger �̏������ʂ�ǂݎ��
 #  �W���o�͂ɐ��p��Ƃ��̏d�v�x��Ԃ��v���O����
 #
 #   version 0.14
 #
 #
 
 use TermExtract::BrillsTagger;
 #use strict;
 my $data = new TermExtract::BrillsTagger;
 my $InputFile = "BT_out.txt";    # ���̓t�@�C���w��
 
 # �v���Z�X�ُ̈�I��������
 # (���b�N�f�B���N�g�����g�p�����ꍇ�̂݁j
 $SIG{INT} = $SIG{QUIT} = $SIG{TERM} = 'sigexit';
 
 # �o�̓��[�h���w��
 # 1 �� ���p��{�d�v�x�A2 �� ���p��̂�
 # 3 �� �J���}��؂�
 my $output_mode = 1;
 
 #
 # �d�v�x�v�Z�ŁA�A�ڌ��"���א�"�A"�قȂ萔"�A"�p�[�v���L�V�e�B"�̂�
 # ������Ƃ邩�I���B�p�[�v���L�V�e�B�́u�w�K�@�\�v���g���Ȃ�
 # �܂��A"�A�ڌ�̏����g��Ȃ�"�I��������A���̏ꍇ�͗p��o����
 # (�Ɛݒ肳��Ă����IDF�̑g�ݍ��킹�j�ŏd�v�x�v�Z���s��
 # �i�f�t�H���g��"���א�"���Ƃ� $obj->use_total)
 #
 #$data->use_total;      # ���א����Ƃ�
 #$data->use_uniq;       # �قȂ萔���Ƃ�
 #$data->use_Perplexity; # �p�[�v���L�V�e�B���Ƃ�(TermExtract 3.04 �ȏ�)
 #$data->no_LR;          # �אڏ����g��Ȃ� (TermExtract 4.02 �ȏ�)
 
 #
 # �d�v�x�v�Z�ŁA�A�ڏ��Ɋ|�����킹��p��o���p�x����I������
 # $data->no_LR; �Ƃ̑g�ݍ��킹�ŗp��o���p�x�݂̂̏d�v�x���Z�o�\
 # �i�f�t�H���g�� "Frequency" $data->use_frq)
 # TF�͂���p�ꂪ���̗p��̈ꕔ�Ɏg���Ă����ꍇ�ɂ��J�E���g
 # Frequency �͗p�ꂪ���̗p��̈ꕔ�Ɏg���Ă����ꍇ�ɃJ�E���g���Ȃ�
 #
 #$data->use_TF;   # TF (Term Frequency) (TermExtract 4.02 �ȏ�)
 #$data->use_frq;  # Frequency�ɂ��p��p�x
 #$data->no_frq;   # �p�x�����g��Ȃ�
 
 #
 # �d�v�x�v�Z�ŁA�w�K�@�\���g�����ǂ����I��
 # �i�f�t�H���g�́A�g�p���Ȃ� $obj->no_stat)
 #
 #$data->use_stat; # �w�K�@�\���g��
 #$data->no_stat;  # �w�K�@�\���g��Ȃ�
 
 #
 # �d�v�x�v�Z�ŁA�u�h�L�������g���̗p��̕p�x�v�Ɓu�A�ڌ�̏d�v�x�v
 # �̂ǂ���ɔ�d����������ݒ肷��B
 # �f�t�H���g�l�͂P
 # �l���傫���قǁu�h�L�������g���̗p��̕p�x�v�̔�d�����܂�
 #
 #$data->average_rate(0.5);
 
 #
 # �w�K�@�\�pDB�Ƀf�[�^��~�ς��邩�ǂ����I��
 # �d�v�x�v�Z�ŁA�w�K�@�\���g���Ƃ��́A�Z�b�g���Ă������ق���
 # ����B�����ΏۂɊw�K�@�\�pDB�ɓo�^����Ă��Ȃ��ꂪ�܂܂��
 # �Ɛ��������삵�Ȃ��B
 # �i�f�t�H���g�́A�~�ς��Ȃ� $obj->no_storage�j
 #
 #$data->use_storage; # �~�ς���
 #$data->no_storage;  # �~�ς��Ȃ�
 
 #
 # �w�K�@�\�pDB�Ɏg�p����DBM��SDBM_File�Ɏw��
 # �i�f�t�H���g�́ADB_File��BTREE���[�h�j
 #
 #$data->use_SDBM;
 
 #
 # �ߋ��̃h�L�������g�̗ݐϓ��v���g���ꍇ�̃f�[�^�x�[�X��
 # �t�@�C�������Z�b�g
 # �i�f�t�H���g�� "stat.db"��"comb.db"�j
 #
 #$data->stat_db("stat.db");
 #$data->comb_db("comb.db");
 
 #
 # �f�[�^�x�[�X�̔r�����b�N�̂��߂̈ꎞ�f�B���N�g�����w��
 # �f�B���N�g�������󕶎���i�f�t�H���g�j�̏ꍇ�̓��b�N���Ȃ�
 #
 #$data->lock_dir("lock_dir");
 
 #
 # �i���^�O�t���ς݂̃e�L�X�g����A�f�[�^��ǂݍ���
 # ���p�ꃊ�X�g��z��ɕԂ�
 # �i�ݐϓ��vDB�g�p�A�h�L�������g���̕p�x�g�p�ɃZ�b�g�j
 #
 #my @noun_list = $data->get_imp_word($str, 'var');     # ���͂��ϐ�
 my @noun_list = $data->get_imp_word($InputFile); # ���͂��t�@�C��
 
 #
 # �O��ǂݍ��񂾕i���^�O�t���ς݃e�L�X�g�t�@�C��������
 # ���[�h��ς��āA���p�ꃊ�X�g��z��ɕԂ�
 #$data->use_stat->no_frq;
 #my @noun_list2 = $data->get_imp_word();
 # �܂��A���̌��ʂ�ʂ̃��[�h�ɂ�錋�ʂƊ|�����킹��
 #@noun_list = $data->result_filter (\@noun_list, \@noun_list2, 30, 1000);
 
 #
 #  ���p�ꃊ�X�g�ƌv�Z�����d�v�x��W���o�͂ɏo��
 #
 foreach (@noun_list) {
    # ���l�݂͕̂\�����Ȃ�
    next if $_->[0] =~ /^\d+$/;
 
   # ���ʕ\��
   printf "%-60s %16.2f\n", $_->[0], $_->[1] if $output_mode == 1;
   printf "%s\n",           $_->[0]          if $output_mode == 2;
   printf "%s,",            $_->[0]          if $output_mode == 3;
 }

=head1 Methods

    ���̃��W���[���ł́Aget_imp_word �̂ݎ������A����ȊO�̃��\�b�h�͐e
  ���W���[�� TermExtract::Calc_Imp �Ŏ�������Ă���B
    get_imp_word �͕i���^�O�t�^���s�����o���ꂽ�P����A�X�̒P��̌ꏇ
  �ƕi���������ɕ�����ɐ������Ă���B����ȊO�̃��\�b�h�ɂ��ẮA
  TermExtract::Calc_Imp ��POD�h�L�������g���Q�Ƃ��邱�ƁB

=head2 get_imp_word

    �p���̕i���^�O�t�^���ʂ����̃��[���ɂ�蕡����ɐ�������B��P�����́A
  �����Ώۂ̃f�[�^�A��Q�����͑�P�����̎�ʂł���B�f�t�H���g�ł́A��P
  �����́A�i���^�O�t���ς݂̃e�L�X�g�t�@�C���ƂȂ�B��Q�����ɕ�����
  'var'���Z�b�g���ꂽ�Ƃ��ɂ́A��������i���^�O�t���ς̃e�L�X�g�f�[�^
  ���������X�J���[�ϐ��Ɖ��߂���B

    �P�D�e�i���͎��̂Ƃ��茋������
       �i�P�j����(NN)      �@�@�@���@�����A�`�e���A��A�ߋ������̓�����
                                   ��������B������̐擪�ɂȂ�B
       �i�Q�j�O����(FW)    �@�@�@���@�P��Ƃ��ď���
       �i�R�j�(CD)      �@�@�@���@������̐擪�̂݋�����
       �i�S�j�`�e��(JJ)    �@�@�@���@�`�e��,���L�i���,��Ɍ�������B
                                   ������̐擪�ɂȂ�
        (�T�j���L�i���(POS)�@ �@���@�����Ɍ�������
       �i�U�jof�@�@�@�@�@�@�@�@�@���@�����Ɍ�������
       �i�V�j�ߋ������̓���(VBN) ���@������̐擪�̂݋�����

    �Q�D���s���������ꍇ�́A�����ŕ�����̋�؂�Ƃ���

    �R�D���̋L���␔�l�Ŏn�܂��̏ꍇ�́A�����ŕ�����̋�؂�Ƃ���

        +-%\&\$*#^|

    �S�D������͖������O����ŏI�����̂Ƃ��A�Ȍ�͐؂�̂Ă�

    �T�D�ŗL�����ȊO�̖����́A�擪���啶���̏ꍇ�ɏ������ɕϊ�����

    �U�D������̖���(NNS)��P���`�ɕς���

    �V�D' �i�V���O���N�H�[�e�[�V����)�ŋ�؂�ꂽ��͒P��Ƃ���

    �W�D�����ꖖ���� , . �͏�������

    �X�D�d�v�x�v�Z�ɂ����Ď��̌�͖�������
      of Of OF

=head1 SEE ALSO

    TermExtract::Calc_Imp
    TermExtract::Chasen
    TermExtract::MeCab
    TermExtract::EnglishPlainText
    TermExtract::ChainesPlainTextUC
    TermExtract::ChainesPlainTextGB
    TermExtract::ICTCLAS
    TermExtract::JapanesePlainTextEUC
    TermExtract::JapanesePlainTextSJIS

=head1 COPYRIGHT

    ���̃v���O�����́A������w�E����T�u�����A���l������w�E�X�C����������
  �쐬�����u���p�ꎩ�����o�V�X�e���v��termex_e.pl �����Ƀ��W���[��
  TermExtract�p�ɏ������������̂ł���B
    ���̍�Ƃ́A������w�E�O�c�N (maeda@lib.u-tokyo.ac.jp)���s�����B

    �Ȃ��A�{�v���O�����̎g�p�ɂ����Đ����������Ȃ錋�ʂɊւ��Ă������ł�
  ��ؐӔC�𕉂�Ȃ��B

=cut


1;
