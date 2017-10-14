function [A] = HilbertCurve(size)
%HILBERTCURVE Summary of this function goes here
%   Detailed explanation goes here

A = zeros(0,2);
B = zeros(0,2);
C = zeros(0,2);
D = zeros(0,2);

north = [ 0  1];
east  = [ 1  0];
south = [ 0 -1];
west  = [-1  0];

order = log2(size);
for n = 1:order
  AA = [B ; north ; A ; east  ; A ; south ; C];
  BB = [A ; east  ; B ; north ; B ; west  ; D];
  CC = [D ; west  ; C ; south ; C ; east  ; A];
  DD = [C ; south ; D ; west  ; D ; north ; B];

  A = AA;
  B = BB;
  C = CC;
  D = DD;
end

A = [0 0; cumsum(A)];
A = A + 1;
% 
% plot(A(:,1), A(:,2), 'clipping', 'off')
% axis equal, axis off
end

