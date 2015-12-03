resource "template_file" "minion_v1_cloud_config" {
depends_on = ["aws_elb.k8s_master_elb"]
  filename = "cloud-config/minion_v1.yml"
  vars {
    minion_discovery_url = "${file("cloud-config/minion_discovery_url.txt")}"
  }
}

resource "aws_instance" "minion_v1" {
  depends_on = ["template_file.minion_v1_cloud_config"]
  count = "10"
  ami = "${var.ami}"
  availability_zone = "${element(aws_subnet.kube.*.availability_zone, count.index)}"
  subnet_id = "${element(aws_subnet.kube.*.id, count.index)}"
  vpc_security_group_ids = [
    "${aws_security_group.kube_minion.id}",
    "${aws_security_group.kube_minion_ingress_master.id}",
    "${aws_security_group.dev.id}"
  ]

  instance_type = "${lookup(var.instance_type, "minion")}"
  key_name = "${aws_key_pair.kube.key_name}"
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.minion_profile.id}"
  tags {
    Name = "Kube Minion v1 ${count.index + 1}"
    role = "kube minion"
    KubernetesCluster = "kube" # Must match other KubernetesCluster tags throughout cluster
  }
  source_dest_check = false
  user_data = "${template_file.minion_v1_cloud_config.rendered}"
  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }
}
