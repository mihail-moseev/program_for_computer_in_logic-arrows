ldi a, 100 ;изначально у игрока 100 рублей
st a, balance

ask_start:
  ldi a, 9 ;восстанавливаем число проверки
  st a, num2_change
  ldi b, text_ask_loop ;адрес цикла
  ldi c, text_ask + text_size - 1 ;адрес текста
  ldi d, terminal ;адрес вывода текста

text_ask_loop:
  ld a, c ;читаем символ
  st a, d ;выводим
  dec c ;следующий символ
  js b ;если символы ещё остались, продолжаем выводить

num1:
  ld a, in_out ;читаем первую цифру
  mov c, a ;копируем
  ldi b, "\n" ;если введён enter, повторяем предыдущую ставку (изначально 10 рублей)
  xor b, a
  jz repeat
  ldi b, "1" ;проверка
  sub a, b
  jc num1
  inc a
  ldi b, 9
  sub b, a
  jc num1
  st c, d ;выводим цифру
  st c, d1 ;сохраняем
  jmp clr_c_d ;переходим к подготовке регистров

set_bank: ;банкинг
  st c, bank
  jmp d

i db d2 ;счётчик

s1 db 0 ;первый символ в прокруте
s2 db 0 ;второй символ в прокруте
s3 db 0 ;третий символ в прокруте

save db 0 ;сохранение важных значений

d1 db "1" ;первая цифра прошлой ставки
d2 db "0" ;вторая цифра прошлой ставки
d3 db 0 ;третья цифра прошлой ставки
d4 db 0 ;четвёртая цифра прошлой ставки
d5 db 0 ;пятая цифра прошлой ставки
fill db 0 ;остановка программы, если предыдущая ставка состоит из 5 цифр

bid db 10 ;младший байт ставки
bid256 db 0 ;старший байт ставки

balance db 0 ;младший байт баланса
balance256 db 0 ;старший байт баланса

terminal db 0 ;вывод символов
terminal_art db 0 ;вывод графики

in_out db 0b00111101 ;ввод-вывод (подключаем цветной дисплей для заставки,
;знаковый цифровой индикатор и терминал)

bank db 0 ;банк

display_r db ;заставка
0b00000000, 0b00000000,
0b00000000, 0b00000111,
0b00000000, 0b00000110,
0b11011011, 0b01101100,
0b11011011, 0b01101000,
0b00000000, 0b00000000,
0b11110011, 0b11001111,
0b00010000, 0b01000001,
0b00100000, 0b10000010,
0b01000001, 0b00000100,
0b01000001, 0b00000100,
0b00000000, 0b00000000,
0b01000000, 0b10000011,
0b00010100, 0b00010111,
0b01000001, 0b01000010,
0b00001000, 0b00001010
display_b db
0b11000011, 0b00000010,
0b10100010, 0b10000000,
0b10010010, 0b01000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b11110011, 0b11001111,
0b00010000, 0b01000001,
0b00100000, 0b10000010,
0b01000001, 0b00000100,
0b01000001, 0b00000100,
0b00000000, 0b00000000,
0b00001000, 0b00001011,
0b11000001, 0b01000011,
0b00010100, 0b00010110,
0b01000000, 0b10000010

text_ask db "\n:акватС" ;текст наоборот
text_size equ $ - text_ask
clr_c_d: ;подготовка регистров
  mov c, a
  clr d
num2:
  ld a, in_out ;читаем следующую цифру
  st a, save ;сохраняем
  ldi b, "\n" ;если введён enter, то число уже введено
  xor b, a
  jz end_ask
  ldi b, "0" ;проверка
  sub a, b
  jc num2
  num2_change equ $ + 1
  ldi b, 9
  sub b, a
  jc num2

mul:
  ld b, save ;читаем цифру
  st b, terminal ;выводим
  st a, save ;сохраняем обработанную цифру
  ld a, i ;читаем адрес текущей цифры
  st b, a ;сохраняем
  inc a ;следующий адрес
  st a, i ;сохраняем
  mov a, c ;умножаем на 10 текущее число
  mov b, d
  shl c
  rcl d
  shl c
  rcl d
  add c, a
  adc d, b
  shl c
  rcl d
  ld a, save ;прибавляем цифру
  clr b
  add c, a
  adc d, b
  ldi a, 204 ;3276
  ldi b, 12
  sub a, c
  sbb b, d
  jnz check_3276 ;если сейчас число 3276, то перенастраиваем обработку
  test a
  jz change_check_num2
