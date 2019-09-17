function [amended_matrix,num_amend] = amend_pixels(drainarea, mask, fraction_amend)

% Get size of matrix and vector
[ny,nx] = size(drainarea);
matrix_size = [ny,nx];
vector_size = [ny*nx,1];

% Convert matrices to vectors for sorting
amended_vector =zeros(vector_size);
drain_vector = reshape(drainarea, vector_size);
mask_vector = reshape(mask, vector_size);

% Mark pixesl to ignore based on mask
drain_vector(isnan(mask_vector)) = -Inf;

% Convert amended pixels from percent to number
num_possible = length(find(drain_vector ~= -Inf));
num_amend = ceil(fraction_amend*num_possible);

% Sort pixels and mark amended locations
[~, original_indicies] = sort(drain_vector,'descend');
amended_vector(original_indicies(1:num_amend)) = 1;

% Reshape to matrix
amended_matrix = reshape(amended_vector, matrix_size);

end

