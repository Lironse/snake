IDEAL
MODEL small
STACK 100h

DATASEG
  loc dw 2000, 300 dup(?) ; snake body
  len dw 2 ; snake body length
  dir db ? ; moving direction
  rnd dw ? ; random number
  msg db 'you died. $' ; endscreen message

CODESEG
;-----------------------screen displayed when player dies----------------------------
;IN: offset msg, offset rnd
;OUT: nones
    proc endScreen
      push bp
      mov bp, sp
      push ax
      push bx
      push dx
      push cx

      push [bp+6] ; push offset rnd
      call clear
      mov di, 1990
      mov bx, [bp+4] ; [bp+4] = offset msg

      print:
        mov al, [bx]
        cmp al, '$'
        jz exitGame
        mov ah, 0c0h
        mov [es:di], ax
        inc bx
        add di, 2
        jmp print

      exitGame:
        mov ah, 4ch
        int 21h ; end

      pop cx
      pop dx
      pop bx
      pop ax
      pop bp
      ret 4
      endp endScreen
;------------------------------------------------------------------------------------------------------------

;-----------------------check if food is available, if available: increase snake length, generate new food---
;IN: offset rnd, location, offset len
;OUT: none
    proc eat
      push bp
      mov bp, sp
      push bx
      push cx

      eatCheck:
        mov bx, [bp+4] ; [bp+4] = food ptr
        mov bx, [bx] ; bx = food location
        cmp bx, [bp+6] ; check if head on food loc, [bp+6]=head location
        jne eatSkip

      newFood: ; generate new food
        push [bp+4]
        call random
        mov bx, [bp+8] ; bp+8 = len offset
        mov cx, [bx] ; cx = len
        inc cx ; inc snake length
        mov [bx], cx ; update len

      eatSkip:
        pop cx
        pop bx
        pop bp
        ret 6
      endp eat
;------------------------------------------------------------------------------------------------------------

;-----------------------; generate random number between 0-4000----------------------------------------------
;IN: offset rnd
;OUT: none
    proc random
      push bp
      mov bp, sp
      push ax
      push bx
      push cx
      push dx
      push di
      push es

      xoroshift: ; random algorightm

        time:
          mov ax, 40h ; getting the time
          mov es, ax
          mov ax, [es:6Ch]

        algo:
          xor ah, al ; xoroshift 16+ algorithm
          mov cl, al
          rol cl, 1
    		  rol cl, 1
    		  rol cl, 1
    		  rol cl, 1
    		  rol cl, 1
    		  rol cl, 1
          xor cl, ah
          mov ch, cl
          shl ch, 1
          xor cl, ch
          mov al, cl
          mov ch, ah
          rol ch, 1
    		  rol ch, 1
    		  rol ch, 1
          mov ah, ch ; random number goes to AX
          mov dx, 0
          mov cx, 2000
          div cx
          shl dx, 1
          mov ax, dx ; random number is between 0-4000

          mov bx, 0
          
          algoCheck:
          cmp [bx], ax
          jz algo
          inc bx
          cmp bx, 300
          jnz algoCheck

      mov bx, [bp+4] ; [bp+4] = rnd ptr
      mov [bx], ax ; place new number in rnd variable

      pop es
      pop di
      pop dx
      pop cx
      pop bx
      pop ax
      pop bp
      ret 2
      endp random
;------------------------------------------------------------------------------------------------------------

;-----------------------; clear the entire screen and replace food-------------------------------------------
;IN: offset rnd
;OUT: none
    proc clear
      push bp
      mov bp, sp
      push di
      push bx
      mov di, 0

      clearLoop:
        mov [es:di], 0C020h
        add di, 2
        cmp di, 4002
        jne clearLoop

      placeFood:
        mov bx, [bp+4] ; [bp+4] = rnd location
        mov di, [bx]
        mov [es:di], 0ce4fh ; place food

      pop bx
      pop di
      pop bp
      ret 2
      endp clear
;------------------------------------------------------------------------------------------------------------

;-------------------------display initial snake-------------------------------------------
;IN: none
;OUT: none
    proc firstSnake ;
      push di
      mov di, 2000
      mov [es:di], 0ca99h ; head
      mov di, 2002
      mov [es:di], 0cafeh ; body
      mov di, 2004
      mov [es:di], 0cafeh ; tail
      pop di
      ret
      endp firstSnake
;------------------------------------------------------------------------------------------------------------

;-------------------------; set the new locations of the snake's body and head-------------------------------
;IN: offset msg, new head location, offset rnd, len
;OUT: none
    proc set ; set the new locations of the snake's body and head
      push bp
      mov bp, sp
      push bx
      push di
      push ax

      push [bp+8]
      call clear

      mov bx, [bp+10] ; getting the last cell of snake, [bp+8] = len
      shl bx, 1

      setBody:
        mov dx, [bx-2] ; getting the value of previous cell, moving it to next
        mov [bx], dx
        mov di, [bx]
        mov [es:di], 0cafeh ; set cell
        sub bx, 2
        cmp bx, 0
        jnz setBody ; check if reached head

      collision: ; check if check is eating itself
        mov di, [bp+6] ; head location
        mov bx, [es:di]
        cmp bl, 0feh
        jne setHead

        push [bp+8] ; rnd
        push [bp+4] ; msg
        call endScreen

      setHead:
        mov di, [bp+6] ; [bp+6] = new head location
        mov [es:di], 0ca99h

        pop ax
        pop di
        pop bx
        pop bp
        ret 8
      endp set
;------------------------------------------------------------------------------------------------------------

