#!/usr/bin/python

import sys
import os
import subprocess
import math
import yaml
import cv2
import random
from tqdm import tqdm
import operator
from pdf2image import convert_from_path

# COMMANDS
ONLYENCO = False
ONLYCONT = False
SHOWENCO = False
SHOWCONT = False
DOFRAMES = True
SHOWFRAMES = False # Show canvas (full frame with assembled graphs)
DOVIDEO = True # Warning: set DOFRAMES and TOPNG to True

PRINTPDFLATEXOUT = False

# Meta parameters
SEED = 0
RANDOM_POS_MAG = 15
MAX_FRAME = None # None implies finding max_frame
DIR_PATH = os.path.dirname(os.path.realpath(__file__))
HOME_DIR = os.path.expanduser("~")
ICGPRES_DIR = HOME_DIR #+ "/Documents/git/ICGP-results"
IMG_EXT = ".png"
TOPNG = True # convert pdf canvas to png TODO video:True screen:True
DELETE_GRAPHS_PDF = True # TODO video:True screen:False
DELETE_CANVAS_PDF = True # TODO video:True screen:True
FPSS = [60,15] # TODO video:60

# Graph layout
PRINTBUFFER = True # set to False for easy positioning
GRAPHBACK = True
BUFFERCLIP = True
IMG_WIDTH = 1.5
IMGOUT_WIDTH = 1.0
WH_RATIO = 0.76
THICKNESS_ACTIVE = "thick"
THICKNESS_INACTIVE = "thick"
COLOR_ACTIVE = "red" # TODO video:red screen:black
COLOR_INACTIVE = "black" # TODO video:"black" screen:"black"
COLOR_INACTIVE_EDGE = "black!50" # TODO video:"black!50" screen:"black"
COLOR_BACKGROUND = "white"
HALOEDGELABELS = False
BACKGROUNDEDGELABELS = True
ENABLE_MANUAL_POS = True
LABEL_EDGES = False
FONT_FAMILY = "sf" # rm:serif sf:sans-serif tt:mono-space

# Macros
T="thick,"
UT="thick,"

"""
Exp 1:
Simple:
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-01T17:44:01.968_boxing
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-03T18:18:35.090_freeway

Simple + acceleration:
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-23T18:31:09.813_asteroids

Complex with an interesting double dilatation:
/home/opaweynch/Documents/git/ICGP-results/results/2021-10-01T18:23:26.293_space_invaders

Complex:
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-23T18:31:09.829_breakout
/home/opaweynch/Documents/git/ICGP-results/results/2021-10-01T18:22:33.340_riverraid
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-07T17:17:40.579_gravitar
"""

