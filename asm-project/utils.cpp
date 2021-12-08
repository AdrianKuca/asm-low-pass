

#include "utils.h"

bool compare_images(const BYTE* image1, const BYTE* image2, const int width, const int height)
{
	for (int i = 0; i < width * height; ++i)
		if (abs((int)image1[i] - (int)image2[i]) > 1)
			return false;
	return true;
}

void load_image(const BYTE* input_buffer) {

}

void save_image() {

}