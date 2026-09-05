out_display equ 0x80 ;дисплей
out_indicator equ 0x10 ;индикатор
indicator equ 0x40 ;вывод на индикатор
;стираем заставку
ldi b, clear_loop ;адрес цикла для его ускорения
ldi c, 32 ;кол-во итераций
ldi d, display ;дисплей
;регситр a пустой
clear_loop:
  st a, d ;очищаем байт
  inc d ;следующий байт
  dec c ;если байты ещё остались продолжаем очистку
  jnz b
loop:
  ld a, x ;читаем координаты
  ld b, y
xy_to_pos: ;преобразовываем координаты в позицию и адрес на дисплее
  ldi c, 7
  and c, a
  shr a
  shr a
  shr a
  shl b
  add b, a
  ldi a, display
  add b, a ;в регситре b адрес
  shl a
  pos_loop:
    shr a
    dec c
    jns pos_loop
  rcl a ;в регистре a позиция
ld d, rotate ;заранее читаем направление
ld c, b ;читаем байт дисплея
xor c, a ;меняем цвет клетки на противоположный
st c, b ;выводим
and c, a
jz black
white: ;если клетка была белой, поворочиваем направо
  inc d ;прибавление 1 - поврот направо
  jmp end_color
black: ;если клетка была чёрной, поворочиваем налево
  dec d ;убавление 1 - поврот налево
end_color:
  ldi a, 3 ;преобрзуем напрвление в число от 0 до 3
  and d, a
  st d, rotate ;сохраняем
  jmp read_change_xy ;переходим к изменению позиции
rotates db
0, 1, ;направление вниз - изменяем x на 0, y на 1
0 - 1, 0, ;направление влево - изменяем x на -1, y на 0
0, 0 - 1, ;направление вверх - изменяем x на 0, y на -1
1, 0 ;направление вправо - изменяем x на 1, y на 0
rotate db 1 ;направление (изначально влево)
step_count db 0 ;кол-во шагов, которое прошёл муравей
x db 8 ;координаты муравья (изначально в центре)
y db 8
in db 0 ;ввод (не используется)
out db out_display ;вывод (подключаем дисплей)
display db          0b00000000, 0b00000000, ;заставка
                    0b00000000, 0b00000000,
                    0b10010000, 0b00000000,
                    0b01001000, 0b00000000,
                    0b01001000, 0b00000000,
                    0b01111000, 0b00000000,
                    0b11111011, 0b00011000,
                    0b11011111, 0b10111100,
                    0b01110111, 0b11111110,
                    0b00000111, 0b10111111,
                    0b00001001, 0b00001000,
                    0b00010010, 0b00000100,
                    0b00100100, 0b00000010,
                    0b00000000, 0b00000000,
                    0b00000000, 0b00000000,
                    0b00000000, 0b00000000
read_change_xy: ;изменяем положение муравья
  shl d ;уиножаем направление на 2
  ldi a, rotates ;адрес направлений
  add a, d ;адрес текущего направления
  ld b, a ;читаем движение по x
  inc a ;прибавляем 1
  ld c, a ;читаем движение по y
  ld a, x ;читаем координату x
  add b, a ;изменяем по направлению
  ld a, y ;читаем координату y
  add c, a ;изменяем по направлению
  ldi a, 15 ;преобразуем новые координаты в значение от 0 до 15 (делаем зацикленный экран)
  and b, a
  and c, a
  st b, x ;сохраняем новые координаты
  st c, y
output_step: ;выводим кол-во шагов на цифровой индикатор
  ld b, display ;сохраняем байт дисплея
  ldi a, out_indicator ;подключаем цифровой индикатор
  st a, out
  ld a, step_count ;читаем кол-во шагов
  inc a ;увеличиваем
  st a, step_count ;сохраняем
  st a, indicator ;выводим
  ldi a, out_display ;подключаем дисплей
  st a, out
  st b, display ;восстанавливаем байт дисплея
  jmp loop ;повторяем итерацию


;дискета:
;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