"""
Instructions on positioning:

Position by nodename prevails on position "by type", which prevails on random positioning (default).
	nodename > type > random

Position "by type" apply to either all inputs or all outputs. Here are examples:
	{"type": "singlenode", "pos": (0, 0)}
	{"type": "column", "pos": (10, 0), "span": 1}
	{"type": "squares", "pos": (0, 0)} # Only valid for controller input
"""
POS = {
	"2022-02-23T18:11:39.288_1_bowling" : { # Super simple encoder: erode + motion + motion. Controller makes some weird strategy where it sort of pushes the ball towards the bottom constantly unless it reaches the middle/end of the bowling alley where it pushes the ball towards the top. No cst actions use.
		"encoder": {
			"1": (0,0), "7": (2.3,0), "17": (5.5,0), "19": (9.5,0), "out19": (12.3,0),
			"names": {"7": "E1", "17": "E2", "19": "E3"},
			"backgroundnode": {"pos": (-1, 0.2), "width": (1.8, 10.2, 1.4), "height": 2.7}
		},
		"controller": {
			"50": (4.1, 2.1), "75": (4.1, 0.6), "82": (7, 1.5),
			"65": (4.1, 4),
			"73": (6, -2),
			"52": (6, -0.5),
			"names": {"65": "C1", "75": "C3", "50": "C2", "82": "C4", "52": "C5", "73": "C6"},
			"loopopt": {(65,65): "loop right"},
			'''"customndopt": { # last custom opt
				"thick, draw=black": ["20"],
				"thick, draw=orange": ["5", "out5"],
				"thick, draw=red": ["8", "22", "24", "75", "50", "82", "out82"],
				"thick, draw=teal": ["11", "20", "52", "out52"],
				"thick, draw=purple": ["3", "out3"],
				"thick, draw=yellow!50!orange": ["18", "73", "out73"],
				"thick, draw=cyan": ["9", "65", "out65"]
			},'''
			"customedgeopt": { # last custom opt
				"thick, color=orange": [(5,"out5")],
				"thick, color=red": [(22,75), (24,50), (20,75), (8,50), (75,82), (50,82), (82,"out82")],
				"thick, color=teal": [(11,52), (20,52), (52,"out52")],
				"thick, color=purple": [(3,"out3")],
				"thick, color=yellow!50!orange": [(18,73),(73,"out73")],
				"thick, color=cyan": [(9,65),(65,65),(65,"out65")]
			},
			"avoided": ["1", "2", "4", "6", "7", "10", "12", "13", "14", "15", "16", "17", "19", "21", "23", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35"],
			"inputs": {"type": "squares", "showcoord": True, "origin": (0, 0), "innerspan": 1, "squarespan": 7,
				"cst_in": True, "cst_input_y": -5},
			"customedges": {
				(5, "out5"): "bend left=22",
				(3, "out3"): "bend left=6",
				(22, 75): "out=-90, in=-90, looseness=0.9",
				(20, 75): "out=90, in=-90",
				(8, 50): "out=-45, in=180, looseness=1.3",
				(24, 50): "out=90, in=180, looseness=0.9",
				(50,82): "out=0, in=180",
				(75,82): "out=0, in=180",
				(9, 65): "out=90, in=180", (65, "out65"): "bend right=15",
				(11, 52): "bend right=5",
				(18, 73): "bend right=5"
			},
			"outputs": {"type": "column", "pos": (10, -0.5), "span": 1},
			"sticky": (10, 3.3),
			"backgroundnode": {"pos": (-2.9, 0.8), "width": (5.3, 5.9, 2.1), "height": 7.6}
		},
		"canvas": {
			"rgbpos": (0, 0.29), "hrgbpos": (0, 0.63), "scorepos": (0.52, 0.58),
			"epos": (0, 0), "hepos": (0, 0.22),
			"cpos": (1.01, 0), "hcpos": (1.01, 0.63),
			"scoresc":0.1, "rgbsc":0.5, "esc":1.0, "csc":1.1,
			"hrgbsc":0.1, "hesc":0.1, "hcsc":0.1,
			"ctrim":"0cm 1.08cm 0cm 0cm",
			"background": {"color":"white","sw":(0,0),"ne":(2.11,0.67), "hsep":0.2, "vsep":0.01}
		}
	},
	"2022-02-23T18:11:39.277_2_bowling" : { # Complexe encoder with 12 intermediate nodes. Its output seems to be a dilated motion capture version of the original input. Controller is a bit simpler and suggests a tendency to alternate between moving the ball towards the top or the bottom.
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7,
				"cst_in": True, "cst_input_y": -5},
			"outputs": {"type": "column", "pos": (20, 0), "span": 1}
		}
	},
	"2022-02-23T18:11:39.278_3_bowling" : { # Average complex encoder with 7 intermediate nodes. The output of the encoder seems hard to interprete as the ultimate operation is an AND between two non-binary images. The controller seems also hard to understand, there seems to be a persistent control towards the bottom at the begining and I am not sure about the mechanism that brings the ball upwards. Things get tricky as the encoder output are hard to understand.
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7,
				"cst_in": True, "cst_input_y": -5},
			"outputs": {"type": "column", "pos": (20, 0), "span": 1}
		}
	},
	"2022-02-08T15:19:07.129_1_boxing" : { # Simple encoder alternating between positive and negative view of the opponent. Controller simply runs towards the top right corner and hits when one of the two regions where the boxers are supposed to be is bright.
		"encoder": {
			"1": (0,0), "2": (2.4,-1.1), "5": (2.4,1.1), "6": (4.6,0), "9": (6.9,0), "out9": (4.6,0),
			"names": {"5": "E1", "2": "E2"},
			"avoided": ["6", "9"],
			"extra_edges": [("5", "out9")],
			"backgroundnode": {"pos": (-1, 0), "width": (1.8, 2.5, 1.4), "height": 4.2}
		},
		"controller": {
			"35": (2,8.5),
			"34": (2,3.5), "45": (5,4), "57": (8,4), "86": (11,4),
			"32": (2,7),
			"27": (2,-6.5),
			"30": (2,-5),
			"26": (2,-7.5),
			"46": (8,2.75), "77": (11,2.75),
			"48": (7,1.5),
			"47": (11,0.5),
			"38": (11,-4), "37": (8,-4),
			"94": (10,-1),
			"68": (5,-2),
			"36": (5,-3.5), "55": (8,-4), "76": (11,-4),
			"29": (2,-5), "69": (4.5,-5),
			"out35": (14,9),
			"out41": (14,8),
			"out32": (14,7),
			"out4": (14,6),
			"out5": (14,5),
			"out86": (14,4),
			"out77": (14,3),
			"out48": (14,2),
			"out47": (14,1),
			"out47'": (14,0),
			"out94": (14,-1),
			"out68": (14,-2),
			"out23": (14,-3),
			"out76": (14,-4),
			"out69": (14,-5),
			"out27": (14,-6),
			"out38": (14,-7),
			"out81": (14,-8),
			"names": {"46": "C4", "77": "C5", "48": "C6", "45": "C1", "57": "C2", "86": "C3", "69": "C13", "47": "C7", "68": "C9", "37": "C10", "38": "C11", "36": "C10", "55": "C11", "76": "C12", "94": "C8"},
			"sticky": (14, 9.6),
			'''"customndopt": { # last custom opt
				UT+"draw=orange": [
					"9", "46", "77", "out77"
				],
				UT+"draw=yellow!50!orange": [
					"15", "68", "out68"
				],
				UT+"draw=teal": ["10", "21", "45", "57", "86", "out86"],
				UT+"draw=purple": [
					"2", "20", "94", "out94",
					"7", "6", "55", "76", "out76"
				],
				UT+"text=black, draw=lightgray": [
					"4", "out4",
					"32", "out32",
					"23", "out23",
					"27", "out27",
					"5", "out5",
					"26", "out81",
					"out38",
					"35", "out35", "out41",
					"25", "30", "37", "38"
				],
				UT+"draw=cyan": [
					"8", "18", "47", "out47", "out47'",
					"29", "17", "69", "out69"
				],
				UT+"draw=red": [
					"13", "48", "out48"
				],
				UT+"draw=black": ["34", "36", "14", "16"],
			},'''
			"customedgeopt": { # last custom opt
				UT+"color=orange": [
					(9,46), (36,77), (34,46), (46,77), (77,"out77")
				],
				UT+"color=teal": [(10,57), (21,86), (34,45), (45,57), (57,86), (86,"out86")],
				UT+"color=black!50!white": [
				],
				UT+"color=yellow!50!orange": [
					(15,68),(36,68),(68,"out68")
				],
				UT+"color=purple": [
					(20,94), (94,"out94"), (2,94),
					(7,55),(6,76),(36,55),(55,76),(76,"out76")
				],
				UT+"color=lightgray": [
					(4, "out4"),
					(32,"out32"),
					(27,"out27"),
					(23,"out23"),
					(5,"out5"),
					(26,"out81"),
					(26, "out38"),
					(35,"out35"), (35,"out41")
				],
				UT+"color=cyan": [
					(8,47),(18,47),(47,"out47"),(47,"out47'"),
					(29,69), (17,69), (69,"out69")
				],
				UT+"color=red": [
					(13,48), (14,48), (48,"out48")
				],
				UT+"color=black": [(14,36),(16,36)],
			},
			"customedges": {
				(4,"out4"): "out=120, in=180, looseness=1.2",
				(5,"out5"): "out=120, in=180, looseness=1.2",
				(21,86): "out=135, in=160, looseness=1.1",
				(10,57): "out=0, in=180",
				(34,45): "out=0, in=180",
				(34,46): "out=0, in=180",
				(77,"out77"): "out=0, in=180",
				(9,46): "out=25, in=180",
				(13,48): "out=25, in=180, looseness=0.3",
				(14,48): "out=25, in=180, looseness=0.5",
				(8,47): "out=-30, in=180, looseness=0.3",
				(18,47): "out=20, in=180, looseness=0.7",
				(2,94): "out=-8, in=180, looseness=1.5",
				(47,"out47"): "out=0, in=180",
				(47,"out47'"): "out=0, in=180",
				(16,36): "bend right=5",
				(6,76): "out=-150, in=-140, looseness=1.3",
				(7,55): "out=-150, in=-140, looseness=1.5",
				(17,69): "out=-90, in=180, looseness=0.7",
				(14,36): "out=-90, in=180",
				(16,36): "out=-45, in=180",
				(36,55): "out=0, in=180",
				(36,77): "out=0, in=180, looseness=0.5",
				(23,"out23"): "out=-20, in=180, looseness=0.5",
				(15,68): "out=0, in=180"
			},
			#"customedgesanchors": {("2", "94"): ("west", "west")},
			"inputs": {"type": "squares", "showcoord": True, "origin": (0, 0), "innerspan": 1, "squarespan": 7,
				"cst_in": True, "cst_input_y": -5},
			"avoided": [
				"25", "30", "37", "38",
				"41", "42", "81",
				"1", "3", "11", "12", "19", "22", "24",
				"28", "31", "33"
			],
			"extra_edges": [(13,48), ("26","out81"), ("35","out41"), ("26", "out38")],
			"outputs": {"type": "column", "pos": (14, 0), "span": 1},
			"backgroundnode": {"pos": (-2.9, 1.05), "width": (5.4, 9.7, 2.2), "height": 18.8}
		},
		"canvas": {
			"hrgbpos": (0, 1.5), "rgbpos": (0, 1.16), "scorepos": (0, 1.12),
			"hepos": (0, 0.36), "epos": (0, 0),
			"cpos": (0.6, 0), "hcpos": (0.69, 1.5),
			"scoresc":0.1, "rgbsc":0.5, "esc":0.5, "csc":1.5,
			"hrgbsc":0.1, "hesc":0.1, "hcsc":0.1,
			"ctrim":"4.5cm 0.575cm 0cm 0cm",
			"background": {"color":"white","sw":(0,0),"ne":(2.1,1.54), "hsep":0.01, "vsep":0.1}
		}
	},
	"2022-02-08T15:19:07.234_2_boxing" : { # Complex encoder with many logical operators
		"encoder": {
			"1": (0,0), "2": (4,2), "3": (4,0),
			"5": (8,2), "14": (4,-2), "12": (4,-4),
			"17": (8,-2), "13": (8,0), "out17": (12,0),
			"customedges": {(1, 2): {1: "bend left=20", 2: "bend right=20"}},
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7,
				"cst_in": True, "cst_input_y": -5},
			"outputs": {"type": "column", "pos": (20, 0), "span": 1}
		}
	},
	"2022-02-08T15:19:07.173_3_boxing" : { # Simple encoder alternating between positive and negative view of the opponent. Interesting rythm that is found by playing with this alternating scheme. Same strategy going up and hitting most of the time.
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7,
				"cst_in": True, "cst_input_y": -5},
			"outputs": {"type": "column", "pos": (20, 0), "span": 1}
		}
	},
	"2021-10-01T18:22:33.340_riverraid" : {
		"encoder": {
			"1": (0,0),
			"6": (4,0),
			"2": (2,-2), "5": (4,-2), "out5": (10,-2),
			"7": (2,3), "11": (4,3), "3": (2,1.5), "8": (4,1.5), "15": (6,3), "10": (6,0),
			"17": (8,1.5), "out17": (10,1.5),
			"backgroundnode": {"pos": (-1, 0.5), "width": (1.7, 7.9, 1.5), "height": 7},
			"customedges": {(2, 5): "bend right=45", (1, 7): "bend left=20", (8, 15): "bend right=45"},
			"customlabel": {(2, 5): "rotate=-45"},
			"labelsinclination": 45
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"62": (7, 9),
			"73": (8, 7),
			"70": (5, 5), "85": (7, 5),
			"58": (5.3, 4),
			"65": (7.2, 1),
			"52": (6.5,-1),
			"54": (6,-3),
			"53": (7,-7),
			"customedges": {
				(30, "out30"): "bend right=10",
				(39, "out39"): "bend right=25",
				(85, "out85'"): "bend right=10",
				(85, "out85''"): "bend right=12",
				(43, "out43"): "bend left=12",
				(12, 70): "bend left=10",
				(15, 62): "bend left=10", (28, 62): "bend left=2",
				(26, 65): "bend left=10",
				(33, 85): "bend right=5",
				(8, "out8"): "bend right=25",
				(65, "out65'"): "out=south east, in=west",
				(10, "out10"): "out=south, in=west",
				(4, "out4"): "out=east, in=west"
			},
			"customlabel": {
				(2, 73): "pos=0.85",
				(13, 58): "pos=0.9", (19, 58): "pos=0.7",
				(12, 70): "pos=0.87",
				(70, 85): "pos=0.5",
				(26, 65): "pos=0.67",
				(22, 52): "pos=0.8", (37, 52): "pos=0.8",
				(28, 54): "pos=0.9", (48, 54): "pos=0.6",
				(18, 53): "pos=0.9"
			},
			"backgroundnode": {"pos": (-2.8, 1), "width": (5.2, 5.9, 2.1), "height": 19},
			"sticky": (10, 9.6),
			"labelsinclination": 45
		},
		"canvas": {
			"rgbpos": (0.03, 0.5), "hrgbpos": (0.1, 1.12), "scorepos": (0.1, 0.52),
			"epos": (0, -0.35), "hepos": (0.1, 0.41),
			"cpos": (1.1, -0.4), "hcpos": (1.2, 1.13)
		}
	},
	"2021-09-03T18:18:35.090_freeway" : {
		"encoder": {
			"1": (0,0),
			"2": (2,0),
			"8": (4,1), "11": (6,1), "out11": (8,1),
			"17": (4,-1), "out17": (8,-1),
			"backgroundnode": {"pos": (-1, 0), "width": (1.7, 6, 1.5), "height": 4},
			"customedges": {(2, 11): "bend right=20"},
			"labelsinclination": 45
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"68": (5,-0.5), "79": (7,-0.5),
			"sticky": (10, 2),
			"backgroundnode": {"pos": (-2.7, 0), "width": (5.2, 5.8, 2.1), "height": 13},
			"labelsinclination": 45
		},
		"canvas": {
			"rgbpos": (0.03, 0.5), "hrgbpos": (0.1, 1.12), "scorepos": (0.1, 0.52),
			"epos": (0, -0.15), "hepos": (0.1, 0.41),
			"cpos": (1.1, -0.05), "hcpos": (1.2, 1.13)
		}
	},
	"2021-10-01T18:23:26.293_space_invaders": {
		"encoder": {
			"1": (0,0),
			"3": (4, -1), "out3": (12, -1),
			"5": (2, 1), "6": (4, 1), "12": (6, 1), "17": (8, 1), "20": (10, 1),
			"out20": (12, 1),
			"backgroundnode": {"pos": (-1, 0.4), "width": (1.7, 9.8, 1.5), "height": 4},
			"customedges": {(1, 5): {1: "bend left=90", 2: "bend left=50"}},
			"labelsinclination": 45
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"63": (4, -3), "70": (6, -3), "85": (8, -3),
			"76": (4, 2), "83": (6, 2), "73": (6, 0), "89": (8, 1),
			"80": (6, 3),
			"customedges": {(10, 85): "bend right=20", (85, "out85"): "bend left=30", (28, "out28"): "bend left=4"},
			"customlabel": {(33, 73): "pos=0.9", (19, 73): "pos=0.9", (27, 83): "pos=0.9", (42, 63): "pos=0.9", (2, 63): "pos=0.9", (63, 70): "pos=0.5", (70, 85): "pos=0.5"},
			"sticky": (10, 3.7),
			"backgroundnode": {"pos": (-2.7, 0), "width": (5.2, 5.8, 2.1), "height": 13}
		},
		"canvas": {
			"rgbpos": (0.03, 0.5), "hrgbpos": (0.1, 1.12), "scorepos": (0.1, 0.52),
			"epos": (0, -0.05), "hepos": (0.1, 0.41),
			"cpos": (1.1, -0.05), "hcpos": (1.2, 1.13)
		}
	},
	"2021-09-01T17:44:01.968_boxing": {
		"encoder": {
			"1": (-1, 2), "2": (3, 3), "4": (3, 1), "6": (7, 2), "out6": (10, 2),
			"3": (1, -1), "9": (3, -1), "11": (5.5, -1), "14": (8.5, -1), "out14": (10, -1),
			"loopopt": {(11, 11): "loop above"},
			"backgroundnode": {"pos": (-2, 0.8), "width": (1.7, 9.15, 1.2), "height": 6},
			"labelsinclination": 45
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (-1, 0), "innerspan": 1, "squarespan": 7},# {"type": "singlenode", "pos": (0, 0)},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"53": (5, 6),
			"74": (5, -8), "81": (7, -8),
			"67": (5, -4),
			"78": (6, -3), "59": (6, -1.6), "79": (8, -3),
			"85": (5, 5),
			"77": (5, 8),
			"52": (7, 7),
			"69": (6, 3), "82": (8, 4),
			"customedges": {
				(1, "out1"): "bend left=15",
				(4, 52): "bend left=10",
				(32, 53): "bend left=10",
				(53, "out53"): "bend right=5",
				(14, 77): "bend left=30",
				(14, "out14"): "bend right=10",
				(7, "out7"): "bend right=18",
				(1, 78): "bend right=10",
				(47, 78): "bend left=10",
				(48, "out48"): "bend left=20",
				(27, "out27"): "bend left=10",
				(35, "out35"): "bend left=12",
				(36, "out36"): "bend left=5",
				(14, "out14'"): "bend right=20",
				(12, "out12"): "bend right=20",
				(37, 74): "bend right=18",
				(44, 67): "bend right=18"
			},
			"customlabel": {
				(32, 53): "pos=0.8",
				(49, 85): "pos=0.93",
				(17, 69): "pos=0.9",
				(31, 69): "pos=0.93",
				(1, 78): "pos=0.9",
				(47, 78): "pos=0.8",
				(78, 79): "pos=0.5, yshift=-0.25cm",
				(74, 81): "pos=0.5, yshift=-0.25cm",
				(69, 82): "pos=0.5, yshift=-0.25cm"
			},
			"loopopt": {(52, 52): "loop below, min distance=1cm"},
			"backgroundnode": {"pos": (-3.7, 1), "width": (5.2, 6.8, 2.1), "height": 19},
			"sticky": (10, 9.6)
		},
		"canvas": {
			"rgbpos": (0.03, 0.5), "hrgbpos": (0.1, 1.12), "scorepos": (0.1, 0.52),
			"epos": (0, -0.3), "hepos": (0.1, 0.32),
			"cpos": (1.1, -0.3), "hcpos": (1.2, 1.13)
		}
	},
	"2021-09-03T18:18:34.627_solaris": {
		"encoder": {
			"1": (0, 0),
			"9": (2, 2.62), "12": (5, 2.62), "18": (8, 2.62), "out18": (12, 2.62),
			"4": (4, 0), "8": (7, 0), "20": (10, 0), "out20": (12, 0),
			"2": (2, -2.62), "3": (5, -2.62), "7": (8, -2.62),
			"backgroundnode": {"pos": (-1.1, 0.4), "width": (1.8, 9.9, 1.5), "height": 7.8}
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (-1, 0), "innerspan": 1, "squarespan": 7},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"54": (5, 8),
			"56": (5, 6), "66": (7, 6),
			"63": (7, -0.5), "81": (7, 2.5),
			"59": (2.8, 2.4), "80": (6.7, 4.7),
			"87": (7, -5),
			"77": (7, -6),
			"backgroundnode": {"pos": (-3.7, 1), "width": (5.2, 6.8, 2.1), "height": 19},
			"sticky": (10, 9.6)
		},
		"canvas": {
			"rgbpos": (0.03, 0.5), "hrgbpos": (0.1, 1.12), "scorepos": (0.1, 0.52),
			"epos": (0, -0.3), "hepos": (0.1, 0.41),
			"cpos": (1.1, -0.3), "hcpos": (1.2, 1.13)
		}
	}
}

