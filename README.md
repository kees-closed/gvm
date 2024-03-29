[![Docker Repository on Quay](https://quay.io/repository/keesdejong/gvm/status "Docker Repository on Quay")](https://quay.io/repository/keesdejong/gvm)

Greenbone has released [official community containers](https://community.greenbone.net/greenbone-community-containers/), therefore this repository is not maintained anymore.

---

# Greenbone Vulnerability Manager (GVM) - Source Edition 
This GVM installation is done to the letter of the [official documentation](https://greenbone.github.io/docs/) with some minor exceptions due to undocumented steps (e.g. creating folders, setting permissions).

Run the container with the following command: `podman run --name=gvm -it --rm -p 9392:9392 -v openvas-data:/var/lib/openvas -v gvm-data:/var/lib/gvm -v gvm-database:/var/lib/postgresql -v /etc/localtime:/etc/localtime:ro --cap-add=NET_RAW quay.io/keesdejong/gvm:latest`. Then wait for the `rsync` to finish (first run will take a while) and then open the following link in your browser: https://localhost:9392

Default credentials:
* Username: admin
* Password: admin

In order to override the default password "admin" with "test123123", provide the following Podman command argument `--env password="test123123"`. Other environment variables can also change the behavior inside the container, check `entrypoint.sh`.

In case the initial NVT sync needs to be skipped, add the `--env initial_nvt_sync=0`. The NVT sync will then only be triggered by the daily cron.

For more detailed information about this container, check the [installation instructions](https://community.greenbone.net/t/gvm-21-04-stable-initial-release-2021-04-16/8942) and [architecture overview](https://community.greenbone.net/t/about-gvm-20-08-and-21-04-architecture/8449).

# Upcoming features
## Docker compose/Kubernetes
A Docker compose and a Kubernetes solution is in the works. Environment variables will be easier to use by using a `.env` file. Furthermore, the GVM components will be separate containers for easier troubleshooting and updates.
