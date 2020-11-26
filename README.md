# Greenbone Vulnerability Manager (GVM) - Source Edition 
Run the container with the following command: `podman run -it --rm -p 9392:9392 -v gvm-sync:/usr/local/var/lib -v gvm-postgres:/var/lib/postgresql aqual1te/gvm:latest bash`. Then wait for the `rsync` to finish (first run will take a while) and then open the following link in your browser: https://localhost:9392

Username: admin
Password: admin

To override the default credentials with administrator as username and password, append the following variables to the end of the `podman` command: username=administrator password=administrator

For more detailed information about this container, check the [installation instructions](https://community.greenbone.net/t/gvm-20-08-stable-initial-release-2020-08-12/6312) and [architecture overview](https://community.greenbone.net/t/about-gvm-architecture/1231).
