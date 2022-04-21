function [ B ] = get_max_k( A, k, col )
%get_max_k returns k largest values of input matrix
%   Author: Saeid.S.Nobakht

sorted_A = sortrows(A, col,'descend');
B = sorted_A(1:k,:);
%[V , R, C ] = ind2sub(size(A),Ind(1:k)); % fetch indices

end

