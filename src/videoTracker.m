function videoTracker(varargin)
%% Function description:
% This function calculates the displacement of and between blobs drawn
% along the gauge length of a dog-bone sample subjected to uniaxial
% tension.
% Initial input requires a calibration image with a scale bar. Following
% that, blob displacemnt is calculated from a video of the blobs when the
% dog-bone sample was subjected to uniaxial tension.
%
%% Author:
% Dr. Azdiar Gazder, 2024, azdiaratuowdotedudotau
%
%% Acknowledgements:
% This function is modified from the video extensometer script by:
% M. Battaini, Deformation behaviour and twinning mechanisms of
% commercially pure titanium alloys, PhD thesis, Monash University, 2007.
% https://bridges.monash.edu/articles/thesis/Deformation_behaviour_and_twinning_mechanisms_of_commercially_pure_titanium_alloys/4534439?file=7341602
%
% This function uses ancillary functions located at:
% https://github.com/jeromewang-github/MyPresentations/tree/7fd320603c8325f3d0694a41df751e92f8a7fe29/Week_9/code/KeyFrame%20Extraction/mmread
% and
% ~\mtex\tools\option_tools
%
%% Syntax:
%
%% Input:
%
%% Output:
%  *.avi        - a video file containing the displacement of and between
%                 a defined number of blobs.
%  *.txt        - a text file containing the displacement of and between
%                 a defined number of blobs.
%
%% Options:
% 'exclude'    - @double, defines the seconds to exclude from the end of
%                the video.
% 'blobs'      - @double, defines the number of blobs to track.
% 'blobArea'   - @double, defines the minimum blob area to track.
% 'frames'     - @double, defines the frame rate to save the output video.
% 'threshold'  - @double, defines the value of the mask used to
%                distiniguish the blobs from the background.
% 'filter'     - @double, a [1 x 2] vector defining the median filter mask
%                size.
%


%% Pre-define options
excludeTime = get_option(varargin,'exclude',10);
numBlobs = get_option(varargin,'blobs',3);
blobArea = get_option(varargin,'blobArea',200);
frameRate = get_option(varargin,'frames',5);
medfilterSize = get_option(varargin,'filter',[3 3]);


