module ps.aco;

import std.stdio;
import std.file;
import std.format;
import std.algorithm;
import std.range;
import std.bitmanip;
import std.typecons;

alias rgb_ = Tuple!(uint, "r", uint, "g", uint, "b");
alias hsb_ = Tuple!(uint, "h", uint, "s", uint, "b");
alias cmyk_ = Tuple!(uint, "c", uint, "m", uint, "y", uint, "k");
alias lab_ = Tuple!(int, "l", int, "a", int, "b");
alias grayscale_ = Tuple!(uint, "rgb");

package alias Word = ubyte[2];

struct AcoColor {

    enum ColorSpaceId : ushort { 
        rgb, 
        hsb, 
        cmyk, 
        lab = 7, 
        grayscale 
    }

private:
    Word id_;
	Word w_;
	Word x_;
	Word y_;
	Word z_;

    this(Word id, Word w, Word x, Word y, Word z) {
        id_ = id; w_ = w; x_ = x; y_ = y; z_ = z;

        specs = id_.dup.peek!(ColorSpaceId);
        // assert(specs is valid!);
    }

public:
	wstring name;
    ColorSpaceId specs;

    static immutable size = 5 * Word.sizeof;

    this(rgb_ color, wstring name = ""w) {
        id_[0] = id_[1] = 0;
        w_[0] = w_[1] = cast(ubyte)color.r;
        x_[0] = x_[1] = cast(ubyte)color.g;
        y_[0] = y_[1] = cast(ubyte)color.b;
        z_[0] = z_[1] = 0;
        this.name = name;
    }

    auto toRGB() const {
        return rgb_(w_.dup.peek!ushort >> 8
                  , x_.dup.peek!ushort >> 8
                  , y_.dup.peek!ushort >> 8);
    }

    string toString() const @safe pure {
        string rnt;

        final switch (specs) {
            case ColorSpaceId.rgb:
                rnt = format("#%02x%02x%02x", w_.dup.peek!ushort >> 8, 
                x_.dup.peek!ushort >> 8, y_.dup.peek!ushort >> 8);
                break;
            case ColorSpaceId.hsb:
                break;
            case ColorSpaceId.cmyk:
                break;
            case ColorSpaceId.lab:
                break;
            case ColorSpaceId.grayscale:
                break;
        }

        return rnt;
    }
}

final class ACO  {
private:
	ubyte[] data_;
	ushort version_ = 2;
	ushort count_;
	AcoColor[] colors_;

    bool parseData() {
        bool ret = true;
        auto parsed = data_.dup;

        // parse aco1
        {
            ret = getVersion(parsed);

            ret = getCount(parsed);

            ret = getAco1Colors(parsed);
        }

        // parse aco2
        if (parsed.length > 0) {
            ret = getVersion(parsed);

            ret = getCount(parsed);

            ret = getAco2Names(parsed);
        }

        debug {
            dumpDataAsciiArt(this.toBinary);
            this.toCsv.writeln;
            this.toJson.writeln;
        }

        return ret;
    }

    bool getVersion(ref ubyte[] parsed) {
        if (parsed.length < version_.sizeof) {
            stderr.writeln("acoFormatError: cannot read `version` bytes.");
            return false;    
        } 
        version_ = parsed[0..version_.sizeof].peek!(typeof(version_));  // default big-endian, that's what we want.
        parsed = parsed[version_.sizeof..$];

        return true;
    }

    bool getCount(ref ubyte[] parsed) {
        if (parsed.length < count_.sizeof) {
            stderr.writeln("acoFormatError: cannot read `count` bytes.");
            return false;
        } 
        count_ = parsed[0..count_.sizeof].peek!(typeof(count_));
        parsed = parsed[count_.sizeof..$];

        return true;
    }

    bool getAco1Colors(ref ubyte[] parsed) {
        if (parsed.length < count_ * AcoColor.size) {
            stderr.writeln("acoFormatError: cannot read `Aco1Colors` bytes.");
            return false;
        }
        colors_.reserve(count_);
        foreach (i; 0..count_) {
            colors_ ~= parseColor(parsed);
            parsed = parsed[AcoColor.size..$];
        }

        return true;
    }

    bool getAco2Names(ref ubyte[] parsed) {
        assert((count_ != 0) && (count_ == colors_.length));

        foreach(i; 0..count_) {
            if (parsed.length < AcoColor.size + Word.sizeof * 2) {  // color + 0 constants + name length
                stderr.writeln("acoFormatError: cannot read `Aco2Names` bytes.");
                return false;
            }
            parsed = parsed[AcoColor.size..$];  // skip color(same as aco1 color).
            parsed = parsed[Word.sizeof..$];    // skip 0 constants.
            
            auto nameLen = parsed[0..Word.sizeof].peek!(ushort);
            assert(nameLen >= 1);
            parsed = parsed[Word.sizeof..$];    // skip name length
            if (parsed.length < nameLen * Word.sizeof) {
                stderr.writeln("acoFormatError: cannot read `Aco2NamesString` bytes.");
                return false;
            }
            colors_[i].name = parseName(parsed[0..(nameLen - 1) * Word.sizeof]);
            parsed = parsed[nameLen * Word.sizeof..$];
        }

        return true;
    }

