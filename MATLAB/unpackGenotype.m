function [W,a,b,c,d,tau_pressure,tau_tension,Wp,Wt,delays] =...
    unpackGenotype(individual,N,numProj)
    
    evolve_polarity=1;
    W = zeros(N,N);
    polarity = zeros(N,1);
    a = zeros(N,1);
	b = zeros(N,1);
	c = zeros(N,1);
	d = zeros(N,1);
    
    Wp = zeros(1,numProj);
    Wt = zeros(1,numProj);
    
    delays = zeros(N,N);
    
    k=1; %% initialize the index that will count along the genome
			
    %% decode weights
    for i=1:N
        for j=1:N
            W(i,j) =  individual(1,k); %% W(to,from)
            k=k+1;
        end
    end
    
    %% decode polarity
    for i=1:N 
        polarity(i) = individual(1,k);
        k=k+1;
    end	

    %% evolvable polarity
    %% - set W negative and scale down slightly
    if evolve_polarity==1
        for i=1:N 
            if polarity(i)<=0.5 
                W(:,i) = -W(:,i);
            end
        end
    end

    %% decode variable a
    for i=1:N 
        a(i) = individual(1,k);
        k=k+1;
    end

    %% decode variable b
    for i=1:N 
        b(i) = individual(1,k);
        k=k+1;
    end		

    %% decode variable c
    for i=1:N 
        c(i) = individual(1,k);
        k=k+1;
    end	

    %% decode variable d
    for i=1:N 
        d(i) = individual(1,k);
        k=k+1;
    end
    
    tau_pressure = individual(1,k); k=k+1;
    tau_tension = individual(1,k); k=k+1;
    
    for i=1:numProj 
        Wp(1,i) = individual(1,k);
        k=k+1;
    end
    
    
    for i=1:numProj 
        Wt(1,i) = individual(1,k);
        k=k+1;
    end
    
    %% decode axonal delays
    for i=1:N
        for j=1:N
            delays(i,j) =  round(individual(1,k)); %% delays(to,from)
            k=k+1;
        end
    end
    