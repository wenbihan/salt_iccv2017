function [Xr, outputParam] = SALT_videodenoising(data, param)
%Function for denoising the gray-scale video using SALT denoising
%algorithm.
%
%Note that all input parameters need to be set prior to simulation. We
%provide some example settings using function SALT_videodenoise_param.
%However, the user is advised to carefully choose optimal values for the
%parameters depending on the specific data or task at hand.
%
% The SALT_videodenoising algorithm denoises an gray-scale video based
% on joint Sparse And Low-rank Tensor Reconstruction (SALT) method. 
% Detailed discussion can be found in
%
% (1) "Joint Adaptive Sparsity and Low-Rankness on the Fly:
%      An Online Tensor Reconstruction Scheme for Video Denoising",
% written by B. Wen, Y. Li, L, Pfister, and Y Bresler, in Proc. IEEE
% International Conference on Computer Vision (ICCV), Oct. 2017.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs -
%       1. data : Video data / path. The fields are as follows -
%                   - noisy: a*b*numFrame size gray-scale tensor for denoising
%                   - oracle: path to the oracle video (for
%                   PSNR calculation)
%
%       2. param: Structure that contains the parameters of the
%       VIDOSAT_videodenoising algorithm. The various fields are as follows
%       -
%                   - sig: Standard deviation of the additive Gaussian
%                   noise (Example: 20)
%                   - onlineBMflag : set to true, if online VIDOSAT
%                   precleaning is used.
% Outputs -
%       1. Xr - Image reconstructed with SALT_videodenoising algorithm.
%       2. outputParam: Structure that contains the parameters of the
%       algorithm output for analysis as follows
%       -
%                   - PSNR: PSNR of Xr, if the oracle is provided
%                   - timeOut:   run time of the denoising algorithm
%                   - framePSNR: per-frame PSNR values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%% parameter & initialization %%%%%%%%%%%%%%
% (0) Load parameters and data
param = SALT_videodenoise_param(param);
noisy = data.noisy;                                 % noisy
% (1-1) Enlarge the frame
[noisy, param] = module_videoEnlarge(noisy, param);
if param.onlineBMflag
    data.ref = module_videoEnlarge(data.ref, param);  
end
[aa, bb, numFrame] = size(noisy);               % height / width / depth
% (1-2) parameters
dim                         =   param.dim;          % patch length, i.e., 8
n3D                         =   param.n3D;          % TL tensor size
tempSearchRange             =   param.tempSearchRange;
startChangeFrameNo          =   tempSearchRange + 1;   
endChangeFrameNo            =   numFrame - tempSearchRange;  
blkSize                     =   [dim, dim];  
slidingDis                  =   param.strideTemporal;
numFrameBuffer              =   tempSearchRange * 2 + 1;
param.numFrameBuffer        =   numFrameBuffer;
nFrame                      =   param.nFrame;
% (1-3) 2D index
idxMat                      =   zeros([aa, bb] - blkSize + 1);
idxMat([[1:slidingDis:end-1],end],[[1:slidingDis:end-1],end]) = 1;
[indMatA, indMatB]          =   size(idxMat);
param.numPatchPerFrame      = 	indMatA * indMatB;
% (1-4) buffer and output initialization
IMout               =   zeros(aa, bb, numFrame);
Weight              =   zeros(aa, bb, numFrame);
buffer.YXT          =   zeros(n3D, n3D);
buffer.D            =   kron(kron(dctmtx(dim), dctmtx(dim)), dctmtx(nFrame));
%%%%%%%%%%%%%%% (2) Main Program - video streaming %%%%%%%%%%%%%
tic;
for frame = 1 : numFrame
    display(frame);
    % (0) select G_t
    if frame < startChangeFrameNo
        curFrameRange   =   1 : numFrameBuffer;
        centerRefFrame  =   frame;
    elseif frame > endChangeFrameNo
        curFrameRange   =   numFrame - numFrameBuffer + 1 : numFrame;
        centerRefFrame  =   frame - (numFrame - numFrameBuffer);
    else
        curFrameRange   =   frame - tempSearchRange : frame + tempSearchRange;
        centerRefFrame  =   startChangeFrameNo;
    end
    % (1) Input buffer
    tempBatch       =   noisy(:, :, curFrameRange);     
    extractPatch    =   module_video2patch(tempBatch, param);  % patch extraction
    % (2) KNN << Block Matching (BM) >>
    % Options: Online / Offline BM
    if param.onlineBMflag
    % (2-1) online BM using pre-cleaned data
        tempRef         =   data.ref(:, :, curFrameRange);
        refPatch        =   module_video2patch(tempRef, param);
        [blk_arr, ~, blk_pSize] = ...
            module_videoBM_fix(refPatch, param, centerRefFrame);
    else
        % (2-2) using offline BM result
        blk_arr         =   data.BMresult(:, :, frame);
        blk_pSize       =   data.BMsize(:, :, frame);
    end
    % (3) Denoising current G_t using LR approximation
    [denoisedPatch_LR, weights_LR] = ...
        module_vLRapprox(extractPatch, blk_arr, blk_pSize, param); 
    % (4) Denoising current G_t using Online TL
    [denoisedPatch_TL, frameWeights_TL, buffer] = ...
        module_TLapprox(extractPatch, buffer, blk_arr, param);
    % (5) fusion of the LR + TL + noisy here
    denoisedPatch = denoisedPatch_LR + denoisedPatch_TL + extractPatch * param.noisyWeight;
    weights = weights_LR + frameWeights_TL + param.noisyWeight;    
    % (6) Aggregation
    [tempBatch, tempWeight]  =    ...
        module_vblockAggreagtion(denoisedPatch, weights, param);
    % (7) update reconstruction
    IMout(:, :, curFrameRange) = IMout(:, :, curFrameRange) + tempBatch;
    Weight(:, :, curFrameRange) = Weight(:, :, curFrameRange) + tempWeight;
end
outputParam.timeOut = toc;
% (3) Normalization and Output
Xr = module_videoCrop(IMout, param) ./ module_videoCrop(Weight, param);
outputParam.PSNR = PSNR3D(Xr - double(data.oracle));
framePSNR = zeros(1, numFrame);
for i = 1 : numFrame
    framePSNR(1, i) = PSNR(Xr(:,:,i) - double(data.oracle(:,:,i)));
end
outputParam.framePSNR = framePSNR;
end






