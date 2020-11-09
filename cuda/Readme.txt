To Compile the Code:
    nvcc -o blur ppmFile.c blur.cu
    nvcc -o <any name for executable file> <ppm Library file name.c> <cuda file name .cu>

To Run the program:
    ./blur 5 input.ppm output.ppm
    ./<name of executable file> <radius> <input ppm file> <output ppm file>


Sample Picture taken from:
    https://filesamples.com/formats/ppm

Sample Picture resized using:
    http://convert-my-image.com/ImageConverter
