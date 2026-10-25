ADD_D_C equ 0x6b ;код команды add d, c (сместить курсор вниз)
SUB_D_C equ 0x7b ;код команды sub d, c (сместить курсор вверх)
INC_D equ 0x6F ;код команды inc d (сместить курсор вправо)
DEC_D equ 0x7F ;код команды dec d (сместить курсор влево)
emoji equ field + 11 ;адрес смайлика на поле
space equ field + 23 ;адрес пробела на поле
enter equ field + 35 ;адрес символа enter на поле
mine equ 0xa4 ;символ, обозначающий мину
cursor equ 0x40 ;адрес хранения курсора
row equ 0x41 ;адрес хранения колонки
column equ 0x42 ;адрес хранения строки
save equ 0x43 ;адрес сохранения важных значений
adress_end equ 0x44 ;адрес хранения перехода после вывода поля
field equ 128 - 47 ;адрес поля
ldi a, 0b00000101 ;подключаем цифровой индикатор и терминал
st a, 0x3e
ldi a, 2 ;заменяем заставку на поле
ldi b, field_loop
ldi d, field
field_loop:
  st a, d
  inc d
  jns b
inc a
st a, enter
inc a
st a, emoji
ldi a, " "
st a, space
jmp ask_start ;переходим к старту
set_bank: ;банкинг с регистрами c и d
  st c, bank
  jmp d
set_bank2: ;банкинг с регистрами a и b
  st a, bank
  jmp b
ask_row_text db "column\n(a-k): " ;текст опроса колонки
ask_row_size equ $ - ask_row_text
ask_column_text db "\nrow (1-4): " ;текст опроса строки
ask_column_size equ $ - ask_column_text
void db 0
bcd db 0, 0 ;цифровой индикатор (показывает количество оставшихся пустых клеток)
terminal db 0 ;вывод символов
terminal_art db 0 ;вывод графики
in_out db 0b00110000 ;ввод-вывод (подключаем цветной дисплей для заставки)
bank db 0 ;банк
display_r db ;заставка
0b00000000, 0b00001100,
0b00000000, 0b00000010,
0b00000000, 0b00000100,
0b00000000, 0b00000010,
0b00000001, 0b00001100,
0b00001001, 0b00100000,
0b00000011, 0b10000000,
0b00000101, 0b11000000,
0b00011111, 0b11110000,
0b00000111, 0b11000000,
0b00000011, 0b10000100,
0b11001001, 0b00100111,
0b00100001, 0b00000110,
0b01000000, 0b00000000,
0b10000000, 0b00000000,
0b11100000, 0b00000000
display_b db
0b00100000, 0b00000000,
0b01100000, 0b00000000,
0b00100000, 0b00000000,
0b01110000, 0b00000000,
0b00000001, 0b00000000,
0b00001001, 0b00100000,
0b01000011, 0b10000000,
0b11000101, 0b11000000,
0b01011111, 0b11110000,
0b11100111, 0b11000000,
0b00000011, 0b10000000,
0b00001001, 0b00100000,
0b00000001, 0b00000000,
0b00000000, 0b00000100,
0b00000000, 0b00000100,
0b00000000, 0b00001110
;BANK ASK содержит опрос пользователя
;BANK RANDOM содержит генерацию мин
;BANK ASK
ask_start:
  ldi d, terminal ;адрес вывода
ask:
  ldi b, ask_row_size ;размер текста
  ldi c, ask_row_text ;адрес текста
ask_row_loop:
  ld a, c ;читаем символ
  st a, d ;выводим
  inc c ;следующий символ
  dec b ;если символы не закончились, продолжаем
  jnz ask_row_loop
ask_row:
  ld a, in_out ;читаем ввод пользователя
  mov c, a ;копируем символ
  ldi b, "a" ;проверяем, находится ли символ в диапазоне от a до k (включительно)
  sub a, b
  jc ask_row
  ldi b, 10
  sub b, a
  jc ask_row
  st c, d ;если символ в диапазоне, выводим его
  st a, row ;и сохраняем колонку
ldi b, ask_column_size ;то же самое, но для строки
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
  jc ask_column
  ldi b, 3
  sub b, a
  jc ask_column
  st c, d
  st a, column
