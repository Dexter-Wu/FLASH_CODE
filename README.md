%%%%%
%%%%%


FLIM DATA PROCESSING AND RECONSTRUCTION TOOLBOX: DOCUMENTATION

================================================================
I. PREREQUISITES & MATLAB TOOLBOXES
================================================================
To run this toolbox, ensure the following are installed in your MATLAB environment:

1. Parallel Computing Toolbox: 
   Used for accelerating pixel-wise fitting and image reconstruction via 
   multi-core parallelization.

2. Curve Fitting Toolbox: 
   Required for lifetime estimation (tau estimation) and decay modeling.

3. Statistics and Machine Learning Toolbox: 
   Used for statistical analysis of intensity/lifetime distributions.

4. Image Processing Toolbox: 
   Required for basic image manipulation and visualization.

================================================================
II. DATA DESCRIPTION (TEST DATASETS) 
================================================================
The following datasets are used for testing and validation:

* Phantom Experiments (Varying Thickness):
  - testData384: 1 mm thickness phantom
  - testData383: 2 mm thickness phantom
  - testData382: 3 mm thickness phantom
  - testData381: 4 mm thickness phantom

* Biological Experiments:
  - testData150: In vivo mouse experimental data

Code source: http://gofile.me/6Ud2V/KXTGhqBHa
================================================================
III. PROJECT STRUCTURE (MAIN SCRIPTS)
================================================================
* Main_Mouse.m: 
  Processes FLIM data from mouse (testData150).

* Main_phantom_V4.m: 
  Processes phantom data (testData381-384).

* Mian_ShowPeriodOverlay_V4.m: 
  Investigates the effect of cycle (period) overlaying on image quality.

================================================================
IV. FUNCTION LIBRARY
================================================================

A. PRE-PROCESSING
-----------------
- FLIM_ImgPath: 
  Configures and manages data storage directories.
- FLIM_Extraction_Timepoint: 
  Identifies and determines specific time points in the sequence.
- FLIM_Extraction_Intensity: 
  Extracts specific image segments from raw time-series data.

B. RECONSTRUCTION (I_hat, N_hat, tau_hat)
-----------------------------------------
- FLIM_Intensity_Recon: 
  Estimates intensity (I_hat) and photon count (N_hat).
- FLIM_Lifetime_Recon: 
  Performs pixel-wise estimation of fluorescence lifetime (tau_hat).
- FLIM_Intensity_Descattering: 
  Implements the Dark Channel Prior (DCP) algorithm to remove scattering.
- FLIM_Lifetime_Construct_Interleaved_Data: 
  Consolidates periodic data into an interleaved dataset for reconstruction.

C. VISUALIZATION & DIAGNOSTICS
------------------------------
- FLIM_ShowPhasesImage: 
  Displays raw phase data.
- FLIM_ShowReconImage: 
  Visualizes standard reconstructed Intensity and Lifetime maps.
- FLIM_ShowEnhanceImage: 
  Displays enhanced results specifically for phantom data.
- FLIM_ShowEnhanceImage_mouse: 
  Displays enhanced results specifically for mouse experimental data.
- FLIM_Showcyclesmaps: 
  Visualizes the result of a single cycle overlay.
- FLIM_Showallcyclesmaps: 
  Compares results across different cycle overlay configurations.

================================================================
V. USAGE NOTES
================================================================
- Parallelization: 
  Reconstruction functions automatically initiate a 'parpool'. Ensure 
  your hardware supports parallel workers for optimal performance.
- Optimization: 
  The de-scattering algorithm (DCP) is specifically optimized for 
  improving contrast in turbid media (phantoms and tissue).

