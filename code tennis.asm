RIGHT equ 0x13 ;код клавиши "вправо"
LEFT equ 0x11 ;код клавиши "влево"
jmp start ;переходим к старту
text db "\n\nSINNET\b\t" ;TENNIS наоборот
start:
  ldi a, 0b00010101 ;подключаем монохромный дисплей, цифровой индикатор и терминал
  st a, 0x3e
  ldi a, "\n" ;восстанавливаем последний символ
  st a, 0x01
  ldi d, text_loop ;адрес цикла
  ldi c, start - 1 ;адрес текста
  ldi b, terminal ;адрес вывода в терминал
text_loop:
  ld a, c ;читаем символ
  st a, b ;выводим в терминал
  dec c ;если символы не закончились, продолжаем вывод
  jnz d
ldi a, 32 ;стираем заставку
ldi d, display_r
ldi b, clear_loop
;регистр c содержит 0
clear_loop:
  st c, d
  inc d
  dec a
  jnz b
ldi c, 2 ;переходим к генерации мяча
ldi d, random_ball
set_bank:
  st c, bank
  jmp d
void db 0, 0, 0, 0, 0, 0, 0
speedY db 0 ;направление по Y
speedX db 0 ;направление по X
ball_pos db 0 ;позиция мяча в байте
ball_adress db 0 ;адрес мяча на дисплее
score db 0xff, 0xff ;счёт (изначально -1, чтобы при старте было 0)
terminal db 0 ;вывод символов
terminal_art db 0 ;вывод графики (не используется)
in_out db 0b00110000 ;ввод-вывод (подключаем цветной дисплей для вывода заставки)
bank db 0 ;банк
;заставка
display_r db
0b00000000, 0b00000000,
0b00000000, 0b01110000,
0b00000000, 0b11111100,
0b00000001, 0b11111110,
0b00000011, 0b11111111,
0b00000111, 0b11111111,
0b00000111, 0b11111111,
0b00000111, 0b11111110,
0b00000011, 0b11111110,
0b00000001, 0b11111100,
0b00000100, 0b11111000,
0b00000010, 0b01110000,
0b00000110, 0b00000000,
0b00001100, 0b00000000,
0b00011000, 0b00000000,
0b00110000, 0b00000000
display_b db
0b00110000, 0b00000000,
0b01011000, 0b01110000,
0b01111000, 0b00001100,
0b00110000, 0b00000010,
0b00000000, 0b00000001,
0b00000000, 0b00000001,
0b00000000, 0b00000001,
0b00000000, 0b00000010,
0b00000100, 0b00000010,
0b00000110, 0b00000100,
0b00000111, 0b00001000,
0b00001111, 0b10010000,
0b00011110, 0b00000000,
0b00111100, 0b00000000,
0b01111000, 0b00000000,
0b00110000, 0b00000000
add_score:
  ld a, score ;читаем счёт
  inc a ;увеличиваем
  st a, score ;сохраняем
  jnz key_read ;если не вышли за пределы байта, переходим к чтению клавиши
  ld a, score + 1 ;если вышли, читаем счёт x256
  inc a ;увеличиваем
  st a, score + 1 ;сохраняем
key_read:
  ld b, in_out ;читаем клавишу
  ldi a, LEFT ;влево
  xor a, b
  jz left
  ldi a, RIGHT ;вправо
  xor a, b
  jnz ball_move ;если клавиша не нажата, переходим к движению мяча
right:
  ldi b, 0x59 ;правый байт ракетки
  ld a, b ;читаем
  shr a ;сдвигаем
  jc ball_move ;если упёрлись в стену, переходим к движению мяча
  dec b ;левый байт
  ld a, b ;читаем
  rcr a ;сдвигаем
  st a, b ;сохраняем
  inc b ;правый байт
  ld a, b ;читаем
  rcr a ;сдвигаем
  st a, b ;сохраняем
  jmp ball_move ;переходим к движению мяча
left:
  ;то же самое, что и для правой, но наоборот
  ldi b, 0x58
  ld a, b
  shl a
  jc ball_move
  inc b
  ld a, b
  rcl a
  st a, b
  dec b
  ld a, b
  rcl a
  st a, b
ball_move:
  ld a, ball_adress ;читаем адрес мяча
  clr c ;стираем мяч
  st c, a
  ld b, speedY ;читаем движение по Y
  add a, b ;добавляем
  test b ;если двигаемся вниз, переходим к движению мяча по горизонтали
  jns ball_jmp
  ldi c, 0x40 ;если двигаемся вверх, проверяем столкновение с верхней стороной
  xor c, a
  shr c
  jnz ball_jmp ;если столкновение есть, меняем направление мяча вниз
  ldi b, 0x02
  st b, speedY
