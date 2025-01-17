clc; clear all; close all
currentFolder;
excludeTime = 10;

%% Load a video with blobs to analyse
[fileName,pathName] = uigetfile([pwd,'*.avi'],'Load video to analyse');
if fileName == 0
    disp('The program was terminated by the user');
    return
else
    tic
    disp('...')
    disp('Loading video via mmread...');
    pfName = [pathName fileName];
    disp(pfName);
    % Read the video file information
    videoFileInfo = VideoReader(pfName);

    % Define the number of frames in the video
    numFramesInVideo = videoFileInfo.Duration * videoFileInfo.FrameRate;
    % Define the time interval between frames
    timeInterval = 1/videoFileInfo.FrameRate;

    % Define the first frame to start analysis
    startFrame = 1;
    % Exclude the frames of sample failure
    numFrames2Delete = excludeTime * videoFileInfo.FrameRate;
    % Define the last frame to end analysis
    endFrame = numFramesInVideo - numFrames2Delete;
    % List the total number of frames to analyse
    listFrames = [startFrame : videoFileInfo.FrameRate : endFrame]';
    % Define the total number of frames to analyse
    numFrames2Analyse = length(listFrames);
    % Add a time stamp to each frame to analyse
    timeStamp = listFrames .* timeInterval;

    % Only read the video frames to analyse (saves time)
    videoFrames2Analyse = mmread(pfName,listFrames);
    disp('Finished loading video...');
    toc
    disp('...')
end


% Loop through the desired frames
tic
disp('...')
disp('Loading video via readFrame...');
frames = cell([1,length(listFrames)]);
for ii = 1:length(listFrames)
    % Set the CurrentTime property to the specific frame
    frameNumber = listFrames(ii);
    videoFileInfo.CurrentTime = (frameNumber - 1) / videoFileInfo.FrameRate;  % Convert frame number to time
    % Read the frame
    frames{ii} = readFrame(videoFileInfo);
    progress(ii,length(listFrames));
end
disp('Finished loading video...');
toc
disp('...')