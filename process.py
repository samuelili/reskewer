import numpy as np
import math
from PIL import Image
import cv2 as cv
from scipy.signal import convolve2d
from skimage.transform import hough_line, hough_line_peaks
import itertools
from datetime import datetime

# Gaussian function
def gaussian(x, y, sigma):
  coeff = 1 / (2 * np.pi * (sigma ** 2))
  exp = -1 * ((x**2 + y**2) / (2 * (sigma ** 2)))

  return coeff * np.exp(exp)

def gaussian_filter(sigma):
  kernel_size = 2 * int(sigma * 4 + 0.5) + 1
  filter = np.zeros((kernel_size, kernel_size))

  # Get center from shape
  rows, cols = filter.shape
  x, y = filter.shape
  x //= 2 # center
  y //= 2 # center

  # iterate through matrix and reassign values
  for i in range(0, rows):
    for j in range(0, cols):
      filter[i][j] = gaussian(x - i, y - j, sigma)

  # make sure they sum up to 1
  filter = filter / (np.sum(filter))

  return filter

def preprocess(im):
  preprocessed = np.copy(im)

  # increase contrast
  # preprocessed = 0.5 * np.tanh(6 * preprocessed - 3) + 0.5

  # increase brightness
  # preprocessed = np.maximum(preprocessed + 190, 255)

  # magnitude
  gx_filter = np.array([[-1, 0, 1], [-4, 0, 4], [-1, 0, 1]])
  gy_filter = np.array([[-1, -2, -1], [-4, 0, 4], [1, 2, 1]])

  mag_image = np.sqrt(convolve2d(preprocessed, gx_filter)**2 + convolve2d(preprocessed, gy_filter)**2)

  for y in range(mag_image.shape[0]):
    for x in range(mag_image.shape[1]):
      if mag_image[y][x] < 0.3:
        mag_image[y][x] = 0
      else:
        mag_image[y][x] = 1

  # for y in range(preprocessed.shape[0]):
  #   for x in range(preprocessed.shape[1]):
  #     if mag_image[y][x] == 1:
  #       preprocessed[y][x] = 0.5 * np.tanh(6 * preprocessed[y][x] - 3) + 0.5

  preprocessed = mag_image

  return preprocessed

# canny
def find_canny_edges(im):
  edges = cv.Canny(np.uint8(im * 255), 100,200)
  edges = np.float64(edges / 255)

  return edges


def normalize(im):
  # convert to grayscale
  # grayscale = np.zeros(im.shape[:2])
  r, g, b = im[:,:,0], im[:,:,1], im[:,:,2]
  grayscale = 0.2989 * r + 0.5870 * g + 0.1140 * b

  # gaussian blur
  # kernel = gaussian_filter(2)
  # blurred = convolve2d(grayscale, kernel)

  # subsample
  subsampled = np.zeros((768, 1024))
  x_stride, y_stride = grayscale.shape[1] / 1024, grayscale.shape[0] / 768

  for y in range(768):
    for x in range(1024):
      subsampled[y, x] = grayscale[math.floor(y * y_stride), math.floor(x * x_stride)]

  return subsampled / 255

def find_lines(im):
  # Classic straight-line Hough transform
  # Set a precision of 0.5 degree.
  tested_angles = np.linspace(-np.pi / 2, np.pi / 2, 360, endpoint=False)
  h, theta, d = hough_line(im, theta=tested_angles)
  
  #get lines
  hough_lines = []
  for _, angle, dist in zip(*hough_line_peaks(h, theta, d)):
      (x0, y0) = dist * np.array([np.cos(angle), np.sin(angle)])
      slope=np.tan(angle + np.pi / 2)
      intercept = y0 - slope * x0
      hough_lines.append((slope, intercept))
  
  return hough_lines

def getIntersection(line1, line2):
  L1_slope, L1_y_inter = line1[0], line1[1]
  L2_slope, L2_y_inter = line2[0], line2[1]

  if L1_slope == L2_slope:
      return(None, None)

  x_inter = (L2_y_inter-L1_y_inter)/(L1_slope-L2_slope)
  y_inter = L1_slope * x_inter + L1_y_inter #arbitrarily using line1

  return x_inter, y_inter

