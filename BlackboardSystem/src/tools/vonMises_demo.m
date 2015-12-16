% This script shows some examples of how to work with mixtures of von Mises
% (mvM) distributions. mvM distributions are especially useful when dealing
% with circular data that is distributed on the unit circle. For detailed
% information on these type of probability distribution, please refer to
% e.g. [1] or [2].
%
% LITERATURE:
%   [1] J. Bentley (2006): "Modelling Circular Data using a Mixture of von
%       Mises and Uniform Distributions"
%   [2] I.S. Dhillon, S. Sra (2003): "Modeling Data using Directional
%       Distributions"
%
% DEPENDS ON:
%   VonMisesMixture.m, fitmvmdist.m, histnorm.m (available at
%   MatlabCentral)
%
% AUTHORS:
%   Christopher Schymura (christopher.schymura@rub.de)
%   Cognitive Signal Processing Group
%   Ruhr-Universitaet Bochum
%   Universitaetsstr. 150, 44801 Bochum

% Initialize plot
figure(1)

%% Initialize a mvM distribution with custom parameters

% Distribution parameters for a mvM distribution with 3 mixture components
componentProportion = [0.4; 0.3; 0.3];  % Proportion of the mixture 
                                        % components. Must always sum to 
                                        % one.
mu = [-pi/2; 0; pi];                    % Mean angle for each mixture 
                                        % component. As mvM distibutions 
                                        % are restircted to model circular
                                        % data, the components of mu are
                                        % wihtin the range of -pi to pi.
kappa = [4; 6; 5];                      % The concentration parameters. 
                                        % These parameters can be
                                        % interpreted as the "inverse
                                        % variance" of each component.
                                        
% Create an instance of the mvM distribution
mvmDist = VonMisesMixture(componentProportion, mu, kappa);

%% Sample from a given distribution and plot the PDF

% Generate samples from the above distribution
nSamples = 5000;
samples = mvmDist.random(nSamples);

% Draw a histogram of the sampled data
histnorm(samples, 100); hold on;

% Generate an "angular axis" with 2000 data points
aAxis = linspace(-pi, pi, 2000)';

% Compute the likelihoods of the distribution for all data points
lik = mvmDist.pdf(aAxis);

% Plot the probability density function
plot(aAxis, lik, 'r', 'LineWidth', 2); hold on;

%% Estimate the distribution parameters

% Estimate the parameters for the set of generated samples
nComponents = 3;
mvmEstimated = fitmvmdist(samples, nComponents, 'MaxIter', 300);

% Plot the PDF of the estimated distribution
likEstimated = mvmEstimated.pdf(aAxis);
plot(aAxis, likEstimated, 'g', 'LineWidth', 2);

%% Plot parameters

title('DEMO: Mixture of von Mises distributions');
xlabel('Angle [rad]');
ylabel('Normalized count / Probability');
legend('Sample histogram', 'True PDF', 'Estimated PDF');
grid on;
axis([-pi, pi, 0, 1]);