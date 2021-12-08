#pragma once
#ifdef HIGH_LEVEL_EXPORTS
#define HIGH_LEVEL_API __declspec(dllexport)
#else
#define HIGH_LEVEL_API __declspec(dllimport)
#endif

extern "C" HIGH_LEVEL_API void filter_high(const BYTE * input_image, BYTE * output_image, const int width, const int height);