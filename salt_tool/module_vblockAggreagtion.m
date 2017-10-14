function [reconBlock, reconWeight]  = module_vblockAggreagtion(patches, weights, param)
%MODULE_AGGREAGTION Summary of this function goes here
%   Goal:   Aggregate the patches back to the images (shrinking) with weights
%   Inputs:
%       1. patches              : reconstructed patches
%       2. weights              : weights for LRpatch
%       3. param                : parameters for reconstruction
%   Outputs:
%       1. Xr                   : reconstructed image by patch aggregation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% parameters %%%%%%%%%%%%%%%%%%%%%%
aa                  =   param.aa;
bb                  =   param.bb;
% aa0                 =   param.aa0;
% bb0                 =   param.bb0;
nFrame              =   size(patches, 3); 
% frontPadSize        =   param.frontPadSize;
dim                 =   param.dim;
Mimage              =   aa - dim + 1;
Nimage              =   bb - dim + 1;
r                   =   1 : Mimage;
c                   =   1 : Nimage;
reconBlock          =   zeros(aa, bb, nFrame);
reconWeight         =   zeros(aa, bb, nFrame);

%%%%%%%%%%%%%%% Aggregation %%%%%%%%%%%%%%
for idxFrame = 1 : nFrame
    k                   =   0;
    curPatch            =   patches(:, :, idxFrame);
    curWeight           =   weights(:, :, idxFrame);
    for i  = 1 : dim
        for j  = 1 : dim
            k    =  k + 1;
            reconBlock(r-1+i, c-1+j, idxFrame)  =  ...
                reconBlock(r-1+i, c-1+j, idxFrame) + ...
                reshape(curPatch(k,:)', [Mimage Nimage]);     % reweighting
            reconWeight(r-1+i, c-1+j, idxFrame)  =  ...
                reconWeight(r-1+i, c-1+j, idxFrame) + ...
                reshape(curWeight', [Mimage Nimage]);
        end
    end
end

end

