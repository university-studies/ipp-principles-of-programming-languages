NAME=JSN-doc

all:
	vlna -v KkSsVvZzOoUuAIai $(NAME).tex
	latex $(NAME).tex
	dvips -t a4 $(NAME).dvi
	ps2pdf $(NAME).ps

clean:
	rm -f $(NAME).dvi $(NAME).log $(NAME).ps $(NAME).aux $(NAME).pdf

pack: all
	zip xloffa00-JSN.zip $(NAME).pdf jsn.pl xml_writer.pm rozsireni 

pack_source:
	zip xloffa00-JSN-source.zip JSN-doc.tex jsn.pl rozsireni Makefile xml_writer.pm

pack_test:
	zip xloffa00-JSN-test.zip public-jsn-tests.zip _stud_tests.sh add_root.py jexamxml.zip options
	
