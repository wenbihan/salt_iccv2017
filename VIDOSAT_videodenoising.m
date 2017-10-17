function [Xr, outputParam] = VIDOSAT_videodenoising(data, param)
%Function for denoising the gray-scale video using VIDOSAT denoising
%algorithm.
%
%Note that all input parameters need to be set prior to simulation. We
%provide some example settings using function VIDOSAT_videodenoise_param.
%However, the user is advised to carefully choose optimal values for the
%parameters depending on the specific data or task at hand.
%
%
% The VIDOSAT_videodenoising algorithm denoises an gray-scale video based
% on online 3D transform learning. Detailed discussion can be found in
%
%
% (1) "Video denoising by online 3D sparsifying transform learning",
% written by B. Wen, S. Ravishankar, and Y Bresler, in Proc. IEEE
% International Conference on Image Processing (ICIP), Sep. 2015.
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
%                   - nSpatial: Spatial patch size as (Example: 64)
%                   - stride: stride of overlapping patches (Example: 1)
%                   - strideTemporal: stride of overlapping frames (Example: 1)
%                   - nFrame: number of frames in each tensor patch
%                   (Example: 8)
%                   (Optional, set if you know what you are doing)
%                   - showStats: Set to 1, to output Status parameters
%                   - isTesting: Set to 1 for fast testing the code
%
% Outputs -
%       1. Xr - Image reconstructed with VIDOSAT_Videodenoising algorithm.
%       2. outputParam: Structure that contains the parameters of the
%       algorithm output for analysis as follows
%       -
%                   - transform:  learned online transform
%                   - psnrXr: PSNR of Xr, if the oracle is provided
%                   - timeOut:   run time of the denoising algorithm
%                   - framePSNR: per-frame PSNR values
%       (optional)
%                   - condNum: condition number of transform in process
%                   - PSNRprocess: PSNR value in process for each pass
%                   - finalcondNum: final condition of learned transform

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% initialization %%%%%%%%%%%%%%%%%%
param = VIDOSAT_videodenoising_param(param);
oracle = data.oracle;
noisy = data.noisy;                                 % noisy
% if isfield(param, 'outputPath')
%     output = param.outputPath;                          % output path
% end
ns = param.nSpatial;
patchFrame = param.nFrame;
stride = param.stride;                              % overlap
strideTemporal = param.strideTemporal;              % timeOverlap
D = param.transform;
sig2 = param.sig2;

[aa, bb, numFrame] = size(noisy);
% [oracle, numFrame, aa, bb] = avi2grayVideo(oracle);     % loading oracle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IMout=zeros(aa, bb, numFrame);
Weight=zeros(aa, bb, numFrame);
bbb=sqrt(ns);                                       % spatial patch width
n = ns*patchFrame;                                  % tensor dimension
numPass = param.numPass;

maxNumber = param.maxNumber;                      % mini-batch Size, M
l0 = param.l0;                                    % regularizer weight, lambda_0
%%% weighting for initial tensor data
w1 = 0.001;
w2 = 0.20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% Main Program %%%%%%%%%%%%%%%%%%%%%%%%%
%%%% indexing tensor data %%%%
blkSize = [bbb, bbb];
slidingDis = stride;
idxMat = zeros(size(noisy(:,:,1)) - blkSize +1);
idxMat([[1:slidingDis:end-1],end],[[1:slidingDis:end-1],end]) = 1; % take blocks in distances of 'slidingDix', but always take the first and last one (in each row and column).
idx = find(idxMat);
N = length(idx);                                % N is number of patches
[rows, cols] = ind2sub(size(idxMat),idx);
%%%% initialize storage buffer %%%%
% numDataSet = zeros(1, numPass);                 % to delete?
l3 = zeros(1, numPass);                         
RS =zeros(n, n, numPass);
TS =zeros(n, n, numPass);
if isfield(param, 'showStats') && param.showStats
    condNum = zeros(numPass, numFrame - patchFrame + 1);            % condition number in process
    PSNRprocess = zeros((numFrame - patchFrame + 1), numPass);      % per-frame PSNR
