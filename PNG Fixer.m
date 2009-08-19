/*
 *  fixpng.c / iPhonePNG.m
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

#import "PNG Fixer.h"

#define MAX_CHUNKS 20
#define BUFSIZE 1048576 // 1MB buffer size

png_chunk **chunks;
id basePath = nil;

unsigned char pngheader[8] = {137, 80, 78, 71, 13, 10, 26, 10};
unsigned char datachunk[4] = {0x49, 0x44, 0x41, 0x54}; // IDAT
unsigned char endchunk[4] = {0x49, 0x45, 0x4e, 0x44}; // IEND
unsigned char cgbichunk[4] = {0x43, 0x67, 0x42, 0x49}; // CgBI


@implementation NSString (Extensions)

    - (NSString*) stringByRemovingPrefix: (NSString*) thePrefix; {
        if ([self hasPrefix: thePrefix]) {
            return [self substringFromIndex: [thePrefix length]];
        } else {
            return self;
        }
    }

@end

@implementation PNGFixer

+ (NSData *)fixPNG:(NSData *)pngData {
	NSString *newPath = @"/tmp/icon.png"; // BAD BAD BAD BAD BAD FIX ME
	
	unsigned char *buf = (unsigned char *)malloc([pngData length]);
	
	memcpy(buf, [pngData bytes], [pngData length]);
	
	if (memcmp(buf, pngheader, 8)) {
		printf("This is not a PNG file. I require a PNG file!\n");
        return [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sad_mac" ofType:@"gif"]];
    }
	
	chunks = malloc(sizeof(png_chunk *) * MAX_CHUNKS);
	
	read_chunks(buf);
	process_chunks();
    write_png([newPath cString]);
	
    free(chunks);
    free(buf);
    
    // channel flipping 
    if (read_png_file((char*)[newPath cString]) == 1) {
		if (process_file() == 1) {
			write_png_file((char*)[newPath cString]);
			return [NSData dataWithContentsOfFile:newPath];
		}
	}
	return pngData;
}

@end


void convertPath(id thePath) {
    NSLog(@"Converting: %@", [thePath stringByRemovingPrefix: basePath]);

	int fd;
	unsigned char *buf;
	struct stat s;

	fd = open([thePath cString], O_RDONLY, 0);
	
	if (fstat(fd, &s) < 0) {
		printf("Couldn't stat file\n");
        return;
    }

	buf = (unsigned char *)malloc(s.st_size);

	if (read(fd, buf, s.st_size) != s.st_size) {
		printf("Couldn't read file\n");
        return;
    }
	if (memcmp(buf, pngheader, 8)) {
		printf("This is not a PNG file. I require a PNG file!\n");
        return;
    }
	
	chunks = malloc(sizeof(png_chunk *) * MAX_CHUNKS);

	read_chunks(buf);
	process_chunks();
    write_png([thePath cString]);

    free(chunks);
    free(buf);
    close(fd);
    
    /* channel flipping */
    read_png_file((char*)[thePath cString]);
    process_file();
    write_png_file((char*)[thePath cString]);
}

void read_chunks(unsigned char* buf){
	int i = 0;
	
	buf += 8;
	do {
		png_chunk *chunk;
		
		chunk = (png_chunk *)malloc(sizeof(png_chunk));

		memcpy(&chunk->length, buf, 4);
		chunk->length = ntohl(chunk->length);
		chunk->data = (unsigned char *)malloc(chunk->length);
		chunk->name = (unsigned char *)malloc(4);

		buf += 4;
		memcpy(chunk->name, buf, 4);
		buf += 4;
		memcpy(chunk->data, buf, chunk->length);
		buf += chunk->length;
		memcpy(&chunk->crc, buf, 4);
		chunk->crc = ntohl(chunk->crc);
		buf += 4;
		
        #ifdef TEST
		printf("Found chunk: %c%c%c%c\n", chunk->name[0], chunk->name[1], chunk->name[2], chunk->name[3]);
		printf("Length: %d, CRC32: %08x\n", chunk->length, chunk->crc);
		#endif
        
		*(chunks+i) = chunk;
		
		if (!memcmp(chunk->name, endchunk, 4)){
			// End of img.
			break;
		}
	} while (i++ < MAX_CHUNKS); 
	
}

