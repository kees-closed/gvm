[![Docker Repository on Quay](https://quay.io/repository/keesdejong/gvm/status "Docker Repository on Quay")](https://quay.io/repository/keesdejong/gvm)

# Greenbone Vulnerability Manager (GVM) - Source Edition 
Run the container with the following command: `podman run -it --rm -p 9392:9392 -v gvm-sync:/usr/local/var/lib -v gvm-postgres:/var/lib/postgresql --cap-add=NET_RAW docker.io/aqual1te/gvm:latest`. Then wait for the `rsync` to finish (first run will take a while) and then open the following link in your browser: https://localhost:9392

Default credentials:
* Username: admin
* Password: admin

In order to override the default password "admin" with "test123123", provide the following Podman command argument `--env password="test123123"`. Other environment variables can also change the behavior inside the container, check `entrypoint.sh`.

In case the initial NVT sync needs to be skipped, add the `--env initial_nvt_sync=0`. The NVT sync will then only be triggered by the daily cron.

For more detailed information about this container, check the [installation instructions](https://community.greenbone.net/t/gvm-21-04-stable-initial-release-2021-04-16/8942) and [architecture overview](https://community.greenbone.net/t/about-gvm-20-08-and-21-04-architecture/8449).

# Upcoming features
## Docker compose/Kubernetes
A Docker compose and a Kubernetes solution is in the works. Environment variables will be easier to use by using a `.env` file. Furthermore, the GVM components will be separate containers for easier troubleshooting and updates.
