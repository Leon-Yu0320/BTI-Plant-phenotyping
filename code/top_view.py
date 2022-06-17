#!/usr/bin/env python

import os
import numpy as np
import argparse
from plantcv import plantcv as pcv

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
    img1 = pcv.white_balance(img, roi=(white_Xwhite_Ywhite_Wwhite_H))
    img1 = img
    #img1 = pcv.transform.rotate(img=img1, rotation_deg=, crop=False)
    imgs = pcv.shift_img(img=img1, number=shift1, side=dir1)
    img1 = pcv.shift_img(img=imgs, number=shift2, side=dir2)

    # STEP 2: Convert image from RGB colorspace to LAB colorspace
    a = pcv.rgb2gray_lab(rgb_img=img1, channel='a')

    # STEP 3 Set a binary threshold on the saturation channel image
    img_binary = pcv.threshold.binary(gray_img=a, threshold=cut_off, max_value=255, object_type='dark')

    # STEP 4: Find objects (contours: black-white boundaries)
    id_objects, obj_hierarchy = pcv.find_objects(img=img1, mask= img_binary)

    # STEP 5: Define region of interest (ROI)
    roi_contour, roi_hierarchy = pcv.roi.rectangle(img=img1, ROIxROIyROIwROIh)

    # STEP 11: Keep objects that overlap with the ROI
    roi_objects, roi_obj_hierarchy, kept_mask, obj_area = pcv.roi_objects(img=img1, roi_contour=roi_contour, 
                                                                      roi_hierarchy=roi_hierarchy,
                                                                      object_contour=id_objects, 
                                                                      obj_hierarchy=obj_hierarchy, 
                                                                      roi_type='partial')


    rois1, roi_hierarchy1 = pcv.roi.multi(img=img1, coord=(plantx, planty), radius=VALUE, spacing=(475, 475), nrows=4, ncols=4)
                          
    img_copy = np.copy(img1)
    for i in range(0, len(rois1)):
        roi = rois1[i]
        hierarchy = roi_hierarchy1[i]
        # Filter objects by ROI 
        filtered_contours, filtered_hierarchy, filtered_mask, filtered_area = pcv.roi_objects(img=img_copy, roi_type="partial", roi_contour=roi, roi_hierarchy=hierarchy, object_contour=roi_objects, obj_hierarchy=roi_obj_hierarchy)

        # Combine objects together in each plant     
        plant_contour, plant_mask = pcv.object_composition(img=img_copy, contours=filtered_contours, hierarchy=filtered_hierarchy)         
        
        #Build a new array to distinguish missing plants
        test = np.array(plant_contour)
        
         # Analyze the shape of each existing plant:
        if test.dtype == 'int32':
            analysis_images = pcv.analyze_object(img=img_copy, obj=plant_contour, mask=plant_mask)
            
            # Save the image with shape characteristics 
            test2 = np.array(analysis_images)
            if test2.dtype == 'uint8':
                img_copy = analysis_images
                
                pcv.outputs.add_observation(sample ='default', variable = 'plantID', trait='ID',
                            method='none', scale='none',datatype = str, value= filename[:-4] + "_" + str(i), label = '#')

                # Print out a text file with shape data for each plant in the image 
                pcv.outputs.save_results(filename = args.result + str(i) + '.txt')
                # Clear the measurements stored globally into the Ouptuts class
                pcv.outputs.clear()  


    if args.writeimg:
        outfile = os.path.join(args.outdir, filename[:-4] + ".png")
        pcv.print_image(img=img_copy, filename=outfile)
        
        
if __name__ == '__main__':
    main()