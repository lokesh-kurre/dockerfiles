# AIML Python
<font size=3>
Uses the conda-forge or standard python installatoin via deadsnake ubuntu repository to install python.

## Keypoints
1. User is `root`.
3. Uses the venv to hold all the required packages into ${VENV_DIR}.

## Command
Sample Command to run docker images
```bash
docker run -it --rm --gpus 'device=all' <image_tag>
```

With Custom command you can use:
```bash
docker run -it --rm --gpus 'device=all' <image_tag> <custom_command>
```

</font>