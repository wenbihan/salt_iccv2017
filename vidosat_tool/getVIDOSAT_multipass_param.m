function [alpha, lam, l5] = getVIDOSAT_multipass_param(sigma)
%GETVIDOSAT_MULTIPASS_PARAM Summary of this function goes here
%   Detailed explanation goes here
%%%%%%%%% forgetting factor %%%%%%%%%%
switch sigma
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
        lam = (1e-4 / sigma);               % weight over noisy observation
        l5 = (1.9 * sigma)^2;               % sparsity penalty
end

