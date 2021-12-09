#include "pch.h"
#include "high-level.h"

void filter_high(const BYTE *input_image, BYTE *output_image, const int width, const int height)
{
	int j;
	double sum;
	int length = width * height;
	int nextZero = 2 * width - 1;
	int lenmwidthmone = length - width - 1;

	for (j = width + 1; j < lenmwidthmone; ++j) // start from the second row and end before the last row starts
	{
		if (j == nextZero)
		{						 // j is on the last pixel of the row
			output_image[j] = 0; // this pixel and also the next one are set to 0
			output_image[j + 1] = 0;
			j++;			   // skip first pixel of the next line
			nextZero += width; // remember to stop at the last pixel of the next line
		}
		else
		{
			sum = 0;

			//center
			sum += 1 / 9 * input_image[j];
			int jmwidth = j - width;
			int jpwidth = j + width;

			// sides
			sum += 1 / 9 * (input_image[j - 1] + input_image[j + 1] + input_image[jmwidth] + input_image[jpwidth]);

			//diagonals
			sum += 1 / 9 * (input_image[jmwidth - 1] + input_image[jmwidth + 1] + input_image[jpwidth - 1] + input_image[jpwidth + 1]);

			output_image[j] = (BYTE)sum;
		}
	}
}