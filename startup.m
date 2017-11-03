%STARTUP MATLAB startup file (kind of octaverc).

disp(['Loading ', mfilename('fullpath'), '...']);

addpath('m');
configGliderToolboxPath;

%% External libraries
ext_lib_path = '/home/glider/.local/lib/octave/packages';

% snctools: NetCDF library preferences.
% patched version for text attribute encoding.
disp('....... mexcdf');
disp('           ==>  mexnc');
addpath(fullfile(ext_lib_path, 'mexcdf', 'mexnc'));
disp('           ==>  snctools');
addpath(fullfile(ext_lib_path, 'mexcdf', 'snctools'));
disp('                (set prefs to use java)');
setpref('SNCTOOLS', 'USE_JAVA', true);

% m2html: inline html documentation generator.
disp('....... m2html');
addpath(fullfile(ext_lib_path, 'm2html'));

% M_Map: mapping toolbox.
disp('....... m_map');
addpath(fullfile(ext_lib_path, 'm_map'));

% seawater: CSIRO Sea Water Library.
disp('....... seawater');
addpath(fullfile(ext_lib_path, 'seawater'));

% override: overridden functions because of known bugs.
%disp('....... override');
%addpath(fullfile(ext_lib_path, 'override'));

disp([mfilename('fullpath'), ' loaded.']);
