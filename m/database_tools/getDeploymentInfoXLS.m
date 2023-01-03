function [data, metadata] = getDeploymentInfoXLS(spreadsheet)
% getDeploymentInfoXLS  Get deployment information from norwegian missions spreadsheet.
%
%  Syntax:
%    DATA = getDeploymentInfoXLS()
%
%  Location of spreadsheet:
%    DB = if /Data/gfi/projects/naco/gliderdeployments\Norwegian_Missions.xlsx
%
%  Description:
%    DATA = getDeploymentInfoXLS() executes the query on the UIB glider deployment
%    spreadsheet hardcoded by string DB. The query return all deployments listed 
%    in the spreadsheet and presents them in a dialog box that the user is able to select from.
%    The function returns a struct DATA with fields given by corresponding columns in the query result.
%
%    The returned struct DATA should have the following fields to be considered 
%    a deployment structure:
%      DEPLOYMENT_ID: deployment identifier (invariant over time).
%      DEPLOYMENT_NAME: deployment name (may eventually change).
%      DEPLOYMENT_START: deployment start date (see note on time format).
%      DEPLOYMENT_END: deployment end date (see note on time format).
%      GLIDER_NAME: glider platform name (present in Slocum file names).
%      GLIDER_SERIAL: glider serial code (present in Seaglider file names).
%      GLIDER_MODEL: glider model name (like Slocum G1, Slocum G2, Seaglider).
%    The returned structure may include other fields, which are considered to be
%    global deployment attributes by functions generating final products like
%    GENERATEOUTPUTNETCDF.%    Example of output structure
%    data.deployment_id = '0016'; 
%    data.deployment_name = '20180519-NANSEN'; 
%    data.deployment_start = '2018-05-19 20:00:00';
%    data.deployment_end = '2018-06-02 22:00:00';  
%    data.glider_name = 'urd'; 
%    data.glider_serial = '873'; 
%    data.glider_model = 'Slocum G3'; 
%
%   
%  Notes:
%    Time columns selected in the query should be returned as UTC timestamp
%    strings in ISO 8601 format ('yyyy-mm-dd HH:MM:SS') or other format accepted
%    by DATENUM, and are converted to serial date number format. 
%    Null entries are set to invalid (NaN).
%
%  See also:
%    GENERATEOUTPUTNETCDF
%    DATABASE
%    FETCH
%    DATENUM
%
%  Authors:
%    Fiona Elliott  <fiona.elliott@uib.no>
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <http://www.gnu.org/licenses/>.

 narginchk(1,1);

 
%% --- Setup --------------------------------
% Retrieve all deployments in spreadsheet
T = readtable(spreadsheet,"FileType","spreadsheet");

% Delete rows that dont have mission number
T(isnan(T.MISSIONNUMBER),:) = [];
% Delete rows that have STATUS listed as scheduled
T(contains(T.STATUS,'scheduled'),:) = [];
% Delete slocum missions listed as active or missing 

% List all deployments in a dialog box for the user to select
deployId = T.MISSIONNUMBER;
deployName = T.INTERNALMISSIONID;
num_missions = height(T);
deploymentNameStr = cell(num_missions,1);
deployments = cell(num_missions,1);
for i = 1:num_missions
    deploymentNameStr{i} = [num2str(deployId(i)) ' - ' deployName{i}];
    deployments{i} = [num2str(deployId(i)) '-' deployName{i}];
end

OK = 0;
while ~OK
    % Selection is a vector of indices of the selected string
    [selection,OK] = listdlg('PromptString','Select a glider deployment to process:',...
        'SelectionMode','single',...
        'ListString',deploymentNameStr,...
        'InitialValue',num_missions,...
        'ListSize',[400 600],...
        'Name','Select');
end


%% Output structure
try
    metadata = table2struct(T(selection,:));
    deployment_id = T{selection,'MISSIONNUMBER'}; 
    deployment_name = char(T{selection,'INTERNALMISSIONID'}); 
    deployment_site = char(T{selection,'SITE'}); 
    deployment_start = datenum(T{selection,'STARTDATE'}); 
    deployment_end = datenum(T{selection,'ENDSCIENCEDATE'}); 
    glider_name = char(T{selection,'GLIDERNAME'}); 
    glider_serial = T{selection,'GLIDERSERIALNUMBER'};
    glider_model = [lower(char(T{selection,'GLIDERPLATFORM'})) '_' lower(char(T{selection,'GLIDERMODEL'}))]; 
    
    data = struct('deployment_id',deployment_id,...
    'deployment_name',deployment_name,...
    'deployment_site',deployment_site,...
    'deployment_start',deployment_start,...
    'deployment_end',deployment_end,...
    'glider_name',glider_name,...
    'glider_serial',glider_serial,...
    'glider_model',glider_model);
catch ME
    switch ME.identifier
        case 'MATLAB:datenum:ConvertDateString'
            [~,NAME,EXT] = fileparts(spreadsheet);
            disp('Error converting datetime.')
            disp(['Check the fields deploy_date, deploy_time, end_date or end_time in: ','<a href = "matlab: [s,r] = system(''explorer ',spreadsheet,' &'');">',...
                [NAME EXT],'</a>'])
            error(ME.identifier,ME.message)
        otherwise
            error(ME.identifier,ME.message)
    end
end

