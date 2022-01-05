.data
	block_size dw 32
.code
	filter_low proc 
		; arguments : const BYTE* input_image, BYTE* output_image, const int width, const int height
		; RCX input_image; RDX output_image; R8 width; R9 height
		mov r11, 0 ; r11 is x_index
		mov r12, 0 ; r12 is r12
		
		cmp r8, 32
		jl calculate_width_remainder ; Skip simd for width < 32 pixels

	; Use R8/32  iterations of simds for single line of the input image (leave reminder of the image for further calculation)
	y_loop:
		mov eax, r8
		div block_size
		mov ecx, eax
		mov r11, 0 ; r11 is x_index
	x_loop:
		; Load 32 bytes from 3 next rows and sum them into ymm0
		vmovntdqa ymm1, [RDX]+ r11*32 
		vmovntdqa ymm2, [RDX]+ (r12*r8)+1 + r11*32 
		vmovntdqa ymm3, [RDX]+ (r12*r8)+2 + r11*32 
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
		vpbroadcastw ymm8, 32768 / 9
		vpmulhrsw ymm0, ymm0, ymm8

		; Save ymm0 into next row of output image
		vmovntdq [RDX] + (r12+1)*r8 +(r11+1)*32 , ymm0

		; Increment r11 which means go right by 32 pixels
		inc r11
		loop x_loop

		; Increment r12 which means go down by 1 row
		inc r12
		; Check if we are at the end of the image
		cmp r12, r9-2
		je calculate_width_remainder
		jmp y_loop

	calculate_width_remainder:
		; Calculate the remaining width of the image
		mov eax, r8
		div block_size
		mov r10, edx
		mov r10, r8-r10
		mov ecx, r8
		xor r12, r12
	y_single_pixel_loop:
		xor r11, r11
	x_single_pixel_loop:
		; Recalculate single pixel from the remaining width of the image
			; Add neighbouring pixels from the same row
			mov rax, [RDX] + (r12+1)*r8 + (r10 + r11+1)
			add rax, [RDX] + (r12+1)*r8 + (r10 + r11)
			add rax, [RDX] + (r12+1)*r8 + (r10 + r11+2)
			; Add neighbouring pixels from the next row
			add rax, [RDX] + (r12+2)*r8 + (r10 + r11)
			add rax, [RDX] + (r12+2)*r8 + (r10 + r11+1)
			add rax, [RDX] + (r12+2)*r8 + (r10 + r11+2)
			; Add neighbouring pixels from the previous row
			add rax, [RDX] + (r12)*r8 + (r10 + r11)
			add rax, [RDX] + (r12)*r8 + (r10 + r11+1)
			add rax, [RDX] + (r12)*r8 + (r10 + r11+2)
			; Divide by 9
			mov rax, rax / 9
			; Save result into [RDX]+ (r11+1)
			mov [RDX] + (r12+1)*r8 + (r11+1), rax
			; Increment r11 which means go right by 1 pixel
			mov r11, r11+1
		loop x_single_pixel_loop

		; Increment r12 which means go down by 1 row
		mov r12, r12+1
		
		; Check if we are at the end of the image
		cmp r12, r9-2
		je recalculate_side_pixels
		mov ecx, r8
		jmp y_single_pixel_loop
	recalculate_side_pixels:
		; Recalculate every 1st and 32th pixel of the image
		xor r12, r12
	y_single_pixel_loop_recalc:
		xor r11, r11
		mov ecx, r8
	x_single_pixel_loop_recalc:
		; Recalculate every first pixel of 32 bytes
			; Add neighbouring pixels from the same row
			mov rax, [RDX] + (r12+1)*r8 + ((32*r11)+1)
			add rax, [RDX] + (r12+1)*r8 + ((32*r11))
			add rax, [RDX] + (r12+1)*r8 + ((32*r11)+2)
			; Add neighbouring pixels from the next row
			add rax, [RDX] + (r12+2)*r8 + ((32*r11))
			add rax, [RDX] + (r12+2)*r8 + ((32*r11)+1)
			add rax, [RDX] + (r12+2)*r8 + ((32*r11)+2)
			; Add neighbouring pixels from the previous row
			add rax, [RDX] + (r12)*r8 + ((32*r11))
			add rax, [RDX] + (r12)*r8 + ((32*r11)+1)
			add rax, [RDX] + (r12)*r8 + ((32*r11)+2)
			; Divide by 9
			mov rax, rax / 9
			; Save result into [RDX]+ (r11+1)
			mov [RDX] + (r12+1)*r8 + (32*r11+1), rax
		; Recalculate every last pixel of 32 bytes
			; Add neighbouring pixels from the same row
			mov rax, [RDX] + (r12+1)*r8 + (31+(32*r11)+1)
			add rax, [RDX] + (r12+1)*r8 + (31+(32*r11))
			add rax, [RDX] + (r12+1)*r8 + (31+(32*r11)+2)
			; Add neighbouring pixels from the next row
			add rax, [RDX] + (r12+2)*r8 + (31+(32*r11))
			add rax, [RDX] + (r12+2)*r8 + (31+(32*r11)+1)
			add rax, [RDX] + (r12+2)*r8 + (31+(32*r11)+2)
			; Add neighbouring pixels from the previous row
			add rax, [RDX] + (r12)*r8 + (31+(32*r11))
			add rax, [RDX] + (r12)*r8 + (31+(32*r11)+1)
			add rax, [RDX] + (r12)*r8 + (31+(32*r11)+2)
			; Divide by 9
			mov rax, rax / 9
			; Save result into [RDX]+ (r11+1)
			mov [RDX] + (r12+1)*r8 + (31+32*r11+1), rax

		; Increment r11 which means go right by 1 pixel
		inc r11
		loop x_single_pixel_loop_recalc

		; Increment r12 which means go down by 1 row
		inc r12

		; Check if we are at the end of the image
		cmp r12, r9-2
		je clear_edges
		jmp y_single_pixel_loop_recalc
	clear_edges:
		xor r12, r12
		xor r11, r11
		mov ecx, r8
	x_loop_clear_first:
		; clear 0th line
		mov [RDX] + (r11), 0
		inc r11
		loop x_loop_clear_first
		xor r11, r11
		mov ecx, r8
	x_loop_clear_last:
		; clear last line
		mov [RDX] + (r9-1)*r8 + (r11), 0
		inc r11
		loop x_loop_clear_last
		xor r11, r11
		mov ecx, r9
		
	y_loop_clear:
		; clear first and last column
		mov [RDX] + r12*r8, 0
		mov [RDX] + r12*r8 + r8-1, 0
		inc r12
		loop y_loop_clear

		ret
	filter_low endp
	

end