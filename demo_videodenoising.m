clear
addpath('salt_tool');



% load the demo video data
load('./demo_data/salesman.mat');               % clean video
% simulated noise standard deviation
param.sig = 20;
noisy = double(clean) + param.sig * randn(size(clean));
% transfer to input data struct
data.noisy = double(noisy);
data.oracle = double(clean);        % add if denoised analysis is required



% ------------- pre-cleaning -----------
% Input: data
% Output: (1) ref - precleaned video, used for KNN block matching
%         (2) VIDOSATout - statistics of the precleaning.
% We provide 2 options as examples
% (1) using VIDOSAT gray-scale video denoising
% proposed in:
% "Video denoising by online 3D sparsifying transform learning",
% written by B. Wen, S. Ravishankar, and Y Bresler, in Proc. IEEE
% International Conference on Image Processing (ICIP), Sep. 2015.
%
% The Matlab implementation package is included
VIDOSATparam.sig = param.sig;
VIDOSATparam.nSpatial = 64;
VIDOSATparam.stride = 1;         
VIDOSATparam.nFrame = 8;
VIDOSATparam.strideTemporal = 1;
addpath('./vidosat_tool');
[ref, VIDOSATout] = VIDOSAT_videodenoising(data, VIDOSATparam);
% % (2) using VBM3D
% % need to download the VBM3D software package
% % available at http://www.cs.tut.fi/~foi/GCF-BM3D/BM3D.zip
% % unzip the package and put it in the SALT directory
% addpath('./BM3D');
% [ref, psnrBM3D] = ...
%     VBM3D_Bihan(data.noisy, param.sig, 0);
% data.ref        =   ref * 255;

% ------------- Blocking Matching -------------
% The block matching can be performed online, or offline
% There is a flag to control such option, param.onlineBMflag
% (1) offline BM before SALT denoising
param.onlineBMflag  = false;
[BMresult, BMsize, timeBM] = module_offlineBM(ref, param);
data.BMresult = BMresult;
data.BMsize = BMsize;
% (2) online BM during SALT denoising
param.onlineBMflag      =   true;
data.ref                =   ref;

% -------------- SALT based Video Denoising -----------------
[Xr, outputParam] = SALT_videodenoising(data, param);
fprintf('The PSNR of the SALT result = %.2f.\n', outputParam.PSNR);










