function [hfig, haxs, hcts, hlbs, hlns] = plotTSDiagram(varargin)
%PLOTTSDIAGRAM  Plot temperature-salinity diagram of glider data.
%
%  Syntax:
%    PLOTTSDIAGRAM(OPTIONS)
%    PLOTTSDIAGRAM(OPT1, VAL1, ...)
%    PLOTTSDIAGRAM(H, OPTIONS)
%    PLOTTSDIAGRAM(H, OPT1, VAL1, ...)
%    [HFIG, HAXS, HCTS, HLBS, HLNS] = PLOTTSDIAGRAM(...)
%
%  Description:
%    PLOTTSDIAGRAM(OPTIONS) and PLOTTSDIAGRAM(OPT1, VAL1, ...) generate a new 
%    figure with a line (marker) plot of temperature versus salinity samples of 
%    glider data on constant sigma-t level contours, according to options in 
%    key-value pairs OPT1, VAL1... or in struct OPTIONS with field names as 
%    option keys and field values as option values. The line plot is generated 
%    with function PLOT. Labeled contour levels are generated by functions
%    CONTOUR and CLABELS from density measurements computed by SW_DENS0.
%    Recognized options are:
%      SDATA: salinity data (x-axis coordinate).
%        Vector or matrix of salinity data.
%        Default value: []
%      TDATA: temperature data (y-axis coordinate).
%        Vector or matrix of temperature or potential temperature data.
%        Default value: []
%      XLABEL: horizontal axis label data.
%        Struct defining x label properties.
%        The text of the label is in property 'String'.
%        Default value: struct()
%      YLABEL: vertical axis label data.
%        Struct defining y label properties.
%        The text of the label is in property 'String'.
%        Default value: struct()
%      TITLE: axes title data.
%        Struct defining axes title properties.
%        The text of the label is in property 'String'.
%        'String'.
%        Default value: struct()
%      AXSPROPS: extra axis properties.
%        Struct of axis properties to set for the plot axes with function SET.
%        Default value: struct()
%      FIGPROPS: extra figure properties.
%        Struct of figure properties to set for the figure with function SET.
%        Default value: struct()
%
%    PLOTTRANSECTVERTICALSECTION(H, ...) does not create a new figure,
%    but plots to figure given by figure handle H.
%
%    [HFIG, HAXS, HCTS, HLBS, HLNS] = PLOTTRANSECTVERTICALSECTION(...) returns 
%    handles for figure, axes, contour lines, contour labels and lineseries
%    objects in HFIG, HAXS, HCTS, HLBS and HLNS, respectively.
%
%  Notes:
%    If input temperature is potential temperature instead of in situ 
%    temperature, base contour levels are potential density contour levels.
%
%  Examples:
%    [hfig, haxs, hcts, hlbs, hlns] = ...
%      plotTSDiagram(gcf, ...
%        'SData', 37.5 + rand(30,5), 'TData', 10 + 15 * rand(30,5), ...
%        'Xlabel', struct('String', 'salinity'), ...
%        'Ylabel', struct('String', 'temperature'), ...
%        'title', struct('String', 'random TS plot on \sigma_t contours'))
%
%  See also:
%   SW_DENS0
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

  % No argument number checking since any number of arguments is allowed.

  %% Set plot options and default values.
  options = struct();
  options.sdata = [];
  options.tdata = [];
  options.idata = [];
  options.xlabel = struct();
  options.ylabel = struct();
  options.title = struct();
  options.axsprops = struct();
  options.figprops = struct();
  
  
  %% Get optional figure handle and option arguments.
  if (nargin > 0) && isscalar(varargin{1}) && ishghandle(varargin{1})
    args = varargin(2:end);
    hfig = figure(varargin{1});
  else
    args = varargin;
    hfig = figure();
  end
  
  
  %% Get options from extra arguments.
  % Parse option key-value pairs in any accepted call signature.
  if isscalar(args) && isstruct(args{1})
    % Options passed as a single option struct argument:
    % field names are option keys and field values are option values.
    option_key_list = fieldnames(args{1});
    option_val_list = struct2cell(args{1});
  elseif mod(numel(args), 2) == 0
    % Options passed as key-value argument pairs.
    option_key_list = args(1:2:end);
    option_val_list = args(2:2:end);
  else
    error('glider_toolbox:plotTSDiagram:InvalidOptions', ...
          'Invalid optional arguments (neither key-value pairs nor struct).');
  end
  % Overwrite default options with values given in extra arguments.
  for opt_idx = 1:numel(option_key_list)
    opt = lower(option_key_list{opt_idx});
    val = option_val_list{opt_idx};
    if isfield(options, opt)
      options.(opt) = val;
    else
      error('glider_toolbox:plotTSDiagram:InvalidOption', ...
            'Invalid option: %s.', opt);
    end
  end
  
  
  %% Set figure properties.
  set(hfig, options.figprops);
  
  
  %% Initialize all plot elements.
  haxs = gca();
  hlns = plot(haxs, 0, 0);
  haxs_next = get(haxs, 'NextPlot');
  set(haxs, 'NextPlot', 'add');
  [~, hcts] = contour(haxs, [], [], []);
  hlbs = [];
  haxstit = title(haxs, []);
  haxsxlb = xlabel(haxs, []);
  haxsylb = ylabel(haxs, []);
  
  
  %% Set properties of plot elements.
  valid_data = ~(isnan(options.sdata) | isnan(options.tdata));
  srange = quantile(options.sdata(valid_data), [0.0001 0.9999]);
  trange = quantile(options.tdata(valid_data), [0.0001 0.9999]);
