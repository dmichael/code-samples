%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   [MSE_total] = spectralFitness(targetFile,renderedFile,outputPath)
%
%   David M Michael 7.2005
%
%   Original algorithm:
%   "Growing sound synthesizers with evolutionary methods"
%   Ricardo Garcia (2001)
%   see also: "FM Synthesis matching using genetic algorithms"
%   Andrew Horner et al (1993)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [MSE_total] = spectralFitness(targetFile,renderedFile,outputPath)
clear MSE_total MSE_mag MSE_mag2 Wm2 STFT_T STFT_R...
    STFT_T_abs STFT_R_abs STFT_T_log STFT_R_log...
    targetSignal renderedSignal


targetSignal = wavread(targetFile);
[renderedSignal,Fs] = wavread(renderedFile);

n = 512; % Number of frequency windows (bins)

STFT_T = myspectrogram_noprompt(targetSignal,n,Fs,hanning(500),475);
STFT_R = myspectrogram_noprompt(renderedSignal(1:length(targetSignal))...
                                ,n,Fs,hanning(500),475);


minfreq = 10;
maxfreq = 5500;
index = 10:n*maxfreq/Fs;

% take desired maxfreq and make positive
STFT_T_abs = abs(STFT_T(index,:)); 
STFT_T_log = STFT_T_abs/max(max(STFT_T_abs)); % normalize to [0  1]
STFT_T_log = log(STFT_T_log);

% take desired maxfreq and make positive
STFT_R_abs = abs(STFT_R(index,:)); 
STFT_R_log = STFT_R_abs/max(max(STFT_R_abs)); % normalize to [0  1]
STFT_R_log = log(STFT_R_log);

num_freq_bins2 = size(STFT_T_log,1);
num_frames2 = size(STFT_T_log,2);

for i=1:num_frames2
    maxSTFT_T_log(i) = max(STFT_T_log(:,i));
    minSTFT_T_log(i) = min(STFT_T_log(:,i));
end

Wm2 = zeros(num_freq_bins2,num_frames2);
for j=1:num_frames2
    for i=1:num_freq_bins2
    Wm2(i,j) =...
     (STFT_T_log(i,j) - minSTFT_T_log(j))/...
     abs(minSTFT_T_log(j) - maxSTFT_T_log(j));
    end
end

XXX = sum(sum(STFT_R_abs));
YYY = sum(sum(STFT_T_abs));
XXX - YYY;

MSE_before = (STFT_R_abs - STFT_T_abs).^2;

MSE = (STFT_R_abs - STFT_T_abs).^2 .* Wm2;

%      figure;specgram(renderedSignal,512,Fs,kaiser(500,5),475);
%      figure; imagesc (MSE); figure(gcf)

MSE_mag2 = sum(MSE,1);
MSE_mag2 = sum(MSE_mag2,2);
MSE_mag2 = (1/num_frames2)*MSE_mag2;


if XXX<(YYY-17000)
    disp('PENALTY for MUCH LESS sound info in the rendered file!')
    MSE_mag2 = MSE_mag2+5000; 
end

if XXX>(YYY+18000)
    disp('PENALTY for MORE sound info in the rendered file!')
    MSE_mag2 = MSE_mag2+500; 
end
MSE_total = MSE_mag2


% -------------------------------------------------------

         
    
   
    