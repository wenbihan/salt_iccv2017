function [X, nonZeromap] = sparse_l0(X, threshold)
%sparse_SPIEl0 Summary of this function goes here
%   Detailed explanation goes here
[~, maxInd] = max(abs(X));
[n, N] = size(X);
nonZeromap = (abs(X) >= threshold);
base = 0 : n : n*(N - 1);
maxInd = maxInd + base;
nonZeromap(maxInd) = true;
X = X .* nonZeromap;
nonZeromap = sum(nonZeromap)';
end

