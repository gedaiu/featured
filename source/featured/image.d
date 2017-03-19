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

	auto type() pure {
		return image.c;
	}

	IFImage raw() {
		return IFImage(image.w, image.h, image.c, image.pixels.dup);
	}

	IFImage rawColor() {
		if(image.c == ColFmt.RGBA) {
			return IFImage(image.w, image.h, ColFmt.RGBA, image.pixels.dup);
		}

		if(image.c == ColFmt.Y) {
			return IFImage(image.w, image.h, ColFmt.RGBA, image.pixels.map!(a => cast(ubyte[])[a, a, a, 255]).joiner.array);
		}

		if(image.c == ColFmt.YA) {
			return IFImage(image.w, image.h, ColFmt.RGBA, image.pixels.chunks(2).map!(a => cast(ubyte[])[a[0], a[0], a[0], a[1]]).joiner.array);
		}

		if(image.c == ColFmt.RGB) {
			return IFImage(image.w, image.h, ColFmt.RGBA, image.pixels.chunks(3).map!(a => cast(ubyte[])[a[0], a[1], a[2], 255]).joiner.array);
		}

		return IFImage(image.w, image.h, image.c, image.pixels);
	}
}

auto plot(T)(ref T im, int x, int y, ubyte[] color = [ 100 ]) {
	if(x < 0 || y<0) {
		return im;
	}

	auto size = im.pixels.length / (im.w * im.h);
	auto index = (max(0, y - 1) * im.w + x) * size;

	if(index < 0 || index >= im.pixels.length) {
		return im;
	}

	for(int i=0; i< color.length; i++) {
		im.pixels[index+i] = color[i];
	}

	return im;
}

auto circle(T)(ref T im, int x0, int y0, int radius, ubyte[] color = [ 100 ]) {
	int x = radius;
	int y = 0;
	int err = 0;

	while (x >= y)
	{
		im.plot(x0 + x, y0 + y, color);
		im.plot(x0 + y, y0 + x, color);
		im.plot(x0 - y, y0 + x, color);
		im.plot(x0 - x, y0 + y, color);
		im.plot(x0 - x, y0 - y, color);
		im.plot(x0 - y, y0 - x, color);
		im.plot(x0 + y, y0 - x, color);
		im.plot(x0 + x, y0 - y, color);

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

int[2][] neighbours(int[2] point, int width = int.max, int height = int.max, int distance = 1) pure {
	int[2][] points;

	foreach(x; point[0] - distance..point[0]+distance+1)
		foreach(y; point[1] - distance..point[1]+distance+1) {
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

	return d.abs;
}

auto distance(T)(T color1, T color2) pure {
	int d;

	foreach(i; 0..color1.length) {
		d += color1[i] - color2[i];
	}

	return d.abs;
}
