ADD_D_C equ 0x6b ;код команды add d, c (сместить курсор вниз)
SUB_D_C equ 0x7b ;код команды sub d, c (сместить курсор вверх)
INC_D equ 0x6F ;код команды inc d (сместить курсор вправо)
DEC_D equ 0x7F ;код команды dec d (сместить курсор влево)
emoji equ field + 11 ;адрес смайлика на поле
enter equ field + 35 ;адрес символа enter на поле
mine equ 0xa4 ;символ, обозначающий мину
jmp ask_start ;переход к опросу пользователя
cell db ;клетка
0b11111111,
0b10000001,
0b10000001,
0b10000001,
0b10000001,
0b11111111
enter db ;символ enter
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
ask_row_text db "\nrow (a-k): " ;текст для опроса колонки
ask_row_size equ $ - ask_row_text
ask_column_text db "column\n(1-4): " ;текст для опроса строки
ask_column_size equ $ - ask_column_text
bcd db 0, 0 ;цифровой индикатор (показывает, сколько осталось открыть безопасных клеток)
terminal db 0 ;вывод символов
terminal_art db 0 ;вывод графики
in_out db 0b00000101 ;ввод-вывод (подключаем цифровой индикатор и терминал)
bank db 0 ;банк
set_bank: ;переход к нужной части кода через регистры c и d
  st c, bank
  jmp d
set_bank2: ;переход к нужной части кода через регистры a и b
  st a, bank
  jmp b
cursor db 0 ;адрес на поле, куда указал пользователь
row db 0 ;колонка, которую указал пользователь
column db 0 ;строка, которую указал пользователь
save db 0 ;сохранение важных значений
adress_end db wait ;адрес перехода после вывода поля
void db 0, 0, 0, 0, 0, 0
;поле
;1 - мина
;2 - пустая клетка
;3 - символ enter
;4 - символ смайлика, когда играет игрок
;5 - символ смайлика, когда игрок победил
;6 - символ смайлика, когда игрок проиграл
;остальное - символы для вывода в терминал (цифры, пробел и мина)
field db 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4,
2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, " ",
2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3,
2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
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
  jnc ask_row
  ldi b, 10
  sub b, a
  jnc ask_row
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
  jnc ask_column
  ldi b, 3
  sub b, a
  jnc ask_column
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
      jc mod_b_c
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
check_mine_jmp:
  ldi c, 2 ;переход на проверку столкновения с миной
  ldi d, check_mine
  jmp set_bank
void2 db 0, 0, 0, 0, 0, 0, 0
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
  clr c ;если да, спрашиваем клетку снова
  ldi d, ask_start
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
void3 db 0, 0, 0, 0, 0, 0, 0, 0
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
void db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
show_counter:
  ldi b, 0x30 ;превращаем счётчик в символ
  add a, b
  ld b, cursor ;сохраняем
  st a, b
check_win:
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
draw_field:
  ldi c, field ;адрес поля
  ldi d, terminal ;адрес вывода символов
  ldi a, "\n" ;рисуем поле с новой строки
  st a, d
draw_field_loop: ;цикл отрисовки поля
  ld a, c ;читаем фрагмент поля
  dec a ;вычитаем 1 для проверки на мину
  jnz check_draw ;если не попали на мину, переходим к проверке на графику
  inc a ;обратно прибавляем 1
  jmp draw ;переходим к отрисовке собственного символа
  check_draw:
    ldi b, 7 ;если фрагмент < 7, значит это собственный символ
    sub a, b
    add a, b
    jc draw
    ;если фрагмент > 7, значит это символ в терминале
    inc a ;обратно прибавляем 1
    st a, d ;выводим символ в терминал
    jmp check_end ;переход к проверке на конец цикла
  draw:
    st c, save ;сохраняем адрес фрагмента
    ldi c, cell ;самый первый символ
    dec a ;убавляем ещё 1
    mov b, a ;и умножаем на 6
    add a, b
    add a, b
    shl a
    add c, a ;получаем адрес символа
    inc d ;адрес 0x3d для произвольной графики
    ldi b, 6 ;размер символа
  draw_loop:
    ld a, c ;читаем часть символа
    st a, d ;сохраняем
    inc c
    dec b ;если символ ещё не выведен, продолжаем сохранять
    jnz draw_loop
  dec d ;обратно возвращаемся на 0x3c для вывода символов
  ld c, save ;восстанавливаем адрес фрагмента
  check_end:
    inc c ;если фрагменты ещё остались, повторяем заново
    jns draw_field_loop
