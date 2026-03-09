function root = setup_paths()
%SETUP_PATHS Add project subfolders using relative paths.
% Call this from anywhere; it finds the project root automatically.

thisFile = mfilename('fullpath');
experimentsDir = fileparts(thisFile);      % .../experiments
root = fileparts(experimentsDir);          % .../invpend_mpc_pipeline

addpath(fullfile(root,'model'));
addpath(fullfile(root,'mpc'));
addpath(fullfile(root,'estimation'));
addpath(fullfile(root,'controllers'));
addpath(fullfile(root,'nmpc'));
addpath(fullfile(root,'experiments'));
addpath(fullfile(root,'casadi_nmpc'));
addpath(fullfile(root,'casadi-3.7.2-windows64-matlab2018b'))

% Ensure output folders exist
if ~exist(fullfile(root,'results'),'dir');  mkdir(fullfile(root,'results'));  end
if ~exist(fullfile(root,'figures'),'dir');  mkdir(fullfile(root,'figures'));  end
end
