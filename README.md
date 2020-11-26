# Greenbone Vulnerability Manager (GVM) - Source Edition 
Run the container with the following command: `podman run -it --rm -p 9392:9392 -v gvm-sync:/usr/local/var/lib -v gvm-postgres:/var/lib/postgresql aqual1te/gvm:latest bash`. Then wait for the `rsync` to finish (first run will take a while) and then open the following link in your browser: https://localhost:9392

Default credentials:
* Username: admin
* Password: admin

In order to override the default password "admin" with "test123123", provide the following Podman command argument `--env password="test123123"`.

For more detailed information about this container, check the [installation instructions](https://community.greenbone.net/t/gvm-20-08-stable-initial-release-2020-08-12/6312) and [architecture overview](https://community.greenbone.net/t/about-gvm-architecture/1231).
