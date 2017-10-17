function [enlargedVideo, BMparam] = ...
    module_videoEnlarge(video, BMparam)
%MODULE_IMAGEENLARGE Summary of this function goes here
% Goal: enlarge the image by symmetry for BM purpose
% Inputs:
%   1. video            : [aa0, bb0, numFrame] size video (gray-scale)
%   2. BMparam          : parameters for BM
%       - dim               : patch width
%       - n                 : n patch spatial dimension (vectorized)
%       - BMstride            : patch extraction stride
%       - searchWindowSize  : BM search window size
% Outputs:
%   1. enlargedVideo    :   [aa, bb, numFrame] enlarged video
%   2. BMparam          :   enlarging parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters
[aa0, bb0, numFrame]        =   size(video);
dim                         =   BMparam.dim;
stride                      =   BMparam.stride;
searchWindowSize            =   BMparam.searchWindowSize;

% equal size extension
frontPadSize        =   floor((searchWindowSize - dim) / 2);     
modnx               = mod(aa0, stride);
endRowPadSize       = frontPadSize + (stride - modnx) * (modnx ~= 0);    
modny               = mod(bb0, stride);
endColPadSize       = frontPadSize + (stride - modny) * (modny ~= 0);
BMparam.aa0         = aa0;
BMparam.bb0         = bb0;
BMparam.aa          = aa0+frontPadSize+endRowPadSize;
BMparam.bb          = bb0+frontPadSize+endColPadSize;
BMparam.frontPadSize    = frontPadSize;
% output initialization
enlargedVideo       =   zeros(BMparam.aa, BMparam.bb, numFrame);
% enlarge by symmertry per frame
for idxFrame = 1 : numFrame
    enlargedVideo(:, :, idxFrame)      =   ...
        enlarge(video(:, :, idxFrame), frontPadSize, endRowPadSize, endColPadSize);
end
end
function y = enlarge(x, frontPadSize, endRowPadSize, endColPadSize)
% enlarge matrix 
% Inputs:
%   x               : orig. image, size = nlin * ncol
%   a, b            : 
[nlin,ncol]=size(x);
y=x(:,[frontPadSize:-1:1 1:ncol ncol:-1:ncol-endColPadSize+1]);
y=y([frontPadSize:-1:1 1:nlin nlin:-1:nlin-endRowPadSize+1],:);
end