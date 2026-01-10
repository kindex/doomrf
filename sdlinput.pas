{$mode objfpc}{$H+}
unit sdlinput;

interface

uses sdl2;

type
  mouseType = (twoButton, threeButton, another);

var
  // Keyboard state (DOS scancodes)
  pkey: array[0..255] of boolean;

  // Mouse state
  mouse_present: boolean;
  mouse_buttons: mouseType;
  ddx, ddy: longint;
  mouseCursorLevel: integer;

  // Quit flag
  quit_requested: boolean;

// Mouse functions (compatible with mouse.pas)
procedure initMouse;
procedure show;
procedure hide;
function X: word;
function Y: word;
function push: boolean;
function push2: boolean;
function push3: boolean;
function down(Button: byte): boolean;
function buttonPressed: boolean;
procedure setMouseCursor(ax, ay: word);
procedure mouseBox(left, top, right, bottom: word);
procedure Sensetivity(sx, sy: word);

// Keyboard functions (compatible with mycrt.pas)
function ReadKey: char;
function KeyPressed: boolean;
procedure Delay(ms: word);

// SDL event processing - call this every frame
procedure PollEvents;

// Initialize input system
procedure InitInput;

implementation

var
  mouseX, mouseY: integer;
  mouseButtonState: UInt32;
  keyBuffer: array[0..255] of char;
  keyHead, keyTail: integer;

// DOS scancode to SDL scancode mapping
const
  DOStoSDL: array[0..127] of integer = (
    0,                          // 0 - unused
    SDL_SCANCODE_ESCAPE,        // 1 - Esc
    SDL_SCANCODE_1,             // 2 - 1
    SDL_SCANCODE_2,             // 3 - 2
    SDL_SCANCODE_3,             // 4 - 3
    SDL_SCANCODE_4,             // 5 - 4
    SDL_SCANCODE_5,             // 6 - 5
    SDL_SCANCODE_6,             // 7 - 6
    SDL_SCANCODE_7,             // 8 - 7
    SDL_SCANCODE_8,             // 9 - 8
    SDL_SCANCODE_9,             // 10 - 9
    SDL_SCANCODE_0,             // 11 - 0
    SDL_SCANCODE_MINUS,         // 12 - -
    SDL_SCANCODE_EQUALS,        // 13 - =
    SDL_SCANCODE_BACKSPACE,     // 14 - Backspace
    SDL_SCANCODE_TAB,           // 15 - Tab
    SDL_SCANCODE_Q,             // 16 - Q
    SDL_SCANCODE_W,             // 17 - W
    SDL_SCANCODE_E,             // 18 - E
    SDL_SCANCODE_R,             // 19 - R
    SDL_SCANCODE_T,             // 20 - T
    SDL_SCANCODE_Y,             // 21 - Y
    SDL_SCANCODE_U,             // 22 - U
    SDL_SCANCODE_I,             // 23 - I
    SDL_SCANCODE_O,             // 24 - O
    SDL_SCANCODE_P,             // 25 - P
    SDL_SCANCODE_LEFTBRACKET,   // 26 - [
    SDL_SCANCODE_RIGHTBRACKET,  // 27 - ]
    SDL_SCANCODE_RETURN,        // 28 - Enter
    SDL_SCANCODE_LCTRL,         // 29 - Left Ctrl
    SDL_SCANCODE_A,             // 30 - A
    SDL_SCANCODE_S,             // 31 - S
    SDL_SCANCODE_D,             // 32 - D
    SDL_SCANCODE_F,             // 33 - F
    SDL_SCANCODE_G,             // 34 - G
    SDL_SCANCODE_H,             // 35 - H
    SDL_SCANCODE_J,             // 36 - J
    SDL_SCANCODE_K,             // 37 - K
    SDL_SCANCODE_L,             // 38 - L
    SDL_SCANCODE_SEMICOLON,     // 39 - ;
    SDL_SCANCODE_APOSTROPHE,    // 40 - '
    SDL_SCANCODE_GRAVE,         // 41 - `
    SDL_SCANCODE_LSHIFT,        // 42 - Left Shift
    SDL_SCANCODE_BACKSLASH,     // 43 - \
    SDL_SCANCODE_Z,             // 44 - Z
    SDL_SCANCODE_X,             // 45 - X
    SDL_SCANCODE_C,             // 46 - C
    SDL_SCANCODE_V,             // 47 - V
    SDL_SCANCODE_B,             // 48 - B
    SDL_SCANCODE_N,             // 49 - N
    SDL_SCANCODE_M,             // 50 - M
    SDL_SCANCODE_COMMA,         // 51 - ,
    SDL_SCANCODE_PERIOD,        // 52 - .
    SDL_SCANCODE_SLASH,         // 53 - /
    SDL_SCANCODE_RSHIFT,        // 54 - Right Shift
    SDL_SCANCODE_KP_MULTIPLY,   // 55 - Numpad *
    SDL_SCANCODE_LALT,          // 56 - Left Alt
    SDL_SCANCODE_SPACE,         // 57 - Space
    SDL_SCANCODE_CAPSLOCK,      // 58 - Caps Lock
    SDL_SCANCODE_F1,            // 59 - F1
    SDL_SCANCODE_F2,            // 60 - F2
    SDL_SCANCODE_F3,            // 61 - F3
    SDL_SCANCODE_F4,            // 62 - F4
    SDL_SCANCODE_F5,            // 63 - F5
    SDL_SCANCODE_F6,            // 64 - F6
    SDL_SCANCODE_F7,            // 65 - F7
    SDL_SCANCODE_F8,            // 66 - F8
    SDL_SCANCODE_F9,            // 67 - F9
    SDL_SCANCODE_F10,           // 68 - F10
    SDL_SCANCODE_NUMLOCKCLEAR,  // 69 - Num Lock
    SDL_SCANCODE_SCROLLLOCK,    // 70 - Scroll Lock
    SDL_SCANCODE_HOME,          // 71 - Home / Numpad 7
    SDL_SCANCODE_UP,            // 72 - Up / Numpad 8
    SDL_SCANCODE_PAGEUP,        // 73 - Page Up / Numpad 9
    SDL_SCANCODE_KP_MINUS,      // 74 - Numpad -
    SDL_SCANCODE_LEFT,          // 75 - Left / Numpad 4
    SDL_SCANCODE_KP_5,          // 76 - Numpad 5
    SDL_SCANCODE_RIGHT,         // 77 - Right / Numpad 6
    SDL_SCANCODE_KP_PLUS,       // 78 - Numpad +
    SDL_SCANCODE_END,           // 79 - End / Numpad 1
    SDL_SCANCODE_DOWN,          // 80 - Down / Numpad 2
    SDL_SCANCODE_PAGEDOWN,      // 81 - Page Down / Numpad 3
    SDL_SCANCODE_INSERT,        // 82 - Insert / Numpad 0
    SDL_SCANCODE_DELETE,        // 83 - Delete / Numpad .
    0, 0, 0,                    // 84-86 - unused
    SDL_SCANCODE_F11,           // 87 - F11
    SDL_SCANCODE_F12,           // 88 - F12
    0, 0, 0, 0, 0, 0, 0, 0,     // 89-96 - unused
    0, 0, 0, 0, 0, 0, 0, 0,     // 97-104
    0, 0, 0, 0, 0, 0, 0, 0,     // 105-112
    0, 0, 0, 0, 0, 0, 0, 0,     // 113-120
    0, 0, 0, 0, 0, 0, 0         // 121-127
  );

