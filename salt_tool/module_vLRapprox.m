function [denoisedPatch, weights] = ...
    module_vLRapprox(extractPatch, blk_arr, blk_pSize, param)
%MODULE_LRAPPROX Summary of this function goes here
%   Detailed explanation goes here
% Goal: Apply Low-rank approximation by hard SVD thresholding
% Inputs:
%   1. extractPatch     : extracted patches from the video
%   2. blk_arr          : BM patch indices in each tensor
%   3. blk_pSize        : tensor size
%   4. param            : parameters for BM
%       - numTensorPatch    : #patch in each tensor
%       - thr               : Singular value threshold, = thr0 * sigma
%       - n                 : spatial dimension
% Outputs:
%   1. denoisedPatch    : denoised patch (with weights) after LR approx.
%   2. Weight           : weights (#times that appears in tensor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   paramters
numPatchPerFrame    =   param.numPatchPerFrame;
numFrameBuffer      =   param.numFrameBuffer;
ns                  =   param.nSpatial;
dim                 =   param.dim;
thr                 =   param.LRthr;            % LR threshold value
% output
denoisedPatch       =   zeros(ns, numPatchPerFrame, numFrameBuffer);
weights             =   zeros(1, numPatchPerFrame, numFrameBuffer);
numRef              =   size(blk_arr, 2);
%   LR
for  k  =  1 : numRef
    curTensorSize           =   blk_pSize(:, k);
    curTensorInd            =   blk_arr(1 : curTensorSize, k);
    Scenter                 =   extractPatch(:, curTensorInd);
    sizeScale               =   (sqrt(double(curTensorSize)) + dim)^2;    
    % %%%% LR part %%%%
    mB              =   mean(Scenter, 2);
    Scenter         =   double(bsxfun(@minus, Scenter, mB));    % de-mean
    % Eigen Value
    [bas, eigenVal] =   eig((Scenter*Scenter'));
    diat            =   diag(eigenVal)/ sizeScale;
    thr2            =   thr^2;
    diatthr         =   (diat>thr2);
    diatthr(end)    =   true;                   % at least rank-1
    ys              =   bas * diag(diatthr) * bas' * Scenter;
    ys              =   bsxfun(@plus, ys, mB);              % LR estimate 
    denoisedPatch(:, curTensorInd)          =   ...
        denoisedPatch(:, curTensorInd) + ys;
    weights(:, curTensorInd)                =   ...
        weights(:, curTensorInd) + 1;
end
end