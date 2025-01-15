
% ======================================================================= %
%                                                                         %
% This script determines the optimal net primary production (NPP) model   %
% for use in the SLAM DUNK project by comparing five models against       %
% in situ NPP data derived from the 14C method at four time-series        %
% stations. The analysis is based on matchup statistics. The script also  %
% evaluates global NPP distribution for the five models and calculates    %
% integrated global stocks using two different interpolation methods.     %
%                                                                         %
% The workflow is divided into the following 8 sections:                  %                                  
%   Section 1 - Presets                                                   %
%   Section 2 - Calculation of globally integrated NPP stocks             %
%   Section 3 - Visualisation of monthly modelled NPP                     %
%   Section 4 - Visualisation of annual modelled NPP                      %
%   Section 5 - Processing of 14C in situ observations and monthly values %
%   Section 6 - Extraction of modelled NPP at study locations             %
%   Section 7 - Calculation of matchup statistics                         %
%   Section 8 - Bar chart comparison of observations-models               %
%                                                                         %
%   WRITTEN BY A. RUFAS, UNIVERISTY OF OXFORD                             %
%   Anna.RufasBlanco@earth.ox.ac.uk                                       %
%                                                                         %
%   Version 1.0 - Completed 23 Dec 2024                                   %
%   Version 2.0 - Updated 15 Jan 2025                                     %
%                   - Added a guided gap-filling method that uses a mask  %
%                     created from the combined effect of chla            %
%                     availability and ice coverage                       %
%                                                                         %
% ======================================================================= %

close all; clear all; clc
addpath('./data/processed/');
addpath('./data/raw/');
addpath(genpath('./resources/external/')); 
addpath('./resources/internal/'); 
addpath('./code/');

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 1 - PRESETS
% -------------------------------------------------------------------------

% Input filenames
filenameInputModelledNpp = {'npp_vgpm_modis.mat',...
                            'npp_cbpm_modis.mat',...
                            'npp_cafe_modis.mat',...
                            'npp_bicep.mat',...
                            'npp_carr2002_seawifs_pathfinder_zeub97.mat',...
                            'npp_carr2002_modis_pathfinder_zeuc02.mat'}; 

filenameInputInsituNpp    = 'npp_c14.xls'; % in situ NPP data from the 14C method at study locations
filenameInputCustomMask   = 'custom_mask_icefrac_cmems_chla_occci.mat'; % mask to guide gap-filling                  

% Output filenames
filenameOutputModelledNppProcessed   = 'npp_modelled.mat';
filenameOutputCsvTableLocalNpp       = 'npp_local_14Cobs_and_modelled.csv';
filenameOutputLatexTableMatchupStats = 'npp_matchup_stats.tex';

% Naming conventions
labelLocations = {'ALOHA','BATS','EqPac','OSP'}; % study locations, notice names are the same as in the input file 'npp_c14.xls' 
labelModels = {'VGPM (MODIS)','CbPM (MODIS)','CAFE (MODIS)','BICEP (merged)',...
    'Carr (SeaWiFS, B&F97)','Carr (MODIS, C02)',};

% Build study location information
locationInformation = array2table(NaN(numel(labelLocations), 2), ...
    'VariableNames', {'latitude', 'longitude'}, ...  
    'RowNames', labelLocations);                     
locationInformation{1,:} = [22.5, -158];
locationInformation{2,:} = [31.6, -64.2];
locationInformation{3,:} = [0,    -140];
locationInformation{4,:} = [50,   -145];   

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 2 - CALCULATION OF GLOBALLY INTEGRATED NPP STOCKS
% -------------------------------------------------------------------------

calculateGloballyIntegratedNpp(filenameInputModelledNpp,filenameInputCustomMask,...
    labelModels,filenameOutputModelledNppProcessed)
 
% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 3 - VISUALISATION OF MONTHLY MODELLED NPP
% -------------------------------------------------------------------------

mapMonthlyNpp(filenameInputModelledNpp,filenameOutputModelledNppProcessed)

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 4 - VISUALISATION OF ANNUAL MODELLED NPP
% -------------------------------------------------------------------------

mapAnnualNpp(filenameInputModelledNpp,filenameOutputModelledNppProcessed)

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 5 - PROCESSING OF 14C IN SITU OBSERVATIONS AND MONTHLY VALUES
% -------------------------------------------------------------------------

nppInsituMonthlyMean = processInsituNpp(filenameInputInsituNpp,labelLocations); 

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 6 - EXTRACTION OF MODELLED NPP AT STUDY LOCATIONS
% -------------------------------------------------------------------------

% Use gap-filled modelled data
nppModelLocalMonthlyMean = extractLocalModelledNpp(filenameInputModelledNpp,...
    filenameOutputModelledNppProcessed,locationInformation); 

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 7 - CALCULATION OF MATCHUP STATISTICS
% -------------------------------------------------------------------------

[matchupStats,combinedModelAndObsNpp] = calculateMatchupStatistics(...
    nppInsituMonthlyMean,nppModelLocalMonthlyMean,labelModels,labelLocations,...
    filenameOutputLatexTableMatchupStats,filenameOutputCsvTableLocalNpp);

% =========================================================================
%%
% -------------------------------------------------------------------------
% SECTION 8 - BAR CHART COMPARISON OF OBSERVATIONS AND MODELS
% -------------------------------------------------------------------------

plotBarChartInsituVsModelled(combinedModelAndObsNpp,labelModels,labelLocations)