;вычисляем курсор
ld b, row
mov c, a ;умножение на 12 (ширина терминала - 12 символов)
add a, c
add a, c
shl a
shl a
add a, b
ldi b, field
add a, b
st a, cursor ;сохраняем курсор
ask_jmp:
  jmp random ;заменяемый адрес перехода
;BANK RANDOM
random:
  ldi b, 1 ;чтобы мина изначально не попала на ввод пользователя, временно сохраняем туда мину
  st b, a
  ldi d, 10 ;генерируем 10 мин
  random_column: ;генерируем строку
    rnd a
    ldi b, 3
    and a, b
  random_row: ;генерируем колонку
    rnd b
    ldi c, 11
    mod_b_c:
      sub b, c
      jnc mod_b_c
    add b, c
  mov c, a ;вычисляем положение на поле
  add a, c
  add a, c
  shl a
  shl a
  add a, b
  ldi b, field
  add a, b
  ld b, a ;если попали на мину, генерируем заново
  dec b
  jz random_column
  st b, a ;если нет, сохраняем мину на поле
  dec d ;если мины ещё остались, продолжаем
  jnz random_column
ld a, cursor ;изначально ввод пользователя должен быть на свободную клетку
ldi b, 2
st b, a
ldi b, 34 ;выводим количество оставшихся пустых клеток на цифровой индикатор
st b, bcd
ldi b, check_mine_jmp ;меняем адрес перехода
st b, ask_jmp + 1
ldi b, wait ;сохраняем адрес перехода после вывода поля
st b, adress_end
check_mine_jmp:
  ldi c, 2 ;переход на проверку столкновения с миной
  ldi d, check_mine
  jmp set_bank
void2 db 0, 0, 0
;BANK CENTER - содержит обработку центральных клеток на поле
check_mine:
  ld b, a ;читаем клетку, которую указал пользователь
  dec b ;если попали на мину, переходим к концу игры
  jnz check_repeat
  ldi c, 4
  ldi d, game_over
  jmp set_bank
check_repeat:
  dec b ;проверяем, не указал ли пользователь уже открытую клетку
  jz check_side
  ldi c, 5 ;если да, выводим поле без изменений
  ldi d, draw_field
  jmp set_bank
check_side:
  mov d, a ;копируем курсор в d
  ldi c, 12 ;число, которое позволяет сдвигать курсор вверх и вниз
  ld a, column ;читаем строку
  test a ;если строка верхняя, переходим на подсчёт верхней горизонтальной стороны
  jz horizontal_side_up_jmp
  ldi b, 3
  xor a, b ;если строка нижняя, переходим на подсчёт нижней горизонтальной стороны
  jz horizontal_side_down_jmp
  ld a, row ;читаем колонку
  test a ;если колонка левая, переходим на подсчёт левой вертикальной стороны
  jz vertical_side_left_jmp
  ldi b, 10
  xor a, b ;если колонка правая, переходим на подсчёт правой вертикальной стороны
  jz vertical_side_right_jmp
;пользователь указал центральные координаты, подсчитываем все клетки вокруг
next0:
  clr a ;счётчик мин
  sub d, c ;смещаем курсор вверх (верхняя клетка)
  ld b, d ;читаем
  dec b ;если попали на мину, увеличиваем счётчик
  jnz next1
  inc a
;повторяем то же самое для других окружающих клеток
next1:
  inc d ;смещаем курсор вправо (верхняя правая клетка)
  ld b, d
  dec b
  jnz next2
  inc a
next2:
  add d, c ;смещаем курсор вниз (правая клетка)
  ld b, d
  dec b
  jnz next3
  inc a
next3:
  add d, c ;смещаем курсор вниз (нижняя правая клетка)
  ld b, d
  dec b
  jnz next4
  inc a
next4:
  dec d ;смещаем курсор влево (нижняя клетка)
  ld b, d
  dec b
  jnz next5
  inc a
next5:
  dec d ;смещаем курсор влево (нижняя левая клетка)
  ld b, d
  dec b
  jnz next6
  inc a
next6:
  sub d, c ;смещаем курсор вверх (левая клетка)
  ld b, d
  dec b
  jnz next7
  inc a
