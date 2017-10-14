function [denoisedPatch, weights, buffer] = module_TLapprox(extractPatch, ...
    buffer, blk_arr, param)
%PROCESSSTATIC Summary of this function goes here
%   Detailed explanation goes here
% Goal : online VIDOSAT denoising the buffer data, update transform
% Inputs:
%   1. buffer            : buffer data
%           - YXT
%           -  D
%   3. idx               : spatial patch size, i.e., [dim, dim]
%   4. D                 : n * n, most recent transform
%   5. rows / cols       : row/col indices
%   6. tempBatch         : temporal Gt data, aa * bb * K * 2
%   7. tempWeight        : temporal weights, aa * bb * K * 2
%   8. tempFrom / tempTo : 1 or 2, pointer to I/O
% Output:
%   6. denoisedPatch     : temporal Gt data, aa * bb * K * 2
%   7. weights           : temporal weights, aa * bb * K * 2\
%   1. buffer            : buffer data
%           - RS         : n*n, YY'
%           - TS         : n*n, YX'
%           - l3         : scalar, regularizer weight 
%           - blocks     : reconstructed blocks
%   4. D                 : n * n, most recent transform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   paramters
numPatchPerFrame    =   param.numPatchPerFrame;
numFrameBuffer      =   param.numFrameBuffer;
ns                  =   param.nSpatial;
sizeMini            =   param.VIDOmini;
n3D                 =   param.n3D;
nFrame              =   param.nFrame;

% output
miniBlock           =   zeros(n3D, sizeMini);
denoisedPatch       =   zeros(ns, numPatchPerFrame, numFrameBuffer);
weights             =   zeros(1, numPatchPerFrame, numFrameBuffer);
blk_arr             =   blk_arr(1 : param.nFrame, :);
numTotal            =   size(blk_arr, 2);

currData        =   0;
TLstart         =   1;            % global pointer
for     k   =   1   :   numTotal
    currData                 =   currData + 1;
    curTensorInd            =   blk_arr(:, k);
    curPatch3D              =   extractPatch(:, curTensorInd);
    miniBlock(:, currData)   =   curPatch3D(:);
    if ((currData == sizeMini) || k == numTotal)
        if (k == numTotal)
            miniBlock       =   miniBlock(:, 1 : currData);
        end      
        buffer = onlineUTLupdate_analysis(buffer, param, miniBlock);
        denoisedBlock           =   buffer.blocks;
        denoisedBlock(denoisedBlock < 0)    =   0;
        denoisedBlock(denoisedBlock > 255)  =   255;
        TLscores            =   buffer.scores;
        denoisedBlock           =   bsxfun(@times, denoisedBlock, TLscores');
        for idxBM   =   TLstart : k
            curTensorInd    =   blk_arr(:, idxBM);
            idxMini         =   idxBM - TLstart + 1;
            curTensor       =   reshape(denoisedBlock(:, idxMini), [ns, nFrame]);
            curWeight       =   TLscores(idxMini);
            denoisedPatch(:, curTensorInd)   =   ...s
                denoisedPatch(:, curTensorInd) + curTensor;
            weights(:, curTensorInd)         =   weights(:, curTensorInd) + curWeight;
%             weights(:, curTensorInd)         =   weights(:, curTensorInd) + 1;
        end 
        TLstart         =   k + 1;
        currData        =   0;
    end
end
end

