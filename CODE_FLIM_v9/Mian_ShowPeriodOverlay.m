clc; clear; close all;

%% part 0: Parameter configuration and data loading
dataIndex = '381';
Path = ['testData',dataIndex];
load([Path,'\Database_all.mat'])

%% parameter setting
impulse_freq = 100;                  
impulse_period = 1/impulse_freq;     
duty_cycle = 0.5;                    
t0 = 0;                              
t2 = impulse_period*duty_cycle ;     
t4 = impulse_period;                 

freq = 5000;                         
dt = 1/freq;                         

num_cycle_array = 1:20;                      

% Initialize cell arrays to store results
Noise_maps = cell(1,length(num_cycle_array));
Intensity_maps = cell(1,length(num_cycle_array));
I_descattering_maps = cell(1,length(num_cycle_array));
I_enhancement_maps = cell(1,length(num_cycle_array));
Lifetime_maps = cell(1,length(num_cycle_array));

%% 
for i = 1:length(num_cycle_array)
    num_cycle = num_cycle_array(i);
    Img_length = round(num_cycle * impulse_period / dt);
    Img_length = min(size(Database_all,3),Img_length); % select images
     
    STAR = 1;
    ImgPath = FLIM_ImgPath(Path,STAR,num_cycle);            % Image storage folder

    %% part I: Segmentation & Extraction
    % 1.1 Segmentation
    k0 = floor(t0*freq);               % Image index corresponding to the laser's start time
    k2 = floor(t2*freq);               % Image index corresponding to the laser's off time
    k4 = floor(t4*freq);               % Image index corresponding to the start of the next cycle
    
    % Thresh_high = 0.93;
    % Thresh_Low = 0.05;
    % SmoothingNumber = 1;
    % [k1,k3] = FLIM_Extraction_Timepoint(Database_all,Thresh_high,Thresh_Low,k0,k2,k4,SmoothingNumber);

    % k1 = 8; % our number
    % k3 = 34; % our number

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

    %% part II:  Intesity Recon
    % 2.1 PreProcessing: Background estimate & Intensity Map Formation 
    alpha = 1; 
    [Intensity_Map,Noise_Map] = FLIM_Intensity_Recon(Image_Saturation,Image_Baseline,alpha,ImgPath); 
    

    %% part III:  Lifeitme Recon
    % 3.1 Lifetime data Extraction and deniose
    [L,W,~] = size(Image_Decay);
    Lifetime_data = Image_Decay - Noise_Map;
    
    % 3.2 Lifetime data accumulation 
    Lifetime_data_4D = reshape(Lifetime_data, L, W, decay_len, num_cycle); 
    
    % Minor temporal offset per cycle: dt / (num_cycle * 10), 
    time_shift = 1e-7;   % approximately one order of magnitude smaller than dt
    method = 'accum'; %%  method - 'accum' (default ) or 'all'
    [Lifetime_data_fitting, Lifetime_data_t_axis] = FLIM_Lifetime_Construct_Interleaved_Data(Lifetime_data_4D, dt, time_shift,method);
    
    
    % 3.3 lifetime Map and R^2 Map generation
    Lifetime_Mask = ones(L,W); % mask
    method = 'nonlinear'; %%  method - 'nonlinear' (default ) or 'log'
    FilterSize = 1; % odd number
    % Decay_num = size(Image_Decay,3);
    % Decay_num = size(Image_Decay,3) - size(Image_Baseline,3) + 0 ;
    [R_square_Img,Lifetime_Img] = FLIM_Lifetime_Recon(Lifetime_data_fitting, Lifetime_data_t_axis, Lifetime_Mask, ImgPath, FilterSize, method);


    %% part VI:  Enhancement
    % 4.1 Intensity Map Descattring: Estimated FLIM intensity image after de-scattering and normalization to [0,1]
    gamma = 1;
    window_radius = 35;
    lambda = 0.1;
    [I_descattering, Scattering_mask] = FLIM_Intensity_Descattering(Intensity_Map,window_radius,lambda,gamma,ImgPath);

    % 4.2 Intensity Map Enhancement(phantom only)
    I_enhancement = double(I_descattering).*R_square_Img;
    
    % Store results in cell arrays
    Noise_maps{i} = Noise_Map;
    Intensity_maps{i} = Intensity_Map;
    I_descattering_maps{i} = I_descattering;
    I_enhancement_maps{i} = I_enhancement;
    Lifetime_maps{i} = Lifetime_Img;

end

%% save
save(fullfile(Path, 'FLIM_Result_CellArrays.mat'), ...
    'Noise_maps', 'Intensity_maps', ...
    'I_descattering_maps', 'I_enhancement_maps', ...
    'Lifetime_maps', '-v7.3');

