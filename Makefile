ELF_CODE = $(wildcard hex/elf_code_*)
ELF_BINS = $(patsubst hex/elf_code_%, bin/elf_bin_%, $(ELF_CODE))

all: setup $(ELF_BINS)

serve: setup
	cd docs && jekyll serve --baseurl "" -D

.PRECIOUS: obj/elf_code_%
obj/elf_code_%: hex/elf_code_% obj
	cat $< | xxd -r -p - $@

obj/elf_header: hex/elf_header obj
	cat $< | xxd -r -p - $@

obj/elf_program_header: hex/elf_program_header obj
	cat $< | xxd -r -p - $@

bin/elf_bin_%: obj/elf_header obj/elf_program_header obj/elf_code_%
	cat $^ > $@
	chmod +x $@

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
