#!/usr/bin/python

import sys
import os
import networkx as nx
import matplotlib.pyplot as plt
import yaml


DIR_PATH = os.path.dirname(os.path.realpath(__file__))


def str_to_tuple(s):
	if s[0] == "(":
		s = s[1:-1]
	if s[-1] == ")":
		s = s[0:-2]
	return tuple(map(int, s.split(', ')))

def get_g_paths_dict(exp_dir):
	g_dir = exp_dir + "/graphs"
	dct = {}
	for f in  os.listdir(g_dir):
		ind_name = f[0:len(f)-len(".yaml")]
		dct[ind_name] = g_dir + "/" + f
	return dct

def g_dict_from_g_paths_dict(g_paths_dict):
	g_dict = {}
	for k, v in g_paths_dict.items():
		with open(v, 'r') as stream:
			try:
				g = yaml.safe_load(stream)
				g["edges"] = [str_to_tuple(e) for e in g["edges"]]
				g_dict[k] = g
			except yaml.YAMLError as exc:
				print(exc)		
	return g_dict

def make_graph(g):
	G = nx.DiGraph()
	G.add_nodes_from(list(range(1, g["n_in"] + 1))) # Input nodes
	G.add_nodes_from(g["nodes"])
	G.add_edges_from(g["edges"])
	return G

def draw_graph_structure(G, seed=123):
	pos = nx.spring_layout(G, seed=seed)
	options = {
		"font_size": 15,
		# "node_size": 1000,
		"node_color": "white",
		"edgecolors": "black",
		"linewidths": 1,
		"width": 1 # , "with_labels": True
	}
	nx.draw_networkx(G, pos, **options)

	# Set margins for the axes so that nodes aren't clipped
	ax = plt.gca()
	ax.margins(0.20)
	plt.axis("off")
	plt.show()

def draw_graph(G, seed=123):
	fig, ax = plt.subplots()
	ax.set_aspect('equal')
	plt.xlim(-1.5,1.5)
	plt.ylim(-1.5,1.5)
	pos = nx.spring_layout(G, seed=seed)
	edge_options = {
		"pos": pos,
		"ax": ax,
		"arrows": True,
		"arrowstyle": "-"
	}

	# Note: the min_source/target_margin kwargs only work with FancyArrowPatch objects.
	# Force the use of FancyArrowPatch for edge drawing by setting `arrows=True`,
	# but suppress arrowheads with `arrowstyle="-"`
	nx.draw_networkx_edges(G, **edge_options)
	# nx.draw_networkx(G, **graph_options)

	# Transform from data coordinates (scaled between xlim and ylim) to display coordinates
	tr_figure = ax.transData.transform
	# Transform from display to figure coordinates
	tr_axes = fig.transFigure.inverted().transform

	# Select the size of the image (relative to the X axis)
	img_size = (ax.get_xlim()[1] - ax.get_xlim()[0]) * 0.1
	img_center = img_size / 2.0

	# Add the respective image to each node
	for n in G.nodes:
		xf, yf = tr_figure(pos[n])
		print(pos[n])
		print(xf, yf)
		print()
		xa, ya = tr_axes((xf, yf))
		# get overlapped axes and plot icon
		a = plt.axes([xa - img_center, ya - img_center, img_size, img_size])
		a.imshow(G.nodes[n]["image"])
		a.axis("off")

	ax.axis("off")
	plt.show()

def mwe_self_loop():
	# Create a graph and add a self-loop to node 0
	G = nx.complete_graph(3, create_using=nx.DiGraph)
	G.add_edge(0, 0)
	pos = nx.circular_layout(G)

	# As of version 2.6, self-loops are drawn by default with the same styling as
	# other edges
	nx.draw(G, pos, with_labels=True)

	# Add self-loops to the remaining nodes
	edgelist = [(1, 1), (2, 2)]
	G.add_edges_from(edgelist)

	# Draw the newly added self-loops with different formatting
	nx.draw_networkx_edges(G, pos, edgelist=edgelist, arrowstyle="<|-", style="dashed")

	plt.show()
	exit()

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	seed = 0 if (len(sys.argv) < 2) else int(sys.argv[2])

	g_paths_dict = get_g_paths_dict(exp_dir)
	g_dict = g_dict_from_g_paths_dict(g_paths_dict)

	print(g_dict["encoder"])

	g_enco = make_graph(g_dict["encoder"])
	draw_graph_structure(g_enco, seed)

