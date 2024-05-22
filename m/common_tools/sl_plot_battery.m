function sl_plot_battery(cfg)
%-----------------------------------------------------------------------------------------
% sl_plot_battery(cfg)
%
% NIWA Slocum toolbox
% 
% History:
% -2014             ANFOG
% 2015-Jun-17 FE    Adapted for the NIWA Slocum toolbox
%-----------------------------------------------------------------------------------------

%% --- Set-up ---
glider              = cfg.GLIDER;
s                   = datenum(cfg.DEPLOY_DATE);
dataDir             = cfg.PROJECT_DIR;
surfDir             = fullfile(cfg.PROJECT_DIR,'surface\');

t_offset            = 0.1;   % t-offset (in days)    (TUNABLE)
FirstGuessPwr       = 0.008;
Vwarning            = 11.5;  % Warning voltage
Vcutoff             = 10.0;  % Pull out voltage
col                 = linspecer(3); % colormap for plot

%% --- Model Parameters ---
Vh  = 1.315;             % Voltage 'half-life'        (default=1.315 V)
O   = 2;                 %                            (default=2)
R   = 8.3144;            %                            (default=8.3144)
T   = 295;               % Temperature in Kelvin (11.85 deg C)      (default=295K)
F   = 96485;             %                            (default=96485)
QT  = 30000;             % Energy in each cell        (default=30000 kJ)
Vf  = 0.2;               %                            (default=0.2 V)
n   = 10;                % Number of cells in series  (default=10 )


%% --- Main ---
% load data structure
load(fullfile(dataDir,[glider,'_srfStruct.mat']));
% read time and voltage information
for i = 1:length(srfStruct)
    tmeas(i,1)  = srfStruct(i).CurrentTimeNum;
    try
        Vmeas(i,1)  = srfStruct(i).Sensors.m_battery(1);
    catch ME
        if strcmp(ME.identifier,'MATLAB:nonExistentField')
            disp(ME.message)
            disp(['Assigning voltage( ' num2str(i) ') to NaN'])
            Vmeas(i,1) = NaN;
        end
    end
end

clear('data');

t0      = tmeas(1) - t_offset;  % apply t offset to start time 
dt      = (tmeas - t0)*86400;   % calculate dt in seconds

% Fit battfun function to measured data
c    = [Vh, O, R, T, F, QT, Vf, n];
data = [tmeas, Vmeas, dt];
Pm   = fminsearch(@(P) battfun(P,c,data),FirstGuessPwr);

% Calculate modelled voltage at measurement times
A = O.*R.*T./F;
B = log((dt.*Pm)./(QT - dt.*Pm));
Vmodelcell = Vh - (A.*B) - Vf./n;
Vmod = Vmodelcell.*10;

% Extrapolate modelled voltage
ti = s:0.01:s+40;
dti = (ti - t0)*86400;
Bi = log((dti.*Pm)./(QT - dti.*Pm));
Vmodelcelli = Vh - (A.*Bi) - Vf./n;
Vmodi = Vmodelcelli.*10;

% Estimate time when cutoff voltage is reached
ind = max(find(sign(Vmodi - Vcutoff)==1));
tcutoff     = ti(ind);
time2cutoff = tcutoff - max(tmeas);
clear('ind');

% Estimate time when warning voltage is reached
ind = max(find(sign(Vmodi - Vwarning)==1));
twarning     = ti(ind);
time2warning = twarning - max(tmeas);

% Estimate % duration remaining
 duration  = max(tmeas) - min(tmeas);
 remaining = time2cutoff;
 pc_rem = remaining/(duration+remaining) * 100;
 
 e = tcutoff;
 
%% --- Create Plots ---
% hf = figure('color','white','Units','cen','Position',[0 0 13.5 11],'Name','Battery usage',...
%     'Tag','battery_usage');
% movegui(hf,'center');
% ah = axes('Units','cen','fontsize',8, 'FontName','Calibri','Position',[1.5 4 11 6],'YGrid','on');
[fh,ah] = plot_default('battery','battery_usage');
% set(gcf,'PaperPosition',get(gcf,'Position'))
warning('off')
plot(ti,Vmodi,'col',col(1,:),'LineWidth',2);
warning('on')
hold on;
plot(tmeas,Vmeas,'col',col(3,:),'Marker','.','markersize',5,'MarkerFaceColor',col(3,:),'LineStyle','none')
line('Xdata',[s twarning],'Ydata',[Vwarning Vwarning],'LineStyle','--','Color','k')
line('Xdata',[twarning twarning],'Ydata',[8 Vwarning],'LineStyle','--','Color','k')
line('Xdata',[s tcutoff],'Ydata',[Vcutoff Vcutoff],'LineStyle','--','Color','r')
line('Xdata',[tcutoff tcutoff],'Ydata',[8 Vcutoff],'LineStyle','--','Color','r')
set(gca,'Xlim',[s e+5],'Ylim', [9.5 16]);
xtimelab(gca) % datetick('x','dd','keeplimits')
ylabel('Battery Voltage (V)');

% Create text data
% Labels
hl = legend('Modelled','Measured');
% legPos = get(hl,'Position');
Txt{1} = sprintf('Modelled Ave Power Usage:');
Txt{2} = sprintf('Last Voltage:');
Txt{3} = sprintf('Cutoff Voltage:');
Txt{4} = sprintf('Estimated remaining (flat) :');
Txt{5} = sprintf('Estimated %% remaining (flat):');
Txt{6} = sprintf('Estimated end date:');
ht = text(3,3,Txt);
set(ht,'Units','cen', 'Position', [0 -2.2],'FontName', 'Calibri',...
    'fontsize',8,'Color',([118 118 140])/256);
% Values
Txt{1} = sprintf('%6.4f W',Pm);
Txt{2} = sprintf('%4.2f V',Vmeas(length(Vmeas)));
Txt{3} = sprintf('%4.2f V',Vcutoff);
Txt{4} = sprintf('%4.2f Days',time2cutoff);
Txt{5} = sprintf('%4.2f%%', pc_rem);
Txt{6} = datestr(tcutoff);
ht = text(3,3,Txt);
set(ht,'Units','cen', 'Position', [4 -2.2],'FontName', 'Calibri',...
    'fontsize',8,'Color',([118 118 140])/256);

title('Battery Usage')
%eval(['print -f -dpng ' dataDir  get(gcf,'Name') ';']);
print_fig(surfDir)
close(fh);


%% --- Sub Function to model battery discharge ---
function dV=battfun(P,c,data)
tmeas = data(:,1);
Vmeas = data(:,2);
dt    = data(:,3);
Vh    = c(1);
O     = c(2);
R     = c(3);
T     = c(4);
F     = c(5);
QT    = c(6);
Vf    = c(7);
n     = c(8);

A = O.*R.*T./F;
B = log((dt.*P)./(QT - dt.*P));
Vmodelcell = Vh - (A.*B) - Vf./n;
Vmod = Vmodelcell.*10;

dV = (sum((Vmeas - Vmod).^2));
