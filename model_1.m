function [ P ] = model_1( x, mu, v )
%model_1 calculates value of model for given feature vector
%   Author: Saeid.S.Nobakht

Probs = (1./sqrt(2*pi*v)).*exp(-((x-mu).^2)./(2*v));
P = prod(Probs);


end

