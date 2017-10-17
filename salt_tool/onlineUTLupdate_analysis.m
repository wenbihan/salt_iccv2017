function updateBuffer = onlineUTLupdate_analysis(buffer, param, blocks)
%ONLINE_TLUPDATE Summary of this function goes here
%   Detailed explanation goes here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs -
%       1. buffer : buffer storage of online TL training -
%                   - YXT : accumulation of matrix YX';
%                   - D : n * n, most recent transform
%       2. param: Structure that contains the parameters of the
%       online_TLupdate algorithm. The various fields are as follows
%       -
%                   - alpha: forgetting factor
%                   - lam (optional): fidelity term weight
%                   - l5: l0 norm weight <-> hard threshold
%                   - isRecon (optional) : set to 1, if instant recon is
%                   needed.
%       3. blocks : n * N, current extracted tensor
% Outputs -
%       1. updateBuffer - updated buffer -
%                   - YXT : accumulation of matrix YX';
%                   - blocks : instant recon, if isRecon = true;
%                   - scores : the scores, inversely proportional to
%                   sparsity of each tensor pack
%                   - D: n * n, updated transform
%                   - sparsity : number of non-zero in each sparse code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% buffers
YXT                 =   buffer.YXT;
D                   =   buffer.D;
alpha               =   param.alpha;
thr                 =   param.TLthr;                % sparse coding threshold
sparseWeight        =   param.sparseWeight;
%%%%%%%%%%%%%%%%%%%%%% Main Program %%%%%%%%%%%%%%%%%%%
% (1) sparse coding
X1 = D * blocks;      
% X2 = X1.*(bsxfun(@ge,abs(X1),thr));
X2 = sparse_l0(X1, thr);
% (2) accumulate YX'
YXT = alpha * YXT + (blocks * X2');
% (3) svd
[U, ~, V] = svd(YXT);
% (4) Update D
D = V * U';
if isfield(param, 'isRecon') && param.isRecon
    % sparse coding with updated D
    X1 = D * blocks;
    %  enforce sparsity >= 1
    [X2, scores] = sparse_l0(X1, thr);
    updateBuffer.sparsity = scores;
    scores = sparseWeight ./ scores;  
    updateBuffer.TLaproxError = sum((X2 - X1).^2);
    % recon
    blocks = D' * X2;
    updateBuffer.blocks = blocks;               % instantaneous recon.
    updateBuffer.scores = scores;
end
%%%%%%%%%%%%%%%%%%%%%% Output %%%%%%%%%%%%%%%%%%%
updateBuffer.YXT = YXT;
updateBuffer.D = D;
end

