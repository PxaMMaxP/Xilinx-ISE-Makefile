###########################################################################
## Xilinx ISE Makefile
##
## To the extent possible under law, the author(s) have dedicated all copyright
## and related and neighboring rights to this software to the public domain
## worldwide. This software is distributed without any warranty.
##
## Makefile github repository: https://github.com/PxaMMaxP/Xilinx-ISE-Makefile
###########################################################################

###########################################################################
# Version
###########################################################################

Makefile_Version := 1.0.3
$(info ISE Makefile Version: $(Makefile_Version))

###########################################################################
# Include project configuration
###########################################################################

include ../project.cfg

###########################################################################
# Default values
###########################################################################

ifndef XILINX
    $(error XILINX must be defined)
endif

ifndef PROJECT
    $(error PROJECT must be defined)
endif

ifndef TARGET_PART
    $(error TARGET_PART must be defined)
endif

TOPLEVEL         ?= $(PROJECT)
CONSTRAINTS      ?= $(PROJECT).ucf
BUILD_DIR        ?= working
BITFILE          ?= $(BUILD_DIR)/$(PROJECT).bit
 
COMMON_OPTS      ?= -intstyle xflow
XST_OPTS         ?=
NGDBUILD_OPTS    ?=
MAP_OPTS         ?= -detail
PAR_OPTS         ?=
BITGEN_OPTS      ?=
TRACE_OPTS       ?= -v 3 -n 3
FUSE_OPTS        ?= -incremental
 
PROGRAMMER       ?= none
PROGRAMMER_PRE   ?=
 
IMPACT_OPTS      ?= -batch impact.cmd
 
DJTG_EXE         ?= djtgcfg
DJTG_DEVICE      ?= DJTG_DEVICE-NOT-SET
DJTG_INDEX       ?= 0
DJTG_FLASH_INDEX ?= 1

XC3SPROG_EXE     ?= xc3sprog
XC3SPROG_CABLE   ?= none
XC3SPROG_OPTS    ?=


###########################################################################
# Internal variables, platform-specific definitions, and macros
###########################################################################

ifeq ($(OS),Windows_NT)
    XILINX := $(shell cygpath -m $(XILINX))
    CYG_XILINX := $(shell cygpath $(XILINX))
    EXE := .exe
    XILINX_PLATFORM ?= nt64
    PATH := $(PATH):$(CYG_XILINX)/bin/$(XILINX_PLATFORM)
else
    EXE :=
    XILINX_PLATFORM ?= lin64
    PATH := $(PATH):$(XILINX)/bin/$(XILINX_PLATFORM)
endif

TEST_NAMES = $(foreach file,$(VTEST) $(VHDTEST),$(basename $(file)))
TEST_EXES = $(foreach test,$(TEST_NAMES),$(BUILD_DIR)/isim_$(test)$(EXE))

RUN = @echo "\n\e[1;33m============ $(1) ============\e[m\n"; \
	cd $(BUILD_DIR) && $(XILINX)/bin/$(XILINX_PLATFORM)/$(1)

# isim executables don't work without this
export XILINX

# Initialize the libs and paths variables for VHDL and Verilog sources
VHD_PATHS ?=
VHD_LIBS  ?=
V_PATHS   ?=
V_LIBS    ?=

# Define a function to process source files
define process_sources
$(foreach src,$(1),\
    $(eval lib_and_path=$(subst :, ,$(src))) \
    $(eval libname=$(word 1,$(lib_and_path))) \
    $(eval filepath=$(word 2,$(lib_and_path))) \
    $(if $(filepath),,$(eval filepath=$(libname)) $(eval libname=work)) \
    $(eval $(2) += $(libname)) \
    $(eval $(3) += ../$(filepath)) \
)
endef

# Run the function for VHDL sources
$(eval $(call process_sources,$(VHDSOURCE),VHD_LIBS,VHD_PATHS))
# Run the function for Verilog sources
$(eval $(call process_sources,$(VSOURCE),V_LIBS,V_PATHS))

###########################################################################
# Default build
###########################################################################

default: $(BITFILE)

clean:
	rm -rf $(BUILD_DIR)

$(BUILD_DIR)/$(PROJECT).prj: ../project.cfg
	@echo "Updating $@"
	@mkdir -p $(BUILD_DIR)
	@rm -f $@
	@$(foreach idx,$(shell seq 1 $(words $(V_PATHS))),echo "verilog $(word $(idx),$(V_LIBS)) \"../$(word $(idx),$(V_PATHS))\"" >> $@;)
	@$(foreach idx,$(shell seq 1 $(words $(VHD_PATHS))),echo "vhdl $(word $(idx),$(VHD_LIBS)) \"../$(word $(idx),$(VHD_PATHS))\"" >> $@;)


$(BUILD_DIR)/$(PROJECT)_sim.prj: $(BUILD_DIR)/$(PROJECT).prj
	@cp $(BUILD_DIR)/$(PROJECT).prj $@
	@$(foreach file,$(VTEST),echo "verilog work \"../../$(file)\"" >> $@;)
	@$(foreach file,$(VHDTEST),echo "vhdl work \"../../$(file)\"" >> $@;)
	@echo "verilog work $(XILINX)/verilog/src/glbl.v" >> $@

$(BUILD_DIR)/$(PROJECT).scr: ../project.cfg
	@echo "Updating $@"
	@mkdir -p $(BUILD_DIR)
	@rm -f $@
	@echo "run" \
	    "-ifn $(PROJECT).prj" \
	    "-ofn $(PROJECT).ngc" \
	    "-ifmt mixed" \
	    "$(XST_OPTS)" \
	    "-top $(TOPLEVEL)" \
	    "-ofmt NGC" \
	    "-p $(TARGET_PART)" \
	    > $(BUILD_DIR)/$(PROJECT).scr

