# Xilinx ISE Makefile

Tired of clicking around in Xilinx ISE? Run your builds from the command line!

## Forked from..

The original project is located at [Xilinx-ISE-Makefile](https://github.com/duskwuff/Xilinx-ISE-Makefile) and was created by [duskwuff](github.com/duskwuff/).

Many thanks for the good work!

## Requirements

- Xilinx ISE, ideally 14.7 (the final version)

  Works great on Linux. Windows Subsystem for Linux is tested and works well.

- GNU (or compatible?) Make

  Install this through Cygwin on Windows.

## Creating a project

To start building a project, you will need to create a file `project.cfg` in
the top level of your project. This file is a text file sourced by Make, so
it consists of `KEY = value` pairs. It must define at least the following keys:

- `PROJECT`

  The name of the project, used as a name for certain intermediate files, and
  as the default name for the top-level module and constraints file.

- `TARGET_PART`

  The full part-speed-package identifier for the Xilinx part to be targeted,
  e.g. `xc6slx9-2-tqg144`.

- `XILINX`

  The path to the appropriate binaries directory of the target Xilinx ISE
  install, e.g.
  `/cygdrive/c/Xilinx/14.7/ISE_DS/ISE`
  or
  `/opt/Xilinx/14.7/ISE_DS/ISE`
  for typical installs.

- `VSOURCE` and/or `VHDSOURCE`

  The space-separated names of all Verilog and/or VHDL source files to be
  used in the project.

  You can define these on multiple lines using `+=`, e.g.

      VSOURCE += foo.v
      VSOURCE += bar.v

  You can also add a library name to the source file, e.g.

      VSOURCE += my_lib:foo.v
      VSOURCE += my_lib:bar.v

  The default library name is `work`.

A simple `project.cfg` may thus resemble:

    PROJECT = example
    TARGET_PART = xc6slx9-2-cpg196

    XILINX = /cygdrive/c/Xilinx/14.7/ISE_DS/ISE/bin/nt64

    VSOURCE = example.v

A number of other keys can be set in the project configuration, including:

- `XILINX_PLATFORM`

  The Xilinx name for the platform to build for, e.g. `nt64` or `lin`.
  `nt64` is used by default for Windows systems, and `lin64` for Linux
  systems, so you only need to set this if you explicitly need to use the
  32-bit version of the tools for some reason.

- `TOPLEVEL`

  The name of the top-level module to be used in the project.
  (Defaults to `$PROJECT`.)

- `CONSTRAINTS`

  The name of the constraints file (`.ucf`) to be used for the project.
  (Defaults to `$PROJECT.ucf`.)

- `COMMON_OPTS`

  Extra command-line options to be passed to all ISE executables. Defaults to
  `-intstyle xflow`.

- `XST_OPTS`, `NGDBUILD_OPTS`, `MAP_OPTS`, `PAR_OPTS`, `BITGEN_OPTS`,
  `TRACE_OPTS`, `FUSE_OPTS`

  Extra command-line options to be passed to the corresponding ISE tools.

  Defaults is:

  ```
  XST_OPTS        ?=
  NGDBUILD_OPTS   ?=
  MAP_OPTS        ?= -detail
  PAR_OPTS        ?=
  BITGEN_OPTS     ?=
  TRACE_OPTS      ?= -v 3 -n 3
  FUSE_OPTS       ?= -incremental
  ```

  Note that `XST_OPTS` will not appear on the command line during
  compilation, as the XST options are embedded in a script file.

  `MAP_OPTS` and `PAR_OPTS` can be set to `-mt 2` to use multithreading,
  which may speed up compilation of large designs.

  `BITGEN_OPTS` can be set to `-g Compress` to apply bitstream compression.

- `PROGRAMMER`

  The name of the programmer to be used for `make prog`. Currently supported
  values are:

  - `impact`

    Uses Xilinx iMPACT for programming, using a batch file named
    `impact.cmd` by default. The iMPACT command line may be overridden by
    setting `IMPACT_OPTS`.

    A typical batch file may resemble:

        setMode -bscan
        setCable -p auto
        addDevice -p 1 -file build/projectname.bit
        program -p 1
        quit

  - `digilent`

    Uses the Digilent JTAG utility for programming, which must be installed
    separately. The name of the board must be set as `DJTG_DEVICE`; the
    path to the djtgcfg executable can be set as `DJTG_EXE`, and the index
    of the device can be set as `DJTG_INDEX`. You can set the flash index
    with `DJTG_FLASH_INDEX`.

  - `xc3sprog`

    Uses the xc3sprog utility for programming, which must also be installed
    separately. The cable name must be set as `XC3SPROG_CABLE`; additional
    options can be set as `XC3SPROG_OPTS`.

- `PROGRAMMER_PRE`

  A command to be run before programming. This can be used to use `sudo` or
  `yes` to confirm programming.

## Targets

The Xilinx ISE Makefile implements the following targets:

- `make default` (or just `make`)

  Builds the bitstream.

- `make clean`

  Removes the build directory.

- `make prog`

  Writes the bitstream to a target device. Requires some additional
  configuration; see below for details.

- `make flash`

  Writes the bitstream to a flash device.
  **This is currently only for digilent implemented.**

## Console output

After a successful build, you will find the paths to the generated **reports** on the console. E.g.:

```
============ Reports.. ===========

==== Synthesis Summary Report ====
 ./build/Example.srp

======= Map Summary Report =======
 ./build/Example.map.mrp

======= PAR Summary Report =======
 ./build/Example.par

===== Pinout Summary Report ======
 ./build/Example_pad.txt

```

## Unimplemented features

The following features are not currently implemented. (Pull requests are
encouraged!)

- Generation of SPI or other unusual programming files

- CPLD synthesis

- Synthesis tools other than XST

- Display and/or handling of warnings and errors from `build/_xmsgs`

- Running unit tests

- Anything else (open an issue?)

## License

To the extent possible under law, the author(s) have dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.

See LICENSE.md for details.
