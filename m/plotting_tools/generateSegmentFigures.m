function figure_info = generateSegmentFigures(unproccessed_files, figure_list, varargin)
%GENERATEFIGURES  Generate figures from glider data.
%
%  Syntax:
%    FIGURE_INFO = GENERATEGLIDERFIGURES(DATA, FIGURE_LIST)
%    FIGURE_INFO = GENERATEGLIDERFIGURES(DATA, FIGURE_LIST, OPTIONS)
%    FIGURE_INFO = GENERATEGLIDERFIGURES(DATA, FIGURE_LIST, OPT1, VAL1, ...)
%
%  See also:
%    PRINTFIGURE
%    PLOTTRANSECTVERTICALSECTION
%    PLOTTSDIAGRAM
%    PLOTPROFILESTATISTICS
%    CONFIGFIGURES
%    DATESTR
%    NOW
%
%  Authors:
%    Joan Pau Beltran  <joanpau.beltran@socib.cat>

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

  narginchk(2, 20);
  
  
  %% Set plot options and default values.
  options.dirname = '';
  options.format = 'eps';
  options.resolution = 72;
  options.driver = 'epsc2';
  options.render = [];
  options.loose = 'loose';
  options.convert = 'convert';
  options.keepeps = false;
  options.date = datestr(now(), 31);
  
  
  %% Get options from extra arguments.
  % Parse option key-value pairs in any accepted call signature.
  if isscalar(varargin) && isstruct(varargin{1})
    % Options passed as a single option struct argument:
    % field names are option keys and field values are option values.
    option_key_list = fieldnames(varargin{1});
    option_val_list = struct2cell(varargin{1});
  elseif mod(numel(varargin), 2) == 0
    % Options passed as key-value argument pairs.
    option_key_list = varargin(1:2:end);
    option_val_list = varargin(2:2:end);
  else
    error('glider_toolbox:generateFigures:InvalidOptions', ...
          'Invalid optional arguments (neither key-value pairs nor struct).');
  end
  % Overwrite default options with values given in extra arguments.
  for opt_idx = 1:numel(option_key_list)
    opt = lower(option_key_list{opt_idx});
    val = option_val_list{opt_idx};
    if isfield(options, opt)
      options.(opt) = val;
    else
      error('glider_toolbox:generateFigures:InvalidOption', ...
            'Invalid option: %s.', opt);
    end
  end
  
  
  %% Plot unproccessed_files
  disp('Loading science files...');
%   unproccessed_files
    dba_file = [];
%   dba_sci_files = cell(size(dba_sci_names));
%   dba_sci_success = false(size(dba_sci_names));
%   meta_sci = cell(size(dba_sci_names));
%   data_sci = cell(size(dba_sci_names));
    try
      % Load the dba file
      dba_file = unproccessed_files{idx};
      dba_data = dba2mat(dba_file); % 'sensors', options.sensors);
      dba_success = true;
    catch exception
      disp(['Error loading dba file ' unproccessed_files{idx} ':']);
      disp(getReport(exception, 'extended'));
    end
    
    
   
  meta_sci = meta_sci(dba_sci_success);
  data_sci = data_sci(dba_sci_success);
  disp(['Science files loaded: ' ...
        num2str(numel(data_sci)) ' of ' num2str(numel(dba_sci_names)) '.']);
  
  
  %% Initialize output.
  figure_info = struct();
  
  
  %% Generate figures given in figure list, if data is available.
  figure_key_list = fieldnames(figure_list);
  for figure_key_idx = 1:numel(figure_key_list)
    % Get current figure key and settings.
    figure_key = figure_key_list{figure_key_idx};
    figure_plot = figure_list.(figure_key);
    % Set print options (figure options override global options).
    if isfield(figure_plot, 'prntopts')
      print_options = figure_plot.prntopts;
    else
      print_options = struct();  
    end
    print_option_field_list = fieldnames(options);
    for print_option_field_idx = 1:numel(print_option_field_list)
      print_option_field = print_option_field_list{print_option_field_idx};
      if ~isfield(print_options, print_option_field)
        print_options.(print_option_field) = options.(print_option_field);
      end
    end
    % Get plot function as function handle.
    plot_function = figure_plot.plotfunc;
    if ischar(figure_plot.plotfunc)
      plot_function = str2func(figure_plot.plotfunc);
    end
    % Get plot extra options.
    if isfield(figure_plot, 'plotopts')
      plot_options = figure_plot.plotopts;
    else
      plot_options = struct();
    end
    % Get plot data options.
    data_option_field_list = fieldnames(figure_plot.dataopts);
    data_options = repmat(struct(), size(figure_plot.dataopts));
    for data_option_idx = 1:numel(figure_plot.dataopts)
      dataopt = figure_plot.dataopts(data_option_idx);
      for data_option_field_idx = 1:numel(data_option_field_list)
        data_option_field = data_option_field_list{data_option_field_idx};
        data_options(data_option_idx).(data_option_field) = '';
        if ischar(dataopt.(data_option_field))
          data_option_value_list = {dataopt.(data_option_field)};
        else
          data_option_value_list = dataopt.(data_option_field);
        end
        for data_option_value_idx = 1:numel(data_option_value_list)
          data_option_value = data_option_value_list{data_option_value_idx};
          if isfield(data, data_option_value) ...
              && ~all(isnan(data.(data_option_value)(:)))
            data_options(data_option_idx).(data_option_field) = data_option_value;
            break
          end
        end
      end
    end
    % Generate figure if all data is there.
    % Data specified in dataopts should be in data options,
    % data_available = all(isfield(data_options, data_option_field_list)) ...
    %                  && ~any(any(cellfun(@isempty, struct2cell(data_options))));
    data_option_field_missing = ...
      any(cellfun(@isempty, struct2cell(data_options(:))), 2);               
    data_available = ...
      ~any(data_option_field_missing) || ...
       all(isfield(plot_options, data_option_field_list(data_option_field_missing)));
    if data_available
      fprintf('Generating figure %s with settings:\n', figure_key);
      fprintf('  plot function    : %s\n', func2str(plot_function));
      for data_option_field_idx = 1:numel(data_option_field_list)
        data_option_field = data_option_field_list{data_option_field_idx};
        data_option_value_str = cell(size(data_options));
        if isscalar(data_options)
            data_option_value = data_options.(data_option_field);
            if isempty(data_option_value)
              data_option_value_str{1} = ...
                sprintf('[%dx%d %s]', ...
                        size(plot_options.(data_option_field)), ...
                        class(plot_options.(data_option_field)));
            else
              data_option_value_str{1} = data_option_value;
              plot_options.(data_option_field) = data.(data_option_value);
            end
        else
          for data_option_idx = 1:numel(data_options)
            data_option_value = data_options(data_option_idx).(data_option_field);
            if isempty(data_option_value)
              data_option_value_str{data_option_idx} = ...
                sprintf('[%dx%d %s]', ...
                        size(plot_options.(data_option_field){data_option_idx}), ...
                        class(plot_options.(data_option_field){data_option_idx}));
            else
              data_option_value_str{data_option_idx} = data_option_value;
              plot_options.(data_option_field){data_option_idx} = ...
                data.(data_option_value);
            end
          end
        end
        fprintf('  %-16s :%s\n', ...
                data_option_field, sprintf(' %-16s', data_option_value_str{:}));
      end
      figure_handle = figure();
      try
        plot_function(figure_handle, plot_options);
        figure_info.(figure_key) = printfigure(figure_handle, print_options);
      catch exception
        fprintf('Figure generation failed:\n');
        disp(getReport(exception, 'extended'));
      end
      close(figure_handle);
    end
    
  end

end
