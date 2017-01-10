% dobirth.m : This script performs a birth operation. It has
% considerable flexibility in the way it does this, along with a few
% tweakables, but here the operation is to split the
% *responsibilities* of the parent component.

% Please email m.beal@gatsby.ucl.ac.uk for more information.

s = size(Lm,2);
n = size(Y,2);

s = s+1;
t = s; % t is the identity of the newborn.

hardness = 1; % 1 means hard, 0.5 means soft, 0 is equiv to 1 (opposite direction)

fprintf('\nCreating comp:%2i, as hybrid of comp:%2i.',t,parent);

% Sample from the full covariance ellipsoid of the component
Lm{t} = Lm{parent};
delta_vector = mvnrnd(zeros(1,p),Lm{t}(:,2:end)*Lm{t}(:,2:end)'+diag(1./psii),1)';

% Qns birth
assign = sign( delta_vector'*(Y-repmat(Lm{parent}(:,1),1,n)) ); % size 1 x n
pos_ind = find(assign == 1);
neg_ind = find(assign == -1);
% Reassign those one side of vector to the child, t,
% whilst the rest remain untouched. Positive are sent to child
Qns(pos_ind',t) = hardness*Qns(pos_ind',parent);
Qns(pos_ind',parent) = (1-hardness)*Qns(pos_ind',parent);
Qns(neg_ind',t) = (1-hardness)*Qns(neg_ind',parent);
Qns(neg_ind',parent) = hardness*Qns(neg_ind',parent);
% set all features of t to those of t_parent
Lcov{t} = Lcov{parent};
Lm{t}(:,1)      = Lm{t}(:,1)      + delta_vector;
Lm{parent}(:,1) = Lm{parent}(:,1) - delta_vector;
b{t} = b{parent};
u(parent) = u(parent)/2; u(t) = u(parent);
pu = alpha/s *ones(1,s);
% Update Q(X)Q(L) posterior
inferQX, inferQL
inferQX, inferQL

allcomps
cophd = 0;

