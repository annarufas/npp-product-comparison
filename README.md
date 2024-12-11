## Comparison of Net Primary Production (NPP) Products with In Situ Data from Time-Series Locations

This repository contains a collection of MATLAB scripts developed to evaluate and compare net primary production (NPP) models against *in situ* data. The scripts process, format and visualise freely-available NPP products for the global ocean and compare them with *in situ* oceanographic data from time-series stations using the <sup>14</sup>C technique, enabling the identification of the most optimal model based on this comparison. The workflow addresses the often-overlooked task of systematically assessing multiple existing biogeochemical forcing products for ocean models.

The analysed NPP datasets include: 
- Carbon, Absorption, and Fluorescence Euphotic-resolving ([**CAFE**](http://orca.science.oregonstate.edu/1080.by.2160.monthly.hdf.cafe.m.php)) model
- Carbon-based Production Model ([**CbPM**](http://orca.science.oregonstate.edu/1080.by.2160.monthly.hdf.cbpm2.m.php))
- Vertically Generalized Production Model ([**VGPM**](http://orca.science.oregonstate.edu/1080.by.2160.monthly.hdf.vgpm.m.chl.m.sst.php))
- **Carr ([2002](https://doi.org/10.1016/S0967-0645(01)00094-7)) model**
- ESA Biological Pump and Carbon Exchange Processes ([**BICEP**](https://catalogue.ceda.ac.uk/uuid/69b2c9c6c4714517ba10dab3515e4ee6/)) project model

The scripts used to read `.nc` files from the above repositories and generate the raw data for this repository can be found in this related [repository](https://github.com/annarufas/ocean-data-lab).

## Requirements

To use the content of this repository, ensure you have the following.
- [MATLAB](https://mathworks.com/products/matlab.html) version R2021a or later installed.
- Third-party functions downloaded from [MATLAB'S File Exchange](https://mathworks.com/matlabcentral/fileexchange/): `brewermap` and `subaxis`. Once downloaded, please place the functions under the `./resources/external/` directory.

## MATLAB Scripts

| Num| Script name                       | Script action                                                |
|----|-----------------------------------|---------------------------------------------------------------
| 1  | main.m                            | Main entry point for running the entire data processing and plotting pipeline  |
| 2  | calculateGloballyIntegratedNpp.m  | Calculation of globally integrated NPP stocks                |
| 3  | mapMonthlyNpp.m                   | Visualisation of monthly modelled NPP                        |
| 4  | mapAnnualNpp.m                    | Visualisation of annual modelled NPP                         |
| 5  | nppInsituMonthlyMean.m            | Processing of 14C in situ observations and monthly values    |
| 6  | extractLocalModelledNpp.m         | Extraction of modelled NPP at study locations                |
| 7  | calculateMatchupStatistics.m      | Calculation of matchup statistics                            |
| 8  | plotBarChartInsituVsModelled.m    | Bar chart comparison of observations-models                  |

## Reproducibility

The provided scripts perform a matchup analysis using *in situ* data from the following study sites:
- Hawaii Ocean Time-series (HOT) station ALOHA, in the subtropical NE Pacific (22.45ºN, 158ºW).
- Bermuda Atlantic Time-Series (BATS) study site, in the subtropical NW Atlantic (31.6ºN, 64.2ºW).
- US JGOFS Equatorial Pacific process study experimental site (EqPac), in the central equatorial Pacific upwelling system (–2 to 2ºN, 140ºW).
- Ocean Station Papa (OSP), in the HNLC region of the subpolar NE Pacific (50ºN, 145ºW).

## Acknowledgments

This work was conducted as part of my ESA Living Planet Fellowship at the University of Oxford under the [SLAM DUNK](https://eo4society.esa.int/projects/slam-dunk/) project.

## Cite as

If you use this repository in your research, please cite it as:

> Rufas, A. (2024). annarufas/npp-product-comparison: Initial release (v1.0.0) [collection]. Zenodo. 