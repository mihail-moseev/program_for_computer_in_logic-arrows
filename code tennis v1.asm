KEY_RIGHT equ 0x13 ;код клавиши вправо
KEY_LEFT equ 0x11 ;код клавиши влево
BAT_RIGHT equ 0x59 ;правый байт ракетки
BAT_LEFT equ 0x58 ;левый байт ракетки
add_score:
  ldi b, 0x10 ;подключаем цифровой индикатор
  st b, out
  ld b, score ;читаем счёт
  inc b ;увеличиваем
  st b, score ;сохраняем
  st b, display ;выводим
  ldi b, 0x80 ;подключаем дисплей
  st b, out
  mov a, 0 ;очищаем байт дисплея
  st a, display
key_read:
  ld b, in ;читаем клавишу
  mov a, 0 ;обнуляем порт
  st a, in
  ldi a, KEY_RIGHT ;клавиша вправо
  xor a, b
  jz bat_right
  ldi a, KEY_LEFT ;клавиша влево
  xor a, b
  jz bat_left
  jmp ball_clear ;если клавиша не нажата, переходим сразу к обработке мяча
coord_to_pos: ;функция преобразования координат в позицию на дисплее
  shl b ;преобразовываем две координаты в 1 байт
  shl b
  shl b
  shl b
  or a, b
  ldi c, 7 ;определяем позицию в байте
  and c, a
  ldi b, 0b10000000
  shr_loop:
    shr b
    dec c
    jns shr_loop
  rcl b
  shr a ;определяем адрес на дисплее
  shr a
  shr a
  ldi c, 0x40
  add a, c
  jmp d ;переходим дальше
score db 0 - 1 ;очки (изначально -1, чтобы в начале программы вывести 0)
speed_x db 1 ;скорость мяча по x
speed_y db 0 - 1 ;скорость мяча по y
ball_x db 0x07 ;координата мяча по x
ball_y db 0x0b ;координата мяча по y
in db 0 ;ввод
out db 0x80 ;вывод (подключаем дисплей)
display db ;дисплей
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000001, 0b00000000,
0b00000011, 0b10000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000,
0b00000000, 0b00000000
bat_right: ;смещение ракетки вправо
  ldi b, BAT_RIGHT ;читаем байт правой ракетки
  ld a, b ;проверяем столкновение со стеной
  shr a
  jc ball_move_x ;если столкновение есть, переходим к движению мяча
  dec b ;иначе переключаемся на левый байт
  ld a, b ;сдвигаем
  shr a
  st a, b
  inc b ;правый байт
  ld a, b ;сдвигаем с переносом из левого
  rcr a
  st a, b
  jmp ball_clear ;переходим к движению мяча
bat_left: ;смещение ракетки влево (то же самое, что и для правой, но наоборот)
  ldi b, BAT_LEFT
  ld a, b
  shl a
  jc ball_clear
  inc b
  ld a, b
  shl a
  st a, b
  dec b
  ld a, b
  rcl a
  st a, b
;движение мяча
ball_clear: ;стираем мяч
  ld a, ball_x ;читаем x и y мяча
  ld b, ball_y
  shr a ;преобразуем в адрес
  shr a
  shr a
  shl b
  add b, a
  ldi a, 0x40
  add b, a
  mov a, 0 ;стираем байт
  st a, b
ball_move_y:
  ld a, ball_y ;читаем y мяча
check_up:
  or a, 0 ;если находимся не в верхней части, переходим к проверке скорости
  jnz check_speed_y
  ldi b, 1 ;иначе меняем скорость
  st b, speed_y
  jmp add_y ;и переходим к изменению координаты
check_speed_y:
  ld c, speed_y ;читаем скорость
  inc c ;если двигаемся вверх, пропускаем проверку на ракетку
  jz add_y
check_coord_bat:
  ldi b, 0x0b ;сравниваем координату с линией отталкивания ракетки
  xor b, a
  jnz add_y ;если находимся не на этой линии, пропускаем дальнейшую обработку
  inc a ;смещаем координату вниз
  mov b, a ;копируем в b
  ld a, ball_x ;читаем координату по x
  ldi d, check_bat ;переходим к преобразованию
  jmp coord_to_pos
check_bat:
  mov d, a
  mov a, b
  ld c, d ;читаем байт
  and c, a ;если ракетки не коснулись, переходим к поражению
  jz game_over
  mov a, 0 ;иначе меняем адрес перехода после отрисовки мяча
  st a, draw_jmp + 1
  dec a ;и меняем скорость
  st a, speed_y
  ld a, ball_y ;читаем координату обратно
