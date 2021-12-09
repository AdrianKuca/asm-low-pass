#include <iostream>
#include <windows.h>
#include "high-level.h"
#include "utils.h"
using namespace std;

typedef int(_stdcall *Filter_Low)(const BYTE *input_image, BYTE *output_image, const int width, const int height);
HINSTANCE dllHandle = NULL;

#define N 200
#define M 100

int main()
{
	dllHandle = LoadLibrary(TEXT("low-level.dll"));
	Filter_Low filter_low = (Filter_Low)GetProcAddress(dllHandle, "filter_low");

	// Load image
	BYTE *input_image = new BYTE[M * N];
	for (int i = 0, k = 0; i < N * M; ++i)
		input_image[i] = k++ % 255;

	// Process image high level
	BYTE *output_image_high = new BYTE[M * N];
	memset(output_image_high, 0, M * N); // whole image set to 0
	filter_high(input_image, output_image_high, N, M);

	// Process image low level
	BYTE *output_image_low = new BYTE[M * N];
	memset(output_image_low, 0, M * N); // whole image set to 0
	filter_low(input_image, output_image_low, N, M);

	if (compare_images(output_image_high, output_image_low, N, M))
	{
		cout << "Comparision test OK!\n";
	}
	else
	{
		cout << "Comparision test failed!!!";
		exit(1);
	}

	clock_t start_time, end_time;
	int iterations = 10000;

	cout << "Starting high level performance test...\n";
	start_time = clock();
	for (int i = 0; i < iterations; ++i)
		filter_high(input_image, output_image_low, N, M);
	end_time = clock();
	cout << "High level function execution time = " << ((float)(end_time - start_time) / CLOCKS_PER_SEC) << " s";

	cout << "Starting low level performance test...\n";
	start_time = clock();
	for (int i = 0; i < iterations; ++i)
		filter_low(input_image, output_image_low, N, M);
	end_time = clock();
	cout << "Low level function execution time = " << ((float)(end_time - start_time) / CLOCKS_PER_SEC) << " s";

	delete[] input_image;
	delete[] output_image_low;
	delete[] output_image_high;

	return 0;
}
