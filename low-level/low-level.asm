.code
	filter_low proc 
		; arguments : const BYTE* input_image, BYTE* output_image, const int width, const int height
		; RCX input_image; RDX output_image; R8 width; R9 height
		
		cmp r8, 32
		jl end_of_image ; Skip simd for width < 32 pixels

	; Use R8/32  iterations of simds for single line of the input image (leave reminder of the image for further calculation)
	y_loop:
		mov eax, r8
		div 32
		mov ecx, eax
		mov x_index, 0
	x_loop:
		; Load 32 bytes from 3 next rows and sum them into ymm0
		vmovntdqa ymm1, [RDX]+ x_index*32 
		vmovntdqa ymm2, [RDX]+ (y_index*r8)+1 + x_index*32 
		vmovntdqa ymm3, [RDX]+ (y_index*r8)+2 + x_index*32 
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
		vmovntdq [RDX] + (y_index+1)*r8 +(x_index+1)*32 , ymm0

		; Increment x_index which means go right by 32 pixels
		mov x_index, x_index+1
		loop x_loop

		; Increment y_index which means go down by 1 row
		mov y_index, y_index+1
		; Check if we are at the end of the image
		cmp y_index, r9-2
		je calculate_width_remainder
		jmp y_loop

	calculate_width_remainder:
		; Calculate the remaining width of the image
		mov eax, r8
		div 32
		mow r10, edx
		mov r10, r8-r10
		mov ecx, r8
		mov y_index, 0
	y_single_pixel_loop:
		mov x_index, 0
	x_single_pixel_loop:
		; Recalculate single pixel from the remaining width of the image
			; Add neighbouring pixels from the same row
			mov rax, [RDX] + (y_index+1)*r8 + (r10 + x_index+1)
			add rax, [RDX] + (y_index+1)*r8 + (r10 + x_index)
			add rax, [RDX] + (y_index+1)*r8 + (r10 + x_index+2)
			; Add neighbouring pixels from the next row
			add rax, [RDX] + (y_index+2)*r8 + (r10 + x_index)
			add rax, [RDX] + (y_index+2)*r8 + (r10 + x_index+1)
			add rax, [RDX] + (y_index+2)*r8 + (r10 + x_index+2)
			; Add neighbouring pixels from the previous row
			add rax, [RDX] + (y_index)*r8 + (r10 + x_index)
			add rax, [RDX] + (y_index)*r8 + (r10 + x_index+1)
			add rax, [RDX] + (y_index)*r8 + (r10 + x_index+2)
			; Divide by 9
			mov rax, rax / 9
			; Save result into [RDX]+ (x_index+1)
			mov [RDX] + (y_index+1)*r8 + (x_index+1), rax
			; Increment x_index which means go right by 1 pixel
			mov x_index, x_index+1
		loop x_single_pixel_loop

		; Increment y_index which means go down by 1 row
		mov y_index, y_index+1
		
		; Check if we are at the end of the image
		cmp y_index, r9-2
		je recalculate_side_pixels
		mov ecx, r8
		jmp y_single_pixel_loop
	recalculate_side_pixels:
		; Recalculate every 1st and 32th pixel of the image
		mov y_index, 0
	y_single_pixel_loop_recalc:
		mov x_index, 0
		mov ecx, r8
	x_single_pixel_loop_recalc:
		; Recalculate every first pixel of 32 bytes
			; Add neighbouring pixels from the same row
			mov rax, [RDX] + (y_index+1)*r8 + ((32*x_index)+1)
			add rax, [RDX] + (y_index+1)*r8 + ((32*x_index))
			add rax, [RDX] + (y_index+1)*r8 + ((32*x_index)+2)
			; Add neighbouring pixels from the next row
			add rax, [RDX] + (y_index+2)*r8 + ((32*x_index))
			add rax, [RDX] + (y_index+2)*r8 + ((32*x_index)+1)
			add rax, [RDX] + (y_index+2)*r8 + ((32*x_index)+2)
			; Add neighbouring pixels from the previous row
			add rax, [RDX] + (y_index)*r8 + ((32*x_index))
			add rax, [RDX] + (y_index)*r8 + ((32*x_index)+1)
			add rax, [RDX] + (y_index)*r8 + ((32*x_index)+2)
			; Divide by 9
			mov rax, rax / 9
			; Save result into [RDX]+ (x_index+1)
			mov [RDX] + (y_index+1)*r8 + (32*x_index+1), rax
		; Recalculate every last pixel of 32 bytes
			; Add neighbouring pixels from the same row
			mov rax, [RDX] + (y_index+1)*r8 + (31+(32*x_index)+1)
			add rax, [RDX] + (y_index+1)*r8 + (31+(32*x_index))
			add rax, [RDX] + (y_index+1)*r8 + (31+(32*x_index)+2)
			; Add neighbouring pixels from the next row
			add rax, [RDX] + (y_index+2)*r8 + (31+(32*x_index))
			add rax, [RDX] + (y_index+2)*r8 + (31+(32*x_index)+1)
			add rax, [RDX] + (y_index+2)*r8 + (31+(32*x_index)+2)
			; Add neighbouring pixels from the previous row
			add rax, [RDX] + (y_index)*r8 + (31+(32*x_index))
			add rax, [RDX] + (y_index)*r8 + (31+(32*x_index)+1)
			add rax, [RDX] + (y_index)*r8 + (31+(32*x_index)+2)
			; Divide by 9
			mov rax, rax / 9
			; Save result into [RDX]+ (x_index+1)
			mov [RDX] + (y_index+1)*r8 + (31+32*x_index+1), rax

		; Increment x_index which means go right by 1 pixel
		mov x_index, x_index+1
		loop x_single_pixel_loop_recalc

		; Increment y_index which means go down by 1 row
		mov y_index, y_index+1

		; Check if we are at the end of the image
		cmp y_index, r9-2
		je clear_edges
		jmp y_single_pixel_loop_recalc
	clear_edges:
	ret
	filter_low endp
	

end

.data
x_index DW 0
y_index DW 0