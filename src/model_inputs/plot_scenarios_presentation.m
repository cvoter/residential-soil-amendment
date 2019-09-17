%model_inputs_by_drainage.m
%Carolyn Voter
%February 8, 2019

close all; clear all; clc;
set(0,'defaultTextFontSize',14,'defaultTextFontName','Segoe UI Semilight',...
    'defaultAxesFontSize',14,'defaultAxesFontName','Segoe UI Semilight')

%% DATA PATHS AND CONSTANTS
input_dir = 'J:/git_research/projects/parcel_soil_amendment/data/model_inputs';
layout_dir = 'J:/git_research/projects/parcel_soil_amendment/data/layouts';
top_percent_pixels = [0, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100];
percent_strings = {'0', '0.25', '0.5', '1', '2.5', '5', '10', '25', '50', '100'};
percent_labels = {'0%', '0.25%', '0.5%', '1%', '2.5%', '5%', '10%', '25%', '50%', '100%'};

load(sprintf('%s/domainInfo.mat',layout_dir))
amended_pixels = zeros(size(parcelCover));

type = 'random';
for p = 2:length(top_percent_pixels)
    if strcmp(type,'random') ~= 1
        runname = sprintf("amend_pixels_%s_%s",type,percent_strings{p});
    else
        runname = sprintf("amend_pixels_clay_loam_%s",percent_strings{p});
    end
    
    if strcmp(type,'random') == 1 && p == length(top_percent_pixels)
        amended_pixels = amended_pixels + 1;
    else
        load(sprintf('%s/%s/domainInfo.mat',input_dir,runname))
        cellArea = dx*dy;
        [Xy,Yx] = meshgrid(x,y);
        xL = 0; xU = nx*dx;
        yL = 0; yU = ny*dy;
        zL = 0; zU = nz*dz;
        
        amended_pixels(parcelCover == 10) = amended_pixels(parcelCover == 10) + 1;
    end
    
    % Plot
    figure(p)
    hold on
    pcolor(Xy,Yx,amended_pixels.*mask)
    shading flat
    rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
        '-','LineWidth',1.5);
    brewer_map = brewermap([10],'Reds');
    brewer_map(1,:) = [1,1,1];
    colormap(brewer_map)
    caxis([-0.5,9.5])
    xlabel('Distance (m)');
    ylabel('Distance (m)');
    title(sprintf("%s Amended",percent_labels{p}))
    axis equal
    axis([xL xU yL yU])
    set(gca,'Color',[0.7 0.7 0.7])
    hold off
    
end

%% %% FEATURE STUFF
close all
load(sprintf('%s/domainInfo.mat',layout_dir))
amended_pixels = zeros(size(parcelCover));
amended_pixels_sm = zeros(size(parcelCover));

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
                amended_pixels(i,j) = 1;
            end
            % 1 pixel
            if x(j) == ds_small(d,1) && y(i) == ds_small(d,2)
                amended_pixels(i,j) = 2;
                amended_pixels_sm(i,j) = 1;
            end
        end
        
        % FW
        if parcelCover(i,j) == 6 && parcelCover(i,j+1) == 0
            amended_pixels(i,j+1:j+2) = 1;
            amended_pixels(i,j+1) = 2;
            amended_pixels_sm(i,j+1) = 1;
        end
        
        % DW
        if parcelCover(i,j) == 5 && parcelCover(i,j+1) == 0
            amended_pixels(i,j+1:j+2) = 1;
            amended_pixels(i,j+1) = 2;
            amended_pixels_sm(i,j+1) = 1;
        end
        
        % SW
        if y(i) == (fc(4,3) + dy/2) && parcelCover(i-1,j) == 0
%             amended_pixels(i-4:i-1,j) = 1; % SW4
            amended_pixels(i-2:i-1,j) = 1; % SW2
            amended_pixels(i-1,j) = 2; %SW1
            amended_pixels_sm(i-1,j) = 1; %SW1
        end
    end
end
% amended_pixels(amended_pixels == 0) = 9;

%% FIX THE PLOT FOR FEATURES STARTING HERE
% should be red, instead of "paired".
% Plot
figure(1)
hold on
pcolor(Xy,Yx,amended_pixels_sm.*mask)
shading flat
rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
    '-','LineWidth',1.5);
brewer_map = brewermap([3],'Reds');
brewer_map(1,:) = [1,1,1];
colormap(brewer_map)
caxis([-0.5,2.5])
xlabel('Distance (m)');
ylabel('Distance (m)');
title("Small")
axis equal
axis([xL xU yL yU])
set(gca,'Color',[0.7 0.7 0.7])
hold off

figure(2)
hold on
pcolor(Xy,Yx,amended_pixels.*mask)
shading flat
rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
    '-','LineWidth',1.5);
brewer_map = brewermap([3],'Reds');
brewer_map(1,:) = [1,1,1];
colormap(brewer_map)
caxis([-0.5,2.5])
xlabel('Distance (m)');
ylabel('Distance (m)');
title("Large")
axis equal
axis([xL xU yL yU])
set(gca,'Color',[0.7 0.7 0.7])
hold off


