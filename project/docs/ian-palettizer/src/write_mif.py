
def write_mif(image_palettized, k, image_name):
	"""
	https://www.intel.com/content/www/us/en/programmable/quartushelp/13.0/mergedProjects/reference/glossary/def_mif.htm
	"""
	print("Generating MIF (Memory Instantiation File)... ", end="", flush=True)

	width = k
	depth = len(image_palettized)

	buildString = (
		# construct header
		f"""WIDTH={width};\n"""
		f"""DEPTH={depth};\n"""
		f"""\n"""
		f"""ADDRESS_RADIX=UNS;\n""" # UNS = unsigned int
		f"""DATA_RADIX=UNS;\n"""
		f"""\n"""
		f"""CONTENT BEGIN\n"""
	)

	# write data in address : data format
	for i, palette_index in enumerate(image_palettized):
		buildString += f"""\t{i} : {palette_index};\n"""
	
	buildString += f"""END;\n"""

	# write the data to the file
	mif_name = f"""./{image_name}/{image_name}.mif"""
	with open(mif_name, "w") as f:
		f.write(buildString)

	print("Done")
	return width, depth, mif_name
