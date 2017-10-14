function X = module_video2patch(video, param)
%MODULE_IM2PATCH Summary of this function goes here
% Goal : decompose the 3D tensor (e.g., video) into 2D patches
psize = param.dim;
stride = param.stride;
[aa, bb, numFrame] = size(video);
%   Detailed explanation goes here
f       =   psize;
N       =   floor((aa-f+1) / stride);
M       =   floor((bb-f+1) / stride);
L       =   N*M;                            % total #patches
X       =   zeros(f*f, L, numFrame, 'single');        % n
for idxFrame = 1 : numFrame
    k       =   0;
    for i  = 1:f
        for j  = 1:f
            k      =  k+1;
            blk    =  video(i : stride : aa-f+i, ...
                j : stride : bb-f+j, ...
                idxFrame);
            X(k, :, idxFrame) =  blk(:)';
        end
    end
end
end