EDGELABELS = {
	"f_binary": "Binary",
	"f_bitwise_or": "OR",
	"f_bitwise_not": "NOT",
	"f_bitwise_and": "AND",
	"f_bitwise_xor": "XOR",
	"f_subtract": "$-$", # "Subtract",
	"f_threshold": "Threshold",
	"f_dilate": "Dilate",
	"f_erode": "Erode",
	"f_motion_capture": "Motion Capture",
	"f_add": "$+$",
	"f_mult": "$\\times$",
	"f_lt": "$\\leq$",
	"f_gt": "$\\geq$",
	"f_div": "$\\div$",
	"f_sqrt": "$\\sqrt{\cdot}$",
	"f_and": "AND",
	"f_or": "OR",
	"f_xor": "XOR",
	"f_not": "NOT"
}

ACTIONLABELS = {
	0: "$\\quad$",
	1: "$\\bullet$",
	2: "$\\uparrow$",
	3: "$\\rightarrow$",
	4: "$\\leftarrow$",
	5: "$\\downarrow$",
	6: "$\\nearrow$",
	7: "$\\nwarrow$",
	8: "$\\searrow$",
	9: "$\\swarrow$",
	10: "$\\bullet \\uparrow$",
	11: "$\\bullet \\rightarrow$",
	12: "$\\bullet \\leftarrow$",
	13: "$\\bullet \\downarrow$",
	14: "$\\bullet \\nearrow$",
	15: "$\\bullet \\nwarrow$",
	16: "$\\bullet \\searrow$",
	17: "$\\bullet \\swarrow$"
}

	
def printinddict(g, verbose=True):
	spacing = "  "
	if verbose:
		for k, v in g.items():
			print(spacing, k, ":", v)
	else:
		for k in ["inputs", "nodes", "outputs"]:
			print(spacing, k, ":", g[k])

