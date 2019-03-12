locals {
  tags_asg_format = ["${null_resource.tags_as_list_of_maps.*.triggers}"]
  instance_types  = ["${data.null_data_source.instance_types.*.outputs}"]
}

resource "null_resource" "tags_as_list_of_maps" {
  count = "${length(keys(var.tags_as_map))}"

  triggers = "${map(
    "key", "${element(keys(var.tags_as_map), count.index)}",
    "value", "${element(values(var.tags_as_map), count.index)}",
    "propagate_at_launch", "true"
  )}"
}

data "null_data_source" "instance_types" {
  count = "${length(var.instance_types)}"

  inputs = "${map(
    "instance_type", trimspace(element(var.instance_types, count.index))
  )}"
}
