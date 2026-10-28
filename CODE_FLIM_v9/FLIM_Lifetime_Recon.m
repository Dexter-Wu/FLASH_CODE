function [R_square_Img, Lifetime_Img] = FLIM_Lifetime_Recon(Lifetime_data_fitting, Lifetime_data_t_axis, Lifetime_Mask, ImgPath, FilterSize, method)
% FLIM_Lifetime_withmask_withregulationV3 - Fluorescence lifetime fitting with mask
% 
%   [R_square_img, Lifetime_Img] = FLIM_Lifetime_Recon( ...
%       Lifetime_data_fitting, Lifetime_data_t_axis, Lifetime_Mask, ImgPath, method)
%
%   This function performs pixel-wise fitting of fluorescence decay curves
%   using either nonlinear exponential fitting or log-linear fitting. A
%   binary mask is used to skip irrelevant pixels. Results include both
%   lifetime (tau) and coefficient of determination (R²) maps.
%
%   INPUTS:
%       Lifetime_data_fitting : 3D decay data (len × wid × T)
%                               T is the number of time points
%       Lifetime_data_t_axis  : 1D vector, time axis (seconds), length = T
%       Lifetime_Mask         : 2D binary mask (len × wid), 0 means skip pixel
%       ImgPath               : directory path to save results
%       method                : fitting method, either
%                               'nonlinear' (default) or 'log'
%
%   OUTPUTS:
%       R_square_img          : 2D map (len × wid), coefficient of determination R²
%       Lifetime_Img          : 2D map (len × wid), fitted fluorescence lifetime (seconds)
%
%   Author: (Your name / lab)
%   License: MIT
% -------------------------------------------------------------------------

    if nargin < 5
        method = 'nonlinear'; % default method
    end

    disp('Fitting started...');

    [len, wid] = size(Lifetime_Mask);
    R_square_Img = zeros(len, wid);
    Lifetime_Img = zeros(len, wid);

    switch lower(method)
        case 'nonlinear'
            startTime = datetime('now');
            fprintf('Nonlinear fitting start: %s\n', string(startTime, 'HH:mm:ss'));
            fprintf('Est. runtime: %.1f min\n', len*wid*0.005/60);
        case 'log'
            startTime = datetime('now');
            fprintf('Log-linear fitting start: %s\n', string(startTime, 'HH:mm:ss'));
            fprintf('Est. runtime: <1 min\n');
    end

    % ------------------ Preprocessing ------------------
    extend_length_back_all = size(Lifetime_data_fitting,3);

    % Apply Gaussian smoothing along the temporal dimension
    Lifetime_data_filtered = zeros(len, wid, extend_length_back_all);
    if FilterSize == 0
            Lifetime_data_filtered = Lifetime_data_fitting;
    else
        for jj = 1:extend_length_back_all
            Lifetime_data_filtered(:,:,jj) = imgaussfilt(Lifetime_data_fitting(:,:,jj), "FilterSize", FilterSize);
        end
    end


    % ------------------ Pixel-wise fitting ------------------
    pixel_count = 0;
    replaced_count = 0;
    
    parfor j = 1:len
        for i = 1:wid

            % Skip pixels outside mask
            % i = 187;j = 107;
            if Lifetime_Mask(j,i) == 0
                continue;
            end

            pixel_count = pixel_count + 1;

            % Extract decay curve
            temp_vec = reshape(Lifetime_data_filtered(j,i,:), 1, extend_length_back_all);
            axis_t_curve = Lifetime_data_t_axis;

            try
                switch lower(method)
                    case 'nonlinear' % --- Nonlinear exponential fitting ---
                        curve = temp_vec - mean(temp_vec(1,end-floor(length(temp_vec)/3):end));
                        % curve = temp_vec;
                        max_curvest = max(curve(1:3));

                        [xData, yData] = prepareCurveData(axis_t_curve, curve);
                        ft = fittype('exp1');
                        opts = fitoptions('Method','NonlinearLeastSquares', ...
                                          'Display','Off', ...
                                          'Lower',[max_curvest*0.95 -inf], ...
                                          'Upper',[max_curvest*1.01 inf], ...
                                          'StartPoint',[max_curvest 0]);

                        [fitresult, gof] = fit(xData, yData, ft, opts);

                        R_square = gof.rsquare;
                        tau = -1 / fitresult.b;
  

                    case 'log' % --- Log-linear fitting ---
                        warning('off');
                        num_off = mean(temp_vec(1,end-floor(length(temp_vec)/3):end)); %% DATA FILTER
                        curve = temp_vec-num_off;
                        curve = curve - min(curve);
                        valid_idx = curve > 0;
                        y = log(curve(valid_idx));
                        x = axis_t_curve(valid_idx);

                        % figure;scatter(x,y)
                        % figure;scatter(axis_t_curve(valid_idx),curve(valid_idx))

                        % Linear regression: y = a + b*x
                        P = polyfit(x,y,1);
                        y_fit = polyval(P,x);
                        % y_fit = real(y_fit);

                        slope = P(1);
                        tau = -1 / slope;
                        tau = real(tau);

                        % R²
                        SS_res = sum((y - y_fit).^2);
                        SS_tot = sum((y - mean(y)).^2);
                        R_square = 1 - SS_res/SS_tot;
                        R_square = real(R_square);

                end
            catch
                R_square = 0;
                tau = 0;
                replaced_count = replaced_count + 1;
            end

            % Filter out invalid values
            if tau < 0 || tau > 1
                tau = 0;
                replaced_count = replaced_count + 1;
            end

            R_square_Img(j,i) = R_square;
            Lifetime_Img(j,i) = tau;
        end

        % disp(['pixels = ', num2str(j) ,'/',num2str(size(R_square_Img,3))]);

    end
    toc
    
    % ------------------ Save results ------------------
    save(fullfile(ImgPath,'Lifetime_Img.mat'),'Lifetime_Img');
    save(fullfile(ImgPath,'R_square_Img.mat'),'R_square_Img');
    disp(['Fitting completed: Valid pixels = ', num2str(pixel_count), ...
          ', Replaced pixels = ', num2str(replaced_count)]);

    endTime = datetime('now');
    duration = endTime - startTime;
    fprintf('Completed at: %s (%.1f min)\n', string(endTime, 'HH:mm:ss'), minutes(duration));

    % ------------------ Visualization ------------------
    % figure;
    % subplot(121); imagesc(R_square_img); axis image; clim([0 1]); colorbar; 
    % title('R-square map'); 
    % subplot(122); imagesc(Lifetime_Img*1e6); axis image; colorbar; 
    % title('Lifetime map (\mus)');

end
