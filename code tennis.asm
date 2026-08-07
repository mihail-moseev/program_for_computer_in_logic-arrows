RIGHT equ 0x13 ;код клавиши "вправо"
LEFT equ 0x11 ;код клавиши "влево"
jmp start ;переходим к старту
text db "\n\nSINNET\b\t" ;TENNIS наоборот
start:
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
ldi d, add_score ;переходим к добавлению счёта
set_bank:
  st c, bank
  jmp d
void db 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0
speedY db 0x02 ;скорость по Y (изначально вниз)
speedX db ball_left ;направление по X (изначально влево)
ball_pos db 0b00000100 ;позиция мяча в байте
ball_adress db 0x46 ;адрес мяча на дисплее
score db 0xff ;счёт (изначально -1, чтобы при старте было 0)
scoreX256 db 0xff
terminal db 0 ;вывод символов
terminal_art db 0 ;вывод графики (не используется)
in_out db 0b00010101 ;ввод-вывод (подключаем монохромный дисплей, цифровой индикатор и терминал)
bank db 0 ;банк
;дисплей
display db 0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000100, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000011, 0b10000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000
add_score:
  ld a, score ;читаем счёт
  inc a ;увеличиваем
  st a, score ;сохраняем
  jnz key_read ;если не вышли за пределы байта, переходим к чтению клавиши
  ld a, scoreX256 ;если вышли, читаем счёт x256
  inc a ;увеличиваем
  st a, scoreX256 ;сохраняем
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
  ldi d, check_game_over ;сохраняем адрес, чтобы программа занимала меньше байт
  ld b, ball_pos ;читаем позицию мяча заранее
  ld c, speedX ;читаем направление мяча по X
  jmp c
ball_left:
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
void2 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
game_over_start:
  ldi b, image_size ;размер изображения
  ldi c, img ;адрес изображения
  ldi d, 0x44 ;адрес вывода изображения
game_over_loop:
  ld a, c ;читаем фрагмент изображения
  st a, d ;сохраняем на дисплей
  inc c
  inc d
  dec b ;если фрагменты ещё остались, повторяем итерацию
  jnz game_over_loop
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
image_size equ $ - img ;размер изображения



