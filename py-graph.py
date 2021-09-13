#!/usr/bin/python

import sys
import os
import networkx as nx
import matplotlib.pyplot as plt
# import random
import yaml
from PIL import Image


# Meta parameters
DIR_PATH = os.path.dirname(os.path.realpath(__file__))
IMG_TYPE = ".png"
INP_NODE_COLOR = "red"
INN_NODE_COLOR = "black"
OUT_NODE_COLOR = "blue"
INCR = 100 # increment for controller's nodes names

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

def retrieve_buffer(ind_name, path, frame):
	if ind_name == "encoder":
		return retrieve_img_buffer(path, frame, "e")
	elif ind_name == "reducer":
		return retrieve_img_buffer(path, frame, "f")
	elif ind_name == "controller":
		return retrieve_cont_buffer(path, frame)
	else:
		raise NameError(ind_name)

def retrieve_img_buffer(path, frame, key):
	b = {}
	for f in os.listdir(path):
		if int(f[0]) == frame and f[2] == key:
			node = int(f[3:-len(IMG_TYPE)])
			b[node] = Image.open(path + f)
	return b

def retrieve_cont_buffer(path, frame):
	fname = path + str(frame) + "_c.yaml"
	b = open_yaml(fname)
	return b

def retrieve_metadata(path, frame):
	fname = path + str(frame) + "_m.yaml"
	return open_yaml(fname)

def get_paths(exp_dir):
	g_dir = exp_dir + "/graphs"
	paths = {}
	for f in os.listdir(g_dir):
		ind_name = f[0:len(f)-len(".yaml")]
		paths[ind_name] = {}
		paths[ind_name]["graph"] = g_dir + "/" + f
		paths[ind_name]["buffer"] = exp_dir + "/buffers/"
	paths["reducer"] = {}
	paths["reducer"]["buffer"] = exp_dir + "/buffers/"
	paths["meta"] = exp_dir + "/buffers/"
	return paths

def gdict_from_paths(paths, frame):
	gdict = {}
	for ind_name in ["encoder", "controller"]:
		v = paths[ind_name]
		g = open_yaml(v["graph"])
		g["inputs"] = list(range(1,1+g["n_in"]))
		g["edges"] = [str_to_tuple(e) for e in g["edges"]]
		g["buffer"] = retrieve_buffer(ind_name, v["buffer"], frame)
		gdict[ind_name] = g
	gdict["reducer"] = {}
	gdict["reducer"]["buffer"] = retrieve_buffer("reducer", paths["reducer"]["buffer"], frame)
	gdict["meta"] = retrieve_metadata(paths["meta"], frame)
	return gdict

def test_gdict():
	bpath = DIR_PATH + '/results/2021-09-01T17:44:01.968_boxing/buffers/'
	eb = retrieve_img_buffer(bpath, 1, "e")
	rb = retrieve_img_buffer(bpath, 1, "f")
	img = eb[1]
	red = rb[1]
	gdict = {
		'encoder': {
			'nodes': [4, 5, 6],
			'fs': ['f_compare', 'f_motion_tracking', 'f_dilate'],
			'n_in': 3,
			'n_out': 2,
			'inputs': [1, 2, 3],
			'outputs': [4, 6],
			'edges': [(1, 4), (2, 4), (3, 5), (5, 6)],
			'buffer': {1:img, 2:img, 3:img, 4:img, 5:img, 6:img}
		},
		'controller': {
			'nodes': [6, 7, 8, 9, 10],
			'fs': 5*["f"],
			'n_in': 5,
			'n_out': 5,
			'inputs': [1, 2, 3, 4, 5],
			'outputs': [1, 2, 6, 8, 10],
			'edges': [(1, 6), (2, 6), (3, 7), (7, 8), (4, 10)],
			'buffer': {1:1, 2:2, 3:3, 4:4, 5:5, 6:6, 7:7, 8:8, 9:9, 10:10}
		},
		'reducer': {'buffer': {1:red, 2:red}},
		'meta': {'action':1, 'is_sticky': True}
	}
	return gdict

def incr_nodes(g, incr):
	for k in ["nodes", "inputs", "outputs"]:
		g[k] = [n + incr for n in g[k]]
	g["edges"] = [(e[0]+incr, e[1]+incr) for e in g["edges"]]
	init_keys = [k for k in g["buffer"].keys()]
	for k in init_keys:
		g["buffer"][k+incr] = g["buffer"].pop(k)
	return g

def dualcgp_colors(G, gdict):
	colors = []
	for n in G:
		print(n)
		if n in gdict["encoder"]["inputs"] + gdict["controller"]["inputs"]:
			c = INP_NODE_COLOR
		elif n in gdict["encoder"]["outputs"] + gdict["controller"]["outputs"]:
			c = OUT_NODE_COLOR
		else:
			c = INN_NODE_COLOR
		colors.append(c)
	return colors

