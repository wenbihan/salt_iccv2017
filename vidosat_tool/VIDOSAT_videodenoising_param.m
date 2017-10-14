function [param] = VIDOSAT_videodenoising_param(param)
%Function for tuning paramters for VIDOSAT denoising
%
%Note that all input parameters need to be set prior to simulation. 
%This tuning function is just an example settings which we provide, for 
%generating the results in the "VIDOSAT paper". However, the user is
%advised to carefully modify this function, thus choose optimal values  
%for the parameters depending on the specific data or task at hand.

n = param.nSpatial * param.nFrame;
sig = param.sig;
%% multi-pass denoising signal list     -   sig2
switch sig
    case 5
        sig2 = [5];
    case 10
		sig2 = [9,3];
    case 15
		sig2 = [13.5, 3, 1.5, 0.8];
    case 20
		sig2 = [18,4,2];
    case 50
        sig2=[45,10,2,1];
    case 100
		sig2 = [90,20,4,3];       
    otherwise
        sig2 = sig;
end
param.sig2 = sig2;

numPass = size(sig2, 2);
param.numPass = numPass;
param.l0 = 0.01;                                          % regularizer weight, lambda_0
param.maxNumber = 15*n;                                   % mini-batch Size, M

% %% coefficient  -   la
% la = 0.01/sig;

%% initial OCTOBOS   -   transform
D1 = dctmtx(sqrt(param.nSpatial));                              % spatial transform init.
D2 = dctmtx(param.nFrame);                            % temporal transform init.
D0 = kron(kron(D1, D2), D1);
if(det(D0)<0)
    D0(1,:)=-D0(1,:);
end
D = zeros(size(D0, 1), size(D0, 2), numPass);
for i = 1 : numPass
    D(:, :, i) = D0;                                % 3D transform init.
end
param.transform = D;

% param.la = la;
end

