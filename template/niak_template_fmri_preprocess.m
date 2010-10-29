% This script demonstrates how to write a script to run an fMRI
% preprocessing pipeline in NIAK.
%
% To actually run a demo of the preprocessing data, please see
% NIAK_DEMO_FMRI_PREPROCESS.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI, preprocessing, pipeline

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting input/output files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Subject 1
files_in.subject1.anat             = '/home/pbellec/demo_niak/anat_subject1.mnc.gz';       % Structural scan
files_in.subject1.fmri.session1{1} = '/home/pbellec/demo_niak/func_motor_subject1.mnc.gz'; % fMRI run 1
files_in.subject1.fmri.session1{2} = '/home/pbellec/demo_niak/func_rest_subject1.mnc.gz';  % fMRI run 2

%% Subject 2
files_in.subject1.anat             = '/home/pbellec/demo_niak/anat_subject2.mnc.gz';       % Structural scan
files_in.subject1.fmri.session1{1} = '/home/pbellec/demo_niak/func_motor_subject2.mnc.gz'; % fMRI run 1
files_in.subject1.fmri.session1{2} = '/home/pbellec/demo_niak/func_rest_subject2.mnc.gz';  % fMRI run 2

%%%%%%%%%%%%%%%%%%%%
%% Bricks options %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%

% General
opt.folder_out          = '/home/pbellec/demo_niak/fmri_preprocess/';            % Where to store the results

% Pipeline manager : Uncomment the following lines if you don't want to use 
% the default configuration. 
% opt.psom.mode                  = 'batch'; % Process jobs in the background
% opt.psom.mode_pipeline_manager = 'batch'; % Run the pipeline manager in the background : if I unlog, keep working
% opt.psom.max_queued            = 2;       % Run as much as two jobs in parallel (Could be more or less, depending on the number of cores on your computer)

% Slice timing correction (niak_brick_slice_timing)
opt.slice_timing.type_acquisition = 'interleaved ascending'; % Interleaved ascending (odd first by default)
opt.slice_timing.type_scanner     = 'Bruker';                % Only the value 'Siemens' will actually have an impact
opt.slice_timing.delay_in_tr      = 0;                       % The delay in TR ("blank" time between two volumes)
opt.slice_timing.flag_skip        = 0;                       % Turn on/off the slice timing (here it is on)

% Motion correction (niak_brick_motion_correction)
opt.motion_correction.suppress_vol = 0;          % There is no dummy scan to supress.
opt.motion_correction.session_ref  = 'session1'; % The session that is used as a reference. Use the session corresponding to the acqusition of the T1 scan.
opt.motion_correction.flag_skip    = 0;          % Turn on/off the motion correction

% Linear and non-linear fit of the anatomical image in the stereotaxic
% space (niak_brick_t1_preprocess)
opt.t1_preprocess.nu_correct.arg = '-distance 50'; % Parameter for non-uniformity correction. 200 is a suggested value for 1.5T images, 50 for 3T images. If you find that this stage did not work well, this parameter is usually critical to improve the results.

% T1-T2 coregistration (niak_brick_anat2func)
opt.anat2func.init = 'identity'; % The 'center' option usually does more harm than good. Use it only if you have very big misrealignement between the two images (say, > 2 cm).

% Temporal filtering (niak_brick_time_filter)
opt.time_filter.hp = 0.01; % Apply a high-pass filter at cut-off frequency 0.01Hz (slow time drifts)
opt.time_filter.lp = Inf;  % Do not apply low-pass filter. Low-pass filter induce a big loss in degrees of freedom without sgnificantly improving the SNR.

% Correction of physiological noise (niak_pipeline_corsica)
opt.corsica.sica.nb_comp             = 20;    % Number of components estimated during the ICA. 20 is a minimal number, 60 was used in the validation of CORSICA.
opt.corsica.component_supp.threshold = 0.15;  % This threshold has been calibrated on a validation database as providing good sensitivity with excellent specificity.
opt.corsica.flag_skip                = 0;     % Turn on/off the motion correction

% resampling in stereotaxic space
opt.resample_vol.interpolation       = 'tricubic'; % The resampling scheme. The most accurate is 'sinc' but it is awfully slow
opt.resample_vol.voxel_size          = [3 3 3];    % The voxel size to use in the stereotaxic space
opt.resample_vol.flag_skip           = 0;          % Turn on/off the resampling in stereotaxic space

% Spatial smoothing (niak_brick_smooth_vol)
opt.smooth_vol.fwhm      = 6;  % Apply an isotropic 6 mm gaussin smoothing.
opt.smooth_vol.flag_skip = 0;  % Turn on/off the spatial smoothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run the fmri_preprocess pipeline  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pipeline,opt] = niak_pipeline_fmri_preprocess(files_in,opt);