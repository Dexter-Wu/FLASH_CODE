function FLIM_Showallcyclesmaps(Noise_maps, Intensity_maps, I_descattering_maps, I_enhancement_maps, Lifetime_maps, num_cycle_array)
num_cycles = length(num_cycle_array);

% Convert all maps to double
for i = 1:num_cycles
    Noise_maps{i}         = double(Noise_maps{i});
    Intensity_maps{i}     = double(Intensity_maps{i});
    I_descattering_maps{i}= double(I_descattering_maps{i});
    I_enhancement_maps{i} = double(I_enhancement_maps{i});
    Lifetime_maps{i} = double(Lifetime_maps{i})*1e6 ;
end

figure('Color','w','Position',[100 100 1200 900]);

map_names = {'$\hat{N}$ Noise Map', '$\hat{I}_{0}$ Intensity Map', ...
             '$I_{\rm descattering}$', '$I_{\rm enhancement}$', '$\tau$ Lifetime Map'};

for i = 1:num_cycles
    images_array = {Noise_maps{i}, Intensity_maps{i}, I_descattering_maps{i}, I_enhancement_maps{i}, Lifetime_maps{i}};
    for j = 1:5
        idx = (i-1)*5 + j;
        ax1 = subplot(num_cycles,5,idx);

        imagesc(images_array{j}); 
        colormap(ax1,gray); 
        if j ==5
            colormap(ax1,"parula"); 
        end
        axis image off;

        %  colorbar
        cb = colorbar;
        % cb.Label.String = 'Intensity';
        % cb.Label.FontSize = 10;
        cb.Ticks = [ceil(min(images_array{j}(:))), floor(max(images_array{j}(:)))];  % 

        % title
        if i == 1
            title(map_names{j},'Interpreter','latex','FontSize',14);
        end

        % cycle index
        text(0.02, 0.95, sprintf('Cycle %d', num_cycle_array(i)), ...
            'Units','normalized','Color','r','FontSize',10,'FontWeight','bold');
    end
end

end
