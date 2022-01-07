.data
	divisor dw 9
	block_size dw 32
.code
	filter_low proc 
		; arguments : const BYTE* input_image, BYTE* output_image, const int width, const int height
		; RCX input_image; RDX output_image; R8 width; R9 height

		; REGISTERS
		; r8 is width
		; r9 is height
		; r10 helps in calculations
		mov r11, 0 ; r11 is x_index
		mov r12, 0 ; r12 is y_index
		mov r13, RCX ; r13 is input_image address
		mov r14, RDX ; r14 is output_image address
		; r15 helps in calculations

		cmp r8, 32
		jl calculate_width_remainder ; Skip simd for width < 32 pixels

	; Use R8/32  iterations of simds for single line of the input image (leave reminder of the image for further calculation)
	y_loop:
		mov rax, r8
		div block_size
		mov rcx, rax
		xor r11, r11
	x_loop:
		; Load 32 bytes from 3 next rows and sum them into ymm0
		mov rax, r11
		mul block_size
		mov r15, rax
		mov rax, r12
		mul r8
		add rax, r15
		add rax, r13
		vmovdqu  ymm1, ymmword ptr [rax] ; r13 + r11*32 + r12*r8

		add rax, r8
		vmovdqu ymm2, ymmword ptr [rax] ; r13 + r11*32 + (r12+1)*r8

		add rax, r8
		vmovdqu ymm3, ymmword ptr [rax] ; r13 + r11*32 + (r12+2)*r8)

		vpaddb ymm4, ymm1, ymm2
		vpaddb ymm0, ymm3, ymm4
		
		
		; Shift right and sum
		vpsrldq ymm4, ymm1, 1
		vpsrldq ymm5, ymm2, 1
		vpsrldq ymm6, ymm3, 1
		vpaddb ymm7, ymm4, ymm5
		vpaddb ymm0, ymm7, ymm6

		; Shift left and sum
		vpslldq ymm4, ymm1, 1
		vpslldq ymm5, ymm2, 1
		vpslldq ymm6, ymm3, 1
		vpaddb ymm7, ymm4, ymm5
		vpaddb ymm0, ymm7, ymm6
		
		; Divide ymm0 by 9
		mov rax, 32768
		div divisor
		vpbroadcastw ymm8, rax
		vpmulhrsw ymm0, ymm0, ymm8

		; Save ymm0 into next row of output image [r14 + (r12+1)*r8 +(r11+1)*32]
		mov rax, r11
		inc rax
		mul block_size
		mov r15, rax
		mov rax, r12
		inc rax
		mul r8
		add rax, r15
		add rax, r14
		vmovntdq ymmword ptr [rax], ymm0

		; Increment r11 which means go right by 32 pixels
		inc r11
		loop x_loop

		; Increment r12 which means go down by 1 row
		inc r12
		; Check if we are at the end of the image
		mov rax, r9
		sub rax, 2
		cmp r12, rax
		je calculate_width_remainder
		jmp y_loop

	calculate_width_remainder:
		; Calculate the remaining width of the image in pixels [width - (width % 32)]
		mov rax, r8
		div block_size
		mov rax, r8
		sub rax, rdx
		mov r10, rax
		mov rcx, r8
		xor r12, r12
	y_single_pixel_loop:
		xor r11, r11
	x_single_pixel_loop:
		; Recalculate single pixel from the remaining width of the image
			; Add neighbouring pixels from the same row
			mov rax , r12 ; y_index
			mul r8
			add rax, r13 ; start of image
			add rax, r11 ; x _index
			add rax, r10 ; start of reminder
			mov r15, [rax]
			inc rax
			add r15, [rax]
			inc rax
			add r15, [rax]

			; Add neighbouring pixels from the next row
			add rax, r8
			add r15, [rax]
			dec rax
			add r15, [rax]
			dec rax
			add r15, [rax]

			; Add neighbouring pixels from the next next row
			add rax, r8
			add r15, [rax]
			inc rax
			add r15, [rax]
			inc rax
			add r15, [rax]
		
			; Divide by 9
			mov rax, r15
			div divisor
			mov r15, rax
			
			; Save result into [r14 + (r12+1)*r8 + (r11+1)]
			mov rax, r12
			inc rax
			mul r8
			add rax, r11
			inc rax
			add rax, r14
			mov [rax], r15
			; Increment r11 which means go right by 1 pixel
			inc r11
		loop x_single_pixel_loop

		; Increment r12 which means go down by 1 row
		inc r12
		
		; Check if we are at the end of the image
		mov rax, r9
		sub rax, 2
		cmp r12, rax
		je recalculate_side_pixels
		mov rcx, r8
		jmp y_single_pixel_loop
	recalculate_side_pixels:
		; Recalculate every 1st and 32th pixel of the image
		xor r12, r12
	y_single_pixel_loop_recalc:
		xor r11, r11
		mov rcx, r8
	x_single_pixel_loop_recalc:
		; Recalculate every first pixel of 32 bytes
			; Add neighbouring pixels from the same row
			mov rax , r12 ; y_index
			mul r8
			add rax, r13 ; start of image
			mov r15, rax

			mov rax, r11 ; x_index
			mul block_size
			add rax, r15 
			
			mov r15, [rax]
			inc rax
			add r15, [rax]
			inc rax
			add r15, [rax]

			; Add neighbouring pixels from the next row
			add rax, r8
			add r15, [rax]
			dec rax
			add r15, [rax]
			dec rax
			add r15, [rax]
			
			; Add neighbouring pixels from the next next row
			add rax, r8
			add r15, [rax]
			inc rax
			add r15, [rax]
			inc rax
			add r15, [rax]
			
			; Divide by 9
			mov rax, r15
			div divisor
			mov r15, rax

			; Save result into [r14 + (r12+1)*r8 + 32*r11+1]
			mov rax, r12
			inc rax
			mul r8
			add rax, r14
			mov rax, r10

			mov rax,r11
			mul block_size
			inc rax
			add rax, r10

			mov [rax], r15

		; Recalculate every last pixel of 32 bytes
			mov rax , r12 ; y_index
			mul r8
			add rax, r13 ; start of image
			mov r15, rax

			mov rax, r11 ; x_index
			mul block_size
			add rax, r15 
			add rax, block_size
			dec rax
			
			; Add neighbouring pixels from the same row
			mov r15, [rax]
			inc rax
			add r15, [rax]
			inc rax
			add r15, [rax]
			; Add neighbouring pixels from the next row
			add rax, r8
			add r15, [rax]
			dec rax
			add r15, [rax]
			dec rax
			add r15, [rax]
			; Add neighbouring pixels from the previous row
			add rax, r8
			add r15, [rax]
			inc rax
			add r15, [rax]
			inc rax
			add r15, [rax]

			; Divide by 9
			mov rax, r15
			div divisor
			mov r15, rax

			; Save result into [r14 + (r12+1)*r8 + (31+32*r11+1)]
			
			mov rax, r12
			inc rax
			mul r8
			add rax, r14
			mov rax, r10

			mov rax,r11
			mul block_size
			inc rax
			add rax, r10

			mov [rax], r15

		; Increment r11 which means go right by 32 pixels
		inc r11
		loop x_single_pixel_loop_recalc

		; Increment r12 which means go down by 1 row
		inc r12

		; Check if we are at the end of the image
		mov rax, r9
		sub rax, 2
		cmp r12, rax
		je clear_edges
		jmp y_single_pixel_loop_recalc
	clear_edges:
		xor r12, r12
		xor r11, r11
		mov rcx, r8
	x_loop_clear_first:
		; clear 0th line
		mov rax, r14
		add rax, r11
		mov OFFSET rax, 0
		inc r11
		loop x_loop_clear_first
		xor r11, r11
		mov rcx, r8
	x_loop_clear_last:
		; clear last line
		mov [r14 + (r9-1)*r8 + (r11)], 0
		inc r11
		loop x_loop_clear_last
		xor r11, r11
		mov rcx, r9
		
	y_loop_clear:
		; clear first and last column
		mov [r14 + r12*r8], 0
		mov [r14 + r12*r8 + r8-1], 0
		inc r12
		loop y_loop_clear

		ret
	filter_low endp
	

end