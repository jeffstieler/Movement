/*
 *  fixpng.c / iPhonePNG.h
 *
 *  Copyright 2007 MHW. Read the GPL v2.0 for legal details.
 *  http://www.gnu.org/licenses/gpl-2.0.txt
 *
 *  Modifications by David Watanabe.
 *  Portions Copyright 2007 David Watanabe.
 *   - channel flipping
 *   - directory traversal
 *
 *  Modifications by Jeff Stieler.
 *  Portions Coyright 2009 Jeff Stieler.
 *   - PNGFixer class, static conversion method using NSData objects
 *   - NOTE: IS NO LONGER A COMMAND LINE UTILITY
 *
 *  This tool converts iPhone PNGs from its incompatible format to a format any 
 *  PNG-compatible application can read.  It will also flip the R and B channels.  
 *
 *  In summary, this tool takes an input png uncompresses the IDAT chunk, recompresses
 *  it in a PNG-compatible way and then writes everything except the, so far,
 *  useless CgBI chunk to the output.
 * 
 *  It's a relatively quick hack, and it will break if the IDAT in either form
 *  (compressed or uncompressed) is larger than 1MB, and if there are more than 20
 *  chunks before the IDAT(s). In that case, poke at MAX_CHUNKS and BUFSIZE.
 *
 *  Usage: iphonePNG <input.png>
 *  - or -
 *  Usage: iphonePNG <input-directory>
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <arpa/inet.h>
#include <errno.h>
#include <zlib.h>
#include <stdarg.h>
#include "/Developer/SDKs/MacOSX10.5.sdk/usr/X11/include/png.h"


#define foreach(A) id a = A; id object, e = [a objectEnumerator]; while ((object = [e nextObject]))


typedef unsigned int uint32;
typedef struct png_chunk_t {
	uint32 length;
	unsigned char *name;
	unsigned char *data;
	uint32 crc;
} png_chunk;


void read_chunks(unsigned char *);
void process_chunks(void);
void write_png(const char *);
unsigned long mycrc(unsigned char *, unsigned char *, int);


int read_png_file(char* file_name);
int process_file();
int write_png_file(char* file_name);

@interface PNGFixer : NSObject

+ (NSData *)fixPNG:(NSData *)pngData;

@end