$(BITFILE): ../project.cfg $(V_PATHS) $(VHD_PATHS) ../$(CONSTRAINTS) $(BUILD_DIR)/$(PROJECT).prj $(BUILD_DIR)/$(PROJECT).scr
	@mkdir -p $(BUILD_DIR)
	$(call RUN,xst) $(COMMON_OPTS) \
	    -ifn $(PROJECT).scr
	$(call RUN,ngdbuild) $(COMMON_OPTS) $(NGDBUILD_OPTS) \
	    -p $(TARGET_PART) -uc ../../$(CONSTRAINTS) \
	    $(PROJECT).ngc $(PROJECT).ngd
	$(call RUN,map) $(COMMON_OPTS) $(MAP_OPTS) \
	    -p $(TARGET_PART) \
	    -w $(PROJECT).ngd -o $(PROJECT).map.ncd $(PROJECT).pcf
	$(call RUN,par) $(COMMON_OPTS) $(PAR_OPTS) \
	    -w $(PROJECT).map.ncd $(PROJECT).ncd $(PROJECT).pcf
	$(call RUN,bitgen) $(COMMON_OPTS) $(BITGEN_OPTS) \
	    -w $(PROJECT).ncd $(PROJECT).bit
	@echo "\e[1;32m============ OK ============\e[m\n\n"
	@echo "\e[1;33m============ Reports.. ===========\e[m\n"
	@echo "\e[1;97m==== Synthesis Summary Report ====\e[m"
	@echo "\e[1;35m ./$(BUILD_DIR)/$(PROJECT).srp\e[m\n"
	@echo "\e[1;97m======= Map Summary Report =======\e[m"
	@echo "\e[1;35m ./$(BUILD_DIR)/$(PROJECT).map.mrp\e[m\n"
	@echo "\e[1;97m======= PAR Summary Report =======\e[m"
	@echo "\e[1;35m ./$(BUILD_DIR)/$(PROJECT).par\e[m\n"
	@echo "\e[1;97m===== Pinout Summary Report ======\e[m"
	@echo "\e[1;35m ./$(BUILD_DIR)/$(PROJECT)_pad.txt\e[m\n"
	


###########################################################################
# Testing (work in progress)
###########################################################################

trace: ../project.cfg $(BITFILE)
	$(call RUN,trce) $(COMMON_OPTS) $(TRACE_OPTS) \
	    $(PROJECT).ncd $(PROJECT).pcf
	@echo "\n\e[1;33m============ Reports.. ===========\e[m\n"
	@echo "\e[1;97m===== Timing Summary Report ======\e[m"
	@echo "\e[1;35m ./$(BUILD_DIR)/$(PROJECT).twr\e[m\n"

test: $(TEST_EXES)

$(BUILD_DIR)/isim_%$(EXE): $(V_PATHS) $(VHD_PATHS) $(BUILD_DIR)/$(PROJECT)_sim.prj $(VTEST) $(VHDTEST)
	$(call RUN,fuse) $(COMMON_OPTS) $(FUSE_OPTS) \
	    -prj $(PROJECT)_sim.prj \
	    -o isim_$*$(EXE) \
	    work.$* work.glbl

isim: $(BUILD_DIR)/isim_$(TB)$(EXE)
	@grep --no-filename --no-messages 'ISIM:' $(TB).{v,vhd} | cut -d: -f2 > $(BUILD_DIR)/isim_$(TB).cmd
	@echo "run all" >> $(BUILD_DIR)/isim_$(TB).cmd
	cd $(BUILD_DIR) ; ./isim_$(TB)$(EXE) -tclbatch isim_$(TB).cmd

isimgui: $(BUILD_DIR)/isim_$(TB)$(EXE)
	@grep --no-filename --no-messages 'ISIM:' $(TB).{v,vhd} | cut -d: -f2 > $(BUILD_DIR)/isim_$(TB).cmd
	@echo "run all" >> $(BUILD_DIR)/isim_$(TB).cmd
	cd $(BUILD_DIR) ; ./isim_$(TB)$(EXE) -gui -tclbatch isim_$(TB).cmd


###########################################################################
# Programming
###########################################################################

ifeq ($(PROGRAMMER), impact)
prog: $(BITFILE)
	$(PROGRAMMER_PRE) $(XILINX)/bin/$(XILINX_PLATFORM)/impact $(IMPACT_OPTS)
endif

ifeq ($(PROGRAMMER), digilent)
prog: $(BITFILE)
	$(PROGRAMMER_PRE) $(DJTG_EXE) prog -d $(DJTG_DEVICE) -i $(DJTG_INDEX) -f $(BITFILE)
endif

ifeq ($(PROGRAMMER), xc3sprog)
prog: $(BITFILE)
	$(PROGRAMMER_PRE) $(XC3SPROG_EXE) -c $(XC3SPROG_CABLE) $(XC3SPROG_OPTS) $(BITFILE)
endif

ifeq ($(PROGRAMMER), none)
prog:
	$(error PROGRAMMER must be set to use 'make prog')
endif

###########################################################################
# Flash
###########################################################################

ifeq ($(PROGRAMMER), digilent)
flash: $(BITFILE)
	$(PROGRAMMER_PRE) $(DJTG_EXE) prog -d $(DJTG_DEVICE) -i $(DJTG_FLASH_INDEX) -f $(BITFILE)
endif

###########################################################################
