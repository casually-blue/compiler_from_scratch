all: setup elf_bin 

serve: setup
	cd docs && jekyll serve --baseurl "" -D

elf_bin: obj/elf_header obj/elf_program_header obj/elf_code
	cat $^ > $@
	chmod +x $@

obj/elf_code: hex/elf_code obj
	cat $< | xxd -r -p - $@

obj/elf_header: hex/elf_header obj
	cat $< | xxd -r -p - $@

obj/elf_program_header: hex/elf_program_header obj
	cat $< | xxd -r -p - $@

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
