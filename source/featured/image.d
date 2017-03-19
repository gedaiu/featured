module featured.image;

import std.stdio;
import std.math;
import std.algorithm;
import std.array;
import std.conv;
import std.range;

import imageformats;

struct Image {

	private {
		IFImage image;
	}

	this(string path) {
		image = read_image(path);
	}

	ref auto opIndex(int x, int y) pure {
		auto index = (y * image.w + x) * pixelSize;

		return image.pixels[index..index+pixelSize];
	}

	int width() pure {
		return image.w;
	}

	int height() pure {
		return image.h;
	}

	auto pixelSize() pure {
		return image.pixels.length / (image.w * image.h);
	}

  IFImage raw() {
    return IFImage(image.w, image.h, image.c, image.pixels.dup);
  }
}

auto plot(T)(ref T im, int x, int y) {
	if(x < 0 || y<0) {
		return im;
	}

	auto size = im.pixels.length / (im.w * im.h);
	auto index = (max(0, y - 1) * im.w + x) * size;

	if(index < 0 || index >= im.pixels.length) {
		return im;
	}

	im.pixels[index] = 100;

	return im;
}

auto circle(T)(ref T im, int x0, int y0, int radius) {
	int x = radius;
  int y = 0;
  int err = 0;

  while (x >= y)
  {
    im.plot(x0 + x, y0 + y);
    im.plot(x0 + y, y0 + x);
    im.plot(x0 - y, y0 + x);
    im.plot(x0 - x, y0 + y);
    im.plot(x0 - x, y0 - y);
    im.plot(x0 - y, y0 - x);
    im.plot(x0 + y, y0 - x);
    im.plot(x0 + x, y0 - y);

    if (err <= 0)
    {
      y += 1;
      err += 2*y + 1;
    } else {
      x -= 1;
      err -= 2*x + 1;
    }
  }
}

int[2][] neighbours(int[2] point, int width = int.max, int height = int.max) pure {
	int[2][] points;

	foreach(x; point[0]-1..point[0]+2)
		foreach(y; point[1]-1..point[1]+2) {
			if(x == point[0] && y == point[1]) {
				continue;
			}

			if(x >= 0 && y >= 0 && x < width && y < height) {
				points ~= [x, y];
			}
		}

	return points;
}

auto distance(T)(ref T im, int[2] point1, int[2] point2) {
	auto pixel1 = im.getPixel(point1[0], point1[1]);
	auto pixel2 = im.getPixel(point2[0], point2[1]);

	int d;

	foreach(i; 0..pixel1.length) {
		d += pixel1[i] - pixel2[i];
	}

	return d;
}

auto distance(T)(T color1, T color2) pure {
	int d;

	foreach(i; 0..color1.length) {
		d += color1[i] - color2[i];
	}

	return d;
}