def printdict(d):
	for k, v in d.items():
		print(k, ":", v)

def printgdict(gdict):
	print("\nLoaded gdict:")
	print("\nencoder:")
	#print(gdict["encoder"])
	printinddict(gdict["encoder"])
	print("\nreducer:")
	print(gdict["reducer"])
	print("\ncontroller:")
	#print(gdict["controller"])
	printinddict(gdict["controller"])
	print("\nmeta:")
	print(gdict["metadata"])
	print()

def str_to_tuple(s):
	if s[0] == "(":
		s = s[1:-1]
	if s[-1] == ")":
		s = s[0:-2]
	return tuple(map(int, s.split(', ')))

def open_yaml(path):
	with open(path, 'r') as stream:
		try:
			return yaml.safe_load(stream)
		except yaml.YAMLError as exc:
			print(exc)

def rgbfname(frame):
	return str(frame) + "_rgb.png"

def graphfname(frame, indtype):
	return str(frame) + "_graph_" + indtype

def canvasfname(frame):
	return str(frame) + "_canvas"
	
def writeat(path, lines):
	with open(path, 'w') as f:
		for l in lines:
			f.write(l)
			f.write('\n')
		f.close()

def retrieve_buffer(indtype, path, frame):
	if indtype == "encoder":
		return retrieve_img_buffer(path, frame, "e")
	elif indtype == "reducer":
		return retrieve_img_buffer(path, frame, "f")
	elif indtype == "controller":
		return retrieve_cont_buffer(path, frame)
	else:
		raise NameError(indtype)

def retrieve_img_buffer(path, frame, key):
	b = {}
	fprefix = str(frame) + "_" + key
	for f in os.listdir(path):
		if f.startswith(fprefix):
			node = int(f[len(fprefix):-len(IMG_EXT)])
			b[node] = path + f # PIL.Image.open(path + f)
	return b

def retrieve_cont_buffer(path, frame):
	fname = path + str(frame) + "_c.yaml"
	b = open_yaml(fname)
	return b

def retrieve_metadata(path, frame):
	fname = path + str(frame) + "_m.yaml"
	return open_yaml(fname)
	
def get_max_frame(exp_dir):
	if MAX_FRAME is None:
		bdir = get_paths(exp_dir)["metadata"]
		return max([int(f.split("_")[0]) for f in os.listdir(bdir)])
	else:
		return MAX_FRAME

def get_paths(exp_dir):
	paths = {}
	paths["exp"] = exp_dir.split("/")[-1]
	g_dir = exp_dir + "/graphs"
	for f in os.listdir(g_dir):
		indtype = f[0:len(f)-len(".yaml")]
		paths[indtype] = {}
		paths[indtype]["graph"] = g_dir + "/" + f
		paths[indtype]["buffer"] = exp_dir + "/buffers/"
	paths["reducer"] = {}
	paths["reducer"]["buffer"] = exp_dir + "/buffers/"
	paths["metadata"] = exp_dir + "/buffers/"
	return paths

def gdict_from_paths(paths, frame):
	gdict = {}
	for indtype in ["encoder", "controller"]:
		v = paths[indtype]
		g = open_yaml(v["graph"])
		g["inputs"] = list(range(1,1+g["n_in"]))
		g["edges"] = [str_to_tuple(e) for e in g["edges"]]
		g["buffer"] = retrieve_buffer(indtype, v["buffer"], frame)
		gdict[indtype] = g
	gdict["reducer"] = {}
	gdict["reducer"]["buffer"] = retrieve_buffer("reducer", paths["reducer"]["buffer"], frame)
	gdict["metadata"] = retrieve_metadata(paths["metadata"], frame)
	return gdict
	
def getnodename(node, g=None, isout=False):
	if isout:
		node_index_in_cgp = g["outputs"][node] # here, node is the index in g["output"]
		n_prev_occurences = g["outputs"][0:node].count(node_index_in_cgp)
		return "out" + str(node_index_in_cgp) + n_prev_occurences*"'"
	else: # input or inner node
		return str(node)
	
def randompos():
	return (RANDOM_POS_MAG*random.random(), RANDOM_POS_MAG*random.random())
	
def postostr(pos):
	for k, v in pos.items():
		pos[k] = str(v[0])+","+str(v[1])
	return pos
	
def twopletostr(t):
	return "(" + str(t[0]) + ", " + str(t[1]) + ")"
	
def getcanvastrim(expdir):
	etrim, ctrim = "", ""
	if expdir in list(POS.keys()) and "canvas" in list(POS[expdir].keys()):
		if "etrim" in list(POS[expdir]["canvas"].keys()):
			etrim = ",clip,trim={" + POS[expdir]["canvas"]["etrim"] + "}"
		if "ctrim" in list(POS[expdir]["canvas"].keys()):
			ctrim = ",clip,trim={" + POS[expdir]["canvas"]["ctrim"] + "}"
	return etrim, ctrim

def getcanvaspos(expdir):
	scorepos, rgbpos, epos, cpos = "(0, -1)", "(0, 0)", "(1, 0)", "(2, 0)"
	hrgbpos, hepos, hcpos = "(0, 1)", "(1, 1)", "(2, 1)"
	if expdir in list(POS.keys()) and "canvas" in list(POS[expdir].keys()):
		if "scorepos" in list(POS[expdir]["canvas"].keys()):
			scorepos = twopletostr(POS[expdir]["canvas"]["scorepos"])
		if "rgbpos" in list(POS[expdir]["canvas"].keys()):
			rgbpos = twopletostr(POS[expdir]["canvas"]["rgbpos"])
		if "hrgbpos" in list(POS[expdir]["canvas"].keys()):
			hrgbpos = twopletostr(POS[expdir]["canvas"]["hrgbpos"])
		if "epos" in list(POS[expdir]["canvas"].keys()):
			epos = twopletostr(POS[expdir]["canvas"]["epos"])
		if "hepos" in list(POS[expdir]["canvas"].keys()):
			hepos = twopletostr(POS[expdir]["canvas"]["hepos"])
		if "cpos" in list(POS[expdir]["canvas"].keys()):
			cpos = twopletostr(POS[expdir]["canvas"]["cpos"])
		if "hcpos" in list(POS[expdir]["canvas"].keys()):
			hcpos = twopletostr(POS[expdir]["canvas"]["hcpos"])
	return scorepos, rgbpos, hrgbpos, epos, hepos, cpos, hcpos
	
def getcanvasscales(expdir):
	scoresc, rgbsc, esc, csc = "0.1", "0.8", "1.0", "1.0"
	hrgbsc, hesc, hcsc = "0.1", "0.1", "0.1"
	if expdir in list(POS.keys()) and "canvas" in list(POS[expdir].keys()):
		if "scoresc" in list(POS[expdir]["canvas"].keys()):
			scoresc = str(POS[expdir]["canvas"]["scoresc"])
		if "rgbsc" in list(POS[expdir]["canvas"].keys()):
			rgbsc = str(POS[expdir]["canvas"]["rgbsc"])
		if "hrgbsc" in list(POS[expdir]["canvas"].keys()):
			hrgbsc = str(POS[expdir]["canvas"]["hrgbsc"])
		if "esc" in list(POS[expdir]["canvas"].keys()):
			esc = str(POS[expdir]["canvas"]["esc"])
		if "hesc" in list(POS[expdir]["canvas"].keys()):
			hesc = str(POS[expdir]["canvas"]["hesc"])
		if "csc" in list(POS[expdir]["canvas"].keys()):
			csc = str(POS[expdir]["canvas"]["csc"])
		if "hcsc" in list(POS[expdir]["canvas"].keys()):
			hcsc = str(POS[expdir]["canvas"]["hcsc"])
	return scoresc, rgbsc, hrgbsc, esc, hesc, csc, hcsc

