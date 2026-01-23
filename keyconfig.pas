{$mode objfpc}{$H+}
unit keyconfig;

interface

uses sdl2, sdlinput, api;

const
  { Количество основных действий (для всех игроков) }
  KC_MAXKEY = 8;
  KC_MAXPLAYERS = 3;

  { Индексы основных действий }
  KC_LEFT    = 1;
  KC_RIGHT   = 2;
  KC_JUMP    = 3;
  KC_DOWN    = 4;
  KC_ATTACK  = 5;
  KC_ATTACK2 = 6;
  KC_NEXT    = 7;
  KC_PREV    = 8;

  { Количество дополнительных действий (только игрок 1) }
  KC_MAXEXTRA = 20;

  { Индексы дополнительных действий }
  KC_BOTFOLLOW  = 1;   { Z - боты за мной }
  KC_BOTSTAND   = 2;   { X - стоять }
  KC_BOTATTACK  = 3;   { C - в атаку }
  KC_BOTFREEZE  = 4;   { V - замереть }
  KC_WEAP1      = 5;   { 1 }
  KC_WEAP2      = 6;   { 2 }
  KC_WEAP3      = 7;   { 3 }
  KC_WEAP4      = 8;   { 4 }
  KC_WEAP5      = 9;   { 5 }
  KC_WEAP6      = 10;  { 6 }
  KC_WEAP7      = 11;  { 7 }
  KC_WEAP8      = 12;  { 8 }
  KC_WEAP9      = 13;  { 9 }
  KC_SAVE       = 14;  { F2 }
  KC_LOAD       = 15;  { F3 }
  KC_FRAGS      = 16;  { F1 }
  KC_ANGLEUP    = 17;  { PgUp }
  KC_ANGLEDOWN  = 18;  { PgDn }
  KC_ANGLEHOME  = 19;  { Home }
  KC_ANGLEEND   = 20;  { End }

  { Имена основных действий для меню }
  KeyActionNames: array[1..KC_MAXKEY] of string[20] = (
    'Влево',
    'Вправо',
    'Прыжок',
    'Присесть',
    'Атака',
    'Альт.атака',
    'След.оружие',
    'Пред.оружие'
  );

  { Имена дополнительных действий }
  ExtraActionNames: array[1..KC_MAXEXTRA] of string[20] = (
    'За мной',
    'Стоять',
    'В атаку',
    'Замереть',
    'Оружие 1',
    'Оружие 2',
    'Оружие 3',
    'Оружие 4',
    'Оружие 5',
    'Оружие 6',
    'Оружие 7',
    'Оружие 8',
    'Оружие 9',
    'Сохранить',
    'Загрузить',
    'Фраги',
    'Угол вверх',
    'Угол вниз',
    'Угол Home',
    'Угол End'
  );

  { Имена профилей }
  ProfileNames: array[1..4] of string[12] = (
    'Стрелки',
    'WASD',
    'Numpad',
    'Свои'
  );

  { Таблица имён клавиш -> DOS scancode }
  KeyNameCount = 83;
  KeyNameTable: array[1..KeyNameCount] of record
    name: string[12];
    code: byte;
  end = (
    (name: 'Esc';       code: 1),
    (name: '1';         code: 2),
    (name: '2';         code: 3),
    (name: '3';         code: 4),
    (name: '4';         code: 5),
    (name: '5';         code: 6),
    (name: '6';         code: 7),
    (name: '7';         code: 8),
    (name: '8';         code: 9),
    (name: '9';         code: 10),
    (name: '0';         code: 11),
    (name: 'Minus';     code: 12),
    (name: 'Equals';    code: 13),
    (name: 'Backspace'; code: 14),
    (name: 'Tab';       code: 15),
    (name: 'Q';         code: 16),
    (name: 'W';         code: 17),
    (name: 'E';         code: 18),
    (name: 'R';         code: 19),
    (name: 'T';         code: 20),
    (name: 'Y';         code: 21),
    (name: 'U';         code: 22),
    (name: 'I';         code: 23),
    (name: 'O';         code: 24),
    (name: 'P';         code: 25),
    (name: 'LBracket';  code: 26),
    (name: 'RBracket';  code: 27),
    (name: 'Enter';     code: 28),
    (name: 'LCtrl';     code: 29),
    (name: 'A';         code: 30),
    (name: 'S';         code: 31),
    (name: 'D';         code: 32),
    (name: 'F';         code: 33),
    (name: 'G';         code: 34),
    (name: 'H';         code: 35),
    (name: 'J';         code: 36),
    (name: 'K';         code: 37),
    (name: 'L';         code: 38),
    (name: 'Semicolon'; code: 39),
    (name: 'Apostrophe';code: 40),
    (name: 'Grave';     code: 41),
    (name: 'LShift';    code: 42),
    (name: 'Backslash'; code: 43),
    (name: 'Z';         code: 44),
    (name: 'X';         code: 45),
    (name: 'C';         code: 46),
    (name: 'V';         code: 47),
    (name: 'B';         code: 48),
    (name: 'N';         code: 49),
    (name: 'M';         code: 50),
    (name: 'Comma';     code: 51),
    (name: 'Period';    code: 52),
    (name: 'Slash';     code: 53),
    (name: 'RShift';    code: 54),
    (name: 'NumMul';    code: 55),
    (name: 'LAlt';      code: 56),
    (name: 'Space';     code: 57),
    (name: 'CapsLock';  code: 58),
    (name: 'F1';        code: 59),
    (name: 'F2';        code: 60),
    (name: 'F3';        code: 61),
    (name: 'F4';        code: 62),
    (name: 'F5';        code: 63),
    (name: 'F6';        code: 64),
    (name: 'F7';        code: 65),
    (name: 'F8';        code: 66),
    (name: 'F9';        code: 67),
    (name: 'F10';       code: 68),
    (name: 'NumLock';   code: 69),
    (name: 'ScrollLock';code: 70),
    (name: 'Home';      code: 71),
    (name: 'Up';        code: 72),
    (name: 'PageUp';    code: 73),
    (name: 'NumMinus';  code: 74),
    (name: 'Left';      code: 75),
    (name: 'Num5';      code: 76),
    (name: 'Right';     code: 77),
    (name: 'NumPlus';   code: 78),
    (name: 'End';       code: 79),
    (name: 'Down';      code: 80),
    (name: 'PageDown';  code: 81),
    (name: 'Insert';    code: 82),
    (name: 'Delete';    code: 83)
  );

