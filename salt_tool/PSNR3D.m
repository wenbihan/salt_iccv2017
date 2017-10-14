function [ t ] = PSNR3D(X)  %#codegen
% Goal: calculate the psnr for 3D tensor (e.g., video)
[aa,bb, cc]=size(X);
t=20*log10((sqrt(aa*bb*cc))*255/(norm(X(:),'fro')));
end

