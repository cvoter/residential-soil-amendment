% carsel_parrish_to_log_normal_stats.m
% Carolyn Voter
% 2019.06

close all; clear all; clc;

save_dir = 'J:/git_research/projects/parcel_soil_amendment/data/soil';

%% CARSEL AND PARRISH (1988) VALUES
% % For Loam soils
% soil_name = 'loam';
% Ks_soil = 1.04/100; %mean hydraulic conductivity, cm/hr to m/hr
% sd = 1.82/100; %standard deviation of Ksat, cm/h to m/h
% porosity_soil = 0.43;
% Sres_soil = 0.19; %thetaR/porosity
% Ssat_soil = 1.0;
% VGa_soil = 3.6; %1/m
% VGn_soil = 1.56;
% mn_grass = 6.6667e-05;

% For Clay Loam soils
soil_name = 'clay_loam';
Ks_soil = 0.26/100; %mean hydraulic conductivity, cm/hr to m/hr
sd = 0.70/100; %standard deviation of Ksat, cm/h to m/h
porosity_soil = 0.41;
Sres_soil = 0.095/porosity_soil; %thetaR/porosity
Ssat_soil = 1.0;
VGa_soil = 1.9; %1/m
VGn_soil = 1.31;
mn_grass = 6.6667e-05;

%% TRANFORM TO LOG
% From Quan and Zhang, 2003. Estimate of standard deviation for a
% log-transformed variable using arithmetic means and standard deviations.
% Statistics in Medicine, 22:2723-2736. Eq. 5.

variance_log = log(1 + (sd^2)/(Ks_soil^2));
sd_log = sqrt(variance_log);

mean_log = log(Ks_soil) - (1/2)*variance_log;
mean_log_tranformed = exp(mean_log);

Ks_soil_mean = mean_log_tranformed;
Ks_soil_sigma = sd_log;

%% SAVE
save(sprintf('%s/soil_base_%s.mat',save_dir, soil_name),'Ks_soil','Ks_soil_mean',...
    'Ks_soil_sigma', 'porosity_soil','Sres_soil','Ssat_soil','VGa_soil',...
    'VGn_soil', 'mn_grass')