check_3276:
  jnc num2 ;если число меньше 3276, спрашиваем следующую цифру

end_ask:
  ldi a, "Р" ;дополняем ставку символом рубля
  st a, terminal
  ld a, balance ;из баланса вычитаем ставку
  ld b, balance256
  sub a, c
  sbb b, d
  jno save_bid ;если баланс стал ниже -32768, изменяем ставку
  clr a ;на балансе -32768
  ldi b, 0 - 128
  ld c, balance ;читаем баланс
  ld d, balance256
  ;вычитаем из баланса -32768 и получаем новую ставку
  ;sub c, a - ничего не меняет, потому что в a значение 0
  sub d, b ;sbb d, b - пишем sub, потому что после sub c, a флаг C точно сбросится
save_bid:
  st c, bid ;сохраняем ставку
  st d, bid256
  ldi c, 2 ;переходим к сохранению баланса
  ldi d, save_balance
  jmp set_bank

change_check_num2:
  ldi a, 7 ;меняем диапазон с 0...9 на 0...7
  st a, num2_change
  jmp num2 ;читаем 5 цифру

repeat: ;повторяем ставку, если изначально введён enter
  ldi c, d1 ;первая цифра прошлой ставки
  ldi d, terminal ;адрес вывода
repeat_loop:
  ld a, c ;читаем цифру
  test a ;если получили 0, значит все цифры уже выведены
  jz end_repeat_loop
  st a, d ;выводим цифру
  inc c ;следующая цифра
  jmp repeat_loop ;повторяем
end_repeat_loop:
  st c, i ;сохраняем адрес первого 0, чтобы не потерять цифры в ставке при их стирании
  ld c, bid ;читаем ставку
  ld d, bid256
  jmp end_ask ;переходим к её обработке
void1 db 0, 0, 0

save_balance: ;сохраняем и выводим баланс
  st a, balance
  st b, balance256
clear_digit:
  clr a ;стираем неиспользовавшиеся цифры ставки
  ldi b, clear_digit_loop ;адрес цикла
  ld d, i ;адрес цифры, которая не используется
clear_digit_loop:
  ldi c, d5 + 1 ;проверка на последнюю цифру
  xor c, d
  jz spin
  st a, d ;стираем цифру
  inc d ;следующая цифра
  jmp b ;повторяем
spin:
  ld a, in_out ;читаем ввод
  st a, save ;сохраняем
  ldi a, "\n" ;новая строка
  st a, terminal
  ldi a, s1 ;обновляем счётчик
  st a, i
choose_symbol:
  rnd a ;генерируем случайное число
  clr b
  ldi c, 27 ;шанс выпадения семёрки составляет 27/255
  sub a, c
  jc draw_symbol
  inc b
  ldi c, 52 ;шанс выпадения перца составляет 52/255
  sub a, c
  jc draw_symbol
  inc b
  ldi c, 77 ;шанс выпадения вишни составляет 77/255
  sub a, c
  jc draw_symbol
  ;шанс выпадения клубники составляет 99/255
  inc b
draw_symbol:
  ld a, i ;читаем адрес текущего символа
  st b, a ;сохраняем символ
  inc a ;следующий символ
  st a, i ;сохраняем
  mov a, b ;умножаем на 5
  shl b
  shl b
  add b, a
  ldi a, symbols ;и добавляем адрес символов
  add b, a
  ldi c, 5 ;количество итераций
  ldi d, terminal_art ;вывод графики в терминал
draw_symbol_loop:
  ld a, b ;читаем фрагмент символа
  st a, d ;сохраняем
  inc b ;следующий фрагмент
  dec c ;если фрагменты не закончились, продолжаем сохранять
  jnz draw_symbol_loop
st c, d ;каждый фрагмент занимает 5 байт, 6 байт пустой

check_current_symbol:
  ld a, i ;если символы ещё остались, генерируем следующий
  ldi b, s3 + 1
  xor a, b
  jnz choose_symbol
check_spin:
  ld a, save ;если пользователь дал реакцию, сравниваем символы между собой
  test a
  jz spin
