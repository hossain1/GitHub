function derivative_ = derivative(t,x,useEoV,u,lengthX,lengthY,epsilon,perturbationCase)

k = @(n)2*n*pi/lengthX;

c2 = .205*u;
c3 = .461*u;

sigma1 = .5*k(2)*(c2 - c3);
sigma2 = 2*sigma1;

switch perturbationCase
    case {1,3}
        epsilon(1) = epsilon(1)/10;
        epsilon(2) = epsilon(2)/10;
end

switch perturbationCase
    case 1
        % Time-periodic psi1, case 1 on page 1691 of
        % doi:10.1016/j.physd.2012.06.012.
        f1 = @(t)exp(1i*sigma1*t);
        f2 = @(t)exp(1i*sigma2*t);
    case {2,3}
        % Time-aperiodic psi1, cases 2 and 3 on page 1691 of
        % doi:10.1016/j.physd.2012.06.012.
        
        % Duffing oscillator
        % FIXME Value copied from Beron-Vera's lcsgeo_bickleyduffing_u1
        beronVeraNT = 5;
        beronVeraW = 5;
        phiTimespan = [0,beronVeraNT*beronVeraW];
        
        phiInitial = [0,0];
        phiSol = ode45(@d_phi,phiTimespan,phiInitial);
        
        timeResolution = 1e5;
        phi1 = deval(phiSol,linspace(phiTimespan(1),phiTimespan(2),timeResolution),1);
                
        % Computational optimization -- solve forcing function once for
        % entire timespan and use interpolation when integrating forced
        % flow.
        phi1Int = griddedInterpolant(linspace(phiTimespan(1),phiTimespan(2),timeResolution),phi1);
        
        beronVeraT = max(2*pi./abs([sigma1,sigma2]));
        
        % Find maximum value of phi
        % FIXME Sufficently large maxSamples found heuristically.
        % maxSamples = 1e3;
        phi1Max = max(phi1);
        
        beronVeraMagicScaleAmp = 2.625e-2;
        beronVeraMagicScaleTime = beronVeraT/beronVeraW;
        
        f1 = @(t)beronVeraMagicScaleAmp*phi1Int(t/beronVeraMagicScaleTime)*phi1Max;
        f2 = f1;
    otherwise
        error('Invalid perturbation case selected')
end

if useEoV
    idx1 = 1:6:size(x,1)-5;
    idx2 = 2:6:size(x,1)-4;
else
    idx1 = 1:2:size(x,1)-1;
    idx2 = 2:2:size(x,1);
end

derivative_ = nan(size(x));

% u
derivative_(idx1) = (cosh(x(idx2)./lengthY).*(u + u.*epsilon(3).*cos(k(3).*x(idx1)).*sinh(x(idx2)./lengthY)) + 2.*u.*real(epsilon(1).*f1(t).*exp(k(1).*x(idx1).*1i)).*sinh(x(idx2)./lengthY) + 2.*u.*real(epsilon(2).*f2(t).*exp(k(2).*x(idx1).*1i)).*sinh(x(idx2)./lengthY))./cosh(x(idx2)./lengthY).^3 - c3;

% v
derivative_(idx2) = - (lengthY.*u.*(imag(epsilon(1).*f1(t).*k(1).*exp(k(1).*x(idx1).*1i)) + imag(epsilon(2).*f2(t).*k(2).*exp(k(2).*x(idx1).*1i))))./cosh(x(idx2)./lengthY).^2 - (lengthY.*u.*epsilon(3).*k(3).*sin(k(3).*x(idx1)))./cosh(x(idx2)./lengthY);

if useEoV
    idx3 = 3:6:size(x,1)-3;
    idx4 = 4:6:size(x,1)-2;
    idx5 = 5:6:size(x,1)-1;
    idx6 = 6:6:size(x,1);
    
    dux = -(2.*u.*imag(epsilon(1).*f1(t).*k(1).*exp(k(1).*x(idx1).*1i)).*sinh(x(idx2)./lengthY) + 2.*u.*imag(epsilon(2).*f2(t).*k(2).*exp(k(2).*x(idx1).*1i)).*sinh(x(idx2)./lengthY) + u.*epsilon(3).*k(3).*sin(k(3).*x(idx1)).*cosh(x(idx2)./lengthY).*sinh(x(idx2)./lengthY))./cosh(x(idx2)./lengthY).^3;
    duy = ((sinh(x(idx2)./lengthY).*(u + u.*epsilon(3).*cos(k(3).*x(idx1)).*sinh(x(idx2)./lengthY)))./lengthY + (2.*u.*real(epsilon(1).*f1(t).*exp(k(1).*x(idx1).*1i)).*cosh(x(idx2)./lengthY))./lengthY + (2.*u.*real(epsilon(2).*f2(t).*exp(k(2).*x(idx1).*1i)).*cosh(x(idx2)./lengthY))./lengthY + (u.*epsilon(3).*cos(k(3).*x(idx1)).*cosh(x(idx2)./lengthY).^2)./lengthY)./cosh(x(idx2)./lengthY).^3 - (3.*sinh(x(idx2)./lengthY).*(cosh(x(idx2)./lengthY).*(u + u.*epsilon(3).*cos(k(3).*x(idx1)).*sinh(x(idx2)./lengthY)) + 2.*u.*real(epsilon(1).*f1(t).*exp(k(1).*x(idx1).*1i)).*sinh(x(idx2)./lengthY) + 2.*u.*real(epsilon(2).*f2(t).*exp(k(2).*x(idx1).*1i)).*sinh(x(idx2)./lengthY)))./(lengthY.*cosh(x(idx2)./lengthY).^4);
    dvx = - (lengthY.*u.*(real(epsilon(1).*f1(t).*k(1).^2.*exp(k(1).*x(idx1).*1i)) + real(epsilon(2).*f2(t).*k(2).^2.*exp(k(2).*x(idx1).*1i))))./cosh(x(idx2)./lengthY).^2 - (lengthY.*u.*epsilon(3).*k(3).^2.*cos(k(3).*x(idx1)))./cosh(x(idx2)./lengthY);
    dvy = (2.*u.*sinh(x(idx2)./lengthY).*(imag(epsilon(1).*f1(t).*k(1).*exp(k(1).*x(idx1).*1i)) + imag(epsilon(2).*f2(t).*k(2).*exp(k(2).*x(idx1).*1i))))./cosh(x(idx2)./lengthY).^3 + (u.*epsilon(3).*k(3).*sin(k(3).*x(idx1)).*sinh(x(idx2)./lengthY))./cosh(x(idx2)./lengthY).^2;
    
    % Perform matrix multiplication manually
    derivative_(idx3) = dux.*x(idx3) + duy.*x(idx5);
    derivative_(idx4) = dux.*x(idx4) + duy.*x(idx6);
    derivative_(idx5) = dvx.*x(idx3) + dvy.*x(idx5);
    derivative_(idx6) = dvx.*x(idx4) + dvy.*x(idx6);
end

% Forced-damped Duffing oscillator used with aperiodic forcing
function dPhi = d_phi(tau,phi)
dPhi(2,1) = nan;

dPhi(1) = phi(2);
dPhi(2) = -.1*phi(2) - phi(1)^3 + 11*cos(tau);
