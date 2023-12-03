
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#define ERR_BADARGS 1
#define ERR_BADFILE 2
#define ERR_ALLOC 4

/* = stdint for DOS = */

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
#if __WORDSIZE == 64
typedef int int32_t;
typedef unsigned int uint32_t;
#else
typedef long int32_t;
typedef unsigned long uint32_t;
#endif

/* = Color Table = */

#define CGA_BLACK 0
#define CGA_CYAN 1
#define CGA_MAGENTA 2
#define CGA_WHITE 3

#define CGA_DITHER_BLACK 1
#define CGA_DITHER_MAGENTA 2
#define CGA_DITHER_WHITE 4

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

const uint8_t gc_cga_color_table[] = {
   /*  0 */ CGA_BLACK,
   /*  1 */ CGA_CYAN,
   /*  2 */ CGA_CYAN,
   /*  3 */ CGA_CYAN,
   /*  4 */ CGA_MAGENTA,
   /*  5 */ CGA_MAGENTA,
   /*  6 */ CGA_CYAN,
   /*  7 */ CGA_WHITE,
   /*  8 */ CGA_WHITE,
   /*  9 */ CGA_CYAN,
   /* 10 */ CGA_CYAN,
   /* 11 */ CGA_CYAN,
   /* 12 */ CGA_MAGENTA,
   /* 13 */ CGA_MAGENTA,
   /* 14 */ CGA_CYAN,
   /* 15 */ CGA_WHITE
};

const uint8_t gc_cga_flags_table[] = {
   /*  0 */ 0,
   /*  1 */ CGA_DITHER_BLACK,
   /*  2 */ CGA_DITHER_BLACK,
   /*  3 */ 0,
   /*  4 */ CGA_DITHER_BLACK,
   /*  5 */ CGA_DITHER_BLACK,
   /*  6 */ CGA_DITHER_MAGENTA,
   /*  7 */ CGA_DITHER_BLACK,
   /*  8 */ CGA_DITHER_BLACK,
   /*  9 */ 0,
   /* 10 */ 0,
   /* 11 */ 0,
   /* 12 */ 0,
   /* 13 */ 0,
   /* 14 */ CGA_DITHER_WHITE,
   /* 15 */ 0
};

#define COLOR_TABLE_CONST( idx, lc, uc, r, g, b ) \

/* = Program = */

int main( int argc, char* argv[] ) {
   int retval = 0;
   int i = 0;
   FILE* bmp_file = NULL;
   uint32_t bmp_offset = 0;
   uint32_t bmp_type = 0;
   uint32_t bmp_sz = 0;
   int32_t bmp_line_w = 0;
   int32_t bmp_lines = 0;
   uint32_t iter_pos = 0;
   uint8_t bmp_px = 0;
   uint32_t iter_line = 0;
   uint32_t cga_plane_sz = 0;
   uint8_t* cga_bytes_plane_1 = NULL;
   uint32_t cga_byte_idx_plane_1 = 0;
   uint8_t cga_bit_idx_plane_1 = 0;
   uint8_t* cga_bytes_plane_2 = NULL;
   uint32_t cga_byte_idx_plane_2 = 0;
   uint8_t cga_bit_idx_plane_2 = 0;
   uint8_t* cga_plane_bytes_sel = NULL;
   uint32_t* cga_plane_byte_idx_sel = NULL;
   uint8_t* cga_plane_bit_idx_sel = NULL;

   assert( sizeof( int32_t ) == 4 );
   assert( sizeof( uint32_t ) == 4 );
   assert( sizeof( uint16_t ) == 2 );
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
   fread( &bmp_line_w, 4, 1, bmp_file );
   if( 0 == bmp_line_w ) {
      printf( "bad line width (%d): %s\n", bmp_line_w, argv[1] );
      retval = ERR_BADFILE;
      goto cleanup;
   }

   /* Get bitmap height. */
   fseek( bmp_file, 0x16, SEEK_SET );
   fread( &bmp_lines, 4, 1, bmp_file );
   if( 0 == bmp_lines ) {
      printf( "bad line count (%d): %s\n", bmp_lines, argv[1] );
      retval = ERR_BADFILE;
      goto cleanup;
   }

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

   cga_plane_sz = ((bmp_lines * bmp_line_w) / 4) / 2;
   printf( "using CGA plane size: %d\n", cga_plane_sz );
   cga_bytes_plane_1 = calloc( cga_plane_sz, 1 );
   if( NULL == cga_bytes_plane_1 ) {
      printf( "allocation error: CGA plane 1\n" );
      retval = ERR_ALLOC;
      goto cleanup;
   }
   cga_bytes_plane_2 = calloc( cga_plane_sz, 1 );
   if( NULL == cga_bytes_plane_2 ) {
      printf( "allocation error: CGA plane 1\n" );
      retval = ERR_ALLOC;
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

      if( 0 == iter_pos % bmp_line_w ) {
         printf( "\n" );
      }
#endif /* DEBUG_BMP */

      /* TODO: Output CGA bytes. */
      if( 0 == bmp_lines % 2 ) {
         /* Even plane. */
         cga_plane_bytes_sel = cga_bytes_plane_1;
         cga_plane_byte_idx_sel = &cga_byte_idx_plane_1;
         cga_plane_bit_idx_sel = &cga_bit_idx_plane_1;
      } else {
         /* Odd plane. */
         cga_plane_bytes_sel = cga_bytes_plane_2;
         cga_plane_byte_idx_sel = &cga_byte_idx_plane_2;
         cga_plane_bit_idx_sel = &cga_bit_idx_plane_2;
      }

      cga_plane_bytes_sel[*cga_plane_byte_idx_sel] <<= 2;
      cga_plane_bytes_sel[*cga_plane_byte_idx_sel] |= 
         gc_cga_color_table[bmp_px];

      /* Figure out the next byte/bit. */
      (*cga_plane_bit_idx_sel) += 2;
      if( *cga_plane_bit_idx_sel >= 8 ) {
         *cga_plane_bit_idx_sel = 0;
         (*cga_plane_byte_idx_sel)++;
      }

      /* Next pixel. */
      iter_pos++;
      if( 0 == iter_pos % bmp_line_w ) {
         iter_line++;
      }
   }

   for( i = 0 ; cga_plane_sz > i ; i++ ) {
      printf( "0%02xh, ", cga_bytes_plane_1[i] );
   }
   printf( "\n" );

#ifdef DEBUG_BMP
   printf( "\n" );
#endif /* DEBUG_BMP */

cleanup:
   return retval;
}

