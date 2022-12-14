function [some_output] = generateBatteryFigures(processed_logs, glider, figure_dir, units, start)
%GENERATESURFACEFIGURES  Generate figures from individual segments for flight glider data.
%
%  Syntax:
%    FIGURE_INFO = GENERATESURFACEFIGURES(DATA, FIGURE_LIST)
%    FIGURE_INFO = GENERATESURFACEFIGURES(DATA, FIGURE_LIST, OPTIONS)
%    FIGURE_INFO = GENERATESURFACEFIGURES(DATA, FIGURE_LIST, OPT1, VAL1, ...)
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
%    Fiona Elliott     <fiona.elliott@uib.no>

%  Copyright (C) 2013-2016
%  ICTS SOCIB - Servei d'observacio i prediccio costaner de les Illes Balaars
%  <http://www.socib.es>
%  UIB GFI NorGliders - Universitet i Bergen, Geofysisk Institutt
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

narginchk(5, 5);

n = height(processed_logs);
if height(processed_logs) < 2
    return
end


%% --- Set-up ---
% TEMP
if strcmp(glider,'verd') || strcmp(glider,'dvalin')
    bat_type = 'lithium rechargeable extended';
elseif strcmp(glider,'odin')
    bat_type = '4s primary standard';
else
    bat_type = '4s primary extended';
end

col                 = linspecer(4);
%start                   = datenum(2021,11,27);   %cfg.DEPLOY_DATE);
VariableNames       = {'total_non_derated_Ah','total_non_derated_Wh','f_coulomb_battery_capacity', 'undervolts', 'Vcutoff', 'Vmax','Vmin'};
RowNames            = {'alkaline standard pack', '3s primary pack','3s primary extended','4s primary standard', '4s primary extended', 'lithium rechargeable standard', 'lithium rechargeable extended'};
days_ago            = 10; % recent projection
do_recent_est       = true;

% Tunable parameters
t_offset            = 0.1;   % t-offset (in days)
FirstGuessPwr       = 0.008; % Initial power

% https://datahost.webbresearch.com/viewtopic.php?f=3&t=437&p=1250&hilit=m_undervolts#p1250
bat_info_ar =  [168   2520    120   10      10      16  9 
    780   8424    720   9.8     10      16  9
    1140  12312   1050	9.8     10      16  9
    600   8600    550   12      10      16  9
    870   12500   800   12      10      16  9
    234.6 3300    215   12.5      10      17  9
    326.4 4700    300   12.5      10      17  9
    ];

bat_table = array2table(bat_info_ar,'VariableNames',VariableNames,'RowNames',RowNames);
bat_info = bat_table(lower(bat_type),:);
%bat_type = char(bat_info.Properties.RowNames);

total_non_derated_Ah = bat_info.total_non_derated_Ah;
capacity = bat_info.f_coulomb_battery_capacity;
Vundervolts = bat_info.undervolts;
Vcutoff = bat_info.Vcutoff;
Vmax = bat_info.Vmax;
Vmin = bat_info.Vmin;


% Load data structure
% fix bug where something time column isn't datetime  variable
Tmeas = processed_logs.current_time;
if ~isdatetime(Tmeas)
    Tmeas = datetime(Tmeas);
end
Tmeas = datenum(Tmeas);


Ameas = processed_logs.m_coulomb_amphr_total;
Vmeas = processed_logs.m_battery;

% Linear interpolatation between
[Tmeas,TF] = fillmissing(Tmeas,'linear');
fprintf('Filled %i of %i time values\n', sum(TF), numel(TF))
[Ameas,TF] = fillmissing(Ameas,'linear');
fprintf('Filled %i of %i current values\n', sum(TF), numel(TF))
[Vmeas,VF] = fillmissing(Vmeas,'linear');
fprintf('Filled %i of %i voltage values\n', sum(TF), numel(TF))

% Voltage
vt0      = Tmeas(1) - t_offset;  % apply t offset to start time
vdt      = (Tmeas - vt0)*86400;   % calculate dt in seconds

