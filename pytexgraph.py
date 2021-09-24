#!/usr/bin/python

import sys
import os
import subprocess
import math
import yaml
import PIL
import matplotlib.animation as animation
from matplotlib.widgets import Slider


# Meta parameters
SEED = 1234
DIR_PATH = os.path.dirname(os.path.realpath(__file__))
IMG_EXT = ".png"
IMG_TYPE = PIL.PngImagePlugin.PngImageFile
CTR_INCR = 200 # increment for controller's nodes names
OUT_INCR = 100 # increment for outputs's nodes names
FEATURE_SIZE = 25 # 5*5 mean-pooling features

# Graph Layout
FRW_NODE_COLOR = "red"
INP_NODE_COLOR = "green"
INN_NODE_COLOR = "black"
OUT_NODE_COLOR = "blue"
POSITIONING = "spring" # circular spring dual single
MERGE_CONTROLLER_INPUT = False
WITH_LABELS = False
FIGSIZE = (5, 5)
XLIM, YLIM = 100, 100
E_XLIM, E_YLIM = 1, 1
C_XLIM, C_YLIM = 1, 1
IMG_SIZE_PROPORTION = 0.01
NODES_SIZE = 30
NODES_SPACING = 1

TEST_TEXSCRIPT = [
	"\\documentclass{article}",
	"\\usepackage{tikz}",
	"\\usepackage{verbatim}",
	"\\usepackage{verbatim}",
	"\\usepackage[active,tightpage]{preview}",
	"\\PreviewEnvironment{tikzpicture}",
	"\\setlength\PreviewBorder{5pt}%",
	"\\begin{document}",
	"\\begin{tikzpicture}",
	"\\def \\n{5}",
	"\\def \\radius {3cm}",
	"\\def \\margin {8}",
	"\\foreach \\s in {1,...,\\n}",
	"{",
	"  \\node[draw, circle] at ({360/\\n * (\\s - 1)}:\\radius) {$\\s$};",
	"  \\draw[->, >=latex] ({360/\\n * (\\s - 1)+\\margin}:\\radius)",
	"    arc ({360/\\n * (\\s - 1)+\\margin}:{360/\\n * (\\s)-\\margin}:\\radius);",
	"}",
	"\\end{tikzpicture}",
	"\\end{document}"
]

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
			node = int(f[3:-len(IMG_EXT)])
			b[node] = PIL.Image.open(path + f)
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
	red = rb[list(rb.keys())[0]]
	gdict = {
		'encoder': {
			'nodes': [4, 5, 6],
			'fs': ['f1', 'f2', 'f3'],
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
			'buffer': {1:0.0, 2:0.2, 3:0.3, 4:0.4, 5:0.5, 6:0.6, 7:0.7, 8:0.8, 9:0.9, 10:1.0}
		},
		'reducer': {'buffer': {4:red, 6:red}},
		'meta': {'action':1, 'is_sticky': False}
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
		if n in gdict["encoder"]["inputs"] + gdict["controller"]["inputs"]:
			c = INP_NODE_COLOR
		elif n in gdict["encoder"]["outputs"] + gdict["controller"]["outputs"]:
			c = OUT_NODE_COLOR
		else:
			c = INN_NODE_COLOR
		colors.append(c)
	return colors

def merge_cinpos(pos, gdict):
	gc = gdict["controller"]
	# refpos = pos[gc["inputs"][0]]
	refpos = (0, 0)
	for o in gc["inputs"]:
		pos[o] = refpos
	return pos
	
def get_pos(G, gdict, seed, key=None, verbose=False):
	if POSITIONING == "spring":
		pos = nx.spring_layout(G, seed=seed)
	elif POSITIONING == "circular":
		pos = nx.circular_layout(G)
	elif POSITIONING == "dual":
		pos = dual_pos(G, gdict)
	elif POSITIONING == "single":
		pos = single_pos(G, gdict, key)
	else:
		raise NameError(POSITIONING)
	if MERGE_CONTROLLER_INPUT:
		pos = merge_cinpos(pos, gdict)
	if verbose:
		print("\nNodes positions:")
		for k, v in pos.items():
			print(k, v)
	return pos

def dual_pos(G, gdict):
	ge = gdict["encoder"]
	gc = gdict["controller"]
	e_out = get_output_nodes_labels(G, ge["outputs"])
	c_out = get_output_nodes_labels(G, gc["outputs"])
	e_mid = [n for n in ge["buffer"].keys() if n not in ge["inputs"]]
	c_mid = [n for n in gc["buffer"].keys() if n not in gc["inputs"]]
	e_n_mid, e_n_inp, e_n_out = len(e_mid), len(ge["inputs"]), len(ge["outputs"])
	c_n_mid, c_n_inp, c_n_out = len(c_mid), len(gc["inputs"]), len(gc["outputs"])
	d = NODES_SPACING
	pos = {}
	
	# Encoder pos
	e_xs = [(x-0.5*(e_n_mid+1))*d for x in range(e_n_mid+2)]
	e_inp_ys = [d*(y-(e_n_inp-1)/2) for y in range(e_n_inp)]
	e_out_ys = [d*(y-(e_n_out-1)/2) for y in range(e_n_out)]
	for i in range(len(ge["inputs"])):
		pos[ge["inputs"][i]] = (e_xs[0], e_inp_ys[i])
	for i in range(len(e_mid)):
		pos[e_mid[i]] = (e_xs[i+1], 0.0)
	for i in range(len(e_out)):
		pos[e_out[i]] = (e_xs[-1], e_out_ys[i])

	# Controller pos
	y_drift = 0.6 * d * (e_n_out+c_n_out) # max(e_n_inp+c_n_inp, e_n_out+c_n_out)
	c_xs = [(x-0.5*(c_n_mid+1))*d for x in range(c_n_mid+2)]
	c_inp_ys = [d*(y-(c_n_inp-1)/2)-y_drift for y in range(c_n_inp)]
	c_out_ys = [d*(y-(c_n_out-1)/2)-y_drift for y in range(c_n_out)]
	for i in range(len(gc["inputs"])):
		# pos[gc["inputs"][i]] = (c_xs[0], c_inp_ys[i])  # Equally spanned input
		pos[gc["inputs"][i]] = (c_xs[0], 5*d-y_drift)  # Single input node
	for i in range(len(c_mid)):
		pos[c_mid[i]] = (c_xs[i+1], -y_drift)
	for i in range(len(c_out)):
		pos[c_out[i]] = (c_xs[-1], c_out_ys[i])

	return pos

def single_pos(G, gdict, key):
	g = gdict[key]
	out = get_output_nodes_labels(G, g["outputs"])
	mid = [n for n in g["buffer"].keys() if n not in g["inputs"]]
	n_mid, n_inp, n_out = len(mid), len(g["inputs"]), len(g["outputs"])
	d = NODES_SPACING
	pos = {}
	xs = [(x-0.5*(n_mid+1))*d for x in range(n_mid+2)]
	inp_ys = [d*(y-(n_inp-1)/2) for y in range(n_inp)]
	out_ys = [d*(y-(n_out-1)/2) for y in range(n_out)]
	for i in range(len(g["inputs"])):
		inp_y_i = inp_ys[i] if key == "encoder" else 5*d
		pos[g["inputs"][i]] = (xs[0], inp_y_i)
	for i in range(len(mid)):
		pos[mid[i]] = (xs[i+1], 0.0)
	for i in range(len(out)):
		pos[out[i]] = (xs[-1], out_ys[i])
	return pos
	
def get_output_nodes_labels(G, outputs):
	out = []
	for i in range(len(outputs)):
		out_i = outputs[i] + OUT_INCR
		while out_i in out:
			out_i += 1
		out.append(out_i)
	return out
	
def set_graph(G, g, gr=None):
	# Nodes
	G.add_nodes_from(g["buffer"].keys())
	output_nodes = get_output_nodes_labels(G, g["outputs"])
	G.add_nodes_from(output_nodes)

	# Edges
	G.add_edges_from(g["edges"])
	for i in range(len(output_nodes)):
		G.add_edge(g["outputs"][i], output_nodes[i])
	edgelabels = {}
	for e in g["edges"]:
		dest_node = e[1]
		dest_node_index = g["nodes"].index(dest_node)
		edgelabels[e] = g["fs"][dest_node_index]

	# Set colors
	edgecolors = []
	for n in G:
		if n in g["inputs"]:
			edgecolors.append(INP_NODE_COLOR)
		elif n in g["outputs"]:
			edgecolors.append(OUT_NODE_COLOR)
		else:
			edgecolors.append(INN_NODE_COLOR)

	# Set inner buffer
	for n in g["buffer"].keys():
		G.nodes[n]["buffer"] = g["buffer"][n]
	
	# Set output buffer
	for i in range(len(output_nodes)):
		out_node_i = output_nodes[i]
		out_i = g["outputs"][i]
		r_buffer_i = g["buffer"][out_i] if gr is None else gr["buffer"][out_i]
		G.nodes[out_node_i]["buffer"] = r_buffer_i
		
	return G, edgelabels, edgecolors
	
def make_enco_graph(gdict):
	ge = gdict["encoder"]
	G = nx.DiGraph()
	G, edgelabels, edgecolors = set_graph(G, ge, gdict["reducer"])
	return G, edgelabels, edgecolors
	
def make_cont_graph(gdict):
	gc = incr_nodes(gdict["controller"], CTR_INCR)
	G = nx.DiGraph()
	G, edgelabels, edgecolors = set_graph(G, gc)
	return G, edgelabels, edgecolors

def make_dualcgp_graph(gdict):
	ge = gdict["encoder"]
	gc = incr_nodes(gdict["controller"], CTR_INCR)
	G = nx.DiGraph()
	edgelabels, edgecolors = {}, []
	
	# Fetch encoder graph info
	G, lab, _ = set_graph(G, ge, gdict["reducer"])
	edgelabels.update(lab)
	
	# Fetch controller graph info
	G, lab, _ = set_graph(G, gc)
	edgelabels.update(lab)
	
	edgecolors = dualcgp_colors(G, gdict)
	return G, edgelabels, edgecolors

def draw_graph(G, edgelabels, col, pos, ax, lim, edgecolors=None):
	#fig = plt.figure(figsize=(5,5))
	#ax = plt.subplot(111)
	plt.sca(ax)
	ax.set_aspect('equal')
	#ax.margins(0.20)
	#ax.axis("off")
	#plt.axis("off")
	plt.xlim(-lim[0],lim[0])
	plt.ylim(-lim[1],lim[1])
	
	options = {
		"with_labels": WITH_LABELS,
		"font_size": 10,
		"node_size": NODES_SIZE,
		"node_shape": 'o', # s o
		"node_color": "white",
		"edgecolors": col,
		"linewidths": 1,
		"width": 1 # , "with_labels": True
	}
	if edgecolors is not None:
		options["edge_color"] = edgecolors
	nx.draw_networkx(G, pos, **options, ax=ax)
	nx.draw_networkx_edge_labels(G, pos, edge_labels=edgelabels, font_color='black', ax=ax)
	
	# Transform from data coordinates (scaled between xlim and ylim) to display coordinates
	tr_figure = ax.transData.transform
	# Transform from display to figure coordinates
	tr_axes = fig.transFigure.inverted().transform

	# Select the size of the image (relative to the X axis)
	img_size = (ax.get_xlim()[1] - ax.get_xlim()[0]) * IMG_SIZE_PROPORTION
	img_center = img_size / 2.0

	# Add the respective image to each node
	for n in G.nodes:
		if type(G.nodes[n]["buffer"]) == IMG_TYPE:
			xf, yf = tr_figure(pos[n])
			xa, ya = tr_axes((xf, yf))
			a = plt.axes([xa - img_center, ya - img_center, img_size, img_size])
			a.imshow(G.nodes[n]["buffer"])
			a.axis("off")
	
	#plt.show()

def show_img_buffer(gdict, elt="encoder", node=1):
	image = gdict[elt]["buffer"][node]
	print(image.format)
	print(image.mode)
	print(image.size)
	image.show()
	
def print_inddict(g, verbose=True):
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

def print_gdict(gdict):
	print("\nLoaded gdict:")
	print("\nencoder:")
	#print(gdict["encoder"])
	print_inddict(gdict["encoder"])
	print("\nreducer:")
	print(gdict["reducer"])
	print("\ncontroller:")
	#print(gdict["controller"])
	print_inddict(gdict["controller"])
	print("\nmetadata:")
	print(gdict["meta"])
	print()
	
def create_texscript(gdict):
	texscript = TEST_TEXSCRIPT
	return texscript
	
def build(texscript, paths, frame):
	savedir = paths["meta"]
	fname = "1_graph"
	texsavepath = savedir + fname + ".tex"
	with open(texsavepath, 'w') as f:
		for line in texscript:
			f.write(line)
			f.write('\n')
		f.close()
	print(texsavepath)
	subprocess.run(["pdflatex", "-interaction", "nonstopmode",
			"-output-directory", savedir, texsavepath])
	# Clean
	for ext in [".tex", ".aux", ".log"]:
		os.remove(savedir + fname + ext)
	# Evince
	subprocess.run(["evince", savedir + fname + ".pdf"])
		
def make_graph(paths, frame):
	gdict = gdict_from_paths(paths, frame)
	texscript = create_texscript(gdict)
	build(texscript, paths, frame)

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	max_frame = 1
	pdict = get_paths(exp_dir)

	for frame in range(1, max_frame + 1):
		make_graph(pdict, frame)

# python3.7 pygraph.py /home/wahara/.julia/dev/IICGP/results/2021-09-01T17:44:01.968_boxing
# python3.8 pygraph.py /home/opaweynch/.julia/environments/v1.6/dev/IICGP/results/2021-09-01T17:44:01.968_boxing