type
  TKeyProfile = array[1..KC_MAXKEY] of byte;
  TExtraKeys = array[1..KC_MAXEXTRA] of byte;

var
  { Пользовательские клавиши для 3 игроков }
  UserKeys: array[1..KC_MAXPLAYERS] of TKeyProfile;
  { Использовать свои клавиши (true) или встроенный профиль (false) }
  UseCustomKeys: array[1..KC_MAXPLAYERS] of boolean;
  { Дополнительные клавиши (только игрок 1) }
  ExtraKeys: TExtraKeys;
  { Использовать свои дополнительные клавиши }
  UseCustomExtra: boolean;

{ Основные процедуры }
procedure InitKeyConfig;
procedure LoadKeyConfig(const filename: string);
procedure SaveKeyConfig(const filename: string);
function WaitForKey: byte;

{ Конвертация имя <-> код }
function KeyNameToCode(const name: string): byte;
function KeyCodeToName(code: byte): string;

{ Получить клавишу для действия игрока }
function GetPlayerKey(player, action: integer): byte;
{ Получить дополнительную клавишу }
function GetExtraKey(action: integer): byte;

{ Встроенные профили клавиш по умолчанию }
const
  DefaultKeys: array[1..3, 1..KC_MAXKEY] of byte = (
    (75, 77, 72, 80, 29, 56, 28, 54),  { Профиль 1: Стрелки }
    (30, 32, 17, 31, 15, 58, 41, 16),  { Профиль 2: WASD }
    (79, 81, 76, 82, 78, 69, 74, 55)   { Профиль 3: Numpad }
  );

  { Дополнительные клавиши по умолчанию }
  DefaultExtra: TExtraKeys = (
    44,  { KC_BOTFOLLOW: Z }
    45,  { KC_BOTSTAND: X }
    46,  { KC_BOTATTACK: C }
    47,  { KC_BOTFREEZE: V }
    2,   { KC_WEAP1: 1 }
    3,   { KC_WEAP2: 2 }
    4,   { KC_WEAP3: 3 }
    5,   { KC_WEAP4: 4 }
    6,   { KC_WEAP5: 5 }
    7,   { KC_WEAP6: 6 }
    8,   { KC_WEAP7: 7 }
    9,   { KC_WEAP8: 8 }
    10,  { KC_WEAP9: 9 }
    60,  { KC_SAVE: F2 }
    61,  { KC_LOAD: F3 }
    59,  { KC_FRAGS: F1 }
    73,  { KC_ANGLEUP: PageUp }
    81,  { KC_ANGLEDOWN: PageDown }
    71,  { KC_ANGLEHOME: Home }
    79   { KC_ANGLEEND: End }
  );