% Extend time array far to make sure we project to total capacity
time = start:1:start+400;

% Get the estimated amphours with polyval() for the last x days up to end_date_total_capacity
time_last = Tmeas(end);
time_first = time_last - days_ago;
time_first_ind = find(Tmeas > time_first,1);

if ~isempty(time_first_ind)
    Tmeas_recent = Tmeas(time_first_ind:end);
    Ameas_recent = Ameas(time_first_ind:end);
else
    do_recent_est = false;
end
    
% Capacity
% Do the regression with polyfit, fit a straight line through the measured y values.
% The x coefficient, slope, is coef_fit(1), the constant, the intercept, is coef_fit(2).
acoef_fit = polyfit(Tmeas,Ameas,1);
acoef_fit_recent = polyfit(Tmeas_recent,Ameas_recent,1);

% Find x (end date) for the nominal and total non-derated capacity
end_date_nominal_capacity = (capacity - acoef_fit(2)) / acoef_fit(1);
disp(['Projected end date for a nominal capacity of ' num2str(capacity) 'Ah: ' datestr(end_date_nominal_capacity,'dd.mmm.yyyy')])
disp(['Total days in water: ' num2str(ceil(end_date_nominal_capacity -start))])

end_date_recent_nominal_capacity = (capacity - acoef_fit_recent(2)) / acoef_fit_recent(1);
disp(['Projected end date for a nominal capacity of ' num2str(capacity) 'Ah based on the last 10 days use: ' datestr(end_date_recent_nominal_capacity,'dd.mmm.yyyy')])
disp(['Total days in water: ' num2str(ceil(end_date_recent_nominal_capacity -start))])

end_date_total_capacity = (total_non_derated_Ah - acoef_fit(2)) / acoef_fit(1);
disp(['Projected end date for a total non derated capacity of ' num2str(total_non_derated_Ah) 'Ah: ' datestr(end_date_total_capacity,'dd.mmm.yyyy')])
disp(['Total days in water: ' num2str(ceil(end_date_total_capacity-start))])

% Get the estimated amphours with polyval() up to end_date_total_capacity
t_fit = start:1:ceil(end_date_total_capacity); % maybe i want total to extend range?
a_fit = polyval(acoef_fit,t_fit);

t_fit_recent = Tmeas_recent(1):1:ceil(end_date_recent_nominal_capacity);
a_fit_recent = polyval(acoef_fit_recent,t_fit_recent);

% Voltage
% Get the coefficients for a linear fit
vcoef_fit = polyfit(Tmeas,Vmeas,1);

% Get the estimated voltages using end date obtained from capacity estimates
v_fit = polyval(vcoef_fit,t_fit);

% Estimate time when cutoff voltage is reached
ind          = max(find(sign(v_fit - Vcutoff)==1));
tcutoff      = t_fit(ind);
time2cutoff  = tcutoff - max(Tmeas);

% Estimate time when warning voltage is reached
ind          = max(find(sign(v_fit - Vundervolts)==1));
twarning     = time(ind);
time2warning = twarning - max(Tmeas);

% Estimate % duration remaining
duration     = max(Tmeas) - min(Tmeas);
remaining    = time2cutoff;
pc_rem       = remaining/(duration+remaining) * 100;


%% Current
% Daily
ahr0 = Ameas(1);
t0   = Tmeas(1);

ahr  = Ameas - ahr0;
t    = Tmeas - t0;

dAve_ahr = ahr(end)/t(end);

dAhr=0;
dt=0;
for i=2:length(ahr)
    dAhr(i) = ahr(i) - ahr(i-1);
    dt(i)   = t(i)   - t(i-1);
end

dAhrdt = dAhr./dt;

ind = find(dt<0.02);

dt(ind)=[];
Tmeas(ind)=[];
Ameas(ind)=[];
Vmeas(ind)=[];
dAhrdt(ind)=[];
dAhr(ind)=[];

