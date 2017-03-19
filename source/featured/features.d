module featured.feature;

import featured.image;

import std.stdio;
import std.math;
import std.algorithm;
import std.array;
import std.conv;
import std.range;

struct Feature2d {
	int x;
	int y;
}

struct FeatureDetector {
	class Point {
		int x;
		int y;

		Point[] links;

		bool used = false;

		this(int x, int y) {
			this.x = x;
			this.y = y;
		}
	}

	private {
		bool isNeighbour(Point point, int x, int y) {
			return point.x == x + 1 || point.x == x - 1 || point.y == y + 1 || point.y == y - 1;
		}

		int[2] lineEnd(ref Point point, int diffX, int diffY, int len = 0) {
			auto next = point.links.filter!(a => (a.x == point.x + diffX && a.y == point.y + diffY));

			point.used = true;

			if(!next.empty && len < 3) {
				return lineEnd(next.front, diffX, diffY, len+1);
			}

			return [point.x, point.y];
		}
	}

	int[2][] get(Image image) {
		Point[] points;
		int[2][] list;


		import std.datetime;

		auto begin = Clock.currTime;

		foreach(x; 0..image.width) {
			//auto beginX = Clock.currTime;

			foreach(y; 0..image.height) {
				if(isFeature(image, x, y)) {
					auto point = new Point(x, y);
					auto neighbours = iota(0, points.length)
						.filter!(i => isNeighbour(points[i], x, y))
						.map!(i => points[i])
						.filter!(a => image[x, y].distance(image[a.x, a.y]) < 50)
							.array;

					neighbours
						.each!(a => a.links ~= point);

					point.links = neighbours;
					points ~= point;
				}
			}

			//writeln("X ", Clock.currTime - beginX);
		}

		writeln("Found points in ", Clock.currTime - begin);

		begin = Clock.currTime;
		foreach(point; points.filter!(a => !a.used)) {
			auto next = point.links.filter!(a => (a.x == point.x+1 && a.y == point.y) ||
																					(a.x == point.x && a.y == point.y+1));

			if(!next.empty) {
				point.used = true;
				list ~= [point.x, point.y];
				lineEnd(next.front, next.front.x - point.x, next.front.y - point.y);
			}
		}

		writeln("grouped points in ", Clock.currTime - begin);


		return list ~ points.filter!(a => !a.used).map!(a => cast(int[2])[a.x, a.y]).array;
	}
}

bool isFeature(Image image, int x, int y) pure {
	return [x, y]
						.neighbours(image.width, image.height, 2)
						.map!(a => image[a[0], a[1]])
							.array
							.isFeature(image[x, y]);
}

bool isFeature(T)(T[][] image) pure {
	auto x = image[0].length / 2 - image[0].length % 2 ? 0 : 1;
	auto y = image.length / 2 - image.length % 2 ? 0 : 1;

	auto color = image[x][y];

	return image.joiner.array.isFeature(color);
}

bool isFeature(T)(T[] colors, T color) pure {

	//debug colors.writeln( " ", color);

	auto distances = colors
		.map!(a => color.distance(a))
		.filter!(a => a > 0)
			.array;

	//debug distances.writeln;

	auto mean = (distances.sum.to!double / (colors.length.to!double - 1)).abs;

	//debug mean.writeln;

	return mean > 50 && distances.length > colors.length / 3;
}

version(unittest) {
	//import unit_threaded.io;
	import bdd.base;
	import std.random;
	import std.conv;

	static immutable black = [0];
	static immutable white = [255];
	static immutable whiteContrast = [200];
}

@("it should detect a low contrast point")
unittest {
	auto data = [
		[ white, white,         white ],
		[ white, whiteContrast, white ],
		[ white, white,         white ]
	];

	//data.isFeature.should.equal(true);
}

@("it should detect a black point on white bg as a feature")
unittest {
	auto data = [
		[ white, white, white ],
		[ white, black, white ],
		[ white, white, white ]
	];

	data.isFeature.should.equal(true);
}

@("it should detect a white point on black bg as a feature")
unittest {
	auto data = [
		[ black, black, black ],
		[ black, white, black ],
		[ black, black, black ]
	];

	data.isFeature.should.equal(true);
}

@("it should detect two white points on black bg as a feature")
unittest {
	auto data = [
		[ black, black, black ],
		[ black, white, white ],
		[ black, black, black ]
	];

	data.isFeature.should.equal(true);
}

@("it should detect three white points on black bg as a feature")
unittest {
	auto data = [
		[ black, black, black ],
		[ black, white, white ],
		[ black, white, black ]
	];

	data.isFeature.should.equal(true);
}

