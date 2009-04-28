%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SIMULATED MUSCLE
%
% [control_value] = syringealForcing(T,DT,v,tau_syrinx,W,Eex,VREST)
%
%------------------------------------------------------------

function [control_value] = syringealForcing(T,DT,v,tau_syrinx,W,Eex,VREST)
    clear control_value     
    tau = 20;       % ms    membrane time constant (decay)
    
    % initialize parameters
    Gex = zeros(1,length(T));
    control_value = zeros(1,length(v));
    I = zeros(1,length(v));
     
    for t=1:length(T)-1; 
      
       fired=find(v(:,t)>=25);
    
        if ~isempty(fired)
           Gex(1,t)=Gex(1,t)+sum(W(1,fired),2)/2;
        end;

        dvdt = (...
            VREST - control_value(1,t) + ...
            Gex(1,t).*(Eex - control_value(1,t)) + ...
            I(1,t))/tau;

        control_value(1,t+1) = control_value(1,t) + dvdt*DT;

        % conductance decay
        dgdt = -Gex(1,t)/tau_syrinx;
        Gex(1,t+1) = Gex(1,t) + dgdt*DT;    
    end
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 