implementation

{ Маппинг DOS scancode -> SDL scancode (копия из sdlinput.pas) }
const
  DOStoSDL: array[0..88] of integer = (
    0,                          { 0 - unused }
    SDL_SCANCODE_ESCAPE,        { 1 - Esc }
    SDL_SCANCODE_1,             { 2 - 1 }
    SDL_SCANCODE_2,             { 3 - 2 }
    SDL_SCANCODE_3,             { 4 - 3 }
    SDL_SCANCODE_4,             { 5 - 4 }
    SDL_SCANCODE_5,             { 6 - 5 }
    SDL_SCANCODE_6,             { 7 - 6 }
    SDL_SCANCODE_7,             { 8 - 7 }
    SDL_SCANCODE_8,             { 9 - 8 }
    SDL_SCANCODE_9,             { 10 - 9 }
    SDL_SCANCODE_0,             { 11 - 0 }
    SDL_SCANCODE_MINUS,         { 12 - - }
    SDL_SCANCODE_EQUALS,        { 13 - = }
    SDL_SCANCODE_BACKSPACE,     { 14 - Backspace }
    SDL_SCANCODE_TAB,           { 15 - Tab }
    SDL_SCANCODE_Q,             { 16 - Q }
    SDL_SCANCODE_W,             { 17 - W }
    SDL_SCANCODE_E,             { 18 - E }
    SDL_SCANCODE_R,             { 19 - R }
    SDL_SCANCODE_T,             { 20 - T }
    SDL_SCANCODE_Y,             { 21 - Y }
    SDL_SCANCODE_U,             { 22 - U }
    SDL_SCANCODE_I,             { 23 - I }
    SDL_SCANCODE_O,             { 24 - O }
    SDL_SCANCODE_P,             { 25 - P }
    SDL_SCANCODE_LEFTBRACKET,   { 26 - [ }
    SDL_SCANCODE_RIGHTBRACKET,  { 27 - ] }
    SDL_SCANCODE_RETURN,        { 28 - Enter }
    SDL_SCANCODE_LCTRL,         { 29 - Left Ctrl }
    SDL_SCANCODE_A,             { 30 - A }
    SDL_SCANCODE_S,             { 31 - S }
    SDL_SCANCODE_D,             { 32 - D }
    SDL_SCANCODE_F,             { 33 - F }
    SDL_SCANCODE_G,             { 34 - G }
    SDL_SCANCODE_H,             { 35 - H }
    SDL_SCANCODE_J,             { 36 - J }
    SDL_SCANCODE_K,             { 37 - K }
    SDL_SCANCODE_L,             { 38 - L }
    SDL_SCANCODE_SEMICOLON,     { 39 - ; }
    SDL_SCANCODE_APOSTROPHE,    { 40 - ' }
    SDL_SCANCODE_GRAVE,         { 41 - ` }
    SDL_SCANCODE_LSHIFT,        { 42 - Left Shift }
    SDL_SCANCODE_BACKSLASH,     { 43 - \ }
    SDL_SCANCODE_Z,             { 44 - Z }
    SDL_SCANCODE_X,             { 45 - X }
    SDL_SCANCODE_C,             { 46 - C }
    SDL_SCANCODE_V,             { 47 - V }
    SDL_SCANCODE_B,             { 48 - B }
    SDL_SCANCODE_N,             { 49 - N }
    SDL_SCANCODE_M,             { 50 - M }
    SDL_SCANCODE_COMMA,         { 51 - , }
    SDL_SCANCODE_PERIOD,        { 52 - . }
    SDL_SCANCODE_SLASH,         { 53 - / }
    SDL_SCANCODE_RSHIFT,        { 54 - Right Shift }
    SDL_SCANCODE_KP_MULTIPLY,   { 55 - Numpad * }
    SDL_SCANCODE_LALT,          { 56 - Left Alt }
    SDL_SCANCODE_SPACE,         { 57 - Space }
    SDL_SCANCODE_CAPSLOCK,      { 58 - Caps Lock }
    SDL_SCANCODE_F1,            { 59 - F1 }
    SDL_SCANCODE_F2,            { 60 - F2 }
    SDL_SCANCODE_F3,            { 61 - F3 }
    SDL_SCANCODE_F4,            { 62 - F4 }
    SDL_SCANCODE_F5,            { 63 - F5 }
    SDL_SCANCODE_F6,            { 64 - F6 }
    SDL_SCANCODE_F7,            { 65 - F7 }
    SDL_SCANCODE_F8,            { 66 - F8 }
    SDL_SCANCODE_F9,            { 67 - F9 }
    SDL_SCANCODE_F10,           { 68 - F10 }
    SDL_SCANCODE_NUMLOCKCLEAR,  { 69 - Num Lock }
    SDL_SCANCODE_SCROLLLOCK,    { 70 - Scroll Lock }
    SDL_SCANCODE_HOME,          { 71 - Home / Numpad 7 }
    SDL_SCANCODE_UP,            { 72 - Up / Numpad 8 }
    SDL_SCANCODE_PAGEUP,        { 73 - Page Up / Numpad 9 }
    SDL_SCANCODE_KP_MINUS,      { 74 - Numpad - }
    SDL_SCANCODE_LEFT,          { 75 - Left / Numpad 4 }
    SDL_SCANCODE_KP_5,          { 76 - Numpad 5 }
    SDL_SCANCODE_RIGHT,         { 77 - Right / Numpad 6 }
    SDL_SCANCODE_KP_PLUS,       { 78 - Numpad + }
    SDL_SCANCODE_END,           { 79 - End / Numpad 1 }
    SDL_SCANCODE_DOWN,          { 80 - Down / Numpad 2 }
    SDL_SCANCODE_PAGEDOWN,      { 81 - Page Down / Numpad 3 }
    SDL_SCANCODE_INSERT,        { 82 - Insert / Numpad 0 }
    SDL_SCANCODE_DELETE,        { 83 - Delete / Numpad . }
    0, 0, 0,                    { 84-86 - unused }
    SDL_SCANCODE_F11,           { 87 - F11 }
    SDL_SCANCODE_F12            { 88 - F12 }
  );

function KeyNameToCode(const name: string): byte;
var
  i: integer;
  lname: string;
begin
  lname := downcase(name);
  for i := 1 to KeyNameCount do
    if downcase(KeyNameTable[i].name) = lname then
    begin
      KeyNameToCode := KeyNameTable[i].code;
      exit;
    end;
  { Попробовать как число }
  KeyNameToCode := vl(name);
end;

function KeyCodeToName(code: byte): string;
var
  i: integer;
begin
  for i := 1 to KeyNameCount do
    if KeyNameTable[i].code = code then
    begin
      KeyCodeToName := KeyNameTable[i].name;
      exit;
    end;
  KeyCodeToName := st(code);
end;

procedure InitKeyConfig;
var
  i, j: integer;
begin
  { Инициализация пользовательских клавиш значениями по умолчанию }
  for i := 1 to KC_MAXPLAYERS do
  begin
    UseCustomKeys[i] := false;
    for j := 1 to KC_MAXKEY do
      UserKeys[i][j] := DefaultKeys[i][j];
  end;

  { Инициализация дополнительных клавиш }
  UseCustomExtra := false;
  ExtraKeys := DefaultExtra;
end;

procedure LoadKeyConfig(const filename: string);
var
  f: text;
  s, s1, s2: string;
  i, p: integer;
  section: integer; { 0=none, 1=Player1, 2=Player2, 3=Player3, 4=Extra }
begin
  assign(f, filename);
  {$i-} reset(f); {$i+}
  if ioresult <> 0 then exit;

  section := 0;
  while not eof(f) do
  begin
    readln(f, s);
    { Пропуск пустых строк и комментариев }
    if (s = '') or (s[1] = ';') or (s[1] = '/') then continue;

    { Проверка секции }
    if s[1] = '[' then
    begin
      s := downcase(s);
      if pos('[player1]', s) > 0 then section := 1
      else if pos('[player2]', s) > 0 then section := 2
      else if pos('[player3]', s) > 0 then section := 3
      else if pos('[extra]', s) > 0 then section := 4
      else section := 0;
      continue;
    end;

    { Парсинг key=value }
    p := pos('=', s);
    if p = 0 then continue;
    s1 := downcase(copy(s, 1, p - 1));
    s2 := copy(s, p + 1, length(s) - p);
    { Убираем пробелы }
    while (length(s1) > 0) and (s1[length(s1)] = ' ') do
      s1 := copy(s1, 1, length(s1) - 1);
    while (length(s2) > 0) and (s2[1] = ' ') do
      s2 := copy(s2, 2, length(s2) - 1);

    case section of
      1, 2, 3: { Player 1-3 }
        begin
          if s1 = 'custom' then
            UseCustomKeys[section] := (vl(s2) <> 0)
          else if s1 = 'left' then
            UserKeys[section][KC_LEFT] := KeyNameToCode(s2)
          else if s1 = 'right' then
            UserKeys[section][KC_RIGHT] := KeyNameToCode(s2)
          else if s1 = 'jump' then
            UserKeys[section][KC_JUMP] := KeyNameToCode(s2)
          else if s1 = 'down' then
            UserKeys[section][KC_DOWN] := KeyNameToCode(s2)
          else if s1 = 'attack' then
            UserKeys[section][KC_ATTACK] := KeyNameToCode(s2)
          else if s1 = 'attack2' then
            UserKeys[section][KC_ATTACK2] := KeyNameToCode(s2)
          else if s1 = 'next' then
            UserKeys[section][KC_NEXT] := KeyNameToCode(s2)
          else if s1 = 'prev' then
            UserKeys[section][KC_PREV] := KeyNameToCode(s2);
        end;
      4: { Extra }
        begin
          if s1 = 'custom' then
            UseCustomExtra := (vl(s2) <> 0)
          else if s1 = 'botfollow' then
            ExtraKeys[KC_BOTFOLLOW] := KeyNameToCode(s2)
          else if s1 = 'botstand' then
            ExtraKeys[KC_BOTSTAND] := KeyNameToCode(s2)
          else if s1 = 'botattack' then
            ExtraKeys[KC_BOTATTACK] := KeyNameToCode(s2)
          else if s1 = 'botfreeze' then
            ExtraKeys[KC_BOTFREEZE] := KeyNameToCode(s2)
          else if s1 = 'weap1' then
            ExtraKeys[KC_WEAP1] := KeyNameToCode(s2)
          else if s1 = 'weap2' then
            ExtraKeys[KC_WEAP2] := KeyNameToCode(s2)
          else if s1 = 'weap3' then
            ExtraKeys[KC_WEAP3] := KeyNameToCode(s2)
          else if s1 = 'weap4' then
            ExtraKeys[KC_WEAP4] := KeyNameToCode(s2)
          else if s1 = 'weap5' then
            ExtraKeys[KC_WEAP5] := KeyNameToCode(s2)
          else if s1 = 'weap6' then
            ExtraKeys[KC_WEAP6] := KeyNameToCode(s2)
          else if s1 = 'weap7' then
            ExtraKeys[KC_WEAP7] := KeyNameToCode(s2)
          else if s1 = 'weap8' then
            ExtraKeys[KC_WEAP8] := KeyNameToCode(s2)
          else if s1 = 'weap9' then
            ExtraKeys[KC_WEAP9] := KeyNameToCode(s2)
          else if s1 = 'save' then
            ExtraKeys[KC_SAVE] := KeyNameToCode(s2)
          else if s1 = 'load' then
            ExtraKeys[KC_LOAD] := KeyNameToCode(s2)
          else if s1 = 'frags' then
            ExtraKeys[KC_FRAGS] := KeyNameToCode(s2)
          else if s1 = 'angleup' then
            ExtraKeys[KC_ANGLEUP] := KeyNameToCode(s2)
          else if s1 = 'angledown' then
            ExtraKeys[KC_ANGLEDOWN] := KeyNameToCode(s2)
          else if s1 = 'anglehome' then
            ExtraKeys[KC_ANGLEHOME] := KeyNameToCode(s2)
          else if s1 = 'angleend' then
            ExtraKeys[KC_ANGLEEND] := KeyNameToCode(s2);
        end;
    end;
  end;
  close(f);
end;

procedure SaveKeyConfig(const filename: string);
var
  f: text;
  i: integer;
begin
  assign(f, filename);
  {$i-} rewrite(f); {$i+}
  if ioresult <> 0 then exit;

  writeln(f, '; Doom RF Key Configuration');
  writeln(f, '; Automatically generated');
  writeln(f);

  { Player 1 }
  writeln(f, '[Player1]');
  if UseCustomKeys[1] then writeln(f, 'custom=1') else writeln(f, 'custom=0');
  writeln(f, 'left=', KeyCodeToName(UserKeys[1][KC_LEFT]));
  writeln(f, 'right=', KeyCodeToName(UserKeys[1][KC_RIGHT]));
  writeln(f, 'jump=', KeyCodeToName(UserKeys[1][KC_JUMP]));
  writeln(f, 'down=', KeyCodeToName(UserKeys[1][KC_DOWN]));
  writeln(f, 'attack=', KeyCodeToName(UserKeys[1][KC_ATTACK]));
  writeln(f, 'attack2=', KeyCodeToName(UserKeys[1][KC_ATTACK2]));
  writeln(f, 'next=', KeyCodeToName(UserKeys[1][KC_NEXT]));
  writeln(f, 'prev=', KeyCodeToName(UserKeys[1][KC_PREV]));
  writeln(f);

  { Player 2 }
  writeln(f, '[Player2]');
  if UseCustomKeys[2] then writeln(f, 'custom=1') else writeln(f, 'custom=0');
  writeln(f, 'left=', KeyCodeToName(UserKeys[2][KC_LEFT]));
  writeln(f, 'right=', KeyCodeToName(UserKeys[2][KC_RIGHT]));
  writeln(f, 'jump=', KeyCodeToName(UserKeys[2][KC_JUMP]));
  writeln(f, 'down=', KeyCodeToName(UserKeys[2][KC_DOWN]));
  writeln(f, 'attack=', KeyCodeToName(UserKeys[2][KC_ATTACK]));
  writeln(f, 'attack2=', KeyCodeToName(UserKeys[2][KC_ATTACK2]));
  writeln(f, 'next=', KeyCodeToName(UserKeys[2][KC_NEXT]));
  writeln(f, 'prev=', KeyCodeToName(UserKeys[2][KC_PREV]));
  writeln(f);

  { Player 3 }
  writeln(f, '[Player3]');
  if UseCustomKeys[3] then writeln(f, 'custom=1') else writeln(f, 'custom=0');
  writeln(f, 'left=', KeyCodeToName(UserKeys[3][KC_LEFT]));
  writeln(f, 'right=', KeyCodeToName(UserKeys[3][KC_RIGHT]));
  writeln(f, 'jump=', KeyCodeToName(UserKeys[3][KC_JUMP]));
  writeln(f, 'down=', KeyCodeToName(UserKeys[3][KC_DOWN]));
  writeln(f, 'attack=', KeyCodeToName(UserKeys[3][KC_ATTACK]));
  writeln(f, 'attack2=', KeyCodeToName(UserKeys[3][KC_ATTACK2]));
  writeln(f, 'next=', KeyCodeToName(UserKeys[3][KC_NEXT]));
  writeln(f, 'prev=', KeyCodeToName(UserKeys[3][KC_PREV]));
  writeln(f);

  { Extra keys }
  writeln(f, '[Extra]');
  if UseCustomExtra then writeln(f, 'custom=1') else writeln(f, 'custom=0');
  writeln(f, '; Bot commands');
  writeln(f, 'botfollow=', KeyCodeToName(ExtraKeys[KC_BOTFOLLOW]));
  writeln(f, 'botstand=', KeyCodeToName(ExtraKeys[KC_BOTSTAND]));
  writeln(f, 'botattack=', KeyCodeToName(ExtraKeys[KC_BOTATTACK]));
  writeln(f, 'botfreeze=', KeyCodeToName(ExtraKeys[KC_BOTFREEZE]));
  writeln(f, '; Weapon selection');
  writeln(f, 'weap1=', KeyCodeToName(ExtraKeys[KC_WEAP1]));
  writeln(f, 'weap2=', KeyCodeToName(ExtraKeys[KC_WEAP2]));
  writeln(f, 'weap3=', KeyCodeToName(ExtraKeys[KC_WEAP3]));
  writeln(f, 'weap4=', KeyCodeToName(ExtraKeys[KC_WEAP4]));
  writeln(f, 'weap5=', KeyCodeToName(ExtraKeys[KC_WEAP5]));
  writeln(f, 'weap6=', KeyCodeToName(ExtraKeys[KC_WEAP6]));
  writeln(f, 'weap7=', KeyCodeToName(ExtraKeys[KC_WEAP7]));
  writeln(f, 'weap8=', KeyCodeToName(ExtraKeys[KC_WEAP8]));
  writeln(f, 'weap9=', KeyCodeToName(ExtraKeys[KC_WEAP9]));
  writeln(f, '; System');
  writeln(f, 'save=', KeyCodeToName(ExtraKeys[KC_SAVE]));
  writeln(f, 'load=', KeyCodeToName(ExtraKeys[KC_LOAD]));
  writeln(f, 'frags=', KeyCodeToName(ExtraKeys[KC_FRAGS]));
  writeln(f, '; Sniper angle');
  writeln(f, 'angleup=', KeyCodeToName(ExtraKeys[KC_ANGLEUP]));
  writeln(f, 'angledown=', KeyCodeToName(ExtraKeys[KC_ANGLEDOWN]));
  writeln(f, 'anglehome=', KeyCodeToName(ExtraKeys[KC_ANGLEHOME]));
  writeln(f, 'angleend=', KeyCodeToName(ExtraKeys[KC_ANGLEEND]));

  close(f);
end;

function WaitForKey: byte;
var
  event: TSDL_Event;
  i: integer;
  sdlCode: TSDL_Scancode;
begin
  WaitForKey := 0;

  { Очистить буфер событий }
  while SDL_PollEvent(@event) <> 0 do;

  { Ждать нажатия }
  repeat
    if SDL_WaitEvent(@event) <> 0 then
    begin
      case event.type_ of
        SDL_KEYDOWN:
          begin
            sdlCode := event.key.keysym.scancode;
            { ESC - отмена }
            if sdlCode = SDL_SCANCODE_ESCAPE then
            begin
              WaitForKey := 0;
              exit;
            end;
            { Найти DOS код для SDL scancode }
            for i := 1 to 88 do
              if DOStoSDL[i] = sdlCode then
              begin
                WaitForKey := i;
                exit;
              end;
          end;
        SDL_QUITEV:
          begin
            quit_requested := true;
            exit;
          end;
      end;
    end;
  until quit_requested;
end;

function GetPlayerKey(player, action: integer): byte;
begin
  if (player < 1) or (player > KC_MAXPLAYERS) then
  begin
    GetPlayerKey := 0;
    exit;
  end;
  if (action < 1) or (action > KC_MAXKEY) then
  begin
    GetPlayerKey := 0;
    exit;
  end;

  if UseCustomKeys[player] then
    GetPlayerKey := UserKeys[player][action]
  else
    GetPlayerKey := DefaultKeys[player][action];
end;

function GetExtraKey(action: integer): byte;
begin
  if (action < 1) or (action > KC_MAXEXTRA) then
  begin
    GetExtraKey := 0;
    exit;
  end;

  if UseCustomExtra then
    GetExtraKey := ExtraKeys[action]
  else
    GetExtraKey := DefaultExtra[action];
end;

end.
