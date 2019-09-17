%analyze_surface_storage_by_feature.m
%Carolyn Voter
%February 8, 2019

close all; clear all; clc;
set(0,'defaultTextFontSize',10,'defaultTextFontName','Segoe UI Semilight',...
    'defaultAxesFontSize',10,'defaultAxesFontName','Segoe UI Semilight')

%% DATA PATHS AND CONSTANTS
weather_dir = '../../data/weather';
layout_dir = '../../data/layouts';
save_dir = '../../data/model_inputs';
soil_dir = '../../data/soil';
IC_dir = '../../data/initial_pressure';
top_percent_pixels = [0, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100];

% Select soil base type
soil_base_file = 'soil_base_clay_loam.mat'; % measured, loam, clay_loam

% Load colormap for heat maps
load('../../data/colormaps/red_top_pixels.mat');

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

%% FEATURE STUFF
% parcelCover key:
    %     0 = turfgrass
    %     1 = street
    %     2 = alley
    %     3 = parking lot
    %     4 = sidewalk
    %     5 = driveway
    %     6 = frontwalk
    %     7 = house
    %     8 = house2 (extra house behind garage)
    %     9 = garage
% fc rows correspond with above key. Columns are:
    %     col 1 = lower x
    %     col 2 = upper x
    %     col 3 = lower y
    %     col 4 = upper y
  
% Downspouts
%   1 pixel
ds_small(1,:) = [fc(7,1)+3*dx/2, fc(7,3)-7*dy/2]; %lower left
ds_small(2,:) = [fc(7,1)+3*dx/2, fc(8,4)+7*dy/2]; % upper left
ds_small(3,:) = [fc(7,2)-3*dx/2, fc(7,3)-7*dy/2]; % lower right
ds_small(4,:) = [fc(8,2)-3*dx/2, fc(8,4)+7*dy/2]; % upper right

%   3 pixels
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


ds{1} = parcelCover;
ds{3} = parcelCover;
for d = 1:4
    for i = 1:ny
        for j = 1:nx
            % 1 pixel
            if x(j) == ds_small(d,1) && y(i) == ds_small(d,2)
                ds{1}(i,j) = 10;
            end
            % 3 pixels
            if x(j) >= ds_big(d,1) && x(j) <= ds_big(d,2) && ...
                    y(i) >= ds_big(d,3) && y(i) <= ds_big(d,4)
                ds{3}(i,j) = 10;
            end
        end
    end
end

% Sidewalk
sw{1} = parcelCover;
sw{2} = parcelCover;
sw{4} = parcelCover;

for i = 1:ny
        for j = 1:nx
            if y(i) == (fc(4,3) + dy/2) && parcelCover(i-1,j) == 0
                sw{1}(i-1,j) = 10;
                sw{2}(i-2:i-1,j) = 10;
                sw{4}(i-4:i-1,j) = 10;
            end
        end
end

% Front walk
fw{1} = parcelCover;
fw{2} = parcelCover;

for i = 1:ny
        for j = 1:nx
            if parcelCover(i,j) == 6 && parcelCover(i,j+1) == 0
                fw{1}(i,j+1) = 10;
                fw{2}(i,j+1:j+2) = 10;
            end
        end
end

% Driveway
dw{1} = parcelCover;
dw{2} = parcelCover;
for i = 1:ny
        for j = 1:nx
            if parcelCover(i,j) == 5 && parcelCover(i,j+1) == 0
                dw{1}(i,j+1) = 10;
                dw{2}(i,j+1:j+2) = 10;
            end
        end
end

%% INPUT STUFF
ds_key = [1 3 0 0 0 0 0 0 0 1 3 1 3];
fw_key = [0 0 1 2 0 0 0 0 0 1 1 0 0];
dw_key = [0 0 0 0 1 2 0 0 0 1 1 0 0];
sw_key = [0 0 0 0 0 0 1 2 4 1 1 4 4];