void process_chunks(){
	int i;
	
	// Poke at any IDAT chunks and de/recompress them
	for (i = 0; i < MAX_CHUNKS; i++){
		png_chunk *chunk;
		int ret;
		
		chunk = *(chunks+i);
		z_stream infstrm, defstrm;
		
		if (!memcmp(chunk->name, datachunk, 4)){
			unsigned char *inflatedbuf;
			unsigned char *deflatedbuf;
			
			inflatedbuf = (unsigned char *)malloc(BUFSIZE);
			#ifdef TEST
            printf("processing IDAT chunk %d\n", i);
            #endif
			infstrm.zalloc = Z_NULL;
			infstrm.zfree = Z_NULL;
			infstrm.opaque = Z_NULL;
			infstrm.avail_in = chunk->length;
			infstrm.next_in = chunk->data;
			infstrm.next_out = inflatedbuf;
			infstrm.avail_out = BUFSIZE;
			
			// Inflate using raw inflation
			if (inflateInit2(&infstrm,-8) != Z_OK){
				printf("ZLib error");
                return;
			}
			
			ret = inflate(&infstrm, Z_NO_FLUSH);
			switch (ret) {
				case Z_NEED_DICT:
					ret = Z_DATA_ERROR;     /* and fall through */
				case Z_DATA_ERROR:
				case Z_MEM_ERROR:
                    printf("ZLib error! %d\n", ret);
					inflateEnd(&infstrm);
			}
		 
			inflateEnd(&infstrm);
			
			// Now deflate again, the regular, PNG-compatible, way
			deflatedbuf = (unsigned char *)malloc(BUFSIZE);

			defstrm.zalloc = Z_NULL;
			defstrm.zfree = Z_NULL;
			defstrm.opaque = Z_NULL;
			defstrm.avail_in = infstrm.total_out;
			defstrm.next_in = inflatedbuf;
			defstrm.next_out = deflatedbuf;
			defstrm.avail_out = BUFSIZE;

			deflateInit(&defstrm, Z_DEFAULT_COMPRESSION);
			deflate(&defstrm, Z_FINISH);
			
            if (chunk->data)
                free(chunk->data);
			chunk->data = deflatedbuf;
			chunk->length = defstrm.total_out;
			chunk->crc = mycrc(chunk->name, chunk->data, chunk->length);
			
            #ifdef TEST
			printf("New length: %d, new CRC: %08x\n", chunk->length, chunk->crc);
			#endif
            
		} else if (!memcmp(chunk->name, endchunk, 4)){
			break;
		}
	
	}
}

void write_png(const char *filename){
	int fd, i = 0;
	
	fd = open(filename, O_CREAT|O_RDWR, S_IRUSR|S_IWUSR);
	write(fd, pngheader, 8);
	
	for (i = 0; i < MAX_CHUNKS; i++){
		png_chunk *chunk;
		int tmp;
		
		chunk = *(chunks+i);
		
		tmp = htonl(chunk->length);
		chunk->crc = htonl(chunk->crc);

		if (memcmp(chunk->name, cgbichunk, 4)){ // Anything but a CgBI
			int ret;

			ret = write(fd, &tmp, 4);
			ret = write(fd, chunk->name, 4);
			
			if (chunk->length > 0){
				#ifdef TEST
                printf("About to write data to fd length %d\n", chunk->length);
                #endif
				ret = write(fd, chunk->data, chunk->length);
				if (!ret){
					#ifdef TEST
                    printf("%c%c%c%c size %d\n", chunk->name[0], chunk->name[1], chunk->name[2], chunk->name[3], chunk->length);
					perror("write");
                    #endif
				}
			}
			
			ret = write(fd, &chunk->crc, 4);
		}
		
		if (!memcmp(chunk->name, endchunk, 4)){
			break;
		}
        
        free(chunk->data);
        free(chunk->name);
        free(chunk);
        chunk = nil;
	}
	close(fd);
}

unsigned long mycrc(unsigned char *name, unsigned char *buf, int len) {
	uint32 crc;
	crc = crc32(0, name, 4);
	return crc32(crc, buf, len);
}