ldi c, 3 ;переходим к сравнению символов
ldi d, cmp_symbols
jmp set_bank

symbols: ;символы
  seven db
  0b00000011,
  0b11110011,
  0b11111011,
  0b00011111,
  0b00001111
  pepper db
  0b11000000,
  0b01110000,
  0b01111100,
  0b00111111,
  0b00011101
  cherry db
  0b11111111,
  0b11000001,
  0b00000010,
  0b01111100,
  0b01100000
  strawberry db
  0b00011101,
  0b01110110,
  0b11101111,
  0b01110110,
  0b00011101
void3 db 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0

cmp_symbols: ;сравнение символов
  ld a, s1
  ld b, s2
  xor a, b ;сравниваем первый и второй
  jnz check_Lose
  ld a, s3
  xor b, a ;сравниваем второй и третий
  jnz check_Lose
  ld b, s1
  xor a, b
  jnz check_Lose ;сравниваем третий и первый
  ;если все символы равны, смотрим на множитель
  ;регистр b уже содержит символ
  ldi a, 10 ;если выпало 3 семёрки, множитель 10
  dec b
  js mul_bid
  ldi a, 7 ;если выпало 3 перца, множитель 7
  dec b
  js mul_bid
  ldi a, 4 ;если выпало 3 вишни, множитель 4
  dec b
  js mul_bid
  ldi a, 2 ;если выпало 3 клубники, множитель 2

mul_bid: ;умножаем ставку на множитель
  clr b
  clr c
  clr d
mul_bid_loop:
  st a, i
  ld a, bid
  add b, a
  ld a, bid256
  adc c, a
  clr a
  adc d, a
  ld a, i
  dec a
  jnz mul_bid_loop

add_balance:
  ld a, balance ;добавляем баланс
  add b, a
  ld a, balance256
  adc c, a
  test a
  clr a
  jns check_Win
  dec a
check_Win:
  adc d, a
  js win ;если баланс всё ещё отрицательный, пишем о попадании
  jnz Win ;если баланс больше 32767, пишем о победе
  test c
  js Win

win: ;попадание
  st b, balance ;сохраняем и выводим баланс
  st c, balance256
  ldi a, text_win ;текст попадания
  ldi b, ask_jmp ;адрес перехода после вывода текста
  jmp text_start_jmp ;переходим на прыжок к выводу текста
Win:
  ldi a, 255 ;выводим максимальное число на баланс (32767)
  st a, balance
  shr a
  st a, balance256
  ldi a, text_Win ;текст победы
  ldi b, end ;адрес перехода после вывода текста
  jmp text_start_jmp ;переходим на прыжок к выводу текста

check_Lose: ;промах, проверяем на окончательное поражение
  ld a, balance ;читаем баланс и проверяем на -32768
  test a
  jnz lose
  ld b, balance256
  neg b
  jno lose

Lose: ;поражение, баланс после ставки -32768
  ldi a, text_Lose ;текст поражения
  ldi b, end ;адрес перехода после вывода текста
  jmp text_start_jmp ;переходим на прыжок к выводу текста
lose:
  ldi a, text_lose ;текст промаха
  ldi b, ask_jmp ;адрес перехода после вывода текста

text_start_jmp: ;прыжок к выводу текста
  ldi c, 4
  ldi d, text_start
  jmp set_bank
void4 db 0, 0, 0, 0, 0, 0, 0, 0

text_start: ;выводим текст с новой строки
  ldi d, terminal
  ldi c, "\n"
  st c, d
text_loop:
  ld c, a ;читаем символ
  test c ;если прочли 0, значит символы закончились
  jz b
  st c, d ;выводим символ
  inc a ;следующий символ
  jmp text_loop ;продолжаем выводить

ask_jmp:
  ldi d, d2 ;обновляем счётчик цифр
  st d, i
  ldi d, ask_start ;повторяем
  jmp set_bank

end: ;конец
  hlt

text_Lose db "Коллектор:\n", "\"ОТКРЫВАЙ!\"\n", "*звуки боли*", 0 ;текст поражения
text_lose db "Промах!\n", 0 ;текст промаха
text_win db "Попадание!\n", 0 ;текст попадания
text_Win db "Поздравляю! ", "Ты заработал", "на казике!!!", 0 ;текст победы



;дискета:
;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
