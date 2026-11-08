{ buildGoModule }:

buildGoModule {
  pname = "terraform-provider-matrix";
  version = "0.1.0";
  src = ./.;

  vendorHash = "sha256-Z0Sos+VJoeZJNEtEHMr6RMuap2NVLOtCwKc6gi2hcCU=";

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    provider_dir="$out/libexec/terraform-providers/registry.terraform.io/jarvahl/matrix/0.1.0/linux_amd64"
    install -Dm755 "$out/bin/terraform-provider-matrix" \
      "$provider_dir/terraform-provider-matrix_v0.1.0"
    rm "$out/bin/terraform-provider-matrix"
    rmdir "$out/bin"
  '';
}
