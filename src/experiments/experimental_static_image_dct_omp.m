clear all;
close all;
clc;

%% Project paths
scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fullfile(scriptDir, '..', '..');

addpath(fullfile(repoRoot, 'src', 'algorithms'));

%% Read input image
imagePath = fullfile(repoRoot, 'data', 'cameraman_test_image.jpg');

if ~isfile(imagePath)
    error('Test image not found at: %s', imagePath);
end

Orig_Image = im2double(imread(imagePath));

% Convert to grayscale if the image is RGB
if size(Orig_Image, 3) == 3
    Orig_Image = rgb2gray(Orig_Image);
end

figure;
imshow(Orig_Image);
title('Original Test Image');

%% DCT sparsifying transform
[rows, cols] = size(Orig_Image);

F_row = dctmtx(rows);
F_col = dctmtx(cols);

Sparse_Image = F_row * Orig_Image * F_col';

figure;
imshow(Sparse_Image, []);
title('Sparse Image in DCT Domain');

%% Get sparse vector
S = size(Orig_Image);
N = numel(Orig_Image);
%% reshape from matrix into vector, stacking columns under one another from
%left to right
k_w=1;  
Sparse_Vector = zeros(S(1,1)*S(1,2),1);
for j = 1:S(1,2)
    for i = 1:S(1,1)
        Sparse_Vector(k_w,1)=Sparse_Image(i,j);
        k_w = k_w+1;
    end
end

%% now we create a random gaussian sampling matrix
num_samples = 3500;
Random_G_Sam_m = rand(num_samples,N);
for x = 1:num_samples
    for y =1:N
        if (Random_G_Sam_m(x,y)+ 0.001 >= 1)
            Random_G_Sam_m(x,y) = 1;
        else
            Random_G_Sam_m(x,y) = 0;
        end
    end
end


Random_Sample_Y = Random_G_Sam_m * Sparse_Vector; 

%There are infinite solutions to (random matrix * transform) * solution =
%sample
%% we must pick the best one

theta = Random_G_Sam_m * dctmtx(size(N,1));

%To pick the correct solution, we will use the OMP algorithm

solution = (omp_recovery(Random_Sample_Y,theta,N)');

%% convert image vector back to pixel matrix
%S = size(solution);                     
Solution_Pixel_Matrix = zeros(100,100); %pixel matrix
k=1;
j=1;
for i = 1 : 10000
    if(k > 100)
        k=1;
        j=j+1;
    end
    Solution_Pixel_Matrix(k,j) = solution(i);
    k=k+1;
end

%Invert 2d discrete cosine transform
Solution_Pixel_Matrix = idct2(Solution_Pixel_Matrix); %use line 34 -> faster

imshow(Solution_Pixel_Matrix)

static_reconstruct_error = norm(Solution_Pixel_Matrix - Orig_Image) / norm(Orig_Image)