дискета:
AAASAAAAAAAJCRkUACQANABEAFQAZAB0AIQAlACkALQAxADUAOQA9AAFAAYCBwIIAgkECgQLAwwBDQEOAQ8BCjgmAicCKAJoA4gDqAPIA+gDKQJJAmkCiQKpAskC6QIqAkoCagKKAqoCygLqAisCSwJrAosCqwLLAusCLAJMAmwCjAKsAswC7AItAk0CbQKNAq0CzQLtAi4CTgJuAo4CrgLOAu4CLwJPAm8CjwKvAs8C7wIMBkUBNgJnAIcApwDHAOcAAR03A7kB2QH5AToBugHaAfoBOwFbAbsB2wH7ATwBvAHcAfwBPQFdAZ0BvQHdAf0BvgHeAf4BPwG/Ad8B/wEOATgBSAQIBDkBeQGbAT4BngETBkYBVgF2AZYBtgHWAfYBEAZHAVcBdwGXAbcB1wH3AQcUWAF4AZgBuAHYAfgBWQGZBVoBegGaBXsBXAF8AZwBfQVeAX4BXwF/AZ8FBgRmAIYApgDGAOYAAQAAAAQJDwABAQECAQMBBAEFAQYBBwEIAQkECgQLAwwBDQEOAQ8BCm8gAkACYAKAAqACwALgAiECQQJhAoECoQLBAuECIgJCAmICggKiAsIC4gIjAkMCYwKDAqMCwwLjAiQCRAJkAoQCpALEAuQCJQJFAmUChQKlAsUC5QImAkYCZgKGAqYCxgLmAicCRwJnAocCpwLHAucCKAJIAmgCiAKoAsgC6AIpAkkCaQKJAqkCyQLpAioCSgJqAooCqgLKAuoCKwJLAmsCiwKrAssC6wIsAkwCbAKMAqwCzALsAi0CTQJtAo0CrQLNAu0CLgJOAm4CjgKuAs4C7gIvAk8CbwKPAq8CzwLvAgFFMAFwAZABsAHQAfABUQGxAdEB8QGyAdIB8gEzAVMBswHTAfMBNAFUAbQB1AH0AZUBtQHVAfUBlgG2AdYB9gE3AVcBdwG3AdcB9wE4AVgBeAG4AdgB+AFZAbkB2QH5AToBugHaAfoBuwHbAfsBnAG8AdwB/AF9Ab0B3QH9Ab4B3gH+AT8BXwG/Ad8B/wEHIFABMQVxBTIFUgVyAZIBcwGTAXQBlAE1BVUBNgVWBXYFlwWYAXkBmQVaAXoBmgU7AVsBewE8AVwBfAE9AV0FPgVeBQgIkQF1ATkBmwGdAX4BngF/AZ8BAgAAAAQJGAABAQECAQMBBAEFAQYBBwEIAQkAGgAqADoASgBaAGoAegCKAJoAqgC6AMoA2gDqAPoACj4gAkACYAKAAqACwALgAiECQQJhAoECoQLBAuECIgJCAmICggKiAsIC4gIjAkMCYwKDAqMCwwLjAiQCRAJkAoQCpALEAuQCJQJFAmUChQKlAsUC5QImAkYCZgKGAqYCxgLmAicCRwJnAocCpwLHAucCKAJIAmgCiAKoAsgC6AIHDDABMQXxBXIFkgE0AXQBNQVVAfUBdgE4AfgFCAWRATIBUwE2AXcB9wEBK1ABcAGQAbAB0AHwAVEBcQGxAdEBUgGyAdIB8gEzAXMBkwGzAdMB8wFUAZQBtAHUAfQBdQGVAbUB1QFWAZYBtgHWAfYBNwFXAZcBtwHXAVgBeAGYAbgB2AEAAAEACAkPBAAUACQANABEAFQAZAB0AIQAlACkALQAxADUAOQA9AAGBwYAJgBGAGYAhgCmAMYA5gAMBwcAJwBHAGcAhwCnAMcA5wAKPwgDKANIA2gDiAOoA8gD6AMJAikCSQJpAokCqQLJAukCCgIqAkoCagKKAqoCygLqAgsCKwJLAmsCiwKrAssC6wIMAiwCTAJsAowCrALMAuwCDQItAk0CbQKNAq0CzQLtAg4CLgJOAm4CjgKuAs4C7gIPAi8CTwJvAo8CrwLPAu8CEwcWATYBVgF2AZYBtgHWAfYBEAcXATcBVwF3AZcBtwHXAfcBBxMYATgBWAF4AZgBuAHYAfgBGgHaBfoBuwH7AbwBHQW9BR4BvgX+Bd8FASYZATkBWQF5AbkB+QE6AVoBegGaAboBGwE7AVsBewGbARwBPAFcAXwBnAHcAT0BXQF9AZ0B3QH9AT4BXgF+AZ4B3gEfAT8BXwF/AZ8B/wEIBJkB2QHbAfwBvwEBAAEAAwp/AAIgAkACYAKAAqACwALgAgECIQJBAmECgQKhAsEC4QICAiICQgJiAoICogLCAuICAwIjAkMCYwKDAqMCwwLjAgQCJAJEAmQChAKkAsQC5AIFAiUCRQJlAoUCpQLFAuUCBgImAkYCZgKGAqYCxgLmAgcCJwJHAmcChwKnAscC5wIIAigCSAJoAogCqALIAugCCQIpAkkCaQKJAqkCyQLpAgoCKgJKAmoCigKqAsoC6gILAisCSwJrAosCqwLLAusCDAIsAkwCbAKMAqwCzALsAg0CLQJNAm0CjQKtAs0C7QIOAi4CTgJuAo4CrgLOAu4CDwIvAk8CbwKPAq8CzwLvAgcTEAGQBdAB8gWzBbQB9AXWBfYB9wH4AbkF2QG6BdsB+wHcAd0F/gH/AQgQEQESARMB0wEUARUB1QEWARcBtwHXARgB+QG7Ab4B3gHfAQFaMAFQAXABsAHwATEBUQFxAZEBsQHRAfEBMgFSAXIBkgGyAdIBMwFTAXMBkwHzATQBVAF0AZQB1AE1AVUBdQGVAbUB9QE2AVYBdgGWAbYBNwFXAXcBlwE4AVgBeAGYAbgB2AEZATkBWQF5AZkBGgE6AVoBegGaAdoB+gEbATsBWwF7AZsBHAE8AVwBfAGcAbwB/AEdAT0BXQF9AZ0BvQH9AR4BPgFeAX4BngEfAT8BXwF/AZ8BvwECAAEABApHAAIgAkACYAKAAqACwALgAgECIQJBAmECgQKhAsEC4QICAiICQgJiAoICogLCAuICAwIjAkMCYwKDAqMCwwLjAgQCJAJEAmQChAKkAsQC5AIFAiUCRQJlAoUCpQLFAuUCBgImAkYCZgKGAqYCxgLmAgcCJwJHAmcChwKnAscC5wIIAigCSAJoAogCqALIAugCCQ8KABoAKgA6AEoAWgBqAHoAigCaAKoAugDKANoA6gD6AAEzEAEwAVABcAGQAbAB0AExAVEBcQGRAbEB0QHxAVIBcgGSATMBUwFzAZMB8wEUATQBVAF0AZQB9AEVATUBVQF1AZUBtQEWATYBVgF2AZYBtgHWARcBNwFXAXcBlwEYATgBWAF4AZgB2AEHEBEBEgEyAdIBEwGzBdMBtAHUAdUB9QX2AbcB1wH3AbgB+AUIAvABsgHyAQAAAgAICQ8EABQAJAA0AEQAVABkAHQAhACUAKQAtADEANQA5AD0AAYHBgAmAEYAZgCGAKYAxgDmAAwHBwAnAEcAZwCHAKcAxwDnAAo/CAMoA0gDaAOIA6gDyAPoAwkCKQJJAmkCiQKpAskC6QIKAioCSgJqAooCqgLKAuoCCwIrAksCawKLAqsCywLrAgwCLAJMAmwCjAKsAswC7AINAi0CTQJtAo0CrQLNAu0CDgIuAk4CbgKOAq4CzgLuAg8CLwJPAm8CjwKvAs8C7wITBxYBNgFWAXYBlgG2AdYB9gEQBxcBNwFXAXcBlwG3AdcB9wEHKBgBOAFYAXgBmAG4AdgB+AEZAVkBmQW5BdkB+QUaAVoBmgW6AdoB+gEbATsBWwGbBbsBHAFcAZwFvAEdAZ0F3QX9AR4FPgFeBX4B3gEfAV8B/wUBDzkBeQE6AXoBewH7AdwB/AE9AV0BfQG9AZ4BvgH+Ab8BCAbbATwBfAE/AX8BnwHfAQEAAgADCn8AAiACQAJgAoACoALAAuACAQIhAkECYQKBAqECwQLhAgICIgJCAmICggKiAsIC4gIDAiMCQwJjAoMCowLDAuMCBAIkAkQCZAKEAqQCxALkAgUCJQJFAmUChQKlAsUC5QIGAiYCRgJmAoYCpgLGAuYCBwInAkcCZwKHAqcCxwLnAggCKAJIAmgCiAKoAsgC6AIJAikCSQJpAokCqQLJAukCCgIqAkoCagKKAqoCygLqAgsCKwJLAmsCiwKrAssC6wIMAiwCTAJsAowCrALMAuwCDQItAk0CbQKNAq0CzQLtAg4CLgJOAm4CjgKuAs4C7gIPAi8CTwJvAo8CrwLPAu8CB0IQAVABsAExAXEBkQGxBfEFEgEyAVIBcgHSATMFkwGzAdMB8wUUATQBVAF0AZQB1AGVBbUFFgE2AXYBlgG2AdYB9gEXBVcFtwXXAfcFOAF4ARkFWQXZAfkFGgVaBZoBOwGbBdsBnAHcAR0FXQWdAb0FHgE+AV4BfgGeAb4F3gX+BR8BXwG/BQEnMAFwAZAB0AERAVEBkgGyARMBUwH0ARUBNQFVAXUB1QH1AVYBNwF3AZgBOQF5AZkBuQE6AXoB2gEbAVsBewG7AfsBHAFcAbwB/AE9AX0B3QEIFPAB0QHyAXMBtAGXARgBWAG4AdgB+AG6AfoBPAF8Af0BPwF/AZ8B3wH/AQIAAgAECkcAAiACQAJgAoACoALAAuACAQIhAkECYQKBAqECwQLhAgICIgJCAmICggKiAsIC4gIDAiMCQwJjAoMCowLDAuMCBAIkAkQCZAKEAqQCxALkAgUCJQJFAmUChQKlAsUC5QIGAiYCRgJmAoYCpgLGAuYCBwInAkcCZwKHAqcCxwLnAggCKAJIAmgCiAKoAsgC6AIJDwoAGgAqADoASgBaAGoAegCKAJoAqgC6AMoA2gDqAPoAByoQBVAFkAWwBfAFEQFRAZEBsQHRBfEBEgFSAbIB8gFTBXMBswHTAfMBFAFUAXQBtAHUAfQBNQV1AZUFtQX1ARYBNgFWAXYFlgXWATcBlwUYATgFWAGYBQgFMQGSARMB1QF3AdcBARYwAXAB0AFxATIBcgHSATMBkwE0AZQBFQFVAbYB9gEXAVcBtwH3AXgBuAHYAfgBAAADAAgJDwQAFAAkADQARABUAGQAdACEAJQApAC0AMQA1ADkAPQABgcGACYARgBmAIYApgDGAOYADAcHACcARwBnAIcApwDHAOcACj8IAygDSANoA4gDqAPIA+gDCQIpAkkCaQKJAqkCyQLpAgoCKgJKAmoCigKqAsoC6gILAisCSwJrAosCqwLLAusCDAIsAkwCbAKMAqwCzALsAg0CLQJNAm0CjQKtAs0C7QIOAi4CTgJuAo4CrgLOAu4CDwIvAk8CbwKPAq8CzwLvAhMHFgE2AVYBdgGWAbYB1gH2ARAHFwE3AVcBdwGXAbcB1wH3AQchGAE4AVgBeAGYAbgB2AH4ATkBWQF5BZkB+QU6AVoBegW6BTsBWwG7AdsFPAFcAbwBnQW9Bd0FfgHeAf4BnwG/Ad8B/wEBExkBuQEaAZoB+gEbAfsBfAGcAfwBHQE9AV0BHgE+AV4BngG+AT8BXwEICdkB2gF7AZsBHAHcAX0B/QEfAX8BAQADAAMKfwACIAJAAmACgAKgAsAC4AIBAiECQQJhAoECoQLBAuECAgIiAkICYgKCAqICwgLiAgMCIwJDAmMCgwKjAsMC4wIEAiQCRAJkAoQCpALEAuQCBQIlAkUCZQKFAqUCxQLlAgYCJgJGAmYChgKmAsYC5gIHAicCRwJnAocCpwLHAucCCAIoAkgCaAKIAqgCyALoAgkCKQJJAmkCiQKpAskC6QIKAioCSgJqAooCqgLKAuoCCwIrAksCawKLAqsCywLrAgwCLAJMAmwCjAKsAswC7AINAi0CTQJtAo0CrQLNAu0CDgIuAk4CbgKOAq4CzgLuAg8CLwJPAm8CjwKvAs8C7wIHMRABMAFQBZAB0AHwAXEBkQWxBdEFEgEyAXIBkgGyAXMBswV0AfQFNQF1BZUF1QU2AZYF1gU3BVcFWAGYBRkFOQWZAdkFGgFaAZoF2gEbATsFuwX7ARwBvAF9Ab0FPgF+BT8FnwUIGLABEQExAdIBkwHTAVQBtAHUAfUBtgGXAdcBGAE4AVkBOgG6AfoBewHbAR0B3QGeAX8BATRwAVEB8QFSAfIBEwEzAVMB8wEUATQBlAEVAVUBtQEWAVYBdgH2ARcBdwG3AfcBeAG4AdgB+AF5AbkB+QF6AVsBmwE8AVwBfAGcAdwB/AE9AV0BnQH9AR4BXgG+Ad4B/gEfAV8BvwHfAf8BAgADAAQKRwACIAJAAmACgAKgAsAC4AIBAiECQQJhAoECoQLBAuECAgIiAkICYgKCAqICwgLiAgMCIwJDAmMCgwKjAsMC4wIEAiQCRAJkAoQCpALEAuQCBQIlAkUCZQKFAqUCxQLlAgYCJgJGAmYChgKmAsYC5gIHAicCRwJnAocCpwLHAucCCAIoAkgCaAKIAqgCyALoAgkPCgAaACoAOgBKAFoAagB6AIoAmgCqALoAygDaAOoA+gAICxABMAFQARMBcwGzARUBNgEXAVcBdwE4AQchkAGwAREFMQVRBXEBsQUSBTIFUgFyAZIFsgFTAZMF0wVUAZQBtAXUATUBVQGVBdUFFgF2BZYBtgXWAZcB1wFYBZgB2AEBGXAB0AHwAZEB0QHxAdIB8gEzAfMBFAE0AXQB9AF1AbUB9QFWAfYBNwG3AfcBGAF4AbgB+AEAAAQADgkNBAAUACQANABEAFQAZAB0AIQAlACkALQAxADUAwYGBgAmAEYAZgCGAKYAxgIMCuQC9AIHACcARwBnAIcApwDHAMkC6wEKOAgDKANIA2gDiAOoA9gB6AAJAikCSQJpAokCqQIKAioCSgJqAooCqgILAisCSwJrAosCqwL7AwwCLAJMAmwCjAKsAtwB/AMNAi0CTQJtAo0CrQL9Aw4CLgJOAm4CjgKuAu4B/gMPAi8CTwJvAo8CrwL/AxMFFgE2AVYBdgGWAbYBEAUXATcBVwF3AZcBtwEHGhgBOAFYAXgBmAE5AVkFeQG5AToBWgV6BboBOwFbBbsBPAFcAXwFvAV9BT4FvgE/AV8FfwW/AQEa9gDIA/gCGQGZARoBmgHKAxsBewGbAcsDHAGcAcwDHQE9AZ0BvQHNAh4BfgGeAc4DHwGfAc8DCAFdAV4BDQG4BukGDgLWAfcF+QMRA9cC5wLsAe0BCwLZAfoC3QMEA9oB2wHeAd8BEgHmAOoBAQAEAAcKbAACIAJAAmACgAKgAtAB8AMBAiECQQJhAoECoQLxAwICIgJCAmICggKiAgMCIwJDAmMCgwKjAvMDBAIkAkQCZAKEAqQC1AH0AwUCJQJFAmUChQKlAvUDBgImAkYCZgKGAqYC9gMHAicCRwJnAocCpwL3AwgCKAJIAmgCiAKoAtgB+AMJAikCSQJpAokCqQL5AwoCKgJKAmoCigKqAgsCKwJLAmsCiwKrAgwCLAJMAmwCjAKsAtwBDQItAk0CbQKNAq0CDgIuAk4CbgKOAq4CDwIvAk8CbwKPAq8CAUYQATABkAHAAxEBkQHBAhIBkgHCAxMBkwHDA+MBFAGUAcQD5AEVAVUBlQG1AcUC5QEWAZYBxgMXATcBVwGXAccD5wMYAVgBmAHIA+gDGQGZAckC6QMaAZoBugHKA+oDGwFbAcsD6wMcAcwD7AMdAT0BnQG9Ac0C7QMeAV4BngHOA+4DHwE/AV8BnwHPA+8DBy5QAXAFsAExBVEBcQGxATIBUgFyAbIBMwFzBbMBNAFUAXQFtAU1BXUBdgG2AXcBtwU4BXgBuAFZBXkBuQU6AVoBOwF7BZsFuwU8AVwFfAWcAbwBXQF9BT4BfgG+AX8BCAVTATYBVgE5AXoBvwELA9ED1QPZA90DBA7SAeIB0wHWAdcB2gH6A9sB+wP8A/0D3gH+A98B/wMNAeAB8gMRAOYCAgAEAAgKNwACIAJAAmACgAKgAtABAQIhAkECYQKBAqECAgIiAkICYgKCAqICAwIjAkMCYwKDAqMCBAIkAkQCZAKEAqQC1AEFAiUCRQJlAoUCpQIGAiYCRgJmAoYCpgIHAicCRwJnAocCpwIIAigCSAJoAogCqAIJD/cD6APZAwoAGgAqADoASgBaAGoAegCKAJoAqgC6AMoAASsQAVABkAGwAcAD4AMRATEBUQGxAcEC4QMSAVIBsgHCA+IDEwEzAbMBwwMUAbQBxAMVATUBVQG1AcUCFgFWAXYBtgHGAxcBVwG3AccDGAE4AVgBmAG4AcgDBxAwAXABcQGRATIFkgFTBXMFkwE0AVQBdAGUBZYBdwGXBXgBCARyAXUBlQE2ATcBCwXRA/QA1QP1AuYC1wIEB/AD0gHTAeMD8wHkA+UD1gERAPEDBgDyAwAABQAIDAMEABYAJwEpAwoJQANCA0QDBgAmAjYARgNWAAgBCQMRAAcCBAUKAQsBDAENAQ4BDwEOARQBJQQLABcCCQYoACoAKwEsAy0DLgMvAwEAZgAYFIQBlAGkAXUBhQGVAaUBtQF2AIYAlgCmALYAdwOHA5cDpwO3A4gDmAOoAwEABQABBA8AAQEBAgEDAQQBBQEGAQcBCAEJAQoBCwEMAQ0BDgEPAQkPIAMhAyIDIwMkAyUDJgMnAygDKQMqAysDLAMtAy4DLwMCAAUAAgQBAAEBAAECAgADAwQDCQYgAyEDIgMjAyQDFQMGAw==
