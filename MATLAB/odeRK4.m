%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% RUNGE-KUTTA 4th order integration
%------------------------------------------------------------
function [t,y] = odeRK4(diffeq,tfinal,dt,y_init,varargin)   
    h = dt;
    t = (0:h:tfinal)';      % Column vector of elements with spacing h 
    n = length(t);          % Number of elements in the t vector 
  
    [m,mm] = size(y_init);
    y = zeros(m,n);         % Preallocate y for speed 
    % Avoid repeated evaluation of constants 
    h2 = h/2; h3 = h/3; h6 = h/6;

    % Begin RK4 integration; j=1 for initial condition 
    for j=2:n 
        k1 = feval(diffeq, j, t(j-1), y(:,j-1), varargin{:}); 
        k2 = feval(diffeq, j, t(j-1)+h2, y(:,j-1)+h2*k1, varargin{:}); 
        k3 = feval(diffeq, j, t(j-1)+h2, y(:,j-1)+h2*k2, varargin{:}); 
        k4 = feval(diffeq, j, t(j-1)+h, y(:,j-1)+h*k3, varargin{:}); 
        y(:,j) = y(:,j-1) + h6*(k1+k4) + h3*(k2+k3); 
    end 