fprintf('All result cell arrays have been saved to:\n%s\n', ...
    fullfile(ImgPath, 'FLIM_Result_CellArrays.mat'));
%% part VI: Visualization (Plot all cycles in one figure)
close all
i = 1;
Noise_Map = Noise_maps{i};
Intensity_Map = Intensity_maps{i};
I_descattering = I_descattering_maps{i};
I_enhancement = I_enhancement_maps{i};
Lifetime_Img = Lifetime_maps{i};

inten_reso = 256;
life_reso = 256;
R_square_thre = 0.9;
FLIM_Showcyclesmaps(Noise_Map, I_descattering, Lifetime_Img, Intensity_Map, R_square_Img, R_square_thre, inten_reso, life_reso)

%% SNR test

close all
slice = Intensity_maps{20};
%  roi
roi_1 = [190, 55, 10, 10];
roi_2 = [175, 250, 10, 10];
roi_3 = [205, 250, 10, 10];
roi_b = [150, 200, 10, 10];

roi = [roi_1;roi_2;roi_3;roi_b];

close all
figure; imshow(Intensity_maps{20},[]);colormap('gray');colorbar;
hold on;
rectangle('Position',roi_1 , 'EdgeColor', [0.33 0.33 0.75], 'LineWidth', 3);  % 2
rectangle('Position',roi_2, 'EdgeColor', [1 0.25 0.5], 'LineWidth', 3); % 1
rectangle('Position',roi_3 , 'EdgeColor', [0.1 0.66 0.66], 'LineWidth', 3); % 3
rectangle('Position',roi_b, 'EdgeColor', [0.6 0.2 0.8], 'LineWidth', 3); % 4

%% SNR FIGURE
SNR_each = zeros(3, num_cycle);
for i = 1:num_cycle
    I = double(Intensity_maps{i});
    bg = imcrop(I, roi_b);
    bg_mean = mean(bg(:));
    bg_std = std(bg(:));

    sig_rois = {roi_1, roi_2, roi_3};
    for j = 1:3
        sig = imcrop(I, sig_rois{j});
        sig_mean = mean(sig(:));
        SNR_each(j, i) = (sig_mean - bg_mean) / bg_std;
    end
end

% draw figure
figure;
hold on;
plot(1:num_cycle, SNR_each(1,:), 'LineWidth', 2, 'Color', [0.33 0.33 0.75]);
plot(1:num_cycle, SNR_each(2,:), 'LineWidth', 2, 'Color', [1 0.25 0.5]);
plot(1:num_cycle, SNR_each(3,:), 'LineWidth', 2, 'Color', [0.1 0.66 0.66]);
hold off;

xlabel('Cycle Number');
ylabel('SNR');
legend({'ROI 1','ROI 2','ROI 3'}, 'Location', 'southeast');  
title('SNR of Each ROI vs Cycle Number');
grid off;
set(gca, 'FontSize', 12, 'LineWidth', 1);


%% lifetime

roi_1 = [190, 55, 10, 10];
roi_2 = [175, 250, 10, 10];
roi_3 = [205, 250, 10, 10];
roi_b = [150, 200, 10, 10];

num_cycle = length(Lifetime_maps);
roi_all = {roi_1, roi_2, roi_3, roi_b};
roi_names = {'ROI 1', 'ROI 2', 'ROI 3', 'Background'};

Lifetime_curve = zeros(4, num_cycle);

for i = 1:num_cycle
    L_img = Lifetime_maps{i};
    for r = 1:4
        roi_now = roi_all{r};
        roi_data = imcrop(L_img, roi_now);
        Lifetime_curve(r, i) = mean(roi_data(:), 'omitnan') * 1e6;   
    end
end

figure;
plot(1:num_cycle, Lifetime_curve(1,:), 'o-', 'LineWidth', 2, 'Color', [0.33 0.33 0.75]); hold on;
plot(1:num_cycle, Lifetime_curve(2,:), 's-', 'LineWidth', 2, 'Color', [1 0.25 0.5]);
plot(1:num_cycle, Lifetime_curve(3,:), '^-', 'LineWidth', 2, 'Color', [0.1 0.66 0.66]);
plot(1:num_cycle, Lifetime_curve(4,:), 'd--', 'LineWidth', 2, 'Color', [0.6 0.2 0.8]);
hold off;

xlabel('Cycle Number');
ylabel('Lifetime (\mus)', 'Interpreter', 'tex');
title('Lifetime Changes in Each ROI');
legend(roi_names, 'Location', 'east');   
% legend(roi_names, 'Location', 'eastoutside');  
grid off;
set(gca, 'FontSize', 12, 'LineWidth', 1);








