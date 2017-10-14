function [ psnr ] = PSNR(X)
% calculate the PSNR value for 2D iamge
[aa bb]=size(X);
psnr=20*log10((sqrt(aa*bb))*255/(norm(X,'fro')));
end

