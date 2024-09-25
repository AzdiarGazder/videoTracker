function makedll(REMOVEMSDLL)
% function makedll
% makedll makes the mexDDGrab dll which is used by mmread.
% makedll requires Microsoft Visual Studio.  It may work with other
% compilers, but this is the only one that is supported.  It also requires
% the DirectX SDK to be installed as well as the DirectShow extensions to
% DirectX.  Currently the DirectShow extensions are included in the Extras for 
% the DirectX SDK (a separate download).
%
% Go to http://msdn.microsoft.com/directx/directxdownloads/default.aspx
% Download and install the SDK.
% Download the Extras and expand it.  Take the contents (DirectShow and DirectSound)
%  out of the Extras directory and move them to the \Samples\C++ directory
%  under the DirectX SDK.
% (Build the baseclasses.vcproj under the DirectX SDK+Extras in
%  \Samples\C++\DirectShow\Samples\C++\DirectShow\BaseClasses
%  this will make strmbase.lib and quartz.lib.  Make sure to build the
%  Release version.  THIS STEP MAY NOT BE NEEDED ANYMORE.)
% Configure mex to use Visual Studio as its compiler.  Type mex -setup at 
%  the matlab prompt to do this if needed.
% Run makedll.  It will search for the required .h and .lib files.  If it
% can't find them it will ask you for the directory (or root directory to
% search under).
% 
% Option REMOVEMSDLL is optional and it makes the dll/mexw32 file more
% system independent.  It removes the dependency on MSVC*.dlls.  To enable
% this call makedll(true) AND YOU MUST EDIT YOUR mexopts.bat file and add
% /NODEFAULTLIB to the set LINKFLAGS line.

if (nargin < 1)
    REMOVEMSDLL = false;
end

disp('WARNING, YOU PROBABLY DON''T HAVE TO RUN THIS.  The only reasons to run this are: you have modified the source or for some other reason mmread doesn''t work when downloaded.  HIT ENTER TO CONTINUE');
input('','s')

DirectX_SDK_Include_dir = 'C:\Program Files'; %\Microsoft DirectX 9.0 SDK (June 2005)
VisualStudio_Include_dir = 'C:\Program Files'; %\Microsoft Visual Studio .NET
DirectX_SDK_Include_dir = getpath('DirectX_SDK_Include_dir', DirectX_SDK_Include_dir, 'ddraw.h');
disp(['Using ' DirectX_SDK_Include_dir]);
DirectX_SDK_DirectShow_Include_dir = fileparts(DirectX_SDK_Include_dir);
DirectX_SDK_DirectShow_Include_dir = getpath('DirectX_SDK_DirectShow_Include_dir', DirectX_SDK_DirectShow_Include_dir, 'dshow.h');
disp(['Using ' DirectX_SDK_DirectShow_Include_dir]);
Quartz_Lib_dir = fileparts(DirectX_SDK_DirectShow_Include_dir);
Quartz_Lib_dir = getpath('Quartz_Lib_dir', Quartz_Lib_dir, 'Quartz.lib');
disp(['Using ' Quartz_Lib_dir]);
Strmiids_Lib_dir = fileparts(DirectX_SDK_DirectShow_Include_dir);
Strmiids_Lib_dir = getpath('Strmiids_Lib_dir', Strmiids_Lib_dir, 'STRMIIDS.lib');
%Strmbase_Lib_dir = getpath('Strmbase_Lib_dir', Strmbase_Lib_dir, 'STRMBASE.lib');
disp(['Using ' Strmiids_Lib_dir]);
VisualStudio_Include_dir = getpath('VisualStudio_Include_dir', VisualStudio_Include_dir, 'atlbase.h');
disp(['Using ' VisualStudio_Include_dir]);
VisualStudio_Lib_dir = fileparts(VisualStudio_Include_dir);
VisualStudio_Lib_dir = getpath('VisualStudio_Lib_dir', VisualStudio_Lib_dir, 'atl.lib');
disp(['Using ' VisualStudio_Lib_dir]);

if (REMOVEMSDLL)
    Kernel32_Lib_dir = getpath('Kernel32_Lib_dir', 'C:\Program Files', 'Kernel32.lib');
    LibC_Lib_dir = getpath('LibC_Lib_dir', 'C:\Program Files', 'Libc.lib');
    Ole32_Lib_dir = getpath('Ole32_Lib_dir', 'C:\Program Files', 'Ole32.lib');
    Uuid_Lib_dir = getpath('Uuid_Lib_dir', 'C:\Program Files', 'Uuid.lib');
end

mexCmd = ['mex -I''' DirectX_SDK_Include_dir ''' -I''' DirectX_SDK_DirectShow_Include_dir ...
        ''' -I''' VisualStudio_Include_dir ''' mexDDGrab.cpp DDGrab.cpp ''' ...
        Strmiids_Lib_dir '\Strmiids.lib'' ''' ...
        Quartz_Lib_dir '\Quartz.lib'''];
%        Strmbase_Lib_dir '\Strmbase.lib'' ''' ...

% if atls.lib exists it will be in the same directory as atl.lib
if (exist([VisualStudio_Lib_dir '\atls.lib'],'file'))
    mexCmd = [mexCmd ' ''' VisualStudio_Lib_dir '\atls.lib'''];
end

if (REMOVEMSDLL)
    mexCmd = [mexCmd ...
             ' ''' Kernel32_Lib_dir '\Kernel32.lib''' ...
             ' ''' LibC_Lib_dir '\Libc.lib''' ...
             ' ''' Ole32_Lib_dir '\Ole32.lib''' ...
             ' ''' Uuid_Lib_dir '\Uuid.lib''' ...
             ' -DREMOVEMSDLL'];
end

try
    fid = fopen([fileparts(mfilename('fullpath')) '\build.m'],'wt+'); 
    fwrite(fid,mexCmd,'char');
    fclose(fid);
    disp('Generated build.m  Run this in the future to compile.');
catch
end
disp(['Running: ' mexCmd]);
eval(mexCmd);

function path = getpath(pathname, default, testfile)
path = findpath(default, testfile);
while isempty(path)
    path = findpath(input([pathname ' does not contain the file ''' testfile ''', enter new path to search under: '],'s'),testfile);
end
path = path{choose(pathname,path)};

function path = findpath(startdir, filename)
files = dir(startdir);
files = files(~ismember({files.name},{'.','..'})); % remove . and .. from the list
path = {};
if (any(strcmpi(filename,{files.name})))
    path{1} = startdir;
end
for i=1:length(files)
    if (files(i).isdir)
        tmppath = findpath([startdir filesep files(i).name],filename);
        path = {path{:}, tmppath{:}};
    end
end

function opt = choose(pathname,options)
if (length(options) > 1)
    disp(['There are multiple options for ' pathname ' please choose one of the following:']);
    for i=1:length(options)
        disp([num2str(i) '   ' options{i}]);
    end
    opt = 0;
    while opt < 1 || opt > length(options)
        opt = str2double(input('','s'));
        if opt < 1 || opt > length(options)
            disp(['Invalid response, must enter a number between 1 and ' num2str(length(options))]);
        end
    end
else
    opt = 1;
end
