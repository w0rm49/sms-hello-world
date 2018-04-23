; Описание формата рома 

.memorymap
    defaultslot 0
    slotsize $4000
    slot 0 $0000
    slot 1 $4000
.endme

.rombankmap
    bankstotal 2
    banksize $4000
    banks 2
.endro

.sdsctag 1.0, "", "", ""

.include "sms.inc"

; Определения относящиеся к проекту
.define EOL $ff

; Банк 0 слот 0

.bank 0 slot 0
.org $0000
    di            ; отключаем обработку маскируемых прерываний
    im 1          ; переводим процессор в режим прерываний 1
    ld sp, $dff0  ; укажем начало стека, то есть установим его вершину по адресу $dff0
    jp main       ; переход к метке main

.org $0038        ; обработчик маскируемого прерывания
    ex af,af'
    exx
    in a, (VDPControlPort)
    call PrintStatus
    exx
    ex af,af'
    ei            ; включить прерывания
    reti          ; возврат из прерывания

.org $0066        ; обработчик немаскируемого прерывания
    retn          ; возврат из немаскируемого прерывания


; здесь продолжается основная программа

main:

; Инициализация регистров VDP

ld hl, VdpInit
ld b, VdpInitEnd-VdpInit
ld c, VDPControlPort
otir

; Очищаем видеопамять
ld a, $00                
out (VDPControlPort),a   ; Нам нужно отправить команду $4000
ld a, VDPWriteVRAM       ; запись в VRAM начиная с адреса $0000
out (VDPControlPort),a   ; %01000000 %0000000 = $4000

ld bc, $4000             ; Используем регистр bc как счётчик
                         ; Мы $4000 раз отправим ноль, чтобы забить ими всю память
-:
    ld a, $00            ; загружаем в a $00
    out (VDPDataPort), a ; отправляем содержимое регистра A в порт VDPDataPort
    dec bc               ; уменьшаем счётчик на единицу
    ld a, b              ; теперь нам необходимо проверить обнулился ли регистр bc
    or c                 ; мы просто делаем битовое "или" между старшим и младшим байтом
                         ; результат будет равен нулю только в случае 
                         ; когда оба байта равны нулю
    jp nz, -

; Загружаем палитру
ld a, $00                           ; Отправляем младший байт команды
out (VDPControlPort), a             ; Нам нужно отправить команду $c000
ld a, VDPWriteCRAM                  ; запись в CRAM начиная с адреса $0000
out (VDPControlPort), a             ; %11000000 %0000000 = $c000

ld hl, PaletteData                  ; Адрес начала отправляемой последовательности
ld b, (PaletteDataEnd-PaletteData)  ; Количество отправляемых байт
ld c, VDPDataPort                   ; Номер порта
otir                                ; Отправка


; Загружаем шрифт
ld a, $00                          ; Нам нужно отправить команду $4000
out (VDPControlPort), a            ; запись в VRAM начиная с адреса $0000
ld a, VDPWriteVRAM                 ; %01000000 %0000000 = $c000
out (VDPControlPort), a

ld hl, TilesetData                 ; Начало данных тайлсета
ld bc, TilesetSize                 ; Количество байт
-:
    ld a, (hl)                     ; Получить текущий байт по адресу hl
    out (VDPDataPort), a           ; Отправить в порт данных
    inc hl                         ; Изменяем указатель чтобы 
                                   ; он указывал на следующий байт
    dec bc                         ; Уменьшаем счётчик
    ld a, b                        ; Проверяем обнулился ли счётчик,
    or c
    jp nz, -


; Выводим сообщение

ld hl, Message
ld c, $00
call PrintStr

; Включаем экран
ld a, VDPReg1EnableScreen | VDPReg1EnableVblank
out (VDPControlPort), a
ld a, VDPWriteRegister | $01
out (VDPControlPort), a

.define IO1State $c080
.define IO1Change $c081
.define StrStart $40

ei

in a, (IOPort1)         ; читаем состояние контроллеров из порта
ld (IO1State), a        ; сохраним в памяти текущее состояние
xor a                   ; обнуляем a
ld (IO1Change), a       ; сохраняем 0 в IO1Change

