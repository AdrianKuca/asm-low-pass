

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

void load_image(const ::std::string &name, const BYTE *input_buffer)
{
	std::ifstream in(name, std::ios::in | std::ios::binary);
	if (!in)
	{
		throw std::runtime_error("Failed to open file " + name);
	}
	// Read the header
	BITMAPFILEHEADER file_header;
	in.read(reinterpret_cast<char *>(&file_header), sizeof(BITMAPFILEHEADER));
	// Check the header
	if (file_header.bfType != 0x4d42)
	{
		throw std::runtime_error("Invalid file type");
	}
	// Read the info header
	BITMAPINFOHEADER info_header;
	in.read(reinterpret_cast<char *>(&info_header), sizeof(BITMAPINFOHEADER));
	// Check the info header
	if (info_header.biSize != sizeof(BITMAPINFOHEADER))
	{
		throw std::runtime_error("Invalid info header size");
	}
	// Check the image bit depth
	if (info_header.biBitCount != 24)
	{
		throw std::runtime_error("Invalid image bit depth");
	}
	char *r = 0, g = 0, b = 0;
	// Read the image data but treat three bytes as one pixel
	for (int y = info_header.biHeight - 1; y >= 0; y--)
	{
		for (int x = 0; x < info_header.biWidth; x++)
		{
			in.read((char*)&input_buffer[y*info_header.biWidth + x], 1); // Only work on single channel
			in.seekg(1, std::ios::cur);
			in.seekg(1, std::ios::cur);
		}
		for (int x = 0; x < (info_header.biWidth * 3) % 4; x++)
		{
			in.seekg(1, std::ios::cur);
		}
	}
	in.close();
}

void save_image(const ::std::string &name, BYTE *image, int width, int height)
{
	uint32_t file_size = (width * height) * 3 + 54;
	uint16_t zero = 0;
	uint16_t ones = 0xff;
	uint32_t offset = 54;

	uint32_t dib_size = 40;
	uint16_t planes = 1;
	uint16_t bits = 24;
	uint32_t compression = 0;
	uint32_t image_size = (width * height) * 3 + ((width % 4) * height);
	uint32_t x_pixels_per_meter = 0;
	uint32_t y_pixels_per_meter = 0;
	uint32_t colors_used = 0;
	uint32_t colors_important = 0;

	// save image as bmp
	std::ofstream out(name, std::ios::out | std::ios::binary);
	// header
	out.write("BM", 2);
	out.write((char *)&file_size, 4);
	out.write((char *)&zero, 2);
	out.write((char *)&zero, 2);
	out.write((char *)&offset, 4);

	// DIB header
	out.write((char *)&dib_size, 4);
	out.write((char *)&width, 4);
	out.write((char *)&height, 4);
	out.write((char *)&planes, 2);
	out.write((char *)&bits, 2);
	out.write((char *)&compression, 4);
	out.write((char *)&image_size, 4);
	out.write((char *)&x_pixels_per_meter, 4);
	out.write((char *)&y_pixels_per_meter, 4);
	out.write((char *)&colors_used, 4);
	out.write((char *)&colors_important, 4);
	int i = 0;
	// image data with 4 byte padding
	for (int y = height - 1; y >= 0; y--)
	{
		for (int x = 0; x < width; x++)
		{
			out.write((char *)&image[y * width + x], 1);
			out.write((char *)&image[y * width + x], 1);
			out.write((char *)&image[y * width + x], 1);
			i += 1;
		}
		for (int x = 0; x < (width * 3) % 4; x++)
		{
			out.write((char *)&zero, 1);
			i += 1;
		}
	}
	out.close();
}