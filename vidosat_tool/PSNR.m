function [ t ] = PSNR(X)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
[aa,bb]=size(X);
t=20*log10((sqrt(aa*bb))*255/(norm(X,'fro')));
end

