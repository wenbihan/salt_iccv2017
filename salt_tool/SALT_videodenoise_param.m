function param = SALT_videodenoise_param(param)
%Function for setting up paramters for SALT based video denoising
%
%Note that all input parameters need to be set prior to simulation. 
%This tuning function is just an example settings which we provide, for 
%generating the results in the "SALT paper". However, the user is
%advised to carefully modify this function, thus choose optimal values  
%for the parameters depending on the specific data or task at hand.
sig                     =   param.sig;                  % noise level
param.stride            =   1;                          % spatial stride
param.strideTemporal    =   1;                          % temp. stride
param.dim               =   8;
param.nSpatial          =   param.dim * param.dim;      % 2D patch size
% search tensor depth and window size
if sig <= 5
    param.csim              =   0.5;
    param.searchWindowSize  =   30;
elseif sig <= 15
    param.csim              =   0.75;
    param.searchWindowSize  =   28;
elseif sig <= 20
    param.csim              =   1;
    param.searchWindowSize  =   26;
else
    param.csim              =   1.5;
    param.searchWindowSize  =   26;
end
param.tensorSize        =   round(param.csim * param.nSpatial);        % tensor size
param.n                 =   param.nSpatial * param.tensorSize;  % tensor pixel#
param.numPatchMini      =   15 * param.n;                       % mini-batch size
param.numTensorMini     =   param.numPatchMini / param.tensorSize;

% --- << KNN step >> ---
param.tempSearchRange       =   4;
param.spaSearchNumber       =   1;

% --- << low rank approx (LR) >> ---
param.LRthr0              =   1.1;            % threshold coefficient
param.LRthr               =   param.LRthr0 * sig; % actual threshold

% --- << transform learning (TL) >> ---
param.TLthr0            =   3;
param.TLthr             =   param.TLthr0 * sig;
param.isMeanRemoved     =   true;
param.nFrame            =   9;              % TL tensor temporal depth
                             
param.n3D               =   param.nFrame * param.nSpatial;      % VIDO patch size
param.VIDOmini          =   15 * param.n3D;
switch sig
    case 0.8
        alpha = 0.61;
    case 1
        alpha = 0.62;
    case 1.5
        alpha = 0.64;
    case 2
        alpha = 0.65;
    case 3
        alpha = 0.66;
    case 4
        alpha = 0.67;
    case 5
        alpha = 0.68;
    case 6
        alpha = 0.69;
    case 7
        alpha = 0.70;
    case 8
        alpha = 0.705;
    case 9
        alpha = 0.71;
    case 10
        alpha = 0.72;
    case 13.5
        alpha = 0.75;
    case 15
        alpha = 0.76;
    case 18
        alpha = 0.8;
    case 20
        alpha = 0.83;
    case 43
        alpha = 0.88;
    case 45
        alpha = 0.88;
    case 50
        alpha = 0.89;
    otherwise
        alpha = 0.8;
end
param.alpha = alpha;
% for online Transform learning
param.isRecon = true;
% combination weight
param.sparseWeight = 60;
param.noisyWeight = 1e-4 / sig;
end