next7:
  sub d, c ;смещаем курсор вверх (верхняя левая клетка)
  ld b, d
  dec b
  jnz end_counter
  inc a
end_counter:
  ldi c, 5 ;переход на вывод поля
  ldi d, show_counter
  jmp set_bank
horizontal_side_up_jmp:
  ldi a, 3 ;переход на подсчёт для верхней клетки
  ldi b, horizontal_side_up
  jmp set_bank2
horizontal_side_down_jmp:
  ldi a, 3 ;переход на подсчёт для нижней клетки
  ldi b, horizontal_side_down
  jmp set_bank2
vertical_side_left_jmp:
  ldi a, 4 ;переход на подсчёт для левой клетки
  ldi b, vertical_side_left
  jmp set_bank2
vertical_side_right_jmp:
  ldi a, 4 ;переход на подсчёт для правой клетки
  ldi b, vertical_side_right
  jmp set_bank2
void3 db 0, 0, 0, 0, 0, 0, 0
;BANK HORIZONTAL - содержит обработку горизонтальных сторон поля
;BANK CORNER UP - содержит обработку верхних углов поля
;BANK HORIZONTAL
;подсчёт для верхней клетки
horizontal_side_up:
  ld a, row ;читаем колонку
  test a ;если колонка левая, переходим на подсчёт для верхней левой клетки
  jz corner_up_left
  ldi b, 10
  xor a, b ;если колонка правая, переходим на подсчёт для верхней правой клетки
  jz corner_up_right
  ldi a, ADD_D_C ;заменяем операцию на движение курсора вниз
  st a, next11
  ldi a, SUB_D_C ;заменяем операцию на движение курсора вверх
  st a, next14
  jmp next10 ;переход к подсчёту
horizontal_side_down:
  ld a, row ;читаем колонку
  test a ;если колонка левая, переходим на подсчёт для нижней левой клетки
  jz corner_down_left_jmp
  ldi b, 10
  xor a, b ;если колонка правая, переходим на подсчёт для нижней правой клетки
  jz corner_down_right_jmp
  ldi a, SUB_D_C ;заменяем операцию на движение курсора вверх
  st a, next11
  ldi a, ADD_D_C ;заменяем операцию на движение курсора вниз
  st a, next14
next10:
  clr a ;счётчик мин
  dec d ;сдвигаем курсор влево (левая клетка)
  ld b, d ;читаем
  dec b ;если попали на мину, увеличиваем счётчик
  jnz next11
  inc a
next11:
  add d, c ;для верхней клетки смещаем курсор вниз (нижняя левая клетка)
  ;sub d, c для нижней клетки смещаем курсор вверх (верхняя левая клетка)
  ld b, d
  dec b
  jnz next12
  inc a
next12:
  inc d ;смещаем курсор вправо
  ;(для верхней клетки нижняя клетка)
  ;(для нижней клетки верхняя клетка)
  ld b, d
  dec b
  jnz next13
  inc a
next13:
  inc d ;смещаем курсор вправо
  ;(для верхней клетки - нижняя правая клетка)
  ;(для нижней клетки - верхняя правая клетка)
  ld b, d
  dec b
  jnz next14
  inc a
next14:
  sub d, c ;для верхней клетки смещаем курсор вверх (правая клетка)
  ;add d, c для нижней клетки смещаем курсор вниз (правая клетка)
  ld b, d
  dec b
  jnz end_counter2
  inc a
  jmp end_counter2 ;переход к выводу поля
;BANK CORNER UP
;подсчёт для верхней левой клетки
corner_up_left:
  ldi a, INC_D ;заменяем операцию на движение курсора вправо
  st a, next31
  jmp next30 ;переход к подсчёту
;подсчёт для верхней правой клетки
corner_up_right:
  ldi a, DEC_D ;заменяем операцию на движение курсора влево
  st a, next31
next30:
  clr a ;счётчик мин
  add d, c ;смещаем курсор вниз (нижняя клетка)
  ld b, d ;читаем
  dec b ;если попали на мину, увеличиваем счётчик
  jnz next31
  inc a