@("it should not detect a black corner")
unittest {
	auto data = [
		[ black, black ],
		[ black, white ],
		[ black, black ]
	];

	data.isFeature.should.equal(false);

	data = [
		[ black, black ],
		[ black, white ],
		[ black, white ]
	];

	data.isFeature.should.equal(false);
}

@("it should not detect a white corner")
unittest {
	auto data = [
		[ white, white ],
		[ white, black ],
		[ white, white ]
	];

	data.isFeature.should.equal(false);

	data = [
		[ white, white ],
		[ white, black ],
		[ white, black ]
	];

	data.isFeature.should.equal(false);

	data = [
		[ white, white, white ],
		[ white, black, black ]
	];

	data.isFeature.should.equal(false);
}

@("it should detect one point")
unittest {
	auto image = Image("samples/1.png");
	FeatureDetector detector;

	auto features = detector.get(image);

	features.length.should.be.equal(1);
	features[0][0].should.be.equal(1);
	features[0][1].should.be.equal(1);
}

@("it should detect two points")
unittest {
	auto image = Image("samples/2.png");
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
	FeatureDetector detector;

	auto features = detector.get(image);

	features.length.should.be.equal(1);
	features.should.contain([1, 1]);
}

@("it should detect two horizontal lines")
unittest {
	auto image = Image("samples/4.png");
	FeatureDetector detector;

	auto features = detector.get(image);

	features.should.contain([1, 1]);
	features.should.not.contain([2, 1]);

	features.should.contain([3, 2]);
	features.should.not.contain([4, 2]);
}

@("it should split a long horizontal line in two features")
unittest {
	auto image = Image("samples/5.png");

	FeatureDetector detector;

	auto features = detector.get(image);

	features.should.contain([1, 1]);
	features.should.not.contain([2, 1]);
	features.should.not.contain([3, 1]);
	features.should.not.contain([4, 1]);
	features.should.not.contain([5, 1]);

	features.should.contain([6, 1]);
	features.should.not.contain([7, 1]);
}

@("it should detect one vertical line")
unittest {
	auto image = Image("samples/6.png");
	FeatureDetector detector;

	auto features = detector.get(image);

	features.should.contain([1, 1]);
	features.should.not.contain([1, 2]);
	features.should.not.contain([1, 3]);
}

@("it should detect two vertical lines")
unittest {
	auto image = Image("samples/7.png");
	FeatureDetector detector;

	auto features = detector.get(image);


	features.should.contain([1, 1]);
	features.should.not.contain([1, 2]);

	features.should.contain([2, 3]);
	features.should.not.contain([2, 4]);
}

@("it should detect all pixels from the pincipal diag line")
unittest {
	auto image = Image("samples/8.png");
	FeatureDetector detector;

	auto features = detector.get(image);

	features.should.contain([1, 1]);
	features.should.contain([2, 2]);
	features.should.contain([3, 3]);
	features.should.contain([4, 4]);
}

@("it should detect all pixels from the secondary diag line")
unittest {
	auto image = Image("samples/9.png");
	FeatureDetector detector;

	auto features = detector.get(image);

	features.should.contain([1, 4]);
	features.should.contain([2, 3]);
	features.should.contain([3, 2]);
	features.should.contain([4, 1]);
}

@("it should detect one white line on black background")
unittest {
	auto image = Image("samples/10.png");
	FeatureDetector detector;

	auto features = detector.get(image);

	features.should.contain([1, 1]);
	features.should.not.contain([2, 1]);
	features.should.not.contain([3, 1]);
}

@("it should detect line inside gradients")
unittest {
	auto image = Image("samples/11.png");
	FeatureDetector detector;

	auto features = detector.get(image);

	//features.should.contain([3, 3]);
	features.should.not.contain([4, 3]);
	features.should.not.contain([5, 3]);
}

unittest {
	import imageformats;

	auto image = Image("samples/scene.png");
	FeatureDetector detector;

	writeln("scene.png", image.type);
	auto features = detector.get(image);

	auto im = image.rawColor;

	writeln("Found ", features.length, " features");

	foreach(feature; features) {
		im.circle(feature[0], feature[1], 5, [ uniform(0, 255), uniform(0, 255) ].to!(ubyte[]));
	}

	write_image("result/scene.png", im.w, im.h, im.pixels);
}


unittest {
	import imageformats;

	auto image = Image("samples/opencv_scene.png");
	FeatureDetector detector;

	auto features = detector.get(image);

	writeln("opencv_scene.png", image.type);
	auto im = image.rawColor;

	writeln("Found ", features.length, " features");

	foreach(feature; features) {
		im.circle(feature[0], feature[1], 5, [ uniform(0, 255), uniform(0, 255) ].to!(ubyte[]));
	}

	write_image("result/opencv_scene.png", im.w, im.h, im.pixels);
}
