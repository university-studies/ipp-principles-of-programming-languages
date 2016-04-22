NAME=SYN-doc
all:
	vlna -v KkSsVvZzOoUuAIai $(NAME).tex
	latex $(NAME).tex
	dvips -t a4 $(NAME).dvi
	ps2pdf $(NAME).ps

clean:
	rm -f $(NAME).dvi $(NAME).log $(NAME).ps $(NAME).aux $(NAME).pdf

pack: all
	zip xloffa00-SYN.zip $(NAME).pdf syn.py

pack_source:
	zip xloffa00-SYN-source.zip $(NAME).tex Makefile syn.py

pack_test:
	zip xloffa00-SYN-test.zip public-syn-tests.zip _stud.tests.sh

