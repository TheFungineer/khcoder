move plugin_jp plugin_jp_bak
move plugin_en plugin_en_bak
attrib -h kh_lib\Tk\CVS
move kh_lib\Tk\CVS CVS_bak
perlapp --add Encode::Guess;Encode::JP::H2Z;Encode::JP;feature;Encode::EUCJPMS;kh_project_io;YAML::Dumper;YAML::Loader --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.ca[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.ca,mode=666] --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.de[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.de,mode=666] --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.el[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.el,mode=666] --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.en[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.en,mode=666] --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.es[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.es,mode=666] --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.fr[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.fr,mode=666] --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.it[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.it,mode=666] --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.nl[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.nl,mode=666] --bind auto/share/dist/Lingua-Sentence/nonbreaking_prefix.pt[file=C:\apps\Perl\site\lib\auto\share\dist\Lingua-Sentence\nonbreaking_prefix.pt,mode=666] --icon memo\1.ico --lib .\kh_lib --shared private --tmpdir config --norunlib --verbose --force --info "CompanyName=Ritsumeikan Univ.;FileDescription=KH Coder;FileVersion=2;InternalName=kh_coder.exe;LegalCopyright=Higuchi Koichi;OriginalFilename=kh_coder.exe;ProductName=KH Coder;ProductVersion=2" --exe kh_coder.exe kh_coder.pl
move plugin_jp_bak plugin_jp
move plugin_en_bak plugin_en
move CVS_bak kh_lib\Tk\CVS
attrib +h kh_lib\Tk\CVS
pause
