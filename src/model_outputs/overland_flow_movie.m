%analyze_surface_storage_by_pixel.m
%Carolyn Voter
%February 8, 2019

close all; clear all; clc;
set(0,'defaultTextFontSize',24,'defaultTextFontName','Segoe UI Semilight',...
    'defaultAxesFontSize',20,'defaultAxesFontName','Segoe UI Semilight')

%% DATA PATHS AND CONSTANTS
base_dir = '../../data/disconnected_compacted_lot';

% Load colormap for heat maps
load('../../data/colormaps/map_ylgrbu.mat');

%% LOAD AND SUMMARIZE SUMMARIZE SURFACE WATER
% Domain info
load(sprintf('%s/domainInfo.mat',base_dir))
cellArea = dx*dy;
[Xy,Yx] = meshgrid(x,y);
xL = x(1); xU = x(length(x));
yL = y(1); yU =y(length(y));

clear z
zL = 0; dz = 0.25; nz = 40;
R = 1;  %No. Z processors    
varDZ = [0.4,0.4,0.4,0.4,0.4,1.0,1.0,1.0,1.0,1.0,1.0,...
    2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,...
    1.0,1.0,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4,0.4];
zU = zL+dz*nz;  z0 = zL+varDZ(1)*dz/2;   zf = zU-varDZ(end)*dz/2;
z(1) = z0;
for i = 2:nz
    z(i) = z(i-1) + (varDZ(i-1)*dz/2) + (varDZ(i)*dz/2);
end

% Mannings N
impervious_zero = NaNimp(:,:,end);
impervious_zero(isnan(impervious_zero)) = 0;
pervious_zero = zeros(size(impervious_zero));
pervious_zero(impervious_zero==0) = 1;
mannings = mn_grass*impervious_zero + mn_imperv*pervious_zero;

% Surface pressure
load(sprintf('%s/Ss.mat',base_dir))
surface_pressure = data; clear data;
nhours = length(surface_pressure);
for i = 1:nhours
    surface_pressure{i} = surface_pressure{i}/cellArea;
end

% Flow direction
xdir = zeros(size(slopeX));
ydir = zeros(size(slopeY));
xdir(slopeX > 0) = -1;
xdir(slopeX < 0) = 1;
ydir(slopeY > 0) = -1;
ydir(slopeY < 0) = 1;

%% CALCULATE CUMULATIVE FLOW OVER CELLS
q_cum = zeros([ny nx]);
for i = 1:nhours
    for j = 1:ny
        for k = 1:nx
            dirx = xdir(j,k);
            Sx = slopeX(j,k);
            mnx = mannings(j,k);
            px = surface_pressure{i}(j,k);
            q_x{i}(j,k) = dirx*(px^(5/3))*sqrt(abs(Sx))*dx/mnx;
            diry = ydir(j,k);
            Sy = slopeY(j,k);
            mny = mannings(j,k);
            py = surface_pressure{i}(j,k);
            q_y{i}(j,k) = diry*(py^(5/3))*sqrt(abs(Sy))*dy/mny;
            q_net{i}(j,k) = abs(q_y{i}(j,k)) + abs(q_x{i}(j,k));
            q{i}(j,k) = q_net{i}(j,k)/cellArea;
        end
    end
    q_cum = q_cum + q_net{i};
end

%% Plot
figure('Position',[248,477,560,420])
hold on
pcolor(Xy,Yx,q_cum.*NaNimp(:,:,end))
shading flat
rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
    '-','LineWidth',1.5);
set(gcf,'Colormap',mycmap)
h = colorbar;
ylabel(h, 'Cumulative Overland Flow (m^3)')
xlabel('Distance (m)');
ylabel('Distance (m)');
axis equal
axis([xL-2 xU+2 yL-2 yU+2])
set(gcf,'color','w');
hold off


%% Movie
%Setup video
writerObj = VideoWriter('overland_flow.avi');
writerObj.FrameRate = 3;
open(writerObj);

fig = figure('Position',[248,477,560,420]);
for h = 3520:3700
    hold on
    pcolor(Xy,Yx,q{h}.*NaNimp(:,:,end))
    shading flat
    rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
        '-','LineWidth',1.5);
    set(gcf,'Colormap',mycmap)
    caxis([0,0.2])
    xlabel('Distance (m)');
    ylabel('Distance (m)');
    axis equal
    axis([xL-2 xU+2 yL-2 yU+2])
    set(gcf,'color','w');
    hold off
    set(gcf,'Renderer','zbuffer')
    frame = getframe(gcf);
    writeVideo(writerObj,frame);
end
close(writerObj);