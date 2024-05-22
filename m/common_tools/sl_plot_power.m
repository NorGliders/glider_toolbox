function sl_plot_power(cfg)
%-----------------------------------------------------------------------------------------
% plot_battery(cfg)
%
% NIWA Slocum toolbox
%
% TODO - not sure whats happening with the calculation for 'last
% measurement and mission average?
% 
% History:
% -2014             ANFOG
% 2015-Jun-17 FE    Adapted for the NIWA Slocum toolbox
%-----------------------------------------------------------------------------------------

%% --- Set-up ---
glider              = cfg.GLIDER;
dataDir             = cfg.PROJECT_DIR;
surfDir             = fullfile(cfg.PROJECT_DIR,'surface\');
battery_capacity    = 153;                                         % TODO - check this, ANFOG = 170                                                        
col                 = linspecer(3);                                % colormap for plot

% Load data structure
load(fullfile(dataDir,[glider,'_srfStruct.mat']));

%% --- Main ---
% read time and voltage information
for i=1:length(srfStruct)
    tmeas(i,1)  = srfStruct(i).CurrentTimeNum;
    try
    amphr_total(i,1)  = srfStruct(i).Sensors.m_coulomb_amphr_total(1);
     catch ME
        if strcmp(ME.identifier,'MATLAB:nonExistentField')
            disp(ME.message)
            disp(['Assigning amphr_total( ' num2str(i) ') to NaN'])
            amphr_total(i,1) = NaN;
        end
    end
end

ahr0 = amphr_total(1);
t0   = tmeas(1);

ahr  = amphr_total - ahr0;
t    = tmeas - t0;

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
tmeas(ind)=[];
dAhrdt(ind)=[];
dAhr(ind)=[];

dat = [dt',dAhr',dAhrdt'];

s = floor(min(tmeas));
e = ceil(max(tmeas));

%% --- Plot ---
[fh,ah] = plot_default('power','power_usage');
% hf = figure('color','white','Units','cen','Position',[0 0 13.5 9],'Name','Power usage',...
%     'Tag','power_usage','NumberTitle','off');
% movegui(hf,'center');
% ah = axes('Units','cen','fontsize',8, 'FontName','Calibri','Position',[1.5 3 11 5]);
% set(gcf,'PaperPosition',get(gcf,'Position'))

plot(tmeas,dAhrdt,'col',col(3,:),'Marker','o','MarkerSize',4,'MarkerFaceColor',col(3,:),'LineStyle','none')
line('Xdata',[min(tmeas) max(tmeas)],'Ydata',[dAve_ahr dAve_ahr],'LineStyle','-','Col',col(1,:),'linewidth',2)
set(ah,'Xlim',[min(tmeas) max(tmeas)],'Ylim', [0 10],'Xtick',s:e);
ylabel('Ah/Day');
if max(tmeas) - min(tmeas) < 2
    %datetick('x','HH:MM','keeplimits');
    xtimelab(gca)
    xlabel(datestr(min(tmeas),'dd mmm'));
else
    %datetick('x','keeplimits','keepticks');
    xtimelab(gca)
end
% grid on

% FE - suspect this isn't quite right, have changed
% end_1 = tmeas(end)+((battery_capacity-ahr(end))/dAve_ahr);
% end_2 = tmeas(end)+((battery_capacity-ahr(end))/dAhrdt(end));
end_1 = tmeas(end)+((battery_capacity-ahr(end))/dAve_ahr);
end_2 = tmeas(end); %+((battery_capacity-ahr(end))/dAhrdt(end));

% Add text notes to plot
% Labels
Txt{1} = sprintf('Capacity:');
Txt{2} = sprintf('Used:');
Txt{3} = sprintf('Mission Average:');
Txt{4} = sprintf('Last measurement:');
ht = text(0,0,Txt);
set(ht,'Units','cen','Position',[0 -1.8],'FontName', 'Calibri','fontsize',8,...
    'Color',([118 118 140])/256);

% Values
Txt{1} = sprintf(' %5.2f Ah',battery_capacity);
Txt{2} = sprintf(' %5.2f Ah (%4.2f%%)',ahr(end),(ahr(end)/battery_capacity)*100);
% Txt{3} = sprintf('%5.2f Ah/day  --> [%s]',dAve_ahr,datestr(end_1));
Txt{3} = sprintf('%5.2f Ah/day',dAve_ahr); % FE 19/aug/2015
Txt{4} = sprintf('%5.2f Ah/day  --> [%sZ]',dAhrdt(end),datestr(end_2));
ht = text(0,0,Txt);
set(ht,'Units','cen','Position',[3 -1.8],'FontName', 'Calibri','fontsize',8,...
    'Color',([118 118 140])/256);

title('Power Use')
print_fig(surfDir)
%eval(['print -f -dpng ' dataDir  get(gcf,'Name') ';']);
close(fh);
