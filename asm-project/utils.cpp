

#include "utils.h"

bool compare_images(const BYTE *image1, const BYTE *image2, const int width, const int height)
{
	bool ok = true;
	// Iterate over every pixel with x and y and return false if the pixels are different
	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			if (image1[y * width + x] != image2[y * width + x])
			{
				// Print the pixel coordinates and the pixel values
				printf("Pixel (%d, %d) has different values: %d and %d\n", x, y, image1[y * width + x], image2[y * width + x]);
				ok = false;
			}
		}
	}
	return ok;
}

void load_image(const BYTE *input_buffer)
{
}


void save_image(const ::std::string &name, BYTE *image, int width, int height)
{
	using ::std::ios;
	using ::std::ofstream;
	using ::std::string;
	typedef unsigned char pixval_t;
	auto as_pgm = [](const string &name) -> string
	{
		if (!((name.length() >= 4) && (name.substr(name.length() - 4, 4) == ".pgm")))
		{
			return name + ".pgm";
		}
		else
		{
			return name;
		}
	};

	ofstream out(as_pgm(name), ios::binary | ios::out | ios::trunc);

	string width_str = std::to_string(width);
	string height_str = std::to_string(height);
	out << "P5\n"
		<< width_str << " " << height_str << "\n255\n";
	for (int x = 0; x < height; ++x)
	{
		for (int y = 0; y < width; ++y)
		{
			const char outpv = static_cast<const char>(image[x *width + y]);
			out.write(&outpv, 1);
		}
	}
}