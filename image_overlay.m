function image_overlay(image, seg, gt, display_options, output_filename)
% image should be in Row X Column X Slice X Sequence
% seg should be in Row X Column X Slice
% gt  should be in Row X Column X Slice
% display_options include intensity_range, num_slices alpha, and color
% output_filename

close all
clc

if isempty(gt)
    bool_gt = false;
else
    bool_gt = true;
end

if isempty(seg)
    bool_seg = false;
else
    bool_seg = true;
end

if isempty(display_options)
    display_options.intensity_range = [min(image(:)) max(image(:))];
    display_options.num_slices = 10;
    if bool_gt
        num_labels = length(unique(gt))-1;
    else
        num_labels = length(unique(seg))-1;
    end
    display_options.color = jet(num_labels);
    display_options.alpha = 0.5;
end

%% Find Slices with Signal
[num_rows, num_columns, num_slices, num_sequences] = size(image);
begin_slice = 1;
end_slice = num_slices;

if bool_seg
    [begin_slice, end_slice] = find_slice(seg, begin_slice, end_slice);
end
if bool_gt
    [begin_slice, end_slice] = find_slice(gt, begin_slice, end_slice);
end
slice_list = linspace(begin_slice, end_slice, display_options.num_slices);
slice_list = round(slice_list);

if isempty(slice_list)
    slice_list = linspace(1, num_slices, display_options.num_slices);
    slice_list = round(slice_list);
end

%% Extract slice and concatenate
%% Image
image_stack = zeros(num_rows*num_sequences, num_columns*display_options.num_slices);
for i_sequence = 1:num_sequences
    start_row = (i_sequence-1)*num_rows+1;
    end_row = (i_sequence-1)*num_rows+num_rows;
    
    image_slices = image(:,:,slice_list,i_sequence);
    image_slices = reshape(image_slices,num_rows,num_columns*display_options.num_slices);
    image_stack(start_row:end_row,:) = image_slices;
end
mask_stack = zeros(size(image_stack));
repeat = 1;

%% Segmentation
if bool_seg
    mask_stack = stack_mask(mask_stack, seg, slice_list, display_options.num_slices, num_sequences);
    repeat = repeat+1;
end

%% Ground Truth
if bool_gt
    mask_stack = stack_mask(mask_stack, gt, slice_list, display_options.num_slices, num_sequences);
    repeat = repeat+1;
end
image_stack = repmat(image_stack, repeat, 1);
mask_stack = uint8(mask_stack);
%% Display
RGBMask = ind2rgb(mask_stack, display_options.color);
imshow(image_stack, display_options.intensity_range)
hold on
h = imshow(RGBMask);
hold off
set(h, 'AlphaData', (mask_stack > 0)*display_options.alpha)

print(output_filename, '-dpng', '-r300')
close all


function mask_stack = stack_mask(mask_stack, seg, slice_list, num_slices, num_sequences)
[num_rows, num_columns, ~] = size(seg);
seg_slices = seg(:,:,slice_list);
seg_slices = reshape(seg_slices,num_rows,num_columns*num_slices);
seg_slices = repmat(seg_slices, num_sequences, 1);
mask_stack = [mask_stack; seg_slices];

function [begin_slice, end_slice] = find_slice(seg, begin_slice, end_slice)
bool_signal = any(seg > 0, [1 2]);
bool_signal = squeeze(bool_signal);
seg_begin_slice = find(bool_signal, 1, 'first');
seg_end_slice = find(bool_signal, 1, 'last');
begin_slice = max(begin_slice, seg_begin_slice);
end_slice = min(end_slice, seg_end_slice);