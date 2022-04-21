function [ P ] = model_2( x, mu, v )
%model_2 calculates value of model for given feature vector
%   Author: Saeid.S.Nobakht
% in here, we use covariance matrix; therefore, we keep correlations
% of features in our considerations.
n = size(v,1);
%P = (1./sqrt(2*pi*v)).*exp(-((x-mu).^2)./(2*v));
P = (1/(((2*pi)^(n/2))*((det(v))^0.5)))*exp(-0.5*(x-mu)*pinv(v)*(x-mu)');
end



