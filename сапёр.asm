ADD_D_C equ 0x6b
SUB_D_C equ 0x7b
INC_D equ 0x6F
DEC_D equ 0x7F
emoji equ field + 11
enter equ field + 35
jmp ask_start
cell db
0b11111111,
0b10000001,
0b10000001,
0b10000001,
0b10000001,
0b11111111
enter db
0b00000000,
0b00100000,
0b01110000,
0b00100000,
0b00111110,
0b00000000
play db
0b00000000,
0b00100100,
0b01000000,
0b01000000,
0b00100100,
0b00000000
win db
0b00000110,
0b00100110,
0b01000010,
0b01000010,
0b00100110,
0b00000110
lose db
0b00000000,
0b01000100,
0b00100000,
0b00100000,
0b01000100,
0b00000000
ask_row_text db "\nrow (a-k): "
ask_row_size equ $ - ask_row_text
ask_column_text db "column\n(1-4): "
ask_column_size equ $ - ask_column_text
bcd db 0, 0
terminal db 0
terminal_art db 0
in_out db 0b00000101
bank db 0
set_bank:
  st c, bank
  jmp d
set_bank2:
  st a, bank
  jmp b
cursor db 0
row db 0
column db 0
save db 0
adress_end db wait
void db 0, 0, 0, 0, 0, 0
field db 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4,
2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, " ",
2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3,
2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
ask_start:
  ldi d, terminal
ask:
  ldi b, ask_row_size
  ldi c, ask_row_text
ask_row_loop:
  ld a, c
  st a, d
  inc c
  dec b
  jnz ask_row_loop
ask_row:
  ld a, in_out
  mov c, a
  ldi b, "a"
  sub a, b
  jnc ask_row
  ldi b, 10
  sub b, a
  jnc ask_row
  st c, d
  st a, row
ldi b, ask_column_size
ldi c, ask_column_text
ask_column_loop:
  ld a, c
  st a, d
  inc c
  dec b
  jnz ask_column_loop
ask_column:
  ld a, in_out
  mov c, a
  ldi b, "1"
  sub a, b
  jnc ask_column
  ldi b, 3
  sub b, a
  jnc ask_column
  st c, d
  st a, column
ld b, row
mov c, a
add a, c
add a, c
shl a
shl a
add a, b
ldi b, field
add a, b
st a, cursor
ask_jmp:
  jmp random
random:
  ldi b, 1
  st b, a
  ldi d, 10
  random_column:
    rnd a
    ldi b, 3
    and a, b
  random_row:
    rnd b
    ldi c, 11
    mod_b_c:
      sub b, c
      jc mod_b_c
    add b, c
  mov c, a
  add a, c
  add a, c
  shl a
  shl a
  add a, b
  ldi b, field
  add a, b
  ld b, a
  dec b
  jz random_column
  st b, a
  dec d
  jnz random_column
ld a, cursor
ldi b, 2
st b, a
ldi b, 34
st b, bcd
ldi b, check_mine_jmp
st b, ask_jmp + 1
check_mine_jmp:
  ldi c, 2
  ldi d, check_mine
  jmp set_bank
void2 db 0, 0, 0, 0, 0, 0, 0
check_mine:
  ld b, a
  dec b
  jnz check_repeat
  ldi c, 4
  ldi d, game_over
  jmp set_bank
check_repeat:
  dec b
  jz check_side
  clr c
  ldi d, ask_start
  jmp set_bank
check_side:
  ld d, cursor
  ldi c, 12
  ld a, column
  test a
  jz horizontal_side_up_jmp
  ldi b, 3
  xor a, b
  jz horizontal_side_down_jmp
  ld a, row
  test a
  jz vertical_side_left_jmp
  ldi b, 10
  xor a, b
  jz vertical_side_right_jmp
next0:
  clr a
  sub d, c
  ld b, d
  dec b
  jnz next1
  inc a
next1:
  inc d
  ld b, d
  dec b
  jnz next2
  inc a
next2:
  add d, c
  ld b, d
  dec b
  jnz next3
  inc a
next3:
  add d, c
  ld b, d
  dec b
  jnz next4
  inc a
next4:
  dec d
  ld b, d
  dec b
  jnz next5
  inc a
next5:
  dec d
  ld b, d
  dec b
  jnz next6
  inc a
next6:
  sub d, c
  ld b, d
  dec b
  jnz next7
  inc a
next7:
  sub d, c
  ld b, d
  dec b
  jnz end_counter
  inc a
end_counter:
  ldi c, 5
  ldi d, show_counter
  jmp set_bank
horizontal_side_up_jmp:
  ldi a, 3
  ldi b, horizontal_side_up
  jmp set_bank2
horizontal_side_down_jmp:
  ldi a, 3
  ldi b, horizontal_side_down
  jmp set_bank2