end    
tempBatch = zeros(aa, bb, patchFrame, 2);
tempWeight = zeros(aa, bb, patchFrame);

%%%%% extracting tensor data sequentially %%%%%
tic;
for frameNo = 1 : strideTemporal : (numFrame - patchFrame + 1)
    tempBatch(:, :, :, 1) = noisy(:, :, frameNo : frameNo + patchFrame - 1);
    %%%% multi-pass within each frame %%%%%
    for k = 1 : numPass         
        tempFrom = mod(k - 1, 2) + 1;               % denoising source
        tempTo = 3 - tempFrom;                      % denoising destiny
        tempBatch(:, :, :, tempTo) = zeros(size(tempWeight));   % empty the destiny
        currdata = 0;                               % tesnor sequential index
        blocks = zeros(n, maxNumber);               % initialize miniBatch
        sigma = sig2(1, k);                 % current (estimated) sigma
        % corresponding forgetting factor, weight over noisy, sparsity penalty
        [alpha, lam, l5] = getVIDOSAT_multipass_param(sigma); 
        % accumulate mini-batches within frame %
        for i = 1:length(idx)                   
            currBlock = tempBatch(rows(i):rows(i)+blkSize(1)-1, cols(i):cols(i)+blkSize(2)-1, :, tempFrom);
            currBlock = permute(currBlock,[1,3,2]);
            j = mod((i-1), maxNumber) + 1;
            blocks(:,j) = currBlock(:);
            % when the current mini-batch is accumulated %
            if ((j == maxNumber) || i == length(idx) )
                if (i == length(idx))
                    blocks = blocks(:,1:j);     %shrink size of last block
                end
