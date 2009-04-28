%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Izhikevich Simple Model Network
%%  - Reimplimented with Euler integration
%%  - Fully connected by default (W=0 where no connections)
%% David Michael, EASy MSc U Sussex
%% June 2005  
%% axonal delays added 7.31.05
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [v,a,b,c,d,firings,INPUT]=izhikevichEuler_Fee2(tfinal,dt,...
                                                                                                    numNeurons,W,a,b,c,d,delays,T,HVC_total,RA_total)

firings=[];
maxDelay=10;
    
v = zeros(numNeurons,length(T));  % pre-allocate voltage array
u = zeros(numNeurons,length(T));  % pre-allocate recovery array
g = zeros(numNeurons,length(T)+maxDelay/dt);

% delay matrix SCALAR is in milliseconds. 
% 'delays' contains number of timesteps... useful in firings measure!
% NB: this should be moved to the genome (7.31.05)

v(:,1) = -60;               % membrane potential
u(:,1) = b.*v(:,1);         % Initial values of u
g(:,1) = 0;             
    tau_g = 6;              % ms

%% INPUTS
%% any constant input must be placed here, least the GA and MATLAB 
%% will not let go of variable values in the loop
%% --------------------------------------------------------
INPUT = zeros(numNeurons,length(T));    

stim_time = round(.2/dt);
stim_size = round(10/dt);
offset2 = round(2/dt);
offset = round(200/dt);
iHVC = 11;           iRA = 1.5;        

ensemble_size = 2;
for num=1:ensemble_size:HVC_total
    to_num=num+ensemble_size-1;
    to_time = stim_time+stim_size;
    INPUT(num:to_num,stim_time:to_time) = iHVC;
    stim_time = stim_time + stim_size + offset2;
end


%% DRIVE THE RA NEURONS WITH A CONSTANT VOLTAGE
RA_proj=RA_total/2;
INPUT(HVC_total+RA_proj+1:end,:) = iRA;

%% ADD NOISE AT NORMAL DISTRIBUTION, MEAN 0
%     irand=0.5*randn(1,1);
%     for i=1:length(T)
%         if mod(i,200)==0
%             irand=0.4*randn(1,1);	
%         end
%         INPUT(:,i) = INPUT(:,i) + irand;
%     end
%% --------------------------------------------------------


%% Izhikevich simple model with Euler integration
%% conductance decay is added to izhikevich's model

%% evalutate the model for the time vector T (defined in ES)
%% minus the length of the maximum delay in timesteps (maxDelay/dt)
dgdt=0;
for t=1:length(T)-1;          
            
    %% Izihkevich original fire detector
    fired=find(v(:,t)>=30);

    if ~isempty(fired) 
        firings=[firings;...% stack on top of the existings 'firings'
                t*ones(length(fired),1),fired];
        
        v(fired,t)=c(fired);
        u(fired,t)=u(fired,t)+d(fired);
        
        
        for j=1:length(fired) 
            for i=1:numNeurons
                tempG=0;

                del=t+delays(i,fired(j));
                tempG=g(i,del)+W(i,fired(j));
                g(i,del) = tempG;

            end
        end           
    
    end;
    
    INPUT(:,t)=INPUT(:,t)+g(:,t);

    %% membrane potential
    dvdt = 0.04*v(:,t).^2+5*v(:,t)+140-u(:,t)+INPUT(:,t);
    v(:,t+1) = v(:,t) + dvdt*dt;

    %% recovery variable
    dudt = a.*(b.*v(:,t)-u(:,t));
    u(:,t+1) = u(:,t) + dudt*dt;
    
    %% conductance decay
    dgdt = -g(:,t)/tau_g;
    for i=1:numNeurons
        if g(i,t+1)>0
            g(i,t+1)=g(i,t+1)+g(i,t);
        else
            g(i,t+1) = g(i,t) + dgdt(i)*dt;
        end
    end
end;