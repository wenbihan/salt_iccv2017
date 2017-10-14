function [output, nFrames, Height, Width] = avi2grayVideo(input)
%Function for loading video (.avi) to tensor data
%
% The avi2grayVideo algorithm takes video location (string) as input,
% outputs 3D tensor (for gray-scale video), and its size.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs -
%       1. input : video location, a string.
%
% Outputs -
%       1. output: 3D / 4D tensor data, for gray-scale / color video
%       2. nFrames - number of frames
%       3. Height - height of frame
%       4. Width - width of frame

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%% version 1, use 'VideoReader', which will be removed %%%%%%%%%%%
% mov = aviread(input);
% mov = VideoReader(input);
% output = read(mov, [1 inf]);
% [Height, Width, numChannel, nFrames] = size(output);
% if numChannel == 1
%     output = reshape(output, [Height, Width, nFrames]);
% end
%%%%%%%%%%% version 2, use 'readFrame' %%%%%%%%%%%
mov = VideoReader(input);
nFrames = mov.FrameRate * mov.Duration;
Height = mov.Height;
Width = mov.Width;
if strcmp(mov.VideoFormat, 'Grayscale')
    output = zeros(Height, Width, nFrames);
    currentFrame = 1;
    while hasFrame(mov)
%     for i = 1 : mov.NumberOfFrames
        output(:, :, currentFrame) = double(readFrame(mov));
%         output(:, :, currentFrame) = double(read(mov, currentFrame));
        currentFrame = currentFrame + 1;
    end
else
    output = zeros(Height, Width, 3, nFrames);
    currentFrame = 1;
    while hasFrame(mov)
        output(:, :, :, currentFrame) = double(readFrame(mov));
        currentFrame = currentFrame + 1;
    end    
end
end

