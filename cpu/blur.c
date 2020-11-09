#include "bmp.h"
#include <math.h>

void blur(int height, int width, RGBTRIPLE image[height][width]) {
	RGBTRIPLE temp[height][width];

	for (int i = 0; i < height; i++) {
		for (int j = 0; j < width; j++) {
			int redT = 0;
			int greenT = 0;
			int blueT = 0;
			float count = 0.00;

			for ( int a = -10; a < 10; a++) {
				for (int b = -10; b < 10; b++) {
					if (i + a < 0 || i + a > height - 1 || j + b < 0 || j + b > width -1)
						continue;

					redT += image[i+a][j+b].rgbtRed;
					greenT += image[i+a][j+b].rgbtGreen;
					blueT += image[i+a][j+b].rgbtBlue;

					count++;
				}
			}
			temp[i][j].rgbtRed = round(redT/count);		
			temp[i][j].rgbtGreen = round(greenT/count);	
			temp[i][j].rgbtBlue = round(blueT/count);		
		}
	}
	for(int i = 0; i < height; i++) {
		for(int j = 0; j < width; j++) {
			image[i][j].rgbtRed = temp[i][j].rgbtRed;
			image[i][j].rgbtGreen = temp[i][j].rgbtGreen;
			image[i][j].rgbtBlue = temp[i][j].rgbtBlue;
		}
	}

	return;
}