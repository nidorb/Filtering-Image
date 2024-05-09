section .bss
  varX resd 1
  varY resd 1
  varWindow resd 1
  varAvgCount resd 1
  varPixelGap resd 1

section .data
  varCurrent dd 0
  varCounter dd 0
  varOffset dd 0
  varInner dd 0
  varOuter dd 0
  varQuotient dd 0
  varRemainder dd 0
  varTotal dd 0

section .text

global _imgAvgFilter
_imgAvgFilter:
  push ebp
  mov ebp, esp ; enter
  
  mov esi, [ebp+8] ; int * input_image
  mov edi, [ebp+12] ; int * output_image
  mov eax, [ebp+16] ; int image_size_x
  mov ebx, [ebp+20] ; int image_size_y
  mov ecx, [ebp+24] ; int sampling_window_size

  mov dword[varX], eax
  mov dword[varY], ebx
  mov dword[varWindow], ecx
  mov eax, ecx
  mul ecx
  mov dword[varAvgCount], eax

  ; copy for now, since we're preserving edges
  mov eax, [varX]
  mul ebx ; get array size
  xor edx, edx
  mov edx, eax ; keep in array size in edx
  mov ecx, 0
  
COPY:
  mov eax, [esi]
  mov [edi], eax
  add esi, 4
  add edi, 4
  inc ecx
  cmp edx, ecx
  JNE COPY 
  ; reset when done
  mov esi, [ebp+8]
  mov edi, [ebp+12]

BIG:
    mov eax, [varX]
    mov ebx, [varY]
    mov ecx, [varWindow]
    cmp eax, ecx
    JL FIN
    cmp ebx, ecx
    JL FIN
    


FILTER: 
  ; to check if window fits horizontally (x axis) check if size + starting point <= endOfRow
  ; to check if window fits vertically (y axis) check if (width * (windowSize-1)) + startingPoint <= lastElement
  ; to find center: move down ( just multiply (window-1)/2 * columns and add to starting point ), move right just add from move down( (window-1)/2 )
  
  
  ; HORIZONTAL CHECK
  mov ecx, [varCurrent] ; ecx = current
  
  ; calculate end of rows
  xor edx, edx ; clear edx
  mov eax, ecx ; eax -> ecx
  mov ebx, [varY] ;  ebx = number of columns
  div ebx 
  
  ; edx contains remainder (place in row) ;2 (value), 3 (index), remainder 3
  mov eax, [varWindow]
  dec eax
  add eax, edx ; check to make sure that current window doesn't end beyond numCols
  cmp eax, ebx 
  
  JGE NEXT ; horizontal check
  
 ;VERTICAL CHECK
  mov eax, [varX]; # ofrows
  mov ebx, [varY]; num columns
  mul ebx ; total -> rows  x columns
  mov [varTotal], eax ; total elmeents -> varTotal
  
  mov ecx, [varCurrent] ;current
  ; (win - 1)* columns
  mov eax, [varWindow] ;window size 
  dec eax ; window size - 1
  mul ebx ; (win - 1)* columns
  
  add ecx, eax ; current with eax
  mov edx, [varTotal]
  cmp ecx, edx
  JGE FIN
  
  
  ; fin vertical
  
  ; CENTER
  xor edx, edx
  mov ecx, [varCurrent]
  mov eax, [varWindow]
  dec eax ; windowSize-1
  mov ebx, 2 
  div ebx ; eax contains (windowSize-1)/2

  mov ecx, [varY] 
  mul ecx ; eax contains "move down"(offset)
  mov ecx, [varCurrent]
  add ecx, eax ; ecx is now move down

  xor edx, edx
  mov eax, [varWindow]
  dec eax ; windowSize-1
  mov ebx, 2 
  div ebx ; eax contains (windowSize-1)/2
  add ecx, eax ;ecx contains index of center
   
  mov eax, 4
  mul ecx ; eax has address
  
  mov edi, [ebp +12] ;reinitialize edi, pointer to array output
  add edi, eax
  
  mov esi, [ebp+8]
  mov ecx, [varCurrent] ;reinitialize esi, pointer to array input
  mov eax, 4
  mul ecx
  add esi, eax ;esi -> address of start of window
  
  xor ebx, ebx ;ebx -> aggregator
  
  xor edx, edx
  
  mov ecx, [varWindow]
  mov [varInner], ecx ; window size
  inc ecx
  mov [varOuter], ecx ; window size
  
  
  OUTER:
      mov ecx, [varInner]
        
      INNER: ; add until window - 1
            add ebx, [esi+edx*4] ; add varCurrent to sum
            inc edx
            LOOP INNER
      
      ;cant use ecx, or ebx or edx
      dec edx
      mov ecx, [varWindow] ; ecx -> window size
      dec ecx ; window - 1
      mov eax, [varY] ; eax -> column size
      sub eax, ecx ; cl size - (window size-1) 
      add edx, eax ; (move next row) add edx with column size - (window size-1)
      
      mov ecx, [varOuter]
      dec ecx
      mov [varOuter], ecx
      
      LOOP OUTER
  
  DIV:
    mov eax, ebx ;eax -> aggregator
    mov ecx, [varAvgCount]
    xor edx, edx
    div ecx ; eax -> quotient, edx -> remainder
    
    mov [varQuotient], eax
    mov [varRemainder], edx
    
    xor edx, edx
    
    mov eax, [varAvgCount]
    inc eax
    mov ebx, 2
    div ebx; eax -> middle, edx -> 0
    
    mov edx, [varRemainder]
    mov ebx, [varQuotient]
    
    cmp edx, eax ; remainder compared w middle
    JL WRITE
    
    inc ebx
    
    
WRITE:
    mov [edi], ebx; save average to pixel
  
NEXT:
    mov ecx, [varCurrent]
    inc ecx
    mov [varCurrent], ecx

    jmp FILTER


FIN:
  mov esp, ebp ; leave
  pop ebp
  ret