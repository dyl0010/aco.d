# aco.d

Simple aco(Adobe COlor) file read/write library written in d.

When copying pixel art these days, I have to pick up colours frequently, a mechanical and error-prone process. It would save a lot of trouble if I could export the colour information from a pixel painting directly into a Photoshop swatch, so I picked up d, a powerful programming language, to implement it. (There are still some corners to be completed, but it is more than enough to solve the above needs, and this tool can be found in the accompanying example!)
## Features

- Parsing an aco file (see `genhtml` example)
- Generating aco files (see `extractaco` example)
- Reading and writing colour names
- Other colour space extensions
- Export in common text formats (csv, json)
- Exporting in ascii art binary format (for debugging)
## Usage/Examples

About parsing existing aco files:
```d
// Create an ACO object to bind to an existing aco file.
auto aco = acoFactory("./test/example.aco"d);

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
```
About generating aco files：
```d
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
```
A more practical usage can be seen in the two accompanying examples.


## Demo

**Example 1 - genhtml**

This example is from http://www.hping.org/aco2html/ and uses d and aco.d to rewrite it. It demonstrates the use of an aco file to generate a well-formatted html page. The core uses a loop to piece together the table tags (the following code is from `genhtml.dd`).

```d
    ...
    for (auto j = 0; j < aco.count; j += cols) {
        page ~= "<tr>"d;
        
        for (auto i = 0; i < cols; ++i) {
            
            if (j + i == aco.count) break;
            
            auto color = aco.colors[j + i];
            auto rgb = color.toRGB;
            dstring sclass = ((rgb.r+rgb.g+rgb.b)>235*3) ? "lbox"d : "box"d;

            page ~= "<td class=\"item\">"d;
            page ~= format("<div class=\"%s\" style=\"background-color:%s;\"></div>"d, sclass, color);
            page ~= format("<span class=\"descr\"> %s %s"d, color.name, color);
            page ~= "</span></td>\n"d;
        }

        page ~= "</tr>"d;
    }
    ...
```

Here is the usage of `genhtml`
```shell
# genhtml ./your/source/file.aco ./your/target/output.html
genhtml ./test/RGB.aco ./test/RGB.html
```

**Example 2 - extractaco**

This example was my original intention in writing the aco.d script. It generates an aco file by capturing the colour information of the pixels in the image. Thanks here to [@adamdruppe](https://github.com/adamdruppe) for the basic code on image processing.

Use the --help option to get the usage of `extractaco`:
```shell
> extractaco --help

Usage:
    extractaco --png=../path/to/yourimage.png [option]
        extracting aco swatches from png images

Options:
    -p, --png=../path/to/yourimage.png
        Target png image.
    -f, --freq=integer
        The frequency of colours will form an internal ranking,
        where it is specified how many top colours will be output.
    --help
        Show this help information and exit.

<https://github.com/dyl0010/aco.d>
```
Here is an example of actual usage:
```shell
> extractaco -p=.\test\pixel.png --freq=5
...
```
You can find the generated `pixel.png.aco` in the same directory as `extractaco`.

 ![extractaco](./screenshot/extractaco.png)

 
## Roadmap

- More colour space support
- More standardised user interface


## Acknowledgements

 - [arsd](https://github.com/adamdruppe/arsd)
 - [D Programming Language](https://github.com/dlang)


## License

[MIT](https://choosealicense.com/licenses/mit/)

