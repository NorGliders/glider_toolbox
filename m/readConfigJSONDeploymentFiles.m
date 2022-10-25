function [ readvals ] = readConfigJSONDeploymentFiles( fconfig, varargin )
%readConfigJSONDeploymentFiles 
%        TODO: Add description
%   This function should read the configuration file and return a structure
%   with the appropriate values from the text file
%   From https://rosettacode.org/wiki/Read_a_configuration_file#MATLAB_.2F_Octave
%
%  Authors:
%    Miguel Charcos Llorens  <mcharcos@socib.es>
%
%  Copyright (C) 2013-2016
%  ICTS SOCIB - Servei d'observacio i prediccio costaner de les Illes Balears
%  <http://www.socib.es>
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

  narginchk(1, 3);
  
  options.array_delimiter = '|';  
    
  %% Parse optional arguments.
  % Get option key-value pairs in any accepted call signature.
  argopts = varargin;
  if isscalar(argopts) && isstruct(argopts{1})
    % Options passed as a single option struct argument:
    % field names are option keys and field values are option values.
    opt_key_list = fieldnames(argopts{1});
    opt_val_list = struct2cell(argopts{1});
  elseif mod(numel(argopts), 2) == 0
    % Options passed as key-value argument pairs.
    opt_key_list = argopts(1:2:end);
    opt_val_list = argopts(2:2:end);
  else
    error('glider_toolbox:readConfigFile:InvalidOptions', ...
          'Invalid optional arguments (neither key-value pairs nor struct).');
  end
  % Overwrite default options with values given in extra arguments.
  for opt_idx = 1:numel(opt_key_list)
    opt = lower(opt_key_list{opt_idx});
    val = opt_val_list{opt_idx};
    if isfield(options, opt)
      options.(opt) = val;
    else
      error('glider_toolbox:readConfigFile:InvalidOption', ...
            'Invalid option: %s.', opt);
    end
  end
    
  % Disp note about location of deployment files
  fprintf(1, 'Active EGO deployment files should be placed here: %s\n', fconfig);

  % List EGO deployment files in real-time directory
  jsons = dir([fconfig,'*.json',]);
  jsons = {jsons.name}';
  bad_words = {'CTD','active_norgliders'};
  deploy_jsons = {};
  
  for i = 1:numel(jsons)
      if ~contains(jsons{i},bad_words)
          deploy_jsons{numel(deploy_jsons)+1} = jsons{i};
      end
  end
     
  if ~numel(deploy_jsons)
      return
  else
      % Create a table
      
      for i = 1:numel(deploy_jsons)
          %% Read configuration file
          this_file = fullfile(fconfig,deploy_jsons{i});
          fprintf(1, 'Found EGO deployment file: %s\n', deploy_jsons{i});
          data = loadjson(this_file);  
          %deployment_id(i,1) = 1; 
          deployment_name{i,1} = data.global_attributes.deployment_code;
          start_date = datenum(data.glider_deployment.DEPLOYMENT_START_DATE,'yyyymmddHHMMSS');
          deployment_start{i,1} = datestr(start_date,'yyyy-mm-dd HH:MM:SS');
          deployment_end{i,1} = nan;
          glider_name{i,1} = data.global_attributes.platform_code;
          glider_serial{i,1} = data.glider_characteristics.GLIDER_SERIAL_NO;
          glider_model{i,1} = data.glider_characteristics.PLATFORM_TYPE;
      end
      readvals = table(deployment_name,deployment_start,deployment_end,glider_name,glider_serial,glider_model);
      fprintf(1, '\n');
      disp(readvals)
      readvals = table2struct(readvals);
  end

  
end

