

mp networks 
mp set local.bridged-network=en0

mp launch 24.04 \
  --name docker \
  --cpus 2 \
  --memory 4G \
  --disk 40G \
  --bridged \
  --cloud-init https://raw.githubusercontent.com/canonical/multipass/refs/heads/main/data/cloud-init-yaml/cloud-init-docker.yaml