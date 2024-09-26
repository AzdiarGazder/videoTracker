% *********************************************************************
%               videoTracker - Demonstration Example
% *********************************************************************
% This script demonstrates how to invoke the videoTracker function. 
% Save the calibration image and video in a sub-folder within the 
% ~/data/input directory.
% All output will be saved in a sub-folder of the same name in the 
% ~/data/output directory.
%
% *********************************************************************
% Dr. Azdiar Gazder, 2024, azdiaratuowdotedudotau
% (Remove "dot" and "at" to make this email address valid)
% *********************************************************************

%% Clear variables
home; clc; clear all; clear hidden; close all;
currentFolder;
warning off MATLAB:subscripting:noSubscriptsSpecified
set(0,'DefaultFigureWindowStyle','normal');


%% Call the videoTracker
videoTracker('exclude',8,'blobs',3,'frames',5);
% videoTracker('exclude',8,'blobs',3,'frames',5,'threshold',0.3,'filter',[3 3]);