def getcanvasbackground(expdir):
	out = ""
	if expdir in list(POS.keys()) and "canvas" in list(POS[expdir].keys()) and "background" in list(POS[expdir]["canvas"].keys()):
		c = POS[expdir]["canvas"]["background"]["color"]
		s = POS[expdir]["canvas"]["background"]["sw"]
		n = POS[expdir]["canvas"]["background"]["ne"]
		hsep = POS[expdir]["canvas"]["background"]["hsep"]
		vsep = POS[expdir]["canvas"]["background"]["vsep"]
		s = (s[0]-vsep, s[1]-hsep)
		n = (n[0]+vsep, n[1]+hsep)
		out = "\\fill["+c+"] "+twopletostr(s)+" rectangle "+twopletostr(n)+";"
	return out
	
def columnpos(posdict, n_nodes, index):
	orig = posdict["pos"]
	span = posdict["span"]
	return (orig[0], orig[1] - index*span + 0.5*n_nodes*span)
	
def squarepos(gdict, posdict, n_nodes, index):
	n_squares = gdict["encoder"]["n_out"]
	n_noncst_in = gdict["controller"]["n_in"] - gdict["controller"]["n_cst_input"]
	nodes_per_square = n_noncst_in / n_squares
	size = math.sqrt(nodes_per_square)
	assert float(size).is_integer(), "impossible square size: " + str(size)
	in_square_index = (index-1) % nodes_per_square
	current_square = math.ceil(index / nodes_per_square)
	row = math.floor(in_square_index / size)
	col = int(in_square_index % size)
	innerspan = posdict["innerspan"]
	pos = ((col-(size-1)/2)*innerspan, (-row+(size-1)/2)*innerspan)
	pos = tuple(map(operator.add, pos, posdict["origin"])) # shift to origin
	sqshift = (0, ((n_squares+1)/2-current_square)*posdict["squarespan"])
	pos = tuple(map(operator.add, pos, sqshift)) # shift squares
	return pos

def cstpos(gdict, posdict, n_nodes, index, expdir):
	n_noncst_in = gdict["controller"]["n_in"] - gdict["controller"]["n_cst_input"]
	pos = (0,POS[expdir]["controller"]["inputs"]["cst_input_y"]+n_noncst_in-index)
	return pos

def getpos(gdict, expdir, indtype):
	pos = {}
	g = gdict[indtype]
	n_inp = g["n_in"]
	
	# Position of input nodes
	for i in range(1, n_inp+1):
		node = i
		nodename = getnodename(node)
		pos[nodename] = randompos() # Default to random position
		if ENABLE_MANUAL_POS:
			if expdir in list(POS.keys()) and indtype in list(POS[expdir].keys()):
				if nodename in list(POS[expdir][indtype].keys()):
					pos[nodename] = POS[expdir][indtype][nodename]
				elif "inputs" in list(POS[expdir][indtype].keys()):
					input_pos_dict = POS[expdir][indtype]["inputs"]
					if input_pos_dict["type"] == "singlenode":
						pos[nodename] = input_pos_dict["pos"]
					elif input_pos_dict["type"] == "column":
						pos[nodename] = columnpos(input_pos_dict, n_inp, i)
					elif input_pos_dict["type"] == "squares":
						pos[nodename] = squarepos(gdict, input_pos_dict, n_inp, i)
					else:
						print("WARNING: input position type", input_pos_dict["type"], "unknown.")
					if ("cst_in" in list(POS[expdir][indtype]["inputs"].keys())
						and POS[expdir][indtype]["inputs"]["cst_in"]
						and i > n_inp - gdict["controller"]["n_cst_input"]): # is cst node test
						pos[nodename] = cstpos(gdict, input_pos_dict, n_inp, i, expdir)
	
	# Position of inner nodes
	for node in list(g["buffer"].keys()):
		isinp = node <= n_inp
		if not isinp:
			nodename = getnodename(node)
			pos[nodename] = randompos() # Default to random position
			if ENABLE_MANUAL_POS:
				if expdir in list(POS.keys()) and indtype in list(POS[expdir].keys()):
					if nodename in list(POS[expdir][indtype].keys()):
						pos[nodename] = POS[expdir][indtype][nodename]

	# Position of output nodes
	n_out = len(g["outputs"])
	for i in range(n_out): 
		# node = g["outputs"][i]
		nodename = getnodename(i, g, True)
		pos[nodename] = randompos() # Default to random position
		if ENABLE_MANUAL_POS:
			if expdir in list(POS.keys()) and indtype in list(POS[expdir].keys()):
				if nodename in list(POS[expdir][indtype].keys()):
					pos[nodename] = POS[expdir][indtype][nodename]
				elif "outputs" in list(POS[expdir][indtype].keys()):
					output_pos_dict = POS[expdir][indtype]["outputs"]
					if output_pos_dict["type"] == "singlenode":
						pos[nodename] = output_pos_dict["pos"]
					elif output_pos_dict["type"] == "column":
						pos[nodename] = columnpos(output_pos_dict, n_out, i)
					else:
						print("WARNING: output position type", output_pos_dict["type"], "unknown.")
						
	# Position of sticky node
	nodename = "sticky"
	pos[nodename] = randompos() # Default to random position
	if (
		ENABLE_MANUAL_POS
		and expdir in list(POS.keys())
		and indtype in list(POS[expdir].keys())
		and nodename in list(POS[expdir][indtype].keys())
	):
		pos[nodename] = POS[expdir][indtype][nodename]

	pos = postostr(pos)
	return pos
	
def getnodecontent(gdict, node, nodename, indtype, is_out, index=None, isbackground=False):
	if not PRINTBUFFER:
		return nodename
	elif indtype == "encoder":
		if is_out:
			width = IMGOUT_WIDTH
			wstr = str(width) + "cm"
			if isbackground: wstr = "5cm"
			return "\includegraphics[width="+wstr+"]{"+gdict["reducer"]["buffer"][node]+"}"
		else:
			width = IMG_WIDTH
			wstr = str(width) + "cm"
			hstr = str(WH_RATIO * width) + "cm"
			return "\includegraphics[width="+wstr+", height="+hstr+"]{"+gdict[indtype]["buffer"][node]+"}"
	elif indtype == "controller":
		if is_out:
			action_name_in_ale = gdict["controller"]["actions"][index]
			act = ACTIONLABELS[action_name_in_ale]
			val = "$" + str(round(gdict[indtype]["buffer"][node], 2)) + "$"
			return act + "\\quad" + val
		else:
			return "$" + str(round(gdict[indtype]["buffer"][node], 2)) + "$"
			
def getnodesettings(gdict, expdir, node, nodename, activated, indtype, isout, iscontout_selected):
	iscontroller = indtype == "controller"
	if (
		iscontroller
		and ENABLE_MANUAL_POS
		and node <= gdict[indtype]["n_in"]
		and nodename[:3] != "out"
		and expdir in list(POS.keys()) 
		and indtype in list(POS[expdir].keys())
		and "inputs" in list(POS[expdir][indtype].keys())
		and POS[expdir][indtype]["inputs"]["type"] == "squares"
	): # reduced images as background
		nodesettings = "draw=none, color=black, fill=white, opacity=0.7, rounded corners=0.1cm, minimum width=0.9cm"
	else:
		issticky = gdict["metadata"]["is_sticky"]
		isactive = (node in activated) and (not issticky or (isout and iscontroller))
		if isactive and isout and iscontroller:
			isactive = not iscontout_selected
			iscontout_selected = True
		nodecolor = COLOR_ACTIVE if isactive else COLOR_INACTIVE
		thickness = THICKNESS_ACTIVE if isactive else THICKNESS_INACTIVE
		h = "0.6cm"
		w = "2cm" if (indtype == "controller" and isout) else "1cm"
		if not PRINTBUFFER and indtype == "encoder": # print nodes in same size as if images were there
			if isout:
				w = str(IMGOUT_WIDTH) + "cm"
				h = w
			else:
				w = str(IMG_WIDTH) + "cm"
				h = str(WH_RATIO * IMG_WIDTH) + "cm"
		sep = "inner sep=0,outer sep=0," if indtype == "encoder" else ""
		nodesettings = "shape=rectangle, rounded corners=0.1cm, minimum width="+w+", minimum height="+h+", fill=white,"+sep+"draw, color="+nodecolor+",fill="+COLOR_BACKGROUND+","+thickness
	return nodesettings, iscontout_selected

def getedgelabel(fname):
	if fname in list(EDGELABELS.keys()):
		return EDGELABELS[fname]
	else:
		return fname[2:].replace('_', ' ')

