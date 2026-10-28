clc;clear;close all;
addpath(genpath('.\slanCM'));
addpath(genpath('.\frangi_filter_version2a'));

%% part 0；Parameter configuration and data loading
% data loading
dataIndex = '150';
Path = ['testData',dataIndex];
load([Path,'\Database_all.mat']);

%% parameter setting
% Signal generator parameters
impulse_freq = 100;                  % Laser pulse frequency (in Hz)
impulse_period = 1/impulse_freq;     % Pulse period
duty_cycle = 0.5;                    % Duty cycle
t0 = 0;                              % Laser on time
t2 = impulse_period*duty_cycle ;     % Laser off time
t4 = impulse_period;                 % Start time of the new period

% Camera parameters
freq = 1000;                         % Camera frame rate (in Hz)
dt = 1/freq;                         % Acquisition time for a single image

% Image storage parameters
STAR = 1;
num_cycle = 50;                      % Number of cycles to be sum
Img_length = round(num_cycle * impulse_period / dt); % Calculate the total number of images to be processed 
ImgPath = FLIM_ImgPath(Path,STAR,num_cycle);            % Image storage folder


%% Part I: Extraction of Temporal Phases from Raw Video Images

% 1.1 Segmentation
k0 = floor(t0*freq);               % Image index corresponding to the laser's start time
k2 = floor(t2*freq);               % Image index corresponding to the laser's off time
k4 = floor(t4*freq);               % Image index corresponding to the start of the next cycle

Thresh_high = 0.93;
Thresh_Low = 0.05;
SmoothingNumber = 1;
[k1,k3] = FLIM_Extraction_Timepoint(Database_all,Thresh_high,Thresh_Low,k0,k2,k4,SmoothingNumber);

% k1 = 2; % our parameter
% k3 = 7; % our parameter

% 1.2 Extration
sat_len = k2-k1; % Saturation phase 
Initial_point = k1;
Image_Saturation = FLIM_Extraction_Intensity(Database_all,Initial_point,sat_len,impulse_period,freq,num_cycle);
base_len = k4-k3; % Baseline phase
Initial_point = k3;
Image_Baseline = FLIM_Extraction_Intensity(Database_all,Initial_point,base_len,impulse_period,freq,num_cycle);
decay_len = k4-k2; % Decay phase
Initial_point = k2;
Image_Decay = FLIM_Extraction_Intensity(Database_all,Initial_point,decay_len,impulse_period,freq,num_cycle);

% 1.3 Rawdata Visualization
num_show = 5;
cycle_length = impulse_period / dt; 
FLIM_ShowPhasesImage(Image_Saturation, Image_Decay, Image_Baseline,k1, k2, k3, ...
                              num_show, num_cycle, cycle_length)         

%% part II:  Intesity Recon 
% 2.1 PreProcessing: Background estimate & Intensity Map Formation 
alpha = 1; 
[Intensity_Map,Noise_Map] = FLIM_Intensity_Recon(Image_Saturation,Image_Baseline,alpha,ImgPath);  

% 2.2 Intensity Map Descattring: 
gamma = 1;
window_radius = 35;
lambda = 0.1;
[I_descattering, Scattering_mask] = FLIM_Intensity_Descattering(Intensity_Map,window_radius,lambda,gamma,ImgPath);

% 2.3 Intensity Map Enhancement(in vivo only)
im = rescale(single(I_descattering)); 
ops = struct('FrangiScaleRange',  [0,4], ...
             'FrangiScaleRatio',  1,     ...
             'FrangiBetaOne',     0.8,       ...
             'FrangiBetaTwo',     0.023,   ...
             'verbose',true, 'BlackWhite', false);

V = FrangiFilter2D(im, ops); % FrangiFilter2D enhancement
se = strel('disk',2);
I_enhancement = imopen(V,se)*65535; % open 
%% part III:  Lifeitme Recon 
% 3.1 Lifetime data Extraction and deniose
[L,W,~] = size(Image_Decay);
Lifetime_data = Image_Decay - Noise_Map;

% 3.2 Lifetime data accumulation 
Lifetime_data_4D = reshape(Lifetime_data, L, W, decay_len, num_cycle); 

% Minor temporal offset per cycle: dt / (num_cycle * 10), 
% time_shift = dt/(num_cycle*100);   % approximately one order of magnitude smaller than dt
time_shift = 1e-7;   % approximately one order of magnitude smaller than dt
method = 'accum'; %%  method - 'accum' (default ) or 'all'
[Lifetime_data_fitting, Lifetime_data_t_axis] = FLIM_Lifetime_Construct_Interleaved_Data(Lifetime_data_4D, dt, time_shift,method);

% 3.3 lifetime Map and R^2 Map generation
Lifetime_Mask = ones(L,W); % mask
method = 'log'; %%  method - 'nonlinear' (default ) or 'log'; 
FilterSize = 0; % odd number
Decay_num = size(Image_Decay,3) - size(Image_Baseline,3);
% Decay_num = size(Lifetime_data_fitting,3);
[R_square_Img,Lifetime_Img] = FLIM_Lifetime_Recon(Lifetime_data_fitting, Lifetime_data_t_axis, Lifetime_Mask, ImgPath, FilterSize, method);


%% part IV Enhancement and Visualization
% 4.1 Recon Visualization
R_square_thre = 0.9;
FLIM_ShowReconImage(Image_Saturation, Noise_Map, Intensity_Map, Lifetime_Img, R_square_Img,R_square_thre)

% 4.2 Enhancement Visualization
R_square_thre = 0.01;
inten_reso = 256;
life_reso = 256;

FLIM_ShowEnhanceImage_mouse(I_descattering, I_enhancement, Lifetime_Img, Intensity_Map, R_square_Img, R_square_thre, inten_reso, life_reso)