n = 1;
for m = 1:length(ds_key)
    runname = sprintf('amend_feature_ds%d_fw%d_dw%d_sw%d', ds_key(m),...
        fw_key(m), dw_key(m), sw_key(m));
    run_dir = sprintf('%s/%s',save_dir,runname);
    mkdir(run_dir)
    mkdir(sprintf('%s/NLDAS',run_dir))
    
    % Get Domain Info
    load(sprintf('%s/domainInfo.mat',layout_dir))
    cellArea = dx*dy;
    [Xy,Yx] = meshgrid(x,y);
    xL = 0; xU = nx*dx;
    yL = 0; yU = ny*dy;
    zL = 0; zU = nz*dz;
    
    % Copy same files into this layout directory
    copyfile(layout_dir,run_dir)
    copyfile(weather_dir,run_dir)
    
    % Load Soils Stuff
    load(sprintf('%s/soil_amend.mat',soil_dir))
    load(sprintf('%s/%s',soil_dir, soil_base_file))
    load(sprintf('%s/imperv.mat',soil_dir))
    load(sprintf('%s/semiperv.mat',soil_dir))
    
    % Load IC stuff
    load(sprintf('%s/IC.mat',IC_dir))
    
    % Update parcel cover map to reflect amended soil
    if ds_key(m) ~= 0
        parcelCover(ds{ds_key(m)}==10) = 10;
    end
    if fw_key(m) ~= 0
        parcelCover(fw{fw_key(m)}==10) = 10;
    end 
    if sw_key(m) ~= 0
        parcelCover(sw{sw_key(m)}==10) = 10;
    end
    if dw_key(m) ~= 0
        parcelCover(dw{dw_key(m)}==10) = 10;
    end
    
    % Recreate indicator file: 1 = pervious, 2 = impervious, 3 = amended
    % Allocate arrays
    domTop = zeros([ny,nx]);  % top 20 cm
    domMid1 = zeros([ny,nx]);  % to 30 cm depth
    domMid2 = zeros([ny,nx]);  % to 3m depth
    
    % Identify key areas in XY map:
    % turfgrass, impervious surface, garage, and house
    for i = 1:ny
        for j = 1:nx
            if parcelCover(i,j) == 0  % turfgrass
                domTop(i,j) = 1;
                domMid1(i,j) = 1;
                domMid2(i,j) = 1;
                domBottom(i,j) = 1;
            elseif (parcelCover(i,j) >= 1) && (parcelCover(i,j) < 7)  % Impervious Surface
                domTop(i,j) = 4;
                domMid1(i,j) = 1;
                domMid2(i,j) = 1;
                domBottom(i,j) = 1;
            elseif (parcelCover(i,j) >= 7 && parcelCover(i,j) <= 9)  % garage and house
                domTop(i,j) = 4;
                domMid1(i,j) = 2;
                if (parcelCover(i,j) == 7) || (parcelCover(i,j) == 8)  % just house
                    domMid2(i,j) = 2;
                elseif (parcelCover(i,j) == 9)  % just garage
                    domMid2(i,j) = 1;
                end
                domBottom(i,j) = 1;
            elseif (parcelCover(i,j) == 10) %amended soil
                domTop(i,j) = 3;
                domMid1(i,j) = 1;
                domMid2(i,j) = 1;
                domBottom(i,j) = 1;
            end
        end
    end
        
    % Sidewalk, front walk, driveway only imperv. 1st 2 layers
    % Garage only impervious for top 30cm.
    % House only impervious for top 3m.
    nMid1 = nz - find(z<(zU-0.3),1,'last');
    nMid2 = nz - find(z<(zU-3),1,'last');
    
    % Intialize domain matricies
    subsurface_feature = zeros([ny,nx,nz]);
    dz_mult = zeros([ny,nx,nz]);
    initial_pressure = zeros([ny,nx,nz]);
    for i = 1:nz
        if i <= 2
            subsurface_feature_layer = domTop;
        elseif i <= nMid1
            subsurface_feature_layer = domMid1;
        elseif i <= nMid2
            subsurface_feature_layer = domMid2;
        else
            subsurface_feature_layer = domBottom;
        end
        subsurface_feature(:,:,nz-i+1) = subsurface_feature_layer;
        dz_mult(:,:,i) = varDZ(i)*ones([ny nx]);
        initial_pressure(:,:,i) = IC(i)*ones([ny nx]);
    end
    subsurfaceFeature = matrixTOpfsa(subsurface_feature);
    dz_mult_pfsa = matrixTOpfsa(dz_mult);
    initialP = matrixTOpfsa(initial_pressure);
    
    % Save
    %resave domainInfo
    save(strcat(run_dir,'/domainInfo.mat'),'dx','dy',...
        'dz','nx','ny','nz','x','y','z','domainArea',...
        'Ks_soil','Ks_soil_mean','Ks_soil_sigma','porosity_soil','VGa_soil',...
        'VGn_soil','Sres_soil','Ssat_soil','mn_grass',...
        'Ks_imperv','porosity_imperv','VGa_imperv',...
        'VGn_imperv','Sres_imperv','Ssat_imperv',...
        'mn_imperv','P','Q','R','fc','parcelCover',...
        'slopeX','slopeY','mask',...
        'Ks_amend','porosity_amend','VGa_amend',...
        'VGn_amend','Sres_amend','Ssat_amend','-v7.3');
    
    %add to parameters.txt
    %Parameter text file
    fid = fopen(strcat(run_dir,'/parameters.txt'),'a');
    fprintf(fid,'%.2f\n',xL); %1 0.00
    fprintf(fid,'%.2f\n',yL); %2 0.00
    fprintf(fid,'%.2f\n',zL); %3 0.00
    fprintf(fid,'%.0f\n',nx); %4 integer
    fprintf(fid,'%.0f\n',ny); %5 integer
    fprintf(fid,'%.0f\n',nz); %6 integer
    fprintf(fid,'%.2f\n',dx); %7 0.00
    fprintf(fid,'%.2f\n',dy); %8 0.00
    fprintf(fid,'%.2f\n',dz); %9 0.00
    fprintf(fid,'%.2f\n',xU); %10 0.00
    fprintf(fid,'%.2f\n',yU); %11 0.00
    fprintf(fid,'%.2f\n',zU); %12 0.00
    fprintf(fid,'%.0f\n',P); %13 integer
    fprintf(fid,'%.0f\n',Q); %14 integer
    fprintf(fid,'%.0f\n',R); %15 integer
    fprintf(fid,'%.4e\n',Ks_soil); %16 0.0000E0
    fprintf(fid,'%.4e\n',mn_grass); %17 0.0000E0
    fprintf(fid,'%.2f\n',VGa_soil); %18 0.00
    fprintf(fid,'%.2f\n',VGn_soil); %19 0.00
    fprintf(fid,'%.2f\n',porosity_soil); %20 0.00
    fprintf(fid,'%.2f\n',Ssat_soil); %21 0.00
    fprintf(fid,'%.2f\n',Sres_soil); %22 0.00
    fprintf(fid,'%.4e\n',Ks_imperv); %23 0.0000E0
    fprintf(fid,'%.4e\n',mn_imperv); %24 0.0000E0
    fprintf(fid,'%.2f\n',VGa_imperv); %25 0.00
    fprintf(fid,'%.2f\n',VGn_imperv); %26 0.00
    fprintf(fid,'%.3f\n',porosity_imperv); %27 0.000
    fprintf(fid,'%.2f\n',Ssat_imperv); %28 0.00
    fprintf(fid,'%.2f\n',Sres_imperv); %29 0.00
    fprintf(fid,'%.4e\n',Ks_amend); %30 0.0000E0
    fprintf(fid,'%.2f\n',VGa_amend); %31 0.00
    fprintf(fid,'%.2f\n',VGn_amend); %32 0.00
    fprintf(fid,'%.3f\n',porosity_amend); %33 0.000
    fprintf(fid,'%.2f\n',Ssat_amend); %34 0.00
    fprintf(fid,'%.2f\n',Sres_amend); %35 0.00
    fprintf(fid,'%.4e\n',Ks_soil_mean); %36 0.0000E0
    fprintf(fid,'%.4e\n',Ks_soil_sigma); %37 0.0000E0
    fprintf(fid,'%.4e\n',Ks_semiperv); %38 0.0000E0
    fprintf(fid,'%.4e\n',mn_semiperv); %39 0.0000E0
    fprintf(fid,'%.2f\n',VGa_semiperv); %40 0.00
    fprintf(fid,'%.2f\n',VGn_semiperv); %41 0.00
    fprintf(fid,'%.3f\n',porosity_semiperv); %42 0.000
    fprintf(fid,'%.2f\n',Ssat_semiperv); %43 0.00
    fprintf(fid,'%.2f\n',Sres_semiperv); %44 0.00
    fclose(fid);
    
    %Impervious-pervious indicator file
    fid = fopen(strcat(run_dir,'/subsurfaceFeature.sa'),'a');
    fprintf(fid,'%d% 4d% 2d\n',[nx ny nz]);
    fprintf(fid,'% d\n',subsurfaceFeature(:));
    fclose(fid);
    
    % DZ multiplier
    fid = fopen(strcat(run_dir,'/dz_mult.sa'),'a');
    fprintf(fid,'%d% 4d% 2d\n',[nx ny nz]);
    fprintf(fid,'% 16.7e\n',dz_mult_pfsa(:));
    fclose(fid);
    
    %Save as *.sa file
    fid = fopen(strcat(run_dir,'/ICpressure.sa'),'a');
    fprintf(fid,'%d% 4d% 2d\n',[nx ny nz]);
    fprintf(fid,'% 16.7e\n',initialP(:));
    fclose(fid);
    
    % Plot
    figure(n)
    hold on
    pcolor(Xy,Yx,parcelCover)
    shading flat
    rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
        '-','LineWidth',1.5);
    set(gcf,'Colormap',mycmap)
    caxis([0,10])
    xlabel('Distance (m)');
    ylabel('Distance (m)');
    axis equal
    axis([xL-2 xU+2 yL-2 yU+2])
    hold off
    savefig(sprintf('%s/%s.fig',run_dir,runname))
    
    % Plot
    figure(n+1)
    hold on
    pcolor(Xy,Yx,subsurface_feature(:,:,end))
    shading flat
    rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
        '-','LineWidth',1.5);
    set(gcf,'Colormap',mycmap)
    caxis([1,3])
    xlabel('Distance (m)');
    ylabel('Distance (m)');
    axis equal
    axis([xL-2 xU+2 yL-2 yU+2])
    hold off
    savefig(sprintf('%s/%s_ssf.fig',run_dir,runname))
    
    n = n + 2;
end