def appendbackgroundnodes(ts, gdict, expdir, indtype):
	if (ENABLE_MANUAL_POS
		and expdir in list(POS.keys()) 
		and indtype in list(POS[expdir].keys())
	):
		if (GRAPHBACK
			and "backgroundnode" in list(POS[expdir][indtype].keys())
		): # I/O background node
			d = POS[expdir][indtype]["backgroundnode"]
			pos = d["pos"]
			w, h = d["width"], d["height"]
			pos_upper = (pos[0]+sum(w), pos[1]+h)
			nodesettings = "anchor=west, text centered, rectangle split, rectangle split horizontal, rectangle split parts=3, draw, rectangle split draw splits=false, color=black, fill=white, rounded corners=0.1cm, minimum height="+str(h)+"cm"
			splitsettings = "dashed"
			pos = str(pos[0]) + "," + str(pos[1])
			ts.append("\\node["+nodesettings+"] (A) at ("+pos+") {\\nodepart[text width="+str(w[0])+"cm]{one}\\begin{minipage}[t]["+str(h)+"cm]{"+str(w[0])+"cm}\centering \\textbf{Input}\\end{minipage} \\nodepart[text width="+str(w[1])+"cm]{two} \\nodepart[text width="+str(w[2])+"cm]{three} \\begin{minipage}[t]["+str(h)+"cm]{"+str(w[2])+"cm}\centering \\textbf{Output}\\end{minipage}};")
			ts.append("\\draw["+splitsettings+"] (A.one split south) -- (A.one split north);")
			ts.append("\\draw["+splitsettings+"] (A.two split south) -- (A.two split north);")
			#ts.append("\\fill ("+pos+") rectangle ("+pos_upper+");")
			#ts.append("\\clip ("+pos+") rectangle ("+pos_upper+");")
		if (indtype == "controller"
			and "inputs" in list(POS[expdir][indtype].keys())
			and POS[expdir][indtype]["inputs"]["type"] == "squares"
		): # reduced images as background
			posdict = POS[expdir][indtype]["inputs"]
			n_squares = gdict["encoder"]["n_out"]
			n_noncst_in = gdict[indtype]["n_in"] - gdict[indtype]["n_cst_input"]
			nodes_per_square = n_noncst_in / n_squares
			size = math.sqrt(nodes_per_square)
			assert float(size).is_integer(), "impossible square size: " + str(size)
			width = posdict["innerspan"]*size
			for i in range(n_squares):
				node = gdict["encoder"]["outputs"][i]
				nodename = getnodename(i, gdict["encoder"], True)
				isout = True
				nodecontent = getnodecontent(gdict, node, nodename, "encoder", isout, i, True)
				pos = posdict["origin"]
				current_square = i + 1
				sqshift = (0, ((n_squares+1)/2-current_square)*posdict["squarespan"])
				pos = tuple(map(operator.add, pos, sqshift)) # shift squares
				pos = str(pos[0]) + "," + str(pos[1])
				ts.append("\\node[] () at ("+pos+") {"+nodecontent+"};")
				# Add coordinates if required
				if ("showcoord" in POS[expdir][indtype]["inputs"].keys()
					and POS[expdir][indtype]["inputs"]["showcoord"]):
					for i in range(1,1+int(size)):
						for pos in [(-2.7,3-i), (i-3,+2.7)]:
							pos = str(pos[0]) + "," + str(pos[1])
							ts.append("\\node[] at ("+pos+") {"+str(i)+"};")

def nodelabelfromfname(expdir, indtype, nodename, fname):
	nodelabel = str(fname)
	if ("names" in POS[expdir][indtype].keys()
		and nodename in POS[expdir][indtype]["names"].keys()):
		nodelabel = POS[expdir][indtype]["names"][nodename] + ": " + str(fname)
	return nodelabel

def getnodecustomopt(expdir, indtype, nodename):
	if "customndopt" in POS[expdir][indtype].keys():
		for customopt in POS[expdir][indtype]["customndopt"].keys():
			if nodename in POS[expdir][indtype]["customndopt"][customopt]:
				return customopt
	return ""

def getedgecustomopt(expdir, indtype, edge):
	if "customedgeopt" in POS[expdir][indtype].keys():
		for customopt in POS[expdir][indtype]["customedgeopt"].keys():
			if edge in POS[expdir][indtype]["customedgeopt"][customopt]:
				return customopt
	return ""	

def getnode(expdir, indtype, nodesettings, nodename, p, nodecontent, fname=None):
	if "avoided" in POS[expdir][indtype].keys() and nodename in POS[expdir][indtype]["avoided"]:
		return ""
	if BUFFERCLIP and indtype == "encoder" and PRINTBUFFER:
		#color = nodesettings.split("draw=")[1]
		#return "\\savebox{\\picbox}{"+nodecontent+"} \\node ["+nodesettings+", minimum width=\\wd\\picbox, minimum height=\\ht\\picbox, path picture={\\node at (path picture bounding box.center) {\\usebox{\\picbox}};}] ("+nodename+") at ("+p+") {};"
		if fname == None: # Encoder Input or Output node
			return "\\node["+nodesettings+", draw, fill=white, align=center, rounded corners=2mm, shape=rectangle, inner sep=1mm, outer sep=0] ("+nodename+") at ("+p+") {"+nodecontent+"};"
		else: # Encoder  Intermediate node
			nodelabel = nodelabelfromfname(expdir, indtype, nodename, fname)
			nodecustomopt = getnodecustomopt(expdir, indtype, nodename)
			return "\\node["+nodesettings+","+nodecustomopt+", draw, fill=white, align=center, rounded corners=2mm, shape=rectangle split, rectangle split parts=2, inner sep=1mm, outer sep=0] ("+nodename+") at ("+p+") {"+nodelabel+"\\nodepart{two}"+nodecontent+"};"
	elif indtype == "controller" and fname != None: # controller intermediate node
		nodelabel = nodelabelfromfname(expdir, indtype, nodename, fname)
		nodecustomopt = getnodecustomopt(expdir, indtype, nodename)
		return "\\node["+nodesettings+","+nodecustomopt+", shape=rectangle split, rectangle split parts=2] ("+nodename+") at ("+p+") {"+nodelabel+"\\nodepart{two}"+nodecontent+"};"
	else:
		nodecustomopt = getnodecustomopt(expdir, indtype, nodename)
		return "\\node["+nodesettings+","+nodecustomopt+"] ("+nodename+") at ("+p+") {"+nodecontent+"};"

def fnamefromnodename(g, nodename):
	for edge in g["edges"]:
		src, dst = str(edge[0]), str(edge[1])
		if dst == nodename:
			dstindex = g["nodes"].index(edge[1])
			edgelabel = getedgelabel(g["fs"][dstindex])
			return edgelabel
	return None
	
def appendnodes(ts, gdict, expdir, indtype):
	g = gdict[indtype]
	activated = gdict["metadata"][indtype]["activated"]
	outputs = gdict["metadata"][indtype]["outputs"]
	pos = getpos(gdict, expdir, indtype)
	appendbackgroundnodes(ts, gdict, expdir, indtype)
	if BUFFERCLIP: ts.append("\\newsavebox{\\picbox}")
	iscontout_selected = False
	
	# INPUT + INTERMEDIATE NODES
	for node in g["buffer"].keys():
		nodename = getnodename(node)
		fname = fnamefromnodename(g, nodename)
		isinput = node <= g["n_in"]
		p = pos[nodename]
		isout = False
		nodecontent = getnodecontent(gdict, node, nodename, indtype, isout)
		nodesettings, iscontout_selected = getnodesettings(gdict, expdir, node, nodename, activated, indtype, isout, iscontout_selected)
		nd = getnode(expdir, indtype, nodesettings, nodename, p, nodecontent, fname=fname)
		ts.append(nd)
	
	# OUTPUT NODES
	for i in range(len(g["outputs"])):
		node = g["outputs"][i]
		nodename = getnodename(i, g, True)
		p = pos[nodename]
		isout = True
		nodecontent = getnodecontent(gdict, node, nodename, indtype, isout, i)
		nodesettings, iscontout_selected = getnodesettings(gdict, expdir, node, nodename, outputs, indtype, isout, iscontout_selected)
		nd = getnode(expdir, indtype, nodesettings, nodename, p, nodecontent)
		ts.append(nd)
	
	# REPEAT ACTION NODE
	if indtype == "controller":
		is_sticky = gdict["metadata"]["is_sticky"]
		color = COLOR_ACTIVE if is_sticky else COLOR_BACKGROUND
		if not PRINTBUFFER: color = "teal"
		nodename = "sticky"
		p = pos[nodename]
		ts.append("\\node[color="+color+"] ("+nodename+") at ("+p+") {\\textbf{Repeated}};")

def getcustomlabelopt(expdir, indtype, edge, seenedges):
	out = ""
	if expdir in POS.keys() and indtype in POS[expdir].keys() and "customlabel" in POS[expdir][indtype].keys() and edge in POS[expdir][indtype]["customlabel"]:
		out += ", "
		setting = POS[expdir][indtype]["customlabel"][edge]
		if isinstance(setting, str):
			out += setting
		elif isinstance(setting, dict):
			out += setting[2] if edge in seenedges else setting[1]
		else:
			out += ""
	return out