add_y:
  ld c, speed_y ;читаем скорость
  add a, c ;прибавляем
  st a, ball_y ;сохраняем
ball_move_x:
  ld a, ball_x ;читаем координату по x
check_left:
  or a, 0
  jnz check_right ;если не находимся слева, делаем проверку на правое положение
  ldi b, 1 ;иначе меняем скорость
  st b, speed_x
  jmp add_x ;и переходим к изменению координаты
check_right:
  ldi b, 0x0f ;сравниваем с самым правым положением
  xor b, a
  jnz add_x ;если мы не на нём, изменяем координату
  dec b ;иначе меняем скорость (регистр b содержит 0)
  st b, speed_x
add_x:
  ld c, speed_x ;читаем скорость
  add a, c ;добавляем к координате
  st a, ball_x ;сохраняем
  ld b, ball_y ;читаем координату по y
  ldi d, draw ;переходим к преобразованию
  jmp coord_to_pos
draw:
  st b, a ;выводим мяч
draw_jmp:
  ldi d, key_read ;изменяемый адрес перехода
  ldi a, key_read ;восстанавливаем адрес перехода
  st a, draw_jmp + 1
  jmp d ;переходим по адресу
game_over: ;поражение
  ldi d, 0x40 ;подключаем терминал
  st d, out
  ldi c, game_over_text ;адрес текста
text_loop:
  ld a, c ;читаем символ
  st a, d ;выводим
  inc c ;следующий символ
  jnz text_loop ;если символы ещё остались - повторяем
hlt ;конец
void db 0, 0, 0, 0
game_over_text db "GAME    OVER! " ;текст при поражении



