#include <iostream>
#include <windows.h>
#include "high-level.h"
#include "utils.h"
using namespace std;

typedef int(_stdcall *Filter_Low)(BYTE *input_image, BYTE *output_image, const int width, const int height);
HINSTANCE dllHandle = NULL;

#define WIDTH 200
#define HEIGHT 100

int main()
{
	dllHandle = LoadLibrary(TEXT("low-level.dll"));
	Filter_Low filter_low = (Filter_Low)GetProcAddress(dllHandle, "filter_low");

	// Load image
	BYTE *input_image = new BYTE[HEIGHT * WIDTH];
	load_image("input.bmp", input_image);

	// Process image high level
	BYTE *output_image_high = new BYTE[HEIGHT * WIDTH];
	filter_high(input_image, output_image_high, WIDTH, HEIGHT);
	save_image("high.bmp", output_image_high, WIDTH, HEIGHT);

	// Process image low level, CHANGES INPUT IMAGE IN PLACE
	BYTE *output_image_low = new BYTE[HEIGHT * WIDTH];
	filter_low(input_image, output_image_low, WIDTH, HEIGHT);
	save_image("low.bmp", output_image_low, WIDTH, HEIGHT);

	clock_t start_time, end_time;
	int iterations = 10000;

	cout << "Starting high level performance test...\n";
	start_time = clock();
	for (int i = 0; i < iterations; ++i)
		filter_high(input_image, output_image_high, WIDTH, HEIGHT);
	end_time = clock();
	cout << "High level function execution time = " <<((double)(end_time - start_time) / CLOCKS_PER_SEC) << " s\n";

	cout << "Starting low level performance test...\n";
	start_time = clock();
	for (int i = 0; i < iterations; ++i)
		filter_low(input_image, output_image_low, WIDTH, HEIGHT);
	end_time = clock();
	cout << "Low level function execution time = " << ((double)(end_time - start_time) / CLOCKS_PER_SEC) << " s\n";

	delete[] input_image;
	delete[] output_image_low;
	delete[] output_image_high;

	return 0;
}
