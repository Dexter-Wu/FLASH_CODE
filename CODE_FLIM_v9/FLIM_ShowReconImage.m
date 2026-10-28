function FLIM_ShowReconImage(Image_Saturation, Noise_Map, Intensity_Map, Lifetime_Img, R_square_Img,R_square_thre)
% FLIM_ShowIntensityImage - Display FLIM results in 1x4 layout, each with its own colorbar
%
% Inputs:
%   Noise_Map       - Noise estimate (\hat{N})
%   Intensity_Map   - Integrated intensity (\hat{I})
%   I_descattering  - De-scattered image
%   I_no_back       - Background removed / enhanced final image

    % 1. lifetime preprocessing
    Lifetime_temp = Lifetime_Img * 1e6; % s to us
    mask = R_square_Img > R_square_thre;
    Lifetime_masked = zeros(size(Lifetime_temp));
    Lifetime_masked(mask) = Lifetime_temp(mask);
    R_square_Img(R_square_Img<0)  = 0;
    lifetime_max = 1200;
    Lifetime_masked(Lifetime_masked>lifetime_max) =  lifetime_max;
    % lifetime_max = max(Lifetime_masked(:))

    maps = {Image_Saturation(:,:,2),Noise_Map, Intensity_Map, Lifetime_masked, R_square_Img};
    titles = {'Rawdata (Saturation)','$\hat{N}$ Noise Map','$\hat{I}_{0}$ Intensity Map','$\hat{\tau}$ Lifetime Map','$R^{2}$ Map'};
    
    figure('Name','FLIM Processing Results','NumberTitle','off','Color','w','Position',[100 100 1600 400]);
    
    % t = tiledlayout(1,4,'Padding','compact','TileSpacing','compact');
    FontSize_title = 14;
    % for i = 1:4
        % nexttile;
        ax0 = subplot(151);
            imagesc(maps{1}); axis image off; clim([min(maps{1}(:)) max(maps{1}(:))]);
            title(titles{1},'Interpreter','latex','FontSize',FontSize_title);
            colormap(ax0,gray);
            
            % Add individual colorbar for each subplot
            cb = colorbar;
            % cb.Label.String = 'Intensity';
            cb.Label.FontSize = 16;
            %
            cmin = ceil(min(maps{1}(:)));
            cmax = floor(max(maps{1}(:)));
            cb.Ticks = floor(linspace(cmin, cmax, 4));   %  

        ax1 = subplot(152);
            imagesc(maps{2}); axis image off; clim([min(maps{2}(:)) max(maps{2}(:))]);
            title(titles{2},'Interpreter','latex','FontSize',FontSize_title);
            colormap(ax1,gray);
            
            % Add individual colorbar for each subplot
            cb = colorbar;
            % cb.Label.String = 'Intensity';
            cb.Label.FontSize = 16;
            %
            cmin = ceil(min(maps{2}(:)));
            cmax = floor(max(maps{2}(:)));
            cb.Ticks = floor(linspace(cmin, cmax, 4));   %  

       ax2 = subplot(153);
            imagesc(maps{3}); axis image off; clim([min(maps{3}(:)) max(maps{3}(:))]);
            title(titles{3},'Interpreter','latex','FontSize',FontSize_title);
            colormap(ax2,gray);
            
            % Add individual colorbar for each subplot
            cb = colorbar;
            % cb.Label.String = 'Intensity';
            cb.Label.FontSize = 16;

       ax3 = subplot(154);
            imagesc(maps{4}); axis image off; clim([min(maps{4}(:)) lifetime_max]);
            title(titles{4},'Interpreter','latex','FontSize',FontSize_title);
            colormap(ax3,parula);
            
            % Add individual colorbar for each subplot
            cb = colorbar;
            % cb.Label.String = 'Intensity';
            cb.Label.FontSize = 16;
            %
            cmin = ceil(min(maps{4}(:)));
            cmax = floor(lifetime_max);
            cb.Ticks = floor(linspace(cmin, cmax, 4));   % 

       ax4 = subplot(155);
            imagesc(maps{5}); axis image off; clim([0 1]);
            title(titles{5},'Interpreter','latex','FontSize',FontSize_title);
            colormap(ax4,"parula");
            
            % Add individual colorbar for each subplot
            cb = colorbar;
            % cb.Label.String = 'Intensity';
            cb.Label.FontSize = 16;
            %
            % cmin = ceil(min(maps{4}(:)));
            % cmax = floor(max(maps{4}(:)));
            % cb.Ticks = ceil(linspace(cmin, cmax, 4));   % 

end
