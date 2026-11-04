extends SceneTree
## Checks that every item has its own icon: no two items share the same picture.
## Run from the godot folder:  godot --headless --path . -s tools/icon_audit.gd
## Prints the items that share an icon and exits with 1 if any do.
## AUDIT_SHEET=path also saves a contact sheet of every icon.

func _initialize() -> void:
	await process_frame
	var Data = root.get_node("Data")
	var Art = root.get_node("Art")
	var by_hash := {}
	var ids: Array = Data.ITEMS.keys()
	var types := {}
	for id in ids:
		var img: Image = Art.icon(id).get_image()
		var key := "%dx%d:%s" % [img.get_width(), img.get_height(), img.get_data().hex_encode().sha256_text()]
		by_hash[key] = by_hash.get(key, []) + [id]
		types[Data.ITEMS[id].type] = types.get(Data.ITEMS[id].type, 0) + 1
	var dup := 0
	for k in by_hash:
		if by_hash[k].size() > 1:
			dup += by_hash[k].size()
			print("  SAME ICON: ", ", ".join(by_hash[k]))
	print("items %d, distinct icons %d, items sharing an icon %d" % [ids.size(), by_hash.size(), dup])
	print(types)
	var sheet_path := OS.get_environment("AUDIT_SHEET")
	if sheet_path != "":
		var cols := 24
		var cell := 40
		var rows := int(ceil(ids.size() / float(cols)))
		var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("f3dcb5"))
		for i in ids.size():
			var img: Image = Art.icon(ids[i]).get_image()
			img.convert(Image.FORMAT_RGBA8)
			var k := maxi(1, int(32 / maxi(img.get_width(), img.get_height())))
			img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
			var x := (i % cols) * cell + (cell - img.get_width()) / 2
			var y := (i / cols) * cell + (cell - img.get_height()) / 2
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, y))
		sheet.save_png(sheet_path)
	quit(1 if dup > 0 else 0)
