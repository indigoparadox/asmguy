
#include <stdio.h>
#include <assert.h>

#define ERR_BADARGS 1
#define ERR_BADFILE 2

/* = stdint for DOS = */

typedef unsigned char uint8_t;
#if __WORDSIZE == 64
typedef unsigned int uint32_t;
#else
typedef unsigned long uint32_t;
#endif

/* = Color Table = */

const uint8_t gc_black = 0;
const uint8_t gc_darkblue = 1;
const uint8_t gc_darkgreen = 2;
const uint8_t gc_teal = 3;
const uint8_t gc_darkred = 4;
const uint8_t gc_violet = 5;
const uint8_t gc_brown = 6;
const uint8_t gc_gray = 7;
const uint8_t gc_darkgray = 8;
const uint8_t gc_blue = 9;
const uint8_t gc_green = 10;
const uint8_t gc_cyan = 11;
const uint8_t gc_red = 12;
const uint8_t gc_magenta = 13;
const uint8_t gc_yellow = 14;
const uint8_t gc_white = 15;

#define COLOR_TABLE_CONST( idx, lc, uc, r, g, b ) \

/* = Program = */

int main( int argc, char* argv[] ) {
   int retval = 0;
   FILE* bmp_file = NULL;
   uint32_t bmp_offset = 0;
   uint32_t bmp_type = 0;
   uint32_t bmp_sz = 0;
   uint32_t bmp_linew = 0;
   uint32_t iter_pos = 0;
   uint8_t bmp_px = 0;

   assert( sizeof( uint32_t ) == 4 );
   assert( sizeof( uint8_t ) == 1 );

   if( 2 > argc ) {
      printf( "usage: %s <filename>\n", argv[0] );
      retval = ERR_BADARGS;
      goto cleanup;
   }

   bmp_file = fopen( argv[1], "rb" );
   if( NULL == bmp_file ) {
      printf( "bad file: %s\n", argv[1] );
      retval = ERR_BADFILE;
      goto cleanup;
   }
   fseek( bmp_file, 0, SEEK_END );
   bmp_sz = ftell( bmp_file );

   /* Get pixel data offset. */
   fseek( bmp_file, 0x0a, SEEK_SET );
   fread( &bmp_offset, 4, 1, bmp_file );
   if( bmp_offset >= bmp_sz ) {
      printf( "bad bitmap sz (%d): %s\n", bmp_offset, argv[1] );
   }

   /* Verify bitmap header size. */
   fseek( bmp_file, 0x0e, SEEK_SET );
   fread( &bmp_type, 4, 1, bmp_file );
   if( 40 != bmp_type ) {
      printf( "bad bitmap (0x%02x): %s\n", bmp_type, argv[1] );
      retval = ERR_BADFILE;
      goto cleanup;
   }

   /* Get bitmap line width. */
   fseek( bmp_file, 0x12, SEEK_SET );
   fread( &bmp_linew, 4, 1, bmp_file );

   /* Verify bitmap pixel size. */
   fseek( bmp_file, 0x1c, SEEK_SET );
   fread( &bmp_type, 4, 1, bmp_file );
   if( 8 != bmp_type ) {
      printf( "bad pixel sz (%d): %s\n", bmp_type, argv[1] );
      retval = ERR_BADFILE;
      goto cleanup;
   }

   /* Verify bitmap compression. */
   fseek( bmp_file, 0x1e, SEEK_SET );
   fread( &bmp_type, 4, 1, bmp_file );
   if( 0 != bmp_type ) {
      printf( "bad compression (0x%02x): %s\n", bmp_type, argv[1] );
      retval = ERR_BADFILE;
      goto cleanup;
   }

#ifdef DEBUG_BMP
   printf( "reading bmp data at 0x%0x:\n", bmp_offset );
#endif /* DEBUG_BMP */

   fseek( bmp_file, bmp_offset, SEEK_SET );
   while( iter_pos < bmp_sz ) {
      /* TODO: Handle line padding. */

      fread( &bmp_px, 1, 1, bmp_file );

#ifdef DEBUG_BMP
      if( gc_magenta == bmp_px ) {
         printf( "      " );
      } else {
         printf( "0x%02x ", bmp_px );
      }

      if( 0 == iter_pos % bmp_linew ) {
         printf( "\n" );
      }
#endif /* DEBUG_BMP */

      /* TODO: Output CGA bytes. */

      iter_pos++;
   }

#ifdef DEBUG_BMP
   printf( "\n" );
#endif /* DEBUG_BMP */

cleanup:
   return retval;
}

