---
layout: post
title: Writing an ELF executable from scratch 
---

## The ELF header layout
An ELF file begins with a few magic bytes and data structures that instruct the operating system on how to load and run the executable.
A basic C representation of this would be:
```cpp
struct ELFHeader {
  char magic_bytes[4];

  uint8_t address_width;
  uint8_t endianness;
  uint8_t elf_version;
  uint8_t os_abi;
  uint8_t abi_version;

  char padding[7];

  uint16_t file_type;
  uint16_t instruction_set;

  uint32_t elf_version_copy;

  void* entry_point;
  void* program_header_table_pointer;
  void* section_header_table_pointer;

  uint8_t flags[4];

  uint16_t header_size;
  uint16_t program_header_table_entry_size;
  uint16_t program_header_table_number_of_entries;
  uint16_t section_header_table_entry_size;
  uint16_t section_header_table_number_of_entries;
  uint16_t section_header_table_section_names_index;
}
```
Don't worry if some of these fields seem confusing, they will be explained as we add them to the executable.

### Building our ELF header
We begin by defining the four byte "Magic Number" that specifies that this is an ELF executable. This is the byte `0x7F` followed by the
ASCII representation of "ELF"
```c
0x7F // ELF magic number
0x45 // 'E'
0x4C // 'L'
0x46 // 'F'
```
We next must fill in the next five bytes to represent what platform we are targeting; followed by seven reserved bytes of 
padding which should be filled with zeroes. Since we will be targeting 64 Bit Linux we set these bytes to:

```c
0x02 // 64 Bit Executable (0x01 represents 32 Bit)
0x01 // Little Endian (any Intel or AMD x86_64 processor will always be little endian)
0x01 // This is the current version of ELF
0x00 // System V UNIX ABI (There are a few valid values of this which aren't reproduced here) 
0x00 // Ignored ABI Version Specifier on Linux
0x00 0x00 0x00 0x00 0x00 0x00 0x00 // Seven bytes of padding
```

We now have to set the flags that determine what type of ELF binary we are creating and the targeted instruction set.
Since we are creating a executable program this will be 
```c
0x02 0x00 // '2' (The bytes appear out of order since they are little endian)
0x3E 0x00 // 0x3E is the hex representation for the x86_64 processor architecture
``` 

We follow this by four bytes representing another copy of the current version of ELF
```c
0x01 0x00 0x00 0x00 // the same as previously only this time with extra bytes
```
The ELF version number is followed by three pointers, these go to:
1. The entry point of the function (Since we aren't doing anything fancy this will be right after the program header table)
2. The start of the program header table (Immediately following the ELF header)
3. The Section Header Table (We won't be using any special sections so for our program this will be empty)
At the moment we know two of these. The first is the offset to the start of the program header table (`0x40` followed by 
7 null bytes to make up a 64 bit pointer) since a 64 bit ELF header is (coincidentally) 64 bytes long.
The second is the Section Header Table pointer, which will be the null pointer since we won't be using it.

We don't know what the pointer for the entry point should be yet, but we can calculate it by adding together the sizes of the
Program header and the ELF header and then offsetting that by the location that we are going to have our program loaded at.

| Element       | Size (In bytes) |
|---------------|-----------------|
|ELF Header     |             64  |
|Program Header |             56  |
|Total          |             120 |

The total size of the two headers is 120 bytes, which means that the offset is `0x78`. We now need to pick a location to load
our program at. The default location for GNU ld to link a program's code section at is `0x400000`
so we add our `0x78` offset to that to get `0x400078` as our entry point address.
We can now write the next portion of our header starting with that entry point.
```c
0x78 0x00 0x40 0x00 0x00 0x00 0x00 0x00 // Entry point address (In little endian encoding and extended to 64 bits)
0x40 0x00 0x00 0x00 0x00 0x00 0x00 0x00 // Program header offset
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 // The section header table offset (We aren't using this so it is null)
```
We don't need any special architecture flags for our program so the next four bytes will also be null
```c
0x00 0x00 0x00 0x00
```
We now need bytes representing the sizes and numbers of the various ELF header entries
```c
0x40 0x00 // The ELF Header Size (64 bytes)
0x38 0x00 // The size of a program header entry (56 bytes)
0x01 0x00 // The number of program header entries (We will only have one)
0x00 0x00 // The size of a section header entry (0 bytes since we aren't using it)
0x00 0x00 // The number of section header entries (We aren't using any sections)
0x00 0x00 // The index of the section header names entry (null, since we aren't using it)
```

We now have a complete ELF header which should be parsable by the `file` command on linux, or `readelf` with
the `-h` flag which tells it to display the ELF header of the file. It should correctly show the data, although
`readelf` will output an error since we told it that we have a program header entry and didn't actually provide
one. 

Here is an example of what the output of `readelf -h` will be for the program:
```
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              EXEC (Executable file)
  Machine:                           Advanced Micro Devices X86-64
  Version:                           0x1
  Entry point address:               0x400078
  Start of program headers:          64 (bytes into file)
  Start of section headers:          0 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           56 (bytes)
  Number of program headers:         1
  Size of section headers:           0 (bytes)
  Number of section headers:         0
  Section header string table index: 0
```
You can see that most of the data that we programmed into the header is very nicely rendered here. You can even mess
with the values of some of the fields and see how that changes the output.

The end of `readelf`'s output will be an error message telling you that it tried to read
the program headers but it got the end of the file instead which we are expecting.
```txt
readelf: Error: Reading 56 bytes extends past end of file for program headers
```

That's it for this post. In the next post we will build the program header entry and actually get our basic executable to run.
