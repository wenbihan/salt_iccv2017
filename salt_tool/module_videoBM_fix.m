function [pos_arr, error_arr, numPatch_arr, BMparam] = ...
    module_videoBM_fix(extractPatch, BMparam, referenceFrame)
%MODULE_BM_FIX Summary of this function goes here
%   Detailed explanation goes here
% Goal: perform block matching (BM)
% Inputs:
%   1. extractPatch     : video patches
%   2. BMparam          : parameters for BM
%       - dim               : patch width
%       - n                 : n patch spatial dimension (vectorized)
%       - stride            : patch extraction stride
%       - searchWindowSize  : BM search window size
%   3. referenceFrame   : #frame used as reference for BM
% Outputs:
%   1. pos_arr          : [tensorSize, Nimage, Mimage] BM indexing
%   2. error_arr        : [tensorSize, Nimage, Mimage] BM errors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
aa                  =   BMparam.aa;
bb                  =   BMparam.bb;
dim                 =   BMparam.dim;
searchWindowSize    =   BMparam.searchWindowSize;
stride              =   BMparam.stride;
tensorSize          =   BMparam.tensorSize;
numFrame            =   size(extractPatch, 3);
% row / col number of total patches
Nimage              =   aa-dim+1;               
Mimage              =   bb-dim+1;               
% row / col index of search window center pos
Nwindow             =   1:stride:aa-searchWindowSize+1; 
Mwindow             =   1:stride:bb-searchWindowSize+1; 
% #patchs in search window
swidth              =   searchWindowSize - dim + 1;
swidth2             =   swidth^2;
%/// noisy all possible patch indexing
numTotalPatch       =   Nimage * Mimage * numFrame; 
idxTotalPatch       =   1 : numTotalPatch;                      
idxTotalPatch       =   reshape(idxTotalPatch, Nimage, Mimage, numFrame);
%/// reference patch indexing
numWindowN      =   length(Nwindow);
numWindowM      =   length(Mwindow);
%/// BM result indexing table
pos_arr         =   zeros(tensorSize, numWindowN*numWindowM);
error_arr       =   zeros(tensorSize, numWindowN*numWindowM);
numPatch_arr    =   ones(1, numWindowN*numWindowM) * tensorSize;        % for fixed Tensor Size     
% middle index (refernce patch index), wihtin the search window
mid             =   mod(swidth, 2) * ((swidth2+1)/2) + ...
    mod(swidth+1, 2) * (swidth2+swidth)/2;  
offsetPatch     =   (referenceFrame - 1) * swidth2;
mid             =   mid + offsetPatch;
for  i  =  1 : numWindowN
    for  j  =  1 : numWindowM
        %// noisy row / col
        row                     =   Nwindow(i);
        col                     =   Mwindow(j);
        %// neighborhood region of size (2S+1)^2 for non-boundary pixel (patch)
        %// search window range <--> all searchable patch indices
        idx                     =   ...
            idxTotalPatch(row : row+swidth-1, col : col+swidth-1, :);
        idx                     =   idx(:);
        %// all the patches in the region
        patchCandidate          =   extractPatch(:,idx);
        %// central patch
        meanCandidate           =   extractPatch(:, idx(mid));
        %// distance: Euclidean & sorting
        dis                     =   ...
            patchCandidate - meanCandidate(:, ones(1, swidth2 * numFrame));
        metric                  =   mean(dis.^2);
        [BMerror, ind]          =   sort(metric);
        %// take tensorSize-largest
        pos_arr(:, (j-1)*numWindowN + i)    =  idx( ind(1:tensorSize) );
        error_arr(:, (j-1)*numWindowN + i)  =  BMerror(ind(1:tensorSize));
    end
end
end

