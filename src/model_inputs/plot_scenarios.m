%model_inputs_by_drainage.m
%Carolyn Voter
%February 8, 2019

close all; clear all; clc;
set(0,'defaultTextFontSize',10,'defaultTextFontName','Segoe UI Semilight',...
    'defaultAxesFontSize',10,'defaultAxesFontName','Segoe UI Semilight')

%% DATA PATHS AND CONSTANTS
layout_dir = '../../data/layouts';
top_percent_pixels = [0, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100];
percent_labels = {'0%', '0.25%', '0.5%', '1%', '2.5%', '5%', '10%', '25%', '50%', '100%'};

% Get Domain Info
load(sprintf('%s/domainInfo.mat',layout_dir))
cellArea = dx*dy;
[Xy,Yx] = meshgrid(x,y);
xL = 0; xU = nx*dx;
yL = 0; yU = ny*dy;
zL = 0; zU = nz*dz;

% Set up impervious mask
mask = ones(size(parcelCover));
mask(parcelCover > 0) = NaN;

%% GET DRAINAGE AREA
plot_on = 0;
[drainarea, TWI, ~] = drainage_area_TWI(slopeX,slopeY,mask,[],[],dx,dy,plot_on);
draintype = {'drain','TWI'};

%% DRAINAGE AREA
amended_pixels = zeros(size(parcelCover));
for p = 1:length(top_percent_pixels)
    [amended_matrix, ~] = amend_pixels(drainarea, mask, top_percent_pixels(p)/100);
    amended_pixels = amended_pixels + amended_matrix;
end

% Plot
figure(1)
hold on
pcolor(Xy,Yx,amended_pixels.*mask)
shading flat
rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
    '-','LineWidth',1.5);
colormap(brewermap([9],'Reds'))
caxis([0.5,9.5])
c = colorbar;
c.Ticks = 1:9;
c.Box = 'off';
c.TickLabels = fliplr(percent_labels(2:end));
c.Label.String = "% of Pixels with Larger Drainage Area";
xlabel('Distance (m)');
ylabel('Distance (m)');
title("Drainage Area")
axis equal
axis([xL xU yL yU])
set(gca,'Color',[0.7 0.7 0.7])
hold off

%% DRAINAGE AREA
amended_pixels = zeros(size(parcelCover));
for p = 1:length(top_percent_pixels)
    [amended_matrix, ~] = amend_pixels(TWI, mask, top_percent_pixels(p)/100);
    amended_pixels = amended_pixels + amended_matrix;
end

% Plot
figure(2)
hold on
pcolor(Xy,Yx,amended_pixels.*mask)
shading flat
rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
    '-','LineWidth',1.5);
colormap(brewermap([9],'Reds'))
caxis([0.5,9.5])
c = colorbar;
c.Ticks = 1:9;
c.Box = 'off';
c.TickLabels = fliplr(percent_labels(2:end));
c.Label.String = "% of Pixels with Larger TWI";
xlabel('Distance (m)');
ylabel('Distance (m)');
title("Topographic Wetness Index")
axis equal
axis([xL xU yL yU])
set(gca,'Color',[0.7 0.7 0.7])
hold off

%% FEATURE STUFF
amended_pixels = zeros(size(parcelCover));
  
% Downspouts
% DS, 1 pixel
ds_small(1,:) = [fc(7,1)+3*dx/2, fc(7,3)-7*dy/2]; %lower left
ds_small(2,:) = [fc(7,1)+3*dx/2, fc(8,4)+7*dy/2]; % upper left
ds_small(3,:) = [fc(7,2)-3*dx/2, fc(7,3)-7*dy/2]; % lower right
ds_small(4,:) = [fc(8,2)-3*dx/2, fc(8,4)+7*dy/2]; % upper right

% DS, 3 pixels
width = 3;
pixels_from_center = floor(width/2);
for i = 1:4
    ds_big(i,1) = ds_small(i,1) - dx*pixels_from_center;
    ds_big(i,2) = ds_small(i,1) + dx*pixels_from_center;
    if ds_small(i,2) < fc(7,3)
        ds_big(i,3) = ds_small(i,2) - dy*(width - 1);
        ds_big(i,4) = ds_small(i,2);
    else
        ds_big(i,3) = ds_small(i,2);
        ds_big(i,4) = ds_small(i,2) + dy*(width - 1);
    end
end

for i = 1:ny
    for j = 1:nx
        % DS
        for d = 1:4
            % 3 pixels
            if x(j) >= ds_big(d,1) && x(j) <= ds_big(d,2) && ...
                    y(i) >= ds_big(d,3) && y(i) <= ds_big(d,4)
                amended_pixels(i,j) = 2;
            end
            % 1 pixel
            if x(j) == ds_small(d,1) && y(i) == ds_small(d,2)
                amended_pixels(i,j) = 1;
            end
        end
        
        % FW
        if parcelCover(i,j) == 6 && parcelCover(i,j+1) == 0
            amended_pixels(i,j+1:j+2) = 4;
            amended_pixels(i,j+1) = 3;
        end
        
        % DW
        if parcelCover(i,j) == 5 && parcelCover(i,j+1) == 0
            amended_pixels(i,j+1:j+2) = 6;
            amended_pixels(i,j+1) = 5;
        end
        
        % SW
        if y(i) == (fc(4,3) + dy/2) && parcelCover(i-1,j) == 0
%             amended_pixels(i-4:i-1,j) = 1; % SW4
            amended_pixels(i-2:i-1,j) = 8; % SW2
            amended_pixels(i-1,j) = 7; %SW1
        end
    end
end
% amended_pixels(amended_pixels == 0) = 9;

% Plot
figure(3)
hold on
pcolor(Xy,Yx,amended_pixels.*mask)
shading flat
rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
    '-','LineWidth',1.5);
cmap = flipud(brewermap([9],'Paired'));
cmap(1,:) = 1;
colormap(cmap)
caxis([-0.5,8.5])
c = colorbar;
c.Ticks = 0:8;
c.Box = 'off';
c.TickLabels = {"Downspout","Sidewalk","Frontwalk","Driveway","Large","Small"};
c.Label.String = "Size of Amendment";
xlabel('Distance (m)');
ylabel('Distance (m)');
title("Features")
axis equal
axis([xL xU yL yU])
set(gca,'Color',[0.7 0.7 0.7])
hold off