%   valid_data = (10 < options.tdata) & (options.tdata < 40) ...
%              & ( 2 < options.sdata) & (options.sdata < 40);
%   srange = [min(options.sdata(valid_data)) max(options.sdata(valid_data))];
%   trange = [min(options.tdata(valid_data)) max(options.tdata(valid_data))];
  [salt_grid, temp_grid] = meshgrid(linspace(srange(1), srange(2), 30), ...
                                    linspace(trange(1), trange(2), 30));
  dns0_grid = sw_dens0(salt_grid, temp_grid) - 1000;
  set(hcts, 'XData', salt_grid, 'YData', temp_grid, 'ZData', dns0_grid);
  set(haxs, 'XLim', srange, 'YLim', trange);
  set(haxs, 'NextPlot', haxs_next);
  set(haxs, options.axsprops);
  set(haxstit, options.title);
  set(haxsxlb, options.xlabel);
  set(haxsylb, options.ylabel);
  set(hcts, 'LineColor', 0.125 * (get(haxs, 'XColor') + get(haxs, 'YColor')));
  % Contour labels must be created here after setting axes properties.
  hlbs = clabel(get(hcts, 'ContourMatrix'), hcts, 'Rotation', 0);
  set(hlbs, 'FontSize', get(haxs, 'FontSize'), 'FontWeight', 'bold');
  set(hlns, ...
      'XData', options.sdata, ...
      'YData', options.tdata, ...
      'LineStyle', 'none', 'LineWidth', 0.25 * get(hcts, 'LineWidth'), ...
      'Marker', 'o', 'MarkerSize', 4 * get(hcts, 'LineWidth'), ...
      'MarkerFaceColor', 0.375 * get(hcts, 'LineColor') + 0.625 * get(haxs, 'Color'), ...
      'MarkerEdgeColor', 0.625 * get(hcts, 'LineColor') + 0.375 * get(haxs, 'Color'), ...
      'Color', 0.625 * get(hcts, 'LineColor') + 0.375 * get(haxs, 'Color'));
 
  % plot last profile
  num_profiles = floor(max(options.idata));
  profile_data = (floor(options.idata) <= num_profiles(end)) & (floor(options.idata) >= num_profiles(end)-1);
  xdata = options.sdata(bsxfun(@and, valid_data, profile_data));
  ydata = options.tdata(bsxfun(@and, valid_data, profile_data));
  hold on

  plot(xdata, ydata, 'Marker', 'o', 'MarkerSize', 3, ...
      'MarkerFaceColor', [224 107 99]/256, ...
      'MarkerEdgeColor', [71, 66, 65]/256, ...
      'LineStyle', '-', 'LineWidth', 0.25 * get(hcts, 'LineWidth'));
  

  %{
  %num_profiles = floor(max(options.cdata));
  %hsct = plot(haxs, zeros(2, num_profiles), zeros(2, num_profiles));
  for p = 1:num_profiles
    profile_data = (options.cdata == p);
    xdata = options.sdata(bsxfun(@and, valid_data, profile_data));
    ydata = options.tdata(bsxfun(@and, valid_data, profile_data));
    if sum(valid_data & profile_data)/sum(profile_data) < 0.5
      xdata = [];
      ydata = [];
    end
    set(hsct(p), ...
        'XData', xdata, 'YData', ydata, ...
        'Marker', 'o', 'MarkerSize', 4 * get(hcts, 'LineWidth'), ...
        'MarkerFaceColor', 0.25 * get(hcts, 'LineColor') + 0.75 * get(haxs, 'Color'), ...
        'MarkerEdgeColor', 0.75 * get(hcts, 'LineColor') + 0.25 * get(haxs, 'Color'), ...
        'LineStyle', '-', 'LineWidth', 0.25 * get(hcts, 'LineWidth'), ...
        'Color', 0.5 * get(hcts, 'LineColor') + 0.5 * get(haxs, 'Color'));
  end
  %}
  
end