def dualcgp_pos(gdict):
	ge = gdict["encoder"]
	gc = gdict["controller"]
	e_mid = [n for n in ge["buffer"].keys() if n not in ge["inputs"]]
	c_mid = [n for n in gc["buffer"].keys() if n not in gc["inputs"]]
	e_n_mid = len(e_mid)
	c_n_mid = len(c_mid)
	e_n_inp = len(ge["inputs"])
	e_n_out = len(ge["outputs"])
	c_n_inp = len(gc["inputs"])
	c_n_out = len(gc["outputs"])
	d = 2.0 # space between nodes
	pos = {}
	# Encoder pos
	e_xs = [(x-0.5*(e_n_mid+1))*d for x in range(e_n_mid+2)]
	e_inp_ys = [d*(y-(e_n_inp-1)/2) for y in range(e_n_inp)]
	e_out_ys = [d*(y-(e_n_out-1)/2) for y in range(e_n_out)]
	for i in range(len(ge["inputs"])):
		pos[ge["inputs"][i]] = (e_xs[0], e_inp_ys[i])
	for i in range(len(e_mid)):
		pos[e_mid[i]] = (e_xs[i+1], 0.0)
	#for i in range(len(ge["outputs"])):
	#	if ge["outputs"][i] not in ge["inputs"] and ge["outputs"][i] not in e_mid:
	#		pos[ge["outputs"][i]] = (e_xs[-1], e_out_ys[i])
	# Controller pos
	y_drift = 0.5 * d * max(e_n_inp+c_n_inp, e_n_out+c_n_out)
	c_xs = [(x-0.5*(c_n_mid+1))*d for x in range(c_n_mid+2)]
	c_inp_ys = [d*(y-(c_n_inp-1)/2)-y_drift for y in range(c_n_inp)]
	c_out_ys = [d*(y-(c_n_out-1)/2)-y_drift for y in range(c_n_out)]
	for i in range(len(gc["inputs"])):
		pos[gc["inputs"][i]] = (c_xs[0], c_inp_ys[i])
	for i in range(len(c_mid)):
		pos[c_mid[i]] = (c_xs[i+1], -y_drift)
	#for i in range(len(gc["outputs"])):
	#	if gc["outputs"][i] not in gc["inputs"] and gc["outputs"][i] not in c_mid:
	#		pos[gc["outputs"][i]] = (c_xs[-1], c_out_ys[i])
	return pos
	
def set_graph(G, g):
	G.add_nodes_from(g["buffer"].keys())
	G.add_edges_from(g["edges"])
	edgelabels = {}
	for e in g["edges"]:
		dest_node = e[1]
		dest_node_index = g["nodes"].index(dest_node)
		edgelabels[e] = g["fs"][dest_node_index]
	edgecolors = []
	for n in G:
		if n in g["inputs"]:
			edgecolors.append(INP_NODE_COLOR)
		elif n in g["outputs"]:
			edgecolors.append(OUT_NODE_COLOR)
		else:
			edgecolors.append(INN_NODE_COLOR)
	return G, edgelabels, edgecolors

def make_dualcgp_graph(gdict, incr=INCR):
	ge = gdict["encoder"]
	gc = incr_nodes(gdict["controller"], incr)
	G = nx.DiGraph()
	edgelabels, edgecolors = {}, []
	for g in [ge, gc]:
		G, lab, _ = set_graph(G, g)
		edgelabels.update(lab)
	edgecolors = dualcgp_colors(G, gdict)
	pos = dualcgp_pos(gdict)
	return G, edgelabels, edgecolors, pos

def make_single_graph(g):
	G = nx.DiGraph()
	G, edgelabels, edgecolors = set_graph(G, g)
	for n in G:
		G.nodes[n]["img"] = g["buffer"][n]
	return G, edgelabels, edgecolors

def draw_graph(G, edgelabels, edgecolors, pos=None, seed=123):
	fig, ax = plt.subplots()
	ax.set_aspect('equal')
	ax.margins(0.20)
	ax.axis("off")
	plt.axis("off")
	# plt.xlim(-1.5,1.5)
	# plt.ylim(-1.5,1.5)
	pos = nx.spring_layout(G, seed=seed) if pos is None else pos
	options = {
		"font_size": 15,
		# "node_size": 1000,
		"node_shape": 's',
		"node_color": "white",
		"edgecolors": edgecolors,
		"linewidths": 1,
		"width": 1 # , "with_labels": True
	}
	nx.draw_networkx(G, pos, **options)
	nx.draw_networkx_edge_labels(G, pos, edge_labels=edgelabels, font_color='black')

	'''
	# Transform from data coordinates (scaled between xlim and ylim) to display coordinates
	tr_figure = ax.transData.transform
	# Transform from display to figure coordinates
	tr_axes = fig.transFigure.inverted().transform

	# Select the size of the image (relative to the X axis)
	img_size = (ax.get_xlim()[1] - ax.get_xlim()[0]) * 0.01
	img_center = img_size / 2.0

	# Add the respective image to each node
	for n in G.nodes:
		xf, yf = tr_figure(pos[n])
		xa, ya = tr_axes((xf, yf))
		a = plt.axes([xa - img_center, ya - img_center, img_size, img_size])
		a.imshow(G.nodes[n]["img"])
		a.axis("off")
	'''

	plt.show()

def show_img_buffer(gdict, elt="encoder", node=1):
	image = gdict[elt]["buffer"][node]
	print(image.format)
	print(image.mode)
	print(image.size)
	image.show()

def print_gdict(gdict):
	print("\nLoaded graph dict:")
	print("\nencoder:")
	print(gdict["encoder"])
	print("\nreducer:")
	print(gdict["reducer"])
	print("\ncontroller:")
	print(gdict["controller"])
	print("\nmetadata:")
	print(gdict["meta"])
	print()

# python3.7 py-graph.py /home/wahara/.julia/dev/IICGP/results/2021-09-01T17:44:01.968_boxing

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	seed = 0 if (len(sys.argv) < 3) else int(sys.argv[2])

	frame = 1

	'''
	paths = get_paths(exp_dir)
	gdict = gdict_from_paths(paths, frame)
	print_gdict(gdict)
	'''

	gdict = test_gdict()
	print_gdict(gdict)

	# print_gdict(gdict)

	# g, lab, col, pos = make_dualcgp_graph(gdict)
	# draw_graph(g, lab, col, pos, seed)

	# g, lab, col = make_single_graph(gdict["encoder"])
	# draw_graph(g, lab, col, seed)

