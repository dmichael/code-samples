%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   evolutionarySongbird(plot,populationSize,numGenerations,...
%                         outputPath,targetFile,tfinal
%   
%   David M Michael 
%   Evolutionary and Adaptive Systems MSc, University of Sussex
%   Thesis project
%   Summer 2005
%
%   http://www.hksintl.com/academic
%   http://www.sussex.ac.uk/~dmm25
%   david.michael@gmail.com
% 
%   Program description
%   ------------------------------ 
%   This program implements an evolvable model of the songbird. 
%   - HVC and RA nuclei
%   - Spiking neural model
%   - Genetic algorithm (microbial) 
% 
%   Implementation notes:
%   ------------------------------ 
% 
%   NEURON MODELS
%   Izhikevich simple model - available from:
%   http://www.nsi.edu/users/izhikevich/
%    
%    
%   GENETIC ALGORITHM
%   Implemented with the Genetic Algorithm Toolbox version 1.2
%   by Andrew Chipperfield, Peter Fleming, Hartmut Pohlheim,
%   and Carlos Fonseca
%   University of Sheffield
%   http://www.shef.ac.uk/acse/research/ecrg/gat.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function evolutionarySongbird(plot,populationSize,numGenerations,...
                              outputPath,targetFile,tfinal)
    
if nargin < 6, tfinal = 330; end
if nargin < 5, targetFile = 'towhee_syllable1.wav'; end
if nargin < 4, outputPath = './'; end
if nargin < 3, numGenerations = 1; end
if nargin < 2, populationSize = 2; end
if nargin < 1, disp 'plotting off...', plot = 0; end	
        
mutationRate = 0.7;	

% SIMULATION INITIAL SETTINGS
% ------------------------------------------------------------------
Fs = 22050;                   % Sampling freq: (samples per second)
%tfinal = 450;                % simulation duration (ms) 
oversample = 4;               % (N times oversampling)
dt = 1000/(Fs*oversample);    % Integration time stepsize 
T = (0:dt:tfinal);            % time vector

% SAVE THE SIMULTATION SETTINGS
simSpecsFilename=[outputPath,'simulationSpecs.mat'];
save(simSpecsFilename,'targetFile','Fs','tfinal','oversample','dt','T')
% ------------------------------------------------------------------
    


% NEURAL NETWORK NUCLEI SETTINGS
% -----------------------------------------------------------------
HVC_total = 50;
RAinter = 36; RAproj = 36;
RA_total = RAinter + RAproj; numProj = RAproj/2;
N = HVC_total + RA_total;		

% Contruct addresses (used primarily for setting weights)
RA_interneurons = HVC_total+1:HVC_total+RAinter;
RA_projection = HVC_total+RAinter+1:N;
RA_pressure = RA_projection(1,1:numProj);
RA_tension = RA_projection(1,numProj+1:end);
% -----------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENOTYPE SETUP
% -----------------------------------------------------------------
% Each genome should contain all evolvable parameters to build
% ONE SONGBIRD
% - connection weights are ordered FIRST in the genome SEQUENTIALLY 
% you must decide  decode how the connection weights are ordered
% - (to,from)!!!

% Connection weights limits (Lower,Upper)
weightsL = zeros(1,N*N);        weightsU = 1.3*ones(1,N*N);

% excitary/inhibitory setting for optional use:
polarityL = zeros(1,N);         polarityU = ones(1,N);

% Izhikevich model parameters 
Amin = 0.01*ones(1,N);          Amax = 0.09*ones(1,N);
Bmin = 0.1*ones(1,N);           Bmax = 0.25*ones(1,N);
Cmin = -50*ones(1,N);           Cmax = -65*ones(1,N);
Dmin = 2*zeros(1,N);            Dmax = 8*ones(1,N);

% Syrinx evolvable parameters
tau_pL = 5;                     tau_pU = 30; % ms
tau_tL = 5;                     tau_tU = 30;  % ms  
W_pL = zeros(1,numProj);        W_pU = 0.7*ones(1,numProj);
W_tL = zeros(1,numProj);        W_tU = 0.7*ones(1,numProj);

