#include <stdio.h>
#include <stdlib.h>
#include <time.h>
extern "C" {
#include "ppmFile.h"
}

// kernel function that blurs image based on block IDs.
__global__ void blur(int *d_width, int *d_height, int *d_radius, unsigned char *d_input, unsigned char*d_output){
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;

    int offset;

    //for loop to loop through all the channels in a thread. 
    for(int channel = 0; channel < 3; channel++){
        int temp = 0;
        int num = 0;

        //nested for loop to go through all the pixels within the radius.
        for(int y = j - (*d_radius); y <= j + (*d_radius); y++)
        {
            for(int x = i - (*d_radius); x < i + (*d_radius); x++){
                
                if(x >=0 && x < *d_width && y>=0 && y < *d_height){
                    offset = (y * (*d_width) + x) * 3 + channel; //setting the offset of the current pixels to blur the image within radius.
                    temp += d_input[offset];
                    num++;
                }
            }
        }
        //averaging the pixel values.
        temp = temp / num;
        offset = (j * (*d_width) + i) * 3 + channel;
        d_output[offset] = temp;
    }

}

int main (int argc, char *argv[]){
    double time_DTH, time_allocateHTD,time_kernel;
    clock_t begin_allocateHTD, end_allocateHTD, begin_kernel, end_kernel, begin_DTH, end_DTH;
    
    
    
    //Host variable
    //width heigth of image and radius of the blur filter.
    int width, height, radius;
    //input image and output image struct. defined in ppmFile.
    Image *inImage, *outImage;
    //data of input image.
    unsigned char *data;

    //Device variable
    //input image data
    unsigned char *d_input;
    //output image data
    unsigned char *d_output;
    //width, height and radius passed to kernel
    int *d_width, *d_height, *d_radius;

    //unsigned char *output = (unsigned char *)malloc(sizeof(unsigned char*) * image_size);

    if(argc != 4){
        printf("Incorrect input argument should include radius, input file and output file.\n");
        return 0;
    }

    //initializing values.
    radius = atoi(argv[1]);
    inImage = ImageRead(argv[2]);
    width = inImage->width;
    height = inImage->height;
    data = inImage->data;

    //check the values of the images.
    printf("Using image: %s, width: %d, height: %d, blur radius: %d\n",argv[2],width,height,radius);


    //Grids based on size of the block 32 * 32
    dim3 blockD(32,32);
    dim3 gridD((width + blockD.x - 1)/blockD.x, (height + blockD.y - 1)/blockD.y);

    //size of image pixels. 3 is number of channels. 
    int image_size = width * height * 3;

    begin_allocateHTD = clock();
    //allocate memory for GPU
    cudaMalloc((void**)&d_input, sizeof(unsigned char*) * image_size);
    cudaMalloc((void**)&d_output, sizeof(unsigned char*) * image_size);
    cudaMalloc((void**)&d_radius, sizeof(int*));
    cudaMalloc((void**)&d_height, sizeof(int*));
    cudaMalloc((void**)&d_width, sizeof(int*));

    //copy values to GPU
    //HostToDevice
    cudaMemcpy(d_input, data, image_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_width, &width, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_height, &height, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_radius, &radius, sizeof(int), cudaMemcpyHostToDevice);

    end_allocateHTD = clock();

    begin_kernel = clock();
    //call blur kernel for GPU execution.
    blur<<<gridD, blockD>>>(d_width, d_height, d_radius, d_input,d_output);

    end_kernel = clock();

    
    //create new image and clear the image to copy blurred image from the device.
    outImage = ImageCreate(width,height);
    ImageClear(outImage,255,255,255);

    
    begin_DTH = clock();
    cudaDeviceSynchronize();

    //copy blured out image from gpu.
    //Device to Host
    cudaMemcpy(outImage->data, d_output, image_size, cudaMemcpyDeviceToHost);
    
    end_DTH = clock();
    //write blurred image into the file name passed as argument.
    ImageWrite(outImage, argv[3]);

    time_allocateHTD = (double)(end_allocateHTD-begin_allocateHTD) / CLOCKS_PER_SEC;
    printf("Allocation and Host to Device Time: %e s\n", time_allocateHTD);

    time_kernel = (double)(end_kernel-begin_kernel) / CLOCKS_PER_SEC;
    printf("Kernel Time: %e s\n", time_kernel);

    time_DTH = (double)(end_DTH-begin_DTH) / CLOCKS_PER_SEC;
    printf("Device to Host Time: %e s\n", time_DTH);

    printf("Total Time : %e s\n",time_allocateHTD + time_kernel + time_DTH);
    //free memory
    free(inImage->data);
    free(outImage->data);
    cudaFree(d_input);
    cudaFree(d_output);
    cudaFree(d_width);
    cudaFree(d_height);
    cudaFree(d_radius);

    return 0;


}