GameLoop:
    in a, (IOPort1)     ; читаем состояние контроллеров из порта
    ld b, a             ; сохраняем новое состояние в b 
    ld a, (IO1State)    ; загружаем предыдущее состояние в a
    xor b               ; в a теперь указано какие биты 
                        ; изменились с прошлого чтения
    ld (IO1Change), a   ; сохраним в памяти изменения
    ld a, b
    ld (IO1State), a    ; сохраним в памяти текущее состояние
    halt                ; дождёмся прерывания
jp GameLoop

PrintStatus:
    ld a, (IO1Change)
    cp 0                  ; Если ничего не изменилось с прошлого чтения,
    ret z                 ; то завершаем процедуру

    ld a, (IO1State)
    ld d, a               ; IO1State в e

    ; стираем строку
    ld b, 22                    ; Длина статусной строки
    ld a, $40                   ; Нам нужно отправить команду $7800
    out (VDPControlPort), a     ; запись в VRAM начиная с адреса $3800
    ld a, VDPWriteVRAM | $38    ; $4000 | $3800 = $7800
    out (VDPControlPort), a
    -:  xor a                   ; обнулим a - $00 - пробел
        out (VDPDataPort), a    ; отправляем символ в виртуальный экран
        dec b
        out (VDPDataPort), a
        jp nz, -                ; возврат к началу цикла

    ; выводим нажатые кнопки
    bit 0, d
    jp nz, +
    ld hl, UpLabel              ; выводимый текст
    ld c, StrStart              ; адрес начала строки в VRAM
    call PrintStr               ; вывод текста
    +: 

    bit 1, d
    jp nz, +
    ld hl, DownLabel
    ld c, StrStart + (3 * 2)
    call PrintStr
    +: 

    bit 2, d
    jp nz, +
    ld hl, LeftLabel
    ld c, StrStart + (8 * 2)
    call PrintStr
    +: 

    bit 3, d
    jp nz, +
    ld hl, RightLabel
    ld c, StrStart + (13 * 2)
    call PrintStr
    +: 

    bit 4, d
    jp nz, +
    ld hl, ALabel
    ld c, StrStart + (19 * 2)
    call PrintStr
    +: 

    bit 5, d
    jp nz, +
    ld hl, BLabel
    ld c, StrStart + (21 * 2)
    call PrintStr
    +: 
ret

; Напечатать слово
; c - позиция на экране
; hl - Адрес начала текста.
PrintStr:
    ld a, c                     ; В c помещаем младший байт адреса в vram 
    out (VDPControlPort), a     ; с которого начинаем запись
    ld a, VDPWriteVRAM | $38    ; $4000 | $3800 = $7800
    out (VDPControlPort), a
    ld b, EOL

    -:  ld a, (hl)              ; в регистр a поместим текущий символ 
        cp b                    ; сравним с символом конца строки
        ret z
        out (VDPDataPort), a    ; отправляем символ в виртуальный экран
        xor a                   ; обнуляем a
        out (VDPDataPort), a    ; отправляем байт аттрибутов
        inc hl
        jp -                    ; возврат к началу цикла
ret

; Данные

.asciitable
    map ' ' = 0
    map '0' to "9" = 1
    map 'a' to "z" = 11
    map 'A' to "Z" = 11
    map '[' = 37
    map '\' = 38
    map ']' = 39
    map '^' = 40
    map '_' = 41
    map ':' = 42
    map ';' = 43
    map '<' = 44
    map '=' = 45
    map '>' = 46
    map '?' = 47
.enda

VdpInit:
  .db $04,$80,$00,$81,$ff,$82,$ff,$85,$ff,$86,$ff,$87,$00,$88,$00,$89,$ff,$8a
VdpInitEnd:

PaletteData:
  .db $00,$3f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
PaletteDataEnd:

Message: 
  .asc "hello world", EOL
UpLabel:
  .asc "up", EOL
DownLabel:
  .asc "down", EOL
LeftLabel:
  .asc "left", EOL
RightLabel:
  .asc "right", EOL
ALabel:
  .asc "a", EOL
BLabel:
  .asc "b", EOL

TilesetData: 
  .incbin "font.bin" fsize TilesetSize
