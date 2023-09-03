# AIML Kubeflow
<font size=3>
Uses the kubeflow serving structure to create servable jupyter notebooks. 

## Keypoints
1. User is `root`.
2. Uses the conda-forge or standard python installatoin via deadsnake ubuntu repository to install python.
3. Uses NB_PREFIX variable passed into the docker, for path prefix.
4. Exposes the service in 8888 port.
5. Internally have two (three) different services running.
   - Jupyter Notebook: on `http://{serverip}:{serverport}$/{NB_PREFIX}` without any token
   - Code (vscode) Server: on `http://{serverip}:{serverport}$/{NB_PREFIX}/vscode`
   - Uses the NGINX reverse proxy to exposes both the services
6. Any additional internal webservices can be exposed via vscode proxy url: `/vscode/proxy/{port}/`

## Endpoint URLS
1. Jupyter: `http://{serverip}:{serverport}$/{NB_PREFIX}`
2. Code Server: `http://{serverip}:{serverport}$/{NB_PREFIX}/vscode`
3. Any Internal Application running on {port}: `http://{serverip}:{serverport}$/{NB_PREFIX}/vscode/proxy/{port}/`

## Command
Sample Command to run docker images
```bash
docker run -it --rm -p 8888:8888 --gpus 'device=all' <image_tag>
```

With Custom command you can use:
```bash
docker run -it --rm -p 8888:8888 --gpus 'device=all' <image_tag> <custom_command>
```

</font>