'''
def isedgein(edge, l):
	for e in l:
		if (str(edge[0]), str(edge[1])) == (str(e[0]), str(e[1])):
			return True
	return False
'''

def getcustompathset(expdir, indtype, edge, seenedges):
	out = ""
	if expdir in POS.keys() and indtype in POS[expdir].keys() and "customedges" in POS[expdir][indtype].keys() and edge in POS[expdir][indtype]["customedges"]:
		out += ", "
		setting = POS[expdir][indtype]["customedges"][edge]
		if isinstance(setting, str):
			out += setting
		elif isinstance(setting, dict):
			out += setting[2] if edge in seenedges else setting[1]
		else:
			out += ""
	return out

def add_extra_edges(gdict, expdir, indtype):
	if expdir in POS.keys() and indtype in POS[expdir].keys() and "extra_edges" in POS[expdir][indtype]:
		for e in POS[expdir][indtype]["extra_edges"]:
			isout = False
			for i in range(2):
				if type(e[i]) == str and e[i][0:3] == "out": # avoid output edges
					isout = True
			if not isout:
				gdict["edges"].append(e)

def anchoredfromsrcdst(src, dst, expdir, indtype):
	if expdir in POS.keys() and indtype in POS[expdir].keys() and "customedgesanchors" in POS[expdir][indtype]:
		if (src, dst) in POS[expdir][indtype]["customedgesanchors"]:
			src_a, dst_a = POS[expdir][indtype]["customedgesanchors"][(src, dst)]
			if not (src_a is None):
				src += "." + src_a
			if not (dst_a is None):
				dst += "." + dst_a
	return src, dst

def appendedges(ts, gdict, expdir, indtype):
	g = gdict[indtype]
	activated = gdict["metadata"][indtype]["activated"]
	outputs = gdict["metadata"][indtype]["outputs"]
	seenedges = []
	add_extra_edges(g, expdir, indtype)
	
	# 1. Non-output edges
	for edge in g["edges"]:
		src, dst = str(edge[0]), str(edge[1])
		# Check is node is avoided
		if expdir in POS.keys() and indtype in POS[expdir].keys() and "avoided" in POS[expdir][indtype]:
			if src in POS[expdir][indtype]["avoided"] or dst in POS[expdir][indtype]["avoided"]:
				continue
		dstindex = g["nodes"].index(edge[1])
		edgelabel = getedgelabel(g["fs"][dstindex])
		loopopt = "loop left" if edge[0] == edge[1] else "" # self-loop
		if expdir in POS.keys() and indtype in POS[expdir].keys() and "loopopt" in POS[expdir][indtype].keys() and edge in POS[expdir][indtype]["loopopt"].keys():
			loopopt = POS[expdir][indtype]["loopopt"][edge]
		if expdir in POS.keys() and indtype in POS[expdir].keys() and "labelsinclination" in POS[expdir][indtype].keys():
			labelopt = "rotate=" + str(POS[expdir][indtype]["labelsinclination"])
		else:
			labelopt = "above"
		labelopt += ", fill=white, rounded corners=0.1cm, fill opacity=0.8, text opacity=1" if BACKGROUNDEDGELABELS else ""
		labelopt += ",pos=0.75" if indtype == "controller" else ""
		labelopt += getcustomlabelopt(expdir, indtype, edge, seenedges)
		isactive = (edge[1] in activated) and (not gdict["metadata"]["is_sticky"])
		edgecolor = COLOR_ACTIVE if isactive else COLOR_INACTIVE_EDGE
		pathset = "->, color="+edgecolor
		pathset += ", " + THICKNESS_ACTIVE if isactive else ", " + THICKNESS_INACTIVE
		custompathset = getcustompathset(expdir, indtype, edge, seenedges)
		pathset += custompathset
		pathset += ", " + getedgecustomopt(expdir, indtype, edge)
		anchored_src, anchored_dst = anchoredfromsrcdst(src, dst, expdir, indtype)
		if HALOEDGELABELS:
			ts.append("\\path[->, color=white, ultra thick"+custompathset+"] ("+anchored_src+") edge["+loopopt+"] node[above] {"+edgelabel+"} ("+anchored_dst+");")
		if LABEL_EDGES:
			ts.append("\\path["+pathset+"] ("+anchored_src+") edge["+loopopt+"] node["+labelopt+"] {"+edgelabel+"} ("+anchored_dst+");")
		else:
			ts.append("\\path["+pathset+"] ("+anchored_src+") edge["+loopopt+"] ("+anchored_dst+");")
		seenedges.append(edge)
	iscontoutedge_selected = False
	
	# 2. Output edges
	for i in range(len(g["outputs"])):
		output = g["outputs"][i]
		src = str(output)
		dst = getnodename(i, g, True)
		
		# Check is node is avoided
		if expdir in POS.keys() and indtype in POS[expdir].keys() and "avoided" in POS[expdir][indtype]:
			if src in POS[expdir][indtype]["avoided"] or dst in POS[expdir][indtype]["avoided"]:
				# Check if another edge is added in "extra_edges" before really avoiding it
				if expdir in POS.keys() and indtype in POS[expdir].keys() and "extra_edges" in POS[expdir][indtype] and dst in [e[1] for e in POS[expdir][indtype]["extra_edges"]]:
					for e in POS[expdir][indtype]["extra_edges"]:
						if dst == e[1]:
							src = e[0]
				else:
					continue

		edge = (int(src), dst) # (output, dst)
		isactive = (output in outputs) and (not gdict["metadata"]["is_sticky"])
		pathset = ""
		if isactive and not iscontoutedge_selected:
			edgecolor = COLOR_ACTIVE
			pathset += THICKNESS_ACTIVE
			if indtype == "controller": iscontoutedge_selected = True
		else:
			pathset += THICKNESS_INACTIVE
			edgecolor = COLOR_INACTIVE_EDGE
		pathset += ", ->, color="+edgecolor
		custompathset = getcustompathset(expdir, indtype, edge, seenedges)
		pathset += custompathset
		pathset += ", " + getedgecustomopt(expdir, indtype, edge)
		anchored_src, anchored_dst = anchoredfromsrcdst(src, dst, expdir, indtype)
		if HALOEDGELABELS:
			ts.append("\\path[->, color=white, ultra thick"+custompathset+"] ("+anchored_src+") edge node {} ("+anchored_dst+");")
		ts.append("\\path["+pathset+"] ("+anchored_src+") edge node {} ("+anchored_dst+");")

def set_font():
	return "\\renewcommand{\\familydefault}{\\" + FONT_FAMILY + "default}"

""" Main tex-script method """
def graph_texscript(gdict, paths, indtype, printtex=False):
	expdir = paths["exp"]
	ts = [] # texscript
	ts.append("\\documentclass[crop,tikz]{standalone}")
	ts.append("\\usepackage{graphicx}")
	ts.append("\\usetikzlibrary{shapes,automata}")
	ts.append("\\tikzset{>=stealth}")
	ts.append(set_font())
	ts.append("\\begin{document}")
	ts.append("\\begin{tikzpicture}[]")
	appendnodes(ts, gdict, expdir, indtype)
	appendedges(ts, gdict, expdir, indtype)
	ts.append("\\end{tikzpicture}")
	ts.append("\\end{document}")
	
	if printtex:
		print("\nPrinting graph TeX file for", indtype, ":")
		print(100*"-")
		for l in ts:
			print(l)
		print(100*"-")
	return ts