def checkForIntersection(line1, line2):
  x_inter, y_inter = getIntersection(line1, line2)
  #check if intersection falls within image range
  if (x_inter, y_inter) == (None, None): # parallel lines
      return (None, None)
  elif x_inter > 1024 or x_inter < 0 or y_inter > 768 or y_inter < 0: # out of bounds
      return (None, None)
  return(x_inter, y_inter)

def findIntersections(lines, intersections):
  for line1, line2 in itertools.combinations(lines,2): #non duplicated pairs
    x_inter, y_inter = checkForIntersection(line1, line2)
    #print(x_inter, y_inter)
    if (x_inter, y_inter) == (None, None):
      continue
    #categorize into quadrants: 0 is upper left, 1 is lower left, 2 is upper right, 3 is lower right
    if x_inter < 512 and y_inter < 384:
      intersections[0].append((x_inter, y_inter, line1, line2))
    elif x_inter < 1024/2 and y_inter > 384:
      intersections[1].append((x_inter, y_inter, line1, line2))
    elif x_inter > 1024/2 and y_inter < 384:
      intersections[2].append((x_inter, y_inter, line1, line2))
    elif x_inter > 1024/2 and y_inter > 384:
      intersections[3].append((x_inter, y_inter, line1, line2))

def find_best_lines(im, intersections):
  #calculate shortest distance from center to the intersection points in each of the quadrants
  centerPt = np.array([im.shape[1]//2, im.shape[0]//2])
  originPt = np.array([0,0])
  bestLines = []
  for quadrant in intersections:
    smallestDistance = np.linalg.norm(originPt-centerPt)
    bestIntersection = (0,0) #dummy values
    for intersection in quadrant:
      x_inter, y_inter, line1, line2 = intersection
      intersectionPt = np.array([x_inter, y_inter])
      distance = np.linalg.norm(intersectionPt-centerPt)
      if distance < smallestDistance:
        smallestDistance = distance
        bestIntersection = (line1, line2)
    bestLines.append(bestIntersection[0])
    bestLines.append(bestIntersection[1])
  bestLines = list(set(bestLines)) #only keep unique 4
  print("final selected set of 4 lines")
  print(bestLines)
  
  return bestLines

def find_homography(lines):
  finalIntersectionPts = []
  for line1, line2 in itertools.combinations(lines,2):
      x_inter, y_inter = getIntersection(line1, line2)
      if x_inter > 1024 or x_inter < 0 or y_inter > 768 or y_inter < 0: #remove out of bounds intersections
          continue
      finalIntersectionPts.append((x_inter,y_inter))
  finalIntersectionPts = list(set(finalIntersectionPts))
  print("4 Corner Points for Homography")
  print(finalIntersectionPts)
  
  src = np.array(finalIntersectionPts, dtype=np.float32)
  dest = np.array([[1024, 768],[0, 0], [1024, 0], [0, 768], ], dtype=np.float32)
  H, _ = cv.findHomography(src, dest)
  
  return H

def transform(im, H):
  warpedImage = np.zeros((768, 1024,3))
  
  for channel in range(3):
      subsampled = np.zeros((768, 1024))
      x_stride, y_stride = im.shape[1] / 1024, im.shape[0] / 768
      for y in range(768):
          for x in range(1024):
              subsampled[y, x] = im[:,:,channel][math.floor(y * y_stride), math.floor(x * x_stride)]
      destSize = (1024, 768)
      warpedImage[:,:,channel] = cv.warpPerspective(subsampled/255, H, destSize)
  
  return warpedImage

def process(file_path):
  print("Opening Image")
  image = np.asarray(Image.open(file_path))
  
  print("Normalizing Image")
  normalized = normalize(image)
  
  print("Preprocessing Image")
  preprocessed = preprocess(normalized)
  
  print("Finding Edges")
  canny_edges = find_canny_edges(preprocessed)
  
  print("Finding Lines")
  hough_lines = find_lines(canny_edges)
  print(hough_lines)
  
  print("Finding Intersections")
  intersections = [[], [], [], []]
  findIntersections(hough_lines, intersections)
  
  print("Finding Best Lines")
  best_lines = find_best_lines(preprocessed, intersections)
  
  print("Finding Homography")
  H = find_homography(best_lines)
  
  print("Transforming Image")
  warped_image = transform(image, H)
  
  print("Done.")
  return warped_image
  