podman run -it --rm \
  --name openclaw \
  --ipc=host \
  -v ./data:/home/node/.openclaw \
  openclaw-local
