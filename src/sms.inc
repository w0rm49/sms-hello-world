; Порты

.define MemoryControlPort $3e
.define IOControlPort $3f
.define PSGPort $7e
.define VDPVCounterPort $7e
.define VDPHCounterPort $7f
.define VDPDataPort $be
.define VDPControlPort $bf
.define IOPort1 $dc
.define IOPort2 $dd

; Команды VDP

.define VDPReadVRAM $00
.define VDPWriteVRAM $40
.define VDPWriteRegister $80
.define VDPWriteCRAM $c0

; Регистры VDP

.define VDPReg0RightPanel      %10000000
.define VDPReg0TopPanel        %01000000
.define VDPReg0HideFirstCol    %00100000
.define VDPReg0EnableHblank    %00010000
.define VDPReg0ShiftSprites    %00001000
.define VDPReg0EnableMode4     %00000100
.define VDPReg0ExtendedHeight  %00000010
.define VDPReg0ExternalSync    %00000001

.define VDPReg1EnableScreen    %01000000
.define VDPReg1EnableVblank    %00100000
.define VDPReg1Height28Rows    %00010000
.define VDPReg1Height30Rows    %00001000
.define VDPReg1DoubleTiles     %00000010
.define VDPReg1DoubleSprites   %00000001