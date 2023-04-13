function sl_plot_mission_sbd(cfg)
%--------------------------------------------------------------------------
% function sl_plot_sbd_data(cfg)
%
% TODO: - add depth_rate (copy from segment plots)
%       - fix time axis
%
% NIWA Slocum toolbox
%
% 2014          ANFOG   sl_plot_sbd_data
% 2015-Aug-06   FE      Renamed, adapted for the NIWA Slocum toolbox
% 2016-Feb-18   FE      Unified
%--------------------------------------------------------------------------
% cfg = parse_config_file('\\hjemme.uib.no\fel063\Settings\Desktop\PROCESS\vessel-slocum-web-monitor\Process\Realtime\durin.cfg');

%% --- Setup ---
disp([getUTC,': STARTING ',mfilename]);
PLOTVARS    = {'m_de_oil_vol', 'm_battpos', 'm_pitch', 'm_fin', 'm_heading', 'm_roll', 'm_depth', 'm_water_depth','m_digifin_leakdetect_reading'};
glider      = cfg.GLIDER;
mission     = cfg.MISSION;
col         = linspecer(3);
DATDIR      = cfg.PROJECT_DIR;
IMGDIR      = [DATDIR '\eng_transects'];
load(fullfile(DATDIR,[glider,'_sbdData.mat']));

% Get column numbers of SBDDATA
for i = 1:size(SBD_VARIABLE_LIST,1)
    eval([SBD_VARIABLE_LIST{i,1} ' = i;']);
end
time = ut2mt(SBDDATA(:,m_present_time));

% Write transect info variable
trInfo = sl_transect(time, cfg, DATDIR);


