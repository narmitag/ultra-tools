docker compose run --rm rclone-ultra


⏰ DSM Task Scheduler (recommended)

DSM → Control Panel → Task Scheduler

Create → Scheduled Task → User-defined script

Run command:

cd /volume1/docker/rclone && docker compose run --rm rclone-ultra


Run as: root
Schedule: Daily or custom
Enabled: ✔