;дискета:
;AAAUAAAAAAAJCR0BAREAIQAxAEEAUQBhAHEAgQCRAKEAsQDBANEA4QDxAAICAwIEAgUCBgQHBAgDCQEKAQsBDAENAQ4BDwEKSmUDhQOlA8UD5QMmAkYCZgKGAqYCxgLmAicCRwJnAocCpwLHAucCKAJIAmgCiAKoAsgC6AIpAkkCaQKJAqkCyQLpAioCSgJqAooCqgLKAuoCKwJLAmsCiwKrAssC6wIsAkwCbAKMAqwCzALsAi0CTQJtAo0CrQLNAu0CLgJOAm4CjgKuAs4C7gIvAk8CbwKPAq8CzwLvAgwGQgEzAmQAhACkAMQA5AABITQDlgG2AdYBVwGXAbcB1wH3ATgBWAGYAdgBeQHZAfkBOgG6AdoBOwF7AZsBuwHbAbwBPQFdAf0BfgH+AT8BfwG/Af8BDgE1AUUEByRVAXUBlQG1AdUB9QE2AVYBdgE3BXcFuAX4ATkFWQWZBbkFWgF6AZoB+gFbBfsFPAF8BZwF3AX8AX0FnQW9Ad0FPgFeAb4B3gVfBRMGQwFTAXMBkwGzAdMB8wEQBkQBVAF0AZQBtAHUAfQBCAX2AXgBXAGeAZ8B3wEGBGMAgwCjAMMA4wABAAAABAkWAAEBAQIBAwEEAQUBBgEHARcAJwA3AEcAVwBnAHcAhwCXAKcAtwDHANcA5wD3AAopIAJAAmACgAKgAsAC4AIhAkECYQKBAqECwQLhAiICQgJiAoICogLCAuICIwJDAmMCgwKjAsMC4wIkAkQCZAKEAqQCxALkAiUCRQJlAoUCpQLFAuUCBxAwBfAFMQVRAXEBsQVSAXIBsgVzBdMFVAX0BVUFdQXVBfUBCAeQAdAB8QEyATMBswE0AbQBARBQAXABsAGRAdEBkgHSAfIBUwGTAfMBdAGUAdQBNQGVAbUBAAABAAgJDwEAEQAhADEAQQBRAGEAcQCBAJEAoQCxAMEA0QDhAPEABgcDACMAQwBjAIMAowDDAOMADAcEACQARABkAIQApADEAOQAClcFAyUDRQNlA4UDpQPFA+UDBgImAkYCZgKGAqYCxgLmAgcCJwJHAmcChwKnAscC5wIIAigCSAJoAogCqALIAugCCQIpAkkCaQKJAqkCyQLpAgoCKgJKAmoCigKqAsoC6gILAisCSwJrAosCqwLLAusCDAIsAkwCbAKMAqwCzALsAg0CLQJNAm0CjQKtAs0C7QIOAi4CTgJuAo4CrgLOAu4CDwIvAk8CbwKPAq8CzwLvAhMHEwEzAVMBcwGTAbMB0wHzARAHFAE0AVQBdAGUAbQB1AH0AQcwFQE1AVUBdQGVAbUB1QH1AVYBdgW2ARcFdwXXAVgBuAXYARkFOQFZAXkFmQXZARoBWgGaAboB2gU7BXsBmwHbBRwBPAVcAZwBvAVdAZ0BvQHdBR4BPgVeAX4FngX+AR8FvwEBGBYBNgGWAdYB9gE3AVcBlwEYAXgBmAG5AToBGwFbAbsBfAHcAR0BfQG+Ad4BXwHfAf8BCA23AfcBOAH4AfkBegH6AfsB/AE9Af0BPwF/AZ8BAQABAAQKLwACIAJAAmACgAKgAsAC4AIBAiECQQJhAoECoQLBAuECAgIiAkICYgKCAqICwgLiAgMCIwJDAmMCgwKjAsMC4wIEAiQCRAJkAoQCpALEAuQCBQIlAkUCZQKFAqUCxQLlAgkPBwAXACcANwBHAFcAZwB3AIcAlwCnALcAxwDXAOcA9wAHGBABUAGwATEBUQGRAbEB0QEyAVIBcgGSBdIFcwWTAbMBFAU0AVQBlAW0AdQFNQF1BbUBAQ9wAZAB0AHwAREBcQHxARIBsgETATMBUwHTAXQBVQHVAQgGMAHyAfMB9AEVAZUB9QEAAAIACAkPAQARACEAMQBBAFEAYQBxAIEAkQChALEAwQDRAOEA8QAGBwMAIwBDAGMAgwCjAMMA4wAMBwQAJABEAGQAhACkAMQA5AAKVwUDJQNFA2UDhQOlA8UD5QMGAiYCRgJmAoYCpgLGAuYCBwInAkcCZwKHAqcCxwLnAggCKAJIAmgCiAKoAsgC6AIJAikCSQJpAokCqQLJAukCCgIqAkoCagKKAqoCygLqAgsCKwJLAmsCiwKrAssC6wIMAiwCTAJsAowCrALMAuwCDQItAk0CbQKNAq0CzQLtAg4CLgJOAm4CjgKuAs4C7gIPAi8CTwJvAo8CrwLPAu8CEwcTATMBUwFzAZMBswHTAfMBEAcUATQBVAF0AZQBtAHUAfQBBwsVATUBVQF1AZUBtQHVAfUBFwEbBf0F3gEIAhYB9gEaAQFINgFWAXYBlgG2AdYBNwFXAXcBlwG3AdcB9wEYATgBWAF4AZgBuAHYAfgBGQE5AVkBeQGZAbkB2QH5AToBWgF6AZoBugHaAfoBOwFbAXsBmwG7AdsB+wEcATwBXAF8AZwBvAHcAfwBHQE9AV0BfQGdAb0B3QEeAT4BXgF+AZ4BvgH+AR8BPwFfAX8BnwG/Ad8B/wEBAAIAAwovAAIgAkACYAKAAqACwALgAgECIQJBAmECgQKhAsEC4QICAiICQgJiAoICogLCAuICAwIjAkMCYwKDAqMCwwLjAgQCJAJEAmQChAKkAsQC5AIFAiUCRQJlAoUCpQLFAuUCCQ8HABcAJwA3AEcAVwBnAHcAhwCXAKcAtwDHANcA5wD3AAEuEAEwAVABcAGQAbAB0AHwAREBMQFRAXEBkQGxAdEB8QESATIBUgFyAZIBsgHSAfIBEwEzAVMBcwGTAbMB0wHzARQBNAFUAXQBlAG0AdQB9AE1AVUBdQGVAbUB1QH1AQcAFQUAAAMACAkPAQARACEAMQBBAFEAYQBxAIEAkQChALEAwQDRAOEA8QAGBwMAIwBDAGMAgwCjAMMA4wAMBwQAJABEAGQAhACkAMQA5AAKVwUDJQNFA2UDhQOlA8UD5QMGAiYCRgJmAoYCpgLGAuYCBwInAkcCZwKHAqcCxwLnAggCKAJIAmgCiAKoAsgC6AIJAikCSQJpAokCqQLJAukCCgIqAkoCagKKAqoCygLqAgsCKwJLAmsCiwKrAssC6wIMAiwCTAJsAowCrALMAuwCDQItAk0CbQKNAq0CzQLtAg4CLgJOAm4CjgKuAs4C7gIPAi8CTwJvAo8CrwLPAu8CEwcTATMBUwFzAZMBswHTAfMBEAcUATQBVAF0AZQBtAHUAfQBBzIVATUBVQF1AZUBtQHVAfUBNgFWAbYB1gE3BXcBlwG3BVgFeAGYBdgF+AE5BXkBmQG5BfkBOgHaBTsFewGbAbsF+wE8AbwBPQFdBX0FnQW9Ad0B/QVeAX4B3gH+AT8BfwWfBb8B3wUBGRYBdgGWAfYBFwFXAdcB9wEYATgBuAEZARoBWgF6AZoBugH6ARsBHAEdAR4BPgGeAb4BHwEIClkB2QFbAdsBXAF8AZwB3AH8AV8B/wEBAAMABAovAAIgAkACYAKAAqACwALgAgECIQJBAmECgQKhAsEC4QICAiICQgJiAoICogLCAuICAwIjAkMCYwKDAqMCwwLjAgQCJAJEAmQChAKkAsQC5AIFAiUCRQJlAoUCpQLFAuUCCQ8HABcAJwA3AEcAVwBnAHcAhwCXAKcAtwDHANcA5wD3AAEQEAFQAXAB0AHwAREBEgEyAVIBcgGyAdIB8gETAbMBFAEVAQcbMAGQBbABMQVRAXEBsQXRAfEBkgUzAVMBcwHTAfMBNAFUAXQBtAHUAfQBNQFVBXUFlQG1AdUF9QUIApEBkwGUAQAABAAICQ8BABEAIQAxAEEAUQBhAHEAgQCRAKEAsQDBANEA4QDxAAYHAwAjAEMAYwCDAKMAwwDjAAwHBAAkAEQAZACEAKQAxADkAApXBQMlA0UDZQOFA6UDxQPlAwYCJgJGAmYChgKmAsYC5gIHAicCRwJnAocCpwLHAucCCAIoAkgCaAKIAqgCyALoAgkCKQJJAmkCiQKpAskC6QIKAioCSgJqAooCqgLKAuoCCwIrAksCawKLAqsCywLrAgwCLAJMAmwCjAKsAswC7AINAi0CTQJtAo0CrQLNAu0CDgIuAk4CbgKOAq4CzgLuAg8CLwJPAm8CjwKvAs8C7wITBxMBMwFTAXMBkwGzAdMB8wEQBxQBNAFUAXQBlAG0AdQB9AEHLBUBNQFVAXUBlQG1AdUB9QE2AVcBtwHXBfcFGAVYAbgBGQE5BVkBeQGZBbkFOgFaAXoBmgG6AfoFGwF7AbsF2wX7BVwBfAXcBR0FXQG9Bf0BXgG+AT8BXwHfAQEeFgFWAXYBlgEXATcBdwGXATgBeAGYAdkB+QEaAdoBWwG8AfwBPQF9AZ0BHgE+AX4BngH+AR8BfwGfAb8B/wEIC7YB1gH2AdgB+AE7AZsBHAE8AZwB3QHeAQEABAAECi8AAiACQAJgAoACoALAAuACAQIhAkECYQKBAqECwQLhAgICIgJCAmICggKiAsIC4gIDAiMCQwJjAoMCowLDAuMCBAIkAkQCZAKEAqQCxALkAgUCJQJFAmUChQKlAsUC5QIJDwcAFwAnADcARwBXAGcAdwCHAJcApwC3AMcA1wDnAPcAARAQAXABsAFRAXEBkQGxARIBMgFSAXIBkgGzAdMBVAHUARUBBxYwAVAFkAHwBREFMQHRBbIB0gUzAVMFcwGTAfMBNAGUBbQFNQFVBXUFtQXVBfUFCAfQAfEB8gETARQBdAH0AZUBAAAFAAgJDwEAEQAhADEAQQBRAGEAcQCBAJEAoQCxAMEA0QDhAPEABgcDACMAQwBjAIMAowDDAOMADAcEACQARABkAIQApADEAOQAClcFAyUDRQNlA4UDpQPFA+UDBgImAkYCZgKGAqYCxgLmAgcCJwJHAmcChwKnAscC5wIIAigCSAJoAogCqALIAugCCQIpAkkCaQKJAqkCyQLpAgoCKgJKAmoCigKqAsoC6gILAisCSwJrAosCqwLLAusCDAIsAkwCbAKMAqwCzALsAg0CLQJNAm0CjQKtAs0C7QIOAi4CTgJuAo4CrgLOAu4CDwIvAk8CbwKPAq8CzwLvAhMHEwEzAVMBcwGTAbMB0wHzARAHFAE0AVQBdAGUAbQB1AH0AQclFQE1AVUBdQGVAbUB1QH1ARYBlgUXBTcB1wX3BXgFuAUZBTkFuQX6BRsFOwVbBXsBnAW8AfwFPQFdBd0FHgE+AV4BfgGeBd4BPwFfBQEeVgG2AXcBtwEYAZgBWQF5AZkB2QH5AToBmgG6AdoBmwHbAfsBHAE8AVwBfAHcAR0BfQH9Ab4B/gF/AZ8B/wEIEjYBdgHWAfYBVwGXATgBWAHYAfgBGgFaAXoBuwGdAb0BHwG/Ad8BAQAFAAQKLwACIAJAAmACgAKgAsAC4AIBAiECQQJhAoECoQLBAuECAgIiAkICYgKCAqICwgLiAgMCIwJDAmMCgwKjAsMC4wIEAiQCRAJkAoQCpALEAuQCBQIlAkUCZQKFAqUCxQLlAgkPBwAXACcANwBHAFcAZwB3AIcAlwCnALcAxwDXAOcA9wAHExABUAWQBfAFUQWxAfEFcgXSBfIBEwFTBRQFVAV0AbQFNQV1BbUF1QUBFDABcAGwAREBMQFxAdEBEgEyAVIBkgGyATMBkwGzAdMBNAGUAdQBlQH1AQgG0AGRAXMB8wH0ARUBVQEAAAYACAkPAQARACEAMQBBAFEAYQBxAIEAkQChALEAwQDRAOEA8QAGBwMAIwBDAGMAgwCjAMMA4wAMBwQAJABEAGQAhACkAMQA5AAKVwUDJQNFA2UDhQOlA8UD5QMGAiYCRgJmAoYCpgLGAuYCBwInAkcCZwKHAqcCxwLnAggCKAJIAmgCiAKoAsgC6AIJAikCSQJpAokCqQLJAukCCgIqAkoCagKKAqoCygLqAgsCKwJLAmsCiwKrAssC6wIMAiwCTAJsAowCrALMAuwCDQItAk0CbQKNAq0CzQLtAg4CLgJOAm4CjgKuAs4C7gIPAi8CTwJvAo8CrwLPAu8CEwcTATMBUwFzAZMBswHTAfMBEAcUATQBVAF0AZQBtAHUAfQBBycVATUBVQF1AZUBtQHVAfUBVgWWAbYF1gE3AVcFtwX3BfgFGQWZAdkFOgF6AZoBugXaATsFWwVcBXwBnAW8BfwFPQWdBT4BngX+AX8BnwXfBQEdFgH2ARcB1wEYATgBeAGYAdgBWQF5AbkBGgFaAZsBuwH7ATwBHQF9Ab0B3QH9AR4BfgG+AR8BPwG/Af8BCBE2AXYBdwGXAVgBuAE5AfkB+gEbAXsB2wEcAdwBXQFeAd4BXwEBAAYABAovAAIgAkACYAKAAqACwALgAgECIQJBAmECgQKhAsEC4QICAiICQgJiAoICogLCAuICAwIjAkMCYwKDAqMCwwLjAgQCJAJEAmQChAKkAsQC5AIFAiUCRQJlAoUCpQLFAuUCCQ8HABcAJwA3AEcAVwBnAHcAhwCXAKcAtwDHANcA5wD3AAcUEAFwBbAFsQXRBfEFMgFSAZIF0gUTAVMF0wXzBRQFNAXUATUFVQWVBfUFAQ4wAVAB0AERATEBkQESAbIBMwGTAVQBdAGUAfQBtQEIC5AB8AFRAXEBcgHyAXMBswG0ARUBdQHVAQAABwAICQ8BABEAIQAxAEEAUQBhAHEAgQCRAKEAsQDBANEA4QDxAAYHAwAjAEMAYwCDAKMAwwDjAAwHBAAkAEQAZACEAKQAxADkAApXBQMlA0UDZQOFA6UDxQPlAwYCJgJGAmYChgKmAsYC5gIHAicCRwJnAocCpwLHAucCCAIoAkgCaAKIAqgCyALoAgkCKQJJAmkCiQKpAskC6QIKAioCSgJqAooCqgLKAuoCCwIrAksCawKLAqsCywLrAgwCLAJMAmwCjAKsAswC7AINAi0CTQJtAo0CrQLNAu0CDgIuAk4CbgKOAq4CzgLuAg8CLwJPAm8CjwKvAs8C7wITBxMBMwFTAXMBkwGzAdMB8wEQBxQBNAFUAXQBlAG0AdQB9AEHIxUBNQFVAXUBlQG1AdUB9QEWBdYBdwWXBRgBOAFYBXgBmAX4BVkFeQXZAdoBGwXbAZwF/AUdBX0F3QEeBV4FfgU/BV8FfwW/AQEgNgF2AZYBtgH2ARcBVwG3AfcBuAHYARkBuQH5ARoBOgF6AZoBugH6AbsB+wEcAbwB3AFdAb0B/QGeAd4BHwGfAd8BCBJWATcB1wE5AZkBWgE7AVsBewGbATwBXAF8AT0BnQE+Ab4B/gH/AQEABwAECi8AAiACQAJgAoACoALAAuACAQIhAkECYQKBAqECwQLhAgICIgJCAmICggKiAsIC4gIDAiMCQwJjAoMCowLDAuMCBAIkAkQCZAKEAqQCxALkAgUCJQJFAmUChQKlAsUC5QIJDwcAFwAnADcARwBXAGcAdwCHAJcApwC3AMcA1wDnAPcABxMQAdAFMQVRBXEBsQHxAVIFsgHyBXMB8wEUBXQF1AX0ARUFNQG1AfUBARgwAVABcAGQAbAB8AERAZEB0QESATIBcgGSAdIBEwEzAVMBkwGzAdMBNAGUAbQBlQHVAQgCVAFVAXUBAAAIAA4JDwEAEQAhADEAQQBRAGEAcQCBAZEBoQGxAcEA0QDhAPEABgEDAJ4BDAyTALMA8wAEACQAdAK0AbYFuAW6BbwFvgWfAQogMwBzBIMB4wBEAAUDJQM1BoUBBgJGA2YAxgMHAocBCAKIAqgC2AMJAnkDCgJ6AdoDCwJ7AwwCzAMNAg4C3gMPAn8DEwkTAeQA1QZXAtcGaALZBtsG3QbfBhANFAG1BOUDZwG3BOcHuQTpB7sE6we9BO0HvwTvBwcJFQFVAmUCFgEXARkBGgUcAR0BHgEBPNMAVALEAHUBpQFWAXYCpgHWACcDNwFHAJcDGAEoAzgBSANYASkDOQBJA1kBqQEqBjoBSgNaAWoDqgEbASsDOwFLA1sAawOrASwDPAJMAlwCbAOsAS0DPQBNAF0BbQCtAS4CPgFOA14AbgOuAR8BLwM/Ak8BXwJvA68BDgYjBuYDdwToA+oD7APuAwsJUwA0AUUBJgeGAZYCpwCYAWkDiQESAcMAZAINApQGeAF9BwMFowCEAtQAlQHIAnwCBAqaAcoCiwGbAIwBnAPcAI0BnQOOAs4CBQXFBMcEyQTLBM0EzwQBAAgADAoMAALAAwECAgLSAwMCBAKUAwUCtQLVAvUClgMJDwcAFwAnADcARwBXAGcAdwCHAJcApwC3AMcA1wDnAPcABwEQBRQFASogAzABUANgAKABEQEhAzEAUQFhA6EBEgEiAjIBQgNSAWIDkgOiARMBIwMzAUMDUwJjA3MBgwCjASQDNAFEA1QAZAB0AIQDFQElAzUCRQJVAmUCdQKFAwsCQAFBA6QBEAZwA5AAsQThB4IAswTjBxMEcQOBAZED0QbTBgwDgAGwBXIHsgUIALQBBQHBBMMEBAHQAMICDQDEBw4C4APiA9QHAAAJAAIJDQEAAgAEBAUEBgQHBAgECQQKBAsEDAQNBA4EDwQKCSADIgMTADMAJAMmAygDKgMsAy4DGAhDAFMAYwBEA1QDZANFA1UDZQMBAAkAAgkGAAQBBAIEAwAEAAYABwALABUCCgIgAyIDJAM=
