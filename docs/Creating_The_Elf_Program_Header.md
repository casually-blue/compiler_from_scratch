# Writing the Program Header Entry
We start the program header right after the ELF header in our test binary.
In most ELF files there are multiple program header table entries, but since
we are just wanting to run some binary code we are just creating one. 
Here is an example of the basic C layout for the program header table:
```c
struct ELFProgramHeaderEntry {
  uint32_t segment_type; 
  uint32_t segment_permission_flags;

  void* segment_offset;
  void* segment_virtual_address;
  void* segment_physical_address;

  uint64_t segment_size_in_file;
  uint64_t segment_size_in_memory;

  uint64_t segment_alignment;
}
```

## Segment type and flags
We start off by defining the type of the segment. We want this segment to get loaded as code,
so we use segment type one (`0x01`) which is a "Loadable" segment. Which means that it has data that is
loaded into the program's address space rather than being parsed by the loader itself.
Like the data in the ELF header the data here is represented in a little endian format.

We next must set the permission flags for the segment. Since we are just writing a simple executable we don't need to
write any data anywhere other than registers and the stack so we can just mark all the memory as readable and executable
but not writable. This is represented as the logical OR of `0x01` for the execute permission and `0x04` for the read 
permission giving us a permission value of `0x05`.

Both of these fields are represented in the header as four bytes.

```bash
0x01 0x00 0x00 0x00 # Loadable Segment Type
0x05 0x00 0x00 0x00 # Read+Execute permission
```

## Segment location
We want the whole executable file to get loaded into the process address space so we just fill in the offset as `0x00`

The next couple header values are the offsets and locations where the segment should be loaded.
We decided in the last post to load the executable at `0x400000` since that is the standard location
that Linux binaries get loaded at. We will use this value for the virtual address
of the binary. The physical address is not important for a linux binary, so we fill it in with `0x0`.

```bash
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 # Offset in the file to load into this segment
0x00 0x00 0x40 0x00 0x00 0x00 0x00 0x00 # Virtual memory address of the start of this segment
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 # Phyical memory address of the start of this segment (ignored)
```

## Segment size
The next two entries specify how much data to read from the file and how much memory to allocate to store it in.
For obvious reasons these should be the same for our executable. It needs to be at least equal to the length of 
the code in our executable, plus the length of the headers. To be extra safe we will use `0xFFFF` as the value
This will probably be more than our first couple executables, but we may want to revisit it in the future and 
keep its value up to date with the size of our program.

```bash
0xFF 0xFF 0x00 0x00 0x00 0x00 0x00 0x00 # Amount of data to read from the ELF file
0xFF 0xFF 0x00 0x00 0x00 0x00 0x00 0x00 # Amound of data to load into memory
```

## Segment alignment
For our simple program we don't care about the alignment of the segment in bytes so we can just put `0x00` as its value.
```bash
0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 # Alignment of the segment
```

We now have all the data needed for our basic elf header and `readelf -h` should now not return any errors when we run it on
our ELF file. However, there is no actual code in the executable so attempting to run it now will just cause a segmentation 
fault.

We can now also call `readelf -l` to 

