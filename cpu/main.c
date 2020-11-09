#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>


//#include "bmp.h"
#include "blur.c"

int main(int argc, char ** argv) {
	double time;
	 clock_t begin, end;

	 begin = clock();
	FILE * inputp = fopen(argv[1],"r");
	if (inputp == NULL) {
		fprintf(stderr,"could not open file");
		return EXIT_FAILURE;
	}
	
	FILE * outputp = fopen(argv[2],"w");
	if (outputp == NULL) {
		fprintf(stderr,"could not open output file");
		return EXIT_FAILURE;
	}

	BITMAPFILEHEADER b;
    fread(&b, sizeof(BITMAPFILEHEADER), 1, inputp);

	BITMAPINFOHEADER a;
	fread(&a, sizeof(BITMAPINFOHEADER), 1, inputp);

	int height = abs(a.biHeight);
	int width = a.biWidth;

	//Allocating memory for image
	RGBTRIPLE(*image)[width] = calloc(height, width * sizeof(RGBTRIPLE));
	if (image == NULL)
    {
        fprintf(stderr, "Not enough memory to store image.\n");
        fclose(outputp);
        fclose(inputp);
        return EXIT_FAILURE;
    }

	// Determine padding for scanlines
    int padding = (4 - (width * sizeof(RGBTRIPLE)) % 4) % 4;

    // Iterate over infile's scanlines
    for (int i = 0; i < height; i++)
    {
        // Read row into pixel array
        fread(image[i], sizeof(RGBTRIPLE), width, inputp);

        // Skip over padding
        fseek(inputp, padding, SEEK_CUR);
    }

	blur(height, width, image);

	fwrite(&b, sizeof(BITMAPFILEHEADER), 1, outputp);
	fwrite(&a, sizeof(BITMAPINFOHEADER), 1, outputp);

	// Write new pixels to outfile
    for (int i = 0; i < height; i++)
    {
        // Write row to outfile
        fwrite(image[i], sizeof(RGBTRIPLE), width, outputp);

        // Write padding at end of row
        for (int k = 0; k < padding; k++)
        {
            fputc(0x00, outputp);
        }
    }


	free(image);
	fclose(inputp);
	fclose(outputp);
	end = clock();
	time = (double)(end-begin) / CLOCKS_PER_SEC;
    printf("Total CPU time: %e s\n", time);
	return EXIT_SUCCESS;
}