;-------------------------delay------------------------------------------------------------------------------
;IN: none
;OUT: none
    proc delay ; create delay with loops
      push cx
      mov cx, 100
      d1:
      push cx
      mov cx, 0FFFFh
      d2:
      loop d2
      pop cx
      loop d1
      pop cx
      ret
      endp delay
;------------------------------------------------------------------------------------------------------------

;-------------------------update head location when w key is pressed-----------------------------------------
;IN: offset loc, offset rnd, len, offset msg
;OUT: none
    proc up
      push bp
      mov bp, sp
      push di
      push bx

      checkUp:
        mov bx, [bp+4]
        mov di, [bx]
        cmp di, 160
        jl endUp

      setUp:
        sub di, 160
        push [bp+8] ; len
        push [bp+6] ; offset rnd
        push di ; new head location
        push [bp+10] ; offset msg
        call set
        mov [bx], di
        jmp upSkip

      endUp:
        push [bp+6]
        push [bp+10]
        call endScreen

      upSkip:
        pop bx
        pop di
        pop bp
        ret 8
      endp up
;------------------------------------------------------------------------------------------------------------

;-------------------------update head location when a key is pressed-----------------------------------------
;IN: offset loc, offset rnd, len, offset msg
;OUT: none
    proc left
      push bp
      mov bp, sp
      push di
      push bx
      push ax
      push dx

      checkLeft:
        mov bx, [bp+4]
        mov di, [bx]
        mov ax, di
        mov dx, 0
        mov bx, 160
        div bx
        cmp dx, 0
        jz endLeft

      setLeft:
        sub di, 2
        push [bp+8] ; len
        push [bp+6] ; offset rnd
        push di ; new head location
        push [bp+10] ; offset msg
        call set
        mov bx, [bp+4]
        mov [bx], di
        jmp leftSkip

      endLeft:
        push [bp+6]
        push [bp+10]
        call endScreen

      leftSkip:
        pop dx
        pop ax
        pop bx
        pop di
        pop bp
        ret 8
      endp left
;------------------------------------------------------------------------------------------------------------

;-------------------------update head location when s key is pressed-----------------------------------------
;IN: offset loc, offset rnd, len, offset msg
;OUT: none
    proc down
      push bp
      mov bp, sp
      push di
      push bx

      checkDown:
        mov bx, [bp+4]
        mov di, [bx]
        cmp di, 3839
        jg endDown

      setDown:
        add di, 160
        push [bp+8] ; len
        push [bp+6] ; offset rnd
        push di ; new head location
        push [bp+10] ; offset msg
        call set
        mov [bx], di
        jmp downSkip

      endDown:
        push [bp+6] ; offset rnd
        push [bp+10] ; msg
        call endScreen

      downSkip:
        pop bx
        pop di
        pop bp
        ret 8
      endp down
;------------------------------------------------------------------------------------------------------------

;-------------------------update head location when d key is pressed-----------------------------------------
;IN: offset loc, offset rnd, len, offset msg
;OUT: none
    proc right
      push bp
      mov bp, sp
      push di
      push bx
      push ax
      push dx

      checkRight:
        mov bx, [bp+4]
        mov di, [bx]
        mov ax, di
        mov dx, 0
        mov bx, 160
        div bx
        cmp dx, 158
        jz endRight

      setRight:
        add di, 2
        push [bp+8] ; len
        push [bp+6] ; offset rnd
        push di ; new head location
        push [bp+10] ; offset msg
        call set
        mov bx, [bp+4]
        mov [bx], di
        jmp rightSkip

      endRight:
        push [bp+6] ; offset rnd
        push [bp+10] ; msg
        call endScreen

      rightSkip:
        pop dx
        pop ax
        pop bx
        pop di
        pop bp
        ret 8
      endp right
;------------------------------------------------------------------------------------------------------------


;--------------------------------------------MAIN------------------------------------------------------------
  main:
    start: ; set up segments
      mov ax, @data
      mov ds, ax ; data segment
      mov ax, 0b800h
      mov es, ax ; extra segment

    advDisp: ; make use of all 16 colors, and stop blinking text
      push ax
      push bx
      mov bx, 0
      mov ax, 1003h
      int 10h
      pop bx
      pop ax

    initialSetup: ; set up the initial screen
      mov bx, offset rnd
      push bx
      call random
      call clear
      call firstSnake

    input: ; send inputs to procs
      mov bx, offset msg ; bp+10
      push bx
      mov bx, offset len ; bp+8
      push [bx]
      mov bx, offset rnd ; bp+6
      push bx
      mov bx, offset loc ; bp+4
      push bx

      call delay

      key: ; check if a new key had been entered
        mov ah, 1
        int 16h
        jnz newKey

        mov al, [dir]
        jmp w

    newKey: ; new direction
      mov ax, 0
      int 16h ; new key in al
      mov [dir], al ; save new direction

    w: ; move up
      cmp al, 'w'
      jnz a
      call up

    a: ; move left
      cmp al, 'a'
      jnz s
      call left

    s: ; move down
      cmp al, 's'
      jnz d
      call down

    d: ; move right
      cmp al, 'd'
      jnz q
      call right

    q: ; quit game
      cmp al, 'q'
      jz exit

      food: ; tranfer variables to eat proc with blackboxing
        mov bx, offset len ; bp+8
        push bx
        mov bx, offset loc ; bp+6
        push [bx]
        mov bx, offset rnd ; bp+4
        push bx
        call eat

      jmp input

    exit:
        mov ax, 4c00h
        int 21h
        END start
