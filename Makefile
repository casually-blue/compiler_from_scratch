all: setup elf_bin 

serve: setup
	cd docs && jekyll serve --baseurl "" -D

elf_bin: obj/elf_header obj/elf_program_header obj/elf_code
	cat $^ > $@
	chmod +x $@

obj/elf_code: obj Makefile
	echo "b8 04000000 \
				bb 00000000 \
				48b9 9F00400000000000 \
				ba 0d000000 \
				cd80 \
				\
				b8 01000000 \
				bb 00000000 \
				cd80 \
				48656c6c6f20576f726c64210a" | xxd -r -p - $@

obj/elf_header: docs/_posts/2022-05-29-Writing_A_Basic_Elf_Executable_From_Scratch.md obj
	cat $< \
		| codedown c \
		| cpp \
		| tail -n +7 \
		| sed --expression="s/0x//g" \
		| tr '\n' ' ' \
		| sed --expression="s/ //g" \
		| xxd -r -p - $@

obj/elf_program_header: docs/_posts/2022-05-30-Creating_The_Elf_Program_Header.md obj
	cat $< \
		| codedown c \
		| cpp \
		| tail -n +7 \
		| sed --expression="s/0x//g" \
		| tr '\n' ' ' \
		| sed --expression="s/ //g" \
		| xxd -r -p - $@

clean:
	rm -rf obj
	rm -f elf_test

obj:
	mkdir -p $@

.PHONY: setup
setup: .setup

.setup:
	sudo npm install -g codedown
	sudo gem install jekyll
	touch .setup