dat = [dt',dAhr',dAhrdt'];

start = floor(min(Tmeas));
e = ceil(max(Tmeas));

% Estimate time when maximum capacity is reached
[c, ind] = min(abs(a_fit - capacity));
atcutoff     = time(ind);
atime2cutoff  = atcutoff - max(Tmeas);
clear('ind');
[c_r, ind] = min(abs(a_fit_recent - capacity));
atcutoff_recent     = t_fit_recent(ind);
atime2cutoff_recent  = atcutoff - max(t_fit_recent);
clear('ind');

% Warning capacity is 7 days before max capacity using daily average Ahr
warning7Day =  floor(capacity - 7*dAve_ahr);

% Estimate time when warning capacity is reached
[c ind] = min(abs(a_fit - warning7Day));
atwarning     = time(ind);
atime2warning = atwarning - max(Tmeas);
[c ind] = min(abs(a_fit - warning7Day));

% Estimate % duration remaining
aduration     = max(Tmeas) - min(Tmeas);
aremaining    = atime2cutoff;
apc_rem       = aremaining/(aduration+aremaining) * 100;


% Plot - Voltage
fh1 = figure('Units', 'Normalized', 'OuterPosition', [0 0 0.4 .8], 'Name', 'Battery diagnostics - Voltage', 'Tag', 'Battery_diagnostics_voltage', 'NumberTitle', 'Off', 'color', 'white');
% fh1 = figure('Units', 'centimeter', 'Name', 'Battery diagnostics - Voltage', 'Tag', 'Battery_diagnostics_voltage', 'NumberTitle', 'Off', 'color', 'white');

subplot(2,1,1)
plot(Tmeas,Vmeas,'col',col(1,:),'Marker','o')
hold on
plot(Tmeas,polyval(vcoef_fit,Tmeas),'col',col(2,:))
grid on
ylabel('Voltage (V)')
title('Measured values')
legend('Measured', 'Linear Fit', 'Location', 'NorthEast');
set(gca,'XLim',[Tmeas(1) Tmeas(end)])
datetick('x')

subplot(2,1,2)
plot(Tmeas,Vmeas,'col',col(1,:),'Marker','o')
hold on
plot(t_fit,v_fit,'col',col(2,:))
grid on
line('Xdata',[t_fit(1) t_fit(end)],'Ydata',[Vundervolts Vundervolts],'LineStyle','--','Color','k')
line('Xdata',[t_fit(1) t_fit(end)],'Ydata',[Vcutoff Vcutoff],'LineStyle','--','Color','r')
ylabel('Voltage (V)')
title('Projected consumption for deployment')
legend('Measured', 'Linear Fit', 'Undervolts', 'Voltage Cutoff', 'Location', 'NorthEast');
set(gca,'XLim',[t_fit(1) t_fit(end)],'ylim',[Vmin Vmax])
datetick('x')
print_fig(figure_dir)
close(fh1);

% Plot - Current
% First plot, first axes
n = 0;
fh2 = figure('Units', 'Normalized', 'OuterPosition', [0 0 0.4 0.8], 'Name', 'Battery diagnostics - Current Draw', 'Tag', 'Battery_diagnostics_current', 'NumberTitle', 'Off', 'color', 'white');
ah(1) = subplot(2,1,1,'Parent',fh2,'Units','Normalized','FontSize',10,'FontName','Calibri');
n = n + 1;
l(n) = plot(Tmeas,Ameas,'col',col(n,:),'Marker','o');
hold on
n = n + 1;
l(n) = plot(Tmeas,polyval(acoef_fit,Tmeas),'col',col(n,:));
grid on
ylabel(ah(1), 'Amp-hours (Ah)')
title('Current Draw')
set(ah(1),'XLim',[Tmeas(1) Tmeas(end)],'box','off')
datetick('x')
ah1_pos = get(ah(1),'Position');

% First plot, seconds axes, overloayed
ah(2) = axes('Parent',fh2,'Units','Normalized');
n = n + 1;
l(n) = plot([min(Tmeas) max(Tmeas)],[dAve_ahr dAve_ahr],'col',col(n,:),'Parent',ah(2),'LineStyle','--','linewidth',1);
n = n + 1;
hold on
l(n) = plot(Tmeas,dAhrdt','col',col(n,:),'Parent',ah(2),'Marker','o','MarkerSize',4);
set(ah(2),'fontsize',10, 'FontName','Calibri','Position', ah1_pos,'Color','none','XAxisLocation','top','YAxisLocation','right', 'XColor','k','YColor',col(n,:),'Xlim',[Tmeas(1) Tmeas(end)],'XTickLabel','','Color','none','box','off'); %,'Ylim',[2 4]
ylabel(ah(2), 'Amp-hours (Ah)')

% Legend for both axes
legend(l,{'m_coulomb_amphr_total','Linear Fit','Avg Daily Ahr', 'Daily Ahr'},'fontsize',8,'fontname','Calibri','Interpreter','none','Location','Best');

% Second plot
n = 0;
ah(3) = subplot(2,1,2,'Parent',fh2,'Units','Normalized','FontSize',10,'FontName','Calibri');
n = n + 1;
l2(n) = plot(Tmeas,Ameas,'col',col(n,:),'Marker','o');
hold on
n = n + 1;
l2(n) = plot(t_fit,a_fit,'col',col(n,:));

% add best fit based on last x days
hold on
n = n + 1;
l2(n) = plot(t_fit_recent,a_fit_recent,'col',col(n,:));

grid on
ylabel('Amp-hours (Ah)')
title('Projected consumption for deployment')
set(gca,'XLim',[t_fit(1) t_fit(end)])
datetick('x')

n = n + 1;
l2(n) = line('Xdata',[t_fit(1) end_date_nominal_capacity],'Ydata',[capacity capacity],'LineStyle','--','Color','k');
n = n + 1;
l2(n) = line('Xdata',[t_fit(1) t_fit(end)],'Ydata',[total_non_derated_Ah total_non_derated_Ah],'LineStyle','--','Color','r');
line('Xdata',[end_date_nominal_capacity end_date_nominal_capacity],'Ydata',[0 capacity],'LineStyle','--','Color','k')
line('Xdata',[end_date_total_capacity end_date_total_capacity],'Ydata',[0 total_non_derated_Ah],'LineStyle','--','Color','r')

legend(l2,{'Measured', 'Linear Fit', 'Nominal Capacity','Nominal Capacity','Non-derated Capacity'},'fontsize',8,'fontname','Calibri','Interpreter','none','Location','SouthEast');

% Current
% Txt{1} = sprintf('Type: Capacity, Days in water, End date');
Txt{1} = sprintf('Nomial capacity: %5.1fAh, %5.0fdays,  %s',capacity,ceil(end_date_nominal_capacity -start),datestr(end_date_nominal_capacity,'dd.mmm.yyyy')); % FE 19/aug/2015
Txt{2} = sprintf('Based on the last %u days: %5.1fAh, %5.0fdays,  %s',days_ago, capacity,ceil(end_date_recent_nominal_capacity -start),datestr(end_date_recent_nominal_capacity,'dd.mmm.yyyy')); % FE 19/aug/2015
% Txt{4} = sprintf('Non-derated capacity: %5.1fAh, %5.0fdays,  %s',total_non_derated_Ah,ceil(end_date_total_capacity -s),datestr(end_date_total_capacity,'dd.mmm.yyyy')); % FE 19/aug/2015
Txt{3} = sprintf('Latest value: %5.2fAh, %s',dAhrdt(end),datestr(Tmeas(end),'dd.mmm.yyyy HH:MM'));


ht = text(0,0,Txt,'units','nor');
set(ht, 'Position',[0.03 0.64],'FontName', 'Calibri','fontsize',11,...
    'Color',([118 118 140])/256);

print_fig(figure_dir)
close(fh2);


