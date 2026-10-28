function [k1, k3] = FLIM_Extraction_Timepoint(Database_all, Thresh_high, Thresh_Low, k0, k2, k4, SmoothingNumber)
% FLIM_Extraction_Timepoint - Automatically identify high and low plateau 
%                             time points (k1 and k3) from fluorescence data.
%
% Functionality:
%   This function processes the fluorescence time-series data by averaging, 
%   smoothing, and applying threshold detection to automatically locate 
%   the Saturation phase start point (k1) and Baseline phase start point (k3).
%
% Input Arguments:
%   Database_all     - Raw fluorescence data (L*W*H matrix)
%   Thresh_high      - High threshold ratio for detecting Saturation phase (0–1)
%   Thresh_Low       - Low threshold ratio for detecting Baseline phase (0–1)
%   k0, k2, k4       - Control indices of data regions:
%       k0 - Image index when the laser turns on
%       k2 - Image index when the laser turns off
%       k4 - Image index when the laser turns on again
%   SmoothingNumber  - Window size for moving median filter
%
% Output Arguments:
%   k1 - Index of the high plateau starting point
%   k3 - Index of the low plateau starting point
%

%% Step 1: Dimensionality reduction
% Average along the first two dimensions to obtain a time profile
Database_downsampling = mean(Database_all(:,:,1:k4), [1,2]);
Database_downsampling = squeeze(Database_downsampling); % remove redundant dimension

%% Step 2: Data smoothing
% Use moving median filter to suppress noise
Database_downsampling = smoothdata(Database_downsampling,'movmedian',SmoothingNumber);

%% Step 3: Calculate profile extrema
Profile_min = min(Database_downsampling(k2:k4));
Profile_max = max(Database_downsampling(k0+1:k4));

%% Step 4: Threshold detection
% Detect positions satisfying high and low threshold conditions
Location_high = Database_downsampling(1:k2) >= Thresh_high * Profile_max;
Location_Low  = Database_downsampling(k2:k4) <= (1 + Thresh_Low) * Profile_min;

%% Step 5: Identify the first valid locations
% High plateau (k1)
high_idx = find(Location_high, 1, 'first');
if isempty(high_idx)
    k1 = k2 - 3;  
    warning('High threshold not reached, k1 set to k2-3');
else
    k1 = max(1, high_idx);  
end

% Low plateau (k3)
low_idx = find(Location_Low, 1, 'first');
if isempty(low_idx)
    k3 = k4 - 3;  
    warning('Low threshold not reached, k3 set to k4-3');
else
    k3 = k2 + low_idx - 1;  
end

%% Step 6: Optional visualization
dt = 0.001;
axis_t = (0:dt:dt*(length(Database_downsampling)-1))';  
figure;
plot(axis_t(1:k4), Database_downsampling(1:k4), 'LineWidth', 1.5); 
xlabel('Time (s)');
ylabel('Intensity');
title('Fluorescence Signal with Plateau Detection');
hold on;

% Key points
plot(axis_t(k0+1), Database_downsampling(k0+1), 'ko', 'MarkerSize', 10);
plot(axis_t(k1), Database_downsampling(k1), 'ro', 'MarkerSize', 10); 
plot(axis_t(k2), Database_downsampling(k2), 'ko', 'MarkerSize', 10);
plot(axis_t(k3), Database_downsampling(k3), 'go', 'MarkerSize', 10);
plot(axis_t(k4), Database_downsampling(k4), 'ko', 'MarkerSize', 10);

legend('Signal', 'k0', 'k1', 'k2', 'k3', 'k4');
grid on; hold off;

end
