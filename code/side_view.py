#!/usr/bin/env python

import os
import numpy as np
import argparse
from plantcv import plantcv as pcv
import matplotlib.pyplot as plt

### Parse command-line arguments
def options():
    parser = argparse.ArgumentParser(description="Imaging processing with opencv")
    parser.add_argument("-i", "--image", help="Input image file.", required=True)
    parser.add_argument("-o", "--outdir", help="Output directory for image files.", required=False)
    parser.add_argument("-r", "--result", help="result file.", required=False)
    parser.add_argument("-w", "--writeimg", help="write out images.", default=False, action="store_true")
    parser.add_argument("-D", "--debug",
                        help="can be set to 'print' or None (or 'plot' if in jupyter) prints intermediate images.",
                        default=None)
    args = parser.parse_args()
    return args

### Main workflow
def main():
    # Get options
    args = options()
    pcv.params.debug = args.debug

    # Read image
    img, path, filename = pcv.readimage(args.image)
    pcv.params.debug=args.debug #set debug mode

    # STEP 1: Adjust images
    img1 = pcv.rotate(img=img, rotation_deg=DEGREE, crop=True)

    img1 = pcv.white_balance(img=img1, mode='hist', roi=[WBX, WBY, WBW, WBH])

    # STEP 2: Convert image from RGB colorspace to LAB and HSV colorspace
    v = pcv.rgb2gray_hsv(rgb_img=img1, channel='v')
    a = pcv.rgb2gray_lab(rgb_img=img1, channel='a')


    # STEP 3 Set a binary threshold on the saturation channel image
    # Threshold the a channel image 
    v_thresh = pcv.threshold.binary(gray_img=v, threshold=THRESHOLD1, max_value=np.max(v), 
                                object_type='dark')
    a_thresh = pcv.threshold.binary(gray_img=a, threshold=THRESHOLD2, max_value=np.max(a), 
                                object_type='dark')

    # STEP 4: Join the threshold from two layers of masking
    v_a = pcv.logical_or(bin_img1=v_thresh, bin_img2=a_thresh)

    # STEP 5: Apply image mask based v_a combined channel 
    masked = pcv.apply_mask(img=img1 , mask=v_a, mask_color='white')

    # STEP 6 Identify objects
    # img - RGB or grayscale image data for plotting 
    # mask - Binary mask used for detecting contours 
    id_objects, obj_hierarchy = pcv.find_objects(img=masked, mask=a_thresh)

    # STEP 7: Define region of interest (ROI)
    roi1, roi_hierarchy= pcv.roi.rectangle(img=masked, x=roix, y=roiy, h=roih, w=roiw)

    # STEP 8: Keep objects that overlap with the ROI
    roi_objects, hierarchy3, kept_mask, obj_area = pcv.roi_objects(img=img1, roi_contour=roi1, 
                                                               roi_hierarchy=roi_hierarchy, 
                                                               object_contour=id_objects, 
                                                               obj_hierarchy=obj_hierarchy,
                                                               roi_type='partial')


    # STEP 9 Object combine kept objects
    # Inputs:
    #   img - RGB or grayscale image data for plotting 
    #   contours - Contour list 
    #   hierarchy - Contour hierarchy array 
    obj, mask = pcv.object_composition(img=img1, contours=roi_objects, hierarchy=hierarchy3)
                          
    img_copy = np.copy(img1)

    # Filter objects by ROI 
    roi = roi1
    hierarchy = roi_hierarchy

    filtered_contours, filtered_hierarchy, filtered_mask, filtered_area = pcv.roi_objects(
            img=img_copy, roi_type="partial", roi_contour=roi,roi_hierarchy = hierarchy,object_contour=roi_objects, 
            obj_hierarchy=hierarchy3)

    # Combine objects together in each plant     
    plant_contour, plant_mask = pcv.object_composition(img=img_copy, contours=filtered_contours, hierarchy=filtered_hierarchy)        

    # Analyze the shape of each plant 
    analysis_images = pcv.analyze_object(img=img_copy, obj=plant_contour, mask=plant_mask)

     # Save the image with shape characteristics 
    img_copy = analysis_images
    pcv.outputs.add_observation(variable = 'roi', trait = 'roi', method = 'roi', scale = 'int', datatype = int, value= filename, label = '#')

    # Print out a text file with shape data for each plant in the image 
    pcv.print_results(filename = args.result + '.txt')

    # Clear the measurements stored globally into the Ouptuts class
    pcv.outputs.clear()

    if args.writeimg:
        outfile = os.path.join(args.outdir, filename + ".png")
        pcv.print_image(img=img_copy, filename=outfile)
        
        
if __name__ == '__main__':
    main()