function [BMresult, BMsize, timeBM] = module_offlineBM(ref, param)
param = SALT_videodenoise_param(param);             % parameters
% (1-1) video frame-wise << enlarging >>
[ref, param]        =   module_videoEnlarge(ref, param);
[aa, bb, numFrame]  =   size(ref);
% parameters
dim                         =   param.dim;              % patch length, i.e., 8
tempSearchRange             =   param.tempSearchRange;  % range, i.e., 4
startChangeFrameNo          =   tempSearchRange + 1;    % start frame, i.e., 5
endChangeFrameNo            =   numFrame - tempSearchRange;                                       
blkSize                     =   [dim, dim];
slidingDis                  =   param.strideTemporal;
numFrameBuffer              =   tempSearchRange * 2 + 1;
param.numFrameBuffer        =   numFrameBuffer;
idxMat                      =   zeros([aa, bb] - blkSize + 1);
idxMat([[1:slidingDis:end-1],end],[[1:slidingDis:end-1],end]) = 1;
[indMatA, indMatB]          =   size(idxMat);
param.numPatchPerFrame      = 	indMatA * indMatB;
param.numPatchBuffer        =   param.numPatchPerFrame * param.numFrameBuffer;
% initialize output
BMresult            =   uint32(zeros(param.tensorSize, ...
    (aa-param.searchWindowSize+1) * (bb-param.searchWindowSize+1), ...
    numFrame));
BMsize              =   uint32(zeros(1, ...
    (aa-param.searchWindowSize+1) * (bb-param.searchWindowSize+1), ...
    numFrame));
% frame-wise BM starts
tic;
for frame = 1 : numFrame
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
    tempRef         =   ref(:, :, curFrameRange);

    % (1) patch extraction
    refPatch        =   module_video2patch(tempRef, param);    
    % (2) Block Matching, << Matching >>
    [blk_arr, ~, blk_pSize, param] = ...
        module_videoBM_fix(refPatch, param, centerRefFrame);
    BMresult(:, :, frame) = uint32(blk_arr);
    BMsize(:, :, frame) = uint32(blk_pSize);   
end
timeBM = toc;
end