next31:
  inc d ;для верхней левой клетки смещаем курсор вправо (нижняя правая клетка)
  ;dec d для верхней правой клетки смещаем курсор влево (нижняя левая клетка)
  ld b, d
  dec b
  jnz next32
  inc a
next32:
  sub d, c ;смещаем курсор вверх
  ;(для верхней левой клетки - правая клетка)
  ;(для верхней правой клетки - левая клетка)
  ld b, d
  dec b
  jnz end_counter2
  inc a
  jmp end_counter2
end_counter2: ;переход к отрисовке поля
  ldi c, 5
  ldi d, show_counter
  jmp set_bank
corner_down_left_jmp: ;переход на подсчёт для нижней левой клетки
  ldi a, 4
  ldi b, corner_down_left
  jmp set_bank2
corner_down_right_jmp: ;переход на подсчёт для нижней правой клетки
  ldi a, 4
  ldi b, corner_down_right
  jmp set_bank2
void4 db 0, 0, 0, 0, 0, 0, 0, 0
;BANK VERTICAL - содержит обработку вертикальных сторон поля
;BANK CORNER DOWN - содержит обработку нижних углов поля
;BANK GAME OVER - меняет поле на поражение
;BANK VERTICAL
;подсчёт для левой клетки
vertical_side_left:
  ldi a, INC_D ;заменяем операцию на движение курсора вправо
  st a, next21
  ldi a, DEC_D ;заменяем операцию на движение курсора влево
  st a, next24
  jmp next20 ;переход к подсчёту
;подсчёт для правой клетки
vertical_side_right:
  ldi a, DEC_D ;заменяем операцию на движение курсора влево
  st a, next21
  ldi a, INC_D ;заменяем операцию на движение курсора вправо
  st a, next24
next20:
  clr a ;счётчик мин
  sub d, c ;смещаем курсор вверх (верхняя клетка)
  ld b, d ;читаем
  dec b ;если попали на мину, увеличиваем счётчик
  jnz next21
  inc a
next21:
  inc d ;для левой клетки смещаем курсор вправо (верхняя правая клетка)
  ;dec d для правой клетки смещаем курсор влево (верхняя левая клетка)
  ld b, d
  dec b
  jnz next22
  inc a
next22:
  add d, c ;смещаем курсор вниз
  ;(для левой клетки - правая клетка)
  ;(для правой клетки - левая клетка)
  ld b, d
  dec b
  jnz next23
  inc a
next23:
  add d, c ;смещаем курсор вниз
  ;(для левой клетки - нижняя правая клетка)
  ;(для правой клетки - нижняя левая клетка)
  ld b, d
  dec b
  jnz next24
  inc a
next24:
  dec d ;для левой клетки смещаем курсор влево (нижняя клетка)
  ;inc d для правой клетки смещаем курсор вправо (нижняя клетка)
  ld b, d
  dec b
  jnz end_counter3
  inc a
  jmp end_counter3 ;переход к отрисовке поля
;BANK CORNER DOWN
;подсчёт для нижней левой клетки
corner_down_left:
  ldi a, INC_D ;заменяем операцию на смещение курсора вправо
  st a, next41
  jmp next40 ;переход к подсчёту
;подсчёт для нижней правой клетки
corner_down_right:
  ldi a, DEC_D ;заменяем операцию на смещение курсора влево
  st a, next41
next40:
  clr a ;счётчик мин
  sub d, c ;смещаем курсор вверх (верхняя клетка)
  ld b, d ;читаем
  dec b ;если попали на мину, увеличиваем счётчик
  jnz next41
  inc a
next41:
  inc d ;для нижней левой клетки смещаем курсор вправо (верхняя правая клетка)
  ;dec d для нижней правой клетки смещаем курсор влево (верхняя левая клетка)
  ld b, d
  dec b
  jnz next42
  inc a
next42:
  add d, c ;смещаем курсор вниз
  ;(для нижней левой клетки - правая клетка)
  ;(для нижней правой клетки - левая клетка)
  ld b, d
  dec b
  jnz end_counter3
  inc a
end_counter3: ;переход к отрисовке поля
  ldi c, 5
  ldi d, show_counter
  jmp set_bank