ld a, adress_end ;читаем адрес перехода
jmp a ;переход по адресу
wait:
  ld a, in_out ;ждём реакции пользователя для опроса
  test a
  jz wait
  ldi a, "\f" ;убираем поле
  st a, d
  clr a ;переходим к опросу (регистр d уже содержит адрес вывода текста)
  ldi b, ask
  jmp set_bank2
end:
  hlt ;конец

дискета:
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AQgJ0gGzAdMBVAHVAZYBNwFXAXcBlwEAAAsADgkLBAAUACQANABEAFQAZAB0AIQAlACkALQDBgUGACYARgBmAIYApgIMC8QC1ALkAPYABwAnAEcAZwCHAKcAqQLLAQoz5gAIAygDSANoA4gDuAHIAOgBCQIpAkkCaQKJAukDCgIqAkoCagKKAgsCKwJLAmsCiwLbAwwCLAJMAmwCjAK8AdwDDQItAk0CbQKNAt0DDgIuAk4CbgKOAs4B3gMPAi8CTwJvAo8C3wMTBBYBNgFWAXYBlgEQBBcBNwFXAXcBlwEHERgBOAFYAXgBOQVZARoBOgV6BRsFOwUcATwBPQF9AT4BHwVfBQEY1gCoA9gCGQF5AZoBqgNbAXsBmwGrA1wBfAGcAawDHQFdAa0CHgFeAZ4BrgN/AZ8BrwMIBJkBWgGdAX4BPwENAZgGyQYOA/QBtgHXBdkDEQS3AscC5wLMAc0BCwP3ArkB2gK9AwQJugHqAbsB6wHsAe0BvgHuAb8B7wESAcYAygEBAAsABwpcAAIgAkACYAKAArAB0AMBAiECQQJhAoEC0QMCAiICQgJiAoICAwIjAkMCYwKDAtMDBAIkAkQCZAKEArQB1AMFAiUCRQJlAoUC1QMGAiYCRgJmAoYC1gMHAicCRwJnAocC1wMIAigCSAJoAogCuAHYAwkCKQJJAmkCiQLZAwoCKgJKAmoCigILAisCSwJrAosCDAIsAkwCbAKMArwBDQItAk0CbQKNAg4CLgJOAm4CjgIPAi8CTwJvAo8CCAwQAXABMgEVARYBNgF2ATcBOQE6AXoBOwF7AQceMAFQBZABEQWRAXIBEwVTAXMBFAFUAXQBNQVVBVYFFwUYATgFWAEZARoBWgEbARwBPAEdBT0FHgE/AV8BfwUBP6ADMQFRAXEBoQISAVIBkgGiAzMBkwGjA8MBNAGUAaQDxAF1AZUBpQLFAZYBpgNXAXcBlwGnA8cDeAGYAagDyANZAXkBmQGpAskDmgGqA8oDWwGbAasDywNcAXwBnAGsA8wDXQF9AZ0BrQLNAz4BXgF+AZ4BrgPOAx8BnwGvA88DCwOxA7UDuQO9AwQe4AHhAbIBwgHiAbMB4wHkAeUBtgHmAbcB5wHoAekBugHaA+oBuwHbA+sB3APsAd0D7QG+Ad4D7gG/Ad8D7wENAcAB0gMRAMYCAgALAAgKLgACIAJAAmACgAKwAQECIQJBAmECgQICAiICQgJiAoICAwIjAkMCYwKDAgQCJAJEAmQChAK0AQUCJQJFAmUChQIGAiYCRgJmAoYCBwInAkcCZwKHAggCKAJIAmgCiAIJD/UD5gPXA8gDuQMKABoAKgA6AEoAWgBqAHoAigCaAKoAASIQAZABoAPAAxEBkQGhAsEDkgGiA8ID4gATATMBkwGjA+MDVAGUAaQD5AMVAVUBlQGlAlYBdgGWAaYDdwGXAacDGAGYAagDBxMwAVABcAUxAVEFcQESBTIFcgFzARQBNAF0ATUFdQU2BTcFOAFYBXgFCARSAVMBFgEXAVcBCwWxA9QAtQPVAsYCtwIECdAD4AHhALIBswHDA9MBxAPFA7YBEQDRAwYA0gMAAAwABQ4ABQQKBiADIgMkAwYCFgAmAzYADAEHAQkDCQYIAAoACwEMAw0DDgMPAwEARgAYFGQBdAGEAVUBZQF1AYUBlQFWAGYAdgCGAJYAVwNnA3cDhwOXA2gDeAOIAwEADAAACQ8AAwEDAgMDAwQDBQMGAwcDCAMJAwoDCwMMAw0DDgMPAwIADAAACQQAAwEDAgMDAwQD