%% Default directories - Do not modify
iniDir = pwd;
Ini.dataPath = [strrep(iniDir,'\','/'),'/data/'];
Ini.inputPath = [Ini.dataPath,'input/'];
Ini.outputPath = [Ini.dataPath,'output/'];
%%



%% Define the screen size
% % Calculate the "true" monitor DPI 
% % % https://au.mathworks.com/matlabcentral/answers/54434-finding-the-height-of-windows-taskbar
% toolkit = java.awt.Toolkit.getDefaultToolkit();
% screenSize = toolkit.getScreenSize();
% jframe = javax.swing.JFrame;
% insets = toolkit.getScreenInsets(jframe.getGraphicsConfiguration());
% screenWidth = screenSize.width;
% taskBarOffset = insets.bottom;
% screenHeight = screenSize.height- taskBarOffset;

% Calculate the "virtual" monitor DPI 
% Open an empty figure, save the handle to a variable
fh = figure('Menu','none','ToolBar','none','Visible','off');
% Calculate the height of the taskbar to offset
taskBarOffset = fh.OuterPosition(4) - fh.InnerPosition(4) + fh.OuterPosition(2) - fh.InnerPosition(2);
% Close the empty figure
delete(fh);
pause(0.075);
% Define the screen dimensions (ex-taskbar)
fPos = get(0,'screensize');
screenWidth = round(fPos(3));
screenHeight = round(fPos(4) - taskBarOffset);
%%



%% Load a calibration image with a scale bar
[fileName,pathName] = uigetfile([Ini.inputPath,'*.tif'],'Load calibration image');
if fileName == 0
    error('The program was terminated by the user');
    return;
else
    tic
    disp('...')
    disp('Loading calibration image...');
    pfName = [pathName fileName];
    disp(pfName);
    % Read the image file information
    imageFileInfo = imfinfo(pfName);
    % Read the image file
    imageFrame = imread(pfName);
    disp('Finished loading calibration image...');
    toc
    disp('...')
end
%%



%% Select the scalebar region of interest (ROI) in the image for calibration
uiwait(helpdlg({'LEFT-click, drag & release = select a rectangular region of interest (ROI) for calibration'}));
% Open a figure, save the handle to a variable
f = figure('Units','pixels');
% Make the figure invisible
set(f, 'Visible', 'off');
% Display the image
imshow(imageFrame);
% Maximise the figure window
f.WindowState = 'maximized';
% Maintain plot aspect ratio
pbaspect([imageFileInfo.Width/imageFileInfo.Height 1 1]);
set(f,'Name','Select a rectangle to make the calibration measurement within','NumberTitle','on');
% Make the figure visible
set(f, 'Visible', 'on');
% Get the position of the selected ROI for calibration
roiPosition = getrect(gcf);
clf; close all;
% Crop the selected ROI for calibration from the image
roiSelectedArea = imcrop(imageFrame,roiPosition);

% Open a figure, save the handle to a variable
f = figure('Units','pixels');
% Make the figure invisible
set(f, 'Visible', 'off');
% Display the image
imshow(roiSelectedArea);
% Maximise the figure window
f.WindowState = 'maximized';
% Maintain plot aspect ratio
pbaspect([size(roiSelectedArea,2)/size(roiSelectedArea,1) 1 1]);
set(f,'Name','Select a line defining the calibration distance','NumberTitle','on');
% Make the figure visible
set(f, 'Visible', 'on');
% Select a line to calibrate
[x,y] = getYLine(gcf);
% Calculate the calibration distance in pixels
% To ensure a horizontal line is always calculated, force the line to be 
% horizontal by adjusting the second y-coordinate
y(2) = y(1); 
pixelDistance = round(sqrt((y(2)-y(1))^2 + (x(2)-x(1))^2));
clf; close all;
disp('...')
disp('USER INPUT')
unitDistance = input('Enter unit distance (in mm) = ');
% Calculate the calibration
calibration = unitDistance/pixelDistance;
disp('...')
disp('IMAGE CALIBRATION')
disp(['Image frame resolution      = ',num2str(imageFileInfo.Width),' x ',num2str(imageFileInfo.Height),' pixels']);
disp(['Distance drawn: ', num2str(pixelDistance), ' pixels  = ', num2str(unitDistance), ' mm']);
disp(['Calibration   : 1 pixel     = ',num2str(calibration),' mm']);
disp(['                1 mm        = ',num2str(1/calibration),' pixels']);
disp('...')
%%



%% Load a video with blobs to analyse
[fileName,pathName] = uigetfile([pathName,'*.avi'],'Load video to analyse');
if fileName == 0
    disp('The program was terminated by the user');
    return
else
    tic
    disp('...')
    disp('Loading video...');
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
    listOfFrames = [startFrame : videoFileInfo.FrameRate : endFrame]';
    % Define the total number of frames to analyse
    numFrames2Analyse = length(listOfFrames);
    % Add a time stamp to each frame to analyse
    timeStamp = listOfFrames .* timeInterval;

    % Loop through the listed frames
    videoFrames2Analyse = cell([1,length(listOfFrames)]);
    for ii = 1:length(listOfFrames)
        % Set the CurrentTime property to the specific frame
        frameNumber = listOfFrames(ii);
        % Convert frame number to time
        videoFileInfo.CurrentTime = (frameNumber - 1) / videoFileInfo.FrameRate;  
        % Read the frame
        videoFrames2Analyse{ii} = readFrame(videoFileInfo);
        progress(ii,length(listOfFrames));
    end

    % Only read the video frames to analyse (saves time)
%     videoFrames2Analyse = repmat(struct(), length(listOfFrames), 1);
%     videoFrames2Analyse = mmread(pfName,listFrames);
    disp('Finished loading video...');
    toc
    disp('...')
end
%%



%% Calibrate the video frames
disp('...')
disp('VIDEO CALIBRATION')
calibration = calibration * (imageFileInfo.Width/videoFileInfo.Width);
disp(['Video frame resolution      = ',num2str(videoFileInfo.Width),' x ',num2str(videoFileInfo.Height),' pixels']);
disp(['Calibration   : 1 pixel     = ',num2str(calibration),' mm']);
disp(['                1 mm        = ',num2str(1/calibration),' pixels']);
disp('...')
%%



%% Select a blob region of interest (ROI) in the video for analysis
uiwait(helpdlg({'LEFT-click, drag & release = select a rectangular region of interest (ROI) for blob tracking'}));
f = figure('Units','pixels');
set(f,'position',[(screenWidth-(videoFileInfo.Width/2))/2,...
    (screenHeight-(videoFileInfo.Height/2))/2,...
    videoFileInfo.Width/2,...
    videoFileInfo.Height/2]);
% roiSelect = videoFrames2Analyse.frames(1,1).cdata;
roiSelect = videoFrames2Analyse{1};
imshow(roiSelect);
set(f,'Name','Select a rectangle containing blobs for tracking','NumberTitle','on');
roiPosition = getrect(f);
clf; close all;
%%



%% Define the blobs to track
% Set the handler for blob analysis
hblob = vision.BlobAnalysis('AreaOutputPort', false, ...
    'CentroidOutputPort', true, ...
    'BoundingBoxOutputPort', true', ...
    'MinimumBlobArea', blobArea, ...
    'MaximumCount', numBlobs);
%%



%% Define the paths to save data and video
outputSubfolder = fullfile(Ini.outputPath,fileName(1:end-4));
if ~exist(outputSubfolder, 'dir')
    mkdir(outputSubfolder);
end
pfName_dataOutput = [outputSubfolder,'/vidExt_',fileName(1:end-4),'.txt'];
pfName_videoOutput = [outputSubfolder,'/vidExt_',fileName(1:end-4),'.avi'];
%%



%% Create an AVI object
videoObj = VideoWriter(pfName_videoOutput,'Uncompressed AVI');
videoObj.FrameRate = frameRate;
% videoObj.VideoCompressionMethod = 'None';
open(videoObj);
%%



%% Analyse the selected frames and save the video
tic
disp('...')
disp('Analysing video frames...')
f = figure('Units','pixels');
set(f,'color','white');
figWidth = 1500; figHeight = 500;
set(f,'position',[(screenWidth-figWidth)/2,...
    (screenHeight-figHeight)/2,...
    figWidth,...
    figHeight]);

coordinates = zeros(numBlobs,2,numFrames2Analyse); % rows = number of blobs; columns = X and Y co-ordinates
displacement_eachBlob = zeros(numFrames2Analyse,numBlobs); % columns = number of blobs
avgDisplacement_eachBlob = zeros(numFrames2Analyse,1);

distance_12 = zeros(numFrames2Analyse,1);
distance_13 = zeros(numFrames2Analyse,1);
distance_23 = zeros(numFrames2Analyse,1);
displacement_12 = zeros(numFrames2Analyse,1);
displacement_13 = zeros(numFrames2Analyse,1);
displacement_23 = zeros(numFrames2Analyse,1);
avgDisplacement_betweenBlobs = zeros(numFrames2Analyse,1);

for frameNumber = 1:numFrames2Analyse

    % Crop the frame to the ROI for analysis
    %     currentFrame = videoFrames2Analyse.frames(1,frameNumber).cdata;
    currentFrame = videoFrames2Analyse{frameNumber};
    roi2Analyse = imcrop(currentFrame,roiPosition);

    %% ROI image processing
    % Define a threshold
    level = get_option(varargin,'threshold',graythresh(roi2Analyse));
    % Binarise the image using the threshold
    roiBinary = imbinarize(roi2Analyse,level);
    % Dilate the white regions
    roiDilate = bwmorph(roiBinary(:,:,1),'dilate');
    % Filter out the noise by using a median filter (default = 3x3)
    roiMedianFilter = medfilt2(roiDilate, medfilterSize);
    % Get the coordinates of the centroids and bounding boxes of the blobs
    [centroid, bBox] = step(hblob, roiMedianFilter);
    coordinates(:,:,frameNumber) = centroid;

    % Distance between blobs in current frame
    distance_12(frameNumber,1) = calibration .* sqrt((coordinates(1,1,frameNumber)-coordinates(2,1,frameNumber)).^2 +...
        (coordinates(1,2,frameNumber)-coordinates(2,2,frameNumber)).^2);
    distance_13(frameNumber,1) = calibration .* sqrt((coordinates(1,1,frameNumber)-coordinates(3,1,frameNumber)).^2 +...
        (coordinates(1,2,frameNumber)-coordinates(3,2,frameNumber)).^2);
    distance_23(frameNumber,1) = calibration .* sqrt((coordinates(2,1,frameNumber)-coordinates(3,1,frameNumber)).^2 +...
        (coordinates(2,2,frameNumber)-coordinates(3,2,frameNumber)).^2);

    if frameNumber ~= 1
        % Displacement of each blob between current and starting frames
        displacement_eachBlob(frameNumber,:) = (calibration .* sqrt((coordinates(:,1,frameNumber)-coordinates(:,1,1)).^2 +...
            (coordinates(:,2,frameNumber)-coordinates(:,2,1)).^2))';
        avgDisplacement_eachBlob(frameNumber,1) = mean(displacement_eachBlob(frameNumber,:));

        % Displacement between blobs between current and starting frames
        displacement_12(frameNumber,1) = distance_12(frameNumber,1) - distance_12(1,1);
        displacement_13(frameNumber,1) = distance_13(frameNumber,1) - distance_13(1,1);
        displacement_23(frameNumber,1) = distance_23(frameNumber,1) - distance_23(1,1);
        avgDisplacement_betweenBlobs(frameNumber,1) = mean([displacement_12(frameNumber,1),...
            displacement_13(frameNumber,1),...
            displacement_23(frameNumber,1)]);
    end

    %% Sub-plot 1: Processed image of the blobs
    subplot(1,3,1);
    % Plot the image processed blobs
    imshow(roiMedianFilter);
    hold all
    % Plot a cross marker at their centroids
    plot(centroid(1,1),centroid(1,2),'r+','MarkerSize',12,'LineWidth',1);
    plot(centroid(2,1),centroid(2,2),'g+','MarkerSize',12,'LineWidth',1);
    plot(centroid(3,1),centroid(3,2),'b+','MarkerSize',12,'LineWidth',1);
    % Plot a rectangular bounding box around each blob
    rectangle('Position',[bBox(1,1) bBox(1,2) bBox(1,3) bBox(1,4)],'EdgeColor','r','LineWidth',2);
    rectangle('Position',[bBox(2,1) bBox(2,2) bBox(2,3) bBox(2,4)],'EdgeColor','g','LineWidth',2);
    rectangle('Position',[bBox(3,1) bBox(3,2) bBox(3,3) bBox(3,4)],'EdgeColor','b','LineWidth',2);
    hold off
    set(gca,'units','pixels','nextplot','replacechildren');
    %%

    xLimits = [min(timeStamp),max(timeStamp)];

    %% Sub-plot 2: Displacement of each blob between current and starting frames
    subplot(1,3,2);
    axis square
    if max(max(displacement_eachBlob)) ~= 0
        yLimits2 = [0,max(max(displacement_eachBlob))];
    else
        yLimits2 = [0,0.0001];
    end
    set(gca,'xlim',xLimits,...
        'ylim',yLimits2,...
        'box','on',...
        'units','pixels',...
        'nextplot','add');
    xlabel('Time (s)');%,'fontSize',12);
    ylabel('Displacement between frames (mm)');%,'fontSize',12);
    plot(timeStamp(1:frameNumber),displacement_eachBlob(1:frameNumber,1),'.-r',...
        timeStamp(1:frameNumber),displacement_eachBlob(1:frameNumber,2),'.-g',...
        timeStamp(1:frameNumber),displacement_eachBlob(1:frameNumber,3),'.-b',...
        timeStamp(1:frameNumber),avgDisplacement_eachBlob(1:frameNumber,1),'.-k');
    legend({'B1','B2','B3','AVG'},'location','southoutside','orientation','horizontal');


    %% Sub-plot 3: Displacement between blobs between current and starting frames
    subplot(1,3,3);
    axis square
    if max(max([displacement_12,...
            displacement_13,...
            displacement_23])) ~= 0
        yLimits3 = [0,max(max([displacement_12,...
            displacement_13,...
            displacement_23]))];
    else
        yLimits3 = [0,0.0001];
    end
    set(gca,'xlim',xLimits,...
        'ylim',yLimits3,...
        'box','on',...
        'units','pixels',...
        'nextplot','add');
    xlabel('Time (s)');
    ylabel('Displacement between blobs (mm)');
    plot(timeStamp(1:frameNumber),displacement_12(1:frameNumber,1),'.-c',...
        timeStamp(1:frameNumber),displacement_13(1:frameNumber,1),'.-m',...
        timeStamp(1:frameNumber),displacement_23(1:frameNumber,1),'.-y',...
        timeStamp(1:frameNumber),avgDisplacement_betweenBlobs(1:frameNumber,1),'.-k');
    legend({'B1-B2','B1-B3','B2-B3','AVG'},'location','southoutside','orientation','horizontal');
    %%

    writeVideo(videoObj, getframe(f));