%                 numDataSet(1, k) = numDataSet(1, k) + 1;          % to delete?
                % sparse coding
                X1 = D(:, :, k)*blocks;
                st = (sqrt(l5))*ones(1,size(X1,2));
                X2 = X1.*(bsxfun(@ge,abs(X1),st));
                % accumulate YY'
                RS(:, :, k) = alpha * RS(:, :, k) + (blocks*blocks');
                % accumulate lambda
                l3(1, k) = alpha * l3(1, k) + l0*((norm(blocks,'fro'))^2);
                l2=l3(1, k);
                % svd
                [U,S,V]=svd(RS(:, :, k) + (l3(1, k)*eye(n)));
                LL=U*(S^(1/2))*V';
                LL2=(inv(LL));
                % accumulate YX'
                TS(:, :, k) = alpha * TS(:, :, k) + (blocks*X2');
                [Q1,Si,R]=svd(LL2*TS(:, :, k));
                % Update D
                sig=diag(Si);
                gamm=(1/2)*(sig + (sqrt((sig.^2) + 2*l2)));
                B=R*(diag(gamm))*Q1';
                D(:, :, k) = B*(LL2);
                %%%%% reconstruction %%%%%%%
                % sparse coding with updated D
                X1 = D(:, :, k)*blocks;
                st = (sqrt(l5))*ones(1,size(X1,2));
                X2 = X1.*(bsxfun(@ge,abs(X1),st));
                % recon
                blocks = (D(:, :, k)\X2 + (lam*blocks))/(1+lam);
                % putting back to (intermediate) locations
                for jj = 1:1000:size(blocks,2)
                    jumpSize = min(jj+1000-1,size(blocks,2));
                    ZZ = blocks(:,jj:jumpSize);
                    inx=(ZZ<0);ing= ZZ>255; ZZ(inx)=0;ZZ(ing)=255;  % project to pixel range
                    for ii  = jj:jumpSize
                        currdata = currdata + 1;
                        col = cols(currdata);
                        row = rows(currdata);
                        block = reshape(ZZ(:,ii-jj+1),[bbb,patchFrame, bbb]);            %swap dimension
                        block = permute(block, [1,3,2]);            % permute back
                        % block =reshape(ZZ(:,ii-jj+1),[bbb,bbb,patchFrame]);
                        tempBatch(row:row+bbb-1,col:col+bbb-1, :, tempTo) = tempBatch(row:row+bbb-1,col:col+bbb-1, :, tempTo) + block;
                        if (k == 1 && frameNo == 1)
                            tempWeight(row:row+bbb-1,col:col+bbb-1, :) = tempWeight(row:row+bbb-1,col:col+bbb-1, :) + ones(size(block));            % save time
                        end
                    end
                end
            end
        end
        if (k < numPass)
            tempBatch(:, :, :, tempTo) = tempBatch(:, :, :, tempTo) ./ tempWeight;
            if isfield(param, 'showStats') && param.showStats
                PSNRprocess(frameNo, k) = PSNR3D(tempBatch(:,:,:,tempTo) - oracle(:, :, frameNo : frameNo + patchFrame - 1));
            end
        else
            if isfield(param, 'showStats') && param.showStats
                PSNRprocess(frameNo, k) = PSNR3D(tempBatch(:, :, :, tempTo) ./ tempWeight - oracle(:, :, frameNo : frameNo + patchFrame - 1));
            end
        end
    end
    % when multi-pass processing is finished
    %%%%%%%%%%%% adjust the weight for starting frames %%%%%%%%%%%%%%%
    if (frameNo == 1)
        IMout(:, :, frameNo : frameNo + patchFrame - 1) = IMout(:, :, frameNo : frameNo + patchFrame - 1) + tempBatch(:, :, :, tempTo) * w1;
        Weight(:, :, frameNo : frameNo + patchFrame - 1) = Weight(:, :, frameNo : frameNo + patchFrame - 1) + tempWeight * w1;
        %             tempBatch(:, :, :, tempTo) = tempBatch(:, :, :, tempTo) * w1;
        %             tempWeight = tempWeight * w1;
    elseif (frameNo == 2)
        IMout(:, :, frameNo : frameNo + patchFrame - 1) = IMout(:, :, frameNo : frameNo + patchFrame - 1) + tempBatch(:, :, :, tempTo) * w2;
        Weight(:, :, frameNo : frameNo + patchFrame - 1) = Weight(:, :, frameNo : frameNo + patchFrame - 1) + tempWeight * w2;
        %             tempBatch(:, :, :, tempTo) = tempBatch(:, :, :, tempTo) * w2;
        %             tempWeight = tempWeight * w2;
    else
        IMout(:, :, frameNo : frameNo + patchFrame - 1) = IMout(:, :, frameNo : frameNo + patchFrame - 1) + tempBatch(:, :, :, tempTo);
        Weight(:, :, frameNo : frameNo + patchFrame - 1) = Weight(:, :, frameNo : frameNo + patchFrame - 1) + tempWeight;
    end
    condNum(k, frameNo) = cond(D(:, :, k));
end
% checkFlag = (N == currdata) && (ceil(N/maxNumber) == numDataSet)      % to delete?
%%%%%%% averaged over weights %%%%%%%
Xr = IMout ./ Weight;
timeOut = toc;
% psnrXr = 20*log10((sqrt(aa*bb*numFrame))*255/(norm(double(Xr(:))-double(oracle(:)),'fro')));
psnrXr = PSNR3D(Xr - oracle);
% SSIM4 = ssim(Xr, oracle)
%%%%% frame-by-frame PSNR %%%%%
framePSNR = zeros(1, numFrame);
for i = 1 : numFrame
    framePSNR(1, i) = PSNR(Xr(:,:,i) - oracle(:,:,i));
end
outputParam.timeOut = timeOut;
outputParam.psnrXr = psnrXr;
outputParam.framePSNR = framePSNR;
outputParam.transform = D;
if isfield(param, 'showStats') && param.showStats
    outputParam.finalcondNum = condNum(:,end);
    outputParam.PSNRprocess = PSNRprocess;
    outputParam.condNum = condNum;
end
end