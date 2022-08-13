import std.stdio;

import ps.aco;

import std.array;

void main() {
   	
    // Create an ACO object to bind to an existing aco file.
	auto aco = acoFactory("./test/RGB.aco"d);

    aco.ver.writeln;     // Print aco file version.
    aco.count.writeln;   // Print the number of colours in this aco file.

    // Print each colour iteratively.
    foreach (color; aco.colors) {
        color.writeln;
    }

    // Print to other text formats.
    aco.toCsv.writeln;

    aco.toJson.writeln;

    // Print to binary format.
    ACO.dumpData(aco.toBinary);

    ACO.dumpDataAsciiArt(aco.toBinary);



    // Create a blank ACO object.
    auto newAco = acoFactory();

    // A set of gradient colours has been added below.
    foreach (i; 0..10) {
        uint clr = i * 20;
        newAco.addColor(AcoColor(rgb_(clr, clr, clr)));
    }

    // Set the colour name.
    newAco.addColor(AcoColor(rgb_(169, 62, 53), "d main color"w));
    newAco.addColor(AcoColor(rgb_(0, 0, 0), "black"w));

    import std.file;

    // Export aco file.
    write("./test/export.aco", newAco.toBinary);

}