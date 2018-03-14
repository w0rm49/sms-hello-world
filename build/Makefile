#Пеменяйте пути к папкам в которых 
#у вас находятся исполняемые файлы ассемблера и эмулятор
WLA_DX_PATH  = $(HOME)/sms_dev/tools/wladx/binaries
MEKA_PATH    = $(HOME)/sms_dev/tools/meka
export PATH := $(PATH):$(WLA_DX_PATH):$(MEKA_PATH)

MAIN_FILE    = hello_world
PROJECT_DIR  = $(realpath $(dir $(realpath $(firstword $(MAKEFILE_LIST))))/../)
BUILD_DIR    = $(PROJECT_DIR)/build
SRC_DIR      = $(PROJECT_DIR)/src

build: $(MAIN_FILE).sms

$(MAIN_FILE).o:
	cd $(BUILD_DIR) && wla-z80 -o $(MAIN_FILE).o -I $(SRC_DIR) $(SRC_DIR)/$(MAIN_FILE).asm

$(MAIN_FILE).sms: $(MAIN_FILE).o
	cd $(BUILD_DIR) && echo "[objects]\n$(MAIN_FILE).o" > $(MAIN_FILE).link
	cd $(BUILD_DIR) && wlalink -i -r -v  $(MAIN_FILE).link $(MAIN_FILE).sms

run: $(MAIN_FILE).sms
	cd $(BUILD_DIR) && $(MEKA_PATH)/meka $(MAIN_FILE).sms

clean:
	cd $(BUILD_DIR) && rm -f *.o *.sms *.link