vertical_side_left_jmp:
  ldi a, 4
  ldi b, vertical_side_left
  jmp set_bank2
vertical_side_right_jmp:
  ldi a, 4
  ldi b, vertical_side_right
  jmp set_bank2
void3 db 0, 0, 0, 0, 0, 0, 0
horizontal_side_up:
  ld a, row
  test a
  jz corner_up_left
  ldi b, 10
  xor a, b
  jz corner_up_right
  ldi a, ADD_D_C
  st a, next11
  ldi a, SUB_D_C
  st a, next14
  jmp next10
horizontal_side_down:
  ld a, row
  test a
  jz corner_down_left_jmp
  ldi b, 10
  xor a, b
  jz corner_down_right_jmp
  ldi a, SUB_D_C
  st a, next11
  ldi a, ADD_D_C
  st a, next14
next10:
  clr a
  dec d
  ld b, d
  dec b
  jnz next11
  inc a
next11:
  add d, c
  ld b, d
  dec b
  jnz next12
  inc a
next12:
  inc d
  ld b, d
  dec b
  jnz next13
  inc a
next13:
  inc d
  ld b, d
  dec b
  jnz next14
  inc a
next14:
  sub d, c
  ld b, d
  dec b
  jnz end_counter2
  inc a
  jmp end_counter2
corner_up_left:
  ldi a, INC_D
  st a, next31
  jmp next30
corner_up_right:
  ldi a, DEC_D
  st a, next31
next30:
  clr a
  add d, c
  ld b, d
  dec b
  jnz next31
  inc a
next31:
  inc d
  ld b, d
  dec b
  jnz next32
  inc a
next32:
  sub d, c
  ld b, d
  dec b
  jnz end_counter2
  inc a
  jmp end_counter2
end_counter2:
  ldi c, 5
  ldi d, show_counter
  jmp set_bank
corner_down_left_jmp:
  ldi a, 4
  ldi b, corner_down_left
  jmp set_bank2
corner_down_right_jmp:
  ldi a, 4
  ldi b, corner_down_right
  jmp set_bank2
void4 db 0, 0, 0, 0, 0, 0, 0, 0
vertical_side_left:
  ldi a, INC_D
  st a, next21
  ldi a, DEC_D
  st a, next24
  jmp next20
vertical_side_right:
  ldi a, DEC_D
  st a, next21
  ldi a, INC_D
  st a, next24
next20:
  clr a
  sub d, c
  ld b, d
  dec b
  jnz next21
  inc a
next21:
  inc d
  ld b, d
  dec b
  jnz next22
  inc a
next22:
  add d, c
  ld b, d
  dec b
  jnz next23
  inc a
next23:
  add d, c
  ld b, d
  dec b
  jnz next24
  inc a
next24:
  dec d
  ld b, d
  dec b
  jnz end_counter3
  inc a
  jmp end_counter3
corner_down_left:
  ldi a, INC_D
  st a, next41
  jmp next40
corner_down_right:
  ldi a, DEC_D
  st a, next41
next40:
  clr a
  sub d, c
  ld b, d
  dec b
  jnz next41
  inc a
next41:
  inc d
  ld b, d
  dec b
  jnz next42
  inc a
next42:
  add d, c
  ld b, d
  dec b
  jnz end_counter3
  inc a
end_counter3:
  ldi c, 5
  ldi d, show_counter
  jmp set_bank
game_over:
  ldi a, end
  st a, adress_end
  ldi a, 6
  st a, emoji
  ldi a, " "
  st a, enter
  ldi c, 5
  ldi d, draw_field
  jmp set_bank
void db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0
show_counter:
  ldi b, 0x30
  add a, b
  ld b, cursor
  st a, b
check_win:
  ld a, bcd
  dec a
  st a, bcd
  jnz draw_field
  ldi a, end
  st a, adress_end
  ldi a, 5
  st a, emoji
  ldi a, " "
  st a, enter
draw_field:
  ldi c, field
  ldi d, 0x3c
  ldi a, "\n"
  st a, d
draw_field_loop:
  ld a, c
  dec a
  jnz check_draw
  inc a
  jmp draw
  check_draw:
    ldi b, 7
    sub a, b
    add a, b
    jc draw
    inc a
    st a, d
    jmp check_end
  draw:
    st c, save
    ldi c, cell
    dec a
    mov b, a
    add a, b
    add a, b
    shl a
    add c, a
    inc d
    ldi b, 6
  draw_loop:
    ld a, c
    st a, d
    inc c
    dec b
    jnz draw_loop
  dec d
  ld c, save
  check_end:
    inc c
    jns draw_field_loop
ld a, adress_end
jmp a
wait:
  ld a, in_out
  test a
  jz wait
  ldi a, "\f"
  st a, d
  inc a
  st a, d
  clr a
  ldi b, ask
  jmp set_bank2
end:
  hlt
