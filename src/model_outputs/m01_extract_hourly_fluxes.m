%extract_hourly_fluxes.m
%Carolyn Voter
%November 13, 2018

% This script reads WBstep.mat for each model run and saves the hourly
% fluxes (mm) in one csv file per model run. Fluxes include: precipitation,
% surface storage, canopy storage, snow storage, subsurface storage,
% subsurface storage in the root zone (top 1m), evaptransum (flux passed
% from CLM to parflow), soil evaporation, surface runoff, transpiration,
% deep drainage, and recharge.

% Note that in September 2018 runs of Cities models, the final matlab water
% balance script (outputsWaterBalanceMatlab.m) forgot to multiply deep
% drainage flux by 1000 (like all the other fluxes). Make that adjustment
% here.

clear all; close all; clc;

%% DIRECTORIES AND FILENAMES
topInDir = 'K:/Parflow/PFoutput';
model_suite = 'parcel_soil_clay_loam';
soil = 'clay_loam'; % measured, loam, clay_loam
inDir = sprintf("%s/2019.06_%s",topInDir,model_suite);
topOutDir = 'J:/git_research/projects/parcel_soil_amendment/results/model_outputs';

% Generate names of models, as saved from original model runs
% TWI
top_percent_pixels = [0, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100];
for i = 1:length(top_percent_pixels)
    runnames{i} = sprintf('amend_pixels_TWI_%s',num2str(top_percent_pixels(i)));
end

% Drain
top_percent_pixels = [0.25, 0.5, 1, 2.5, 5, 10, 25, 50];
for i = 1:length(top_percent_pixels)
    r = length(runnames)+ 1;
    runnames{r} = sprintf('amend_pixels_drain_%s',num2str(top_percent_pixels(i)));
end

% Random
top_percent_pixels = [0.25, 0.5, 1, 2.5, 5, 10, 25, 50];
for i = 1:length(top_percent_pixels)
    r = length(runnames)+ 1;
    runnames{r} = sprintf('amend_pixels_%s_%s',...
        soil,num2str(top_percent_pixels(i)));
end

% Features
ds_key = [1 3 0 0 0 0 0 0 0 1 3 1 3];
fw_key = [0 0 1 2 0 0 0 0 0 1 1 0 0];
dw_key = [0 0 0 0 1 2 0 0 0 1 1 0 0];
sw_key = [0 0 0 0 0 0 1 2 4 1 1 4 4];
for i = 1:length(ds_key)
    r = length(runnames)+ 1;
    runnames{r} = sprintf('amend_feature_ds%d_fw%d_dw%d_sw%d', ds_key(i),...
        fw_key(i), dw_key(i), sw_key(i));
end

for i = 1:length(runnames)
    outDir = sprintf("%s/%s",topOutDir,runnames{i});
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end
end

%% EXTRACT AND RESAVE HOURLY FLUXES
colnames = {'precipitation','delta_surface_storage','delta_storage_canopy',...
    'delta_storage_snow','delta_storage_subsurface','evaptranssum',...
    'evaporation','surface_runoff','transpiration','deep_drainage',...
    'recharge'};
rangeColnames = 'A1:K1';  % headers
rangeData = 'A2:K5137';  % 5136 hrs (growing season) of output data

for i = 1:length(runnames)
    inFile = strcat(inDir,'\',runnames{i},'\WBstep.mat');
    outDir = sprintf("%s/%s",topOutDir,runnames{i});
    if exist(inFile, 'file')
        load(inFile)
        saveFile = sprintf('%s/%s_%s_hourly_balance.csv',outDir, soil, runnames{i});
        hourlyBalanceArray = [precip_step,dSs_step,dcan_step,dsno_step,...
            dSss_step,etS_step,ev_step,sr_step,tr_step,dd_step,re_step];
        hourlyBalanceTable = array2table(hourlyBalanceArray,'VariableNames',colnames);
        writetable(hourlyBalanceTable,saveFile,'Delimiter',',')
    end
    clearvars -except inDir soil topOutDir runnames colnames ...
        rangeColnames rangeData i
end
