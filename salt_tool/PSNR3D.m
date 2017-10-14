function [ t ] = PSNR3D(X)  %#codegen
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
[aa,bb, cc]=size(X);
t=20*log10((sqrt(aa*bb*cc))*255/(norm(X(:),'fro')));
end