def canvas_texscript(paths, frame, score, printtex=False):
	savedir = paths["metadata"]
	expdir = paths["exp"]
	rgb_path = savedir + rgbfname(frame)
	e_gpath = savedir + graphfname(frame, "encoder") + ".pdf"
	c_gpath = savedir + graphfname(frame, "controller") + ".pdf"
	etrim, ctrim = getcanvastrim(expdir)
	rgb_content = "\includegraphics[width=1cm]{"+rgb_path+"}"
	e_content = "\includegraphics[width=1cm"+etrim+"]{"+e_gpath+"}"
	c_content = "\includegraphics[width=1cm"+ctrim+"]{"+c_gpath+"}"
	scorepos, rgbpos, hrgbpos, epos, hepos, cpos, hcpos = getcanvaspos(expdir)
	scoresc, rgbsc, hrgbsc, esc, hesc, csc, hcsc = getcanvasscales(expdir)	
	anch = "anchor=south west,"
	sep = "inner sep=0cm,outer sep=0cm,"
	ts = []
	ts.append("\\documentclass[crop,tikz]{standalone}")
	ts.append("\\usepackage{graphicx}")
	ts.append(set_font())
	ts.append("\\begin{document}")
	ts.append("\\begin{tikzpicture}")
	ts.append(getcanvasbackground(expdir))
	ts.append("\\node["+sep+anch+"scale="+hrgbsc+"] () at "+hrgbpos+" {(1) RGB Image};")
	ts.append("\\node["+sep+anch+"scale="+rgbsc+"] () at "+rgbpos+" {"+rgb_content+"};")
	ts.append("\\node["+sep+anch+"scale="+scoresc+"] () at "+scorepos+" {Score: "+str(score)+"};")
	ts.append("\\node["+sep+anch+"scale="+hesc+"] () at "+hepos+" {(2) CGP Encoder};")
	ts.append("\\node["+sep+anch+"scale="+esc+"] () at "+epos+" {"+e_content+"};")
	ts.append("\\node["+sep+anch+"scale="+hcsc+"] () at "+hcpos+" {(3) CGP Controller};")
	ts.append("\\node["+sep+anch+"scale="+csc+"] () at "+cpos+" {"+c_content+"};")
	ts.append("\\end{tikzpicture}")
	ts.append("\\end{document}")
	if printtex:
		print("\nPrinting canvas TeX file :")
		print(100*"-")
		for l in ts:
			print(l)
		print(100*"-")
	return ts
	
def runtex(fname, savedir, texsavepath, iscanvas=False, indtype=None):
	f = sys.stdout if PRINTPDFLATEXOUT else open('/dev/null', 'w')
	subprocess.run(
		["pdflatex", "-interaction", "nonstopmode",
		"-output-directory", savedir, texsavepath],
		stdout=f, stderr=f # , capture_output=False # TODO check
	)
	# clean
	for ext in [".tex", ".aux", ".log"]:
		os.remove(savedir + fname + ext)
	# evince
	if (iscanvas and SHOWFRAMES) or ((not iscanvas) and (SHOWENCO and indtype=="encoder") or (SHOWCONT and indtype=="controller")):
		subprocess.run(["evince", savedir + fname + ".pdf"])

def canvastopng(fname, savedir):
	pdffile = savedir + fname + ".pdf"
	pngfile = savedir + fname + ".png"
	pages = convert_from_path(pdffile, dpi=2000)
	pages[0].save(pngfile, 'PNG')
	if DELETE_CANVAS_PDF:
		os.remove(pdffile)
	
def build_graph(texscript, paths, frame, indtype):
	savedir = paths["metadata"]
	fname = graphfname(frame, indtype)
	texsavepath = savedir + fname + ".tex"
	writeat(texsavepath, texscript)
	runtex(fname, savedir, texsavepath, indtype=indtype)
	
def build_canvas(texscript, paths, frame):
	savedir = paths["metadata"]
	fname = canvasfname(frame)
	texsavepath = savedir + fname + ".tex"
	writeat(texsavepath, texscript)
	runtex(fname, savedir, texsavepath, iscanvas=True)
	if TOPNG:
		canvastopng(fname, savedir)

def make_graphs(paths, frame, gdict):
	if ONLYENCO:
		indtypes = ["encoder"]
	elif ONLYCONT:
		indtypes = ["controller"]
	else:
		indtypes = ["controller", "encoder"]
	for indtype in indtypes:
		texscript = graph_texscript(gdict, paths, indtype)
		build_graph(texscript, paths, frame, indtype)
		if ONLYENCO or ONLYCONT: exit()
		
def delete_graphs(paths, frame):
	savedir = paths["metadata"]
	for indtype in ["encoder", "controller"]:
		fname = graphfname(frame, indtype)
		os.remove(savedir + fname + ".pdf")

def make_canvas(paths, frame, score):
	texscript = canvas_texscript(paths, frame, score)
	build_canvas(texscript, paths, frame)
	if DELETE_GRAPHS_PDF: delete_graphs(paths, frame)
		
def make_video(paths, max_frame, fps, verbose=True):
	bufferdir = paths["metadata"]
	savedir = bufferdir[0:-len("buffers/")]
	fspan = 1000
	n_vid = math.ceil(max_frame / fspan)
	subvideofnames = [savedir + "canvas" + str(i+1) + ".avi" for i in range(n_vid)]
	img = cv2.imread(bufferdir + str(1) + "_canvas.png")
	height, width, layers = img.shape
	size = (width, height)
	ranges = [range(i, i+fspan) for i in range(1, max_frame + 1 - fspan, fspan)]
	ranges.append(range(len(ranges) * fspan + 1, max_frame + 1))
	subvid_index = 0
	if verbose: print("\nCreating video"+"\nfps: "+str(fps))	
	# Creating sub-videos
	for r in ranges:
		if verbose: print("Loading images from", r[0], "to", r[-1], "out of", max_frame, ":")
		img_array = []
		for frame in tqdm(r):
			fname = bufferdir + str(frame) + "_canvas.png"
			img = cv2.imread(fname)
			img_array.append(img)
		if verbose: print("Successfully loaded", len(r), "images")
		videofname = subvideofnames[subvid_index]
		out = cv2.VideoWriter(videofname, cv2.VideoWriter_fourcc(*'DIVX'), fps, size)
		for i in range(len(img_array)):
			out.write(img_array[i])
		out.release()
		if verbose: print("Successfully created sub-video number", subvid_index+1, "at", videofname)
		subvid_index += 1
		
	# Assembling sub-videos
	viddir = os.path.dirname(os.path.dirname(os.path.dirname(savedir)))
	vidname = os.path.basename(os.path.dirname(savedir)) + "_" + str(fps) + "fps.avi"
	finalvideofname = viddir + "/" + vidname	
	video = cv2.VideoWriter(finalvideofname, cv2.VideoWriter_fourcc(*'DIVX'), fps, size)
	if verbose: print("\nAssembling sub-videos:")
	for f in tqdm(subvideofnames):
		v = cv2.VideoCapture(f)
		while v.isOpened():
			r, frame = v.read()
			if not r:
				break
			video.write(frame)
	video.release()
	if verbose: print("Successfully assembled video at", finalvideofname)
	
	# Removing sub-videos
	if verbose: print("\nRemoving sub-videos:")
	for f in tqdm(subvideofnames):
		os.remove(f)
	if verbose: print("Successfully created video!")
	
def make_frames(paths, max_frame, verbose=True):
	if verbose:
		spth = paths["metadata"]
		print("Creating frames")
		print("Number of frames :", str(max_frame))
		print("Experiment id    :", paths["exp"])
		print("Experiment path  :", os.path.dirname(os.path.dirname(spth)))
		print("Saving frames at :", spth)
	for frame in tqdm(range(1, max_frame + 1)):
		gdict = gdict_from_paths(paths, frame)
		score = gdict["metadata"]["score"]
		make_graphs(paths, frame, gdict)
		make_canvas(paths, frame, score)
	if verbose: print("Successfully created frames!")

def get_exp_dir(rom):
	exp_dir = ICGPRES_DIR + "/results/"
	if rom == "boxing":
		return exp_dir + "2021-09-01T17:44:01.968_1_boxing"
	elif rom == "freeway":
		return exp_dir + "2021-09-03T18:18:35.090_1_freeway"
	elif rom == "asteroids":
		return exp_dir + "2021-09-23T18:31:09.813_1_asteroids"
	elif rom == "space_invaders":
		return exp_dir + "2021-10-01T18:23:26.293_1_space_invaders"
	elif rom == "breakout":
		return exp_dir + "2021-09-23T18:31:09.829_1_breakout"
	elif rom == "riverraid":
		return exp_dir + "2021-10-01T18:22:33.340_1_riverraid"
	elif rom == "gravitar":
		return exp_dir + "2021-09-07T17:17:40.579_1_gravitar"
	else:
		raise NameError(rom)
	
"""
Main make method calling frame-maker and video-maker sequentially.
"""
def make(rom):
	#exp_dir = get_exp_dir(rom)
	exp_dir = rom # new exp_dir
	paths = get_paths(exp_dir)
	max_frame = get_max_frame(exp_dir)
	random.seed(SEED)
	if DOFRAMES: make_frames(paths, max_frame)
	if DOVIDEO:
		for fps in FPSS:
			make_video(paths, max_frame, fps)

if __name__ == "__main__":
	rom = sys.argv[1]
	make(rom)

# python3.8 pytexgraph.py /home/opaweynch/Documents/git/ICGP-results/results/2021-09-01T17:44:01.968_boxing

# python3.8 pytexgraph.py /home/opaweynch/Documents/git/ICGP-results/results/2021-10-01T18:23:26.293_space_invaders