ball_jmp:
  ld b, ball_pos ;читаем позицию мяча заранее
  ldi c, 2
  ld d, speedX ;читаем направление мяча по X
  jmp set_bank
check_game_over:
  st a, ball_adress ;сохраняем адрес мяча
  st b, ball_pos ;сохраняем позицию мяча
  st b, a ;выводим мяч на экран
  ld c, speedY ;читаем направление мяча по Y
  test c ;если двигаемся вверх, переходим к чтению клавиши
  js key_read
  add a, c ;если вниз, проверяем столкновение с ракеткой
  ldi c, 0x58
  xor c, a
  shr c
  jnz key_read ;если мяч не у ракетки, переходим к чтению клавиши
  ld c, a ;если мяч у ракетки, но он не отбит, переходим к концу игры
  and c, b
  jz game_over
  ;если мяч отбит, меняем направление мяча по вертикали и переходим к увеличению счёта
  ldi c, 0xfe ; -2
  st c, speedY
  jmp add_score
;переходим к выводу на дисплей Game Over
game_over:
  ldi c, 2
  ldi d, game_over_start
  jmp set_bank
;регистр a уже содержит случайное число
random_dir_y:
  shr a
  jc up
down:
  ldi b, 0xfe ;направление вверх
  jmp save_y
up:
  ldi b, 2 ;направление вниз
save_y:
  st b, speedY ;сохраняем
  jmp add_score ;переходим к выводу счёта
random_ball:
  rnd a ;генерируем случайное число
  ldi b, 63 ;мяч должен появиться в верхней части экрана
  and a, b
  ldi b, 7 ;кол-во сдвигов, для получение случайной позиции
  and b, a
  ldi c, 0b10000000 ;определяем случайную позицию
  random_loop:
    shr c
    dec b
    jns random_loop
  rcl c
  ;определяем случайный адрес
  shr a
  shr a
  shr a
  ldi b, 0x40
  add a, b
  ;сдвигаем мяч на один ряд вниз
  inc a
  inc a
  st a, ball_adress ;сохраняем
  st c, ball_pos
  st c, a ;выводим мяч на дисплей
  ldi a, 0b00000111 ;выводим ракетку на дисплей
  st a, 0x58
  rnd a ;определяем случайное напрвление мяча по X
  shr a
  jc dir_left
dir_right:
  ldi b, ball_right
  jmp save_x
dir_left:
  ldi b, ball_left
save_x:
  st b, speedX ;сохраняем
  clr c ;переходим к случайному направлению мяча по Y
  ldi d, random_dir_y
  jmp set_bank
ball_left:
  ldi d, check_game_over_jmp
  shl b ;сдвигаем мяч влево
  jnc d ;если нет перехода между байтами, переходим к проверке на конец игры
  shr a ;если адрес чётный, делаем отскок мяча от стенки
  jnc changeX_left
  ldi b, 0b00000001 ;если адрес нечётный, делаем переход между байтами
  rcl a
  dec a
  jmp d
  changeX_left:
    ;отскок мяча от стенки
    rcl a
    ldi c, ball_right
    st c, speedX
    ldi b, 0b01000000
    jmp d
ball_right:
  ;то же самое, что и для левой, но наоборот
  ldi d, check_game_over_jmp
  shr b
  jnc d
  shr a
  jc changeX_right
  ldi b, 0b10000000;
  rcl a
  inc a
  jmp d
  changeX_right:
    rcl a
    ldi c, ball_left
    st c, speedX
    ldi b, 0b00000010
check_game_over_jmp:
  clr c ;переходим к проверке на поражение
  ldi d, check_game_over
  jmp set_bank
game_over_start:
  ldi b, game_over_loop
  ldi c, img ;адрес изображения
  ldi d, 0x44 ;адрес вывода изображения
game_over_loop:
  ld a, c ;читаем фрагмент изображения
  st a, d ;сохраняем на дисплей
  inc d
  inc c
  jnz b
hlt ;конец
img db ;изображение
0b01100000, 0b00000000,
0b10001001, 0b10100010,
0b10100101, 0b01010101,
0b10101101, 0b01010110,
0b01101101, 0b01010011,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b01100000, 0b00000000,
0b10010101, 0b00100111,
0b10010101, 0b01010100,
0b10010101, 0b01100100,
0b01100010, 0b00110100



дискета:
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
