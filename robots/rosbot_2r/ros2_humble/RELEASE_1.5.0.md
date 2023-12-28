TODO:

1. `yq`:

```bash
export YQ_VERSION=v4.40.4
export TARGETARCH=arm64 #amd64
curl -L https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH} -o /usr/bin/yq
chmod +x /usr/bin/yq
```

2. enable `snap`

3. ttyd

4. `ROS_LOCALHOST_ONLY=1` w `.bashrc`