Apache Spark官方镜像的entrypoint脚本期望特定的参数（如 driver 或 executor ），但我们没有提供任何参数。
根据entrypoint脚本的逻辑，如果没有提供参数，它会直接执行 exec "$@" ，但由于我们没有提供任何命令，容器会立即退出。