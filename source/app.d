import std.stdio;
import std.math;
import std.algorithm;
import std.array;

import imageformats;


void main()
{
	writeln("Edit source/app.d to start your project.");
}

struct Feature2d {
	int x;
	int y;
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

int[2][] neighbours(int[2] point) {
	int[2][] points;

	foreach(x; point[0]-1..point[0]+2)
		foreach(y; point[1]-1..point[1]+2) {
			if(x == point[0] && y == point[1]) {
				continue;
			}

			if(x >= 0 && y >= 0) {
				points ~= [x, y];
			}
		}

	return points;
}

auto getPixel(T)(ref T im, int x, int y) {
	auto size = im.pixels.length / (im.w * im.h);
	auto index = (max(0, y - 1) * im.w + x) * size;

	return im.pixels[index..index+size];
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

Feature2d[] features(T)(ref T im) {
	Feature2d[] list;

	int[2][] coordinates;
	int[2][] all;

	foreach(y; 1..im.h) {
		foreach(x; 1..im.w-1) {
			all ~= [x * 2, y * 2];
		}
	}

	foreach(y; 1..im.h / 2) {
		foreach(x; 1..im.w-1 / 2) {
			coordinates ~= [x * 2, y * 2];
			all = all.remove([x * 2, y * 2]).array;
		}
	}

	auto size = im.pixels.length / (im.w * im.h);

	foreach(pair; coordinates) {
		auto value = im.getPixel(pair[0], pair[1]);
		auto neighbours = pair.neighbours;

		foreach(neighbour; neighbours) {
			auto d = im.distance(pair, neighbour);

			if(d != 0) {
				list ~= Feature2d(neighbour[0], neighbour[1]);
			}
		}
	}

	return list;
}

/*
unittest {
	IFImage im = read_image("samples/features.png");
	writeln(im.w, "x", im.h, " ", im.c);

	auto features = im.features;

	features.length.writeln(" :features");


	foreach(feature; features) {
		im.circle(feature.x, feature.y, 5);
	}

	write_image("result/features.png", im.w, im.h, im.pixels);
}*/

struct Image {

	private {
		IFImage image;
	}

	this(string path) {
		image = read_image(path);
	}

	ref auto opIndex(int x, int y) {
		auto index = (y * image.w + x) * pixelSize;

		return image.pixels[index..index+pixelSize];
	}

	int width() {
		return image.w;
	}

	int height() {
		return image.h;
	}

	auto pixelSize() {
		return image.pixels.length / (image.w * image.h);
	}
}

struct FeatureDetector {

	int[2][] get(Image image) {
		int[2][] points = [];
		int[2][] list = [];

		foreach(x; 0..image.width) {
			foreach(y; 0..image.height) {
				if(image[x, y][0] == 0) {
					points ~= [x, y];
				}
			}
		}

		int startX = points[0][0];
		int prevX = points[0][0];
		int prevY = points[0][1];

		foreach(point; points) {
			if(prevX == point[0] - 1 && prevY == point[1]) {
				prevX = point[0];
			} else {
				list ~= point;
				prevY = point[1];
				prevX = point[0];
			}
		}

		return list;
	}
}

version(unittest) {
	import bdd.base;
}

@("it should detect one point")
unittest {
	auto image = Image("samples/1.png");
	image.writeln;

	FeatureDetector detector;

	auto features = detector.get(image);

	features.length.should.be.equal(1);
	features[0][0].should.be.equal(1);
	features[0][1].should.be.equal(1);
}

@("it should detect two points")
unittest {
	auto image = Image("samples/2.png");
	image.writeln;

	FeatureDetector detector;

	auto features = detector.get(image);

	features.length.should.be.equal(2);
	features[0][0].should.be.equal(1);
	features[0][1].should.be.equal(1);

	features[1][0].should.be.equal(4);
	features[1][1].should.be.equal(1);
}

@("it should detect one horizontal line")
unittest {
	auto image = Image("samples/3.png");
	image.writeln;

	FeatureDetector detector;

	auto features = detector.get(image);
	features.writeln;

	features.length.should.be.equal(1);
	features[0][0].should.be.equal(1);
	features[0][1].should.be.equal(1);
}

@("it should detect two horizontal lines")
unittest {
	auto image = Image("samples/scene.png");
	image.writeln;

	FeatureDetector detector;

	auto features = detector.get(image);
	features.writeln;

	features.length.should.be.equal(2);
	features[0][0].should.be.equal(1);
	features[0][1].should.be.equal(1);

	features[1][0].should.be.equal(3);
	features[1][1].should.be.equal(2);
}