;BANK GAME OVER
game_over: ;поражение
  ldi a, end ;меняем адрес перехода после отрисовки поля
  st a, adress_end
  ldi a, 6 ;меняем смайлик игры на смайлик поражения
  st a, emoji
  ldi a, " " ;убираем enter
  st a, enter
  ldi b, mine_loop ;адрес цикла
  ldi c, field ;адрес поля
  ldi d, mine ;символ мины
  mine_loop: ;меняем все мины на их символы
    ld a, c
    dec a
    jnz end_mine_loop
    st d, c
    end_mine_loop:
      inc c
      jns b
  ;переход к отрисовке поля
  ldi c, 5
  ldi d, draw_field
  jmp set_bank
void5 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
;BANK WIN - меняет поле на победу
;BANK DRAW - выводит поле в терминал
;BANK WIN
show_counter:
  test a ;если на счётчике ноль, то вместо нуля показываем пустую клетку
  jz zero
  ldi b, "0" ;превращаем счётчик в символ
  add a, b
  jmp check_win ;переходим к проверке на победу
zero:
  ldi a, " " ;вместо нуля используем пробел (пустую клетку)
check_win:
  ld b, cursor ;сохраняем
  st a, b
  ld a, bcd ;читаем количество оставшихся пустых клеток
  dec a ;уменьшаем
  st a, bcd ;сохраняем
  jnz draw_field ;если пустых клеток не осталось, выполняем действия для победы
  ldi a, end ;меняем адрес перехода после отрисовки поля
  st a, adress_end
  ldi a, 5 ;меняем смайлик игры на смайлик победы
  st a, emoji
  ldi a, " " ;убираем enter
  st a, enter
;BANK DRAW
draw_field:
  ldi c, field ;адрес поля
  ldi d, terminal ;адрес вывода символов
draw_field_loop: ;цикл отрисовки поля
  ld a, c ;читаем символ
  dec a ;если мина, то сразу переходим к рисованию клетки
  jz add_address_symbols
  inc a ;иначе обратно прибавляем 1
  check_symbol:
    ldi b, 6 ;если символ меньше 6, значит он кастомный
    sub b, a
    jnc symbol
    st a, d ;иначе выводим существующий
    jmp draw_field_loop_end ;переходим к концу цикла
  symbol:
    dec a ;убавляем 2
    dec a
    mov b, a ;умножаем на 6
    shl a
    add a, b
    shl a
  add_address_symbols:
    ldi b, symbols ;прибавляем адрес символов
    add a, b
    st c, save ;сохраняем регистр c
    ldi c, 6 ;счётчик
    inc d ;0x3d для произвольной графики
    draw_symbol_loop:
      ld b, a ;читаем фрагмент
      st b, d ;накапливаем
      inc a ;следующий фрагмент
      dec c ;если фрагменты ещё не закончились, продолжаем накапливать
      jnz draw_symbol_loop
    ld c, save ;читаем c обратно
    dec d ;возвращаем 0x3c
    draw_field_loop_end:
      inc c ;следующий символ
      jns draw_field_loop ;если символы ещё не закончились, повторяем
ld a, adress_end ;читаем адрес перехода
jmp a ;переход по адресу
wait:
  ld a, in_out ;ждём реакции пользователя для опроса
  test a
  jz wait
  ldi a, "\f" ;очищаем поле
  st a, d
  inc a ;\r
  st a, d ;возвращаем курсор на место
  clr a ;переходим к опросу (регистр d уже содержит адрес вывода текста)
  ldi b, ask
  jmp set_bank2
end:
  hlt ;конец
symbols:
cell db ;символ клетки
0b11111110,
0b10000010,
0b10000010,
0b10000010,
0b11111110,
0b00000000
enter_draw db ;символ enter
0b00000000,
0b00100000,
0b01110000,
0b00100000,
0b00111110,
0b00000000
play db ;смайлик игры
0b00000000,
0b00100100,
0b01000000,
0b01000000,
0b00100100,
0b00000000
win db ;смайлик победы
0b00000110,
0b00100110,
0b01000010,
0b01000010,
0b00100110,
0b00000110
lose db ;смайлик поражения
0b00000000,
0b01000100,
0b00100000,
0b00100000,
0b01000100,
0b00000000


;дискета:
;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