%% --- Plotting ---
for i = 1:size(trInfo,1)
    disp([getUTC,': Plotting SBD data for ',trInfo{i,3}]);
    
    startInd    = dsearchn(time,trInfo{i,1});
    endInd      = dsearchn(time,trInfo{i,2});
    xMin        = trInfo{i,1};
    xMax        = trInfo{i,2};
    tag         = [trInfo{i,4} '-'];
    mtitle      = trInfo{i,3};
    mtime = time(startInd:endInd);
    
    % Timeseries Plots
    for ind = 1:numel(PLOTVARS)
        if exist(PLOTVARS{ind},'var')
            myVarNum = eval(PLOTVARS{ind});
            myVar = PLOTVARS{ind};
            data = [];
            data2 = [];
            plotCommanded = 0;
            leg = {};
            
            % Assign data
            if ismember(myVar,{'m_heading','m_fin','m_pitch','m_roll'})
                data = rad2deg(SBDDATA(startInd:endInd,myVarNum));
            else
                data = SBDDATA(startInd:endInd,myVarNum);
            end
            if strcmp(myVar,'m_heading') && exist('c_heading','var')
                data2 = rad2deg(SBDDATA(startInd:endInd,c_heading));
                plotCommanded = 1;
                leg = {'m_heading','c_heading'};
            elseif strcmp(myVar,'m_fin') && exist('c_fin','var')
                data2 = rad2deg(SBDDATA(startInd:endInd,c_fin));
                plotCommanded = 1;
                leg = {'m_fin','c_fin'};
            elseif strcmp(myVar,'m_pitch') && exist('c_pitch','var')
                data2 = rad2deg(SBDDATA(startInd:endInd,c_pitch));
                plotCommanded = 1;
                leg = {'m_pitch','c_pitch'};
            elseif strcmp(myVar,'m_roll') && exist('c_roll','var')
                data2 = rad2deg(SBDDATA(startInd:endInd,c_pitch));
                plotCommanded = 1;
                leg = {'m_roll','c_roll'};
            end

            % Setup
            plot_default(1)
            
            if cfg.SHOW_PLOTS == 0
                set(gcf,'visible', 'off');
            end
            
            % Plot
            plot(mtime,data,...
                'col',col(1,:),...
                'Marker','o',...
                'MarkerSize',2,...
                'MarkerFaceColor',col(1,:),...
                'linestyle','none');
            
            hold on
            
            if plotCommanded
                plot(mtime,data2,...
                    'col',col(2,:),...
                    'Marker','o',...
                    'MarkerSize',2,...
                    'MarkerFaceColor',col(2,:),...
                    'linestyle','none');
                legend(leg,'fontsize',8,'fontname','Calibri','Interpreter','none','location','Best');
            end
            
            if strcmp(myVar,'m_heading')
                set(gca,'Ylim', [0 360],'YTick',[0 45 90 135 180 225 270 315 360],...
                    'YTickLabel',{'N','NE','E','SE','S','SW','W','NW','N'},...
                    'Xlim', [min(mtime) max(mtime)]);
            end
                
            title([myVar ': ' mtitle],...
                'Interpreter','none',...
                'Fontsize',10,...
                'FontName','Calibri');
            
            if ismember(myVar,{'m_fin','m_pitch','m_roll'})
                ylabel('degrees');
            elseif strcmp(myVar,'m_heading')
                ylabel('direction (true)');
            else
                ylabel(SBD_VARIABLE_LIST{myVarNum,2});
            end
            
            if strcmp(myVar,'m_depth') || strcmp(myVar,'m_water_depth')
                set(gca,'ydir','rev');
            end
            set(gca,'Xlim',[xMin xMax]);
            set(gcf, 'Name', [tag myVar],...
                'Tag',[tag myVar]);
            xtimelab(gca)
            grid on;
            hTxt = text(0,-1.2,['Figure created at ',getUTC],...
                'Units','cen',...
                'Fontsize',8,...
                'FontName','Calibri');
            
            % Save
            print_fig([IMGDIR '\'])
            close(gcf);
        end
    end
    
    % Diagnostic plots
    % 1. --- Pitch diagnostics (m_battpos vs m_pitch) ---
    if exist('m_battpos','var') && exist('m_pitch','var')

        % Setup
        plot_default(1)
        if cfg.SHOW_PLOTS == 0
            set(hF,'visible', 'off');
        end
        
        % Plot
        plot([-1.5 1.5],[26,26],'k--');
        hold on
        plot([-1.5 1.5],[-26,-26],'k--');
        plot(SBDDATA(startInd:endInd,m_battpos),rad2deg(SBDDATA(startInd:endInd,m_pitch)),...
            'col',col(1,:),'Marker','o','MarkerSize',3,...
            'MarkerFaceColor',col(1,:),'linestyle','none');
        grid on
        set(gcf, 'Name', [tag 'm_battpos Vs m_pitch'], 'Tag',[tag 'm_battpos_Vs_m_pitch']);
        % set(gca,'Xlim',[-1.0 1.0],'Ylim',[-60 60]);
        xlabel('Battery Position [inch]')
        ylabel('Pitch [degrees]');
        title(['m_battpos vs m_pitch: ' trInfo{i,3}],'Interpreter','none',...
            'Fontsize',10,'FontName','Calibri');
        hTxt = text(0,-1.2,['Figure created at ',getUTC],'Units','cen',...
            'Fontsize',8,'FontName','Calibri');
        
        % Save
        print_fig([IMGDIR '\'])
        close(gcf);
    end
    
    % 2. --- Heading diagnostics (c_heading vs m_heading) ---
    if exist('m_heading','var') && exist('c_heading','var')
        
        % Setup
        plot_default(1)
        if cfg.SHOW_PLOTS == 0
            set(hF,'visible', 'off');
        end
        
        % Plot
        plot([0 360],[0 360],'k--','Linewidth',2);
        hold on
        plot(rad2deg(SBDDATA(startInd:endInd,c_heading)),rad2deg(SBDDATA(startInd:endInd,m_heading)),...
            'col',col(1,:),'Marker','o','MarkerSize',3,...
            'MarkerFaceColor',col(1,:),'linestyle','none');
        
        grid on
        set(gcf, 'Name', [tag,'c_heading Vs m_heading'], 'Tag',[tag,'c_heading_Vs_m_heading']);
        set(gca,'Xlim',[0 360],'Ylim',[0 360]);
        xlabel('Commanded heading [deg]')
        ylabel('Measured Heading [deg]');
        title(['c_heading v m_heading: ' trInfo{i,3}],'Interpreter','none',...
            'Fontsize',10,'FontName','Calibri');
        hTxt = text(0,-1.2,['Figure created at ', getUTC],'Units','cen',...
            'Fontsize',8,'FontName','Calibri');
        
        % Save
        print_fig([IMGDIR '\'])
        close(gcf);
    end


    % 3. --- Plot depth_rate ---
    if 0 %exist('m_depth','var')

        % - Setup -
        mm_depth = SBDDATA(startInd:endInd,m_depth);
        nn = ~isnan(mm_depth);
        tt = mtime(nn);
        z = mm_depth(nn);

        if numel(tt) > 1

            dz(1) = 0;
            dt(1) = 0;
            for n = 2:length(tt)
                dz(n) =  z(n)-z(n-1);
                dt(n) =  tt(n)-tt(n-1);
            end
            dt = dt * 86400;

            depthRateRaw = dz./dt;
            depthRateRaw(1)=0;
            depthRateRaw(2)=0;
            depthRate = runmean(depthRateRaw,2,2);

            % -Plot -
            plt_default(1)
            if cfg.SHOW_PLOTS == 0
                set(hF,'visible', 'off');
            end

            line([min(tt) max(tt)], [0 0],'LineStyle','--','col',col(2,:));

            plot(tt,depthRate,'col',col(1,:),'Marker','o',...
                'MarkerSize',4,'MarkerFaceColor',col(1,:));
            hold on;
            % line([min(tt) max(tt)], [-0.5 -0.5],'LineStyle','--','col',col(2,:));
            % line([min(tt) max(tt)], [0.5 0.5],'LineStyle','--','col',col(2,:));
            set(gca,'Xlim',[min(tt) max(tt)]);
            set(gcf, 'Name', [SEGNAME,'_depth_rate'], 'Tag',[SEGNAME,'_depth_rate']);
            xtimelab(gca)
            lh = ylabel('ms^-^1');
            th = title([varname titleTemplate],'Interpreter','none',...
                'Fontsize',10,'FontName','Calibri');
            grid on;
            hTxt = text(0,-1.2,['Figure created at ',getUTC],...
                'Units','cen',...
                'Fontsize',8,...
                'FontName','Calibri');
            print_fig([OUTPUT_DIR '\'])
            plotFiles{numel(plotFiles)+1} = [get(gcf,'Tag') '.png'];
            close(gcf);
        end
    end
end

disp([getUTC,': FINISHED ',mfilename]);
end


%% --- Sub Function to configure plots ---
function plot_default(mkfig)
%-----------------------------------------
% Dimensions - centimeters
figPos  = [0 0 15 10];
axPos   = [1.5 1.5 13 7.5];

if nargin >= 1 && mkfig == 1
    hf = figure('Units','Centimeters','Position',figPos);
    ah = axes('Units','cen','fontsize',8, 'FontName','Calibri','Position',axPos);
else
    hf = gcf;
    ah = gca;
end

movegui('center');

set(hf,'Units','Centimeters','NumberTitle','off','color','white','PaperPosition',get(gcf,'Position'))
set(ah,'FontSize',8,'FontName','Calibri','Units','Centimeters','box','on');

if nargin > 1
    set(hf,'Position',figPos)
end
if nargin > 2
    set(gca,'Position',axPos)
end

end