procedure UpdateKeyboardState;
var
  state: PUint8;
  i, sdlCode: integer;
begin
  SDL_PumpEvents;
  state := SDL_GetKeyboardState(nil);

  // Map SDL scancodes to DOS scancodes
  for i := 0 to 127 do
  begin
    sdlCode := DOStoSDL[i];
    if sdlCode > 0 then
      pkey[i] := state[sdlCode] <> 0
    else
      pkey[i] := false;
  end;
end;

function SDLKeyToChar(const keysym: TSDL_Keysym): char;
begin
  Result := #0;

  // Handle printable ASCII characters
  if (keysym.sym >= 32) and (keysym.sym <= 126) then
  begin
    Result := char(keysym.sym);
    // Handle shift for letters
    if (keysym.mod_ and KMOD_SHIFT) <> 0 then
    begin
      if (Result >= 'a') and (Result <= 'z') then
        Result := UpCase(Result);
    end;
  end
  else
  begin
    // Special keys
    case keysym.sym of
      SDLK_RETURN: Result := #13;
      SDLK_ESCAPE: Result := #27;
      SDLK_BACKSPACE: Result := #8;
      SDLK_TAB: Result := #9;
    end;
  end;
end;

procedure PollEvents;
var
  event: TSDL_Event;
  ch: char;
