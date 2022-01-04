.code
	filter_low proc 
		; arguments : const BYTE* input_image, BYTE* output_image, const int width, const int height
		; RCX input_image; RDX output_image; R8 width; R9 height
		
		cmp r8, 32
		jl not_enough_pixels
		jmp enough_pixels
	not_enough_pixels:
		; Dont use simd for width < 32 pixels
		ret
	enough_pixels:
		; Use R8/32  iterations of simds for single line of the input image (leave reminder of the image for further calculation)
		mov ecx, r8/32
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


		; Increment index 
		mov rax, x_index
		add rax, 1
		mov x_index, rax
		loop x_loop

	filter_low endp
end

.data
x_index DW 0
y_index DW 0