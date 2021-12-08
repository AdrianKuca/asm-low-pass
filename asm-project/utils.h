#pragma once
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <math.h>
#include <algorithm>
#include <Windows.h>
bool compare_images(const BYTE* image1, const BYTE* image2, const int width, const int height);
void load_image(const BYTE* input_buffer);
void save_image();
