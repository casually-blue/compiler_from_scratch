unsigned char as_hex(c) {
	if(c >= '0' && c <= '9') {
		return c - '0';
	} else if(c >= 'a' && c <= 'f'){
		return (c - 'a') + 10;
	}
	return 255;
}

char get_next_char() {
	char c = 255;
	if(!read(0, &c, 1)) {
		return 255;
	}
	return  (c >= 'A' && c <= 'Z') ? (c - 'A' + 'a') : c;
}

char get_hex_digit() {
	char c = 0; 
	do {
		c = get_next_char();
		if(c == '#') {
			do {
				c = get_next_char();
			} while (c != 255 && c != '\n');
		} else if(c == 255 || (c = as_hex(c)) != 255) {
			return c;
		}
	} while(1);
}

unsigned char read_byte() {
	unsigned char higher_half = get_hex_digit();
	unsigned char lower_half = get_hex_digit();

	if(higher_half == 255) {
		exit(0);
	}

	higher_half <<= 4;

	if(lower_half == 255) {
		write(1, &higher_half, 1);
		exit(0);
	}

	return higher_half | lower_half;
}

int main(void) {
	while(1){
		unsigned char c = read_byte();
		write(1, &c, 1);
	}
	return 0;
}
