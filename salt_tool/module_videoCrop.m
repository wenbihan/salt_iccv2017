function reconBlock = module_videoCrop(video_out, param)
%MODULE_VIDEOCROP Summary of this function goes here
%   Detailed explanation goes here
% [aa, bb, nFrame] = size(video_out);
frontPadSize = param.frontPadSize;
aa0 = param.aa0;
bb0 = param.bb0;
reconBlock = video_out(frontPadSize + 1 : frontPadSize + aa0, ...
        frontPadSize + 1 : frontPadSize + bb0, :);
end