minDelay = 0;
maxDelay = 5; % ms
delaysL = zeros(1,N*N);
delaysU = maxDelay*ones(1,N*N)/dt;
% -----------------------------------------------------------------
% FORMAT RANGES FOR THE INDIVIDsizeUAL GENOME FOR USE IN BUILDING THE
% POPULATION
% -----------------------------------------------------------------
fieldDR = [
% weights	+/-		a      b      c      d      syrinx parameters here...         
weightsL	polarityL	Amin   Bmin   Cmin   Dmin   tau_pL   tau_tL     W_pL    W_tL    delaysL; 
weightsU	polarityU	Amax   Bmax   Cmax   Dmax   tau_pU   tau_tU     W_pU    W_tU    delaysU];

% CREATE A RANDOM POPULATION OF REAL VALUED GENOTYES 
% AT THE RANGES SPECIFIED
genotypes = crtrp(populationSize,fieldDR);
    
    
% SAVE THE GENOTYPES AND NETWORK SETTINGS - this should include all 
% settings that will be needed in the genotype unpacking (nuclei)
networkSpecsFilename=[outputPath,'networkSpecs.mat'];
save(networkSpecsFilename,'N','HVC_total',...
    'RA_total','RA_interneurons','RA_projection','RA_tension',...
    'RA_pressure',...
    'numProj','mutationRate'...
)

genotypesFilename=[outputPath,'genotypes_init.mat'];
save(genotypesFilename,'genotypes')
% -----------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

fitnesses=zeros(populationSize,numGenerations);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START OF EVOLUTION
for gen=1:numGenerations	
% clear variables that MATLAB tends to hold on to
clear contestantsGenomes loserGenome genotypes new_genotype

load(genotypesFilename);

if gen > 2
    fitnesses(:,gen) = fitnesses(:,gen-1);
end

% INMAN'S MICROBIAL TOURNAMENT SELECTION         
% -----------------------------------------------------------------
contestant = zeros(1,2);        % Initialize the tournament players

% SELECT TOURNAMENT PAIR (2 at random)
while contestant(1) == 0 || contestant(2) == 0
    contestant = round(rand(1,2)*(populationSize-1))+1;
end
while contestant(1) == contestant(2)
    contestant = round(rand(1,2)*(populationSize-1))+1;
end

disp(['CONTESTANTS: Bird', num2str(contestant(1)),'...
    VS Bird',num2str(contestant(2))]);
disp('---------------');

% GET THE "FITNESSES" OF THE CONTESTANTS
% ------------------------------------------------------
contestantsGenomes = zeros(2,length(genotypes));
renderedFile = {};
error = zeros(2,1);
for i=1:2
    % build for infection of loser
    contestantsGenomes(i,:) = genotypes(contestant(i),:);    
    
    renderedFile{i} = renderSong_Fee2(simSpecsFilename,...
                                        networkSpecsFilename,...
                                        genotypesFilename,outputPath,...
                                        gen,contestant(i),plot);
                            
    error(i) = ...
    spectralFitness3(targetFile,num2str(renderedFile{i}),outputPath);

    fitnesses(contestant(i),gen) = error(i);
end
% ------------------------------------------------------



% SELECTION
% ------------------------------------------------------
if (error(1) < error(2))
    winner = contestant(1);
    loser = contestant(2);
else
    winner = contestant(2);
    loser = contestant(1);
end
% ------------------------------------------------------
disp(['****** WINNER = Bird', num2str(winner),' ******']);
disp('---------------');
disp('---------------');
disp(' ');

% MUTATE THE LOSER and XOVER with the WINNER
% ------------------------------------------------------
% XOVER
new_genotype = recombin('xovdp',contestantsGenomes);
% MUTATION
new_genotype = mutate('mutbga',new_genotype(2,:),fieldDR,[0.2 0.5]);
% monitor amount of change
new_genotype - genotypes(loser,:);

% Reinsert the LOSER into the same place in the population
% Elistism for free! (Cheers Inman)
genotypes(loser,:) = new_genotype;
% ------------------------------------------------------- 

% Save the new population for use in the next round!
%genotypesFilename=[outputPath,'genotypes_gen' ,num2str(gen), '.mat'];
genotypesFilename=[outputPath,'genotypes_lastgen.mat'];
save(genotypesFilename,'genotypes')


fitnessesFilename=[outputPath,'fitnessesSpecs.mat'];
save(fitnessesFilename,'fitnesses')
end
% END OF EVOLUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT the errors over the number of generations
%generations = 1:1:numGenerations;
%plotFitness(generations,fitnesses)

% When you are finished, copy the files to wildlifeanalysis.org
%unixCommand = ['scp ',outputPath,' simulationSpecs.mat ',remotePath]
%unix(unixCommand);
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