end
disp('Finished analysing video frames...');
toc
disp('...')
%%


%% Save the *.avi video file
tic
disp('...')
disp('Saving video frames...')
close(videoObj);
toc
disp('...')
%%


%% Save the *.txt data file
tic
disp('...')
disp('Saving data...')
fileHeader = {'Time (s)',...
    'frameDisplacement_B1 (mm)',...
    'frameDisplacement_B2 (mm)',...
    'frameDisplacement_B3 (mm)',...
    'Avg. frameDisplacement (mm)',...
    'blobDistance_B12 (mm)',...
    'blobDistance_B13 (mm)',...
    'blobDistance_B23 (mm)',...
    'blobDisplacement_B12 (mm)',...
    'blobDisplacement_B13 (mm)',...
    'blobDisplacement_B23 (mm)',...
    'Avg. blobDisplacement (mm)'};
fileData = [timeStamp,...
    displacement_eachBlob(:,1),...
    displacement_eachBlob(:,2),...
    displacement_eachBlob(:,3),...
    avgDisplacement_eachBlob(:,1),...
    distance_12(:,1),...
    distance_13(:,1),...
    distance_23(:,1),...
    displacement_12(:,1),...
    displacement_13(:,1),...
    displacement_23(:,1),...
    avgDisplacement_betweenBlobs(:,1)]';
fid = fopen(pfName_dataOutput,'wt');
fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',fileHeader{:});
fprintf(fid,'%.8f\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\t\n',fileData);
fclose(fid);
toc
disp('...')
%%

end