begin
  while SDL_PollEvent(@event) <> 0 do
  begin
    case event.type_ of
      SDL_QUITEV:
        quit_requested := true;

      SDL_KEYDOWN:
      begin
        // Handle extended keys (arrows, function keys) - DOS style: #0 + scancode
        case event.key.keysym.sym of
          SDLK_UP: begin
            keyBuffer[keyHead] := #0; keyHead := (keyHead + 1) mod 256;
            keyBuffer[keyHead] := #72; keyHead := (keyHead + 1) mod 256;
          end;
          SDLK_DOWN: begin
            keyBuffer[keyHead] := #0; keyHead := (keyHead + 1) mod 256;
            keyBuffer[keyHead] := #80; keyHead := (keyHead + 1) mod 256;
          end;
          SDLK_LEFT: begin
            keyBuffer[keyHead] := #0; keyHead := (keyHead + 1) mod 256;
            keyBuffer[keyHead] := #75; keyHead := (keyHead + 1) mod 256;
          end;
          SDLK_RIGHT: begin
            keyBuffer[keyHead] := #0; keyHead := (keyHead + 1) mod 256;
            keyBuffer[keyHead] := #77; keyHead := (keyHead + 1) mod 256;
          end;
          SDLK_PAGEUP: begin
            keyBuffer[keyHead] := #0; keyHead := (keyHead + 1) mod 256;
            keyBuffer[keyHead] := #73; keyHead := (keyHead + 1) mod 256;
          end;
          SDLK_PAGEDOWN: begin
            keyBuffer[keyHead] := #0; keyHead := (keyHead + 1) mod 256;
            keyBuffer[keyHead] := #81; keyHead := (keyHead + 1) mod 256;
          end;
        else
          // Regular keys
          ch := SDLKeyToChar(event.key.keysym);
          if ch <> #0 then
          begin
            keyBuffer[keyHead] := ch;
            keyHead := (keyHead + 1) mod 256;
          end;
        end;
      end;

      SDL_MOUSEMOTION:
      begin
        mouseX := event.motion.x;
        mouseY := event.motion.y;
      end;

      SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP:
        mouseButtonState := SDL_GetMouseState(@mouseX, @mouseY);
    end;
  end;

  // Update keyboard state array
  UpdateKeyboardState;

  // Update mouse button state
  mouseButtonState := SDL_GetMouseState(@mouseX, @mouseY);
end;

procedure InitInput;
var
  i: integer;
begin
  for i := 0 to 255 do
    pkey[i] := false;

  keyHead := 0;
  keyTail := 0;
  mouseX := 0;
  mouseY := 0;
  mouseButtonState := 0;
  quit_requested := false;

  initMouse;
end;

// Mouse implementation

procedure initMouse;
begin
  mouse_present := true;
  mouse_buttons := threeButton;
  ddx := 1;
  ddy := 1;
  mouseCursorLevel := 0;
end;

procedure show;
begin
  SDL_ShowCursor(SDL_ENABLE);
  Inc(mouseCursorLevel);
end;

procedure hide;
begin
  SDL_ShowCursor(SDL_DISABLE);
  Dec(mouseCursorLevel);
end;

function X: word;
begin
  X := mouseX div ddx;
end;

function Y: word;
begin
  Y := mouseY div ddy;
end;

function push: boolean;
begin
  push := (mouseButtonState and SDL_BUTTON_LMASK) <> 0;
end;

function push2: boolean;
begin
  push2 := (mouseButtonState and SDL_BUTTON_RMASK) <> 0;
end;

function push3: boolean;
begin
  push3 := (mouseButtonState and SDL_BUTTON_MMASK) <> 0;
end;

function down(Button: byte): boolean;
begin
  case Button of
    1: down := push;
    2: down := push2;
    4: down := push3;
    else down := false;
  end;
end;

function buttonPressed: boolean;
begin
  buttonPressed := (mouseButtonState and 7) <> 0;
end;

procedure setMouseCursor(ax, ay: word);
begin
  SDL_WarpMouseInWindow(nil, ax * ddx, ay * ddy);
  mouseX := ax * ddx;
  mouseY := ay * ddy;
end;

procedure mouseBox(left, top, right, bottom: word);
begin
  // SDL2 doesn't have direct mouse confinement like DOS
  // Would need SDL_SetWindowGrab or custom clamping
end;

procedure Sensetivity(sx, sy: word);
begin
  // SDL2 uses system mouse sensitivity
  // This is a no-op in modern systems
end;

// Keyboard implementation

function KeyPressed: boolean;
begin
  PollEvents;
  KeyPressed := keyHead <> keyTail;
end;

function ReadKey: char;
begin
  while not KeyPressed do
  begin
    SDL_Delay(10);
    if quit_requested then
    begin
      ReadKey := #27;  // Return ESC on quit
      Exit;
    end;
  end;

  ReadKey := keyBuffer[keyTail];
  keyTail := (keyTail + 1) mod 256;
end;

procedure Delay(ms: word);
begin
  SDL_Delay(ms);
end;

initialization
  InitInput;

end.