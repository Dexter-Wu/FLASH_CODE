function ImgPath = FLIM_ImgPath(testData,STAR,num_cycle)
    %% IMAGE SAVEPATH
    folderName = sprintf('FLIM_IMG_%d_%d',STAR,num_cycle);  % save path
    ImgPath = fullfile(testData, folderName); 
    if ~exist(ImgPath,'dir')
	mkdir(ImgPath)
    delete(fullfile(ImgPath, '*')); % delete all file
    end 
    

    %% ELSE ...
end