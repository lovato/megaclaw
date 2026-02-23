docker run -it --rm \
  --name openclaw \
  --ipc=host \
  --network bridge \
  -v /home/marco/openclaw/data:/data \
  -v /home/marco/openclaw/config:/config:ro \
  openclaw-local