    AcoColor parseColor(const(ubyte)[] colorBlock) const {
        assert(colorBlock.length >= AcoColor.size);

        auto color = AcoColor(
            colorBlock[0..2].staticArray!2,
            colorBlock[2..4].staticArray!2,
            colorBlock[4..6].staticArray!2,
            colorBlock[6..8].staticArray!2,
            colorBlock[8..$].staticArray!2
        );

        return color;
    }

    wstring parseName(const(ubyte)[] nameBlock) const  {
        wstring name;
        for (size_t i = 0; i < nameBlock.length; i += 2) {
            name ~= cast(wchar)bigEndianToNative!ushort(nameBlock[i..i+2].staticArray!2);
        } 
        return name;
    }

public:
    this() { /* */ }

	this (ubyte[] data) in { assert(data.length != 0); } do {
		data_ = data;

        this.parseData;
	}

    auto ver() const nothrow { return version_; }

    void ver(ushort ver) nothrow { version_ = ver; }

    auto count() const nothrow { return count_; }

    // void count(ushort count) nothrow { count_ = count; }

    auto colors() const nothrow { return colors_; }

    void addColor(AcoColor color) { 
        colors_ ~= color; 
        ++count_;
    } 

    auto data() const nothrow { return data_; }

    immutable(ubyte)[] toBinary() const {
        import std.array;
        auto buffer = appender!(immutable ubyte[])();

        // write aco1
        buffer.append!ushort(0x01);
        buffer.append(count_);
        foreach (color; colors_) {
            buffer.append(color.id_.dup.peek!ushort);
            buffer.append(color.w_.dup.peek!ushort);
            buffer.append(color.x_.dup.peek!ushort);
            buffer.append(color.y_.dup.peek!ushort);
            buffer.append(color.z_.dup.peek!ushort);
        }

        // write aco2
        buffer.append!ushort(0x02);
        buffer.append(count_);
        foreach(color; colors_) {
            buffer.append(color.id_.dup.peek!ushort);
            buffer.append(color.w_.dup.peek!ushort);
            buffer.append(color.x_.dup.peek!ushort);
            buffer.append(color.y_.dup.peek!ushort);
            buffer.append(color.z_.dup.peek!ushort);

            buffer.append!ushort(0x00);  // write 0 constants

            buffer.append(cast(ushort)(color.name.length + 1));
            color.name.each!(wc => buffer.append(wc));
            buffer.append!ushort(0x00);  // string ending in 0
        }

        return buffer.data;
    }

    wstring toCsv() const {
        // format:
        //   Swatch 1,#091505,  // color's name, color's hex
        //   Swatch 2,#fe8a01,
        //   Swatch 3,#30411c,
        //   ...
        //   2,8,               // aco's version, color's counter
        wstring rnt;
        colors_.each!((color) {
            rnt ~= format("%s,%s,\n"w, color.name, color);
        });
        rnt ~= format("%s,%s,\n"w, version_, count_);

        return rnt;
    }

    wstring toJson() const {
        // format:
        // {
        // "colors": [
        //     {
        //     "hex": "#091505",
        //     "name": "Swatch 1",
        //     "specs": "rgb"
        //     },
        //     ...
        // ],
        // "count": 8,
        // "type": ".aco",
        // "version": 2
        // }
        import std.json;
        import std.conv;

        JSONValue rnt = [ "type": ".aco" ];
        rnt["version"] = JSONValue(version_);
        rnt["count"] = JSONValue(count_);
        rnt["colors"] = JSONValue(wstring[].init);

        foreach (color; colors_) {
            JSONValue jvc = [
                "name": color.name,
                "hex": color.to!wstring,
                "specs": color.specs.to!wstring
            ];
            rnt["colors"].array ~= jvc;
        }

        return rnt.toString.to!wstring;
    }

	static void dumpData(immutable(ubyte)[] data) {
		"%(%02X %)".writefln(data);
	}

	static void dumpDataAsciiArt(immutable(ubyte)[] data) {
		immutable columnCount = 0x10;
		size_t headerAddress;
		string asciiArt;

		asciiArt ~= "Hex View  00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F\n";

        import std.ascii: isGraphical;
	
		for (size_t i = 0; i < data.length; i += columnCount / 2) {
			if ((i % columnCount) == 0) {
				if (i != 0) {
					data[(i - columnCount)..i].each!((ch) { 
						asciiArt ~= isGraphical(cast(char)ch) ? cast(char)ch : '.';
					});
				}			
				asciiArt ~= format("\n%08X", headerAddress) ~ "  ";
				headerAddress += columnCount;
			}
			auto end = min(i + columnCount / 2, data.length);
			asciiArt ~= format("%(%02X %)", data[i..end]) ~ "  ";
		}

		// fill last line ascii view.
		auto rest = data.length % columnCount;
		if (rest == 0) rest = columnCount;
		auto fill = columnCount - rest;
		asciiArt ~= repeat("   ", fill).join;
		if (rest <= columnCount / 2) asciiArt ~= " ";
		data[$-rest..$].each!((ch) { 
			asciiArt ~= isGraphical(cast(char)ch) ? cast(char)ch : '.';
		});

		asciiArt.writeln;
	}
}

ACO acoFactory(dstring filename = ""d) {
    if (filename.length) {
        if (!exists(filename)) {
            stderr.writefln("%s not exists!", filename);
            return null;
        }
        return new ACO(cast(ubyte[])read(filename));
    } else {
        return new ACO;
    }
}